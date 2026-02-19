# Check for admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    exit
}

Write-Host "Checking for winget... " -NoNewline
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Found." -ForegroundColor Green
} else {
    Write-Host "Not found. Please update Windows App Installer from Microsoft Store." -ForegroundColor Red
    exit
}

function Install-If-Missing {
    param (
        [string]$Name,
        [string]$Id
    )
    Write-Host "Checking $Name..." -NoNewline
    $list = winget list -e --id $Id
    if ($list -match $Id) {
        Write-Host "Already installed." -ForegroundColor Green
    } else {
        Write-Host "Installing $Name..." -ForegroundColor Yellow
        winget install -e --id $Id --accept-source-agreements --accept-package-agreements
    }
}

# Core Tools
Install-If-Missing "Git" "Git.Git"
Install-If-Missing "Node.js LTS" "OpenJS.NodeJS.LTS"
Install-If-Missing "VS Code" "Microsoft.VisualStudioCode"
Install-If-Missing "Postman" "Postman.Postman"
Install-If-Missing "Python 3" "Python.Python.3.11"
Install-If-Missing "OpenJDK 17" "EclipseAdoptium.Temurin.17.JDK"

# Docker Desktop (Special Case)
Write-Host "Checking Docker Desktop..." -NoNewline
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Docker CLI found." -ForegroundColor Green
} else {
    Write-Host "Docker Desktop not found. Attempting install..." -ForegroundColor Yellow
    winget install -e --id Docker.DockerDesktop
    Write-Warning "After installation, please RESTART your computer and start Docker Desktop manually."
}

# Browsers
Install-If-Missing "Google Chrome" "Google.Chrome"

Write-Host "`nInstallation check complete. Please RESTART your terminal/computer to ensure PATH updates take effect." -ForegroundColor Cyan
