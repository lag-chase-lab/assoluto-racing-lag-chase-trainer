[CmdletBinding()]
param(
    [string]$WindowTitle = 'Android - Assoluto Racing',
    [int]$MaxSize = 1280,
    [int]$MaxFps = 30,
    [string]$VideoBitRate = '4M',
    [int]$ReconnectSeconds = 2
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Common.ps1')

try {
    $scrcpy = Resolve-AssolutoExecutable -Name 'scrcpy.exe'
    $adb = Resolve-AssolutoExecutable -Name 'adb.exe' -AdditionalPaths @((Join-Path (Split-Path -Parent $scrcpy) 'adb.exe'))
} catch {
    Write-Host "エラー: $($_.Exception.Message) Setup.ps1を先に実行してください。" -ForegroundColor Red
    exit 1
}

function Get-ReadyPhysicalDevices {
    return @(Get-AdbDeviceRecords -AdbPath $adb | Where-Object State -eq 'device')
}

function Assert-InitialDeviceState {
    $devices = @(Get-AdbDeviceRecords -AdbPath $adb)
    $unauthorized = @($devices | Where-Object State -eq 'unauthorized')
    $offline = @($devices | Where-Object State -eq 'offline')
    $ready = @($devices | Where-Object State -eq 'device')

    if ($unauthorized.Count -gt 0) {
        Write-Host 'エラー: Androidが未承認です。端末をロック解除し、「USBデバッグを許可しますか？」で「許可」を選んでください。' -ForegroundColor Red
        exit 2
    }
    if ($offline.Count -gt 0) {
        Write-Host 'エラー: Androidがofflineです。USBを挿し直し、端末のロック解除とUSBデバッグを確認してください。' -ForegroundColor Red
        exit 3
    }
    if ($ready.Count -eq 0) {
        Write-Host 'エラー: USBデバッグで使用できるAndroid実機がありません。データ通信対応USBケーブルで接続してください。' -ForegroundColor Red
        exit 4
    }
    if ($ready.Count -gt 1) {
        Write-Host 'エラー: Android実機が複数あります。使用する1台だけをUSB接続してください。' -ForegroundColor Red
        exit 5
    }
}

Assert-InitialDeviceState
Write-Host 'Android実機を読み取り専用・映像のみで表示します。'

while ($true) {
    $arguments = @(
        '--select-usb',
        "--max-size=$MaxSize",
        "--max-fps=$MaxFps",
        "--video-bit-rate=$VideoBitRate",
        '--no-audio',
        '--no-control',
        '--no-clipboard-autosync',
        "--window-title=$WindowTitle"
    )

    & $scrcpy @arguments
    $scrcpyExitCode = $LASTEXITCODE

    $readyAfterExit = @(Get-ReadyPhysicalDevices)
    if ($readyAfterExit.Count -gt 0) {
        if ($scrcpyExitCode -ne 0) {
            Write-Host "エラー: scrcpyがエラー終了しました（終了コード: $scrcpyExitCode）。" -ForegroundColor Red
            exit $scrcpyExitCode
        }
        Write-Host 'scrcpyを終了しました。'
        exit 0
    }

    Write-Warning "USB接続が切れました。$ReconnectSeconds 秒間隔で再接続を待ちます。終了はControl+Cです。"
    $lastState = ''
    while ($true) {
        $devices = @(Get-AdbDeviceRecords -AdbPath $adb)
        $ready = @($devices | Where-Object State -eq 'device')
        $unauthorized = @($devices | Where-Object State -eq 'unauthorized')
        $offline = @($devices | Where-Object State -eq 'offline')

        if ($ready.Count -eq 1) {
            Write-Host "Androidを再検出しました: $($ready[0].Serial)。scrcpyを再起動します。"
            break
        }

        if ($ready.Count -gt 1) {
            $state = 'multiple'
            $message = 'Android実機が複数あります。使用する1台だけを接続してください。'
        } elseif ($unauthorized.Count -gt 0) {
            $state = 'unauthorized'
            $message = 'Androidが未承認です。端末でUSBデバッグを許可してください。'
        } elseif ($offline.Count -gt 0) {
            $state = 'offline'
            $message = 'Androidがofflineです。USBの挿し直しとロック解除を確認してください。'
        } else {
            $state = 'disconnected'
            $message = 'USBデバッグ接続を待っています……'
        }

        if ($state -ne $lastState) {
            Write-Warning $message
            $lastState = $state
        }
        Start-Sleep -Seconds $ReconnectSeconds
    }
}
