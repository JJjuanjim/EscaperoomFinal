@echo off
title Tunel Fijo Permanente Ngrok (Escape Room)
cls
echo ==============================================================================
echo    CONECTANDO TUNEL FIJO PERMANENTE (NGROK)
echo    Dominio: https://cyclic-consuming-survivor.ngrok-free.dev -> http://localhost:4200
echo ==============================================================================
echo.

set "BASE_DIR=%~dp0"
cd /d "%BASE_DIR%"

taskkill /f /im ngrok.exe >nul 2>&1

ngrok.exe http 127.0.0.1:4200 --url=https://cyclic-consuming-survivor.ngrok-free.dev --authtoken=3KI8vtNxPGG9QszqqWQiRfPPVZK_25yNpy1mK5DQ2SErcykCX

pause
