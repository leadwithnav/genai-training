# =============================================================================
# install_tools.ps1
# GenAI Training Lab - Tool Installation Script
#
# Usage:
#   .\install_tools.ps1                   # Install everything
#   .\install_tools.ps1 -InstallOnly Git  # Install one tool only
#
# Strategy per tool:
#   DETECT : PATH → Registry → Env Vars → Filesystem glob  (via tool_helpers.ps1)
#   INSTALL: winget → chocolatey → direct download          (in fallback order)
#
# Compatible: Windows PowerShell 5.1+, Windows 10/11
# =============================================================================

param([string]$InstallOnly = "All")

# Admin check - informational, not blocking
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Warning "Running as standard user. Some system-wide installs may require elevation."
}

# Ensure C:\Tools exists (used for JMeter manual download)
$toolsDir = "C:\Tools"
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null }

# ── Dot-source shared helpers ──────────────────────────────────────────────────
$helpersPath = Join-Path $PSScriptRoot "tool_helpers.ps1"
if (-not (Test-Path $helpersPath)) {
    Write-Error "tool_helpers.ps1 not found at '$helpersPath'. Please place it alongside this script."
    exit 1
}
. $helpersPath
$configs = Get-ToolConfigs

# ── Helper: Initialize Chocolatey (only if needed) ────────────────────────────
function Initialize-Chocolatey {
    # Check 1: already in PATH
    if (Get-Command choco -ErrorAction SilentlyContinue) { return $true }

    # Check 2: installed at known locations but not in PATH - auto-add to session PATH
    $knownPaths = @(
        "C:\ProgramData\chocolatey\bin\choco.exe",
        "C:\chocolatey\bin\choco.exe"
    )
    foreach ($p in $knownPaths) {
        if (Test-Path $p) {
            Write-Host "  Chocolatey found at '$p' - adding to session PATH." -ForegroundColor DarkGray
            Add-ToSessionPath (Split-Path $p -Parent)
            return $true
        }
    }

    # Check 3: chocolatey folder exists but binary is missing (broken/partial install)
    # Do NOT run the installer - it will throw 'existing installation detected'.
    if (Test-Path "C:\ProgramData\chocolatey") {
        Write-Host "  Chocolatey folder exists but choco.exe not found (broken install) - skipping." -ForegroundColor DarkGray
        return $false
    }

    # Not found anywhere - attempt fresh install (requires admin rights)
    Write-Host "  Chocolatey not found. Attempting to install..." -ForegroundColor DarkGray

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Host "  Chocolatey needs Administrator rights - skipping." -ForegroundColor DarkYellow
        return $false
    }
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Refresh-EnvPath
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "  Chocolatey installed." -ForegroundColor Green
            return $true
        }
    }
    catch { Write-Host "  Chocolatey install failed: $_" -ForegroundColor DarkYellow }
    return $false
}

# ── Helper: Install via winget → choco → fallback ────────────────────────────
function Install-WithFallback {
    param(
        [string]$Name,
        [string]$WingetId,
        [string]$ChocoId
    )
    # 1. Winget (preferred - idempotent, handles "already installed" natively)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  Installing $Name via Winget..." -ForegroundColor Yellow
        winget install -e --id $WingetId --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Refresh-EnvPath
            return $true
        }
        Write-Host "  Winget returned exit code $LASTEXITCODE. Trying Chocolatey..." -ForegroundColor DarkGray
    }
    else {
        Write-Host "  Winget not available. Trying Chocolatey..." -ForegroundColor DarkGray
    }

    # 2. Chocolatey fallback (idempotent - skips if already installed)
    if ($ChocoId -and (Initialize-Chocolatey)) {
        Write-Host "  Installing $Name via Chocolatey..." -ForegroundColor Yellow
        choco install $ChocoId -y
        if ($?) {
            Refresh-EnvPath
            return $true
        }
    }

    # Both package managers failed - caller should try a direct download fallback
    Write-Host "  Package managers unavailable for $Name." -ForegroundColor DarkYellow
    return $false
}

# ── Helper: Detect then install a standard tool ──────────────────────────────
function Ensure-Tool {
    param(
        [string]$DisplayName,
        [hashtable]$Config,
        [string]$WingetId,
        [string]$ChocoId
    )
    Write-Host "`nChecking $DisplayName..." -NoNewline

    # ── Layer 0: Run the CLI command - fastest and most definitive check ───────
    # If the tool responds to its version/help flag it is installed AND usable.
    # NOTE: Use $ArgList not $Args - $Args is a reserved PS automatic variable.
    if ($Config.CommandName -and $Config.CliArgs.Count -gt 0) {
        $cmdFound = Get-Command $Config.CommandName -ErrorAction SilentlyContinue
        if ($cmdFound) {
            try {
                $ArgList = $Config.CliArgs
                $out = & $Config.CommandName $ArgList 2>&1 | Select-Object -First 1
                if ($LASTEXITCODE -eq 0 -or $out) {
                    Write-Host " Already installed. [via CLI: $($Config.CommandName) $($Config.CliArgs -join ' ')]" -ForegroundColor Green
                    return $true
                }
            }
            catch { }
        }
    }

    # ── Layers 1-4: PATH / Registry / Env Vars / Filesystem ──────────────────
    # Called only when the CLI check above found nothing (tool not in PATH,
    # or PATH is broken, or tool has no CLI like Postman).
    $result = Find-InstalledTool `
        -ToolName      $DisplayName `
        -CommandName   $Config.CommandName `
        -RegistryNames $Config.RegistryNames `
        -ExeSubPath    $Config.ExeSubPath `
        -EnvVars       $Config.EnvVars `
        -FsGlobs       $Config.FsGlobs

    if ($result.Found) {
        Write-Host " Already installed. [Source: $($result.Source)]" -ForegroundColor Green
        return $true
    }

    Write-Host " Not found. Installing..." -ForegroundColor Yellow
    return (Install-WithFallback -Name $DisplayName -WingetId $WingetId -ChocoId $ChocoId)
}


# ==============================================================================
# TOOL INSTALLATIONS
# ==============================================================================

Write-Host "`n=== GenAI Training Lab: Tool Installation ===" -ForegroundColor Cyan

# ── Git ───────────────────────────────────────────────────────────────────────
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Git") {
    $gitInstalled = Ensure-Tool "Git" $configs["Git"] "Git.Git" "git"
    if (-not $gitInstalled) {
        Write-Host "  Trying direct Git download as last resort..." -ForegroundColor Cyan
        $gitExe = "$env:TEMP\GitSetup.exe"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $release = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest" -ErrorAction Stop
            $asset = $release.assets | Where-Object { $_.name -match "64-bit\.exe$" } | Select-Object -First 1
            $gitUrl = $asset.browser_download_url
            $gitVer = $release.tag_name
            Write-Host "  Downloading Git $gitVer..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $gitUrl -OutFile $gitExe -ErrorAction Stop
            Write-Host "  Installing Git silently..." -ForegroundColor Yellow
            Start-Process $gitExe -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=icons,ext,ext\reg,ext\reg\shellhere,assoc,assoc_sh" -Wait
            Remove-Item $gitExe -Force -ErrorAction SilentlyContinue
            Refresh-EnvPath
            if (Get-Command git -ErrorAction SilentlyContinue) {
                Write-Host "  Git installed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "  Git installer ran but 'git' not yet in PATH. Open a new terminal." -ForegroundColor DarkYellow
            }
        }
        catch {
            Write-Host "  Direct Git download failed: $_" -ForegroundColor DarkYellow
            Write-Host "  Please install manually from https://git-scm.com/download/win" -ForegroundColor DarkYellow
        }
    }
}

# ── Node.js ──────────────────────────────────────────────────────────────────
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Node.js") {
    $nodeInstalled = Ensure-Tool "Node.js (LTS)" $configs["Node.js"] "OpenJS.NodeJS.LTS" "nodejs-lts"
    if (-not $nodeInstalled) {
        # Direct .msi download fallback when winget and choco both unavailable
        Write-Host "  Trying direct Node.js download as last resort..." -ForegroundColor Cyan
        $nodeMsi = "$env:TEMP\NodeSetup.msi"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            # Fetch the current LTS version number from nodejs.org
            $nodeIndex = Invoke-RestMethod "https://nodejs.org/dist/index.json" -ErrorAction Stop
            $lts = $nodeIndex | Where-Object { $_.lts } | Select-Object -First 1
            $nodeVersion = $lts.version
            $nodeMsiUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-x64.msi"
            Write-Host "  Downloading Node.js $nodeVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $nodeMsiUrl -OutFile $nodeMsi -ErrorAction Stop
            Write-Host "  Installing Node.js (requires elevation prompt)..." -ForegroundColor Yellow
            Start-Process msiexec.exe -ArgumentList "/i `"$nodeMsi`" /qn" -Wait -Verb RunAs
            Remove-Item $nodeMsi -Force -ErrorAction SilentlyContinue
            Refresh-EnvPath
            if (Get-Command node -ErrorAction SilentlyContinue) {
                Write-Host "  Node.js installed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "  Node.js MSI ran but 'node' not yet in PATH. Open a new terminal." -ForegroundColor DarkYellow
            }
        }
        catch {
            Write-Host "  Direct Node.js download failed: $_" -ForegroundColor DarkYellow
            Write-Host "  Please install manually from https://nodejs.org/en/download/" -ForegroundColor DarkYellow
        }
    }
}

# ── Python ───────────────────────────────────────────────────────────────────
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Python") {
    $pyInstalled = Ensure-Tool "Python 3.11" $configs["Python"] "Python.Python.3.11" "python"
    if (-not $pyInstalled) {
        Write-Host "  Trying direct Python 3.11 download as last resort..." -ForegroundColor Cyan
        $pyExe = "$env:TEMP\Python311Setup.exe"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            # Python.org latest 3.11.x - fetch to avoid hardcoding a patch version
            $pyRelPage = Invoke-RestMethod "https://www.python.org/downloads/release/python-3119/" -ErrorAction Stop
            $pyUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
            Write-Host "  Downloading Python 3.11.9..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $pyUrl -OutFile $pyExe -ErrorAction Stop
            Write-Host "  Installing Python silently (adds to PATH)..." -ForegroundColor Yellow
            Start-Process $pyExe -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait -Verb RunAs
            Remove-Item $pyExe -Force -ErrorAction SilentlyContinue
            Refresh-EnvPath
            if (Get-Command python -ErrorAction SilentlyContinue) {
                Write-Host "  Python installed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "  Python installer ran but 'python' not yet in PATH. Open a new terminal." -ForegroundColor DarkYellow
            }
        }
        catch {
            Write-Host "  Direct Python download failed: $_" -ForegroundColor DarkYellow
            Write-Host "  Please install manually from https://www.python.org/downloads/" -ForegroundColor DarkYellow
        }
    }
}

# ── Java JDK ─────────────────────────────────────────────────────────────────
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Java") {
    $javaInstalled = Ensure-Tool "Java JDK 17" $configs["Java"] "EclipseAdoptium.Temurin.17.JDK" "temurin17"
    if (-not $javaInstalled) {
        # Direct MSI download from Adoptium API - same pattern as Node.js fallback
        Write-Host "  Trying direct Temurin JDK 17 download as last resort..." -ForegroundColor Cyan
        $javaMsi = "$env:TEMP\TemurinJDK17.msi"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            # Adoptium API returns latest JDK 17 asset metadata
            $apiUrl = "https://api.adoptium.net/v3/assets/latest/17/hotspot?os=windows&architecture=x64&image_type=jdk"
            $assets = Invoke-RestMethod $apiUrl -ErrorAction Stop
            $msiAsset = $assets[0].binary.installer
            $javaUrl = $msiAsset.link
            $javaVer = $assets[0].version.semver
            Write-Host "  Downloading Temurin JDK $javaVer..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $javaUrl -OutFile $javaMsi -ErrorAction Stop
            Write-Host "  Installing JDK (requires elevation prompt)..." -ForegroundColor Yellow
            Start-Process msiexec.exe -ArgumentList "/i `"$javaMsi`" /qn ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome" -Wait -Verb RunAs
            Remove-Item $javaMsi -Force -ErrorAction SilentlyContinue
            Refresh-EnvPath
            if (Get-Command java -ErrorAction SilentlyContinue) {
                Write-Host "  Java JDK installed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "  JDK MSI ran but 'java' not yet in PATH. Open a new terminal." -ForegroundColor DarkYellow
            }
        }
        catch {
            Write-Host "  Direct JDK download failed: $_" -ForegroundColor DarkYellow
            Write-Host "  Please install manually from https://adoptium.net/temurin/releases/?version=17" -ForegroundColor DarkYellow
        }
    }
}

# ── Postman ───────────────────────────────────────────────────────────────────
# Postman uses a Squirrel installer (Electron) - no CLI, detect only via registry/fs
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Postman") {
    Write-Host "`nChecking Postman..." -NoNewline

    $result = Find-InstalledTool `
        -ToolName      "Postman" `
        -CommandName   $configs["Postman"].CommandName `
        -RegistryNames $configs["Postman"].RegistryNames `
        -ExeSubPath    $configs["Postman"].ExeSubPath `
        -EnvVars       $configs["Postman"].EnvVars `
        -FsGlobs       $configs["Postman"].FsGlobs

    if ($result.Found) {
        Write-Host " Already installed. [Source: $($result.Source)]" -ForegroundColor Green
    }
    else {
        Write-Host " Not found. Trying Winget..." -ForegroundColor Yellow
        $wingetOk = $false

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install -e --id Postman.Postman --accept-source-agreements --accept-package-agreements
            $wingetOk = ($LASTEXITCODE -eq 0)
        }

        if (-not $wingetOk) {
            Write-Host "  Downloading Postman installer directly..." -ForegroundColor Cyan
            $installerPath = "$env:TEMP\PostmanSetup.exe"
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri "https://dl.pstmn.io/download/latest/win64" `
                    -OutFile $installerPath -ErrorAction Stop
                Write-Host "  Running Postman installer (GUI will open - please complete it to continue)..." -ForegroundColor Yellow
                Start-Process -FilePath $installerPath -Wait
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                Write-Host "  Postman installation complete." -ForegroundColor Green
            }
            catch {
                Write-Host "  Failed to download Postman: $_" -ForegroundColor DarkYellow
                Write-Host "  Please install manually from https://www.postman.com/downloads/" -ForegroundColor DarkYellow
            }
        }
    }
}

# Refresh PATH after core installs so pip/npm are available below
Refresh-EnvPath

# ── Playwright ────────────────────────────────────────────────────────────────
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Playwright") {
    Write-Host "`nChecking Playwright..." -NoNewline

    # npm may have just been installed - re-check after PATH refresh
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npmCmd) {
        # Final fallback: look for npm in Node.js install dir
        $nodeResult = Find-InstalledTool -ToolName "Node.js" `
            -CommandName "node" `
            -RegistryNames $configs["Node.js"].RegistryNames `
            -ExeSubPath "node.exe" `
            -FsGlobs $configs["Node.js"].FsGlobs
        if ($nodeResult.Found) {
            $npmDir = Split-Path $nodeResult.ExePath -Parent
            Add-ToSessionPath $npmDir
            $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
        }
    }

    if ($npmCmd) {
        $npmList = npm list -g @playwright/test 2>$null
        if ($npmList -match "@playwright/test") {
            Write-Host " Already installed." -ForegroundColor Green
        }
        else {
            Write-Host " Installing @playwright/test..." -ForegroundColor Yellow
            try {
                npm install -g @playwright/test
                Write-Host " Playwright installed." -ForegroundColor Green
            }
            catch {
                Write-Host " Failed to install Playwright npm package." -ForegroundColor DarkYellow
            }
        }

        # Chromium browser - idempotent
        Write-Host "  Installing Playwright Chromium browser..." -ForegroundColor Yellow
        try {
            npx playwright install chromium
            Write-Host "  Chromium installed." -ForegroundColor Green
        }
        catch {
            Write-Host "  Failed to install Playwright Chromium." -ForegroundColor DarkYellow
        }
    }
    else {
        Write-Host " npm not found. Please install Node.js first then re-run." -ForegroundColor DarkYellow
    }
}

# ── Locust (Python pip package) ───────────────────────────────────────────────
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Locust") {
    Write-Host "`nChecking Locust..." -NoNewline

    # Determine which pip variant is available.
    # NOTE: & cmd ($array) doesn't reliably splat in PS 5.1 - use direct calls.
    $pipVariant = $null
    if (Get-Command pip    -ErrorAction SilentlyContinue) { $pipVariant = "pip" }
    elseif (Get-Command pip3   -ErrorAction SilentlyContinue) { $pipVariant = "pip3" }
    elseif (Get-Command python -ErrorAction SilentlyContinue) { $pipVariant = "python" }
    else {
        # Python not in PATH - try 4-layer detection to find and add it
        $pyResult = Find-InstalledTool -ToolName "Python" `
            -CommandName   "python" `
            -RegistryNames $configs["Python"].RegistryNames `
            -ExeSubPath    "python.exe" `
            -EnvVars       $configs["Python"].EnvVars `
            -FsGlobs       $configs["Python"].FsGlobs
        if ($pyResult.Found -and $pyResult.ExePath) {
            Add-ToSessionPath (Split-Path $pyResult.ExePath -Parent)
            if (Get-Command python -ErrorAction SilentlyContinue) { $pipVariant = "python" }
        }
    }

    if ($pipVariant) {
        # Check if locust is already installed - use direct calls, not array splatting
        $alreadyInstalled = $false
        switch ($pipVariant) {
            "pip" { pip    show locust 2>&1 | Out-Null; $alreadyInstalled = ($LASTEXITCODE -eq 0) }
            "pip3" { pip3   show locust 2>&1 | Out-Null; $alreadyInstalled = ($LASTEXITCODE -eq 0) }
            "python" { python -m pip show locust 2>&1 | Out-Null; $alreadyInstalled = ($LASTEXITCODE -eq 0) }
        }

        if ($alreadyInstalled) {
            Write-Host " Already installed." -ForegroundColor Green
        }
        else {
            Write-Host " Installing via pip..." -ForegroundColor Yellow
            try {
                switch ($pipVariant) {
                    "pip" { pip    install locust }
                    "pip3" { pip3   install locust }
                    "python" { python -m pip install locust }
                }
                Write-Host " Locust installed." -ForegroundColor Green
            }
            catch { Write-Host " Failed to install Locust via pip." -ForegroundColor DarkYellow }
        }
    }
    else {
        Write-Host " Python/pip not found. Install Python first, then re-run:" -ForegroundColor DarkYellow
        Write-Host "   .\install_tools.ps1 -InstallOnly Locust" -ForegroundColor DarkYellow
    }
}

# ── JMeter ────────────────────────────────────────────────────────────────────
# JMeter is a plain ZIP - no installer, no registry entry.
# Detection: PATH → JMETER_HOME env var → filesystem wildcard (C: and D:)
if ($InstallOnly -eq "All" -or $InstallOnly -eq "JMeter") {
    Write-Host "`nChecking JMeter..." -NoNewline

    $jmResult = Find-InstalledTool -ToolName "JMeter" `
        -CommandName   $configs["JMeter"].CommandName `
        -RegistryNames $configs["JMeter"].RegistryNames `
        -ExeSubPath    $configs["JMeter"].ExeSubPath `
        -EnvVars       $configs["JMeter"].EnvVars `
        -FsGlobs       $configs["JMeter"].FsGlobs

    if ($jmResult.Found) {
        Write-Host " Already installed. [Source: $($jmResult.Source)]" -ForegroundColor Green
    }
    else {
        $jmeterVersion = "5.6.3"
        $jmeterHome = "$toolsDir\apache-jmeter-$jmeterVersion"
        $url = "https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-$jmeterVersion.zip"
        $zipPath = "$toolsDir\jmeter.zip"

        Write-Host " Not found. Downloading JMeter $jmeterVersion..." -ForegroundColor Yellow
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop

            Write-Host "  Extracting..." -ForegroundColor Yellow
            Expand-Archive -Path $zipPath -DestinationPath $toolsDir -Force -ErrorAction Stop
            Remove-Item $zipPath -Force

            Write-Host "  Installed to $jmeterHome" -ForegroundColor Green

            # Persist to User PATH and patch the current session
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notmatch [regex]::Escape("$jmeterHome\bin")) {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$jmeterHome\bin", "User")
            }
            Add-ToSessionPath "$jmeterHome\bin"
            Write-Host "  Added $jmeterHome\bin to PATH." -ForegroundColor Cyan
        }
        catch {
            Write-Host "  Failed to install JMeter: $_" -ForegroundColor DarkYellow
            Write-Host "  Download manually from https://jmeter.apache.org/download_jmeter.cgi" -ForegroundColor DarkYellow
        }
    }
}

# ── Done ──────────────────────────────────────────────────────────────────────
if ($InstallOnly -eq "All") {
    Write-Host "`n=== Installation Complete ===" -ForegroundColor Cyan
    Write-Host "Run .\verify_tools.ps1 to confirm all tools are detected." -ForegroundColor White
    Write-Host "Note: Open a NEW terminal to ensure all PATH changes take effect." -ForegroundColor Yellow
}
