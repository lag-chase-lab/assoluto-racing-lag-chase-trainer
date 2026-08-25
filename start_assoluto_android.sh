#!/bin/zsh

# Assoluto Racing 比較録画用 Android ミラー起動スクリプト
# USB 接続の Android 1 台だけを、読み取り専用・映像のみで表示します。

ADB_BIN="${ADB_BIN:-$(command -v adb)}"
SCRCPY_BIN="${SCRCPY_BIN:-$(command -v scrcpy)}"
SCRCPY_TITLE="${SCRCPY_TITLE:-Android - Assoluto Racing}"
SCRCPY_MAX_SIZE="${SCRCPY_MAX_SIZE:-1280}"
SCRCPY_MAX_FPS="${SCRCPY_MAX_FPS:-30}"
SCRCPY_VIDEO_BIT_RATE="${SCRCPY_VIDEO_BIT_RATE:-4M}"
RECONNECT_INTERVAL="${RECONNECT_INTERVAL:-2}"

if [[ -z "$ADB_BIN" ]]; then
  print -u2 -- "エラー: adb が見つかりません。Homebrew の android-platform-tools を確認してください。"
  exit 1
fi

if [[ -z "$SCRCPY_BIN" ]]; then
  print -u2 -- "エラー: scrcpy が見つかりません。Homebrew の scrcpy を確認してください。"
  exit 1
fi

ADB_OUTPUT="$($ADB_BIN devices -l 2>&1)"
ADB_RESULT=$?

if (( ADB_RESULT != 0 )); then
  print -u2 -- "エラー: adb の接続確認に失敗しました。"
  print -u2 -- "$ADB_OUTPUT"
  exit 1
fi

UNAUTHORIZED_USB="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "unauthorized" && /usb:/ { print $1 }')"
OFFLINE_USB="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "offline" && /usb:/ { print $1 }')"
READY_USB="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "device" && /usb:/ { print $1 }')"
READY_COUNT="$(print -r -- "$READY_USB" | awk 'NF { count++ } END { print count + 0 }')"

if [[ -n "$UNAUTHORIZED_USB" ]]; then
  print -u2 -- "Android が未承認です。端末のロックを解除し、表示された『USB デバッグを許可しますか？』で『許可』をタップしてから、もう一度実行してください。"
  print -u2 -- "対象端末: $UNAUTHORIZED_USB"
  exit 2
fi

if [[ -n "$OFFLINE_USB" ]]; then
  print -u2 -- "Android は USB 接続されていますが offline 状態です。USB ケーブルを挿し直し、端末のロック解除と USB デバッグ設定を確認してください。"
  print -u2 -- "対象端末: $OFFLINE_USB"
  exit 3
fi

if (( READY_COUNT == 0 )); then
  print -u2 -- "USB デバッグで使用できる Android が見つかりません。データ通信対応の USB ケーブルで接続し、開発者向けオプションの『USB デバッグ』を有効にしてください。"
  exit 4
fi

if (( READY_COUNT > 1 )); then
  print -u2 -- "USB デバッグ可能な Android が複数あります。使用する 1 台だけを USB 接続してから、もう一度実行してください。"
  print -u2 -- "接続端末:"
  print -u2 -- "$READY_USB"
  exit 5
fi

print -- "Android ($READY_USB) を読み取り専用でミラー表示します。終了するには scrcpy ウィンドウを閉じてください。"

while true; do
  SCRCPY_RESULT=0
  "$SCRCPY_BIN" \
    --select-usb \
    --max-size="$SCRCPY_MAX_SIZE" \
    --max-fps="$SCRCPY_MAX_FPS" \
    --video-bit-rate="$SCRCPY_VIDEO_BIT_RATE" \
    --no-audio \
    --no-control \
    --no-clipboard-autosync \
    --window-title="$SCRCPY_TITLE" || SCRCPY_RESULT=$?

  # 終了時にも接続状態を確認します。USB 端末が残っていれば、
  # ウィンドウを手動で閉じたか scrcpy 自体のエラーなので再起動しません。
  ADB_OUTPUT="$($ADB_BIN devices -l 2>&1)"
  READY_AFTER_EXIT="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "device" && /usb:/ { print $1 }')"
  if [[ -n "$READY_AFTER_EXIT" ]]; then
    if (( SCRCPY_RESULT != 0 )); then
      print -u2 -- "scrcpy がエラー終了しました（終了コード: $SCRCPY_RESULT）。"
      exit "$SCRCPY_RESULT"
    fi
    print -- "scrcpy を終了しました。"
    exit 0
  fi

  print -u2 -- "Android との USB 接続が切れました。${RECONNECT_INTERVAL} 秒間隔で再接続を待ちます。"
  print -u2 -- "終了する場合は、このターミナルで Control+C を押してください。"
  LAST_WAIT_STATE=""

  while true; do
    ADB_OUTPUT="$($ADB_BIN devices -l 2>&1)"
    ADB_RESULT=$?

    if (( ADB_RESULT != 0 )); then
      WAIT_STATE="adb_error"
      WAIT_MESSAGE="adb の接続確認に失敗しています。USB 接続と adb を確認してください。"
    else
      UNAUTHORIZED_USB="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "unauthorized" && /usb:/ { print $1 }')"
      OFFLINE_USB="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "offline" && /usb:/ { print $1 }')"
      READY_USB="$(print -r -- "$ADB_OUTPUT" | awk '$2 == "device" && /usb:/ { print $1 }')"
      READY_COUNT="$(print -r -- "$READY_USB" | awk 'NF { count++ } END { print count + 0 }')"

      if (( READY_COUNT == 1 )); then
        print -- "Android ($READY_USB) を再検出しました。scrcpy を再起動します。"
        break
      elif (( READY_COUNT > 1 )); then
        WAIT_STATE="multiple"
        WAIT_MESSAGE="USB デバッグ可能な Android が複数あります。使用する 1 台だけを接続してください。"
      elif [[ -n "$UNAUTHORIZED_USB" ]]; then
        WAIT_STATE="unauthorized:$UNAUTHORIZED_USB"
        WAIT_MESSAGE="Android が未承認です。端末のロックを解除し、『USB デバッグを許可しますか？』で『許可』をタップしてください。"
      elif [[ -n "$OFFLINE_USB" ]]; then
        WAIT_STATE="offline:$OFFLINE_USB"
        WAIT_MESSAGE="Android は offline 状態です。USB ケーブルの挿し直しと端末のロック解除を確認してください。"
      else
        WAIT_STATE="disconnected"
        WAIT_MESSAGE="USB デバッグ接続を待っています……"
      fi
    fi

    # 同じ警告を 2 秒ごとに繰り返さず、状態が変わった時だけ表示します。
    if [[ "$WAIT_STATE" != "$LAST_WAIT_STATE" ]]; then
      print -u2 -- "$WAIT_MESSAGE"
      LAST_WAIT_STATE="$WAIT_STATE"
    fi

    sleep "$RECONNECT_INTERVAL"
  done
done
