$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$addon = Join-Path $root 'SealTwistVisual'
$manifest = Get-Content -LiteralPath (Join-Path $addon 'SealTwistVisual.toc') -Raw
if ($manifest -notmatch '(?m)^## Version:\s*(\d+\.\d+\.\d+)\s*$') { throw 'Versión inválida en el manifiesto' }
$version = $Matches[1]
$dist = New-Item -ItemType Directory -Path (Join-Path $root 'dist') -Force
$zip = Join-Path $dist.FullName "SealTwistVisual-$version.zip"
Compress-Archive -LiteralPath $addon -DestinationPath $zip -Force
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($name in 'SealTwistVisual.toc', 'SealTwistVisual.lua', 'LEEME.txt', 'LICENSE.txt') {
        if (-not $archive.GetEntry("SealTwistVisual/$name")) { throw "Falta $name en el ZIP" }
    }
} finally {
    $archive.Dispose()
}
Write-Output $zip
