# 福智佛教學院 佛法應用研究所
# 課程暨論文管理系統 操作手冊

> 版本：v13　最後更新：2026-06-19
> 系統網址（本機測試）：http://127.0.0.1:5501
> Netlify：https://glistening-crostata-4189e7.netlify.app
> 本版新增（v12-v13）：教師課表 exportPDF 多行 template literal 排版錯誤修正（含圖例樣式補齊）、公佈欄附件管理（編輯時可查看/刪除現有附件，替換＝刪除+重新上傳）、admin 三區域（topbar/sidebar/content）獨立捲動修正（根因為 min-height:100vh 應改 height:100vh+overflow:hidden）

---

## 系統頁面總覽

| 檔案 | 對象 | 登入 | 版本 | 說明 |
|------|------|------|------|------|
| `admin.html` | 行政 | 是 | v4.6 | 後台管理（含帳號管理、列印功能、附件管理、三區獨立捲動）|
| `student.html` | 學生 | 是 | v2.2 | 選課 + 畢業論文 + 意見調查 |
| `teacher.html` | 教師 | 是 | v2.2 | 公佈欄、我的課程（含大綱）、個人資料、所有課程、教學意見、成績登錄 |
| `syllabus.html` | 所有人 | 否 | — | 課程大綱（由課程頁進入）|

---

## 目錄

### 第一部　學生使用手冊
1. [登入學生入口](#1-登入學生入口)
2. [選課操作](#2-選課操作)
3. [查看畢業進度](#3-查看畢業進度)
4. [畢業論文：申請指導教授](#4-畢業論文申請指導教授)
5. [畢業論文：列印申請單](#5-畢業論文列印申請單)
6. [畢業論文：被退回後重新申請](#6-畢業論文被退回後重新申請)

### 第二部　教師使用手冊
7. [登入教師入口](#7-登入教師入口)
8. [我的課程與大綱填寫](#8-我的課程與大綱填寫)
9. [個人資料維護](#9-個人資料維護)
9a. [成績登錄](#9a-成績登錄)
9b. [教學意見調查（規劃中）](#9b-教學意見調查規劃中)

### 第三部　行政使用手冊
10. [登入後台](#10-登入後台)
11. [開課記錄管理](#11-開課記錄管理)
11a. [新增開課](#11a-新增開課)
11b. [取消開課](#11b-取消開課)
12. [課程管理（資料管理）](#12-課程管理資料管理)
13. [課程大綱／教師／教室管理](#13-課程大綱教師教室管理)
13a. [教師管理（含匯出匯入）](#13a-教師管理含匯出匯入)
14. [課表展開](#14-課表展開)
15. [衝堂警示](#15-衝堂警示)
16. [學期管理](#16-學期管理)
17. [CSV 匯入匯出](#17-csv-匯入匯出)
18. [畢業論文後台：審核待辦](#18-畢業論文後台審核待辦)
19. [畢業論文後台：進度總覽與編輯](#19-畢業論文後台進度總覽與編輯)
19a. [畢業論文：匯出](#19a-畢業論文匯出)
19b. [畢業論文：匯入（多用途）](#19b-畢業論文匯入多用途)
19c. [畢業論文：批次建立記錄（SQL）](#19c-畢業論文批次建立記錄sql)
20. [畢業論文後台：歷程查看](#20-畢業論文後台歷程查看)
20a. [操作記錄](#20a-操作記錄)
20b. [會議管理](#20b-會議管理)

### 第四部　技術維護手冊
18. [系統架構](#18-系統架構)
19. [登入機制與帳號權限](#19-登入機制與帳號權限)
20. [課程相關資料表](#20-課程相關資料表)
21. [畢業論文資料表](#21-畢業論文資料表)
22. [Storage 設定（檔案上傳）](#22-storage-設定檔案上傳)
23. [資料匯入](#23-資料匯入)
24. [部署與常見問題](#24-部署與常見問題)
25. [附錄：SQL 維護指令](#25-附錄sql-維護指令)

---

# 第一部　學生使用手冊

## 1. 登入學生入口

開啟 `http://127.0.0.1:5500/student.html`

### 方式一：Email 登入連結（正式）
1. 輸入學校 Email（學號@bwbc.edu.tw）
2. 點「傳送登入連結」
3. 收信點擊連結 → 自動登入

### 方式二：密碼登入（測試用）
登入畫面下方有「— 或使用密碼登入（測試用）—」區塊：
1. 輸入 Email 與密碼
2. 點「密碼登入」

> **提醒**：請使用**一般瀏覽器視窗**，不要用無痕視窗。無痕視窗的「Tracking Prevention（追蹤防護）」會阻擋登入狀態（session）儲存，導致無法保持登入。

---

## 2. 選課操作

登入後預設在「📚 選課」分頁。

| 功能 | 操作 |
|------|------|
| 加選課程 | 課程卡點「＋ 加選」|
| 退選課程 | 已選課程點「✅ 已選　退選」|
| 查看大綱 | 點「📋 大綱」|
| 查看其他年級課程 | 點右上「🔍 查看其他年級課程」|

### 系統自動檢查
- **學分上限**：超過本學期上限無法加選
- **時間衝堂**：與已選課程時間重疊會擋下
- **重複修課**：修過同名課程會提醒或阻擋

四個分頁：選課 / 本學期已選課程 / 歷年已選課程 / 📝畢業論文。

---

## 3. 查看畢業進度

頁面上方「🎓 畢業進度」區塊依學期分三欄顯示：

```
已取得 N學分（114-1）＋ 本學期 N學分（114-2）＋ 新學期 N學分（115-1）
```

- **已取得**：`is_current` 之前已結束的學期
- **本學期**：`is_current` 的前一個學期（課程進行中）
- **新學期**：`is_current` 學期（目前選課中）

必修／選修／合計各顯示三欄數字及進度百分比。進度條深色段 = 已取得＋本學期，淺色段 = 新學期。

右側**畢業論文進度儀表**顯示四個階段（①②③④），中間三條刻度線標示分界，滑鼠移到各弧段可看階段名稱。
- 儀表文字：「① 申請指導教授」→「② 確認論文題目（進行中）」→ ... →「✅ 已完成」
- 儀表同時顯示於**選課頁**（右上角）和**畢業論文頁**（階段進度條旁邊），兩處自動同步

> **注意**：`courses.is_audit=true` 是課程屬性（開放隨班附讀），不影響學分計算。

---

## 4. 畢業論文：申請指導教授

點「📝 畢業論文」分頁。

論文流程分四階段：**①申請指導教授 → ②確認論文題目 → ③送件學倫審查 → ④完成論文撰寫**

### 申請步驟
1. 在「指導教授」區塊點「＋ 申請指導教授」
2. 填寫表單：
   - **指導教授（主）**：必選
   - **協同指導教授**：選填，最多 2 位
   - **論文研究方向／題目**：必填
3. 點「送出申請」
4. 狀態變成「⏳ 指導教授申請審核中」，等待行政審核

> 教授不可重複選擇（主與協同不能同一人）。

---

## 5. 畢業論文：列印申請單

指導教授申請送出後，「指導教授」區塊會出現「🖨 列印指導教授申請單」按鈕。

1. 點該按鈕 → 開新視窗顯示 A4 申請表
2. 自動帶入：學號、姓名、年級、申請日期（民國年）、主與協同教授、研究方向
3. 表單含三層核章欄：所長 / 教育處助理 / 教育長
4. 瀏覽器列印對話框會自動出現
5. 可直接列印，或在印表機選「**另存為 PDF**」存成電子檔

> 列印單供紙本簽核用。線上申請與紙本簽核並行。

---

## 6. 畢業論文：被退回後重新申請

若行政審核後退回申請，論文分頁會顯示：

```
⚠️ 您的指導教授申請已被退回，請重新申請
退回原因：（行政填寫的說明）
[＋ 重新申請指導教授]
```

點「重新申請」時，表單會**自動帶入上次填寫的內容**（教授、研究方向），您只需在原基礎上修改後再送出。

---

# 第二部　教師使用手冊

## 7. 登入教師入口

開啟 `http://127.0.0.1:5500/teacher.html`，使用 Email 登入（Magic Link 或帳號密碼）。

登入後自動進入「📢 公佈欄」，左側導覽列可切換各功能。

### 教師入口頁面結構

teacher.html 採用**左側導覽 + 右側內容**的 SPA 佈局，一次只顯示一個功能：

| 左側選單 | 說明 |
|---------|------|
| 📢 公佈欄 | 進入頁面預設顯示，含收合/展開 + ⊟ 全部收合按鈕 |
| 📚 我的課程 | 個人開課課程、填寫課程大綱、學期下拉篩選、⊞ 資訊卡 / ☰ 資訊列 雙模式 |
| 👤 個人資料 | 維護個人簡介與照片 |
| 🗂 所有課程 | 查看全校課程（唯讀），含學期下拉、⊞ 資訊卡 / ☰ 資訊列（預設表格）|
| 📊 教學意見 | 教學意見調查 |
| 📊 成績登錄 | 學科成績輸入、匯出入 |

> **注意**：`users` 表的 `teacher_id` 欄位必須對應 `teachers.id`，否則無法讀取修課學生資料。可執行批次補齊：`UPDATE users u SET teacher_id = t.id FROM teachers t WHERE u.email = t.email AND u.role = 'teacher' AND u.teacher_id IS NULL;`

---

## 8. 我的課程與大綱填寫

左側點「📚 我的課程」：
- 頂部**學期下拉**（預設選現在學期 `is_current=true`，找不到選最新）
- **統計顯示**：「共 X 門 · Y 學分」
- **⊞ 資訊卡 / ☰ 資訊列** 雙模式切換（預設卡片）
- 資訊卡：代碼、名稱、時間、教室、大綱完成度（X/6）、共同授課教師（👥）
- 資訊列（表格）：學期、代碼、名稱、學分、必/選（徽章）、主軸、**授課教師**、時間、教室、大綱
  - 表格所有欄位可排序
  - 教師欄：多位教師用「、」分隔，自己的名字**粗體**顯示
- 點「填寫大綱 / 編輯大綱」開啟編輯器

### 8a. 所有課程

左側點「🗂 所有課程」：
- **學期下拉**（預設選現在學期）
- **統計**：「共 X 門 · 必修 Y 門 · 選修 Z 門（含二選一 N 門）」
- **⊞ 資訊卡 / ☰ 資訊列**（預設表格）
- 表格欄位：學期、代碼、名稱、學分、必/選、主軸、授課教師、時間、教室（全部可排序）
- 必/選徽章顏色：必修（粉紅）、選修（藍）、二選一（橙）
- req_type 對照：req=必修、sel=選修、go=二選一

大綱含 7 區段：概述 / 教學目標 / 教學方法 / 評量方式 / 教學進度 / 參考書目 / 備註。儲存後行政端與學生端即可看到。

### 教學進度（每週）填寫
每週一列，顯示：週次 / 主題 / 授課教師 / **＋ 展開鈕**。
- 點「**＋**」展開該週的**詳細內容**輸入框（每行一個項目，可用 • 開頭）
- 詳細內容會顯示在學生端課程大綱（保留換行）
- 展開區內有「🗑 刪除此週」（含確認，避免誤刪）
- 點「**−**」收合
- 底部「＋ 新增週次」可加一週

> 資料存於 `syllabi.weeks`（jsonb 陣列），每週物件結構：`{week, title, teacher, content}`。

---

## 9. 個人資料維護

左側點「👤 個人資料」：
- 上傳個人照片（建議尺寸 300×300 像素，正方形；支援 jpg/png）
- 填寫中文簡介、師資介紹網址
- 姓名／職稱／機構為唯讀（由行政管理）

> **照片上傳需先建立 Storage bucket**，否則會出現「Bucket not found」。

左側點「🗂 所有課程」：查看全校課程（唯讀）。

---

## 9a. 成績登錄

左側點「📝 成績登錄」，顯示本學期行政已啟動且在期限內的課程卡片列表。

### 課程卡片列表
- 每張卡顯示：學期、課程代號、課程名稱、截止時間、已登錄人數、狀態（未開始／登錄中／已送出）
- 點卡片進入該課程的學生成績表

### 成績輸入
- 表格欄位：序號、學號、姓名、成績（0-100）、等第（自動換算）、備註
- 停修學生：灰色底色，備註「停修」，成績欄不可輸入
- 休學學生：灰色底色，備註「休學」，成績欄不可輸入
- 輸入成績後即時自動儲存（upsert）
- 等第依學期設定的等第表自動換算（優秀90-100、良好80-89、中等70-79、及格60-69、不及格0-59）

### 匯出 CSV
- 格式含學校抬頭、課程資訊（必選修、學分數）、學生成績表、結尾簽名欄
- 檔名：`{學期}_{課程代號}{課程名稱}_{老師姓名}_學期成績.csv`

### 匯入成績
- 點「📤 匯入成績」開啟 Modal（同 admin 風格：拖曳區 + 預覽 + 確認）
- 先「⬇ 下載成績範本」取得含學號姓名的空白表格，填寫後匯入
- 範本檔名：`(範本){學期}_{課程代號}{課程名稱}_{老師姓名}_學期成績.csv`
- 停修/休學學生自動略過（顯示「略過（停修）」）
- 已送出後無法匯入（提示「成績已送出，如需修改請聯絡行政解鎖」）

### 確認送出
- 綠色「✅ 確認送出」按鈕：送出後立即鎖定所有輸入欄
- 已送出：灰色「🔒 已送出（如需修改請聯絡行政解鎖）」
- 已確認：藍色「✅ 已確認（行政已複核）」

### 解鎖流程
1. 老師電話聯絡行政
2. Admin 在「成績登錄 → 成績狀態」按「🔓」填寫解鎖原因
3. 老師重新修改並送出

---

## 9b. 教學意見調查（規劃中）

左側點「📊 教學意見」，功能尚在規劃中。

---

# 第三部　行政使用手冊

## 10. 登入後台

開啟 `http://127.0.0.1:5500/admin.html`

### 標準流程
1. VS Code 開啟 admin.html → 右下角「Go Live」啟動 Live Server（Port 5500）
2. 瀏覽器開 `http://127.0.0.1:5500/admin.html`
3. 輸入行政 Email（如 meiyi.wu@bwbc.edu.tw）→「傳送登入連結」
4. 收信點連結 → 自動進入後台

### 快速產生登入連結（IT 用，繞過寄信限制）
```powershell
cd "D:\A類\Tools\佛應所課程管理\佛應所課程管理v2"
node -e "require('dotenv').config(); const { createClient } = require('@supabase/supabase-js'); const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, {auth:{autoRefreshToken:false,persistSession:false}}); sb.auth.admin.generateLink({type:'magiclink',email:'meiyi.wu@bwbc.edu.tw',options:{redirectTo:'http://127.0.0.1:5500/admin.html'}}).then(({data,error})=>{ if(error){console.log('❌',error.message);return;} console.log(data.properties.action_link); });"
```
複製輸出連結 → 瀏覽器網址列貼上 → **立即** Enter（連結有時效，過期會 otp_expired）。

> **重要**：行政帳號必須在 `users` 表有 `role='admin'` 的記錄，否則因權限（RLS）看不到論文等資料。詳見第 19 節。

### 儀表板統計（動態）
儀表板的「本學年開課」統計和時程提醒，依 `semesters.is_current=true` 動態計算：
- **本學期**：`is_current` 的前一個學期（如 114-2）
- **新學期**：`is_current` 學期（如 115-1）
- **時程提醒**：從 `semesters` 表和 `enrollment_settings` 表動態取得，不再硬寫日期

---

## 11. 開課記錄管理

**後台 → 左側「課程管理 → 開課記錄」**

頁面頂部統計列顯示：**共 N 門｜必修 N｜選修（含2選1）N｜學分數 N**，隨學期切換自動更新。

點欄位標題可排序。支援兩種顯示模式：⊞ 資訊卡 / 列表。

每門課有 4 個操作按鈕：
- **✏️ 編輯**：修改上課日、起訖時間、教室、授課教師等
- **📋 大綱 X/6**：顯示大綱完成度（0-6 分），hover 顯示每區段 ✅/⬜ 狀態，點擊開啟大綱編輯器
- **📋 點名**：列印課程點名單（見 §20a）
- **🗑 取消**：取消開課

---

## 11a. 新增開課

**後台 → 開課記錄 → 「＋ 新增開課」**

1. 先選好上方學期（如 115-1）
2. 點右上角「＋ 新增開課」
3. 從下拉選單選擇課程（顯示代碼＋名稱，僅列啟用中的課程）
   - 選課程後代碼、名稱、📱🎓屬性自動帶入
4. 填入上課日、開始/結束時間、教室、上課頻率
5. 選填授課教師
6. 點「💾 儲存」

> 系統自動對應目前選擇的學期，完成後自動執行衝堂偵測。

---

## 11b. 取消開課

**後台 → 開課記錄 → 「🗑 取消」**

1. 找到要取消的課程，點「🗑 取消」
2. 確認視窗顯示：「確定要取消『XXX』本學期（115-1）的開課？」
3. 點「確定」

> 此操作刪除該學期的開課記錄及相關選課資料，**課程主檔不受影響**。完成後自動更新衝堂 badge。

---

## 12. 課程管理（資料管理）

**後台 → 左側「資料管理 → 📚 課程管理」**

管理**課程主檔**（與學期無關的課程本體），是建立開課記錄的前提。

### 課程代碼規則
```
A D 2 2 0 0 1
│ │ │ │ └─┴─┴── 流水號 001~999
│ │ │ └──────── 1=必修  2=選修（含2選1）
│ │ └────────── 2=碩士班
│ └──────────── D=佛法應用研究所
└────────────── A（固定）
```

### 列表功能
- 統計列：**啟用 N 門｜必修 N｜選修（含2選1）N｜停用 N**
- 搜尋（代碼或名稱即時篩選）
- 「顯示停用課程」勾選框（停用課程預設隱藏）
- 欄位排序：代碼、課程名稱、主軸、學分、**狀態**

### 新增課程
1. 點右上角「＋ 新增課程」
2. 代碼**留空**→ 系統依必選修自動產生（AD21xxx 必修 / AD22xxx 選修）
3. 填入必填欄位：中文名稱、課程主軸、學分、必選修
4. 選填：英文名稱、系列、屬性（📱數位課程、🎓隨班附讀、🔁循環開課）
5. 點「💾 儲存」

### 編輯課程
點「✏️ 編輯」，代碼唯讀，其餘欄位皆可修改。

### 停用課程
1. 點「✏️ 編輯」→ 展開下方「⏸ 停用此課程」區塊
2. 填寫**停用原因**（必填）
3. 點「⏸ 確認停用」→ 二次確認
4. 停用後課程變灰色顯示，狀態欄顯示「停用」，列表顯示停用原因

> 停用後仍可點「▶ 重新啟用」恢復。歷史開課記錄完整保留。

---

## 13. 課程大綱／教師／教室管理

**課程大綱**（開課記錄 → 📋 大綱）：7 區段，評量方式需加總 100%。
**教師管理**（資料管理 → 教師管理）：詳見 13a。
**教室管理**（資料管理 → 教室管理）：A113、A220、A301（禪堂）、A210（電腦教室）、A109（梵語玲玲講堂）、EXT（校外）。

---

## 13a. 教師管理（含匯出匯入）

**後台 → 資料管理 → 教師管理**

### 列表功能
- 統計列：啟用 N 位｜專任 N｜兼任 N｜外聘 N｜來賓 N
- 搜尋（姓名、email 或教師證號）
- 欄位：姓名、職稱、類型、機構、Email、**教師證號**、狀態

### 新增／編輯
欄位包含：中文姓名、英文姓名、教師類型、職稱、機構、Email、**教師證號**（選填）、個人簡介、備註

### 📤 匯出
點「📤 匯出」下載全部教師資料 CSV，欄位含：`name_zh, name_en, teacher_type, title, affiliation, email, cert_no, bio_zh, notes, active`

### 📥 匯入
1. 點「📥 匯入」→ 下載範本
2. 填寫 CSV（`name_zh` 必填，`teacher_type` 須為 full_time/adjunct/external/guest）
3. 上傳後預覽：🟢 新增 / 🟡 衝突（同姓名）/ 🔴 錯誤
4. 衝突可逐筆選「略過／覆蓋」或一鍵全部

### 教師證號說明
`cert_no` 欄位為選填，格式如「副字第036171號」。匯入論文指導教授申請時，若 CSV 有填教師證號，系統會自動補入教師資料（不覆蓋已有值）。

---

## 14. 課表展開

**後台 → 左側「課程管理 → 課表展開」**

包含三個子頁面：

### 📋 學期總表
- 選學期後自動載入，顯示統計列：**共 N 門｜必修 N｜選修（含2選1）N**
- 同一時段多門課**並排顯示**，不重疊
- 時間待確認的課程列在表格上方
- **滑鼠移到課程方塊（或待確認標籤）**：200ms 後彈出完整課程資訊卡（課程名稱、主軸、學分、必選修、📱🎓標記、時間、教室、授課教師）
- 表格下方有**圖例說明**（主軸色碼、📱🎓標記、學分、教室）
- 點「🖨 列印/匯出 PDF」可匯出

### 👤 教師課表 / 🏛 各教室課表
選教師/教室 + 學期，自動顯示個人週課表，點方塊看詳情。

---

## 15. 衝堂警示

**後台 → 左側「⚠️ 衝堂警示」**

- 進入頁面**自動偵測**，無需手動按按鈕
- 偵測同一時段的**教室衝突**或**教師衝突**
- 單週 vs 雙週不誤報；集中課程不納入
- 點右上「🔍 重新偵測」可手動更新

### 自動偵測時機
以下操作完成後，側欄 badge 數字自動更新：
- 新增開課
- 編輯開課儲存
- 取消開課
- CSV 匯入開課記錄

---

## 16. 學期管理

**後台 → 左側「系統管理 → 📆 學期管理」**

- **新增學期**：學年（民國）、學期（1/2）、起訖日、是否現在學期
- **移轉課程（🔀）**：選目標學期 → 勾選課程 → 執行
- **刪除學期（🗑）**：有開課記錄者拒絕刪除

---

## 17. CSV 匯入匯出

### 匯出格式說明

所有匯出的 CSV 格式統一為：
```
第1列：中文標題（給人閱讀用）
第2列：英文欄位名（匯入時系統對照用）
第3列起：資料
```

| 位置 | 按鈕 | 內容 |
|------|------|------|
| 課程管理 | 📤 匯出 | 課程主檔全部欄位 |
| 開課記錄 | 📤 匯出 | 本學期開課記錄（含教師、教室）|
| 教師管理 | 📤 匯出 | 全部教師資料 |
| 畢業論文 | 📤 匯出 | 論文進度（含篩選）|

> 匯出的 CSV 可直接修改後再匯入，欄位順序與匯入範本一致。

### 匯入流程

1. 點「📥 匯入」→ 選擇範本類型（論文匯入需先選類型）
2. 下載對應範本（含欄位說明）
3. 填寫 CSV 後上傳（拖曳或點擊）
4. 預覽表格，系統標示三種狀態：
   - 🟢 **新增** — 不存在，將新增
   - 🟡 **衝突** — 已存在，顯示現有值 vs 匯入值差異
   - 🔴 **錯誤** — 必填缺漏或格式錯誤（自動跳過）
5. 衝突列逐筆選「**略過**」或「**覆蓋**」，或一鍵「全部略過/覆蓋」
6. 點「✅ 確認匯入」
7. 結果報告：新增 N、更新 N、略過 N、失敗 N
7. 結果報告：新增 N、更新 N、略過 N、失敗 N

### 範本 A — 課程主檔

| 欄位 | 說明 | 必填 |
|------|------|------|
| `code` | 課程代碼（留空自動產生）| — |
| `name_zh` | 中文名稱 | ✅ |
| `name_en` | 英文名稱 | — |
| `axis_code` | 主軸：底蘊/對話/應用 | ✅ |
| `credits` | 學分數（數字）| ✅ |
| `req_type` | req=必修 sel=選修 go=二選一 | ✅ |
| `series_group` | 課程系列名稱 | — |
| `sequence_num` | 序列編號（數字）| — |
| `is_cycling` | 循環開課 TRUE/FALSE | — |
| `is_digital` | 數位課程 TRUE/FALSE | — |
| `is_audit` | 隨班附讀 TRUE/FALSE | — |
| `description` | 課程說明 | — |
| `notes` | 備註（內部）| — |

### 範本 B — 開課記錄

欄位順序與匯出完全一致，可直接修改匯出檔案後匯入。

| 欄位 | 說明 | 匯入用途 |
|------|------|------|
| `course_code` | 課程代碼 | ✅ 必填 |
| `name_zh` | 中文名稱 | 僅供核對，忽略 |
| `name_en` | 英文名稱 | 僅供核對，忽略 |
| `semester_label` | 學期標籤，如 115-1 | ✅ 必填 |
| `day` | 1=週一~5=週五（留空=待確認）| ✅ |
| `start_time` | 開始時間 HH:MM | ✅ |
| `end_time` | 結束時間 HH:MM | ✅ |
| `time_raw` | 顯示文字，如「週三 09:00-12:00」| ✅ |
| `classroom_code` | 教室代碼，如 A113 | ✅ 匯入對應用 |
| `classroom_name` | 教室名稱 | 僅供核對，忽略 |
| `teacher_names` | 教師中文名，多位用「/」分隔 | ✅ |
| `week_pattern` | every/odd/even/intensive | ✅ |
| `target_cohort` | 適用年級數字，如 115 | ✅ |
| `credits` | 學分數 | ✅ 同步更新課程主檔 |
| `req_type` | req/sel/go | 僅供核對，忽略 |
| `axis_code` | 主軸代碼 | 僅供核對，忽略 |
| `is_digital` | 數位課程 TRUE/FALSE | ✅ 同步更新課程主檔 |
| `is_audit` | 隨班附讀 TRUE/FALSE | ✅ 同步更新課程主檔 |
| `notes` | 備註 | ✅ |

> 教師以**中文姓名**識別，找不到對應者會顯示警告但不擋匯入，事後可手動補。

---

## 18. 畢業論文後台：審核待辦

**後台 → 左側「📝 畢業論文」**。選單旁紅點顯示待審核數量。

預設進入「⏳ 待審核」列表，顯示學生送出的：
- **指導教授申請**（教授名單、研究方向）
- **論文題目修改申請**（新題目、原因）

### 核准
點「核准」：
- **指導教授申請** → 教授狀態變「完成」，論文階段 0→1
- **題目修改** → 更新正式題目、寫入歷程，階段進到 2

### 退回
點「退回」→ 彈窗填**退回原因**（學生會看到）→ 確定退回。
- 指導教授申請：狀態變「退回重議」，舊記錄保留為歷史（is_active=false）
- 學生端會看到退回原因，可重新申請

---

## 19. 畢業論文後台：進度總覽與編輯

點右上「📋 論文進度總覽」，顯示所有學生論文進度表格。

**六個欄位均可點擊排序**：學號 / 姓名 / 年級 / 目前階段 / 指導教授 / 論文題目。

### 階段語意（重要）
本系統 **stage = 已完成的階段數**：

| stage | 顯示 |
|-------|------|
| 0 | 尚未申請 |
| 1 | ② 確認論文題目（進行中）|
| 2 | ③ 送件學倫審查（進行中）|
| 3 | ④ 完成論文撰寫（進行中）|
| 4 | ✅ 已完成 |

學生端與後台採同一語意，兩端一致。

### 編輯（✏️）
點「✏️ 編輯」開啟彈窗，可登錄：
- **目前階段**：手動下拉調整 0~4
- **階段二 論文題目**：中文／英文／變更原因
  - 行政可直接修改題目（A 方案）
  - 題目有變動時，**自動寫入變更歷程**（含修改者、時間、原因）
- **階段三 學倫送審**：審查狀態 / 案號 / 通過日期
- **階段四 完成論文**：口試日期 / 完成日期 / 成績

點「儲存」更新。

> **題目維護策略**：目前採 A（行政直接在編輯彈窗修改）。未來若需要學生自行提出題目申請再由行政核准（C 方案），可再擴充。研究生換題目時，每次變更都會留存歷程。

---

## 19a. 畢業論文：匯出

**後台 → 畢業論文 → 📤 匯出**

### 篩選條件（可複合）
- 年級（全部 / 113 / 114 / 115…）
- 指導教授（全部 / 某教授）
- 階段／狀態（全部 / ①②③④ / 已完成）
- 學號或姓名搜尋

點「🔍 預覽筆數」確認後，點「📤 下載 CSV」。

### 匯出欄位
`student_code, name_zh, cohort, main_advisor, co_advisors, title_zh, title_en, stage, stage_label, applied_at, title_confirmed_at, ethics_status, ethics_submitted_at, ethics_case_no, ethics_approved_at, defense_date, completed_at, final_grade, admin_note`

### stage_label 對照
| stage | stage_label |
|---|---|
| 0 | ① 申請指導教授 |
| 1 | ② 確認論文題目（進行中）|
| 2 | ③ 送件學倫審查（進行中）|
| 3 | ④ 完成論文撰寫（進行中）|
| 4 | ✅ 已完成 |

---

## 19b. 畢業論文：匯入（多用途）

**後台 → 畢業論文 → 📥 匯入**

### 匯入類型
選擇類型後下載對應範本，填寫 CSV 上傳。

#### ① 申請指導教授結果（stage 0→1）
適用：行政收到指導教授申請後，批次核准並建立記錄。

**範本欄位（照既有資料表格式）：**
```
通過申請日期, 學號, 姓名, 指導教授, 指導教授級別, 指導教授教師證,
協同指導教授, 協同指導教授級別, 協同指導教授教師證, 論文主題
```

- 系統以**姓名**核對教師資料表（`teachers.name_zh`）
- 教師證號若有填且目前為空，自動補入教師資料
- 只更新 stage=0 的學生；其他 stage 顯示⚠️略過
- `論文主題` 選填，事後可在後台修改

#### ③ 學倫審查結果（stage 2→3）
**範本欄位：**
```
student_code, ethics_result(pass/fail), ethics_case_no,
ethics_submitted_at, ethics_approved_at, admin_note
```

- `pass` → stage 2→3，`ethics_status='完成'`
- `fail` → stage 維持 2，`ethics_status='補件中'`
- 只更新 stage=2 的學生

### 預覽說明
| 標示 | 說明 |
|---|---|
| 🟢 可更新 | 驗證通過，將執行 |
| ⚠️ 略過 | stage 不符，略過 |
| 🔴 錯誤 | 必填缺漏或找不到對應資料，自動跳過 |

---

## 19c. 畢業論文：批次建立記錄（SQL）

當學生尚未在學生端申請，但行政已有紙本記錄時，可用 SQL 直接建立。

**執行步驟：**
1. 確認所有學生在 `students` 表中存在（查詢學號取得 UUID）
2. 確認所有指導教授在 `teachers` 表中存在（查詢姓名取得 UUID）
3. 執行以下順序的 SQL：

```sql
-- STEP 1：建立 thesis_progress（必要欄位）
INSERT INTO thesis_progress
  (id, student_id, stage, advisor_id, title_zh,
   advisor_approved, advisor_approved_at, advisor_status,
   created_at, updated_at)
VALUES (...);

-- STEP 2：建立 thesis_advisors
INSERT INTO thesis_advisors
  (id, thesis_id, teacher_id, advisor_role, status, approved_at, is_active)
VALUES (...);

-- STEP 3（選）：更新教師證號
UPDATE teachers SET cert_no = '...' WHERE id = '...'
  AND (cert_no IS NULL OR cert_no = '');
```

> 若學生已有 `thesis_progress` 記錄（如已在學生端申請），改用 `UPDATE` 補充資料，不要重複 INSERT。

**新增欄位（v8 加入）：**
```sql
ALTER TABLE teachers
  ADD COLUMN IF NOT EXISTS cert_no VARCHAR(50);
ALTER TABLE thesis_progress
  ADD COLUMN IF NOT EXISTS admin_note TEXT,
  ADD COLUMN IF NOT EXISTS ethics_submitted_at TIMESTAMPTZ;
```

---

進度總覽每列點「📜 歷程」，彈出該生**完整論文歷程**時間軸，整合：
- 指導教授申請／核定／退回（含已退回的歷史記錄）
- 論文題目每次異動（新題目、原因、修改者）
- 申請送出與行政審核（含退回原因、審核人）
- 學倫通過、口試、完成等階段時間戳

四欄位（時間／類型／內容／狀態）皆可排序，預設依時間**新→舊**。

---

## 20a. 操作記錄

**後台 → 左側「系統管理 → 📋 操作記錄」**

記錄所有會影響資料的寫入操作，供稽核與查詢。

### 記錄範圍

| 類別 | 記錄的操作 |
|---|---|
| 課程管理 | 新增、編輯、停用、啟用課程 |
| 開課記錄 | 新增、編輯、取消開課 |
| 教師管理 | 新增、編輯教師 |
| 畢業論文 | 核准/退回指導教授申請、核准/退回論文題目、編輯論文進度 |
| 批次匯入 | 課程主檔、開課記錄批次匯入 |

### 欄位說明

| 欄位 | 說明 |
|---|---|
| 時間 | 操作日期時間 |
| 操作者 | 教師姓名（若無則顯示 email）|
| 類別 | 操作分類 |
| 操作 | 具體動作 |
| 對象 | 操作對象（課程代碼+名稱 / 學生+論文題目）|
| 說明 | 變更詳情，如 `stage→2｜學倫狀態：補件中` |

### 篩選功能
- 類別、操作者下拉
- 日期範圍（起訖）
- 關鍵字搜尋（對象或說明）
- 顯示最近 500 筆，永久保留

---

## 20b. 會議管理

**後台 → 左側「系統管理 → 📅 會議管理」**

### 新增會議
1. 點「＋ 新增會議」
2. 填寫：會議名稱、日期、地點、開始/結束時間、說明（Markdown）
3. **出席名單**：
   - 「＋ 新增人員」→ 選教師/學生（搜尋）或自訂外部人員（姓名、職稱、單位、Email）
   - 「📋 從既有會議複製」→ 選來源會議，自動複製名單（重複者跳過）
4. **通知 Email**：額外通知的 email，逗號分隔（非系統師生用）
5. 點「💾 儲存」

### 各按鈕說明

| 按鈕 | 說明 |
|---|---|
| ✏️ 編輯 | 修改會議資料、出席名單 |
| 📝 記錄 | 開啟 Markdown 會議記錄編輯器 |
| 🖨 簽到 | 列印福智格式簽到表（自動啟動列印）|
| ✅ 完成 | 標記會議已完成 |
| ✕ 取消 | 標記會議已取消 |

### 🖨 簽到表格式
```
福智學校財團法人福智佛教學院
OOO會議 簽到表
日期：115年5月20日（星期三）
時間：上午10時30分～12時00分

序號  姓名    職稱    簽到
1    王福智  教授    ___
```

### 📝 會議記錄 Markdown 編輯器

| 按鈕 | Markdown 語法 |
|---|---|
| H1/H2/H3 | `# 標題` / `## 標題` / `### 標題` |
| B 粗體 | `**文字**` |
| I 斜體 | `*文字*` |
| 清單 | `- 項目` |
| 編號 | `1. 項目` |
| 引用 | `> 文字` |
| 分隔線 | `---` |
| → 縮排 | Tab |

點「👁 預覽」左右並排顯示；點「🖨 列印記錄」輸出標楷體格式。

> **⚠️ 不二犯規則（template literal 危險標籤）**：
> 新增任何列印功能時，template literal 裡的 `</script>`、`</style>`、`</head>`、`</body>`、`</html>` 必須用字串拼接拆開：`</scr'+'ipt>`、`</sty'+'le>` 等，否則瀏覽器會截斷 JS 導致登入失敗。

---

## 20. 帳號管理（v12 新增）

**後台 → 左側「資料管理 → 👥 帳號管理」**

列表顯示所有系統帳號，含 7 欄（全部可排序）：Email、顯示名稱、角色、院內職務、權限、建立日、操作。

### 角色 Badge
| 角色 | 顏色 | 說明 |
|------|------|------|
| admin | 粉紅 | 系統管理者，全部權限 |
| staff | 藍 | 行政人員，依模組設定權限 |
| teacher | 綠 | 教師 |
| student | 橙 | 學生 |
| viewer | 紫 | 唯讀 |

### 編輯帳號
點「✏️ 編輯」開啟 Modal，可設定：
- **顯示名稱**：留空使用關聯姓名
- **角色**：admin / staff / teacher / student / viewer
- **院內職務**（多選）：113/114/115 級導師、所長、教育長、副校長、校長
- **模組權限**（僅 staff 適用）：11 個模組 × 4 級（無/讀/寫/全）

### 預設範本（一鍵套用）
| 範本 | 說明 |
|------|------|
| 👤 admin 預設 | 全部模組「全」權限 |
| 🎓 老師兼行政 | 全部可讀 + 公佈欄/待辦/會議可寫 |
| 👁 主管唯讀 | 全部模組「讀」 |
| 🧑‍💼 從零開始 | 全部「無」，逐項手動勾選 |

> **自我降級保護**：admin 把自己降為非 admin 時會警告。

---

## 20a. 列印功能（v12 新增）

### 學生資料頁列印（2 個按鈕）

**後台 → 🧑‍🎓 學生資料**

| 按鈕 | 格式 | 內容 |
|------|------|------|
| 📋 學生資料列表 | Excel 下載 | 16 欄完整資料（序號/學號/姓名/性別/年級/狀態/Email/電話/地址/緊急聯絡人/關係/緊急電話/廣論班級/住宿/班導師/備註）|
| 📋 班級名條 | Excel 下載 | 序號/學號/姓名 + 4 欄空白（通用簽到表）|

兩者皆依**目前篩選條件**（年級、狀態）匯出。

### 課程點名單

**後台 → 📅 開課記錄 → 每門課「📋 點名」**

1. 點「📋 點名」開啟設定 Modal
2. 選擇**年/月份**
3. 填入課程幹部：小天使、TA、視聽（自動記憶，下次帶入）
4. 勾選「📱 數位課程」（自動查 courses 表的 is_digital）
5. 點「🖨 列印點名單」→ A4 橫印

格式仿照「各科點名單.xlsx」範本：
- **上半部**：課程資訊（編號/名稱/教師/必選修/學分/人數/教室/時間）+ 幹部欄
- **中間**：教授出席記錄（每位教授一列，5 週空白欄）
  - 一般課程：「□實體 □連線」
  - 數位課程：「□實體 連線(□同步 □非同步)」
- **下半部**：學生姓名列（學號+姓名+狀態+5 週空白簽到）
  - 停修/休學/退學學生灰色背景

---

## 20b. 公佈欄功能（v12 更新）

三個 HTML（admin / student / teacher）的公佈欄統一有：
- **收合/展開**：點擊標題列可收合單則公告
- **⊟ 全部收合**：一鍵收合所有展開的公告（只收合不展開）
- **附件**：支援 admin-assets Storage 的 signed URL 安全附件

---

## 20c. 學生資料管理（v12 更新）

**後台 → 左側「資料管理 → 🧑‍🎓 學生資料」**

### 學生列表（12 欄，全部可排序）
📷、學號、姓名、**性別**、年級、狀態、學校 email、電話、**緊急聯絡人（含關係）**、**緊急電話**、**班導師（指導/屆導）**、操作

- 頂部篩選：搜尋框、年級下拉、狀態下拉
- 統計：共 N 人 · 各年級人數 · 顯示 N 人
- 橫向滾動（min-width:1500px）

### 批次匯入
「📥 批次匯入」→ 上傳 Excel → 預覽 → 確認匯入

---

# 第四部　技術維護手冊

## 21. 系統架構

```
┌─────────────────────────────────────────────┐
│            前端（HTML 靜態檔）               │
│  115CoursesManagement_LIVE_v4.html  公開課表 │
│  student.html   學生：選課 + 畢業論文        │
│  teacher.html   教師：課程 + 大綱            │
│  admin.html     行政：後台 + 論文審核        │
│  syllabus.html  課程大綱                     │
└──────────────────┬──────────────────────────┘
                   │ HTTPS API
┌──────────────────▼──────────────────────────┐
│         Supabase（PostgreSQL + Auth）        │
│  URL: https://pjyjpcumakxevxuxwcyx.supabase.co│
│  Region: ap-northeast-1（東京）              │
└─────────────────────────────────────────────┘
```

### 技術棧
| 項目 | 技術 |
|------|------|
| 資料庫 | Supabase（PostgreSQL）|
| 前端 | 純 HTML + CSS + JavaScript（無框架）|
| 身份驗證 | Supabase Auth（Magic Link + 密碼）|
| 權限控制 | Row Level Security（RLS）|
| 本機伺服器 | VS Code Live Server（Port 5500）|
| 資料匯入 | Node.js 腳本 |

### 連線資訊
| 項目 | 值 |
|------|-----|
| Project URL | `https://pjyjpcumakxevxuxwcyx.supabase.co` |
| Publishable (anon) Key | `sb_publishable_Hxw2qfgBO5BTkX4wG4xeTQ_tEsPG3pc` |
| Secret Key | 存於 `.env`（勿公開）|

---

## 22. 登入機制與帳號權限

### 兩種登入方式
| 方式 | 函數 | 用途 |
|------|------|------|
| Magic Link | `signInWithOtp` / `sendLink()` | 正式上線 |
| 密碼登入 | `signInWithPassword` / `passwordLogin()` | 測試用（student.html 已內建）|

兩者並存、走同一套認證系統，登入後權限相同。

### 設定測試帳號密碼
```powershell
node -e "require('dotenv').config(); const { createClient } = require('@supabase/supabase-js'); const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, {auth:{autoRefreshToken:false,persistSession:false}}); sb.auth.admin.listUsers().then(async ({data})=>{ const u = data.users.find(x=>x.email==='leetawu@gmail.com'); if(!u){console.log('找不到');return;} const {error} = await sb.auth.admin.updateUserById(u.id, {password:'test1234'}); console.log(error ? '❌'+error.message : '✅ 密碼已設'); });"
```

### 角色與權限（RLS）
`users` 表的 `role` 欄位決定權限：

| role | 對象 | 權限 |
|------|------|------|
| `student` | 學生 | 只能存取自己的資料 |
| `staff` | 行政同仁 | 依 `permissions` JSONB 欄位逐項授權 |
| `viewer` | 行政主管 | 只能讀取，所有編輯按鈕灰掉 |
| `teacher` | 授課教師 | 自己的課程、成績登錄 |
| `admin` | 最高管理者 | 全部功能 |

**關鍵**：
- 學生首次登入時，`student.html` 的 `enterApp()` 會自動在 `users` 表建立 role=student 的記錄。
- **行政帳號需手動建立** role=admin 的記錄，否則 `current_user_role()` 回傳 null，RLS 會擋掉所有論文資料（症狀：後台「待審核 0」「尚無學生」）。

```sql
-- 行政帳號補 users 記錄（用該帳號的 auth.uid）
INSERT INTO users (id, email, role, student_id)
VALUES ('<auth-user-id>', 'meiyi.wu@bwbc.edu.tw', 'admin', NULL);
```

- 修改 role 後，該帳號**必須登出再重新登入**（JWT 才會更新）。

`current_user_role()` 函數定義：
```sql
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS varchar LANGUAGE sql SECURITY DEFINER AS $$
  SELECT role FROM users WHERE id = auth.uid();
$$;
```

### 角色說明（v11 重構）

`director` 角色已廢除，改用 `institute_roles`（JSONB）記錄職務身份：

| institute_role | 說明 |
|---------------|------|
| `advisor_113` | 113級導師 |
| `advisor_114` | 114級導師 |
| `director` | 所長 |
| `dean` | 教育長 |
| `vice_principal` | 副校長 |
| `principal` | 校長 |

### staff 模組權限

`role=staff` 透過 `users.permissions`（JSONB）控制可存取的模組：

| 模組 key | 說明 |
|---------|------|
| `announcements` | 公佈欄 |
| `todos` | 待辦事務 |
| `meetings` | 會議管理 |
| `courses` | 課程管理 |
| `open_courses` | 開課記錄 |
| `teachers` | 教師管理 |
| `thesis` | 畢業論文 |
| `students` | 學生資料 |
| `semesters` | 學期管理 |
| `surveys` | 意見調查 |
| `logs` | 操作記錄 |

### 帳號建立注意事項

teacher 帳號建立後，`users.teacher_id` 必須對應 `teachers.id`，否則成績登錄無法讀取修課學生。批次補齊 SQL：
```sql
UPDATE users u SET teacher_id = t.id
FROM teachers t
WHERE u.email = t.email AND u.role = 'teacher' AND u.teacher_id IS NULL;
```

---

## 23. 課程相關資料表

| 資料表 | 說明 |
|--------|------|
| `academic_years` | 學年 |
| `semesters` | 學期 |
| `course_axes` | 課程主軸（底蘊/對話/應用）|
| `courses` | 課程主檔 |
| `course_offerings` | 開課記錄（含 is_active、week_pattern）|
| `teachers` | 教師 |
| `offering_teachers` | 課程教師關聯 |
| `classrooms` | 教室 |
| `syllabi` | 課程大綱（含 weeks jsonb）|
| `students` | 學生 |
| `enrollments` | 選課記錄 |
| `enrollment_settings` | 各學期選課開放設定 |
| `graduation_requirements` | 各年級畢業學分要求 |
| `class_advisors` | 班級導師及所內職務歷史記錄（含起迄學期、異動原因）|
| `grade_periods` | 成績登錄期程（學科/操行，含等第表 JSONB）|
| `grade_assignments` | 每學期每門課指定的評分老師 |
| `grade_entries` | 成績主表（含 draft/submitted/confirmed 狀態、解鎖記錄）|

### courses 表 v7 新增欄位
| 欄位 | 說明 |
|------|------|
| `is_digital` | 數位課程 📱（BOOLEAN DEFAULT false）|
| `is_audit` | 開放隨班附讀 🎓（BOOLEAN DEFAULT false）|
| `inactive_reason` | 停用原因（TEXT，停用時必填）|

> 從舊版升級需執行：
> ```sql
> ALTER TABLE courses
>   ADD COLUMN IF NOT EXISTS inactive_reason TEXT,
>   ADD COLUMN IF NOT EXISTS is_digital BOOLEAN DEFAULT false,
>   ADD COLUMN IF NOT EXISTS is_audit BOOLEAN DEFAULT false;
> ```

### ⚠️ is_audit 欄位語意說明（重要）

`courses.is_audit` 是**課程屬性**，代表「這門課是否開放隨班附讀」，與學生的選課身份無關。

| 正確理解 | 錯誤理解 |
|---|---|
| 這門課**開放**隨班附讀 | 學生以隨班附讀身份修這門課 |
| 課程層級的設定 | 學生層級的身份 |

目前系統**不記錄**學生是否以隨班附讀身份修課，`enrollments` 表也沒有此欄位。`is_audit=true` 的課程，學生仍正常選課、正常計算學分，只是課程標記上顯示 🎓 圖示供行政參考。

**畢業進度計算**：所有 `status='confirmed'` 的選課記錄均計入學分，不受 `is_audit` 影響。

### 主要視圖
`v_course_schedule`、`v_offering_teachers`、`v_teacher_schedule`、`v_classroom_schedule`。

### week_pattern
| 值 | 說明 |
|----|------|
| `every` | 每週 |
| `odd` | 單週 |
| `even` | 雙週 |
| `intensive` | 集中課程 |

### courses.active vs course_offerings.is_active
`v_course_schedule` 只過濾 `co.is_active = true`，**不**過濾 `c.active`。歷史課程即使停用，只要當學期有開課就應顯示。

---

## 24. 畢業論文資料表

### thesis_progress（每生一筆，UNIQUE student_id）
| 欄位 | 說明 |
|------|------|
| `stage` | 已完成階段數（0~4）|
| `advisor_id` / `advisor_status` | 指導教授狀態 |
| `research_direction` | 研究方向 |
| `title_zh` / `title_en` / `title_status` | 論文題目 |
| `title_confirmed_at` | 題目確認時間 |
| `ethics_status` / `ethics_case_no` / `ethics_approved_at` | 學倫審查 |
| `defense_date` / `completed_at` / `final_grade` | 口試與完成 |
| `stage_overridden` | 階段是否經行政手動調整 |

### thesis_requirements（各年級論文階段定義）
`stages`（jsonb，預設四階段）、`cohort_from`/`cohort_to`、`thesis_credits`、`ethics_required`。

### thesis_advisors（指導教授，可多筆含歷史）
`thesis_id`、`teacher_id`、`advisor_role`（main/co）、`sort_order`、`status`（申請中/核定中/完成/退回重議）、`is_active`、`note`、`applied_at`、`approved_at`。

> 退回重議時將舊記錄設 `is_active=false` 保留歷史，新申請另開記錄。

### thesis_pending_reviews（待審核佇列）
`thesis_id`、`student_id`、`review_type`（advisor_apply/title_change）、`content`（jsonb）、`status`（pending/approved/rejected）、`note`（退回原因）、`requested_at`、`reviewed_at`、`reviewed_by`。

### thesis_title_history（題目變更歷程）
`thesis_id`、`title_zh`/`title_en`、`reason`、`changed_by`、`changed_at`。

### RLS 原則
- 學生：可 select/insert/update 自己的記錄
- admin/director：ALL（全部）
- `CREATE POLICY` 不支援 `IF NOT EXISTS`，更新政策請先 `DROP POLICY IF EXISTS` 再 `CREATE`

### 補欄位 SQL（若缺）
```sql
ALTER TABLE thesis_progress
ADD COLUMN IF NOT EXISTS ethics_status varchar(20),
ADD COLUMN IF NOT EXISTS ethics_case_no varchar(50),
ADD COLUMN IF NOT EXISTS ethics_approved_at timestamptz,
ADD COLUMN IF NOT EXISTS defense_date date,
ADD COLUMN IF NOT EXISTS completed_at timestamptz,
ADD COLUMN IF NOT EXISTS final_grade varchar(10),
ADD COLUMN IF NOT EXISTS stage_overridden boolean DEFAULT false;

ALTER TABLE thesis_pending_reviews ADD COLUMN IF NOT EXISTS note text;
```

---

## 25. Storage 設定（檔案上傳）

教師照片等檔案存放在 Supabase Storage 的 **bucket（儲存桶）**，不是資料表。資料表只存檔案的網址（如 `teachers.photo_url`），實體檔案存在 bucket。

### 教師照片相關
| 項目 | 值 |
|------|-----|
| Bucket 名稱 | `teacher-assets` |
| 上傳路徑 | `teacher-photos/{教師id}.{副檔名}` |
| 公開性 | Public（照片需公開顯示）|
| 程式位置 | teacher.html 的 `uploadPhoto()` |

### 建立 bucket（首次設定 / 換環境必做）
Supabase Dashboard → Storage → New bucket：
- Name：`teacher-assets`（連字號，需完全一致）
- Public bucket：**開啟**（照片要公開顯示）

> 未建立會出現 **「Bucket not found」**（HTTP 400）。

### 上傳權限政策（RLS）
Public bucket 只開放「讀取」，「上傳／更新」仍需 RLS 政策。在 SQL Editor 執行：

```sql
-- 允許登入者上傳/更新到 teacher-assets
CREATE POLICY "teacher_assets_write" ON storage.objects
FOR ALL TO authenticated
USING (bucket_id = 'teacher-assets')
WITH CHECK (bucket_id = 'teacher-assets');
```

> `CREATE POLICY` 不支援 `IF NOT EXISTS`，重設請先 `DROP POLICY IF EXISTS "teacher_assets_write" ON storage.objects;`。

### 常見錯誤
| 錯誤訊息 | 原因 | 解法 |
|---------|------|------|
| `Bucket not found` | bucket 未建立或名稱不符 | 建立 `teacher-assets`（注意拼字）|
| `new row violates row-level security policy` | 缺上傳政策，或上傳請求未被認證為登入者 | 確認上方政策已建立；確認使用者已正確登入（有有效 session）|
| 照片上傳成功但不顯示 | bucket 非 Public | 將 bucket 設為 Public |

> **權限收緊與 anon**：若政策設 `TO authenticated` 卻仍被擋（violates RLS），但放寬為 `TO anon, authenticated` 後可上傳，表示上傳請求未帶有效登入 token（session 問題）。教師照片屬公開非敏感資料，測試階段可暫用放寬政策；正式上線建議確保登入 session 正常後改回 `authenticated`。檢查政策角色：
> ```sql
> SELECT polname, polroles::regrole[] FROM pg_policy
> WHERE polrelid = 'storage.objects'::regclass AND polname LIKE '%teacher%';
> ```

---

## 26. 資料匯入

### .env 設定
```
SUPABASE_URL=https://pjyjpcumakxevxuxwcyx.supabase.co
SUPABASE_SERVICE_KEY=sb_secret_xxxx
SITE_URL=http://127.0.0.1:5500
```

### 執行
```powershell
cd "D:\A類\Tools\佛應所課程管理\佛應所課程管理v2"
npm install
node check_connection.js          # 測試連線
node import_teachers_v2.js         # 匯入教師
node import_offering_teachers.js   # 課程教師關聯
```

歷史學年（113/114）匯入原則見第 24 節附錄。

---

## 27. 部署與常見問題

### ⚠️ Live Server 注入破壞 JS（重要雷區）
**症狀**：瀏覽器 Console 報 `Uncaught SyntaxError: Unexpected end of input`，導致整個 script 中斷、函數未定義、登入卡死。但 `node --check` 檢查原始檔卻通過。

**原因**：VS Code Live Server 會在頁面的 `</body>` 前注入自動刷新 script。若 JavaScript 的**模板字串（template literal）中含有字面的 `</body>`**（例如列印功能用 `window.open` 寫入 HTML），Live Server 會誤判該處為頁面結尾，把注入碼插進字串中間，破壞語法。

**解法**：把模板字串裡的 `</body></html>` 拆開，例如：

---

### ⚠️ 嚴禁在 template literal 中使用的 HTML 標籤（不二犯規則）

瀏覽器解析 HTML 時，以下標籤**一旦出現就立刻截斷**，不管是否在 JS 字串裡：

| 禁止寫法 | 正確寫法 |
|---|---|
| `\`...\</script>...\`` | `\`...\</scr'+'ipt>...\`` |
| `\`...\</body>\</html>\`` | `\`...\</bo'+'dy>\</ht'+'ml>\`` |

**適用場景**：`window.open` 列印功能、動態產生 HTML 的任何地方。

**記憶口訣**：template literal 裡只要有 `</` 開頭的 HTML 結束標籤，就要用字串拼接拆開。
```javascript
// 錯誤：Live Server 會注入到這裡
w.document.write(`...</body></html>`);
// 正確：拆開讓 Live Server 偵測不到
w.document.write(`...</bo`+`dy></ht`+`ml>`);
```
拼接後字串內容相同，瀏覽器執行正常。

> 此問題**僅在 Live Server 開發環境發生**。正式部署到一般 Web 伺服器不會注入，也不會有此問題。但拆開寫法在正式環境同樣正常，可保留。

### 開發環境注意事項
| 問題 | 解法 |
|------|------|
| 無痕視窗無法保持登入 | Tracking Prevention 擋 session，改用**一般視窗** |
| magic link `otp_expired` | 連結有時效且一次性，產生後**立即**使用；或用密碼登入 |
| email rate limit exceeded | Supabase 寄信有頻率限制，改用 node `generateLink` 繞過 |
| 複製貼上程式碼後 script 中斷 | 聊天視窗複製會混入隱形字元（NBSP/零寬空格）。改用**檔案總管剪下→貼上→取代**整個檔案，勿逐段複製貼上 |
| `127.0.0.1 拒絕連線` | Live Server 未啟動，VS Code 右下角點「Go Live」|
| 改 role 後仍無權限 | 需登出再重新登入（JWT 更新）|

### 一般問題
| Q | A |
|---|---|
| 登入按鈕沒反應 | F12 看 Console；確認 Live Server 在 Port 5500 |
| 資料沒更新 | Ctrl+Shift+R 強制重整 |
| 後台看不到論文資料 | 確認該行政帳號在 users 表有 role=admin，並重新登入（見第 19 節）|
| 匯入報 permission denied | 見第 24 節 GRANT 指令 |
| 衝堂誤報 | 確認 week_pattern 設定正確 |
| 新增課程不顯示 | 確認 course_offerings.is_active = true |

---

## 28. 附錄：SQL 維護指令

### 權限授予
```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
```

### 確認開課狀況
```sql
SELECT s.label, COUNT(*) AS 課程數
FROM course_offerings co
JOIN semesters s ON co.semester_id = s.id
WHERE s.academic_year = 115 AND co.is_active = true
GROUP BY s.label ORDER BY s.label;
```

### 查論文整體狀態
```sql
SELECT s.student_code, s.name_zh, s.cohort,
       tp.stage, tp.advisor_status, tp.title_zh,
       ta.status AS advisor_status_detail, ta.is_active, t.name_zh AS advisor
FROM thesis_progress tp
JOIN students s ON tp.student_id = s.id
LEFT JOIN thesis_advisors ta ON ta.thesis_id = tp.id
LEFT JOIN teachers t ON ta.teacher_id = t.id
ORDER BY s.cohort, s.student_code;
```

### 學期 UUID 對照
| 學期 | UUID |
|------|------|
| 113-1 | e6147c6a-b8fb-4594-92a2-2c7674c3abdc |
| 113-2 | 24a8fbfb-a87d-45e8-9e02-c094c27b5d09 |
| 114-1 | af7a32b0-fc6a-4b5e-80ea-be84b8b6b1ad |
| 114-2 | beae415b-8529-4599-b9b3-e356ccd4a789 |

### 歷史資料匯入標準流程
1. 新增學期（WHERE NOT EXISTS 防重複）
2. 新增課程（明確 active=true）
3. 新增開課記錄（用學期 UUID，is_active=true）
4. 新增授課教師關聯（offering_teachers，勿遺漏）
5. 執行後立即 SELECT 確認

> `courses.active` = 課程是否在目錄中；`course_offerings.is_active` = 該學期是否開課。VIEW 只過濾後者。

---

## 29. RLS 全面修復記錄（2026-06-17）

### 問題
Supabase Dashboard 被登出後，先前部署的 permission 系統可能因 CASCADE 操作導致部分表的 RLS policy 遺失。

### 修復清單
| 表 | Policy 數 | 重要修正 |
|---|----------|---------|
| syllabi | 4 | admin+老師可寫大綱 |
| enrollments | 8 | 學生讀自己+老師讀自己課+admin讀全部（修正無限遞迴） |
| students | 6 | 老師可讀自己課的學生 |
| class_advisors | 4 | 公開讀+admin寫 |
| grade_periods | 4 | 公開讀+admin寫 |
| grade_assignments | 4 | 老師讀自己+admin寫 |
| grade_entries | 4 | 老師讀寫自己+admin管理 |
| attachments | 4 | 公開讀+admin寫 |
| meeting_attendees | 4 | 會議權限控制 |
| meeting_notifications | 4 | 會議權限控制 |
| course_equivalencies | 4 | 公開讀+admin寫 |
| bak_* 備份表 | — | RLS 已關閉（不需保護） |

### 重要教訓：避免無限遞迴
```
❌ students policy 查 enrollments → enrollments policy 查 students → 💥 infinite recursion
✅ enrollments 的學生 policy 改用 users.student_id（不查 students 表）
```

---

## 30. 未完成項目清單（截至 2026-06-17）

### 🔴 高優先（需 Dashboard）
| # | 項目 | 說明 | 依賴 |
|---|------|------|------|
| 1 | students_schema_v1.sql PART 5/6 | Storage bucket 設定（學生大頭照）| SQL |
| 2 | v_course_schedule view 加 is_digital | 數位課程標記目前從 courses 表獨立查詢，應整合到 view | SQL |
| 3 | 休學/停修學生等第不應顯示 | 成績登錄中，休學學生顯示「優秀」等第應隱藏 | teacher.html |

### 🟡 中優先（功能增強）
| # | 項目 | 說明 | 依賴 |
|---|------|------|------|
| 4 | E. 特定名條列印 | 多年級複選+自訂表單名稱+空白欄位 | admin.html |
| 5 | 課程編輯 modal 缺 req_type, credits | 這兩個欄位屬於 courses 主表，目前 modal 沒有 | admin.html |
| 6 | 新增課程 UI | 目前只能從前學期 copy，沒有從零新增的介面 | admin.html |
| 7 | 學期總課表（全學期排課表） | 平行欄位顯示重疊時段 | admin.html |
| 8 | admin 端成績登錄管理 | grade_period 設定、grade_assignments 指派 UI | admin.html |
| 9 | 學生帳號批次建立 Supabase Auth | 目前只建 students 記錄，沒建 Auth 帳號 | admin.html + SQL |
| 10 | 幹部存入 DB | 小天使/TA/視聽 目前用 localStorage 暫存，應存到 course_offerings | SQL + admin.html |

### 🟢 低優先（改善體驗）
| # | 項目 | 說明 | 依賴 |
|---|------|------|------|
| 11 | ~~admin 橫向滾動~~ | ✅ 2026-06-19 已修復，見第 31 節 | admin.html CSS |
| 12 | ~~topbar fixed/sticky~~ | ✅ 2026-06-19 已修復，見第 31 節 | CSS |
| 13 | 指導教授資料匯入 | advisor certificate 欄位（teachers 表）+ approval date（thesis_progress）+ 16 列資料 | SQL |
| 14 | 三個 staff 帳號 pending | 曾美芳、廖袖婷、楊韻蓉 — email 確認中 | Supabase Auth |
| 15 | 自訂 Gmail SMTP | 解決 Supabase 免費 SMTP 4封/小時限制 | Supabase Dashboard |
| 16 | 公告附件編輯/替換 | ✅ 2026-06-19 已完成，見第 31 節 | admin.html |
| 17 | 教師課表匯出 PDF 排版錯誤 | ✅ 2026-06-19 已修復，見第 31 節 | admin.html |

### ⚠️ RLS 注意事項
| 表 | Policy 數 | 備註 |
|---|----------|------|
| users | 2 | 可能需要補強（目前只有 2 條） |
| audit_log | 2 | 可能需要補強 |
| thesis_advisors | 2 | 需確認老師能否讀自己的指導學生 |
| thesis_pending_reviews | 2 | 需確認老師能否讀自己的審核 |
| thesis_requirements | 2 | 學生需要讀取（確認現有 policy 是否夠用）|
| thesis_title_history | 2 | 學生需要讀取 |

### 🛡️ RLS 安全守則
1. **加 policy 前先查現有**：`SELECT policyname FROM pg_policies WHERE tablename='xxx'`
2. **不要用 CASCADE 刪函式**（會連帶刪掉引用的 policy）
3. **避免 policy 間互相查詢造成無限遞迴**（如 students ↔ enrollments）
4. **改完測試所有角色**（admin / teacher / student）
5. **每次部署前做健檢**：`SELECT relname, COUNT(policyname) FROM pg_class LEFT JOIN pg_policies...`

---

## 31. 2026-06-19 修正記錄

### 31.1 教師課表 exportPDF 排版錯誤

**現象：** 教師課表頁面按「匯出 PDF」，列印視窗只顯示一堆 CSS 規則文字和標題，看不到實際課表內容；後續修正圖例後，圖例又變成逐行排列（非橫排）。

**根本原因：** `exportPDF()` 雖把 `<style>` 標籤拆開成 `<sty'+'le>` 避免被誤判截斷，但**整段 CSS 仍寫在同一個多行 template literal 裡**直接傳給 `document.write()`。Live Server／瀏覽器解析含大量 `<style>`、`<head>`、`<body>` 字面文字的長多行字串時容易誤判截斷位置——這正是「不二犯規則」要避免的根因，不只標籤要拆開，**整個 HTML 結構都不該用單一 template literal 包**。第二個問題是圖例相關的 CSS class（`.tt-legend`、`.tt-badge`、`.tt-week-tag`）原本沒有加進列印視窗的樣式表，所以列印出來時圖例失去 flex 排列。

**正確修法：**
```javascript
// ✅ CSS 規則寫成陣列，join('') 組成字串變數（不是 template literal）
const css = [
  "body{font-family:'Noto Sans TC',sans-serif;margin:0;padding:16px}",
  '.tt-legend{display:flex;align-items:center;gap:8px;...}',
  '.tt-badge{display:inline-flex;align-items:center;font-size:9px;...}',
  '.tt-week-tag{font-size:9px;padding:1px 4px;border-radius:3px;...}',
  // ...主畫面用到的所有相關 class 都要對應複製進來
].join('');

// ✅ document.write 全部用字串拼接（+），不用反引號包多行內容
printWin.document.write(
  '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>' + title + '</title>'
  + '<sty'+'le>' + css + '</sty'+'le>'
  + '</he'+'ad><bo'+'dy>' + el.innerHTML + '</bo'+'dy></ht'+'ml>'
);
```

**檢查口訣：** 任何 `window.open` 列印函數，凡是「多行字串」一律改成「陣列 join 或字串相加」，絕不用單一個 template literal 包整段 HTML／CSS 結構。新增列印樣式時，要把主畫面用到的**全部相關 class** 複製過去，不能只複製看得到的主要區塊。

### 31.2 公佈欄附件管理（編輯現有附件、刪除、替換）

**問題：** 編輯公告時無法管理已上傳的附件，只能新增，無法刪除或替換舊檔案。

**解法：**
- `editAnn(id)` 改為 `async`，開啟編輯視窗會查詢並顯示該公告**現有**的附件清單
- 現有附件旁加 🗑 按鈕，**點擊立即生效**（同時刪除 Storage 檔案與 `attachments` 資料表記錄），不必等按「儲存」
- 新增的檔案顯示在「待上傳新檔案」區塊，與現有附件視覺分開，按「儲存」才真正上傳
- 5 個附件上限改為「現有附件數＋待上傳新檔案數」一起計算，避免編輯時超量

**替換檔案的操作方式：** 系統沒有獨立「替換」按鈕，邏輯＝**先刪除舊附件（🗑，立即生效）→ 上傳新檔案 → 按「儲存」**。這樣設計使用者清楚知道每個動作的效果，不會被模糊的「替換」動作搞混。

**相關函數：**
| 函數 | 用途 |
|---|---|
| `editAnn(id)` | 改為 async，查詢並渲染現有附件 |
| `renderAnnExistingAttachments(atts)` | 渲染「目前附件」清單 |
| `deleteAnnAttachment(attId, filePath)` | 立即刪除 Storage 檔案＋資料庫記錄 |
| `handleAnnFiles(files)` | 上限檢查改為「現有附件數＋待上傳數」|
| `renderAnnFileList()` | 渲染「待上傳新檔案」清單 |

### 31.3 admin 三區域獨立捲動（topbar/sidebar/content）

**需求：** 上區（topbar）固定不動；游標在左區（導覽列）滾動時只滾動左區；游標在右區（資料顯示區）滾動時只滾動右區。

**先前嘗試的問題（見第 30 節第 11、12 項）：** 之前多次嘗試用 `position:fixed` 或 `position:sticky` 直接設在 `.topbar`，但因為外層 `.app`／`body` 是 `min-height:100vh`（最小高度，內容多時會撐高），瀏覽器視窗本身仍會出現捲軸，導致 fixed/sticky 的定位基準錨點跟瀏覽器捲動互相打架，內容被遮蔽。

**正確根因與修法：** 問題不是 topbar 的定位方式，而是**外層容器的高度設定錯誤**。`min-height:100vh` 必須改成 `height:100vh` 並加 `overflow:hidden`，才能真正鎖住瀏覽器視窗不捲動，讓內部的 `.layout`（`overflow:hidden`）發揮作用，逼使 `.sidebar` 和 `.content` 各自出現獨立捲軸。

```css
/* ❌ 之前：min-height 會讓外層隨內容撐高，瀏覽器本身捲動 */
body{min-height:100vh}
.app{min-height:100vh}

/* ✅ 修正：height 鎖死視窗高度 + overflow:hidden 完全封閉 */
body{height:100vh;overflow:hidden}
.app{display:none;height:100vh;flex-direction:column;overflow:hidden}

/* .layout 維持 flex:1;overflow:hidden（已存在不需改） */
/* .sidebar / .content 補上 height:100% 確保撐滿 .layout 高度 */
.sidebar{...;overflow-y:auto;height:100%}
.content{...;overflow-y:auto;height:100%}
```

**原理：** 滾輪事件作用在滑鼠游標所在的可滾動元素上，這是瀏覽器原生行為，不需要寫 JS 判斷游標位置。只要外層容器不能捲動（`overflow:hidden` + 固定 `height`），左右兩個內部容器各自的 `overflow-y:auto` 就會自然成為唯一可捲動的區域。

**檢查口訣：** 做「固定頭部、內部分區捲動」這種版面，永遠先確認最外層容器是不是 `height:100vh`（不是 `min-height`），這比直接在 topbar 上加 `fixed`/`sticky` 更根本。

**待辦：** 各分頁內部的 `.page-hdr`（如「畢業論文」「會議管理」的標題列）目前還沒有 sticky 處理，下次若需要「分頁內標題列也固定在 content 頂端」要再評估，避免跟這次的修正互相干擾。

---

*本手冊持續更新。每次系統功能變更時同步更新本文件。*
*系統版本：admin v4.6 / student v2.2 / teacher v2.2　最後更新：2026-06-19*
