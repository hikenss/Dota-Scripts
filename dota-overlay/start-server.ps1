param(
    [string]$ProjectPath = "C:\Users\edcfa\Downloads\Umbrela\scripts\dota-overlay"
)

Push-Location $ProjectPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SERVIDOR GSI PARA DOTA 2 OVERLAY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Iniciando servidor em http://localhost:3000" -ForegroundColor Green
Write-Host "WebSocket rodando em ws://localhost:3001" -ForegroundColor Green
Write-Host ""
Write-Host "O servidor ficará ativo até você pressionar Ctrl+C" -ForegroundColor Yellow
Write-Host "Abra o overlay agora com: npm start" -ForegroundColor Yellow
Write-Host ""

try {
    node src/server.js
} finally {
    Pop-Location
    Write-Host ""
    Write-Host "Servidor encerrado." -ForegroundColor Red
}
