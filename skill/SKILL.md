---
name: bwbc-dev-knowledge
description: BWBC（福智佛教學院）課程管理系統的開發規範與除錯知識庫。只要對話內容涉及 admin.html、teacher.html、student.html 這三個檔案的修改，或涉及 Supabase（資料庫、RLS、Storage bucket）、Netlify 部署、Git/GitHub 版本管理，或使用者提到「畫面壞掉」「功能不見了」「樣式跟別的頁面不一致」「列印失敗」「上傳失敗」「sticky 表頭」「資料對不上」等情境，務必主動查閱此 skill，先看 conventions.md 確認是否有現成的架構規則可直接套用，再看 troubleshooting.md 確認是否有對應的標準除錯流程，避免重新發明或重複犯過去犯過的錯。即使使用者沒有明確要求查 skill，只要任務屬於這個專案的開發或除錯，也應主動查閱。
---

# BWBC 課程管理系統 — 開發知識庫

這是福智佛教學院佛法應用研究所課程管理系統（admin.html / teacher.html / student.html，Supabase 後端）在實際開發過程中，**反覆發生三次以上**的問題所整理出的規範與排查手冊。目的是避免同樣的坑被踩第二次、第三次。

## 怎麼用這個 skill

- **動工前** → 看 `references/conventions.md`，確認要做的事有沒有現成規則要遵守（例如新增表格要不要做 sticky 表頭、新增列印功能要注意什麼）。
- **出問題時** → 看 `references/troubleshooting.md`，依症狀對照標準排查順序，不要從零開始猜。
- 兩份文件都不長，直接整份讀完即可，不需要分段查。

## 核心提醒（最容易忘記的事）

0. **任何一次要對 `admin.html`/`teacher.html`/`student.html` 動修改的對話，開工前第一件事：先用 GitHub diff 確認拿到的檔案是不是最新版**——這是整個專案發生頻率最高、後果最嚴重的問題（已發生5次以上，最嚴重一次整份`admin.html`少了6000多行、5大功能模組）。不要等使用者說「功能不見了」才檢查，主動先做：
   ```bash
   curl -s "https://raw.githubusercontent.com/leetawu-tw/bwbc/main/{檔案名}" -o /tmp/gh_latest.html
   diff /mnt/project/{檔案名} /tmp/gh_latest.html | head -50
   ```
   有差異就改用GitHub版本當基底，不要用Project裡的舊版。詳細流程見 `troubleshooting.md` 症狀1、`conventions.md` 第20條。
1. **列印/匯出函式的模板字串裡，絕對不能出現完整的 `</body>`、`</html>`、`</script>` 標籤**——Live Server 會誤判注入，把 JS 弄壞。一律拆成 `</bo'+'dy>` 的形式。
2. **`overflow-x:auto` 會讓瀏覽器把 `overflow-y` 也強制變 `auto`**，這是 CSS 規格的冷知識，不是 bug。要做固定表頭（sticky thead），容器一定要給明確的 `max-height` + `overflow:auto`。
3. **先刪全部再寫入（delete-then-reinsert）的儲存模式，存檔前一定要檢查陣列不是空的**，否則資料載入失敗時會把舊資料整批清空，且使用者察覺不到。
4. **SQL 直接寫 `auth.users` 建立帳號，一定要同步補 `auth.identities` 記錄、並確認 token 欄位是空字串不是 `NULL`**，否則帳號看起來正常但密碼登入會失敗（缺 identities 回400，NULL token 回500）。
5. **Supabase Storage 裡會被覆蓋更新的檔案（如範本），抓取一定要用 signed URL + `cache:'no-store'`**，不能只用 `.download()`，否則CDN快取會讓你抓到舊版內容、完全沒有錯誤訊息，極難排查。
6. **新增一種「人員角色關係」（如導師、所長、TA）時，要主動檢查相關表的RLS policy有沒有認識這種新關係**，否則會出現「部分欄位有值、部分欄位空白」的詭異半成功現象。
7. **修改既有表的enum-like欄位（如role）前，先查資料庫真正的CHECK constraint，不要憑空設計選項**，自己想的值很可能跟資料庫實際允許的不符。
8. **補RLS政策時，如果查詢是巢狀select（nested join，例如`enrollments`帶出`students(...)`），被巢狀帶出的每一張子表都要各自補上對應政策，不能只顧到最外層那張表**——這種失敗模式特別陰險：不是「整個功能對所有人都空白」，而是「對某些使用者少幾筆、對另一些使用者不少」，容易被誤判成資料問題。詳見 `troubleshooting.md` 症狀15。
9. **改既有表的欄位型別／長度之前，先查「生成欄位、視圖、索引、policy」的相依**——`students.student_code` 被 `cohort` 生成欄位與兩個視圖依賴，直接 `ALTER COLUMN TYPE` 會失敗。用「暫存→移除→修改→重建→比對」放在同一個 `DO $$` 交易裡，並從資料庫動態讀計算式，不要猜。詳見 `conventions.md` 第 31 條、`troubleshooting.md` 症狀17。
10. **學分班（`students.student_type <> 'regular'`）只在選課、點名單、教學意見調查需要；任何「學生統計」類功能都要排除他們**，且批次產生記錄（問卷連結）要能補產生、略過休學／退學、課程停開要排除（`is_cancelled`）。詳見 `conventions.md` 第 32～34 條。
11. **休學是學生狀態、停修是課程狀態，不能混用**：休學／退學時選課記錄標 `withdrawn` 且原因開頭「休學」「退學」，顯示層依原因轉換；學期層級的學籍要看「該學期結束當下」的歷程（`student_status_history`），不是現在值；老師端讀不到歷程要用折衷，學生端要先建 self_read policy；休學、退學、停修仍列名單但不算人數（`conventions.md` 第 35 條、`troubleshooting.md` 症狀20、23）。
12. **匯出給 Excel 的 10 碼學號要寫成文字格式（`="…"`），需要欄寬改匯 `.xlsx`**（`conventions.md` 第 36 條）。
13. **日期字串（yyyy-mm-dd）全程當字串處理**；經過 Date 物件再 `toISOString()` 會差一天——詳見規則37。
14. **Storage 上傳路徑不能含中文（含 `%`）**——規則42；**SQL Editor 建新表要另外 GRANT**——規則43。
15. **匯入覆蓋既有資料前先做新舊比對**——規則40；**工具列按鈕超過 5～6 顆收進下拉**——規則41；**Word 套版／解析的坑**——規則39；**定期盤查全庫 RLS**——規則38。
16. **刪除或修改後要驗證筆數（`.select()`）並同步快取變數**——症狀13；**改 view 前先 `pg_get_viewdef`**——症狀10。
17. **同一個顯示邏輯複製在三個 portal 或畫面／匯出多處時，改一處就要 grep 全部**——規則44（首頁時程、彙總 Excel 備註欄、成績單標籤都漏改過）。
18. **要呼叫第三方 API（Anthropic）用 Supabase Edge Function 中繼，金鑰只放 Secrets、函式內檢查 admin 身分、送匿名資料、金鑰設到期提醒**——規則45、症狀24。

詳細規則與排查步驟見下方兩份參考文件。
