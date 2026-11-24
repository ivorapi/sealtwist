$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$addon = Join-Path $root 'RapiTwist'
$manifest = Get-Content -LiteralPath (Join-Path $addon 'RapiTwist.toc') -Raw
if ($manifest -notmatch '(?m)^## Version:\s*(\d+\.\d+\.\d+)\s*$') { throw 'Versión inválida en el manifiesto' }
$version = $Matches[1]
$dist = New-Item -ItemType Directory -Path (Join-Path $root 'dist') -Force
$zip = Join-Path $dist.FullName "RapiTwist-$version.zip"
Compress-Archive -LiteralPath $addon -DestinationPath $zip -Force
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($name in 'RapiTwist.toc', 'RapiTwist.lua', 'LEEME.txt', 'LICENSE.txt') {
        if (-not $archive.GetEntry("RapiTwist/$name")) { throw "Falta $name en el ZIP" }
    }
} finally {
    $archive.Dispose()
}
Write-Output $zip
