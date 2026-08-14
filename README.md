# Babos

個人用的工作記錄 app。一個案子一筆記錄，用氣泡的大小與深淺表示「現在佔掉多少腦袋」與「走了多遠」。

macOS ／ Windows 桌面 app（Tauri 打包）。目前 v0.1.7。

> v0.1.5 已在兩台 Mac 安裝實測通過。**v0.1.6 之後的版本只驗證到「build 通過、
> 瀏覽器裡渲染正常」，沒有實機跑過**，Windows 版更是完全沒人裝過。
> 要驗證的話照 HANDOFF.md 第 8 節的清單走一遍。

**這個 app 的目的不是專案管理，是留下痕跡。** 記錄工具的死法都一樣——做得漂亮，用兩週就停。
差別只在「記一筆要幾秒」，所以工作日誌那個常駐的一行輸入框是整個介面最重要的元件。

---

## 接手的人／AI 先讀這裡

| 想知道什麼 | 看哪份 | 語言 |
|---|---|---|
| **為什麼長這樣、什麼方案被否決過** | [SPEC.md](SPEC.md) | 繁中 |
| **踩過的坑、改過的 bug、不要碰的地方** | [HANDOFF.md](HANDOFF.md) | 日文 |
| 套用中的視覺 token | [DESIGN.md](DESIGN.md) | 英文 |
| 最初的 wireframe 與設計來源 | [docs/](docs/) | — |

**動手前一定要看 SPEC.md 的決策紀錄與 HANDOFF.md 的「やらないこと」。**
兩份都刻意記了被否決的方案跟理由——沒有的話會繞回去重新討論一遍，這已經發生過。

---

## 跑起來

```bash
# 瀏覽器直接開（不需要 build，但檔案儲存不會動，只有 localStorage）
open app.html

# 打包成 dmg
npx --yes @tauri-apps/cli@^2 build
# → src-tauri/target/release/bundle/dmg/Babos_0.1.7_aarch64.dmg
```

沒有 `package.json`。`beforeBuildCommand` 執行 `build.mjs`，把 `app.html` 複製成
`dist/index.html`、把 `fonts/` 複製進 `dist/`。所以**編輯的對象永遠是根目錄的 `app.html`**，
`dist/` 是建置產物。

### Windows 版

推一個 tag 就會由 GitHub Actions 同時產出 dmg 與 exe，自動掛上 Release：

```bash
git tag v0.1.8 && git push origin v0.1.8
```

手動觸發（`gh workflow run release.yml`）則不發 Release，只留成品當 artifact，適合測試。

設定在 [.github/workflows/release.yml](.github/workflows/release.yml)。三個踩過的坑寫在
HANDOFF.md 第 7 節——最重要的是**`beforeBuildCommand` 不能寫 shell 指令**，
Windows 沒有 `mkdir -p` 也沒有 `cp`，而 `node -e "…"` 會被 cmd 把引號吃掉。

Windows 的 exe 沒有簽章，第一次開會跳 SmartScreen，要點「其他資訊 → 仍要執行」。

### 更新已安裝的版本

```bash
./update.sh          # 裝最新的 Release
./update.sh v0.1.7   # 退回特定版本
```

會自動抓最新 tag、下載 dmg、把舊版丟垃圾桶（可還原）、解除 Gatekeeper 隔離。
**工作記錄完全不動**——資料在 `~/Library/Application Support/`，跟 app 分開。

手動做的話是這樣：

```bash
gh release download v0.1.8 --pattern "*.dmg" --clobber
hdiutil attach Babos_0.1.8_aarch64.dmg -nobrowse
mv /Applications/Babos.app ~/.Trash/Babos-old.app
ditto /Volumes/Babos/Babos.app /Applications/Babos.app
hdiutil detach /Volumes/Babos
xattr -dr com.apple.quarantine /Applications/Babos.app
```

最後那行是必要的——ad-hoc 簽名沒有公證，不解除隔離會被 Gatekeeper 擋。

### 升版本號要改兩個地方

`src-tauri/tauri.conf.json` 的 `version`，以及 `app.html` 裡的 `APP_VERSION`
（設定畫面的 About 讀這個）。兩邊沒對齊的話 About 會顯示錯的版本。

`src-tauri/Cargo.toml` 的 version 不影響產品，順手對齊即可。

---

## 資料存在哪

```
~/Library/Application Support/com.shihbo.worklog/work-tracker.json
```

localStorage（key: `work-tracker-v1`）同時保留一份當保險，但**JSON 檔才是正本**——
啟動時如果檔案存在，會用檔案的內容覆蓋 localStorage 的。

設定畫面的「儲存位置」會顯示實際寫入狀態：成功就顯示完整路徑，失敗就顯示紅字錯誤。
**如果那裡是紅的，代表現在只靠 localStorage 在跑**，記錄隨時可能消失。

> 為什麼要把寫入狀態做進 UI：v0.1.4 之前寫入一直失敗，但錯誤只送到 `console.warn`，
> 而 release build 沒有 devtools——幾十次失敗完全無聲。詳見 HANDOFF.md。

---

## 畫面

| 位置 | 作用 |
|---|---|
| 左上・氣泡區 | 一顆氣泡＝一個案件。**大小**＝目前的投入強度（隨進度走常態曲線，小→大→小），**深淺**＝完成度（越做越深）。可以拖曳，氣泡之間會互相推擠 |
| 右上・詳細 | 選取中的案件。進度節點 1–10（點擊推進）、工作日誌、連結。未選取時顯示「最後更新的案件」 |
| 下・列表 | 全部案件。可排序、可設重要度（拖曳圓點）。DETAIL 開啟該案件的備註與完整日誌 |
| 左下・側欄 | 依狀態／類型／客戶篩選，同時作用於氣泡區與列表 |

推到第 10 個節點並確認後跑完成動畫——氣泡先膨脹再往上飄走。
**這是整個 app 唯一該有儀式感的地方，其他都保持安靜。**

無操作 5 分鐘（可設 0／5／15 分）進入螢幕保護，只留氣泡與時鐘。

---

## 檔案地圖

| 路徑 | 內容 |
|---|---|
| `app.html` | **app 本體**。單一檔案、零依賴，含 CSS 與全部 JS（約 1,920 行） |
| `fonts/` | 同捆的歐文字體（Inter、IBM Plex Mono，共 156KB） |
| `build.mjs` | `beforeBuildCommand` 呼叫的複製腳本。**不要改回 shell 指令**，Windows 會壞 |
| `src-tauri/` | Tauri 設定、Rust 進入點、圖示。Rust 端幾乎沒有邏輯，只註冊 fs 與 dialog 外掛 |
| `dist/` | 建置產物（`app.html` ＋ `fonts/` 的複本），不進版控 |
| `docs/` | wireframe、設計來源截圖、給 Claude Design 用的 prompt |
| `.github/workflows/` | 雙平台建置的 CI |

### 字體

**全部同捆，不連網。** `fonts/` 底下共 233 個 woff2，9.8MB。

| 字體 | 檔案 | 用途 |
|---|---|---|
| Inter（可變，300–500） | 2 片 | 歐文本文與標題 |
| IBM Plex Mono 400 | 2 片 | `.meta` 的小標籤與數字 |
| Noto Sans JP（可變） | 124 片 | 和文 |
| Noto Sans TC（可變） | 105 片 | 中文 |

歐文的 4 個 `@font-face` 直接寫在 `app.html` 裡；中日文的 917 行放在
`fonts/noto.css`，由 `<link>` 載入——塞進 app.html 會讓那個檔沒法讀。
**`fonts/noto.css` 是產生出來的，不要手改**，做法寫在 HANDOFF.md 第 6-b 節。

Noto 的片段用 `unicode-range` 切開，所以執行時只會載入畫面上真正出現的字所屬的片段
（實測日文介面約 13 片），不是一次吃掉 9.8MB。

> v0.1.7 之前是用 `@import` 從 Google Fonts 抓的。那是這份「零依賴」架構裡唯一的
> 網路依賴——離線時字會變，而且每次啟動都往外連。代價是 dmg 從 3.4MB 變成 12MB，
> 這是製作者明確選的：視覺一致優先。

### `app.html` 裡的區塊順序

```
STRINGS         i18n（英／日／繁中），全部顯示文字集中在這
Storage         load / save / writeFile / loadFromFile
physics         tick() 每幀解算的碰撞與拖曳
rendering       renderAll() 底下六個 render 函式
actions         setStep / finish / addLog / createCase …
events          document 層的事件委派
screen saver    閒置偵測與全畫面
```

---

## 已知未驗證

- **`file://` 連結**在 Tauri WebView 裡能不能真的開啟本機路徑，還沒實測過
  （`target="_blank"` 在 WebView 可能被攔掉）
- 完成動畫的 2 秒延遲期間如果關掉 app，`done` 不會被寫入

## 之後可能做

- **MCP server** — JSON 檔已經是實體檔案，Claude 可以直接讀寫工作記錄
- **自動記錄** — 監看檔案異動自動生成日誌。日誌已預留 `source: 'manual' | 'auto'` 欄位
