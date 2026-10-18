# BWBC 課程管理系統

福智佛教學院佛法應用研究所的課程管理系統。
- 前端：純 HTML 單檔（admin.html／teacher.html／student.html，另有 survey.html、syllabus*.html、live-poll.html、presentation_view.html），沒有建置流程、沒有共用 JS 模組
- 後端：Supabase（資料庫、RLS、Storage、Auth），SQL 在 schema/
- 部署：Netlify，GitHub repo `leetawu-tw/bwbc`（main 分支）
- 使用手冊：User_Manual_V14.md

## 開工前必讀
- **動手修改前**：先讀 `skill/conventions.md`，確認有沒有現成規則要遵守。
- **除錯前**：先查 `skill/troubleshooting.md`，依症狀照標準排查順序走，不要從零開始猜。
- 背景說明見 `skill/SKILL.md`（其中 `/mnt/project/`、`references/` 是 claude.ai Project 的路徑，本機請對應到 repo 根目錄與 `skill/`）。
- 本機的「確認是最新版」做法：改 admin/teacher/student.html 前先 `git fetch` 並 `git status`／`git diff origin/main -- <檔名>`，確認本機與 GitHub 一致再動手。
- `schema/` 裡的 SQL 可能跟資料庫實際狀態不同步（見 conventions 第 18 條），牽涉資料表結構時先請我在 Supabase 查實際欄位。

## 工作原則
1. **只做最小必要修改**：只改完成這次任務需要的地方。
2. **不重構既有邏輯**：不順手改名、搬移、整理或「優化」沒被要求的程式碼；發現問題就提出來，由我決定要不要改。
3. **分段進行**：每完成一段就停下來，說明改了什麼、要我怎麼測，等我確認後再繼續下一段。
4. 用繁體中文回覆。
5. **不要自己 git commit 或 push**：改完由我檢查後自己提交。
