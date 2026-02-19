$ErrorActionPreference = "Continue"

Write-Host "`n=== GenAI Training Lab: Installation Verification ===`n" -ForegroundColor Cyan

# --- 1. Start Ecommerce App ---
Write-Host "1. Starting Ecommerce App..." -ForegroundColor Yellow
$projectRoot = Resolve-Path "$PSScriptRoot\..\.."
$ecommerceDir = "$projectRoot\ecommerce"

if (Test-Path $ecommerceDir) {
    Set-Location $ecommerceDir
    docker-compose up -d
    
    # Simple wait loop for port 3000
    Write-Host "Waiting for app to be ready on http://localhost:3000..." -NoNewline
    $maxBuffer = 30
    $buffer = 0
    $appReady = $false
    while ($buffer -lt $maxBuffer) {
        try {
            $resp = Invoke-WebRequest -Uri "http://localhost:3000" -Method Head -ErrorAction Stop -TimeoutSec 2 -UseBasicParsing
            if ($resp.StatusCode -eq 200) {
                $appReady = $true
                break
            }
        } catch {
            Start-Sleep -Seconds 2
            $buffer++
            Write-Host "." -NoNewline
        }
    }
    Write-Host "" 

    if ($appReady) {
        Write-Host "App is started on http://localhost:3000" -ForegroundColor Green
    } else {
        Write-Host "App failed to start or is not responding. Proceeding with tests anyway..." -ForegroundColor Red
    }
} else {
    Write-Host "Ecommerce directory not found!" -ForegroundColor Red
}

# --- 2. Playwright Tests ---
Write-Host "`n2. Running Playwright Tests..." -ForegroundColor Yellow
$playwrightDir = "$projectRoot\playwright"
if (Test-Path $playwrightDir) {
    Set-Location $playwrightDir
    # Run tests (headless for CI script)
    try {
        if (Get-Command npx -ErrorAction SilentlyContinue) {
            # Using cmd /c to ensure exit code capture
            cmd /c "npx playwright test --project=chromium --reporter=list"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Playwright tests PASSED" -ForegroundColor Green
            } else {
                Write-Host "Playwright tests FAILED" -ForegroundColor Red
            }
        } else {
             Write-Host "npx not found. Cannot run Playwright." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error running Playwright: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Playwright directory not found!" -ForegroundColor Red
}

# --- 3. JMeter Tests ---
Write-Host "`n3. Running JMeter Tests..." -ForegroundColor Yellow
$jmeterBat = "C:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat"
$jmxFile = "$projectRoot\performance\ecommerce_load_test.jmx"
$jtlFile = "$projectRoot\performance\jmeter_results.jtl"

if (Test-Path $jmeterBat) {
    if (Test-Path $jmxFile) {
        Write-Host "Running JMeter test plan..."
        # Run JMeter in non-GUI mode
        $proc = Start-Process -FilePath $jmeterBat -ArgumentList "-n", "-t", "$jmxFile", "-l", "$jtlFile", "-f" -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode -eq 0) {
             # Check JTL content for failures? (Basic check: if executed without JMeter crashing)
             # To be more precise, we'd parse the JTL. For now, assuming Jmeter success means test ran.
             Write-Host "JMeter test execution PASSED" -ForegroundColor Green
        } else {
             Write-Host "JMeter test execution FAILED (Exit Code: $($proc.ExitCode))" -ForegroundColor Red
        }
    } else {
        Write-Host "JMeter test plan ($jmxFile) not found." -ForegroundColor Red
    }
} else {
    Write-Host "JMeter binary not found at $jmeterBat" -ForegroundColor Red
}

# --- 4. Locust Tests ---
Write-Host "`n4. Running Locust Tests..." -ForegroundColor Yellow
$locustFile = "$projectRoot\performance\locustfile.py"

if (Test-Path $locustFile) {
    if (Get-Command locust -ErrorAction SilentlyContinue) {
        Write-Host "Running Locust headless (5s, 5 users)..."
        # Run locust headless
        try {
            $lProc = Start-Process -FilePath "locust" -ArgumentList "-f", "$locustFile", "--headless", "-u", "5", "-r", "1", "-t", "5s", "--host", "http://localhost:3000" -NoNewWindow -Wait -PassThru
            if ($lProc.ExitCode -eq 0) {
                Write-Host "Locust test running FINE" -ForegroundColor Green
            } else {
                Write-Host "Locust test encountered issues (Exit Code: $($lProc.ExitCode))" -ForegroundColor Yellow
            }
        } catch {
             Write-Host "Error launching Locust: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Locust command not found (pip install locust?)." -ForegroundColor Red
    }
} else {
     Write-Host "Locust file ($locustFile) not found." -ForegroundColor Red
}

# --- 5. Postman Tests (Newman) ---
Write-Host "`n5. Running Postman Tests..." -ForegroundColor Yellow
$collectionFile = "$projectRoot\postman\collection.json"

if (Test-Path $collectionFile) {
    # Try global newman first
    if (Get-Command newman -ErrorAction SilentlyContinue) {
        Write-Host "Running with global 'newman'..."
        cmd /c "newman run `"$collectionFile`" --reporters cli"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Postman tests PASSED" -ForegroundColor Green
        } else {
            Write-Host "Postman tests FAILED" -ForegroundColor Red
        }
    } else {
        # Try npx newman
        Write-Host "Global 'newman' not found. Trying 'npx newman'..."
        if (Get-Command npx -ErrorAction SilentlyContinue) {
            cmd /c "npx -y newman run `"$collectionFile`" --reporters cli"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Postman tests PASSED" -ForegroundColor Green
            } else {
                Write-Host "Postman tests FAILED (or npx issue)" -ForegroundColor Red
            }
        } else {
            Write-Host "Neither newman nor npx found. Cannot run Postman automation." -ForegroundColor Red
            Write-Host "Please open Postman App and import '$collectionFile' manually." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Postman collection ($collectionFile) not found." -ForegroundColor Red
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
