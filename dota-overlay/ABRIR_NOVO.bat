@echo off
title Dota 2 Overlay
color 0B
echo.
echo ========================================
echo    DOTA 2 OVERLAY - INICIANDO...
echo ========================================
echo.

cd /d "%~dp0"

echo Fechando processos anteriores...
taskkill /F /IM electron.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1

echo Aguardando 3 segundos...
timeout /t 3 /nobreak >nul

echo Iniciando overlay...
echo (O servidor GSI inicia automaticamente junto com o Electron)
start /B npm start

echo.
echo [OK] Overlay iniciado!
echo.
echo Pressione qualquer tecla para fechar tudo...
pause >nul

echo.
echo Fechando overlay e servidor...
taskkill /F /IM electron.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1

echo [OK] Tudo fechado!
timeout /t 2 >nul
