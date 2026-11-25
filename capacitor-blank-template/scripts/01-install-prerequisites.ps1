# 01-install-prerequisites.ps1
# Installs everything a freshly formatted Windows machine needs to build
# this template: Git, Node.js (with npm), a JDK 21, and the Android SDK
# (platform 35, build-tools 35.0.0 AND 34.0.0, platform-tools).
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# Everything lives on the chosen drive: <Drive>:\nodejs,
# <Drive>:\jdk-21, <Drive>:\Android\Sdk. JAVA_HOME and ANDROID_HOME are
# set at user level. Downloads are verified BEFORE extraction: Node by
# exact size + SHA256 (official SHASUMS256), the JDK and the Android
# command-line tools by exact size from the official hosts (Microsoft
# and dl.google.com publish no checksum file for these two zips).
#
# Usage (PowerShell):
#   .\01-install-prerequisites.ps1 -Drive 'F'
#
# Requires: Windows 10/11 x64, internet access, winget (App Installer),
# about 4 GB free on the chosen drive. Prefer an INTERNAL drive.

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive
)

$ErrorActionPreference = 'Stop'

function Refresh-Env {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;${Drive}:\nodejs;${Drive}:\jdk-21\bin;${Drive}:\Android\Sdk\platform-tools"
    $env:JAVA_HOME = "${Drive}:\jdk-21"
    $env:ANDROID_HOME = "${Drive}:\Android\Sdk"
}

function Get-VerifiedZip($Url, $Name, $ExactSize, $ExactSha256) {
    $zip = Join-Path $env:TEMP $Name
    if ((Test-Path $zip) -and (Get-Item $zip).Length -ne $ExactSize) {
        Write-Host "Existing $Name has the wrong size. Removing and downloading again."
        Remove-Item $zip -Force
    }
    if (-not (Test-Path $zip)) {
        Write-Host "Downloading $Name..."
        & curl.exe -L --fail -o $zip $Url
        if ($LASTEXITCODE -ne 0) { throw "Download failed for $Name (curl exit $LASTEXITCODE)." }
    }
    if ((Get-Item $zip).Length -ne $ExactSize) { throw "Size mismatch for $Name. Aborting." }
    if ($ExactSha256) {
        $sha = (certutil -hashfile $zip SHA256 | Select-Object -Index 1).Trim().ToLower()
        if ($sha -ne $ExactSha256) { throw "SHA256 mismatch for $Name ($sha). Aborting." }
        Write-Host "$Name verified: exact size and SHA256."
    } else {
        Write-Host "$Name verified: exact size, official host."
    }
    return $zip
}

Write-Host 'Installing Git...'
& winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) { throw "Git install failed (winget exit $LASTEXITCODE)." }

# --- Node.js 26.13.0 (same pin as the reference machine) ---
$nodeZip = Get-VerifiedZip 'https://nodejs.org/dist/v26.13.0/node-v26.13.0-win-x64.zip' `
    'node-v26.13.0-win-x64.zip' 41157375 'dcc60d59a0746999f99064a01c020445d54d84228c691cdbf25b49ac3b59150a'
$NodeDir = "${Drive}:\nodejs"
if (Test-Path $NodeDir) { Remove-Item $NodeDir -Recurse -Force }
$nodeInner = "${Drive}:\node-v26.13.0-win-x64"
if (Test-Path $nodeInner) { Remove-Item $nodeInner -Recurse -Force }
& tar.exe -xf $nodeZip -C "${Drive}:\"
if ($LASTEXITCODE -ne 0) { throw 'Node extraction failed.' }
Move-Item $nodeInner $NodeDir

# --- Microsoft OpenJDK 21.0.13.1 (Capacitor 7 requires JDK 21) ---
$jdkZip = Get-VerifiedZip 'https://aka.ms/download-jdk/microsoft-jdk-21-windows-x64.zip' `
    'microsoft-jdk-21-windows-x64.zip' 201469095 $null
$JdkDir = "${Drive}:\jdk-21"
if (Test-Path $JdkDir) { Remove-Item $JdkDir -Recurse -Force }
& tar.exe -xf $jdkZip -C "${Drive}:\"
if ($LASTEXITCODE -ne 0) { throw 'JDK extraction failed.' }
$jdkInner = Get-ChildItem "${Drive}:\" -Directory -Filter 'jdk-21*' | Select-Object -First 1
if (-not $jdkInner) { throw 'Extracted JDK folder not found.' }
Move-Item $jdkInner.FullName $JdkDir

# Persist JAVA_HOME / ANDROID_HOME / PATH at user level.
[Environment]::SetEnvironmentVariable('JAVA_HOME', $JdkDir, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', "${Drive}:\Android\Sdk", 'User')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
foreach ($p in @($NodeDir, "$JdkDir\bin", "${Drive}:\Android\Sdk\platform-tools")) {
    if ($userPath -notlike "*$p*") { $userPath = "$userPath;$p" }
}
[Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
Refresh-Env

# --- Android SDK: command-line tools, then the packages ---
$SdkDir = "${Drive}:\Android\Sdk"
$toolsZip = Get-VerifiedZip 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip' `
    'commandlinetools-win-11076708_latest.zip' 153583359 $null
$latestDir = Join-Path $SdkDir 'cmdline-tools\latest'
New-Item -ItemType Directory -Force -Path $latestDir | Out-Null
& tar.exe -xf $toolsZip -C (Join-Path $SdkDir 'cmdline-tools')
if ($LASTEXITCODE -ne 0) { throw 'Android tools extraction failed.' }
# The zip extracts a cmdline-tools folder; its contents belong in latest.
Get-ChildItem (Join-Path $SdkDir 'cmdline-tools\cmdline-tools') | Move-Item -Destination $latestDir
Remove-Item (Join-Path $SdkDir 'cmdline-tools\cmdline-tools') -Recurse -Force

$sdkManager = Join-Path $latestDir 'bin\sdkmanager.bat'
$yesFile = Join-Path $env:TEMP 'sdk-yes.txt'
('y' | Out-String) * 30 | Set-Content $yesFile -Encoding ASCII
& cmd.exe /c "`"$sdkManager`" --sdk_root=`"$SdkDir`" --licenses < `"$yesFile`""
Write-Host 'Installing Android SDK packages (platform 35, build-tools 35 + 34, platform-tools)...'
& cmd.exe /c "`"$sdkManager`" --sdk_root=`"$SdkDir`" `"platforms;android-35`" `"build-tools;35.0.0`" `"build-tools;34.0.0`" `"platform-tools`" < `"$yesFile`""
if ($LASTEXITCODE -ne 0) { throw "sdkmanager install failed (exit $LASTEXITCODE)." }

foreach ($p in @('platforms\android-35', 'build-tools\35.0.0', 'build-tools\34.0.0', 'platform-tools\adb.exe')) {
    if (-not (Test-Path (Join-Path $SdkDir $p))) { throw "Missing SDK component: $p" }
}

$v = & (Join-Path $NodeDir 'node.exe') --version
$j = & (Join-Path $JdkDir 'bin\java.exe') -version 2>&1 | Select-Object -First 1
Write-Host "Node OK: $v | $j | Android SDK at $SdkDir"
Write-Host 'PREREQUISITES OK: Git, Node.js, JDK 21 and the Android SDK are installed.'
