#!/bin/zsh

set -u

REPO_ROOT="${0:A:h:h:h}"
MAC_STARTER="$REPO_ROOT/start_assoluto_mac.sh"
ANDROID_STARTER="$REPO_ROOT/start_assoluto_android.sh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  print -u2 -- "エラー: このランチャーはmacOS専用です。"
  exit 1
fi

if [[ ! -x "$MAC_STARTER" || ! -x "$ANDROID_STARTER" ]]; then
  print -u2 -- "エラー: 起動スクリプトが見つからないか、実行権限がありません。"
  exit 2
fi

if pgrep -x OBS >/dev/null 2>&1; then
  print -u2 -- "注意: OBSがすでに起動しています。新しいscrcpyウィンドウを一覧に出すには、OBSを終了してから再実行するのが確実です。"
fi

print -- "1/3 Mac側Android Emulatorを起動します。"
"$MAC_STARTER" &
MAC_STARTER_PID=$!

# Emulatorのウィンドウが生成される時間を確保します。既に起動済みならすぐ次へ進みます。
sleep "${EMULATOR_WINDOW_WAIT:-5}"

print -- "2/3 Android実機のscrcpyを起動します。"
"$ANDROID_STARTER" &
ANDROID_STARTER_PID=$!

sleep "${SCRCPY_WINDOW_WAIT:-3}"
if ! kill -0 "$ANDROID_STARTER_PID" 2>/dev/null; then
  wait "$ANDROID_STARTER_PID"
  exit $?
fi

print -- "3/3 両方のウィンドウを生成した後でOBSを起動します。"
if [[ "${ASSOLUTO_START_OBS:-1}" == "1" ]]; then
  if [[ -d /Applications/OBS.app ]]; then
    open /Applications/OBS.app
  else
    open -a OBS
  fi
fi

print -- "scrcpyのUSB再接続監視を続けます。このターミナルは開いたままにしてください。"
wait "$ANDROID_STARTER_PID"
ANDROID_RESULT=$?

# start_assoluto_mac.sh が既存AVDを検出した場合は既に終了しているため、待機対象にしません。
if kill -0 "$MAC_STARTER_PID" 2>/dev/null; then
  print -- "Mac側Emulatorは引き続き動作しています。"
fi

exit "$ANDROID_RESULT"
