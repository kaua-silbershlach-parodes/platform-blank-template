# 01-update-channels-check.ps1 (test)
# Standalone check of BOTH live-update channels this template uses:
# the GitHub Releases channel and the Hostinger channel. Each must
# answer with a parseable latest.json (version, url, checksum).
#
# Usage (PowerShell):
#   .\01-update-channels-check.ps1

$ErrorActionPreference = 'Stop'
$channels = @(
    @{ Name = 'GitHub'; Url = 'https://github.com/kaua-silbershlach-parodes/capacitor-blank-template/releases/latest/download/latest.json' },
    @{ Name = 'Hostinger'; Url = 'https://aeliteestrangeira.com/capacitor-updates/latest.json' }
)
foreach ($c in $channels) {
    $m = Invoke-RestMethod -Uri $c.Url
    if (-not $m.version -or -not $m.url -or -not $m.checksum) { throw "$($c.Name) manifest is incomplete." }
    Write-Host "$($c.Name) OK: version $($m.version) | bundle $($m.url) | sha256 $($m.checksum)"
}

Write-Host 'CHANNELS CHECK OK'
