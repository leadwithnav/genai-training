$projectRoot = Resolve-Path "$PSScriptRoot\..\.."
Push-Location $projectRoot

Write-Host "Resetting GenAI Training Environment (Root)..." -ForegroundColor Red
docker compose down -v
Write-Host "Database wiped."

Write-Host "Restarting..." -ForegroundColor Green
docker compose up -d

Write-Host "Wait 20-30 seconds for database re-initialization..."
Start-Sleep -Seconds 25

Write-Host "Environment RESET complete!" -ForegroundColor Green
Pause
