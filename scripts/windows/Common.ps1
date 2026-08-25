Set-StrictMode -Version Latest

function Resolve-AssolutoExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$AdditionalPaths = @()
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    foreach ($path in $AdditionalPaths) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }

    $wingetPackages = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetPackages) {
        $found = Get-ChildItem -LiteralPath $wingetPackages -Filter $Name -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*Genymobile.scrcpy*" } |
            Select-Object -First 1
        if ($null -ne $found) {
            return $found.FullName
        }
    }

    throw "実行ファイルが見つかりません: $Name"
}

function Get-AdbDeviceRecords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AdbPath
    )

    $records = @()
    $output = @(& $AdbPath devices -l 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "adb devices に失敗しました: $($output -join [Environment]::NewLine)"
    }

    foreach ($line in $output) {
        if ($line -match '^\s*(\S+)\s+(device|unauthorized|offline)\b') {
            $serial = $Matches[1]
            $state = $Matches[2]

            # Emulator and common wireless-ADB serial formats are excluded.
            if ($serial -like 'emulator-*' -or
                $serial -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' -or
                $serial -match '(_adb-tls-connect|\._tcp)') {
                continue
            }

            $records += [PSCustomObject]@{
                Serial = $serial
                State  = $state
                Line   = [string]$line
            }
        }
    }

    return @($records)
}
