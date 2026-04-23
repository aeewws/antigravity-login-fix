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

    if (-not $state.BackupExists) {
        throw "Backup file was not found: $($state.BackupPath)"
    }

    $backupContent = Read-Utf8Text -Path $state.BackupPath
    if (-not (Test-RestoreBackupContent -Content $backupContent)) {
        throw "Backup file does not look like a valid unpatched Antigravity main.js: $($state.BackupPath)"
    }

    if (-not (Confirm-Action -Message "Backup content will be restored to $($state.MainJsPath). Continue?" -Force:$Force)) {
        Write-Host 'Canceled.'
        exit 1
    }

    Write-Utf8NoBomText -Path $state.MainJsPath -Content $backupContent

    $verify = Get-AntigravityInstallInfo -TargetPath $state.Root -BackupDir $BackupDir
    if ($verify.PatchStatus -ne 'Unpatched') {
        throw "Restore verification failed. Current patch state is $($verify.PatchStatus)."
    }
    if (-not $verify.HasExpectedShape) {
        throw 'Restore verification failed. main.js no longer matches the expected Antigravity shape.'
    }

    Write-Host 'Restore completed.'
    Write-Host "Current patch state: $($verify.PatchStatus)"
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
