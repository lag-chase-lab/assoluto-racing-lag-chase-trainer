#!/bin/zsh

set -u

REPO_ROOT="${0:A:h:h:h}"
SOURCE_FILE="$REPO_ROOT/AssolutoKeyMapper/main.swift"
PLIST_FILE="$REPO_ROOT/AssolutoKeyMapper/Info.plist"
BUILD_ROOT="${ASSOLUTO_BUILD_DIR:-$REPO_ROOT/build}"
APP_BUNDLE="$BUILD_ROOT/Assoluto A-D Key Mapper.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/AssolutoKeyMapper"

if [[ "$(uname -s)" != "Darwin" ]]; then
  print -u2 -- "エラー: A/DキーマッパーのビルドはmacOS専用です。"
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1 || ! xcrun --find swiftc >/dev/null 2>&1; then
  print -u2 -- "エラー: Swiftコンパイラがありません。XcodeまたはCommand Line Toolsをインストールしてください。"
  exit 2
fi

if [[ ! -f "$SOURCE_FILE" || ! -f "$PLIST_FILE" ]]; then
  print -u2 -- "エラー: キーマッパーのソースファイルが見つかりません。"
  exit 3
fi

mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp "$PLIST_FILE" "$APP_BUNDLE/Contents/Info.plist"

xcrun swiftc \
  -O \
  -framework AppKit \
  -framework ApplicationServices \
  "$SOURCE_FILE" \
  -o "$EXECUTABLE"

codesign --force --sign - "$APP_BUNDLE" >/dev/null

print -- "ビルド完了: $APP_BUNDLE"
print -- "初回起動時は、macOSのアクセシビリティ権限を許可してください。"
