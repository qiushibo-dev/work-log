# Babos

個人用的工作記錄 app。一個案子一筆記錄，用氣泡的大小與深淺表示「現在佔掉多少腦袋」與「走了多遠」。

macOS 桌面 app（Tauri 打包）。目前 v0.1.6，已在兩台機器安裝實測。

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
# → src-tauri/target/release/bundle/dmg/Babos_0.1.6_aarch64.dmg
```

沒有 `package.json`。`beforeBuildCommand` 會把 `app.html` 複製成 `dist/index.html`，
所以**編輯的對象永遠是根目錄的 `app.html`**，`dist/` 是建置產物。

安裝 dmg 後第一次開啟會被 Gatekeeper 擋（ad-hoc 簽名）：

```bash
xattr -dr com.apple.quarantine /Applications/Babos.app
```

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
| `app.html` | **app 本體**。單一檔案、零依賴，含 CSS 與全部 JS（約 1,890 行） |
| `src-tauri/` | Tauri 設定、Rust 進入點、圖示。Rust 端幾乎沒有邏輯，只註冊 fs 與 dialog 外掛 |
| `dist/` | 建置產物（`app.html` 的複本），不進版控 |
| `docs/` | wireframe、設計來源截圖、給 Claude Design 用的 prompt |

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
