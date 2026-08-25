[CmdletBinding()]
param(
    [string]$AvdName = $(if ($env:ASSOLUTO_AVD_NAME) { $env:ASSOLUTO_AVD_NAME } else { 'Assoluto_PC_API_36' }),
    [switch]$ColdBoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$emulator = Join-Path $sdkRoot 'emulator\emulator.exe'
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'

if (-not (Test-Path -LiteralPath $emulator -PathType Leaf)) {
    throw "Android Emulatorが見つかりません: $emulator"
}
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) {
    throw "Android SDK platform-toolsが見つかりません: $adb"
}

$avds = @(& $emulator -list-avds)
if ($avds -notcontains $AvdName) {
    throw "AVD $AvdName がありません。Setup-Avd.ps1を先に実行してください。"
}

$ahkScript = Join-Path $repoRoot 'tools\windows\AssolutoKeyMapper.ahk'
$autoHotkeyCandidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\UX\AutoHotkeyUX.exe')
)
$autoHotkey = $autoHotkeyCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if ($autoHotkey -and (Test-Path -LiteralPath $ahkScript -PathType Leaf)) {
    $mapperRunning = Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$ahkScript*" }
    if (-not $mapperRunning) {
        Start-Process -FilePath $autoHotkey -ArgumentList @("`"$ahkScript`"")
    }
} else {
    Write-Warning 'AutoHotkey v2が見つからないため、A/D→左右矢印変換は起動しません。'
}

$deviceLines = @(& $adb devices)
foreach ($line in $deviceLines) {
    if ($line -match '^(emulator-\d+)\s+device') {
        $serial = $Matches[1]
        $runningName = @(& $adb -s $serial emu avd name 2>$null | Select-Object -First 1)
        if ($runningName.Count -gt 0 -and $runningName[0].Trim() -eq $AvdName) {
            Write-Host "$AvdName はすでに起動しています（$serial）。"
            return
        }
    }
}

$arguments = @('-avd', $AvdName, '-no-audio', '-gpu', 'host', '-use-keycode-forwarding')
if ($ColdBoot -or $env:ASSOLUTO_COLD_BOOT -eq '1') {
    $arguments += '-no-snapshot-load'
}

Write-Host "$AvdName を起動します。コールドブート時は数分かかる場合があります。"
Start-Process -FilePath $emulator -ArgumentList $arguments
