#!/usr/bin/env bash
#
# 最新リリースの dmg を落として /Applications に入れ替える。
#
#   ./update.sh          最新版へ
#   ./update.sh v0.1.7   特定のバージョンへ（切り戻し用）
#
# 作業記録は ~/Library/Application Support/com.shihbo.worklog/ にあり、
# アプリとは別なので、この操作でデータは一切動かない。
set -euo pipefail

REPO="qiushibo-dev/work-log"
APP="/Applications/Babos.app"
TAG="${1:-}"

# --- 対応アーキテクチャの確認 -------------------------------------------------
# CI が作っているのは Apple Silicon 版のみ。Intel Mac では動かないので早めに止める。
ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ]; then
  echo "✗ このマシンは $ARCH です。CI は Apple Silicon 版しか作っていません。" >&2
  echo "  Intel 版が必要なら .github/workflows/release.yml に" >&2
  echo "  x86_64-apple-darwin のターゲットを足してください。" >&2
  exit 1
fi

# --- ダウンロード -------------------------------------------------------------
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"; [ -n "${MNT:-}" ] && hdiutil detach "$MNT" -quiet 2>/dev/null || true' EXIT

if [ -z "$TAG" ]; then
  TAG="$(gh release view --repo "$REPO" --json tagName --jq '.tagName')"
fi
echo "→ $TAG を取得中…"
gh release download "$TAG" --repo "$REPO" --pattern '*aarch64.dmg' --dir "$WORK"

DMG="$(find "$WORK" -name '*.dmg' | head -1)"
[ -n "$DMG" ] || { echo "✗ dmg が見つかりません（$TAG に Apple Silicon 版が無い？）" >&2; exit 1; }

# --- 起動中なら閉じる ---------------------------------------------------------
if pgrep -f "Babos.app" > /dev/null; then
  echo "→ 起動中の Babos を終了します…"
  osascript -e 'tell application "Babos" to quit' 2>/dev/null || true
  sleep 2
fi

# --- 差し替え -----------------------------------------------------------------
# マウント先は同名ボリュームがあると /Volumes/Babos 1 などになるため、出力から取る。
MNT="$(hdiutil attach "$DMG" -nobrowse -readonly | grep -o '/Volumes/.*' | head -1)"
echo "→ マウント: $MNT"

if [ -d "$APP" ]; then
  # 消さずにゴミ箱へ。壊れていたら戻せるようにしておく。
  OLD="$HOME/.Trash/Babos-$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo old)-$(date +%H%M%S).app"
  mv "$APP" "$OLD"
  echo "→ 旧版をゴミ箱へ: $(basename "$OLD")"
fi

ditto "$MNT/Babos.app" "$APP"

# 公証していないので、これをやらないと Gatekeeper に止められる。
xattr -dr com.apple.quarantine "$APP"

echo "✓ $TAG をインストールしました（$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)）"
