# 04-install-app.ps1
# Installs the packed app SILENTLY (Velopack Setup with --silent):
# per-user, no wizard, no confirmation prompts, no admin rights.
# Verifies the installed layout afterwards.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# It only locates the packed Setup (work folder defaults to
# <Drive>:\BlazorTemplate, as in scripts 02/03). The app itself always
# installs per-user into %LocalAppData%\BlazorBlankTemplate - that is
# Velopack's design and is not drive-selectable.
#
# Usage (PowerShell):
#   .\04-install-app.ps1 -Drive 'F'
#
# Requires: script 03 completed (a packed release under the clone).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\BlazorTemplate" }
$Project = Join-Path $WorkFolder 'blazor-rz-blank-template'

$setup = Get-ChildItem (Join-Path $Project 'releases') -Recurse -Filter 'BlazorBlankTemplate-win-Setup.exe' |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $setup) { throw 'No Setup.exe found under releases. Run script 03 first.' }

Write-Host "Installing silently: $($setup.FullName)"
$proc = Start-Process $setup.FullName -ArgumentList '--silent' -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "Setup failed (exit $($proc.ExitCode))." }

$installDir = Join-Path $env:LOCALAPPDATA 'BlazorBlankTemplate'
$updateExe = Join-Path $installDir 'Update.exe'
$appExe = Join-Path $installDir 'current\BlazorBlankTemplate.exe'
if (-not (Test-Path $updateExe)) { throw "Install incomplete: $updateExe not found." }
if (-not (Test-Path $appExe)) { throw "Install incomplete: $appExe not found." }

$version = (Get-Item $appExe).VersionInfo.FileVersion
Write-Host "INSTALL OK: version $version at $installDir"
