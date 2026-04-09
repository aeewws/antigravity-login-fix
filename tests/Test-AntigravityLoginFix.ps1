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

$tempRoot = Join-Path $env:TEMP ("antigravity-login-fix-test-" + [Guid]::NewGuid().ToString('N'))
$fixtureRoot = Join-Path $tempRoot 'Antigravity'
$fixtureMainJs = Join-Path $fixtureRoot 'resources\app\out\main.js'
$fixtureBackupDir = Join-Path $tempRoot 'backup'
$invalidShapeRoot = Join-Path $tempRoot 'AntigravityBadShape'
$invalidShapeMainJs = Join-Path $invalidShapeRoot 'resources\app\out\main.js'

try {
    if (Test-SupportedVersion -Version '2.0.0') {
        throw 'Test-SupportedVersion incorrectly accepted 2.0.0.'
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Path $fixtureMainJs -Parent), $fixtureBackupDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $SourceInstallRoot 'Antigravity.exe') -Destination (Join-Path $fixtureRoot 'Antigravity.exe')

    $liveMainJsPath = Join-Path $SourceInstallRoot 'resources\app\out\main.js'
    $liveContent = Read-Utf8Text -Path $liveMainJsPath
    $fixtureOriginal = Remove-KnownShimFromContent -Content $liveContent
    Write-Utf8NoBomText -Path $fixtureMainJs -Content $fixtureOriginal

    & "$repoRoot\check.ps1" -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir
    if ($LASTEXITCODE -ne 0) {
        throw 'check.ps1 failed on the initial pass.'
    }

    & "$repoRoot\install.ps1" -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -ne 0) {
        throw 'install.ps1 failed on the initial install.'
    }

    $patchedContent = Read-Utf8Text -Path $fixtureMainJs
    if ($patchedContent -notmatch [Regex]::Escape($script:PatchMarker)) {
        throw 'Repository patch marker was not found after install.'
    }

    & "$repoRoot\install.ps1" -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -ne 0) {
        throw 'install.ps1 failed the idempotence test.'
    }

    & "$repoRoot\restore.ps1" -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -ne 0) {
        throw 'restore.ps1 failed during restore.'
    }

    $restoredContent = Read-Utf8Text -Path $fixtureMainJs
    if ($restoredContent -ne $fixtureOriginal) {
        throw 'Restored main.js does not match the original fixture content.'
    }

    & "$repoRoot\install.ps1" -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -ne 0) {
        throw 'install.ps1 failed before corrupted-backup restore test.'
    }

    Write-Utf8NoBomText -Path (Join-Path $fixtureBackupDir 'main.js.antigravity-login-fix.backup.js') -Content 'console.log("corrupted backup");'
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$repoRoot\restore.ps1" -TargetPath $fixtureRoot -BackupDir $fixtureBackupDir -Force
    if ($LASTEXITCODE -eq 0) {
        throw 'restore.ps1 unexpectedly succeeded with a corrupted backup.'
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File "$repoRoot\check.ps1" -TargetPath (Join-Path $tempRoot 'MissingInstall')
    if ($LASTEXITCODE -eq 0) {
        throw 'check.ps1 unexpectedly succeeded for a missing target path.'
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Path $invalidShapeMainJs -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $SourceInstallRoot 'Antigravity.exe') -Destination (Join-Path $invalidShapeRoot 'Antigravity.exe')
    Write-Utf8NoBomText -Path $invalidShapeMainJs -Content 'console.log("not-a-real-antigravity-main");'

    & powershell -NoProfile -ExecutionPolicy Bypass -File "$repoRoot\install.ps1" -TargetPath $invalidShapeRoot -Force
    if ($LASTEXITCODE -eq 0) {
        throw 'install.ps1 unexpectedly succeeded for an invalid main.js shape.'
    }

    Write-Host 'Test passed: check, install, idempotence, restore, and corrupted-backup rejection all succeeded.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
