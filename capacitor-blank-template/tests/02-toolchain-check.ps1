# 02-toolchain-check.ps1 (test)
# Standalone check of the build toolchain on this machine: Node,
# JDK 21 (Capacitor 7 fails on older JDKs), and the Android SDK
# components the build needs - including build-tools 34.0.0, which
# AGP requires alongside 35.0.0.
#
# Usage (PowerShell):
#   .\02-toolchain-check.ps1 -Drive 'F'

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive
)

$ErrorActionPreference = 'Stop'

$node = & "${Drive}:\nodejs\node.exe" --version
if (-not $node) { throw 'Node.js not found.' }
Write-Host "OK: Node $node"

$java = & "${Drive}:\jdk-21\bin\java.exe" -version 2>&1 | Select-Object -First 1
if ($java -notmatch '21\.') { throw "JDK 21 not found (got: $java)." }
Write-Host "OK: $java"

$SdkDir = "${Drive}:\Android\Sdk"
foreach ($p in @('platforms\android-35', 'build-tools\35.0.0', 'build-tools\34.0.0', 'platform-tools\adb.exe', 'cmdline-tools\latest\bin\sdkmanager.bat')) {
    if (-not (Test-Path (Join-Path $SdkDir $p))) { throw "Missing SDK component: $p" }
    Write-Host "OK: $p"
}

Write-Host 'TOOLCHAIN CHECK OK'
