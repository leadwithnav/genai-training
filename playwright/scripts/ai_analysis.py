"""
AI Failure Analysis Script
==========================
Called by the GitHub Actions "AI failure analysis" step.

Flow:
  1. Parse JUnit XML from smoke-results.xml and regression-results.xml.
  2. Call GitHub Models API (gpt-4o-mini) with a structured QA prompt.
     If the API is unavailable or the response cannot be parsed the script
     exits with a non-zero status so the CI step is marked as failed.
  3. Write a Markdown summary table to $GITHUB_STEP_SUMMARY so it appears
     on the GitHub Actions "Summary" tab of the job run.

Environment variables injected by the workflow step:
  GITHUB_TOKEN        -- auto-available in every Actions job
  SMOKE_RESULTS       -- path to smoke JUnit XML  (default: playwright/smoke-results.xml)
  REGRESSION_RESULTS  -- path to regression JUnit XML (default: playwright/regression-results.xml)
  RUN_NUMBER          -- github.run_number
  SHA                 -- github.sha
  WORKFLOW            -- github.workflow name
  GITHUB_STEP_SUMMARY -- path to the job summary file (set by Actions runner)
"""

import json
import os
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# 1. Parse JUnit XML -- collect failing test names and error messages
# ---------------------------------------------------------------------------

def parse_junit(path: str) -> list:
    """
    Return a list of dicts for every failed <testcase> in the JUnit XML.
    Each dict: { suite, name, message }
    Returns [] when the file does not exist or cannot be parsed.
    """
    if not os.path.exists(path):
        print(f"[ai_analysis] File not found, skipping: {path}", file=sys.stderr)
        return []

    try:
        tree = ET.parse(path)
    except ET.ParseError as exc:
        print(f"[ai_analysis] XML parse error in {path}: {exc}", file=sys.stderr)
        return []

    failures = []
    root = tree.getroot()

    # Support both <testsuites><testsuite>... and bare <testsuite>...
    suites = root.findall(".//testsuite") or [root]

    for suite in suites:
        suite_name = suite.get("name", "unknown-suite")
        for tc in suite.findall("testcase"):
            failure_el = tc.find("failure")
            if failure_el is None:
                failure_el = tc.find("error")
            if failure_el is not None:
                failures.append(
                    {
                        "suite": suite_name,
                        "name": tc.get("name", "unnamed test"),
                        "message": (
                            failure_el.get("message")
                            or (failure_el.text or "").strip()[:400]
                        ),
                    }
                )

    return failures


# ---------------------------------------------------------------------------
# 2. Build the prompt sent to the AI model
# ---------------------------------------------------------------------------

def build_prompt(failures: list) -> str:
    """
    Construct a QA-engineering prompt from the collected failures.
    The model is asked to return strict JSON so the response is parseable.
    """
    failure_block = "\n".join(
        "- [{}] {}: {}".format(f["suite"], f["name"], f["message"])
        for f in failures
    )

    return (
        "You are a senior QA automation engineer analysing CI test failures.\n\n"
        "The application under test is GenAI Store -- a Dockerized ecommerce app with:\n"
        "  * Web frontend (nginx, port 3000)\n"
        "  * REST API (Node.js/Express, port 8081)\n"
        "  * PostgreSQL database\n"
        "  * Playwright test suites covering ecommerce workflows\n\n"
        "The following tests failed in CI. Each entry shows [suite] test-name: error-message.\n"
        "Infer the impacted feature and root cause from the test name and error message alone.\n\n"
        f"{failure_block}\n\n"
        "For EACH failed test return a JSON object inside a JSON array.\n"
        "Use exactly these string keys:\n"
        "  failed_suite, probable_root_cause, classification (UI|API|DB|ENV),\n"
        "  impacted_feature, retry_recommendation, suggested_owner, draft_bug_title,\n"
        "  suggested_fix_location (file and line number to fix, e.g. 'src/app.js:42' or 'unknown')\n\n"
        "Return ONLY the JSON array -- no markdown fences, no commentary."
    )


# ---------------------------------------------------------------------------
# 3. Call GitHub Models API (gpt-4o-mini) via urllib (no extra packages)
# ---------------------------------------------------------------------------

def call_github_models_api(prompt: str):
    """
    Call the GitHub Models inference endpoint using only stdlib urllib.
    Returns the raw text response string, or None on any failure.
    """
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        print("[ai_analysis] GITHUB_TOKEN not set -- skipping AI call.", file=sys.stderr)
        return None

    payload = json.dumps(
        {
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a senior QA automation engineer. "
                        "Always respond with valid JSON arrays as instructed. "
                        "Never include markdown fences in your response."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.2,
            "max_tokens": 1500,
        }
    ).encode("utf-8")

    req = urllib.request.Request(
        "https://models.inference.ai.azure.com/chat/completions",
        data=payload,
        headers={
            "Authorization": "Bearer {}".format(token),
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
            content = data["choices"][0]["message"]["content"]
            print("[ai_analysis] AI response received from GitHub Models API (gpt-4o-mini).")
            return content
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors="replace")
        print(
            "[ai_analysis] GitHub Models API HTTP {}: {}".format(exc.code, body[:300]),
            file=sys.stderr,
        )
    except Exception as exc:  # noqa: BLE001
        print("[ai_analysis] GitHub Models API unavailable: {}".format(exc), file=sys.stderr)

    return None


# ---------------------------------------------------------------------------
# 4. Parse AI response -- JSON array -> list of dicts
# ---------------------------------------------------------------------------

def parse_ai_response(raw: str):
    """
    Decode the model's JSON array response.
    Returns None if parsing fails (caller will abort the script).
    """
    if not raw:
        return None

    text = raw.strip()
    # Strip accidental markdown fences the model may have added
    if text.startswith("```"):
        lines = [l for l in text.splitlines() if not l.startswith("```")]
        text = "\n".join(lines).strip()

    try:
        data = json.loads(text)
        if isinstance(data, list):
            return data
        print("[ai_analysis] AI returned JSON but not a list -- falling back.", file=sys.stderr)
    except json.JSONDecodeError as exc:
        print("[ai_analysis] JSON decode error: {} -- falling back.".format(exc), file=sys.stderr)

    return None


# ---------------------------------------------------------------------------
# 5. Render Markdown summary table
# ---------------------------------------------------------------------------


_COLUMNS = [
    ("Failed Suite",        "failed_suite"),
    ("Probable Root Cause", "probable_root_cause"),
    ("Classification",      "classification"),
    ("Impacted Feature",    "impacted_feature"),
    ("Retry",               "retry_recommendation"),
    ("Suggested Owner",     "suggested_owner"),
    ("Draft Bug Title",     "draft_bug_title"),
    ("Suggested Fix Location", "suggested_fix_location"),
]


def render_markdown(analyses: list, failures: list) -> str:
    """
    Build the Markdown written to GITHUB_STEP_SUMMARY.
    """
    run_number = os.environ.get("RUN_NUMBER", os.environ.get("GITHUB_RUN_NUMBER", "?"))
    sha = (os.environ.get("SHA", os.environ.get("GITHUB_SHA", "?")) or "?")[:7]
    workflow = os.environ.get("WORKFLOW", os.environ.get("GITHUB_WORKFLOW", "CI"))
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    model_label = "gpt-4o-mini via GitHub Models API"

    header = (
        "## CI Failure Analysis -- Run #{} ({})\n\n"
        "> **{} test failure(s)** detected | {} | Model: {}\n\n"
    ).format(run_number, sha, len(failures), timestamp, model_label)

    # Table header row
    col_labels = [c[0] for c in _COLUMNS]
    col_keys   = [c[1] for c in _COLUMNS]
    table_header = "| " + " | ".join(col_labels) + " |"
    separator    = "| " + " | ".join("---" for _ in _COLUMNS) + " |"

    rows = []
    for analysis in analyses:
        cells = []
        for key in col_keys:
            value = str(analysis.get(key, "--"))
            # Escape pipe characters so they do not break the Markdown table
            value = value.replace("|", "\\|")
            cells.append(value)
        rows.append("| " + " | ".join(cells) + " |")

    table = "\n".join([table_header, separator] + rows)

    footer = (
        "\n\n---\n"
        "*Generated by GitHub Copilot CI | {} | Run #{}*\n"
        "*Model: {}*\n"
    ).format(workflow, run_number, model_label)

    return header + table + footer


# ---------------------------------------------------------------------------
# 6. Main entry point
# ---------------------------------------------------------------------------

def main() -> None:
    smoke_path      = os.environ.get("SMOKE_RESULTS",      "playwright/smoke-results.xml")
    regression_path = os.environ.get("REGRESSION_RESULTS", "playwright/regression-results.xml")

    failures = parse_junit(smoke_path) + parse_junit(regression_path)

    if not failures:
        print("[ai_analysis] No test failures found in JUnit XML files -- nothing to report.")
        return

    print("[ai_analysis] {} failure(s) found. Building AI prompt ...".format(len(failures)))

    # Call AI analysis -- hard-fail if unavailable or response is unparseable
    prompt       = build_prompt(failures)
    raw_response = call_github_models_api(prompt)
    if not raw_response:
        print("[ai_analysis] AI API call failed -- no response received.", file=sys.stderr)
        sys.exit(1)

    analyses = parse_ai_response(raw_response)
    if analyses is None:
        print("[ai_analysis] Failed to parse AI response as JSON array -- aborting.", file=sys.stderr)
        sys.exit(1)

    summary_md   = render_markdown(analyses, failures)
    print(summary_md)

    summary_path = os.environ.get("GITHUB_STEP_SUMMARY", "")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as fh:
            fh.write(summary_md)
        print("[ai_analysis] Summary written to GITHUB_STEP_SUMMARY.")
    else:
        print("[ai_analysis] GITHUB_STEP_SUMMARY not set -- output printed to stdout only.")


if __name__ == "__main__":
    main()
