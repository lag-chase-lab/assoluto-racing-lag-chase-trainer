#!/bin/zsh

set -u

REPO_ROOT="${0:A:h:h:h}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  print -u2 -- "エラー: このセットアップはmacOS専用です。Windowsでは scripts/windows/Setup.ps1 を使用してください。"
  exit 1
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_BIN=/opt/homebrew/bin/brew
elif command -v brew >/dev/null 2>&1; then
  BREW_BIN="$(command -v brew)"
else
  print -u2 -- "Homebrewが見つかりません。"
  print -u2 -- "このスクリプトはHomebrewを自動インストールしません。"
  print -u2 -- "必要性と変更内容を確認したうえで、公式サイト https://brew.sh/ から手動で導入してください。"
  exit 2
fi

MAC_ARCH="$(uname -m)"
if [[ "$MAC_ARCH" == "arm64" && "$BREW_BIN" == /usr/local/* ]]; then
  print -u2 -- "Apple Silicon上でIntel/Rosetta版Homebrew ($BREW_BIN) が選択されています。"
  print -u2 -- "誤ってIntel版Android Studioを入れないよう、/opt/homebrew のネイティブHomebrewを使用してください。"
  print -u2 -- "Homebrew自体はこのスクリプトから変更しません。"
  exit 3
fi

install_formula_if_missing() {
  local command_name="$1"
  local formula_name="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    print -- "確認済み: $command_name"
  else
    print -- "インストール: $formula_name"
    "$BREW_BIN" install "$formula_name" || return $?
  fi
}

install_cask_if_missing() {
  local app_path="$1"
  local command_name="$2"
  local cask_name="$3"
  if [[ -n "$app_path" && -e "$app_path" ]]; then
    print -- "確認済み: $app_path"
  elif [[ -n "$command_name" ]] && command -v "$command_name" >/dev/null 2>&1; then
    print -- "確認済み: $command_name"
  else
    print -- "インストール: $cask_name"
    "$BREW_BIN" install --cask "$cask_name" || return $?
  fi
}

install_cask_if_missing "" adb android-platform-tools || exit $?
install_formula_if_missing scrcpy scrcpy || exit $?
install_cask_if_missing /Applications/OBS.app "" obs || exit $?
install_cask_if_missing "/Applications/Android Studio.app" "" android-studio || exit $?

if [[ -x "$REPO_ROOT/scripts/macos/build_key_mapper.sh" ]]; then
  "$REPO_ROOT/scripts/macos/build_key_mapper.sh" || exit $?
fi

print -- ""
print -- "基本ツールのセットアップが完了しました。"
print -- "次にGoogle Play対応AVDを作成しますか？ Android SDKライセンスの確認と数GBのダウンロードが発生します。"
read "REPLY?続行する場合は y を入力してください [y/N]: "
if [[ "$REPLY" == [yY] ]]; then
  exec "$REPO_ROOT/scripts/macos/setup_avd.sh"
fi

print -- "AVD作成は後から次のコマンドでも実行できます:"
print -- "  ./scripts/macos/setup_avd.sh"
