#!/usr/bin/env bash
#
# ビルド。`npx tauri build` を直接叩かずこちらを使うこと。
#
# 理由：このプロジェクトは ~/Desktop にあり、Desktop は iCloud の File Provider
# 管理下にある（`xattr ~/Desktop` に com.apple.file-provider-domain-id が出る）。
# ビルド生成物をそのまま Desktop 配下に置くと、出来たばかりの .app に
# File Provider が com.apple.FinderInfo を付けにくることがあり、
# codesign が
#
#     resource fork, Finder information, or similar detritus not allowed
#
# で失敗する。**同期が .app に触る前に署名が終われば成功する**ため、
# 一見ランダムに失敗しているように見える（実際 v0.1.7〜0.1.9 の間に3回踏んだ）。
#
# CARGO_TARGET_DIR を iCloud の外に逃がせば根本的に起きない。
# CI（GitHub Actions）には iCloud が無いので、あちらは何もしなくてよい。
set -euo pipefail

export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$HOME/.cache/babos-target}"

npx --yes @tauri-apps/cli@^2 build "$@"

DMG="$(find "$CARGO_TARGET_DIR/release/bundle/dmg" -name '*.dmg' 2>/dev/null | head -1)"
[ -n "$DMG" ] && echo "" && echo "→ $DMG"
