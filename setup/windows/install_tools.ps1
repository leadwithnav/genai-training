# Check for admin (Still good practice, though not strictly needed for user-scope installs like pip/npm)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Running as standard user. Some global installs might fail or require elevation."
}

$toolsDir = "C:\Tools"
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null }

# --- Ensure Package Manager (Chocolatey) ---
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Reload PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host " Chocolatey installed successfully." -ForegroundColor Green
    }
    else {
        Write-Warning " Failed to install Chocolatey. Manual installation required."
    }
}
else {
    Write-Host "Found Chocolatey." -ForegroundColor Green
}

function Install-Package {
    param (
        [string]$Name,
        [string]$WingetId,
        [string]$ChocoId,
        [string]$CommandCheck = $null
    )
    Write-Host "Checking $Name..." -NoNewline
    
    # 1. Check if binary is in PATH (Fastest)
    if ($CommandCheck -and (Get-Command $CommandCheck -ErrorAction SilentlyContinue)) {
        Write-Host " Already installed (Found '$CommandCheck' in PATH)." -ForegroundColor Green
        return
    }

    # 2. Try Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $list = winget list -e --id $WingetId 2>$null
        if ($list -match $WingetId) {
            Write-Host " Already installed (Winget)." -ForegroundColor Green
            return
        }
        Write-Host " Installing via Winget..." -ForegroundColor Yellow
        winget install -e --id $WingetId --accept-source-agreements --accept-package-agreements
        if ($?) { return }
    }

    # 3. Try Chocolatey (Fallback)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $list = choco list --local-only $ChocoId 2>$null
        if ($list -match $ChocoId) {
            Write-Host " Already installed (Chocolatey)." -ForegroundColor Green
            return
        }
        Write-Host " Installing via Chocolatey..." -ForegroundColor Yellow
        choco install $ChocoId -y
        return
    }

    Write-Warning " Could not install $Name (Winget/Choco not available or failed)."
}

# --- 0. Core Prerequisites ---
Install-Package "Git" "Git.Git" "git" "git"
Install-Package "Node.js (LTS)" "OpenJS.NodeJS.LTS" "nodejs-lts" "node"
Install-Package "Python 3.11" "Python.Python.3.11" "python" "python"
Install-Package "Java JDK 17" "EclipseAdoptium.Temurin.17.JDK" "temurin17" "java"
Install-Package "Docker Desktop" "Docker.DockerDesktop" "docker-desktop" "docker"
Install-Package "Postman" "Postman.Postman" "postman"

# Refresh Env (Attempt to reload PATH without restart if possible, mainly for current session)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# --- 1. Playwright (Node.js) ---
Write-Host "`nChecking Playwright..." -NoNewline
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmList = npm list -g @playwright/test 2>$null
    if ($npmList -match "@playwright/test") {
        Write-Host " Already installed." -ForegroundColor Green
    }
    else {
        Write-Host " Installing..." -ForegroundColor Yellow
        npm install -g @playwright/test
        Write-Host " Playwright installed." -ForegroundColor Green
    }
    
    # Install Browsers (Chromium)
    Write-Host " Installing Playwright browsers (Chromium)..." -ForegroundColor Yellow
    npx playwright install chromium
    Write-Host " Browsers installed." -ForegroundColor Green
}
else {
    Write-Warning " npm not found. Skipping Playwright."
}

# --- 2. Locust (Python) ---
Write-Host "`nChecking Locust..." -NoNewline
if (Get-Command pip -ErrorAction SilentlyContinue) {
    $null = pip show locust
    if ($LASTEXITCODE -eq 0) {
        Write-Host " Already installed." -ForegroundColor Green
    }
    else {
        Write-Host " Installing..." -ForegroundColor Yellow
        pip install locust
        Write-Host " Locust installed." -ForegroundColor Green
    }
}
else {
    Write-Warning " pip not found. Skipping Locust."
}

# --- 3. JMeter (Manual Download) ---
Write-Host "`nChecking JMeter..." -NoNewline
$jmeterHome = "$toolsDir\apache-jmeter-5.6.3"
if (Test-Path "$jmeterHome\bin\jmeter.bat") {
    Write-Host " Already installed at $jmeterHome" -ForegroundColor Green
}
else {
    Write-Host " Not found. Downloading..." -ForegroundColor Yellow
    $url = "https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.3.zip"
    $zipArgs = @{
        Uri     = $url
        OutFile = "$toolsDir\jmeter.zip"
    }
    Invoke-WebRequest @zipArgs
    
    Write-Host "Extracting..." -ForegroundColor Yellow
    Expand-Archive -Path "$toolsDir\jmeter.zip" -DestinationPath $toolsDir -Force
    Remove-Item "$toolsDir\jmeter.zip"
    
    Write-Host " JMeter installed to $jmeterHome" -ForegroundColor Green
    
    # Add to PATH (User scope)
    $oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($oldPath -notmatch "jmeter") {
        [Environment]::SetEnvironmentVariable("Path", "$oldPath;$jmeterHome\bin", "User")
        Write-Host " Added JMeter to User PATH." -ForegroundColor Cyan
    }
}

Write-Host "`n--- Setup Complete ---"
Write-Host "Please RESTART your terminal to use new tools (JMeter)." -ForegroundColor Cyan

