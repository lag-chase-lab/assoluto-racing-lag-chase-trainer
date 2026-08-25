# Windowsセットアップ

## 対象

- 64-bit Windows 10/11
- Intel/AMD x64 CPU
- 16GB RAM以上を推奨
- BIOS/UEFIでIntel VT-xまたはAMD-Vが有効
- Windows Hypervisor Platformが有効

Windows ARMはAndroid Studio/Emulatorの公式サポート外のため対象外です。

## 1. 仮想化を有効にする

タスクマネージャー → パフォーマンス → CPUで「仮想化: 有効」を確認します。

無効の場合はPCメーカーの手順に従ってBIOS/UEFIのIntel Virtualization TechnologyまたはSVM/AMD-Vを有効にします。その後、「Windowsの機能の有効化または無効化」で「Windows Hypervisor Platform」を有効にし、再起動します。

## 2. 基本ツールをセットアップする

リポジトリ直下の `setup_windows.cmd` を実行します。PowerShellから実行しても構いません。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\Setup.ps1
```

wingetの公式IDを使い、不足分だけを導入します。

- `Genymobile.scrcpy`（ADBと必要DLLを含む公式scrcpyパッケージ）
- `OBSProject.OBSStudio`
- `Google.AndroidStudio`
- `AutoHotkey.AutoHotkey`

インストーラーが管理者権限を要求した場合は、表示された対象が上記ソフトであることを確認して許可してください。セットアップ後はPATH反映のため、新しいPowerShellを開きます。

## 3. Android StudioとAVD

Android Studioを一度起動し、Setup Wizardを完了します。SDK Manager → SDK Toolsで次を確認します。

- Android SDK Platform-Tools
- Android Emulator
- Android SDK Command-line Tools (latest)

次を実行します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\Setup-Avd.ps1
```

Google SDKライセンスが表示されます。同意できる場合だけ自分で `y` を入力してください。API 36、Google Play対応x86_64イメージ、`Assoluto_PC_API_36` AVDが既定です。

## 4. PC側ゲーム

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\Start-AssolutoMac.ps1
```

スクリプト名の `Mac` は「比較画面の左側・PC側」という既存呼称を維持したものです。WindowsでもAndroid Emulatorを起動します。

AVD内のGoogle PlayからAssoluto Racingをインストールし、比較用の別アカウントでログインします。

AutoHotkey v2は、Android Emulatorが前面の時だけ `A → ←`、`D → →` に変換します。タスクトレイのAutoHotkeyアイコンから終了できます。

## 5. Android実機

実機で開発者向けオプションとUSBデバッグを有効にし、データ通信対応USBケーブルで接続します。初回のRSA確認で、自分のPCであることを確認して「許可」を選びます。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\Start-AssolutoAndroid.ps1
```

scrcpyのwinget版がPATHに見えない場合も、スクリプトはwingetのインストール先を探索します。

## 6. 一括起動

初回構築後は `start_all_windows.cmd` を実行します。

```powershell
.\start_all_windows.cmd
```

Emulatorとscrcpyのウィンドウを確認してからOBSを起動します。scrcpyのUSB再接続監視用PowerShellは閉じないでください。

## 7. OBSキャプチャ

Windowsではソースに「ウィンドウキャプチャ」を使います。

- 左：Android Emulatorの `qemu-system-x86_64.exe`
- 右：`Android - Assoluto Racing` のscrcpy

「ゲームキャプチャ」は不要です。詳しくは [OBS設定](obs.md) を参照してください。
