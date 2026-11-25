# 05-run-smoke-tests.ps1
# End-to-end proof on the rebuilt machine:
#   1. the toolchain answers (Node, JDK 21, the four SDK components);
#   2. BOTH update channels answer and parse (GitHub latest.json and
#      the Hostinger latest.json) - the two channels this template
#      proved on a real phone;
#   3. if a device is connected, the installed app launches on it;
#      without a device this step is reported as skipped, not failed;
#   4. a record file is written to the Desktop.
#
# Usage (PowerShell):
#   .\05-run-smoke-tests.ps1 -Drive 'F'
#
# Requires: scripts 01-03 completed (04 too, for the launch step).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive
)

$ErrorActionPreference = 'Stop'
$SdkDir = "${Drive}:\Android\Sdk"

$node = & "${Drive}:\nodejs\node.exe" --version
$java = & "${Drive}:\jdk-21\bin\java.exe" -version 2>&1 | Select-Object -First 1
foreach ($p in @('platforms\android-35', 'build-tools\35.0.0', 'build-tools\34.0.0', 'platform-tools\adb.exe')) {
    if (-not (Test-Path (Join-Path $SdkDir $p))) { throw "Missing SDK component: $p" }
}
Write-Host "1. Toolchain OK: Node $node | $java | SDK components present."

$gh = Invoke-RestMethod -Uri 'https://github.com/kaua-silbershlach-parodes/capacitor-blank-template/releases/latest/download/latest.json'
$hs = Invoke-RestMethod -Uri 'https://aeliteestrangeira.com/capacitor-updates/latest.json'
if (-not $gh.version -or -not $hs.version) { throw 'A channel answered without a version.' }
Write-Host "2. Update channels OK: GitHub serves $($gh.version) | Hostinger serves $($hs.version)."

$PackageId = 'com.aeliteestrangeira.capacitorblanktemplate'
$adb = Join-Path $SdkDir 'platform-tools\adb.exe'
$launch = 'skipped (no device connected)'
$devices = & $adb devices | Select-String "`tdevice$"
if ($devices) {
    & $adb shell monkey -p $PackageId -c android.intent.category.LAUNCHER 1 | Out-Null
    Start-Sleep -Seconds 4
    $appPid = & $adb shell pidof $PackageId
    if (-not $appPid) { throw 'The app did not stay up after launch.' }
    $launch = "launched on device (pid $appPid)"
}
Write-Host "3. Device launch: $launch."

$record = Join-Path ([Environment]::GetFolderPath('Desktop')) 'CAPACITOR-TEMPLATE-REBUILD-RECORD.txt'
@(
    'Capacitor Blank Template - rebuild record'
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Machine: $env:COMPUTERNAME"
    "Node: $node"
    "Java: $java"
    "Android SDK: $SdkDir"
    "GitHub channel version: $($gh.version)"
    "Hostinger channel version: $($hs.version)"
    "Device launch: $launch"
    'Result: toolchain, APK build inputs and both update channels verified.'
) | Set-Content -Path $record -Encoding ASCII
Write-Host "4. Record written: $record"

Write-Host 'SMOKE TESTS OK: the machine was rebuilt from scratch and everything checks out.'
