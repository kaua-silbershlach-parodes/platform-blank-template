# 03-build-apk.ps1
# Syncs the web app into the Android platform and builds the debug APK
# with the Gradle wrapper (which downloads its own Gradle and the
# Android dependencies on first run - the standard path on a normal
# machine). Verifies the APK exists and reports its size.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The work folder defaults to <Drive>:\CapacitorTemplate (same rule as
# script 02) and can be overridden with -WorkFolder.
#
# Usage (PowerShell):
#   .\03-build-apk.ps1 -Drive 'F'
#
# Requires: scripts 01 and 02 completed. Output:
#   <clone>\android\app\build\outputs\apk\debug\app-debug.apk

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\CapacitorTemplate" }
$Project = Join-Path $WorkFolder 'capacitor-blank-template'
if (-not (Test-Path (Join-Path $Project 'capacitor.config.ts'))) { throw "Project not found at $Project. Run script 02 first." }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = "${Drive}:\jdk-21" }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "${Drive}:\Android\Sdk" }

Write-Host 'Syncing the web app into Android (cap sync)...'
& npx --prefix $Project cap sync android
if ($LASTEXITCODE -ne 0) { throw "cap sync failed (exit $LASTEXITCODE)." }

Write-Host 'Building the debug APK (gradlew assembleDebug)...'
Push-Location (Join-Path $Project 'android')
try {
    & .\gradlew.bat assembleDebug
    if ($LASTEXITCODE -ne 0) { throw "Gradle build failed (exit $LASTEXITCODE)." }
} finally {
    Pop-Location
}

$apk = Join-Path $Project 'android\app\build\outputs\apk\debug\app-debug.apk'
if (-not (Test-Path $apk)) { throw "APK not found at $apk" }
$size = (Get-Item $apk).Length
Write-Host "BUILD OK: $apk ($size bytes)"
