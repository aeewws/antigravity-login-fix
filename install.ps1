param(
    [string]$TargetPath,
    [string]$BackupDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. "$PSScriptRoot\lib\AntigravityLoginFix.Common.ps1"

try {
    $state = Get-AntigravityInstallInfo -TargetPath $TargetPath -BackupDir $BackupDir
    Write-Host (Format-StateReport -State $state)
    Write-Host ''

    if (-not $state.IsSupportedVersion) {
        throw "Version $($state.Version) is not supported. Only 1.2x is supported."
    }

    if (-not $state.HasExpectedShape) {
        throw 'main.js does not match the expected file shape. No changes were written.'
    }

    if ($state.IsPatched) {
        Write-Host "A BigInt login shim is already present: $($state.PatchStatus). No changes were made."
        exit 0
    }

    if (-not (Confirm-Action -Message "A login patch will be injected into $($state.MainJsPath) and a backup will be created at $($state.BackupPath). Continue?" -Force:$Force)) {
        Write-Host 'Canceled.'
        exit 1
    }

    Ensure-Backup -State $state

    $patchedContent = $script:PatchSnippet + [Environment]::NewLine + $state.Content
    Write-Utf8NoBomText -Path $state.MainJsPath -Content $patchedContent

    $verify = Get-AntigravityInstallInfo -TargetPath $state.Root -BackupDir $BackupDir
    if (-not $verify.IsPatched) {
        throw 'Post-write verification failed. main.js is not in a patched state.'
    }

    Write-Host "Patch completed. Current state: $($verify.PatchStatus)"
    Write-Host "Backup file: $($verify.BackupPath)"
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
