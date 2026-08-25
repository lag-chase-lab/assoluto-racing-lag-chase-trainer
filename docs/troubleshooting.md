# トラブルシューティング

| 症状 | 対処 |
|---|---|
| `adb` / `scrcpy` が見つからない | OS別セットアップを再実行。Windowsは新しいPowerShellを開く |
| Androidが `unauthorized` | 実機をロック解除し、「USBデバッグを許可」で「許可」 |
| Androidが `offline` | USBを挿し直し、ロック解除。改善しなければUSBデバッグを一度オフ・オン |
| 実機が出ない | 充電専用ではなくデータ通信対応ケーブルを使う。Windowsは必要に応じてメーカーUSBドライバーを確認 |
| OBS右側が空白 | scrcpyを先に起動してOBSを再起動し、右ソースのウィンドウを再選択 |
| OBS左側が空白 | Emulatorを先に起動してOBSを再起動し、左ソースのウィンドウを再選択 |
| A/Dが効かない（Mac） | Emulatorを最前面にし、キーマッパーのアクセシビリティ権限を確認 |
| A/Dが効かない（Windows） | AutoHotkey v2とタスクトレイアイコンを確認。Emulatorを最前面にする |
| Emulatorが非常に遅い（Windows） | BIOS仮想化とWindows Hypervisor Platformを確認し、`emulator.exe -accel-check` を実行 |
| Google Playのダウンロードが遅い | CDN、Play側処理、Emulator I/Oがボトルネック。空き容量確認後しばらく待つ |
| リプレイ保存がない | 先に「リプレイバッファ開始」。ホットキー設定と録画保存先を確認 |
| MKVを開けない | VLCを使用。必要ならOBSでMP4へ再多重化 |
| scrcpy再接続後にOBSへ戻らない | 新しいscrcpyウィンドウを右ソースで再選択 |

## 診断コマンド

### macOS

```zsh
adb devices -l
scrcpy --version
"$HOME/Library/Android/sdk/emulator/emulator" -accel-check
```

### Windows PowerShell

```powershell
adb.exe devices -l
scrcpy.exe --version
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -accel-check
```

ログやIssueを共有する場合、Androidのシリアル番号、Googleアカウント、録画内の個人情報は伏せてください。
