# Windows Setup Guide for GenAI Tester Course

Welcome! Follow these steps to set up your environment for the course.

## 1. Prerequisites
Ensure you have administrative privileges on your Windows machine.
PowerShell should be available (standard on Windows 10/11).

## 2. Automated Setup (Recommended)
We have provided PowerShell scripts to help you install the necessary tools.
Open PowerShell as Administrator and run the following commands:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
cd .\setup\windows
.\install_tools.ps1
```

This script will attempt to install:
- Node.js (LTS)
- Git
- Postman
- Python
- OpenJDK (for JMeter)
- JMeter
- Playwright
- Locust

> ⚠️ **Docker Desktop** and **VS Code** must be installed **manually** before running this script. See `setup/INSTALL_GUIDE.md` for instructions.

## 3. Verify Installation
After running the installer or installing manually, run the verification script:

```powershell
.\verify_tools.ps1
```

It should report "OK" for all tools. If any are missing, please install them manually using the links below.

## 4. Manual Installation Links
If the script fails, download and install these tools:

- **Docker Desktop**: https://www.docker.com/products/docker-desktop/
- **Node.js LTS**: https://nodejs.org/
- **VS Code**: https://code.visualstudio.com/
- **Git**: https://git-scm.com/download/win
- **Postman**: https://www.postman.com/downloads/
- **Python**: https://www.python.org/downloads/
- **Java (JDK 17+)**: https://adoptium.net/
- **JMeter**: https://jmeter.apache.org/download_jmeter.cgi (Requires Java)

## 5. Starting the System
Once everything is installed:

1. Open VS Code in the project root.
2. Open a terminal.
3. Run: `docker compose up -d --build`
4. Visit `http://localhost:3000` to see the app.
