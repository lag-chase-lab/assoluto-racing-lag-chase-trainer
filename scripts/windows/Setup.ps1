[CmdletBinding()]
param(
    [switch]$SkipAvdPrompt
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not [Environment]::Is64BitOperatingSystem) {
    throw '64-bit Windows 10/11が必要です。'
}

$osArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
if ($osArchitecture -eq 'Arm64') {
    throw 'Windows ARMはAndroid Studio/Emulatorの公式サポート対象外です。Intel/AMD x64 Windowsを使用してください。'
}

if ($null -eq (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw 'wingetが見つかりません。Microsoft Storeの「アプリ インストーラー」を更新してください。'
}

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory = $true)][string]$Id)
    & winget.exe list --exact --id $Id --source winget --disable-interactivity *> $null
    return $LASTEXITCODE -eq 0
}

function Install-WingetPackageIfMissing {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    if (Test-WingetPackageInstalled -Id $Id) {
        Write-Host "確認済み: $DisplayName"
        return
    }

    Write-Host "インストール: $DisplayName ($Id)"
    & winget.exe install --exact --id $Id --source winget
    if ($LASTEXITCODE -ne 0) {
        throw "$DisplayName のインストールに失敗しました。"
    }
}

# The official scrcpy WinGet package includes adb and its runtime dependencies.
Install-WingetPackageIfMissing -Id 'Genymobile.scrcpy' -DisplayName 'scrcpy + adb'
Install-WingetPackageIfMissing -Id 'OBSProject.OBSStudio' -DisplayName 'OBS Studio'
Install-WingetPackageIfMissing -Id 'Google.AndroidStudio' -DisplayName 'Android Studio'
Install-WingetPackageIfMissing -Id 'AutoHotkey.AutoHotkey' -DisplayName 'AutoHotkey v2 (optional A/D mapper)'

Write-Host ''
Write-Host '基本ツールのセットアップが完了しました。'
Write-Host '初回はAndroid Studioを起動してSetup Wizardを完了し、Android SDK Command-line Tools (latest)を導入してください。'
Write-Host 'wingetで追加されたPATHを反映するため、新しいPowerShellを開いてください。'

if (-not $SkipAvdPrompt) {
    $answer = Read-Host 'Google Play対応AVDの作成へ進みますか？ SDKライセンス確認と数GBのダウンロードが発生します [y/N]'
    if ($answer -match '^[yY]$') {
        & (Join-Path $PSScriptRoot 'Setup-Avd.ps1')
    }
}
