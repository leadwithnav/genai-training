import os
import requests
from typing import List, Dict

def ingest_testrail_cases() -> List[Dict]:
    """Fetch test cases from TestRail API."""
    base_url = os.getenv("TESTRAIL_URL")
    user = os.getenv("TESTRAIL_USER")
    token = os.getenv("TESTRAIL_TOKEN")
    project_id = os.getenv("TESTRAIL_PROJECT_ID")
    if not all([base_url, user, token, project_id]):
        raise ValueError("TESTRAIL_URL, TESTRAIL_USER, TESTRAIL_TOKEN, and TESTRAIL_PROJECT_ID must be set in .env")
    auth = (user, token)
    headers = {"Content-Type": "application/json"}
    url = f"{base_url}/index.php?/api/v2/get_cases/{project_id}"
    resp = requests.get(url, auth=auth, headers=headers)
    resp.raise_for_status()
    cases = resp.json().get('cases', resp.json())
    docs = []
    for case in cases:
        doc = {
            "id": f"testrail_{case.get('id')}",
            "content": f"Title: {case.get('title')}\nSection: {case.get('section_id')}\nSteps: {case.get('custom_steps', '')}",
            "source": "testrail"
        }
        docs.append(doc)
    return docs
