#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR" || exit 1

./scripts/macos/setup.sh
RESULT=$?

print -- ""
if (( RESULT == 0 )); then
  print -- "セットアップ処理が完了しました。"
else
  print -u2 -- "セットアップを完了できませんでした（終了コード: $RESULT）。上の日本語メッセージを確認してください。"
fi
read "REPLY?Returnキーで閉じます。"
exit "$RESULT"
