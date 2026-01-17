@echo off
title Dota 2 Overlay + Dota Auto-Start
color 0B

cd /d "%~dp0"

echo.
echo ========================================
echo    INICIANDO OVERLAY + DOTA 2
echo ========================================
echo.

echo Limpando processos anteriores...
taskkill /F /IM electron.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
echo Aguardando portas serem liberadas...
timeout /t 2 /nobreak >nul

REM Inicia o overlay (servidor GSI inicia automaticamente)
echo [1/2] Iniciando overlay...
start "" npm start

REM Aguarda 3 segundos
timeout /t 3 /nobreak >nul

REM Inicia o Dota 2
echo [2/2] Abrindo Dota 2...
start steam://rungameid/570

echo.
echo ========================================
echo [OK] Tudo iniciado com sucesso!
echo ========================================
echo.
echo O overlay vai aparecer quando entrar em partida.
echo.
echo Pressione qualquer tecla para fechar tudo...
pause >nul

echo.
echo Fechando...
taskkill /F /IM electron.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
echo [OK] Fechado!
timeout /t 1 >nul
