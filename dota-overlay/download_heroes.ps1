$ErrorActionPreference = "Stop"
$base = "https://cdn.cloudflare.steamstatic.com/apps/dota2/images/heroes"
$outDir = "templates/heroes"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$heroes = Invoke-RestMethod "https://api.opendota.com/api/heroes"
foreach ($h in $heroes) {
    $short = $h.name.Replace("npc_dota_hero_", "")
    $url = "$base/$short`_full.png"
    $dest = Join-Path $outDir ("npc_dota_hero_{0}.png" -f $short)
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing | Out-Null
        Write-Host "OK  $($h.localized_name)" -ForegroundColor Green
    } catch {
        Write-Host "FAIL $($h.localized_name) $url" -ForegroundColor Red
    }
}
