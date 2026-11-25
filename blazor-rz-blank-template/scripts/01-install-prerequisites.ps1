# 01-install-prerequisites.ps1
# Installs everything a freshly formatted Windows machine needs to build
# this template: Git, the .NET 9 SDK, and the Velopack CLI (vpk).
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The .NET SDK is installed onto the chosen drive (<Drive>:\dotnet) via
# Microsoft's dotnet-install script, and DOTNET_ROOT + PATH (user level)
# are pointed at it, so the SDK and tools work from any new session.
# Git is small and system-level; winget installs it in the default
# location. Everything runs silently with agreements pre-accepted.
#
# Usage (PowerShell):
#   .\01-install-prerequisites.ps1 -Drive 'F'
#
# Requires: Windows 10/11 x64, internet access, winget (App Installer),
# about 2 GB free on the chosen drive. Prefer an INTERNAL drive.

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive
)

$ErrorActionPreference = 'Stop'
$DotNetDir = "${Drive}:\dotnet"

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;$DotNetDir;$env:USERPROFILE\.dotnet\tools"
    $env:DOTNET_ROOT = $DotNetDir
}

Write-Host 'Installing Git...'
& winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) { throw "Git install failed (winget exit $LASTEXITCODE)." }

Write-Host "Installing .NET SDK 9 into $DotNetDir..."
$installer = Join-Path $env:TEMP 'dotnet-install.ps1'
& curl.exe -L --fail -o $installer 'https://dot.net/v1/dotnet-install.ps1'
if ($LASTEXITCODE -ne 0) { throw 'Could not download dotnet-install.ps1.' }
& $installer -Channel '9.0' -InstallDir $DotNetDir
if ($LASTEXITCODE -ne 0) { throw ".NET SDK install failed (exit $LASTEXITCODE)." }

# Persist for future sessions: DOTNET_ROOT and PATH at user level.
[Environment]::SetEnvironmentVariable('DOTNET_ROOT', $DotNetDir, 'User')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$DotNetDir*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$DotNetDir", 'User')
}

Refresh-Path

Write-Host 'Installing the Velopack CLI (vpk)...'
& (Join-Path $DotNetDir 'dotnet.exe') tool install -g vpk
if ($LASTEXITCODE -ne 0) { throw "vpk install failed (dotnet exit $LASTEXITCODE)." }

Refresh-Path

$sdk = & (Join-Path $DotNetDir 'dotnet.exe') --list-sdks | Select-String '^9\.'
if (-not $sdk) { throw 'No .NET 9 SDK found after install.' }
Write-Host "SDK OK: $sdk"

& vpk --version | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'vpk does not respond after install.' }

Write-Host "PREREQUISITES OK: Git installed; .NET 9 SDK and vpk live in $DotNetDir."
