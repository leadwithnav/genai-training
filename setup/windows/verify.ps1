$ErrorActionPreference = "Continue"

function Check-Tool {
    param (
        [string]$Name,
        [string]$Command,
        [string]$Args = "--version"
    )
    Write-Host "Checking $Name... " -NoNewline
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            $output = & $Command $Args 2>&1 | Select-Object -First 1
            Write-Host "OK ($output)" -ForegroundColor Green
        } else {
            Write-Host "NOT FOUND in PATH" -ForegroundColor Red
        }
    } catch {
        Write-Host "ERROR running command" -ForegroundColor Red
    }
}

Write-Host "`n=== GenAI Training Lab: Tool Verification ===`n" -ForegroundColor Cyan

# Core
Check-Tool "Node.js" "node" "-v"
Check-Tool "NPM" "npm" "-v"
Check-Tool "Git" "git" "--version"
Check-Tool "Python" "python" "--version"
Check-Tool "Java" "java" "-version"

# Docker
Write-Host "Checking Docker... " -NoNewline
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerInfo = docker info 2>$null
    if ($dockerInfo) {
        $ver = docker --version
        Write-Host "RUNNING ($ver)" -ForegroundColor Green
    } else {
        Write-Host "INSTALLED BUT NOT RUNNING (Is Docker Desktop started?)" -ForegroundColor Yellow
    }
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}

# New Tools
Check-Tool "Locust" "locust" "--version"
Check-Tool "Playwright" "npx" "playwright --version"
if (Test-Path "$env:LOCALAPPDATA\ms-playwright\chromium-*") {
    Write-Host "Playwright Chromium: OK" -ForegroundColor Green
} else {
    Write-Host "Playwright Chromium: NOT FOUND (Run install_tools.ps1)" -ForegroundColor Red
}

# JMeter (might not be in path yet if just installed)
Write-Host "Checking JMeter... " -NoNewline
if (Get-Command jmeter -ErrorAction SilentlyContinue) {
    Try {
        $ver = jmeter --version 2>&1 | Select-Object -First 1
        Write-Host "OK ($ver)" -ForegroundColor Green
    } Catch {
        Write-Host "INSTALLED (Error getting version)" -ForegroundColor Yellow
    }
} elseif (Test-Path "C:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat") {
    Write-Host "OK (Found at C:\Tools\apache-jmeter-5.6.3)" -ForegroundColor Green
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}

# Postman (App check)
Write-Host "Checking Postman... " -NoNewline
$postmanUser = "$env:LOCALAPPDATA\Postman\Postman.exe"
$postmanProgram = "$env:ProgramFiles\Postman\Postman.exe"
if (Test-Path $postmanUser) {
    Write-Host "OK (Found in User AppData)" -ForegroundColor Green
} elseif (Test-Path $postmanProgram) {
    Write-Host "OK (Found in Program Files)" -ForegroundColor Green
} else {
    Write-Host "NOT FOUND (Manual check required)" -ForegroundColor Yellow
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
