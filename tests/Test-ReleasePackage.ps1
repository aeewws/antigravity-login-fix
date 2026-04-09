param(
    [string]$SourceInstallRoot = "$env:LOCALAPPDATA\Programs\Antigravity"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
. "$repoRoot\lib\AntigravityLoginFix.Common.ps1"

if (-not (Test-Path -LiteralPath (Join-Path $SourceInstallRoot 'Antigravity.exe'))) {
    throw "Source install root was not found: $SourceInstallRoot"
}

$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
$zipPath = Join-Path $repoRoot "dist\antigravity-login-fix-v$version.zip"
$tempRoot = Join-Path $env:TEMP ("antigravity-login-fix-release-test-" + [Guid]::NewGuid().ToString('N'))
$extractRoot = Join-Path $tempRoot 'release'
$fixtureRoot = Join-Path $tempRoot 'Antigravity'
$fixtureMainJs = Join-Path $fixtureRoot 'resources\app\out\main.js'
$fixtureBackupDir = Join-Path $tempRoot 'backup'

try {
    & "$repoRoot\build-release.ps1"
    if (-not $?) {
        throw 'build-release.ps1 failed.'
    }
    if (-not (Test-Path -LiteralPath $zipPath)) {
        throw "Release ZIP was not created: $zipPath"
    }

    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force
    $packageRoot = Join-Path $extractRoot ("antigravity-login-fix-v" + $version)
    if (-not (Test-Path -LiteralPath $packageRoot)) {
        $packageRoot = $extractRoot
    }

    foreach ($expected in @(
        'check.ps1',
        'install.ps1',
        'restore.ps1',
        'OneClickCheck.cmd',
        'OneClickInstall.cmd',
        'OneClickRestore.cmd',
        'lib\AntigravityLoginFix.Common.ps1'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $packageRoot $expected))) {
            throw "Packaged release is missing: $expected"
        }
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Path $fixtureMainJs -Parent), $fixtureBackupDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $SourceInstallRoot 'Antigravity.exe') -Destination (Join-Path $fixtureRoot 'Antigravity.exe')

    $liveMainJsPath = Join-Path $SourceInstallRoot 'resources\app\out\main.js'
    $fixtureOriginal = Remove-KnownShimFromContent -Content (Read-Utf8Text -Path $liveMainJsPath)
    Write-Utf8NoBomText -Path $fixtureMainJs -Content $fixtureOriginal

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $packageRoot 'check.ps1') -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir
    if ($LASTEXITCODE -ne 0) {
        throw 'Packaged check.ps1 failed.'
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $packageRoot 'install.ps1') -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -ne 0) {
        throw 'Packaged install.ps1 failed.'
    }

    $patchedContent = Read-Utf8Text -Path $fixtureMainJs
    if ($patchedContent -notmatch [Regex]::Escape($script:PatchMarker)) {
        throw 'Packaged install did not write the repository patch marker.'
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $packageRoot 'restore.ps1') -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -ne 0) {
        throw 'Packaged restore.ps1 failed.'
    }

    $restoredContent = Read-Utf8Text -Path $fixtureMainJs
    if ($restoredContent -ne $fixtureOriginal) {
        throw 'Packaged restore did not recover the original fixture content.'
    }

    Write-Host 'Packaged release smoke passed.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
