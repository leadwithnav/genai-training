$ErrorActionPreference = "Continue"

function Invoke-ToolCheck {
    param (
        [string]$Name,
        [string]$Command,
        [string]$ToolArgs = "--version"
    )
    Write-Host "Checking $Name... " -NoNewline
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            $output = & $Command $ToolArgs 2>&1 | Select-Object -First 1
            Write-Host "OK ($output)" -ForegroundColor Green
        }
        else {
            Write-Host "NOT FOUND in PATH" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "ERROR running command" -ForegroundColor Red
    }
}

Write-Host "`n=== GenAI Training Lab: Tool Verification ===`n" -ForegroundColor Cyan

# Core
Invoke-ToolCheck "Node.js" "node" "-v"
Invoke-ToolCheck "NPM" "npm" "-v"
Invoke-ToolCheck "Git" "git" "--version"
Invoke-ToolCheck "Python" "python" "--version"
Invoke-ToolCheck "Java" "java" "-version"

# Docker (Manual prereq — verify separately)
Write-Host "Checking Docker... " -NoNewline
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerInfo = docker info 2>$null
    if ($dockerInfo) {
        $ver = docker --version
        Write-Host "RUNNING ($ver)" -ForegroundColor Green
    }
    else {
        Write-Host "INSTALLED BUT NOT RUNNING (Please start Docker Desktop manually)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "NOT FOUND - Docker Desktop must be installed manually (see INSTALL_GUIDE.md Section 3)" -ForegroundColor Yellow
}

# New Tools
Invoke-ToolCheck "Locust" "locust" "--version"
Invoke-ToolCheck "Playwright" "npx" "playwright --version"
if (Test-Path "$env:LOCALAPPDATA\ms-playwright\chromium-*") {
    Write-Host "Playwright Chromium: OK" -ForegroundColor Green
}
else {
    Write-Host "Playwright Chromium: NOT FOUND (Run install_tools.ps1)" -ForegroundColor Red
}

# JMeter (might not be in path yet if just installed)
Write-Host "Checking JMeter... " -NoNewline
if (Get-Command jmeter -ErrorAction SilentlyContinue) {
    Try {
        $ver = jmeter --version 2>&1 | Select-Object -First 1
        Write-Host "OK ($ver)" -ForegroundColor Green
    }
    Catch {
        Write-Host "INSTALLED (Error getting version)" -ForegroundColor Yellow
    }
}
elseif (Test-Path "C:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat") {
    Write-Host "OK (Found at C:\Tools\apache-jmeter-5.6.3)" -ForegroundColor Green
}
else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}

# Postman (App check)
Write-Host "Checking Postman... " -NoNewline
$postmanUser = "$env:LOCALAPPDATA\Postman\Postman.exe"
$postmanProgram = "$env:ProgramFiles\Postman\Postman.exe"
if (Test-Path $postmanUser) {
    Write-Host "OK (Found in User AppData)" -ForegroundColor Green
}
elseif (Test-Path $postmanProgram) {
    Write-Host "OK (Found in Program Files)" -ForegroundColor Green
}
else {
    Write-Host "NOT FOUND (Manual check required)" -ForegroundColor Yellow
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
