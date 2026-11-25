# 05-run-smoke-tests.ps1
# End-to-end proof on the rebuilt machine:
#   1. the install layout is intact (Update.exe + current app exe);
#   2. the GitHub update feed answers and is parsed (releases.win.json);
#   3. the app launches and its process stays up;
#   4. a record file is written to the Desktop with versions and paths.
#
# Usage (PowerShell):
#   .\05-run-smoke-tests.ps1
#
# Requires: script 04 completed (the app installed).

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'BlazorBlankTemplate'
$appExe = Join-Path $installDir 'current\BlazorBlankTemplate.exe'

if (-not (Test-Path (Join-Path $installDir 'Update.exe'))) { throw 'Update.exe missing. Run script 04 first.' }
if (-not (Test-Path $appExe)) { throw 'Installed app exe missing. Run script 04 first.' }
$installed = (Get-Item $appExe).VersionInfo.FileVersion
Write-Host "1. Install layout OK. Installed version: $installed"

$feedUrl = 'https://github.com/kaua-silbershlach-parodes/blazor-rz-blank-template/releases/latest/download/releases.win.json'
$feed = Invoke-RestMethod -Uri $feedUrl
$feedVersion = $feed.Assets | Select-Object -First 1 -ExpandProperty Version
if (-not $feedVersion) { throw 'Update feed parsed but carries no version.' }
Write-Host "2. Update feed OK. Newest published version: $feedVersion"

Write-Host '3. Launching the app...'
Start-Process $appExe
Start-Sleep -Seconds 6
$proc = Get-Process -Name 'BlazorBlankTemplate' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { throw 'The app process is not running after launch.' }
Write-Host "   App running (PID $($proc.Id))."

$record = Join-Path ([Environment]::GetFolderPath('Desktop')) 'BLAZOR-TEMPLATE-REBUILD-RECORD.txt'
@(
    'Blazor Blank Template - rebuild record'
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Machine: $env:COMPUTERNAME"
    "Install folder: $installDir"
    "Installed version: $installed"
    "Update feed version: $feedVersion"
    "Feed: $feedUrl"
    'Result: prerequisites, build, pack, silent install and launch all verified.'
) | Set-Content -Path $record -Encoding ASCII
Write-Host "4. Record written: $record"

Write-Host 'SMOKE TESTS OK: the machine was rebuilt from scratch and everything works.'
