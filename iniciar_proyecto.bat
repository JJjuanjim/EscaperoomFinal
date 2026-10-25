@echo off
title Iniciar Escape Room Digital Colaborativo (Multiplataforma)
cls
echo ==============================================================================
echo    INICIANDO PROYECTO ESCAPE ROOM DIGITAL COLABORATIVO
echo ==============================================================================
echo.

set BASE_DIR=%~dp0

:: 0. Limpiar logs y archivos de sesión previa
if exist "%BASE_DIR%tunnel.log" del /f /q "%BASE_DIR%tunnel.log" >nul 2>&1
if exist "%BASE_DIR%ENLACE_CELULARES.txt" del /f /q "%BASE_DIR%ENLACE_CELULARES.txt" >nul 2>&1

:: 1. Verificar dependencias del Backend
echo [1/4] Verificando dependencias del Backend...
if not exist "%BASE_DIR%backend\node_modules" (
    echo Instalando paquetes del Backend...
    cd /d "%BASE_DIR%backend"
    call npm install
)

:: 2. Iniciar Backend en una ventana separada
echo [2/4] Iniciando Servidor Backend (NestJS 11 + Socket.io en puerto 3002)...
start "Escape Room - Backend (NestJS Puerto 3002)" cmd /k "cd /d "%BASE_DIR%backend" && echo Servidor NestJS Escape Room en puerto 3002 && npm run dev"

:: 3. Verificar dependencias del Frontend
echo [3/4] Verificando dependencias del Frontend e iniciando Angular...
if not exist "%BASE_DIR%frontend\node_modules" (
    echo Instalando paquetes del Frontend...
    cd /d "%BASE_DIR%frontend"
    call npm install
)

:: 4. Iniciar Frontend con proxy unificado (WebSockets y API pasan por puerto 4200)
start "Escape Room - Frontend (Angular Puerto 4200)" cmd /k "cd /d "%BASE_DIR%frontend" && echo Compilando Angular con proxy unificado para WebSockets y Celulares... && npm start"

:: 5. Comprobar si hay configuración de ENLACE FIJO (Ngrok) en config_tunel.txt
echo [4/4] Preparando tunel para celulares (4G/5G y redes externas)...
set "USE_FIXED_NGROK=0"
set "NGROK_TOKEN="
set "NGROK_DOMAIN="

if exist "%BASE_DIR%config_tunel.txt" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%BASE_DIR%config_tunel.txt") do (
        if "%%a"=="NGROK_AUTHTOKEN" if not "%%b"=="" set "NGROK_TOKEN=%%b"
        if "%%a"=="NGROK_DOMINIO_FIJO" if not "%%b"=="" set "NGROK_DOMAIN=%%b"
    )
)

if defined NGROK_TOKEN (
    set "USE_FIXED_NGROK=1"
)

set "TUNNEL_URL="

if "%USE_FIXED_NGROK%"=="1" (
    echo Detectada configuracion de DOMINIO FIJO PERMANENTE (Ngrok)...
    
    :: Buscar ejecutable de ngrok
    set "NGROK_BIN="
    if exist "%BASE_DIR%ngrok.exe" (
        set "NGROK_BIN=%BASE_DIR%ngrok.exe"
    ) else if exist "C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\ngrok.exe" (
        set "NGROK_BIN=C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\ngrok.exe"
    )

    :: Limpiar prefijo https:// si fue incluido
    set "CLEAN_DOMAIN=%NGROK_DOMAIN:https://=%"
    set "CLEAN_DOMAIN=%CLEAN_DOMAIN:http://=%"
    set "CLEAN_DOMAIN=%CLEAN_DOMAIN:/=%"

    if defined CLEAN_DOMAIN (
        set "TUNNEL_URL=https://%CLEAN_DOMAIN%"
        start "Escape Room - Tunel Fijo Permanente" cmd /k "title Tunel Fijo Permanente && echo Conectando dominio fijo: https://%CLEAN_DOMAIN% && "%NGROK_BIN%" http 4200 --url=https://%CLEAN_DOMAIN% --authtoken=%NGROK_TOKEN%"
    ) else (
        start "Escape Room - Tunel Fijo Permanente" cmd /k "title Tunel Fijo Permanente && echo Conectando dominio fijo Ngrok... && "%NGROK_BIN%" http 4200 --authtoken=%NGROK_TOKEN%"
        set "TUNNEL_URL=https://cyclic-consuming-survivor.ngrok-free.dev"
    )
) else (
    echo Iniciando tunel automatico Cloudflare a http://localhost:4200...
    set "CLOUDFLARED_CMD="
    if exist "%BASE_DIR%cloudflared.exe" (
        set "CLOUDFLARED_CMD=%BASE_DIR%cloudflared.exe"
    ) else if exist "C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\cloudflared.exe" (
        set "CLOUDFLARED_CMD=C:\Users\mynor\Documents\umg 2026\decimo\aseguramiento\agente_claude\cloudflared.exe"
    )

    if defined CLOUDFLARED_CMD (
        start "Escape Room - Tunel para Celulares" cmd /k "title Tunel para Celulares && echo Conectando tunel publico Cloudflare... && "%CLOUDFLARED_CMD%" tunnel --url http://localhost:4200 --logfile "%BASE_DIR%tunnel.log""
    ) else (
        start "Escape Room - Tunel para Celulares" cmd /k "title Tunel para Celulares && echo Conectando tunel via SSH... && ssh -p 443 -R0:localhost:4200 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 qr@a.pinggy.io"
    )

    echo Esperando a que el tunel genere el enlace...
    for /l %%i in (1,1,28) do (
        if not defined TUNNEL_URL (
            timeout /t 1 /nobreak >nul
            if exist "%BASE_DIR%tunnel.log" (
                for /f "tokens=*" %%u in ('powershell -Command "try { $m = (Select-String -Path '%BASE_DIR%tunnel.log' -Pattern 'https://[a-zA-Z0-9-]+\.trycloudflare\.com').Matches; if ($m) { $m[-1].Value } } catch {}"') do set "TUNNEL_URL=%%u"
            )
        )
    )
)

echo.
echo ==============================================================================
echo    ESPERANDO A QUE LOS SERVICIOS SE INICIALICEN...
echo ==============================================================================
echo (Esto toma unos 15-20 segundos, por favor espera mientras se compilan los modulos)
timeout /t 10 /nobreak >nul

:: Obtener IP local del equipo en la red Wi-Fi
set "LOCAL_IP=127.0.0.1"
for /f "tokens=*" %%a in ('powershell -Command "try { (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress } catch { '127.0.0.1' }"') do set "LOCAL_IP=%%a"

cls
echo.
echo ==============================================================================
echo    ESCAPE ROOM DIGITAL - SERVICIOS EN LINEA
echo ==============================================================================
echo.
echo [1] EN TU PROPIA COMPUTADORA:
echo     URL: http://localhost:4200
echo.
echo [2] PARA AMIGOS EN TU MISMA RED WI-FI:
echo     URL: http://%LOCAL_IP%:4200
echo.
if defined TUNNEL_URL (
    echo ==============================================================================
    if "%USE_FIXED_NGROK%"=="1" (
        echo [3] ENLACE FIJO PERMANENTE PARA CELULARES (DATOS 4G/5G O CUALQUIER RED):
    ) else (
        echo [3] ENLACE PARA CELULARES (DATOS 4G/5G O CUALQUIER OTRA RED EXTERNA):
    )
    echo     URL: %TUNNEL_URL%
    echo ==============================================================================
    echo (Copiando enlace al portapapeles... ya puedes pegarlo directamente en WhatsApp con Ctrl+V)
    echo %TUNNEL_URL%| clip
    echo %TUNNEL_URL% > "%BASE_DIR%ENLACE_CELULARES.txt"
) else (
    echo [3] PARA CELULARES (DATOS MOVILES 4G/5G):
    echo     Revisa la ventana 'Escape Room - Tunel para Celulares' para ver el enlace generado.
)
echo.
echo [4] DOCUMENTACION SWAGGER API REST:
echo     URL: http://localhost:3002/api/docs
echo.
echo ------------------------------------------------------------------------------
echo NOTA: Manten abiertas las ventanas de Backend, Frontend y Tunel mientras juegues.
echo Para detener todos los servicios, ejecuta 'detener_proyecto.bat'.
echo ------------------------------------------------------------------------------
echo.
start http://localhost:4200
pause
