param(
    [string]$Version = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'VERSION') -Raw).Trim()
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$releaseRoot = Join-Path $PSScriptRoot 'dist'
$packageName = "antigravity-login-fix-v$Version"
$stageDir = Join-Path $releaseRoot $packageName
$zipPath = Join-Path $releaseRoot "$packageName.zip"
$hashPath = Join-Path $releaseRoot "$packageName.zip.sha256"

if (Test-Path -LiteralPath $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

if (Test-Path -LiteralPath $hashPath) {
    Remove-Item -LiteralPath $hashPath -Force
}

New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

$copyItems = @(
    'README.md',
    'LICENSE',
    'VERSION',
    'install.ps1',
    'check.ps1',
    'restore.ps1',
    'install.cmd',
    'check.cmd',
    'restore.cmd',
    'OneClickInstall.cmd',
    'OneClickCheck.cmd',
    'OneClickRestore.cmd'
)

foreach ($item in $copyItems) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $item) -Destination (Join-Path $stageDir $item)
}

Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'lib') -Destination (Join-Path $stageDir 'lib') -Recurse

Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $zipPath -CompressionLevel Optimal

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
$hashLine = "$hash  $([System.IO.Path]::GetFileName($zipPath))"
[System.IO.File]::WriteAllText($hashPath, $hashLine + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

Write-Host "Release package: $zipPath"
Write-Host "SHA256 file: $hashPath"
