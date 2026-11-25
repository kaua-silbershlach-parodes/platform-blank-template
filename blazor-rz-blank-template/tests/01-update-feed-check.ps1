# 01-update-feed-check.ps1 (test)
# Standalone check of the GitHub update feed the app consumes:
# downloads releases.win.json from the newest release, parses it, and
# compares the feed version with the installed one.
#
# Usage (PowerShell):
#   .\01-update-feed-check.ps1

$ErrorActionPreference = 'Stop'
$feedUrl = 'https://github.com/kaua-silbershlach-parodes/blazor-rz-blank-template/releases/latest/download/releases.win.json'

$feed = Invoke-RestMethod -Uri $feedUrl
$asset = $feed.Assets | Select-Object -First 1
if (-not $asset) { throw 'Feed has no assets.' }
Write-Host "Feed version: $($asset.Version) | file: $($asset.FileName) | size: $($asset.Size) | sha256: $($asset.SHA256)"

$appExe = Join-Path $env:LOCALAPPDATA 'BlazorBlankTemplate\current\BlazorBlankTemplate.exe'
if (Test-Path $appExe) {
    $installed = (Get-Item $appExe).VersionInfo.FileVersion
    Write-Host "Installed version: $installed"
    if ([version]$asset.Version -gt [version]$installed) {
        Write-Host 'An update is available on the feed.'
    } else {
        Write-Host 'The installed copy is current.'
    }
} else {
    Write-Host 'App not installed on this machine (feed check only).'
}

Write-Host 'FEED CHECK OK'
