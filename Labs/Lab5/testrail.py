from fastmcp import FastMCP
from testrail_api import TestRailAPI
import os
import re

# Initialize the MCP Server
mcp = FastMCP("testrail-server")

# Helper to get client
def get_client() -> TestRailAPI:
    url = os.environ.get("TESTRAIL_URL")
    email = os.environ.get("TESTRAIL_EMAIL") 
    key = os.environ.get("TESTRAIL_API_KEY")
    if not all([url, email, key]):
        raise ValueError("Missing TESTRAIL_URL, TESTRAIL_EMAIL, or TESTRAIL_API_KEY")
    return TestRailAPI(url, email, key)

@mcp.tool()
def get_test_case(case_id: int) -> str:
    """Fetch details for a specific test case by ID"""
    try:
        client = get_client()
        case = client.cases.get_case(case_id)
        # Custom steps field might vary by instance, often 'custom_steps_separated'
        steps = case.get('custom_steps_separated', [])
        if not steps and 'custom_steps' in case:
             steps = case['custom_steps']
             
        step_text = ""
        if isinstance(steps, list):
            for i, step in enumerate(steps, 1):
                content = step.get('content', '')
                expected = step.get('expected', '')
                step_text += f"\n{i}. {content}\n   Expected: {expected}"
        else:
            step_text = str(steps)

        return f"Case C{case['id']}: {case['title']}\nSteps:{step_text}"
    except Exception as e:
        return f"Error fetching case {case_id}: {str(e)}"


if __name__ == "__main__":
    mcp.run()
