# macOSセットアップ

## 1. 読み取り専用の事前確認

必要なら次で環境を確認できます。

```zsh
sw_vers
uname -m
command -v brew
command -v adb
command -v scrcpy
ls -d /Applications/OBS.app "/Applications/Android Studio.app" 2>/dev/null
```

`arm64` はApple Silicon、`x86_64` はIntel Macです。

## 2. 基本ツール

```zsh
./scripts/macos/setup.sh
```

このスクリプトは既存インストールを確認し、不足しているものだけをHomebrewから導入します。

- `android-platform-tools`
- `scrcpy`
- OBS Studio
- Android Studio

Homebrewがなければ、必要性を表示して停止します。Homebrew自体はインストールしません。Apple Silicon上でIntel/Rosetta版Homebrewしかない場合も、誤ったアーキテクチャのAndroid Studioを避けるため停止します。

## 3. Android StudioとAVD

Android Studioを一度起動し、Setup Wizardを完了してください。SDK Managerの「SDK Tools」で次を確認します。

- Android SDK Platform-Tools
- Android Emulator
- Android SDK Command-line Tools (latest)

その後、次を実行します。

```zsh
./scripts/macos/setup_avd.sh
```

Google SDKライセンスが表示されます。同意できる場合だけ自分で `y` を入力してください。既定ではAPI 36のGoogle Play対応イメージと、`Assoluto_PC_API_36` というAVDを作成します。

AVD名やAPIを変える場合：

```zsh
ASSOLUTO_API_LEVEL=36 ASSOLUTO_AVD_NAME=Assoluto_PC_API_36 ./scripts/macos/setup_avd.sh
```

## 4. PC側ゲーム

```zsh
./start_assoluto_mac.sh
```

AVDが横画面で起動したら、Google Playへログインし、Assoluto Racingを公式ストアからインストールします。比較用の別アカウントでログインしてください。

初回はA/Dキーマッパーの権限が必要です。

1. システム設定
2. プライバシーとセキュリティ
3. アクセシビリティ
4. `Assoluto A-D Key Mapper` を許可
5. 必要ならアプリを一度終了して再起動

キーマッパーはAndroid Emulatorが最前面の時だけ `A → ←`、`D → →` に変換します。他のアプリの文字入力には影響しません。

## 5. Android実機

Androidで開発者向けオプションとUSBデバッグを有効にし、USB接続します。初回のRSA確認ダイアログで、自分のMacであることを確認して「許可」を選びます。

```zsh
./start_assoluto_android.sh
```

実機は本体で操作します。scrcpyからの操作、音声、クリップボード同期は無効です。

## 6. 一括起動

初回構築後は次を使えます。

```zsh
./scripts/macos/start_all.sh
```

起動順はEmulator → scrcpy → OBSです。USB再接続監視を維持するため、起動に使ったターミナルは開いたままにしてください。

## 7. macOS権限

OBSで映像が黒い場合：

1. システム設定
2. プライバシーとセキュリティ
3. 画面収録とシステムオーディオ録音
4. OBSを許可
5. OBSを終了して再起動

本プロジェクトはゲーム音声を必要としません。画面収録だけを目的に、必要最小限の権限を許可してください。
