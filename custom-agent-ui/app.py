"""
QA Coverage Analyzer — Streamlit UI
Loads Jira stories from RAG, shows Acceptance Criteria, existing TestRail
test cases, generates missing test cases with GPT-4o, and exports selected
cases directly to TestRail.
"""

import os
import sys
import json
import re
import requests
import streamlit as st
from dotenv import load_dotenv
from openai import OpenAI

# ── Path / env setup ────────────────────────────────────────────────────────
_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_DIR, "../rag"))
load_dotenv(os.path.join(_DIR, "../rag/.env"))

# ── Config ──────────────────────────────────────────────────────────────────
OPENAI_API_KEY      = os.getenv("OPENAI_API_KEY", "")
TESTRAIL_URL        = os.getenv("TESTRAIL_URL", "").rstrip("/")
TESTRAIL_USER       = os.getenv("TESTRAIL_USER", "")
TESTRAIL_TOKEN      = os.getenv("TESTRAIL_TOKEN", "")
TESTRAIL_PROJECT_ID = int(os.getenv("TESTRAIL_PROJECT_ID", "2"))

client = OpenAI(api_key=OPENAI_API_KEY)


# ── RAG helpers ──────────────────────────────────────────────────────────────
def rag_query(query: str, top_k: int = 20) -> list:
    from get_relevant_docs import get_relevant_docs
    return get_relevant_docs(query, top_k=top_k)


# ── Data loading ─────────────────────────────────────────────────────────────
@st.cache_data(show_spinner="Loading Jira stories from RAG…")
def load_jira_stories() -> list:
    docs = rag_query("all Jira KAN project stories tasks epics", top_k=40)
    stories = []
    seen = set()
    for doc in docs:
        doc_id  = doc.get("id", "")
        content = doc.get("content", "")
        key_match = re.search(r'KAN-\d+', doc_id + " " + content)
        if not key_match:
            continue
        key = key_match.group(0)
        if key in seen:
            continue
        seen.add(key)

        lines    = [l.strip() for l in content.splitlines() if l.strip()]
        summary  = lines[0] if lines else key
        issuetype = "Story"
        status    = "Unknown"
        for line in lines:
            if re.search(r'(type:|issue type:)', line, re.IGNORECASE):
                issuetype = line.split(":", 1)[-1].strip()
            if re.match(r'status:', line, re.IGNORECASE):
                status = line.split(":", 1)[-1].strip()

        stories.append({
            "key":       key,
            "summary":   summary,
            "issuetype": issuetype,
            "status":    status,
            "content":   content,
        })

    return sorted(stories, key=lambda x: int(x["key"].split("-")[1]))


def get_story_full_content(story_key: str) -> str:
    docs = rag_query(f"{story_key} acceptance criteria requirements", top_k=5)
    for doc in docs:
        if story_key in doc.get("id", "") or story_key in doc.get("content", ""):
            return doc.get("content", "")
    return ""


def extract_acceptance_criteria(content: str) -> list:
    """Pull AC bullet lines out of a RAG document."""
    ac, in_ac = [], False
    for line in content.splitlines():
        stripped = line.strip()
        if re.search(r'acceptance criteria', stripped, re.IGNORECASE):
            in_ac = True
            continue
        if in_ac:
            if stripped and not stripped.startswith("#") and not re.match(
                r'^(definition of done|notes?|description):', stripped, re.IGNORECASE
            ):
                ac.append(stripped)
            elif stripped.startswith("#") or re.match(
                r'^(definition of done|notes?|description):', stripped, re.IGNORECASE
            ):
                break
    return ac


@st.cache_data(show_spinner="Finding existing TestRail test cases…")
def get_existing_test_cases(story_key: str, summary: str) -> list:
    docs = rag_query(f"{story_key} {summary}", top_k=15)
    tcs  = []
    for doc in docs:
        doc_id = doc.get("id", "")
        if not doc_id.startswith("testrail_"):
            continue
        m     = re.search(r'testrail_(\d+)', doc_id)
        tc_id = f"C{m.group(1)}" if m else doc_id
        tcs.append({"id": tc_id, "content": doc.get("content", "")})
    return tcs


# ── TestRail API ─────────────────────────────────────────────────────────────
def _tr_auth():
    return (TESTRAIL_USER, TESTRAIL_TOKEN)


def tr_get(endpoint: str) -> dict:
    url = f"{TESTRAIL_URL}/index.php?/api/v2/{endpoint}"
    r   = requests.get(url, auth=_tr_auth(), timeout=15)
    r.raise_for_status()
    return r.json()


def tr_post(endpoint: str, payload: dict) -> dict:
    url = f"{TESTRAIL_URL}/index.php?/api/v2/{endpoint}"
    r   = requests.post(url, json=payload, auth=_tr_auth(), timeout=15)
    r.raise_for_status()
    return r.json()


@st.cache_data(show_spinner="Loading TestRail sections…")
def get_testrail_sections() -> list:
    try:
        data     = tr_get(f"get_sections/{TESTRAIL_PROJECT_ID}")
        sections = data if isinstance(data, list) else data.get("sections", [])
        return [{"id": s["id"], "name": s["name"]} for s in sections]
    except Exception:
        return []


# ── LLM: Generate missing test cases ─────────────────────────────────────────
def generate_missing_test_cases(
    story_key: str,
    summary: str,
    ac_list: list,
    existing_tcs: list,
) -> list:
    existing_block = (
        "\n".join(f"- {tc['id']}: {tc['content'][:150]}" for tc in existing_tcs)
        or "None"
    )
    ac_block = (
        "\n".join(f"- {a}" for a in ac_list)
        or "No AC found — infer from the story summary."
    )

    prompt = f"""You are a senior QA engineer. Analyze the Jira story and produce MISSING test cases.

Jira Story: {story_key} — {summary}

Acceptance Criteria:
{ac_block}

Existing TestRail Test Cases (already covered — do NOT duplicate these):
{existing_block}

Generate test cases that cover uncovered acceptance criteria, edge cases,
negative/error scenarios, and boundary conditions.

Return ONLY a valid JSON array — no markdown fences, no explanation:
[
  {{
    "title": "Short descriptive test case title",
    "preconditions": "Setup required before the test",
    "steps": "Numbered step-by-step test actions",
    "expected": "Expected result after all steps"
  }},
  ...
]"""

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.3,
    )
    raw = resp.choices[0].message.content.strip()
    raw = re.sub(r"^```(?:json)?\s*", "", raw)
    raw = re.sub(r"\s*```$", "", raw).strip()
    return json.loads(raw)


def export_cases_to_testrail(cases: list, section_id: int) -> list:
    results = []
    for case in cases:
        payload = {
            "title":            case["title"],
            "type_id":          1,
            "priority_id":      2,
            "custom_preconds":  case.get("preconditions", ""),
            "custom_steps":     case.get("steps", ""),
            "custom_expected":  case.get("expected", ""),
        }
        try:
            resp = tr_post(f"add_case/{section_id}", payload)
            results.append({
                "title":  case["title"],
                "id":     resp.get("id"),
                "status": "✅ Created",
            })
        except Exception as e:
            results.append({"title": case["title"], "id": None, "status": f"❌ {e}"})
    return results


# ═══════════════════════════════════════════════════════════════════════════════
# Streamlit UI
# ═══════════════════════════════════════════════════════════════════════════════
st.set_page_config(
    page_title="QA Coverage Analyzer",
    page_icon="🧪",
    layout="wide",
)

st.title("🧪 QA Coverage Analyzer")
st.caption("RAG + GPT-4o  |  Jira ↔ TestRail Traceability")

# ── Story dropdown ────────────────────────────────────────────────────────────
stories = load_jira_stories()
if not stories:
    st.error("No Jira stories found in RAG. Make sure the FAISS index is built.")
    st.stop()

story_options  = {f"{s['key']}  —  {s['summary']}": s for s in stories}
selected_label = st.selectbox("📋 Select a Jira Story", list(story_options.keys()))
selected       = story_options[selected_label]

st.divider()

# ── Story header ──────────────────────────────────────────────────────────────
c1, c2, c3 = st.columns(3)
c1.metric("Story Key",  selected["key"])
c2.metric("Issue Type", selected["issuetype"])
c3.metric("Status",     selected["status"])

st.markdown(f"**📝 Summary:** {selected['summary']}")

# ── Main tabs ─────────────────────────────────────────────────────────────────
tab1, tab2 = st.tabs([
    "✅ Existing Test Cases",
    "🔍 Missing Test Cases",
])

# ── Tab 1: Existing Test Cases ────────────────────────────────────────────────
with tab1:
    existing_tcs = get_existing_test_cases(selected["key"], selected["summary"])
    if existing_tcs:
        st.success(f"Found **{len(existing_tcs)}** existing test case(s) in TestRail.")
        for tc in existing_tcs:
            with st.expander(f"🧪 {tc['id']}"):
                st.text(tc["content"][:600])
    else:
        st.warning("No existing TestRail test cases found for this story in RAG.")

# ── Tab 2: Missing Test Cases ─────────────────────────────────────────────────
with tab2:
    # Per-story session state keys
    state_key_cases    = f"gen_cases_{selected['key']}"
    state_key_selected = f"sel_cases_{selected['key']}"

    if state_key_cases not in st.session_state:
        st.session_state[state_key_cases]    = []
        st.session_state[state_key_selected] = []

    # Generate button
    if st.button("🤖 Generate Missing Test Cases", type="primary"):
        full_c   = get_story_full_content(selected["key"])
        ac_list  = extract_acceptance_criteria(full_c)
        ex_tcs   = get_existing_test_cases(selected["key"], selected["summary"])
        with st.spinner("Analyzing coverage gaps and generating test cases with GPT-4o…"):
            try:
                st.session_state[state_key_cases]    = generate_missing_test_cases(
                    selected["key"], selected["summary"], ac_list, ex_tcs
                )
                # Pre-select all by default
                st.session_state[state_key_selected] = list(
                    range(len(st.session_state[state_key_cases]))
                )
            except Exception as e:
                st.error(f"Generation failed: {e}")

    generated = st.session_state[state_key_cases]

    if generated:
        st.subheader(f"Generated {len(generated)} Missing Test Case(s)")
        st.caption("Check the boxes for test cases you want to export to TestRail:")

        selected_indices = []
        for i, tc in enumerate(generated):
            checked = st.checkbox(
                f"**{tc['title']}**",
                value=(i in st.session_state[state_key_selected]),
                key=f"chk_{selected['key']}_{i}",
            )
            if checked:
                selected_indices.append(i)
            with st.expander("View details", expanded=False):
                if tc.get("preconditions"):
                    st.markdown(f"**Preconditions:** {tc['preconditions']}")
                st.markdown(f"**Steps:**  \n{tc['steps']}")
                st.markdown(f"**Expected:** {tc['expected']}")

        st.session_state[state_key_selected] = selected_indices

        # ── Export section ────────────────────────────────────────────────────
        st.divider()
        st.subheader("📤 Export to TestRail")

        sections = get_testrail_sections()
        if sections:
            section_map  = {s["name"]: s["id"] for s in sections}
            section_name = st.selectbox("Select TestRail Section / Suite", list(section_map.keys()))
            section_id   = section_map[section_name]
        else:
            st.caption("Could not fetch sections — enter section ID manually.")
            section_id = st.number_input("TestRail Section ID", min_value=1, value=1, step=1)

        export_disabled = len(selected_indices) == 0
        if st.button(
            f"📤 Export {len(selected_indices)} Selected Test Case(s) to TestRail",
            disabled=export_disabled,
            type="primary",
        ):
            cases_to_export = [generated[i] for i in selected_indices]
            with st.spinner(f"Exporting {len(cases_to_export)} test case(s)…"):
                results = export_cases_to_testrail(cases_to_export, int(section_id))

            created = sum(1 for r in results if "✅" in r["status"])
            failed  = len(results) - created
            if created:
                st.success(f"✅ {created} test case(s) created in TestRail.")
            if failed:
                st.error(f"❌ {failed} test case(s) failed to export.")

            for r in results:
                tc_link = (
                    f"[C{r['id']}]({TESTRAIL_URL}/index.php?/cases/view/{r['id']})"
                    if r["id"] else ""
                )
                st.markdown(f"{r['status']} **{r['title']}** {tc_link}")
    else:
        st.info("Click **Generate Missing Test Cases** to analyse coverage gaps for this story.")
