Pre-requisites:
Python 3.8 or higher installed on your machine
pip install fastmcp
pip install testrail_api

MCP Server Configuration:
To enable the TestRail MCP Server, add the following configuration to your `mcp.json`

"testrail": {
            "command": "python",
            "args": [
                "C:/Users/Lenovo/.gemini/antigravity/scratch/genai_training/Labs/Lab5/testrail.py"
            ],
            "env": {
                "TESTRAIL_URL": "url of your testrail instance, e.g. https://yourdomain.testrail.io",
                "TESTRAIL_EMAIL": "email address associated with testrail account",
                "TESTRAIL_API_KEY": "api key generated from testrail for authentication"
            },
            "type": "stdio"
}





