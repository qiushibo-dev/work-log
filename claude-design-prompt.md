# 拿去 Claude Design 用的東西

## 步驟

1. 打開 `wireframe.html`，**截整頁的圖**（含下方規格說明那塊）
2. Claude Design → 選 animation 或 UI mockup 模板
3. 把截圖拖進去，貼下面那段 prompt
4. 如果已經有建好的 design system，記得在下拉選單掛上

---

## Prompt（直接複製）

```
Build a desktop app UI from the attached wireframe. It is a personal work-tracking
tool for a designer at an agency — one record per client project.

LAYOUT (1600px wide desktop, three zones)

Top bar: search, view toggle, "new project" button.

Upper left — BUBBLE FIELD (the signature element):
- One circle per project, floating and gently colliding with each other like
  balloons, contained within this zone only. Use d3-force (forceCollide plus a
  weak forceCenter) for the packing — the cluster should fill the zone evenly
  rather than sinking to the bottom, and must not overlap the filter chips at the
  top or the legend at the bottom
- Circle SIZE = current intensity of work. It follows a bell curve across the
  project's life: small when just started, largest mid-project, shrinking again
  as it wraps up
- Circle OPACITY = completion. It INCREASES with progress: barely visible when a
  project is first created, fully opaque just before completion
    opacity = 0.18 + 0.82 * progress
- These two encodings are deliberately independent, and the opacity direction is
  deliberately counter-intuitive. Size already shrinks during the wrap-up phase —
  if opacity faded at the same time, a nearly-finished project would become the
  faintest thing on screen. But "stuck at the last 10%" is exactly the state that
  gets forgotten. With opacity increasing, a wrapping-up project reads as small
  and dark — a concentrated dot that pulls attention rather than losing it.
- Do not add a progress ring, a stroke, or a percentage badge to the bubbles.
  Size and opacity carry everything. The bubbles must stay as clean filled circles.
- Click a bubble to select it; the detail card on the right updates
- Hover shows the project name

Upper right — DETAIL CARD for the selected project:
- Title and created date
- Progress: 10 discrete step nodes, clickable to advance. Completed nodes filled,
  current node outlined thicker, future nodes empty. Clicking a node must
  immediately update that project's bubble size and opacity. Reaching node 10
  triggers the completion sequence
- Work log: reverse-chronological entries with date and text, plus a persistent
  one-line input at the bottom for quick capture
- Links: multiple entries, each with a type tag (Drive, Figma, local path, URL)
- When nothing is explicitly selected, show the MOST RECENTLY UPDATED project —
  do not show a "click a bubble to begin" placeholder. That kind of hint is only
  useful once and wastes a whole panel every time after. "Most recently updated"
  means the last project that was WRITTEN to (progress advanced, log added, link
  edited), not merely viewed. On every app launch, default to that project rather
  than restoring the previously selected one.
- A true empty state exists only when there are zero projects: an empty table and
  a prominent "new project" action.

Lower — LIST VIEW:
- Left sidebar: filter by status and by client, with counts. Filters apply to the
  bubble field AND the list simultaneously — they are two views of one dataset
- Main table: project name, a small dot whose opacity mirrors the bubble PLUS a
  numeric percentage (opacity alone is unreadable at 16px, so the number carries
  it), status pill, last-updated, link count. Sorted by last-updated descending; a newly updated row animates to the
  top and briefly highlights
- Clicking a row opens the full project page (different from clicking a bubble,
  which is a quick preview)

INTERFACE LANGUAGE: Japanese.

STYLE: not decided yet — propose something calm and low-contrast that keeps the
bubble field as the visual focus. The bubbles are the only place that should feel
alive; everything else should recede. Avoid heavy borders and avoid a dashboard
look. Think of a quiet workspace, not an analytics product.

COMPLETION SEQUENCE (the one moment worth designing carefully):
When a project hits step 10 and is confirmed, its bubble briefly swells and goes
fully opaque — one last breath — then drifts upward, shrinking and fading out,
leaving a gap in the field. The project moves to the "completed" filter and stays
retrievable from the list. This is the only celebratory moment in the app.

MOTION: the bubbles should drift slowly and settle after collisions. Nothing else
on the screen should animate on idle.
```

---

## 三個建議

### 1. 氣泡數量要設上限

十幾個還好看，超過二十個小圓會小到點不到、名字也塞不下。

建議：**只顯示「進行中 ＋ 待開始」**，完成的案子沉到列表裡。或設一個上限，超過的併成一顆「其他 N 件」。

### 2. 碰撞用現成的物理引擎

自己寫碰撞會做很久且效果不穩。兩個選擇：

- **d3-force** — 專門做這種泡泡聚集，內建 collision 力，程式碼短
- **matter.js** — 真的物理引擎，彈跳感更強但比較重

wireframe 裡我用的是 CSS 假動畫，只是示意。真要做請用上面兩個之一，跟 Claude Design 講明。

### 3. 之後可以打包成真的 app

Claude Design 產出的是 HTML，跟你做星鑑日誌時是同一種東西。要變成 macOS app 的話走 Tauri，你已經踩過一輪坑了。

資料存本機 JSON 就夠，不需要資料庫——你一個人用，案子量級是幾十筆。

---

## 一個要先想清楚的

**這個 app 的成敗不在視覺，在你會不會持續記。**

記錄類工具的死法都一樣：做得很漂亮，用兩週就停了。差別在於「記一筆」要花幾秒。

所以那個常駐的一行輸入框比什麼都重要，它是唯一每天都會碰的東西。設計的時候不要讓它被擠到角落，也不要做成要先點「新增」才展開的形式。
