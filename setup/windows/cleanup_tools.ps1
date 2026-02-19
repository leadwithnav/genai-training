# Check for admin (Recommended for file deletions in C:\Tools)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Running as standard user. File deletion in C:\Tools might fail."
}

$toolsDir = "C:\Tools"
$jmeterDir = "$toolsDir\apache-jmeter-5.6.3"

Write-Host "=== GenAI Training Lab: Cleanup Tools ===`n" -ForegroundColor Cyan

# --- 1. Playwright (Node.js) ---
Write-Host "Cleaning up Playwright..." -ForegroundColor Yellow
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host " Uninstalling global @playwright/test..."
    try {
        npm uninstall -g @playwright/test | Out-Null
        Write-Host " Removed global package." -ForegroundColor Green
    }
    catch {
        Write-Warning " Failed to uninstall global package: $_"
    }

    # Remove browser binaries
    $playwrightCache = "$env:LOCALAPPDATA\ms-playwright"
    if (Test-Path $playwrightCache) {
        Write-Host " Removing Playwright browser binaries..."
        try {
            Remove-Item -Path $playwrightCache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " Removed $playwrightCache" -ForegroundColor Green
        }
        catch {
            Write-Warning " Could not remove Playwright cache: $_"
        }
    }
}
else {
    Write-Warning " npm not found. Skipping Playwright cleanup."
}

# --- 2. Locust (Python) ---
Write-Host "`nCleaning up Locust..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host " Uninstalling locust..."
    try {
        pip uninstall -y locust | Out-Null
        Write-Host " Removed locust package." -ForegroundColor Green
    }
    catch {
        Write-Warning " Failed to uninstall locust: $_"
    }
}
else {
    Write-Warning " pip not found. Skipping Locust cleanup."
}

# --- 3. JMeter (Files & Path) ---
Write-Host "`nCleaning up JMeter..." -ForegroundColor Yellow

# Remove Files
if (Test-Path $jmeterDir) {
    Write-Host " Removing JMeter directory: $jmeterDir"
    try {
        Remove-Item -Path $jmeterDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host " Directory removed." -ForegroundColor Green
    }
    catch {
        Write-Warning " Failed to remove directory (might be in use?): $_"
    }
}
else {
    Write-Host " JMeter directory not found." -ForegroundColor DarkGray
}

# Remove from PATH (User scope)
$jmeterBin = "$jmeterDir\bin"
try {
    $currentPathRaw = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPathRaw -like "*$jmeterBin*") {
        Write-Host " Removing JMeter from User PATH..."
        # Split, filter, join to cleanly remove the entry
        $pathParts = $currentPathRaw -split ';'
        $newPathParts = $pathParts | Where-Object { $_ -ne $jmeterBin }
        $newPath = $newPathParts -join ';'
        
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host " PATH updated." -ForegroundColor Green
    }
    else {
        Write-Host " JMeter not found in User PATH." -ForegroundColor DarkGray
    }
}
catch {
    Write-Warning " Failed to update PATH: $_"
}

# --- 4. Core Tools (Optional & Dangerous) ---
Write-Host "`n--- Core Tools Cleanup (Git, Node, Python, Java, Docker) ---" -ForegroundColor Red
Write-Host "WARNING: This will UNINSTALL these tools from your system via Winget." -ForegroundColor Red
Write-Host "This affects your ENTIRE machine, not just this lab." -ForegroundColor Red
$confirm = Read-Host "Do you want to proceed with Core Tools uninstall? (type 'YES' to confirm)"

if ($confirm -eq 'YES') {
    function Uninstall-Winget {
        param ([string]$Id, [string]$Name)
        Write-Host "Uninstalling $Name..." -NoNewline
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget uninstall --id $Id --accept-source-agreements
            Write-Host " Done (Check output above)." -ForegroundColor Yellow
        }
        else {
            Write-Warning " Winget not found."
        }
    }

    Uninstall-Winget "Git.Git" "Git"
    Uninstall-Winget "OpenJS.NodeJS.LTS" "Node.js"
    Uninstall-Winget "Python.Python.3.11" "Python 3.11"
    Uninstall-Winget "EclipseAdoptium.Temurin.17.JDK" "Java JDK 17"
    Uninstall-Winget "Docker.DockerDesktop" "Docker Desktop"
}
else {
    Write-Host "Skipping Core Tools cleanup." -ForegroundColor Green
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Cyan
