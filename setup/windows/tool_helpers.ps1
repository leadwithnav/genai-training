# =============================================================================
# tool_helpers.ps1
# Shared detection utilities for install_tools.ps1 and verify_tools.ps1
#
# Dot-source this at the top of both scripts:
#   . "$PSScriptRoot\tool_helpers.ps1"
#
# Compatible: Windows PowerShell 5.1+  (no PS7-only syntax)
# =============================================================================

<#
.SYNOPSIS
    Adds a directory to the current session PATH if not already present.
    Does nothing if the dir does not exist or is already in PATH.
#>
function Add-ToSessionPath {
    param([string]$Dir)
    if ([string]::IsNullOrWhiteSpace($Dir)) { return }
    if (-not (Test-Path $Dir -PathType Container)) { return }
    # Case-insensitive check to avoid duplicates
    $existing = $env:Path -split ";" | Where-Object { $_ -ieq $Dir }
    if ($existing) { return }
    $env:Path = "$($env:Path);$Dir"
}

<#
.SYNOPSIS
    Reloads Machine + User PATH into the current session.
    Call this after any install so subsequent tools are found.
#>
function Refresh-EnvPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

<#
.SYNOPSIS
    Detects a tool through 4 layers in order:
      1. PATH (Get-Command)        — fastest
      2. Windows Registry          — works for any GUI/MSI/Squirrel installer
      3. Environment variables     — JAVA_HOME, JMETER_HOME, PYTHON_HOME, etc.
      4. Filesystem wildcard globs — for portable/zip tools (e.g. JMeter)

    If found via layers 2–4 but the binary dir is not in PATH,
    session PATH is auto-patched so subsequent commands work immediately.

.OUTPUTS
    Hashtable: @{ Found = [bool]; ExePath = [string]; Source = [string] }
    Source describes which layer found the tool, e.g. "Registry [Git version 2.43.0]"
#>
function Find-InstalledTool {
    param(
        [string]   $ToolName,                    # Human-readable label (for messages)
        [string]   $CommandName = "",          # Binary name for Get-Command check
        [string[]] $RegistryNames = @(),         # DisplayName wildcard patterns
        [string]   $ExeSubPath = "",          # Relative exe path from InstallLocation
        [string[]] $EnvVars = @(),         # Env var names (JAVA_HOME, etc.)
        [string[]] $FsGlobs = @()          # Filesystem glob patterns (supports %VARS%)
    )

    # ── Layer 1: PATH ─────────────────────────────────────────────────────────
    if ($CommandName) {
        $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
        if ($cmd) {
            return @{ Found = $true; ExePath = $cmd.Source; Source = "PATH" }
        }
    }

    # ── Layer 2: Windows Registry (HKLM 64-bit, HKLM 32-bit, HKCU) ──────────
    if ($RegistryNames.Count -gt 0) {
        $regRoots = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        $regResult = $null
        :regSearch foreach ($root in $regRoots) {
            if (-not (Test-Path $root)) { continue }
            foreach ($key in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
                $entry = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
                if (-not $entry -or -not $entry.DisplayName) { continue }
                foreach ($pattern in $RegistryNames) {
                    if ($entry.DisplayName -like $pattern) {
                        # Clean up InstallLocation (may have quotes or trailing slashes)
                        $loc = if ($entry.InstallLocation) {
                            $entry.InstallLocation.Trim('"').Trim('\').Trim()
                        }
                        else { "" }

                        if ($ExeSubPath -and $loc) {
                            $exeFull = Join-Path $loc $ExeSubPath
                            if (Test-Path $exeFull) {
                                Add-ToSessionPath (Split-Path $exeFull -Parent)
                                $regResult = @{
                                    Found   = $true
                                    ExePath = $exeFull
                                    Source  = "Registry [$($entry.DisplayName)]"
                                }
                                break regSearch
                            }
                        }
                        # Found in registry but exe not pinpointed — still consider installed
                        $regResult = @{
                            Found   = $true
                            ExePath = $loc
                            Source  = "Registry [$($entry.DisplayName)]"
                        }
                        break regSearch
                    }
                }
            }
        }
        if ($regResult) { return $regResult }
    }

    # ── Layer 3: Environment Variables ───────────────────────────────────────
    foreach ($envVar in $EnvVars) {
        $val = [Environment]::GetEnvironmentVariable($envVar, "Machine")
        if (-not $val) { $val = [Environment]::GetEnvironmentVariable($envVar, "User") }
        if (-not $val) { $val = [Environment]::GetEnvironmentVariable($envVar, "Process") }
        if ($val -and (Test-Path $val)) {
            if ($ExeSubPath) {
                $exeFull = Join-Path $val $ExeSubPath
                if (Test-Path $exeFull) {
                    Add-ToSessionPath (Split-Path $exeFull -Parent)
                    return @{ Found = $true; ExePath = $exeFull; Source = "EnvVar [$envVar]" }
                }
            }
            return @{ Found = $true; ExePath = $val; Source = "EnvVar [$envVar]" }
        }
    }

    # ── Layer 4: Filesystem Wildcard Globs ───────────────────────────────────
    foreach ($glob in $FsGlobs) {
        # Expand %LOCALAPPDATA%, %ProgramFiles%, etc.
        $expandedGlob = [Environment]::ExpandEnvironmentVariables($glob)
        $hit = Get-ChildItem $expandedGlob -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) {
            Add-ToSessionPath (Split-Path $hit.FullName -Parent)
            return @{ Found = $true; ExePath = $hit.FullName; Source = "Filesystem [$($hit.FullName)]" }
        }
    }

    return @{ Found = $false; ExePath = $null; Source = $null }
}

# =============================================================================
# Per-Tool Detection Configs
# Each entry is a hashtable of Find-InstalledTool parameters.
# Import this in calling scripts with:  $ToolConfigs = Get-ToolConfigs
# =============================================================================
function Get-ToolConfigs {
    return @{
        "Git"        = @{
            CliArgs       = @("--version")    # git --version
            CommandName   = "git"
            RegistryNames = @("Git*", "Git version*")
            ExeSubPath    = "cmd\git.exe"
            EnvVars       = @()
            FsGlobs       = @(
                "C:\Program Files\Git\cmd\git.exe",
                "C:\Program Files (x86)\Git\cmd\git.exe"
            )
        }
        "Node.js"    = @{
            CliArgs       = @("--version")    # node --version
            CommandName   = "node"
            RegistryNames = @("Node.js*")
            ExeSubPath    = "node.exe"
            EnvVars       = @()
            FsGlobs       = @(
                "C:\Program Files\nodejs\node.exe",
                "C:\Program Files (x86)\nodejs\node.exe"
            )
        }
        "Python"     = @{
            CliArgs       = @("--version")    # python --version
            CommandName   = "python"
            RegistryNames = @("Python 3*", "Python*")
            ExeSubPath    = "python.exe"
            EnvVars       = @("PYTHON_HOME", "PYTHONPATH")
            FsGlobs       = @(
                "C:\Python3*\python.exe",
                "C:\Program Files\Python3*\python.exe",
                "C:\Program Files (x86)\Python3*\python.exe",
                "%LOCALAPPDATA%\Programs\Python\Python3*\python.exe"
            )
        }
        "Java"       = @{
            CliArgs       = @("-version")     # java -version (outputs to stderr, exit 0)
            CommandName   = "java"
            RegistryNames = @("Eclipse Adoptium*", "AdoptOpenJDK*", "Java SE*",
                "Java Development Kit*", "Microsoft Build of OpenJDK*",
                "OpenJDK*", "BellSoft Liberica*", "Azul Zulu*")
            ExeSubPath    = "bin\java.exe"
            EnvVars       = @("JAVA_HOME")
            FsGlobs       = @(
                "C:\Program Files\Eclipse Adoptium\jdk-*\bin\java.exe",
                "C:\Program Files\Java\jdk*\bin\java.exe",
                "C:\Program Files\Microsoft\jdk-*\bin\java.exe",
                "C:\Program Files\BellSoft\LibericaJDK-*\bin\java.exe",
                "C:\Program Files\Zulu\zulu-*\bin\java.exe"
            )
        }
        "JMeter"     = @{
            CliArgs       = @("-v")           # jmeter -v (version to stderr)
            CommandName   = "jmeter"
            RegistryNames = @()
            ExeSubPath    = ""
            EnvVars       = @("JMETER_HOME")
            FsGlobs       = @(
                "C:\Tools\apache-jmeter-*\bin\jmeter.bat",
                "C:\Program Files\apache-jmeter-*\bin\jmeter.bat",
                "C:\Program Files (x86)\apache-jmeter-*\bin\jmeter.bat",
                "C:\ProgramData\chocolatey\lib\jmeter\tools\apache-jmeter-*\bin\jmeter.bat",
                "D:\Tools\apache-jmeter-*\bin\jmeter.bat",
                "D:\apache-jmeter-*\bin\jmeter.bat"
            )
        }
        "Postman"    = @{
            CliArgs       = @()               # Postman has no CLI — skip Layer 0
            CommandName   = ""
            RegistryNames = @("Postman*")
            ExeSubPath    = ""
            EnvVars       = @()
            FsGlobs       = @(
                "%LOCALAPPDATA%\Postman\Postman.exe",
                "%LOCALAPPDATA%\Postman\app-*\Postman.exe",
                "%ProgramFiles%\Postman\Postman.exe",
                "%ProgramFiles%\Postman\app-*\Postman.exe"
            )
        }
        "Docker"     = @{
            CliArgs       = @("--version")    # docker --version
            CommandName   = "docker"
            RegistryNames = @("Docker Desktop*")
            ExeSubPath    = ""
            EnvVars       = @()
            FsGlobs       = @(
                "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
            )
        }
        "Playwright" = @{
            CliArgs       = @("--version")    # playwright --version (global npm bin)
            CommandName   = "playwright"
            RegistryNames = @()
            ExeSubPath    = ""
            EnvVars       = @()
            FsGlobs       = @()
        }
        "Locust"     = @{
            CliArgs       = @("--version")    # locust --version
            CommandName   = "locust"
            RegistryNames = @()
            ExeSubPath    = ""
            EnvVars       = @()
            FsGlobs       = @()
        }
    }
}
