# 02-install-integrity-check.ps1 (test)
# Standalone check of a Velopack install of this app on this machine:
# Update.exe present, current app exe present, version readable, and
# the install was registered by Velopack (packages folder present).
#
# Usage (PowerShell):
#   .\02-install-integrity-check.ps1

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'BlazorBlankTemplate'

$checks = @(
    @{ Name = 'Update.exe'; Path = (Join-Path $installDir 'Update.exe') },
    @{ Name = 'current app exe'; Path = (Join-Path $installDir 'current\BlazorBlankTemplate.exe') },
    @{ Name = 'packages folder'; Path = (Join-Path $installDir 'packages') }
)
foreach ($c in $checks) {
    if (-not (Test-Path $c.Path)) { throw "Missing: $($c.Name) at $($c.Path)" }
    Write-Host "OK: $($c.Name)"
}

$version = (Get-Item $checks[1].Path).VersionInfo.FileVersion
Write-Host "Installed version: $version"
Write-Host 'INTEGRITY CHECK OK'
