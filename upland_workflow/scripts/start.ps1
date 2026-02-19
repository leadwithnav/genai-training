Set-Location "$PSScriptRoot/.."
$currentDir = Get-Location

$currentDir = Get-Location

Write-Host "Starting Upland Workflow App..." -ForegroundColor Green
docker compose up -d --build

Write-Host "`nApp Started Successfully!" -ForegroundColor Cyan
Write-Host "Web UI: http://localhost:3002"
Write-Host "API:    http://localhost:8082"
Write-Host "Admin:  http://localhost:5052 (admin@upland.com / admin)"
