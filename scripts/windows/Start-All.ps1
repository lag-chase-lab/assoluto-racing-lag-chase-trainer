[CmdletBinding()]
param(
    [int]$WindowWaitSeconds = 120
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Common.ps1')

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$macStarter = Join-Path $PSScriptRoot 'Start-AssolutoMac.ps1'
$androidStarter = Join-Path $PSScriptRoot 'Start-AssolutoAndroid.ps1'
$powerShellExe = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }

try {
    $scrcpy = Resolve-AssolutoExecutable -Name 'scrcpy.exe'
    $adb = Resolve-AssolutoExecutable -Name 'adb.exe' -AdditionalPaths @((Join-Path (Split-Path -Parent $scrcpy) 'adb.exe'))
    $readyDevices = @(Get-AdbDeviceRecords -AdbPath $adb | Where-Object State -eq 'device')
    if ($readyDevices.Count -ne 1) {
        throw 'USBデバッグで使用できるAndroid実機を1台だけ接続してから実行してください。'
    }
} catch {
    Write-Host "エラー: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (Get-Process obs64 -ErrorAction SilentlyContinue) {
    Write-Warning 'OBSがすでに起動しています。新しいscrcpyウィンドウを認識しない場合は、録画を停止してOBSだけ再起動してください。'
}

Write-Host '1/3 Mac側相当のAndroid Emulatorを起動します。'
Start-Process -FilePath $powerShellExe -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$macStarter`"")

Write-Host '2/3 Android実機のscrcpy再接続監視を起動します。'
Start-Process -FilePath $powerShellExe -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$androidStarter`"")

Write-Host '両方のウィンドウができるまで待機します。'
$deadline = (Get-Date).AddSeconds($WindowWaitSeconds)
$windowsReady = $false
while ((Get-Date) -lt $deadline) {
    $emulatorReady = @(Get-Process -ErrorAction SilentlyContinue | Where-Object ProcessName -Like 'qemu-system-*').Count -gt 0
    $scrcpyReady = @(Get-Process scrcpy -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -eq 'Android - Assoluto Racing').Count -gt 0
    if ($emulatorReady -and $scrcpyReady) {
        $windowsReady = $true
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $windowsReady) {
    Write-Warning "$WindowWaitSeconds 秒以内に両方のウィンドウを確認できませんでした。端末のUSBデバッグ許可と各PowerShellのエラーを確認してください。"
    exit 2
}

Write-Host '3/3 両方のウィンドウ生成後にOBSを起動します。'
$obsCandidates = @(
    (Join-Path $env:ProgramFiles 'obs-studio\bin\64bit\obs64.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'obs-studio\bin\64bit\obs64.exe')
)
$obs = $obsCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
if (-not $obs) {
    throw 'OBS Studioが見つかりません。Setup.ps1を実行してください。'
}

if (-not (Get-Process obs64 -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $obs -WorkingDirectory (Split-Path -Parent $obs)
}

Write-Host 'OBSで左右のウィンドウを確認し、「録画開始」→「リプレイバッファ開始」の順に操作してください。'
