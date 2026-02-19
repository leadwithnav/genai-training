Set-Location "$PSScriptRoot/.."
Write-Host "Resetting Upland Workflow App..." -ForegroundColor Yellow
docker compose down -v
docker compose up -d --build

Write-Host "`nApp Reset & Started Successfully!" -ForegroundColor Cyan
Write-Host "Web UI: http://localhost:3002"
