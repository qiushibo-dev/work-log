// app.html を dist/index.html にコピーするだけ。tauri.conf.json の
// beforeBuildCommand から呼ばれる。
//
// 以前は `mkdir -p dist && cp app.html dist/index.html` を直接書いていたが、
// Windows には mkdir -p も cp も無い。node -e に書き換えたら今度は
// cmd が引用符を食ってしまい `SyntaxError: Invalid or unexpected token` で落ちた。
// スクリプトファイルにすれば shell の引用符解釈を一切通らない。
import { mkdirSync, copyFileSync } from 'node:fs';

mkdirSync('dist', { recursive: true });
copyFileSync('app.html', 'dist/index.html');
