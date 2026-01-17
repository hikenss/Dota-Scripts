param(
    [string]$ProjectPath = "C:\Users\edcfa\Downloads\Umbrela\scripts\dota-overlay",
    [int]$StartupDelaySecs = 3
)

Push-Location $ProjectPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESTE DO OVERLAY COM MOCK GSI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[AVISO] Este script é APENAS PARA TESTES sem o Dota 2!" -ForegroundColor Yellow
Write-Host "Para uso real com o jogo, use: .\start-server.ps1" -ForegroundColor Yellow
Write-Host ""

Write-Host "Iniciando servidor GSI..." -ForegroundColor Cyan
$server = Start-Process node -ArgumentList 'src/server.js' -WorkingDirectory $ProjectPath -PassThru

try {
    Write-Host "Aguardando $StartupDelaySecs segundos para o servidor subir..." -ForegroundColor Yellow
    Start-Sleep -Seconds $StartupDelaySecs

    Write-Host "Enviando mock-gsi com draft de teste..." -ForegroundColor Green
    node mock-gsi.js
    Write-Host ""
    Write-Host "✓ Mock enviado com sucesso!" -ForegroundColor Green
    Write-Host "Agora abra o overlay (npm start) para ver o draft de teste." -ForegroundColor Green
    Write-Host ""
    Write-Host "Pressione qualquer tecla para encerrar o servidor..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} finally {
    Write-Host "Parando o servidor GSI..." -ForegroundColor Cyan
    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
    Pop-Location
}
