Write-Host "Verifying Environment..." -ForegroundColor Cyan

# Check Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Docker is installed." -ForegroundColor Green
} else {
    Write-Host "[FAIL] Docker is not installed." -ForegroundColor Red
}

# Check Ports
$ports = @(3002, 8082, 5434, 5052)
foreach ($port in $ports) {
    $con = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    if ($con.TcpTestSucceeded) {
        Write-Host "[OK] Port $port is active (App running?)" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Port $port is free." -ForegroundColor Gray
    }
}
