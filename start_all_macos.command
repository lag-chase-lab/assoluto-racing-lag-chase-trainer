#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR" || exit 1

./scripts/macos/start_all.sh
RESULT=$?

print -- ""
if (( RESULT != 0 )); then
  print -u2 -- "起動処理が終了しました（終了コード: $RESULT）。上の日本語メッセージを確認してください。"
  read "REPLY?Returnキーで閉じます。"
fi
exit "$RESULT"
