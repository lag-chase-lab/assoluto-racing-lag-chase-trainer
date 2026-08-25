[CmdletBinding()]
param(
    [string]$ApiLevel = $(if ($env:ASSOLUTO_API_LEVEL) { $env:ASSOLUTO_API_LEVEL } else { '36' }),
    [string]$AvdName = $(if ($env:ASSOLUTO_AVD_NAME) { $env:ASSOLUTO_AVD_NAME } else { 'Assoluto_PC_API_36' })
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$osArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
if ($osArchitecture -ne 'X64') {
    throw "このAVD作成スクリプトはWindows x64専用です。検出: $osArchitecture"
}

$sdkRoot = if ($env:ANDROID_SDK_ROOT) {
    $env:ANDROID_SDK_ROOT
} else {
    Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}

function Find-SdkTool {
    param([Parameter(Mandatory = $true)][string]$Name)

    $latest = Join-Path $sdkRoot "cmdline-tools\latest\bin\$Name"
    if (Test-Path -LiteralPath $latest -PathType Leaf) {
        return $latest
    }

    $toolsRoot = Join-Path $sdkRoot 'cmdline-tools'
    if (Test-Path -LiteralPath $toolsRoot) {
        $found = Get-ChildItem -LiteralPath $toolsRoot -Filter $Name -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($null -ne $found) {
            return $found.FullName
        }
    }

    throw "$Name が見つかりません。Android StudioのSDK Managerで Android SDK Command-line Tools (latest) をインストールしてください。"
}

$sdkManager = Find-SdkTool -Name 'sdkmanager.bat'
$avdManager = Find-SdkTool -Name 'avdmanager.bat'
$emulator = Join-Path $sdkRoot 'emulator\emulator.exe'
$systemImage = "system-images;android-$ApiLevel;google_apis_playstore;x86_64"

Write-Host 'Google Android SDKライセンスを表示します。内容を読み、同意する場合だけ y を入力してください。'
& $sdkManager --licenses
if ($LASTEXITCODE -ne 0) {
    throw 'SDKライセンスが未承認、または確認処理に失敗しました。'
}

Write-Host 'Android EmulatorとGoogle Play対応システムイメージを確認・インストールします。'
& $sdkManager 'platform-tools' 'emulator' $systemImage
if ($LASTEXITCODE -ne 0) {
    throw 'Android SDKパッケージのインストールに失敗しました。'
}

$existingAvds = if (Test-Path -LiteralPath $emulator) { @(& $emulator -list-avds) } else { @() }
if ($existingAvds -contains $AvdName) {
    Write-Host "既存AVDを保持します: $AvdName"
} else {
    $deviceList = @(& $avdManager list device 2>&1)
    $createArgs = @('create', 'avd', '--name', $AvdName, '--package', $systemImage)
    if (($deviceList -join "`n") -match 'id:.*pixel_7') {
        $createArgs += @('--device', 'pixel_7')
    }
    'no' | & $avdManager @createArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'AVDの作成に失敗しました。'
    }
}

$avdConfig = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd\config.ini"
function Set-AvdConfigValue {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $lines = if (Test-Path -LiteralPath $avdConfig) { @(Get-Content -LiteralPath $avdConfig) } else { @() }
    $updated = $false
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match ('^' + [Regex]::Escape($Key) + '=')) {
            $lines[$index] = "$Key=$Value"
            $updated = $true
            break
        }
    }
    if (-not $updated) {
        $lines += "$Key=$Value"
    }
    Set-Content -LiteralPath $avdConfig -Value $lines -Encoding Ascii
}

Set-AvdConfigValue -Key 'hw.keyboard' -Value 'yes'
Set-AvdConfigValue -Key 'hw.initialOrientation' -Value 'landscape'
Set-AvdConfigValue -Key 'hw.ramSize' -Value '4096'
Set-AvdConfigValue -Key 'vm.heapSize' -Value '512'
Set-AvdConfigValue -Key 'disk.dataPartition.size' -Value '16G'

Write-Host "AVD作成完了: $AvdName"
Write-Host 'Start-AssolutoMac.ps1で起動し、Google PlayへログインしてAssoluto Racingをインストールしてください。'
