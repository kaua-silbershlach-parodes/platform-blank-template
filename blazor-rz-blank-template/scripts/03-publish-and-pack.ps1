# 03-publish-and-pack.ps1
# Publishes the app self-contained for win-x64 and packs a Velopack
# release (Setup.exe + update packages) from it. The version is read
# from the project's <Version> in BlazorBlankTemplate.csproj.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The work folder defaults to <Drive>:\BlazorTemplate (same rule as
# script 02) and can be overridden with -WorkFolder.
#
# Usage (PowerShell):
#   .\03-publish-and-pack.ps1 -Drive 'F'
#
# Requires: scripts 01 and 02 completed. Output:
#   <clone>\releases\v<version>\BlazorBlankTemplate-win-Setup.exe (+ assets)

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\BlazorTemplate" }
$Project = Join-Path $WorkFolder 'blazor-rz-blank-template'
$Csproj = Join-Path $Project 'BlazorBlankTemplate.csproj'
if (-not (Test-Path $Csproj)) { throw "Project not found at $Project. Run script 02 first." }

$xml = Get-Content $Csproj -Raw
if ($xml -notmatch '<Version>([^<]+)</Version>') { throw 'Could not read <Version> from the csproj.' }
$Version = $Matches[1]
Write-Host "Project version: $Version"

$PublishDir = Join-Path $Project 'publish\win-x64'
Write-Host 'Publishing (win-x64, self-contained)...'
& dotnet publish $Csproj -c Release -r win-x64 --self-contained true -o $PublishDir
if ($LASTEXITCODE -ne 0) { throw "Publish failed (dotnet exit $LASTEXITCODE)." }

$OutDir = Join-Path $Project "releases\v$Version"
Write-Host "Packing the Velopack release into $OutDir..."
& vpk pack --runtime win-x64 --packId BlazorBlankTemplate --packVersion $Version `
    --packDir $PublishDir --mainExe BlazorBlankTemplate.exe `
    --packTitle 'Blazor Blank Template' --packAuthors 'A Elite Estrangeira' `
    --icon (Join-Path $Project 'icon.ico') --outputDir $OutDir
if ($LASTEXITCODE -ne 0) { throw "vpk pack failed (exit $LASTEXITCODE)." }

$expected = @('BlazorBlankTemplate-win-Setup.exe', "BlazorBlankTemplate-$Version-full.nupkg",
              'BlazorBlankTemplate-win-Portable.zip', 'RELEASES', 'releases.win.json', 'assets.win.json')
foreach ($name in $expected) {
    if (-not (Test-Path (Join-Path $OutDir $name))) { throw "Missing pack output: $name" }
}

Write-Host "PACK OK: $OutDir contains the Setup.exe and the update feed files."
