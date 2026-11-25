# 04-install-on-device.ps1
# Installs the built APK on a connected Android device (or a running
# emulator) with adb, and verifies the package landed, reading its
# versionName back from the device.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# It locates the SDK and the clone (work folder defaults to
# <Drive>:\CapacitorTemplate, as in scripts 02/03).
#
# Usage (PowerShell):
#   .\04-install-on-device.ps1 -Drive 'F'
#
# Requires: script 03 completed, and a device connected with USB
# debugging enabled (or an emulator running).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\CapacitorTemplate" }
$Project = Join-Path $WorkFolder 'capacitor-blank-template'
$adb = "${Drive}:\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { throw "adb not found at $adb. Run script 01 first." }
$apk = Join-Path $Project 'android\app\build\outputs\apk\debug\app-debug.apk'
if (-not (Test-Path $apk)) { throw "APK not found. Run script 03 first." }
$PackageId = 'com.aeliteestrangeira.capacitorblanktemplate'

$devices = & $adb devices | Select-String "`tdevice$"
if (-not $devices) { throw 'No Android device in state "device". Connect one with USB debugging on, or start an emulator.' }

Write-Host "Installing $apk ..."
& $adb install -r $apk
if ($LASTEXITCODE -ne 0) { throw "adb install failed (exit $LASTEXITCODE)." }

$listed = & $adb shell pm list packages $PackageId
if ($listed -notmatch [regex]::Escape($PackageId)) { throw "Package $PackageId not listed after install." }
$dump = & $adb shell dumpsys package $PackageId | Select-String 'versionName='
Write-Host "INSTALL OK: $PackageId on the device ($dump)"
