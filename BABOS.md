# Babos — 這是什麼，以及動它之前要知道的事

最後更新：2026-08-17

這份是總覽，寫給**第一次接觸這個專案的人**（或另一台電腦上的 Claude）。
目的是讓你在改任何東西之前，知道哪些是刻意的、哪些是踩過坑才長成這樣的。

同一個資料夾裡另外三份文件更深，但**都停在 2026-08-14 的 v0.1.6，而且只寫 HTML 版**：

| 檔案 | 內容 | 語言 |
|---|---|---|
| `SPEC.md` | 設計決策與**被否決的方案** | 繁中 |
| `DESIGN.md` | 視覺規範 | 繁中 |
| `HANDOFF.md` | v0.1.6 以前的修正紀錄 | 日文 |
| `README.md` | 使用與建置 | 繁中 |

**8/14 之後發生的事都在這一份**：Swift 版整個、完成計數器、介紹網站、介紹影片。

---

## 1. 這是什麼

一個人用的工作記錄工具。macOS app。

**每個案子是一顆泡泡。** 泡泡的大小和濃淡就是全部的資訊，畫面上不寫任何數字、
不畫進度環、不標百分比。

名字是 **bubbles 的諧音**。

### 為什麼存在

作者自己的說法（這段也放在介紹網站的開頭）：

> 我常常看不到手上有什麼要做的事。不管是工作，還是自己想做的。
> 我想看到進度，但不是日期。有時候有變化，想隨手寫一句話就好。

三件事：**看得見手上有什麼**、**看得見進度但不用日期**、**隨手寫一句話**。
整個 app 就是為了這三件事，其他都是次要的。

**它不是專案管理工具。** 沒有截止日、沒有甘特圖、沒有指派。
如果有人提議加那些東西，方向就跑掉了。

---

## 2. 兩個版本，以及先改哪一個

| | HTML / Tauri 版 | Swift 版 |
|---|---|---|
| 定位 | **試驗場** | **本命** |
| 平台 | macOS ＋ Windows | 只有 macOS |
| 專案 | `~/Desktop/Project_work-tracker/` | `~/Desktop/Project_babos-swift/` |
| repo | `qiushibo-dev/work-log`（private） | `qiushibo-dev/babos-swift`（public） |
| 目前版本 | **v0.3.0** | **v0.2.1** |
| 資料 | `~/Library/Application Support/com.shihbo.worklog/work-tracker.json` | `.../com.shihbo.babos-swift/data.json` |

**規則（作者定的）：新點子先在 HTML 版試，確定好用再搬到 Swift 版。**
HTML 版改起來手數少、壞了也輕。

> 「就先分開，但我之後會用 swift 版，html 的版本當作更新前的嘗試。」

⚠️ **兩個 app 都叫 Babos.app，裝在一起會互相覆蓋。** 要並存得先改名。
資料各自獨立，作者說「就先分開」，**不要建議同步**。

⚠️ **要跨版本搬功能之前先問。** 8/16 那次他中午說「暫時先不更新在 swift 版，
這兩天改太多了」，傍晚才改口。

---

## 3. 核心設計：兩條公式（不要動）

這是整個 app 的心臟。兩版數值完全相同。

```
尺寸 ＝ 這件案子現在佔掉多少腦袋（常態曲線）
size = 16 + 144 × (0.18 + 0.82 × sin(progress × π))
→ 最小 42px、中段山峰 160px

濃淡 ＝ 已經走了多遠（單調遞增）
opacity = 0.18 + 0.82 × progress
```

**尺寸的意義是作者親自定義的**，不要重新詮釋成「投入的勞力」：

> 「我作為一個設計師，最頭痛的其實是設計中段的過程，
> 快要結束的時候反而不重要了」

所以中段最大＝最耗神，收尾變小＝剩機械性動作。讀法是：

- 小而淡 ＝ 剛開始
- 大而中 ＝ 正在燒腦
- **小而濃 ＝ 快好了，可以放心**

**兩條必須獨立、不能同方向衰減。** 如果濃淡也在最後變淡，
「剛開始」和「快結束」在畫面上會一模一樣。這是兩者不同的唯一理由。

---

## 4. 已經否決過的方案（不要繞回去）

1. **進度環** — 視覺太雜。不要在泡泡上加環、框、百分比
2. **透明度遞減** — 見上面，會讓兩端無法區分
3. **教學型空狀態**（「點擊氣泡查看詳細」）— 只有第一次有用，改成顯示最後更新的案件
4. **重要度影響泡泡大小** — 重要度只是列表上的圓點，不進泡泡編碼
5. **保護模式放大泡泡** — 明確不要
6. **Tauri 的 `setFullscreen`** — 兩次都閃退，斷念
7. **泡泡的隨機晃動**（Swift 版）— 原生渲染太銳利，抖動變成閃爍，`driftStrength = 0`

---

## 5. 發版流程

### HTML / Tauri 版

```
改 app.html → 升版本號（tauri.conf.json + APP_VERSION）
→ npx --yes @tauri-apps/cli@^2 build
→ git commit / tag / push
→ gh release create vX.X.X <dmg 路徑>
```

推一個 tag 會同時產出 mac 的 dmg 跟 Windows 的 exe（`.github/workflows/release.yml`）。

### Swift 版

```
改程式 → 改 build.sh 裡的版本號（CFBundleVersion 兩處）
→ ./package.sh          # 產物在 ~/.cache/babos-swift-build/
→ git commit / tag / push
→ gh release create vX.X.X <dmg> <zip>
```

### 兩版共通

- **每次都開新 tag**，不要覆蓋舊 Release
- **release 裡一定要有 zip，不能只有 dmg**（原因見第 7 節）
- 未公證，裝完要 `xattr -dr com.apple.quarantine /Applications/Babos.app`
- **app 不會自動更新**，改了程式要自己重裝

---

## 6. 踩過的坑：資料與存檔（最貴的一類）

### 6.1 靜默失敗會吃掉資料

HTML 版早期 `writeTextFile` **不會自動建父目錄**，AppData 那層不存在，
每次寫入都 ENOENT。而錯誤只送到 `console.warn`——**release build 沒有 devtools，
等於完全靜默地失敗了幾十次**，localStorage 在頂著所以表面正常。

**教訓：與其在使用者看不到的地方失敗，不如讓它崩潰。要吞錯誤就必須在 UI 留出口。**
現在兩版的設定畫面都會顯示儲存狀態（成功顯示路徑、失敗顯示紅字）。

### 6.2 Swift 的 Codable 預設值接不住「缺欄位」

```swift
struct Snapshot: Codable { var cycles: [Cycle] = [] }   // 這個 [] 沒有用
```

合成的 `init(from:)` **不會**用那個預設值，鍵不在就丟 `keyNotFound`。
**加一個欄位就會讓所有既有的 data.json 整包讀不進來。**

而 `load()` 讀失敗只是留著空清單繼續跑，**下一次存檔就把空的寫在真資料上**。
症狀是「東西全部消失」。

→ `Snapshot` / `Tags` / `OpenCycle` 都手寫了 `init(from:)` 走 `decodeIfPresent`。
**`Case` / `LogEntry` / `Link` 還是原生的**，往那三個加欄位時要做同樣的事。

### 6.3 debounce 的寫入會在結束時漏掉

400ms 的 debounce，改完不到 400ms 就 Cmd+Q 那次就沒了。
兩版都用終止通知（Swift 是 `willTerminateNotification`）強制寫完。

### 6.4 非同步載入 vs 有 debounce 的寫入

HTML 版早期：從 localStorage 起 state → 排 400ms 寫檔 timer → 才非同步讀 JSON 檔。
**讀檔只要超過 400ms，timer 先發火，用舊的 localStorage 蓋掉正本。**
加了 `booted` 閘門，讀完檔才放行寫入。

---

## 7. 踩過的坑：發布與下載

### 7.1 不要只放 dmg

GitHub release 的下載連結會 302 到簽名過的 CDN 網址，路徑是一串 UUID。
**Chrome 用路徑命名檔案，不管 `Content-Disposition`**，使用者拿到一個
沒有副檔名的 UUID，雙擊沒反應。Safari 正常，Chrome 不會。

而且 Chrome 的下載列會顯示「完成 12.3 MB」，看起來一切正常，很難察覺。

```bash
ditto -c -k --sequesterRsrc --keepParent Babos.app Babos_0.3.0_macos.zip
```

### 7.2 版本比較要用數值

`"0.1.10" < "0.1.9"` 是 `true`。版號跨過個位數的那一刻就會謊報「已是最新」。

### 7.3 建置產物不要放在專案底下

桌面在 iCloud 的 File Provider 管理下，生成的 `.app` 會被加上
`com.apple.FinderInfo`，**codesign 直接拒絕簽章**。
兩版都改放 `~/.cache/`。HTML 版踩了三次才查出根因。

⚠️ macOS 的 codesign 還會**間歇性**失敗（`resource fork ... not allowed`）。
同樣設定連跑兩次，第一次掛第二次過。**這不是設定問題，踩到就重跑。**

---

## 8. 踩過的坑：SwiftUI

1. **`struct Body` 會跟 `View.Body` 撞名**，在 View 內部被解析成 `some View`。已改名 `PhysicsBody`
2. **物理迴圈不能用 `Task.sleep(16ms)`。** 精度差又會 drift，跟 vsync 錯開之後
   「一幀算兩次／零次」交錯，看起來就是泡泡在抖。
   用 `TimelineView(.animation)` 的 date 變化驅動，一幀剛好一次
3. **`drawingGroup()` 會讓泡泡周圍出現方形光暈**（連陰影一起烤進矩形貼圖）
4. **`.offset` 寫在 `.scaleEffect` 內側，位移會被縮放率一起乘掉。**
   著地倍率 0.07 的話飛行距離也只剩 7%。順序是 `.scaleEffect` → `.offset`
5. **`.coordinateSpace` 要放在 `.overlay` 之後。** 放前面的話 overlay 是座標系
   **外**的兄弟，量到的值以視窗原點為基準。症狀很特別：**橫的準、縱的差一條工具列**
6. **`Font.custom` 沒有 fallback 鏈。** 指定 Inter 之後日文會落到系統的 Hiragino，
   嵌入的 Noto 根本用不到。要用 CoreText 的 `kCTFontCascadeListAttribute` 串。
   weight 要用 `kCTFontWeightTrait`，`Font.weight` 對 CTFont 無效
7. **SF Symbol 不能套自訂字體。** 批次替換時連 `Image(systemName:)` 一起換掉的話，
   圖示畫得出來但**可點區域會跑掉**（symbol 依賴系統字體的 metrics）
8. **`LazyVStack` ＋ `.animation` 捲動時會亂跳。** 延遲生成的列被回收再建立，
   每次都被當成狀態改變而播動畫。幾十筆規模直接用 `VStack`
9. **GUI app 的 stdout 拿不到**（全緩衝，程式不結束就不輸出）。要診斷就寫檔案
10. Swift 6 並行性：`@Observable` class 用 Task 就要 `@MainActor`；
    struct 裡的 closure 要 `@Sendable` 才能當 `static let`

---

## 9. 踩過的坑：CSS / 前端

1. **grid 容器的 `::before` 會變成第一個子項目**，佔掉一欄。
   要畫線用 `background: linear-gradient(...)`，那個不進 layout
2. **`z-index` 只在同一個容器內比大小。** 清單被下面的附件行蓋住時，
   加在清單自己身上沒用，要加在**整行**上
3. **CSS 動畫的時間和 JS 的常數必須一致。** 完成動畫的 `FLY_MS = 1400`
   和 CSS 的 `1.4s` 差一點，點就會先出現、或泡泡消失後有空檔
4. **WKWebView 在版面整組換掉時會閃退**（`.upper` 改 `display:block`
   ＋ 泡泡 `position:absolute` 那次）。Chromium 不重現，所以瀏覽器測不出來

---

## 10. 完成計數器（v0.3.0 / v0.2.1）

案子完成一個，篩選列右邊亮一顆燈。滿 20 顆結算一輪，可以匯出 Markdown 報告。

- **空槽不畫**，點亮的才顯示，從右往左長（作者形容成「像遊戲的 HP 值」）
- 一排放得下 20 個就一排，不夠就兩排各 10 個。**只有 20 或 10 兩種**——
  塞得下幾個算幾個會變成 15＋5，割法還會隨視窗一直變，數不清楚
- **完成的泡泡飛進去變成那顆燈**，不是消失。落地直徑剛好 8px
- 滿了的那一輪**封存起來**，不是只把計數器歸零。不封存的話，
  當下沒匯出就永遠找不回那 20 件是哪 20 件
- **點亮的時機在飛行結束之後。** 先點亮的話，泡泡還在空中而著地點已經被佔，
  行進目標會偏一格

### 還沒解決

作者對落地的**體感**還不滿意（「怪怪的但是先這樣吧」）。座標量過是準的，
問題在速度曲線。他要的動作是：

> 往上稍微移動 >> 加速啟動 >>>> 慢慢減速到 >> 到定位

四段，箭頭數量就是時間配分，**減速最長**。「滑進去」不是「飛到就停」。
現在只有第一段（0.252 秒抬 16px），剩下 1.148 秒是單一條 CubicKeyframe，
中段沒推力、末段沒收力。**他說先這樣，不要主動改。**

---

## 11. 周邊產物

### 介紹網站 — https://babos.chiushihbo.com

單一 HTML 檔，原始檔 `~/Desktop/Babos_網頁/index.html`（約 70 KB）。
Netlify 拖放部署，改版就把資料夾重新拖上去。

- 中英日三語，右上角切換，記在 localStorage，首次依瀏覽器語言
- 下載鈕用 GitHub API 動態抓最新版，**優先 zip**
- ⚠️ **部署資料夾裡只能有 `index.html`**。Netlify 拖整個資料夾，
  裡面每個檔案都會變成公開網址（備份放在 `Babos_網頁_備份/`）
- ⚠️ **中文斷句**：CSS 的 `word-break:auto-phrase` **只有日文模型**，
  中文完全沒作用。要用 `Intl.Segmenter` 切詞再逐詞包 `white-space:nowrap`
- ⚠️ **三語不是翻譯**，是三份各自成立的文案。中文照英文句子順序寫會留下
  「維度」「變數」「而且是你的」這種讀起來不像中文的東西

### 介紹影片

`~/Desktop/Babos_影片/babos-promo/`，58 秒，用 HyperFrames 做的。
無聲版 v3 是目前的最終版，**等旁白錄音和 BGM**。

⚠️ 旁白第一版被退回（只是念畫面上的字），v2 改成**畫面講「是什麼」、
旁白講「為什麼」**。

最後一幕是工作分工，寫著：

> Built in conversation with Claude over four days.
> **The code is paired; the decisions are not.**

---

## 12. 現在的狀態

| | 狀態 |
|---|---|
| HTML 版 v0.3.0 | 已發布（mac ＋ Windows），Windows 版沒人裝過 |
| Swift 版 v0.2.1 | 已發布，作者日常在用 |
| 介紹網站 | 已上線 |
| 介紹影片 | 無聲版完成，等音檔 |

### 談過方向但沒動工

- **app 內的「檢查更新」→ 已完成**（兩版都有），不需要重做
- **Gmail 關鍵字 → 系統通知**：架構談定了。**不要背景服務、不要定時排程、
  不要雙向同步。** 作者原話：「我這個 app 的目的就是自己看爽而且要手控，
  我不是想要到處同步」。做法是按一下才查，走本機的 `gws` 指令
- **落地動畫的速度曲線**（見第 10 節）— 等他開口

---

## 13. 動手之前

1. 先讀第 3 節的兩條公式和第 4 節的否決清單
2. 要改 HTML 版就讀 `SPEC.md`，要改視覺就讀 `DESIGN.md`
3. **新功能先在 HTML 版試**，除非他另外交代
4. 改完自己跑一次再說做好了。**打包成 dmg 就等於說它能用**
