# ==============================================================================
# Script de Inicio de Escape Room Digital (Backend, Frontend y Túnel para Celulares)
# ==============================================================================

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 0. Limpiar logs previos
if (Test-Path "$projectDir\tunnel.log") { Remove-Item -Force "$projectDir\tunnel.log" -ErrorAction SilentlyContinue }
if (Test-Path "$projectDir\ENLACE_CELULARES.txt") { Remove-Item -Force "$projectDir\ENLACE_CELULARES.txt" -ErrorAction SilentlyContinue }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "   INICIANDO PROYECTO ESCAPE ROOM DIGITAL COLABORATIVO" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Iniciar Backend en nueva ventana de PowerShell
Write-Host "[1/3] Iniciando Servidor Backend (NestJS + Socket.io en puerto 3002)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$projectDir\backend'; Write-Host '🔐 Backend Escape Room corriendo en puerto 3002' -ForegroundColor Green; npm run dev"

# 2. Iniciar Frontend con proxy unificado en nueva ventana de PowerShell
Write-Host "[2/3] Iniciando Servidor Frontend (Angular con Proxy en puerto 4200)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$projectDir\frontend'; Write-Host '🚀 Frontend Angular corriendo con proxy en puerto 4200' -ForegroundColor Green; npm start"

# 3. Preparar e iniciar túnel para celulares
Write-Host "[3/3] Iniciando Túnel Seguro para Celulares (4G/5G)..." -ForegroundColor Yellow

$cloudflaredBin = $null
if (Test-Path "$projectDir\cloudflared.exe") {
    $cloudflaredBin = "$projectDir\cloudflared.exe"
} elseif (Test-Path "C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\cloudflared.exe") {
    $cloudflaredBin = "C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\cloudflared.exe"
    Copy-Item "C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\cloudflared.exe" "$projectDir\cloudflared.exe" -Force -ErrorAction SilentlyContinue
    if (Test-Path "$projectDir\cloudflared.exe") { $cloudflaredBin = "$projectDir\cloudflared.exe" }
}

if ($cloudflaredBin) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '🌐 Túnel Cloudflare para Celulares' -ForegroundColor Green; & '$cloudflaredBin' tunnel --url http://localhost:4200 --logfile '$projectDir\tunnel.log'"
} else {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '🌐 Túnel SSH para Celulares' -ForegroundColor Green; ssh -p 443 -R0:localhost:4200 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 qr@a.pinggy.io"
}

Write-Host ""
Write-Host "Servicios iniciados en ventanas independientes." -ForegroundColor Green
Write-Host "Esperando compilación de Angular y enlace del túnel (aprox 20s)..." -ForegroundColor Cyan

$ready = $false
$maxSeconds = 40
$elapsed = 0

while (-not $ready -and $elapsed -lt $maxSeconds) {
    Start-Sleep -Seconds 2
    $elapsed += 2
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:4200" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($res.StatusCode -eq 200) {
            $ready = $true
        }
    } catch {}
    Write-Host "   Verificando servicios... ($elapsed s)" -ForegroundColor Gray
}

# Obtener URL del túnel
$tunnelUrl = $null
if (Test-Path "$projectDir\tunnel.log") {
    $match = (Select-String -Path "$projectDir\tunnel.log" -Pattern "https://[a-zA-Z0-9-]+\.trycloudflare\.com").Matches
    if ($match) {
        $tunnelUrl = $match[-1].Value
    }
}

# Obtener IP local
$localIp = "127.0.0.1"
try {
    $ipObj = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1)
    if ($ipObj) { $localIp = $ipObj.IPAddress }
} catch {}

Clear-Host
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "   ESCAPE ROOM DIGITAL - SERVICIOS EN LÍNEA" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[1] EN TU PROPIA COMPUTADORA:" -ForegroundColor Cyan
Write-Host "    http://localhost:4200" -ForegroundColor White
Write-Host ""
Write-Host "[2] PARA AMIGOS EN TU MISMA RED WI-FI:" -ForegroundColor Cyan
Write-Host "    http://$($localIp):4200" -ForegroundColor White
Write-Host ""

if ($tunnelUrl) {
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host "[3] PARA CELULARES (DATOS MÓVILES 4G/5G O CUALQUIER RED EXTERNA):" -ForegroundColor Magenta
    Write-Host "    $tunnelUrl" -ForegroundColor Yellow
    Write-Host "==============================================================================" -ForegroundColor Magenta
    Write-Host "(El enlace ha sido copiado a tu portapapeles. Solo presiona Ctrl+V en WhatsApp)" -ForegroundColor Green
    Set-Clipboard -Value $tunnelUrl
    $tunnelUrl | Out-File -FilePath "$projectDir\ENLACE_CELULARES.txt" -Encoding utf8
} else {
    Write-Host "[3] PARA CELULARES (DATOS 4G/5G):" -ForegroundColor Magenta
    Write-Host "    Revisa la ventana 'Túnel Cloudflare' para ver el enlace HTTPS generado." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[4] DOCUMENTACIÓN SWAGGER API REST:" -ForegroundColor Cyan
Write-Host "    http://localhost:3002/api/docs" -ForegroundColor White
Write-Host ""
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Para detener el proyecto ejecuta: .\detener_proyecto.ps1" -ForegroundColor Gray
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Gray

Start-Process "http://localhost:4200"
