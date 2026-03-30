param(
    [string]$TargetPath,
    [string]$BackupDir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. "$PSScriptRoot\lib\AntigravityLoginFix.Common.ps1"

try {
    $state = Get-AntigravityInstallInfo -TargetPath $TargetPath -BackupDir $BackupDir
    Write-Host (Format-StateReport -State $state)
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
