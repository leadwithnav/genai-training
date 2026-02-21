# Check for admin (Still good practice, though not strictly needed for user-scope installs like pip/npm)
param(
    [string]$InstallOnly = "All"
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Running as standard user. Some global installs might fail or require elevation."
}

$toolsDir = "C:\Tools"
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null }

# --- Helper: Ensure Package Manager (Chocolatey) ---
function Initialize-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        return $true
    }
    
    Write-Host "Chocolatey not found. Attempting to install..." -ForegroundColor Yellow
    
    # Check Admin again for Choco
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning " Skipping Chocolatey installation: Requires Administrator privileges."
        Write-Warning " Please install Chocolatey manually or run this script as Admin."
        return $false
    }

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force; 
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Reload PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host " Chocolatey installed successfully." -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Warning " Failed to install Chocolatey: $_"
    }
    
    return $false
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
    # Only try to ensure/use Choco if Winget failed or wasn't found
    if (Initialize-Chocolatey) {
        $list = choco list --local-only $ChocoId 2>$null
        if ($list -match $ChocoId) {
            Write-Host " Already installed (Chocolatey)." -ForegroundColor Green
            return
        }
        Write-Host " Installing via Chocolatey..." -ForegroundColor Yellow
        choco install $ChocoId -y
        return
    }

    Write-Error "Could not install $Name. Winget not found and Chocolatey requires Admin/is missing."
    exit 1
}



# ... (Functions are defined above, keep them) ...

# --- 0. Core Prerequisites ---
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Git") { Install-Package "Git" "Git.Git" "git" "git" }
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Node.js") { Install-Package "Node.js (LTS)" "OpenJS.NodeJS.LTS" "nodejs-lts" "node" }
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Python") { Install-Package "Python 3.11" "Python.Python.3.11" "python" "python" }
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Java") { Install-Package "Java JDK 17" "EclipseAdoptium.Temurin.17.JDK" "temurin17" "java" }

# --- Postman (Manual Download Fallback) ---
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Postman") {
    Write-Host "`nChecking Postman..." -NoNewline
    $postmanUser = "$env:LOCALAPPDATA\Postman\Postman.exe"
    $postmanProgram = "$env:ProgramFiles\Postman\Postman.exe"
    
    if ((Test-Path $postmanUser) -or (Test-Path $postmanProgram)) {
        Write-Host " Already installed." -ForegroundColor Green
    }
    else {
        Write-Host " Not found." -ForegroundColor Yellow
        Write-Host " Downloading Postman installer..." -ForegroundColor Cyan
        
        $installerPath = "$env:TEMP\PostmanSetup.exe"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "https://dl.pstmn.io/download/latest/win64" -OutFile $installerPath -ErrorAction Stop
            
            Write-Host " Running Postman installer..." -ForegroundColor Yellow
            Start-Process -FilePath $installerPath -ArgumentList "--silent" -Wait
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            
            if ((Test-Path $postmanUser) -or (Test-Path $postmanProgram)) {
                Write-Host " Postman installed successfully." -ForegroundColor Green
            }
            else {
                Write-Host " Postman installer ran. It may open automatically on first launch." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Failed to install Postman: $_"
            exit 1
        }
    }
}

# Refresh Env (Attempt to reload PATH without restart if possible, mainly for current session)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# --- 1. Playwright (Node.js) ---
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Playwright") {
    Write-Host "`nChecking Playwright..." -NoNewline
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $npmList = npm list -g @playwright/test 2>$null
        if ($npmList -match "@playwright/test") {
            Write-Host " Already installed." -ForegroundColor Green
        }
        else {
            Write-Host " Installing..." -ForegroundColor Yellow
            try {
                npm install -g @playwright/test
                Write-Host " Playwright installed." -ForegroundColor Green
            }
            catch {
                Write-Warning " Failed to install Playwright npm package."
            }
        }
        
        # Install Browsers (Chromium)
        Write-Host " Installing Playwright browsers (Chromium)..." -ForegroundColor Yellow
        try {
            npx playwright install chromium
            Write-Host " Browsers installed." -ForegroundColor Green
        }
        catch {
            Write-Warning " Failed to install Playwright/Chromium."
        }
    }
    else {
        Write-Warning " npm not found. Skipping Playwright."
    }
}

# --- 2. Locust (Python) ---
if ($InstallOnly -eq "All" -or $InstallOnly -eq "Locust") {
    Write-Host "`nChecking Locust..." -NoNewline
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        $null = pip show locust
        if ($LASTEXITCODE -eq 0) {
            Write-Host " Already installed." -ForegroundColor Green
        }
        else {
            Write-Host " Installing..." -ForegroundColor Yellow
            try {
                pip install locust
                Write-Host " Locust installed." -ForegroundColor Green
            }
            catch {
                Write-Warning " Failed to install Locust."
            }
        }
    }
    else {
        Write-Warning " pip not found. Skipping Locust."
    }
}

# --- 3. JMeter (Manual Download - Fallback since Winget missing) ---
if ($InstallOnly -eq "All" -or $InstallOnly -eq "JMeter") {
    Write-Host "`nChecking JMeter..." -NoNewline
    $jmeterHome = "$toolsDir\apache-jmeter-5.6.3"
    
    if (Test-Path "$jmeterHome\bin\jmeter.bat") {
        Write-Host " Already installed at $jmeterHome" -ForegroundColor Green
    }
    else {
        Write-Host " Not found." -ForegroundColor Yellow
        Write-Host " Downloading JMeter 5.6.3... (This may take a minute)" -ForegroundColor Cyan
        
        $url = "https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.3.zip"
        $zipPath = "$toolsDir\jmeter.zip"
        
        try {
            # Download
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop
            
            Write-Host " Extracting..." -ForegroundColor Yellow
            Expand-Archive -Path $zipPath -DestinationPath $toolsDir -Force -ErrorAction Stop
            Remove-Item $zipPath -Force
            
            Write-Host " Installed to $jmeterHome" -ForegroundColor Green
            
            # Update User Path for current session and future
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notmatch "jmeter") {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$jmeterHome\bin", "User")
                $env:Path += ";$jmeterHome\bin"
                Write-Host " Added to PATH." -ForegroundColor Cyan
            }
        }
        catch {
            Write-Error "Failed to install JMeter: $_"
            exit 1
        }
    }
}

if ($InstallOnly -eq "All") {
    Write-Host "`n--- Setup Complete ---"
    Write-Host "Please RESTART your terminal to use new tools (JMeter)." -ForegroundColor Cyan
}

