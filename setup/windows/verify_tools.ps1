# =============================================================================
# verify_tools.ps1
# GenAI Training Lab - Tool Verification Script
#
# Simple, reliable check: run each tool's version command and check exit code.
# If a tool responds, it's installed AND usable. That's what matters.
#
# Compatible: Windows PowerShell 5.1+, Windows 10/11
# =============================================================================

$ErrorActionPreference = "Continue"
$allGood = $true

# ── Core check function ────────────────────────────────────────────────────────
# Runs a command with given args, prints OK + first output line, or NOT FOUND.
# Uses $ArgList (never $Args - reserved PS automatic variable).
function Test-Tool {
    param(
        [string]   $Name,
        [string]   $Cmd,
        [string[]] $ArgList = @("--version"),
        [string]   $Note = ""         # Optional extra context shown on failure
    )
    Write-Host "Checking $Name...".PadRight(32) -NoNewline
    $found = Get-Command $Cmd -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-Host "NOT FOUND" -ForegroundColor Red
        if ($Note) { Write-Host "  ^ $Note" -ForegroundColor DarkYellow }
        return $false
    }
    try {
        $out = & $Cmd $ArgList 2>&1 | Select-Object -First 1
        Write-Host "OK  $out" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR running '$Cmd'" -ForegroundColor Red
        return $false
    }
}

# ==============================================================================
Write-Host ""
Write-Host "=== GenAI Training Lab: Tool Verification ===" -ForegroundColor Cyan
Write-Host ""

# ── Git ───────────────────────────────────────────────────────────────────────
if (-not (Test-Tool "Git"     "git"    @("--version"))) { $allGood = $false }

# ── Node.js ───────────────────────────────────────────────────────────────────
if (-not (Test-Tool "Node.js" "node"   @("--version"))) { $allGood = $false }

# ── NPM (bundled with Node) ───────────────────────────────────────────────────
if (-not (Test-Tool "NPM"     "npm"    @("--version"))) { $allGood = $false }

# ── Python ────────────────────────────────────────────────────────────────────
if (-not (Test-Tool "Python"  "python" @("--version"))) { $allGood = $false }

# ── Java ─────────────────────────────────────────────────────────────────────
# java -version outputs to STDERR - 2>&1 redirects it to stdout for capture
Write-Host "Checking Java...".PadRight(32) -NoNewline
if (Get-Command java -ErrorAction SilentlyContinue) {
    $ver = java -version 2>&1 | Select-Object -First 1
    Write-Host "OK  $ver" -ForegroundColor Green
}
else {
    Write-Host "NOT FOUND" -ForegroundColor Red
    $allGood = $false
}

# ── Docker ────────────────────────────────────────────────────────────────────
Write-Host "Checking Docker...".PadRight(32) -NoNewline
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $ver = docker --version 2>&1 | Select-Object -First 1
    # Also check if the daemon is running
    $daemonRunning = docker info 2>$null
    if ($daemonRunning) {
        Write-Host "OK  $ver  [daemon running]" -ForegroundColor Green
    }
    else {
        Write-Host "INSTALLED but daemon not running" -ForegroundColor Yellow
        Write-Host "  ^ Please start Docker Desktop manually." -ForegroundColor DarkYellow
    }
}
else {
    Write-Host "NOT FOUND - install Docker Desktop manually (see INSTALL_GUIDE.md)" -ForegroundColor Yellow
}

# ── Postman ───────────────────────────────────────────────────────────────────
# Postman is a GUI app with no CLI - check for the executable instead
Write-Host "Checking Postman...".PadRight(32) -NoNewline
$postmanExe = Get-ChildItem @(
    "$env:LOCALAPPDATA\Postman\Postman.exe",
    "$env:LOCALAPPDATA\Postman\app-*\Postman.exe",
    "$env:ProgramFiles\Postman\Postman.exe",
    "$env:ProgramFiles\Postman\app-*\Postman.exe"
) -ErrorAction SilentlyContinue | Select-Object -First 1

if ($postmanExe) {
    Write-Host "OK  (found at $($postmanExe.FullName))" -ForegroundColor Green
}
else {
    Write-Host "NOT FOUND" -ForegroundColor Red
    Write-Host "  ^ Install from https://www.postman.com/downloads/" -ForegroundColor DarkYellow
    $allGood = $false
}

# ── Locust ────────────────────────────────────────────────────────────────────
# Locust is a Python pip package - may be 'locust' CLI or 'python -m locust'
Write-Host "Checking Locust...".PadRight(32) -NoNewline
if (Get-Command locust -ErrorAction SilentlyContinue) {
    $ver = locust --version 2>&1 | Select-Object -First 1
    Write-Host "OK  $ver" -ForegroundColor Green
}
elseif (Get-Command python -ErrorAction SilentlyContinue) {
    python -m locust --version 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ver = [string](python -m locust --version 2>&1 | Select-Object -First 1)
        Write-Host "OK  $ver  [via python -m locust]" -ForegroundColor Green
    }
    else {
        Write-Host "NOT FOUND  (pip install locust)" -ForegroundColor Red
        $allGood = $false
    }
}
else {
    Write-Host "NOT FOUND  (Python not found either)" -ForegroundColor Red
    $allGood = $false
}

# ── Playwright ────────────────────────────────────────────────────────────────
# 'npm install -g @playwright/test' places a 'playwright' binary in npm global bin.
# Check that binary directly - NOT 'npx playwright' (which looks for a different package).
Write-Host "Checking Playwright...".PadRight(32) -NoNewline
$pwFound = $false
$pwVer = ""

# Layer 1: 'playwright' binary in PATH (most reliable after global npm install)
if (Get-Command playwright -ErrorAction SilentlyContinue) {
    $pwVer = [string](playwright --version 2>&1 | Select-Object -First 1)
    $pwFound = $true
}
# Layer 2: npm list -g confirms @playwright/test is installed globally
elseif (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmOut = npm list -g @playwright/test --depth=0 2>&1
    if ($npmOut -match "@playwright") {
        # Extract version from output like: +-- @playwright/test@1.40.0
        $pwVer = [string]($npmOut | Select-String "@playwright/test@" | Select-Object -First 1)
        $pwFound = $true
    }
}
# Layer 3: Try npx with explicit package name as last resort
if (-not $pwFound -and (Get-Command npx -ErrorAction SilentlyContinue)) {
    $npxOut = npx --yes @playwright/test --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0 -and $npxOut) {
        $pwVer = [string]$npxOut
        $pwFound = $true
    }
}

if ($pwFound) {
    Write-Host "OK  $pwVer" -ForegroundColor Green
}
else {
    Write-Host "NOT FOUND  (run: npm install -g @playwright/test)" -ForegroundColor Red
    $allGood = $false
}

# Playwright Chromium browser (separate binary from the npm package)
Write-Host "Checking Playwright Chromium...".PadRight(32) -NoNewline
$chromiumDir = Get-ChildItem "$env:LOCALAPPDATA\ms-playwright\chromium-*" `
    -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($chromiumDir) {
    Write-Host "OK  ($($chromiumDir.Name))" -ForegroundColor Green
}
else {
    Write-Host "NOT FOUND  (npx playwright install chromium)" -ForegroundColor Red
    $allGood = $false
}

# ── JMeter ────────────────────────────────────────────────────────────────────
# JMeter -v outputs version to stderr; some versions return non-zero exit code
Write-Host "Checking JMeter...".PadRight(32) -NoNewline
if (Get-Command jmeter -ErrorAction SilentlyContinue) {
    $ver = jmeter -v 2>&1 | Select-Object -First 1
    Write-Host "OK  $ver" -ForegroundColor Green
}
else {
    # jmeter.bat may exist but not in PATH - check common locations
    $jmeterBat = Get-ChildItem @(
        "C:\Tools\apache-jmeter-*\bin\jmeter.bat",
        "C:\Program Files\apache-jmeter-*\bin\jmeter.bat",
        "C:\ProgramData\chocolatey\lib\jmeter\tools\apache-jmeter-*\bin\jmeter.bat",
        "D:\Tools\apache-jmeter-*\bin\jmeter.bat"
    ) -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($jmeterBat) {
        Write-Host "FOUND but not in PATH ($($jmeterBat.FullName))" -ForegroundColor Yellow
        Write-Host "  ^ Add $($jmeterBat.Directory) to your PATH to use 'jmeter' from terminal." -ForegroundColor DarkYellow
    }
    else {
        Write-Host "NOT FOUND" -ForegroundColor Red
        $allGood = $false
    }
}

# ==============================================================================
Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "All tools are installed and ready!" -ForegroundColor Green
}
else {
    Write-Host "Some tools are missing. Run .\install_tools.ps1 to install them." -ForegroundColor Yellow
}
Write-Host ""
