$projectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $projectRoot

Write-Host "Starting GenAI Training Environment (Root)..." -ForegroundColor Green
docker compose up -d

Write-Host "Wait 10-20 seconds for services to fully initialize..."
Start-Sleep -Seconds 15

Write-Host "Environment is READY!" -ForegroundColor Green
Write-Host "Web UI: http://localhost:3000"
Write-Host "API Swagger: http://localhost:8080/docs (if available)"
Write-Host "Playwright UI: Run 'npx playwright test --ui' in playwright/"
Pause
