Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:PatchMarker = 'antigravity-login-fix-bigint-shim'
$script:LegacyPatchMarkers = @(
    $script:PatchMarker,
    'codex-bigint-json-shim'
)
$script:PatchSnippet = ';(()=>{try{if(typeof BigInt==="function"&&!BigInt.prototype.toJSON){Object.defineProperty(BigInt.prototype,"toJSON",{value:function(){return this.toString()},configurable:true});}}catch{}})();/* antigravity-login-fix-bigint-shim */'

function Resolve-AntigravityRoot {
    param(
        [string]$TargetPath
    )

    $candidatePaths = New-Object System.Collections.Generic.List[string]

    if ($TargetPath) {
        if (-not (Test-Path -LiteralPath $TargetPath)) {
            throw "Target path does not exist: $TargetPath"
        }

        $resolved = (Resolve-Path -LiteralPath $TargetPath).Path
        if ((Get-Item -LiteralPath $resolved).PSIsContainer) {
            $candidatePaths.Add($resolved)
        }
        else {
            if ([System.IO.Path]::GetFileName($resolved) -ne 'Antigravity.exe') {
                throw 'TargetPath must be an Antigravity install directory or Antigravity.exe.'
            }
            $candidatePaths.Add((Split-Path -Path $resolved -Parent))
        }
    }
    else {
        $candidatePaths.Add((Join-Path $env:LOCALAPPDATA 'Programs\Antigravity'))
        $candidatePaths.Add((Join-Path $env:ProgramFiles 'Antigravity'))
        if ($env:ProgramFiles -and ${env:ProgramFiles(x86)}) {
            $candidatePaths.Add((Join-Path ${env:ProgramFiles(x86)} 'Antigravity'))
        }
    }

    foreach ($candidate in $candidatePaths) {
        $exePath = Join-Path $candidate 'Antigravity.exe'
        if (Test-Path -LiteralPath $exePath) {
            return $candidate
        }
    }

    throw 'Antigravity install directory was not found. Use -TargetPath to specify it.'
}

function Get-AntigravityInstallInfo {
    param(
        [string]$TargetPath,
        [string]$BackupDir
    )

    $root = Resolve-AntigravityRoot -TargetPath $TargetPath
    $exePath = Join-Path $root 'Antigravity.exe'
    $mainJsPath = Join-Path $root 'resources\app\out\main.js'

    if (-not (Test-Path -LiteralPath $mainJsPath)) {
        throw "Target file was not found: $mainJsPath"
    }

    $version = (Get-Item -LiteralPath $exePath).VersionInfo.ProductVersion
    $content = Read-Utf8Text -Path $mainJsPath
    $backupPath = Get-BackupPath -MainJsPath $mainJsPath -BackupDir $BackupDir
    $patchStatus = Get-PatchStatus -Content $content

    [pscustomobject]@{
        Root = $root
        ExePath = $exePath
        MainJsPath = $mainJsPath
        Version = $version
        IsSupportedVersion = Test-SupportedVersion -Version $version
        HasExpectedShape = Test-MainJsShape -Content $content
        PatchStatus = $patchStatus
        IsPatched = ($patchStatus -ne 'Unpatched')
        BackupPath = $backupPath
        BackupExists = (Test-Path -LiteralPath $backupPath)
        Content = $content
    }
}

function Get-BackupPath {
    param(
        [string]$MainJsPath,
        [string]$BackupDir
    )

    if ($BackupDir) {
        return (Join-Path $BackupDir 'main.js.antigravity-login-fix.backup.js')
    }

    return (Join-Path (Split-Path -Path $MainJsPath -Parent) 'main.js.antigravity-login-fix.backup.js')
}

function Read-Utf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8NoBomText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)
    $tempPath = '{0}.{1}.tmp' -f $Path, ([Guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, $encoding)
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-SupportedVersion {
    param(
        [string]$Version
    )

    return ($Version -match '^1\.2\d+(?:\.|$)')
}

function Test-MainJsShape {
    param(
        [string]$Content
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $false
    }

    return (
        $Content.Length -gt 1000 -and
        $Content.Contains('Copyright (C) Microsoft Corporation. All rights reserved.') -and
        $Content.Contains('Object.create')
    )
}

function Get-PatchStatus {
    param(
        [string]$Content
    )

    if ($Content.Contains($script:PatchMarker)) {
        return 'RepositoryShim'
    }

    if ($Content.Contains('codex-bigint-json-shim')) {
        return 'LegacyCodexShim'
    }

    if ($Content.Contains('BigInt.prototype.toJSON')) {
        return 'UnknownBigIntShim'
    }

    return 'Unpatched'
}

function Test-RestoreBackupContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    return (
        (Test-MainJsShape -Content $Content) -and
        (Get-PatchStatus -Content $Content) -eq 'Unpatched'
    )
}

function Remove-KnownShimFromContent {
    param(
        [string]$Content
    )

    $bannerIndex = $Content.IndexOf('/*!')
    if ($bannerIndex -gt 0 -and $Content.Substring(0, $bannerIndex).Contains('BigInt.prototype.toJSON')) {
        return $Content.Substring($bannerIndex)
    }

    $patterns = @(
        '^\s*;\(\(\)=>\{try\{if\(typeof BigInt==="function"&&!BigInt\.prototype\.toJSON\)\{Object\.defineProperty\(BigInt\.prototype,"toJSON",\{value:function\(\)\{return this\.toString\(\)\},configurable:true\}\);\}\}\catch\{\}\}\)\(\);\s*/\*\s*antigravity-login-fix-bigint-shim\s*\*/\s*',
        '^\s*;\(\(\)=>\{try\{if\(typeof BigInt==="function"&&!BigInt\.prototype\.toJSON\)\{Object\.defineProperty\(BigInt\.prototype,"toJSON",\{value:function\(\)\{return this\.toString\(\)\},configurable:true\}\);\}\}\catch\{\}\}\)\(\);\s*/\*\s*codex-bigint-json-shim\s*\*/\s*'
    )

    $result = $Content
    foreach ($pattern in $patterns) {
        $result = [System.Text.RegularExpressions.Regex]::Replace(
            $result,
            $pattern,
            '',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
    }

    return $result
}

function Confirm-Action {
    param(
        [string]$Message,
        [switch]$Force
    )

    if ($Force) {
        return $true
    }

    $choice = Read-Host "$Message [y/N]"
    return ($choice -match '^(y|yes)$')
}

function Ensure-Backup {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State
    )

    if ($State.BackupExists) {
        $existingBackup = Read-Utf8Text -Path $State.BackupPath
        if ($existingBackup -ne $State.Content) {
            throw "Backup already exists and does not match current main.js: $($State.BackupPath)"
        }
        return
    }

    Write-Utf8NoBomText -Path $State.BackupPath -Content $State.Content
}

function Format-StateReport {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State
    )

    $patchText = switch ($State.PatchStatus) {
        'RepositoryShim' { 'patched (repository shim)' }
        'LegacyCodexShim' { 'patched (legacy codex shim)' }
        'UnknownBigIntShim' { 'patched (unknown BigInt shim)' }
        default { 'unpatched' }
    }

    return @(
        "Install root: $($State.Root)"
        "Version: $($State.Version)"
        "Supported version: $(if ($State.IsSupportedVersion) { 'yes' } else { 'no' })"
        "main.js path: $($State.MainJsPath)"
        "Feature match: $(if ($State.HasExpectedShape) { 'yes' } else { 'no' })"
        "Patch status: $patchText"
        "Backup path: $($State.BackupPath)"
        "Backup exists: $(if ($State.BackupExists) { 'yes' } else { 'no' })"
    ) -join [Environment]::NewLine
}
