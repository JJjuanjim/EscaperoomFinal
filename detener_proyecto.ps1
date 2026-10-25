# ==============================================================================
# Script para Detener Todos los Servicios del Escape Room
# ==============================================================================

Write-Host "==============================================================================" -ForegroundColor Red
Write-Host "   DETENIENDO SERVICIOS DEL ESCAPE ROOM" -ForegroundColor Red
Write-Host "==============================================================================" -ForegroundColor Red
Write-Host ""

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Liberar puerto 3002
Write-Host "[1/3] Liberando puerto 3002 (Backend)..." -ForegroundColor Yellow
$p3002 = Get-NetTCPConnection -LocalPort 3002 -ErrorAction SilentlyContinue
if ($p3002) {
    $p3002 | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

# 2. Liberar puerto 4200
Write-Host "[2/3] Liberando puerto 4200 (Frontend)..." -ForegroundColor Yellow
$p4200 = Get-NetTCPConnection -LocalPort 4200 -ErrorAction SilentlyContinue
if ($p4200) {
    $p4200 | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

# 3. Detener cloudflared
Write-Host "[3/3] Cerrando túnel para celulares..." -ForegroundColor Yellow
Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

if (Test-Path "$projectDir\tunnel.log") {
    Remove-Item -Force "$projectDir\tunnel.log" -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "   TODOS LOS SERVICIOS Y EL TÚNEL HAN SIDO DETENIDOS" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2
