// app.html を dist/index.html にコピーするだけ。tauri.conf.json の
// beforeBuildCommand から呼ばれる。
//
// 以前は `mkdir -p dist && cp app.html dist/index.html` を直接書いていたが、
// Windows には mkdir -p も cp も無い。node -e に書き換えたら今度は
// cmd が引用符を食ってしまい `SyntaxError: Invalid or unexpected token` で落ちた。
// スクリプトファイルにすれば shell の引用符解釈を一切通らない。
import { mkdirSync, copyFileSync, cpSync } from 'node:fs';

mkdirSync('dist', { recursive: true });
copyFileSync('app.html', 'dist/index.html');

// 欧文フォントを同梱する。CSS の @font-face が index.html から見た
// 相対パス fonts/*.woff2 を参照しているので、隣に置く必要がある。
cpSync('fonts', 'dist/fonts', { recursive: true });
