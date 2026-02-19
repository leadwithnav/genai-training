$ErrorActionPreference = "Stop"

function Check-Tool {
    param (
        [string]$Name,
        [string]$Command,
        [string]$Args = "--version"
    )
    Write-Host "$Name..." -NoNewline
    try {
        $output = & $Command $Args 2>$null
        Write-Host " OK ($output)" -ForegroundColor Green
    } catch {
        Write-Host " MISSING" -ForegroundColor Red
    }
}

Write-Host "=== GenAI Training Lab: Verification ===`n"

Check-Tool "Node.js" "node" "-v"
Check-Tool "NPM" "npm" "-v"
Check-Tool "Git" "git" "--version"
Check-Tool "Python" "python" "--version"
Check-Tool "Java" "java" "-version"
Check-Tool "Google Chrome" "chrome" "--version" # might not be in path
Check-Tool "Edge" "msedge" "--version" # might not be in path

Write-Host "Docker..." -NoNewline
try {
    $output = docker info 2>$null
    if ($output) {
        Write-Host " RUNNING" -ForegroundColor Green
    } else {
        throw "Failed"
    }
} catch {
    Write-Host " NOT RUNNING / MISSING" -ForegroundColor Red
    Write-Warning "Ensure Docker Desktop is started."
}

Write-Host "`n=== Verification Complete ==="
Pause
