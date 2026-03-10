import os
import requests
from typing import List, Dict

def fetch_jira_issues() -> List[Dict]:
    """Fetch issues from Jira API. Requires JIRA_URL, JIRA_USER, JIRA_TOKEN env vars."""
    jira_url = os.getenv("JIRA_URL")
    jira_user = os.getenv("JIRA_USER")
    jira_token = os.getenv("JIRA_TOKEN")
    project_name = os.getenv("PROJECT_NAME")
    if not all([jira_url, jira_user, jira_token, project_name]):
        raise ValueError("JIRA_URL, JIRA_USER, JIRA_TOKEN, and PROJECT_NAME must be set as environment variables.")

    import json
    api_url = f"{jira_url}/rest/api/3/search/jql"
    auth = (jira_user, jira_token)
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    data = {
        "jql": f"project={project_name}",
        "fields": ["summary", "description", "issuetype"]
    }
    response = requests.post(api_url, auth=auth, headers=headers, data=json.dumps(data))
    response.raise_for_status()
    result = response.json()
    # Debug: print the result structure
    import pprint
    print("Jira API result keys:", result.keys())
    print("First issue full structure:")
    pprint.pprint(result.get("issues", [{}])[0])
    issues = result.get("issues", [])
    docs = []
    def extract_adf_text(adf):
        # Recursively extract text from Atlassian Document Format (ADF)
        if not adf:
            return ""
        if isinstance(adf, str):
            return adf
        if isinstance(adf, dict):
            if adf.get('type') == 'text':
                return adf.get('text', '')
            text = ''
            for v in adf.values():
                text += extract_adf_text(v)
            return text
        if isinstance(adf, list):
            return ' '.join(extract_adf_text(i) for i in adf)
        return ""

    for issue in issues:
        print("Processing issue:", issue)
        fields = issue.get("fields", {})
        description_adf = fields.get("description", "")
        description_text = extract_adf_text(description_adf)
        doc = {
            "id": issue.get("key", "unknown"),
            "summary": fields.get("summary", ""),
            "description": description_text,
            "type": fields.get("issuetype", {}).get("name", "")
        }
        docs.append(doc)
    return docs
