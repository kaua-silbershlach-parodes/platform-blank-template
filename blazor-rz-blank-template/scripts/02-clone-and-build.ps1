# 02-clone-and-build.ps1
# Clones this repository (or updates an existing clone) and builds it in
# Release. The step only passes with a clean build: exit code 0.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The work folder defaults to <Drive>:\BlazorTemplate and can be
# overridden with -WorkFolder.
#
# Usage (PowerShell):
#   .\02-clone-and-build.ps1 -Drive 'F'
#
# Requires: script 01 completed (Git + .NET 9 SDK).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\BlazorTemplate" }
$RepoUrl = 'https://github.com/kaua-silbershlach-parodes/blazor-rz-blank-template.git'
$Project = Join-Path $WorkFolder 'blazor-rz-blank-template'

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

Write-Host 'Building (Release)...'
& dotnet build (Join-Path $Project 'BlazorBlankTemplate.csproj') -c Release
if ($LASTEXITCODE -ne 0) { throw "Build failed (dotnet exit $LASTEXITCODE)." }

Write-Host "BUILD OK: $Project compiles with 0 errors."
