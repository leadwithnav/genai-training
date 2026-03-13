step 1: Run Jenkins
cd jenkins 
docker-compose up -d --build

step 2: Wait for Jenkins to initialize

step 3: Access Jenkins
Open localhost:8080 in your browser.

Step 5: Get Jenkins Crumb
http://localhost:8080/crumbIssuer/api/json

Step 6: Create Jenkins API Token
- Go to Jenkins dashboard
- Click on your username (top right) > Configure
- Under API Token section, click "Add new Token"
- Name it "
- lab14-token" and click "Generate"
- Copy the generated token for later use

Step 7: Create New Pipeline Job
- On Jenkins dashboard, click "New Item"
- Enter "lab14-pipeline" as the name
- Select "Pipeline" and click "OK"
- Scroll down to "Pipeline" section
- In "Definition" dropdown, select "Pipeline script"
- In the script box, enter the following pipeline code:
 C:\Users\Lenovo\.gemini\antigravity\scratch\genai_training\jenkins\Jenkinsfile
- Click "Save"

Step 8: Run the Pipeline
- On the job page, click "Build Now"


Step 9: Setup Jenkins MCP Plugin
- Go to Jenkins dashboard > Manage Jenkins > Manage Plugins
- Click on "Available" tab and search for "MCP"
- Check the box next to "MCP Plugin" and click "Install without restart"
- Wait for the plugin to install

Step 10: Add MCP Server to mcp.json
"jenkins": {
        "type": "sse",
        "url": "http://localhost:8080/mcp-server/sse",
        "headers": {
          "Authorization": "Basic YWRtaW46MmJkZjg1ZjcwYTBlYmQ2NWVkODFmMDM3OTc0NDU4YzE=",
		  "Jenkins-Crumb": "8aa2c57bc73ac67da40adf5559b1c440f26cf38afc056dbc4682268b2e419f0c"
        }
      }
- The Authorization header value is the Base64 encoding of "admin:lab14-token" (username:token)}
- The Jenkins-Crumb value can be obtained from the Jenkins Crumb API in Step 5

Step 11: Test MCP Integration
- Open Github Copilot chat and check the tools
- You should see Jenkins listed as a tool and be able to trigger pipeline runs from the chat interface.
- run below prompt in the chat to trigger the pipeline:
``` run new build for lab14-pipeline```

- run below prompt to check the status of the latest build:
``` get latest build status for lab14-pipeline```





