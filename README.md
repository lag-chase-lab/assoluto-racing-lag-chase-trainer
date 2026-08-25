# Assoluto Racing Position-Lag Chase Trainer

Assoluto Racingのオンライン走行で見える**位置ラグを加味した追走を練習するための、2画面比較録画システム**です。

Mac/Windows上のAndroid Emulatorを「PC側の別アカウント」、USB接続したAndroid実機を「操作する本アカウント」として同時に動かし、OBSで左右に並べます。長時間の通常録画を止めずに、直前30秒だけをリプレイとして保存し、相手画面での自車位置、自分の画面での相手位置、追走ライン、車間、ステア・ブレーキのタイミングを目視比較できます。

このツールはゲーム通信、メモリ、物理演算、入力値、サーバー処理を改変しません。チート、ボット、パケット操作、ラグの生成・除去は行わず、既存の2画面をミラー表示・録画するだけです。

> [!IMPORTANT]
> Assoluto Racing、Infinity Vector、Google、Apple、Microsoft、OBS Project、Genymobileとは無関係の非公式コミュニティプロジェクトです。ゲーム本体、Google Play、アカウント、認証情報は含みません。各サービスの利用規約を守って使用してください。

## できること

- PC側Android EmulatorとAndroid実機をOBSで同時表示
- 実機側scrcpyをUSB限定・最大1280px・30fps・4Mbps・音声なし・操作なしで起動
- USB切断後、2秒間隔で再接続を待ってscrcpyを自動再起動
- OBSを両ウィンドウ生成後に開き、起動順によるウィンドウ未検出を減らす
- 通常録画を継続しながら、直前30秒を別のMKVへ保存
- Assoluto Racingが文字キーを受け付けない場合、Emulator前面時だけ `A → ←`、`D → →` に変換
- macOS（Apple Silicon / Intel）とWindows 10/11 x64に対応

## 構成

```text
Android Emulator（別アカウント） ─┐
                                  ├─ OBS ─ 長時間MKV録画
Android実機 ─ USB ─ scrcpy ───────┘       └─ 直前30秒リプレイ
```

## 必要環境

### 共通

- Android実機1台（USBデバッグを有効化）
- データ通信対応USBケーブル
- Google Playを利用できるAndroid Emulator
- PC側と実機側で利用するAssoluto Racingアカウント
- 十分な空き容量（Emulator、ゲーム、録画ファイル用）

### macOS

- macOS 13以降
- Apple SiliconまたはIntel Mac
- Homebrew（このプロジェクトからはHomebrew自体を勝手にインストールしません）
- XcodeまたはCommand Line Tools（A/Dキーマッパーのビルドに使用）

### Windows

- 64-bit Windows 10/11、Intel/AMD x64 CPU
- BIOS/UEFIでIntel VT-xまたはAMD-Vが有効
- Windows Hypervisor Platform
- winget

Windows ARMは、Android Studio/Emulatorの公式サポート対象外のため、このプロジェクトでも対象外です。

## クイックスタート

### Release ZIP（いちばん簡単）

[GitHub Releases](https://github.com/lag-chase-lab/assoluto-racing-lag-chase-trainer/releases)からZIPを1つダウンロードして展開します。

- macOS：`setup_macos.command` を右クリックして「開く」
- Windows：`setup_windows.cmd` をダブルクリック

初回に必要なOS権限、Google SDKライセンス、Google Playログイン、USBデバッグ許可、OBSのウィンドウ選択は自動化できません。それ以外のツール確認・不足分の導入・AVD作成・日常起動はスクリプトが案内します。

### macOS

```zsh
git clone https://github.com/lag-chase-lab/assoluto-racing-lag-chase-trainer.git
cd assoluto-racing-lag-chase-trainer
./scripts/macos/setup.sh
```

Android Studioの初回Setup Wizardを完了し、必要なら次を実行してGoogle Play対応AVDを作ります。

```zsh
./scripts/macos/setup_avd.sh
```

AVD内のGoogle PlayからAssoluto Racingをインストールし、Android実機をUSB接続したら、次回以降はこれだけです。

```zsh
./scripts/macos/start_all.sh
```

Release ZIP版では、次回から `start_all_macos.command` をダブルクリックできます。

詳細: [macOSセットアップ](docs/macos.md)

### Windows

PowerShellまたはコマンドプロンプトで取得します。

```powershell
git clone https://github.com/lag-chase-lab/assoluto-racing-lag-chase-trainer.git
cd assoluto-racing-lag-chase-trainer
.\setup_windows.cmd
```

Android Studioの初回Setup Wizardを完了し、Google Play対応AVDを作成します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\Setup-Avd.ps1
```

AVD内のGoogle PlayからAssoluto Racingをインストールし、Android実機をUSB接続したら、次回以降は次を実行します。

```powershell
.\start_all_windows.cmd
```

詳細: [Windowsセットアップ](docs/windows.md)

## OBSの基本設定

- 解像度：標準は1920×540。端末比率に合わせる場合はキャンバスと出力を同じ値へ変更
- FPS：30
- 録画形式：MKV
- エンコーダー：macOSはApple VT H.264、Windowsは利用可能なH.264ハードウェアエンコーダー
- 音声：全ソースをミュート（OBS上は少なくとも1トラックの選択が必要）
- リプレイバッファ：30秒、512MB
- 左：Android Emulator
- 右：`Android - Assoluto Racing`

詳しいクリック順と、Pixel系の横長画面を含む配置方法は [OBS設定](docs/obs.md) を参照してください。

## 毎回の運用

1. PC側Emulatorを起動
2. Android実機をUSB接続
3. scrcpyを起動
4. 最後にOBSを起動
5. 左右映像と全音声ミュートを確認
6. 「録画開始」→「リプレイバッファ開始」
7. 比較したい場面の直後にリプレイ保存ホットキーを押す
8. VLCで直前30秒のMKVを確認
9. 終了時は「リプレイバッファ停止」→「録画停止」

自動ランチャーはこの順番で起動します。OBSを先に開くと、後から作られたscrcpyウィンドウが候補に出ないことがあるためです。

## scrcpy固定条件

```text
--select-usb
--max-size=1280
--max-fps=30
--video-bit-rate=4M
--no-audio
--no-control
--no-clipboard-autosync
--window-title="Android - Assoluto Racing"
```

値は環境変数またはPowerShell引数で変更できますが、位置比較用途では既定値を推奨します。

## リポジトリ構成

```text
AssolutoKeyMapper/            macOS用A/DキーマッパーのSwiftソース
scripts/macos/                macOSセットアップ・AVD作成・一括起動
scripts/windows/              Windowsセットアップ・AVD作成・一括起動
tools/windows/                AutoHotkey v2キーマッパー
docs/                         OS別・OBS・トラブル対処
start_assoluto_mac.sh         macOS Emulator起動
start_assoluto_android.sh     macOS scrcpy起動・USB再接続監視
setup_windows.cmd             Windows初回セットアップ入口
start_all_windows.cmd         Windows一括起動入口
setup_macos.command           macOS初回セットアップ入口
start_all_macos.command       macOS一括起動入口
```

## 制限事項

- 厳密なフレーム同期装置ではありません。目的は目視比較です。
- USB切断中のAndroid映像は記録できず、後から復元できません。
- scrcpy再起動後はウィンドウIDが変わるため、OBSで右ソースを再選択する場合があります。
- ゲームやGoogle Playのダウンロード速度は、配信CDN、EmulatorのストレージI/O、Google Play側の処理に左右されます。
- コントローラーのUSBパススルーは環境依存性が高いため自動化していません。
- ゲーム更新によりEmulator互換性や入力挙動が変わる可能性があります。

## 安全性

- セットアップは既存パッケージを確認し、不足分だけを導入します。
- Homebrew自体は自動インストールしません。
- Google SDKライセンスは自動承認しません。
- Androidへの入力、音声転送、クリップボード同期をscrcpyで無効化します。
- OBSの個人設定ファイルを直接書き換えません。
- 認証情報、録画、ゲームデータをリポジトリへ保存しません。

## 公式資料

- [scrcpy公式リポジトリ](https://github.com/Genymobile/scrcpy)
- [scrcpy Windows手順](https://github.com/Genymobile/scrcpy/blob/master/doc/windows.md)
- [OBS Studio](https://obsproject.com/)
- [OBS Windowsインストール](https://obsproject.com/kb/windows-installation)
- [Android Studioインストール](https://developer.android.com/studio/install)
- [AVD Manager](https://developer.android.com/tools/avdmanager)
- [Android Emulatorハードウェアアクセラレーション](https://developer.android.com/studio/run/emulator-acceleration)

## License

[MIT License](LICENSE)
