@echo off
echo Fechando Dota 2 Overlay e Servidor GSI...
taskkill /F /IM electron.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
echo Overlay e servidor fechados!
timeout /t 1 >nul
