@echo off
title Detener Escape Room Digital
cls
echo ==============================================================================
echo    DETENIENDO SERVICIOS DEL PROYECTO ESCAPE ROOM
echo ==============================================================================
echo.

set BASE_DIR=%~dp0

:: 1. Detener procesos escuchando en el puerto 3002 (Backend Escape Room)
echo [1/3] Liberando puerto 3002 (Backend Socket.io)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3002 ^| findstr LISTENING') do (
    echo Finalizando proceso Backend con PID %%a...
    taskkill /f /pid %%a >nul 2>&1
)

:: 2. Detener procesos escuchando en el puerto 4200 (Frontend Angular)
echo [2/3] Liberando puerto 4200 (Frontend Angular)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :4200 ^| findstr LISTENING') do (
    echo Finalizando proceso Frontend con PID %%a...
    taskkill /f /pid %%a >nul 2>&1
)

:: 3. Detener Cloudflare Tunnel si está activo
echo [3/3] Cerrando tunel para celulares...
taskkill /f /im cloudflared.exe >nul 2>&1

:: Limpiar archivos temporales de sesión de túnel
if exist "%BASE_DIR%tunnel.log" del /f /q "%BASE_DIR%tunnel.log" >nul 2>&1

echo.
echo ==============================================================================
echo    SERVICIOS DETENIDOS CON ÉXITO
echo ==============================================================================
echo Los puertos 3002, 4200 y el tunel han quedado completamente cerrados.
echo.
timeout /t 3
