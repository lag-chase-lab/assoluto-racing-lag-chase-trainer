#!/bin/zsh

# Assoluto Racing 比較用・Mac側 Android Emulator 起動スクリプト

SCRIPT_DIR="${0:A:h}"
SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
EMULATOR_BIN="$SDK_ROOT/emulator/emulator"
ADB_BIN="$SDK_ROOT/platform-tools/adb"
AVD_NAME="${ASSOLUTO_AVD_NAME:-Assoluto_PC_API_36}"
KEY_MAPPER_APP="${ASSOLUTO_KEY_MAPPER_APP:-$SCRIPT_DIR/build/Assoluto A-D Key Mapper.app}"

# Backward compatibility with the first local build of this project.
if [[ ! -d "$KEY_MAPPER_APP" && -d "$SCRIPT_DIR/Assoluto A-D Key Mapper.app" ]]; then
  KEY_MAPPER_APP="$SCRIPT_DIR/Assoluto A-D Key Mapper.app"
fi

if [[ ! -d "$KEY_MAPPER_APP" && -x "$SCRIPT_DIR/scripts/macos/build_key_mapper.sh" ]]; then
  print -- "A/Dキーマッパーをソースからビルドします。"
  "$SCRIPT_DIR/scripts/macos/build_key_mapper.sh" || {
    print -u2 -- "注意: A/Dキーマッパーをビルドできませんでした。Emulatorは起動を続けます。"
  }
fi

if [[ ! -x "$EMULATOR_BIN" ]]; then
  print -u2 -- "エラー: Android Emulator が見つかりません: $EMULATOR_BIN"
  print -u2 -- "Android SDK の emulator パッケージを確認してください。"
  exit 1
fi

if [[ ! -x "$ADB_BIN" ]]; then
  print -u2 -- "エラー: Android SDK の adb が見つかりません: $ADB_BIN"
  print -u2 -- "Android SDK の platform-tools を確認してください。"
  exit 2
fi

if ! "$EMULATOR_BIN" -list-avds | grep -Fxq "$AVD_NAME"; then
  print -u2 -- "エラー: 仮想端末 $AVD_NAME が見つかりません。"
  exit 3
fi

# Emulatorが最前面の時だけ A→← / D→→ に変換する補助アプリ。
if [[ -d "$KEY_MAPPER_APP" ]]; then
  open -gj "$KEY_MAPPER_APP"
else
  print -u2 -- "注意: A/Dキーマッパーが見つかりません: $KEY_MAPPER_APP"
fi

# すでに対象AVDが動作中なら、重複起動しません。
for SERIAL in $("$ADB_BIN" devices | awk '$1 ~ /^emulator-/ && $2 == "device" { print $1 }'); do
  RUNNING_AVD="$("$ADB_BIN" -s "$SERIAL" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')"
  if [[ "$RUNNING_AVD" == "$AVD_NAME" ]]; then
    print -- "$AVD_NAME はすでに起動しています（$SERIAL）。"
    exit 0
  fi
done

print -- "$AVD_NAME を起動します。初回またはコールドブートには数分かかる場合があります。"

EMULATOR_ARGS=(
  -avd "$AVD_NAME"
  -no-audio
  -gpu host
  -use-keycode-forwarding
)

if [[ "${ASSOLUTO_COLD_BOOT:-0}" == "1" ]]; then
  EMULATOR_ARGS+=( -no-snapshot-load )
fi

exec "$EMULATOR_BIN" "${EMULATOR_ARGS[@]}"
