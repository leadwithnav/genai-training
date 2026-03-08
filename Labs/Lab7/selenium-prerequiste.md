## Selenium Setup Prerequisites

Follow these step-by-step instructions to set up Selenium for JavaScript/TypeScript and Python projects.

---

### 1. Prerequisites (All Languages)

1. **Install Java:**
	- Download and install the latest version of Java (JDK).
	- [Download Java JDK](https://adoptium.net/)
2. **Set JAVA_HOME Environment Variable:**
	- Ensure the `JAVA_HOME` environment variable is set to your JDK installation path.
	- Add `%JAVA_HOME%/bin` to your system `PATH`.
3. **Install Chrome Browser:**
	- Make sure Google Chrome is installed on your system.
4. **Download ChromeDriver:**
	- Download the latest stable ChromeDriver from [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/#stable).
	- Extract and add the ChromeDriver executable to your system `PATH`.
	- To verify, run `chromedriver --version` in your terminal.

---

### 2. For JavaScript/TypeScript Projects

1. **Install Selenium WebDriver:**
	```sh
	npm install selenium-webdriver
	```
2. **Install Selenium SDK via MCP:**
	If your project uses the MCP Selenium SDK, add the following to your `package.json` scripts or run with npx:
	```json
	"selenium": {
	  "command": "npx",
	  "args": ["-y", "@angiejones/mcp-selenium@latest"]
	}
	```

---

### 3. For Python Projects

1. **Install Selenium:**
	```sh
	pip install selenium
	```

---

### 4. Verification

1. **Verify Java Installation:**
	```sh
	java -version
	echo %JAVA_HOME%
	```
2. **Verify ChromeDriver:**
	```sh
	chromedriver --version
	```
3. **Verify Selenium Installation:**
	- For Node.js: `npm list selenium-webdriver`
	- For Python: `pip show selenium`

---

**Troubleshooting Tips:**
- Ensure all environment variables are set and terminals are restarted after changes.
- If ChromeDriver is not recognized, check your `PATH` variable.
- For more details, refer to the [official Selenium documentation](https://www.selenium.dev/documentation/).
