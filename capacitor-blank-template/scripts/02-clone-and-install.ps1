# 02-clone-and-install.ps1
# Clones this repository (or updates an existing clone) and installs the
# npm dependencies (Capacitor core/CLI, the Capgo updater). Passes when
# the Capacitor CLI is present in node_modules.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The work folder defaults to <Drive>:\CapacitorTemplate and can be
# overridden with -WorkFolder.
#
# Usage (PowerShell):
#   .\02-clone-and-install.ps1 -Drive 'F'
#
# Requires: script 01 completed (Git + Node.js).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\CapacitorTemplate" }
$RepoUrl = 'https://github.com/kaua-silbershlach-parodes/capacitor-blank-template.git'
$Project = Join-Path $WorkFolder 'capacitor-blank-template'

New-Item -ItemType Directory -Force -Path $WorkFolder | Out-Null

if (Test-Path (Join-Path $Project '.git')) {
    Write-Host 'Existing clone found. Pulling...'
    & git -C $Project pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw "git pull failed (exit $LASTEXITCODE)." }
} else {
    Write-Host 'Cloning the repository...'
    & git clone $RepoUrl $Project
    if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)." }
}

Write-Host 'Installing npm dependencies...'
& npm --prefix $Project install
if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit $LASTEXITCODE)." }

if (-not (Test-Path (Join-Path $Project 'node_modules\@capacitor\cli'))) { throw 'Capacitor CLI missing after install.' }
if (-not (Test-Path (Join-Path $Project 'node_modules\@capgo\capacitor-updater'))) { throw 'Capgo updater missing after install.' }

Write-Host "DEPENDENCIES OK: $Project is ready to build."
