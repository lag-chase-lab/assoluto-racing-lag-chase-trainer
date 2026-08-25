#!/bin/zsh

set -u

SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
API_LEVEL="${ASSOLUTO_API_LEVEL:-36}"
AVD_NAME="${ASSOLUTO_AVD_NAME:-Assoluto_PC_API_36}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  print -u2 -- "エラー: このスクリプトはmacOS専用です。"
  exit 1
fi

find_sdk_tool() {
  local tool_name="$1"
  local candidate
  local -a candidates
  candidates=(
    "$SDK_ROOT/cmdline-tools/latest/bin/$tool_name"
    "$SDK_ROOT/cmdline-tools"/*/bin/"$tool_name"(N)
  )
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      print -r -- "$candidate"
      return 0
    fi
  done
  return 1
}

SDKMANAGER="$(find_sdk_tool sdkmanager)" || {
  print -u2 -- "Android SDK Command-line Toolsが見つかりません。"
  print -u2 -- "Android Studio → Settings → Languages & Frameworks → Android SDK → SDK Tools で"
  print -u2 -- "『Android SDK Command-line Tools (latest)』をインストールしてください。"
  exit 2
}

AVDMANAGER="$(find_sdk_tool avdmanager)" || {
  print -u2 -- "avdmanagerが見つかりません。Android SDK Command-line Toolsを確認してください。"
  exit 3
}

case "$(uname -m)" in
  arm64) IMAGE_ARCH=arm64-v8a ;;
  x86_64) IMAGE_ARCH=x86_64 ;;
  *)
    print -u2 -- "未対応のMac CPUアーキテクチャです: $(uname -m)"
    exit 4
    ;;
esac

SYSTEM_IMAGE="system-images;android-${API_LEVEL};google_apis_playstore;${IMAGE_ARCH}"

print -- "Google Android SDKライセンスを確認します。内容を読み、同意する場合だけ y を入力してください。"
"$SDKMANAGER" --licenses || {
  print -u2 -- "SDKライセンスが未承認、または確認処理に失敗しました。AVD作成を中止します。"
  exit 5
}

print -- "Android EmulatorとGoogle Play対応システムイメージを確認・インストールします。"
"$SDKMANAGER" "platform-tools" "emulator" "$SYSTEM_IMAGE" || exit $?

if "$SDK_ROOT/emulator/emulator" -list-avds 2>/dev/null | grep -Fxq "$AVD_NAME"; then
  print -- "既存AVDを保持します: $AVD_NAME"
else
  CREATE_ARGS=(create avd --name "$AVD_NAME" --package "$SYSTEM_IMAGE")
  if "$AVDMANAGER" list device 2>/dev/null | grep -q 'id:.*pixel_7'; then
    CREATE_ARGS+=(--device pixel_7)
  fi
  print 'no\n' | "$AVDMANAGER" "${CREATE_ARGS[@]}" || exit $?
fi

AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
set_avd_value() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$AVD_CONFIG"; then
    sed -i '' -E "s|^${key}=.*|${key}=${value}|" "$AVD_CONFIG"
  else
    print -- "${key}=${value}" >> "$AVD_CONFIG"
  fi
}

if [[ -f "$AVD_CONFIG" ]]; then
  set_avd_value hw.keyboard yes
  set_avd_value hw.initialOrientation landscape
  set_avd_value hw.ramSize 4096
  set_avd_value vm.heapSize 512
  set_avd_value disk.dataPartition.size 16G
fi

print -- "AVD作成完了: $AVD_NAME"
print -- "次のコマンドで起動し、Google PlayへログインしてAssoluto Racingをインストールしてください:"
print -- "  ./start_assoluto_mac.sh"
