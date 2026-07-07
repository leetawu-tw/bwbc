# BWBC 除錯手冊（出問題時照步驟排查，不要從零開始猜）

## 症狀1：「某個功能之前明明有，現在不見了」

**不要做的事**：不要直接假設要重寫這個功能。多數情況下程式碼還在，只是被某次操作蓋掉了，或是這次對話拿到的Project檔案本身就是舊版本。

**標準排查順序（2026-07-04更新，改成GitHub diff優先，比翻commit history快）**：
1. **先確認repo是否可連**：`leetawu-tw/bwbc`是public repo，直接跑：
   ```bash
   curl -s "https://raw.githubusercontent.com/leetawu-tw/bwbc/main/{檔案名}" -o /tmp/gh_latest.html
   diff /mnt/project/{檔案名} /tmp/gh_latest.html
   wc -l /mnt/project/{檔案名} /tmp/gh_latest.html
   ```
   如果diff有大量輸出、行數差異明顯 → **Project裡的檔案是舊版本，問題不是「功能被刪掉」，是「這次對話一開始拿到的基底就缺這段」**。直接改用GitHub版本當基底繼續工作（用`grep -n`定位對應的插入點，把這次要做的修改重新套用上去），不用去猜、不用逐段找程式碼。
2. **如果GitHub上的版本也沒有這個功能**（diff是空的，或GitHub版也缺）→ 才進入下面的對話記錄排查：用`conversation_search`搜尋功能名稱／關鍵表名/關鍵函式名，通常能找到當時完整的開發過程（含中間修正、最終定稿版本），比翻GitHub commit history的訊息更容易看懂脈絡、也更完整（開發對話裡連同「為什麼這樣設計」「後來又修正了什麼bug」都在，commit message通常沒那麼詳細）。
3. 如果對話記錄也找不到，才去 GitHub repo 看 commit history（`https://github.com/leetawu-tw/bwbc/commits/main/{檔案名}`），用 `Ctrl+F` 找有沒有 `remove`、`revert`、`restore`、`clean base` 之類字樣的 commit。
4. 找到含該功能的正確版本後，抽取對應的 HTML/CSS/JS 區塊，移植進**目前最新版本**裡（套用目前的視覺風格與架構），不要整份檔案直接覆蓋蓋過去，否則會連帶失去後來做的其他功能。

**真實案例**：2026-07-04發現`admin.html`缺「課程幹部指派」，一開始用對話記錄排查法（步驟2）成功復原，但後來擴大檢查才發現Project版`admin.html`其實整整缺了6000多行（班級導師/操行/成績/兼課鐘點費/獎學金推薦五大模組），用GitHub diff一次抓出完整落差，比逐個功能翻對話記錄快十倍以上。**這證明步驟1（GitHub diff）該放在最前面**，不要先跳去對話記錄排查——如果一開始就先diff，會直接看到整份檔案缺了什麼，不會像那次一樣「先找到一個功能缺失，修好之後才發現還有更多」。

## 症狀2：上傳/儲存出現 403 或 RLS 相關錯誤

**標準排查順序**：
1. Supabase Dashboard → Storage，確認目標 bucket 是否存在（名稱要完全一致，大小寫敏感）。
2. 確認 bucket 的 Public/Private 設定是否符合預期。
3. 即使是 Public bucket，去 SQL Editor 確認有沒有對應的 INSERT/UPDATE policy（規則見 `conventions.md` 第9條）：
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'objects';
   ```
4. 確認使用者端 session 是否有效（F12 → Console，看有沒有 401 Unauthorized）。
5. 錯誤訊息本身通常已經講得很清楚（`Bucket not found` / `row-level security` / `403`），先看清楚錯誤文字再排查，不要跳過直接猜。

## 症狀3：Live Server 環境下出現怪異 JS 語法錯誤，但檔案本身語法檢查過關

**症狀特徵**：錯誤通常是 `Unexpected end of input`、`SyntaxError`，且只在瀏覽器透過 Live Server (127.0.0.1) 開啟時發生，直接用 `node --check` 檢查原始檔案卻沒有問題。

**處理方式**：
1. 直接懷疑是某個列印/匯出函式的模板字串裡含有未拆開的 `</body>`、`</html>` 或 `</script>`。
2. Grep 全檔案搜尋這幾個標籤的完整出現位置：
   ```bash
   grep -n "</body>\|</html>\|</script>" 檔案.html
   ```
3. 確認每一處是真正的頁面結尾（只會有一個），還是藏在 JS 模板字串裡（這些都要拆開，見 `conventions.md` 第1條）。

## 症狀4：測試帳號登入卡關（magic link 過期、email rate limit）

**不要做的事**：不要一直重複嘗試重寄 magic link，Supabase 預設 email 發送頻率限制很低（通常 2次/小時），很快就會卡住。

**處理方式（改用密碼登入，不影響正式環境的 magic link）**：
1. 確認測試帳號已存在於 `auth.users`（沒有的話先在 Supabase Dashboard → Authentication → Users 手動建立）。
2. 用 Service Role Key 跑一行指令幫帳號設密碼（不需要透過 email）：
   ```javascript
   // node 腳本，需要 SUPABASE_URL 和 SUPABASE_SERVICE_KEY 環境變數
   const { createClient } = require('@supabase/supabase-js');
   const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY,
     { auth: { autoRefreshToken: false, persistSession: false } });
   const { data } = await sb.auth.admin.listUsers();
   const u = data.users.find(x => x.email === '測試帳號email');
   await sb.auth.admin.updateUserById(u.id, { password: 'test1234' });
   ```
3. 如果該頁面（student.html/teacher.html/admin.html）還沒有密碼登入欄位，加一個（測試用，跟 magic link 並存，正式環境不受影響）。
4. 密碼登入走的是同一套 Supabase Auth session，登入後的權限、RLS 行為跟 magic link 登入完全一致，不會有差異。

## 症狀5：資料庫某一筆資料跟畫面顯示對不上（通常是舊測試資料殘留）

**不要做的事**：不要直接憑印象刪除，先查清楚再動手。

**標準排查順序**：
1. 寫 SQL 先 `SELECT` 出確切的那一筆（含關聯表的外鍵，例如透過學號查到對應的 student_id，再用 student_id 查關聯記錄），跟使用者核對內容無誤（姓名、課程、分數等）。
2. 確認這筆資料有沒有被其他表引用（外鍵依賴），避免刪除後產生孤兒資料。
3. 拿到確切的 id 之後，用 `DELETE FROM 表 WHERE id = '確切的id'` 精準刪除，不要用條件範圍模糊比對（避免刪錯範圍）。
4. 刪除後重新整理畫面驗證。

## 症狀6：畫面捲動時固定表頭（sticky thead）沒有生效

**標準排查順序**：
1. 檢查外層容器是否同時有 `max-height`（明確數值）+ `overflow:auto`，不能只有 `overflow-x:auto`（見 `conventions.md` 第3條）。
2. 確認 `<th>` 本身（不是只有 `<tr>`）有 `position:sticky; top:0;` 並且**自己也設了背景色**（不是只靠繼承），否則捲動時下面的內容會透出來。
3. 確認沒有更外層的祖先元素也設了 `overflow` 非 `visible`，搶走了 sticky 的定位基準（sticky 是相對「最近的有 overflow 設定的祖先」定位，如果中間有別的容器搶先設了 overflow，會在錯誤的地方生效）。

## 症狀7：新建立的帳號密碼登入失敗（舊帳號正常）

**症狀特徵**：帳號在 `auth.users` 裡確認存在、密碼欄位有值、`email_confirmed_at` 也有值，但登入就是失敗。F12 Console 通常會看到 `POST .../token?grant_type=password` 回應碼是 **400 還是 500**，這個區別是判斷方向的關鍵：

- **回 400**：單純密碼或帳號問題，先確認密碼是不是打對。
- **回 500（Internal Server Error）**：幾乎可以肯定是帳號是用 SQL 直接 INSERT 進 `auth.users` 建立的，不是走官方 API，照下面排查。

**標準排查順序**：
1. 確認帳號是否缺 `auth.identities` 記錄：
   ```sql
   SELECT au.id, au.email, ai.provider
   FROM auth.users au
   LEFT JOIN auth.identities ai ON ai.user_id = au.id
   WHERE au.email = '有問題的帳號email';
   ```
   如果 `provider` 是空的，代表缺這張表，照 `conventions.md` 第12條規則補上。
2. 確認幾個 token 欄位是不是 `NULL`（不是空字串）：
   ```sql
   SELECT confirmation_token, recovery_token, email_change_token_new, email_change
   FROM auth.users WHERE email = '有問題的帳號email';
   ```
   任何一個顯示 `null`，照 `conventions.md` 第12條規則的 UPDATE 補成空字串。
3. 兩項都修完，請使用者實際試登入一次驗證，不要只憑 SQL 查詢結果就判斷完成——密碼登入涉及 Supabase 內部驗證邏輯，SQL 層看起來對不代表登入一定會成功。

**這個問題只會發生在**：用 SQL 批次匯入帳密的場景（例如開學前一次性建立大量學生/老師帳號），透過正常的「新增使用者」介面或 Supabase Dashboard 手動建立的帳號不會有這個問題。

## 症狀8：重新上傳Storage檔案後，前端抓到的還是舊內容（無任何錯誤訊息）

**症狀特徵**：修改了某個檔案（如Word範本）的內容，重新上傳到Supabase Storage覆蓋同名檔案，但前端產生/讀取出來的結果還是反映舊版內容，**完全沒有任何錯誤訊息或例外**，畫面上看起來一切正常執行完畢。

**容易誤判的方向（這次踩過、繞了遠路）**：
- ❌ 以為是程式碼裡有重複/孤兒的函式定義 → 比對前後版本程式碼完全一致，排除
- ❌ 以為是檔案本身內容有問題（如標記被拆碎） → 直接拆開檔案XML逐字核對，確認檔案完全正常，排除
- ❌ 以為是JS記憶體變數快取 → 移除快取機制後問題依然存在，排除

**真正根因**：Supabase Storage 的 CDN 快取，跟以上三者都無關。

**標準排查順序**：
1. 先用 `console.log` 直接印出「程式實際抓到手的內容」（例如 `xml.includes('關鍵標記')`），不要憑猜測——這次就是加了這一行才10秒鐘確定問題
2. 確認是CDN快取後，照 `conventions.md` 第14條規則，改用 signed URL + `cache:'no-store'` + 時間戳記繞開快取
3. 套用修正後，務必請使用者實際重新測試一次（不需要無痕視窗，一般重新整理即可，因為問題在CDN/網路層，不是瀏覽器分頁的session/cookie層）

**判斷口訣**：「邏輯對、檔案對，結果還是舊的」= 九成是 Storage CDN 快取，直接加 console.log 驗證，不要靠猜測排查。

## 症狀9：bug 怎麼修都修不好、或畫面出現程式碼裡根本搜不到的內容——本機檔案不是最新版

**這是整個專案開發過程中發生頻率最高的一類問題**，已經發生超過5次（admin登入`sendMagicLink`、教師管理role欄位、照片上傳、`saveProfile`、兼課鐘點費`[[本學期]]`等），值得列在最前面優先排查。

**症狀特徵**：
- 回報的bug/錯誤訊息，跟目前實際程式碼內容完全對不上（例如使用者說看到`[[本學期]]`這個字串，但全專案搜尋找不到這段文字）
- 同一個bug回報了好幾次，每次都「修好」但下次又「壞了」
- 畫面上某個欄位的位置/內容跟程式碼描述的不一致

**根本原因**：使用者測試時用的本機檔案，跟最後一次拿到的修正版檔案不是同一份——可能是download資料夾跟專案資料夾各有一份互相搞混、瀏覽器分頁開著舊版沒重新整理、或中間手動編輯過本機檔案做測試（如改`type`參數）後忘記改回來。

**標準排查順序**：
1. **先不要假設是程式碼邏輯有新bug**，直接請使用者在本機檔案搜尋一段「這次新增、確定不會出現在舊版」的特定文字（如新函式名稱），確認搜得到/搜不到
2. 如果搜不到 → 確認版本不同步，請使用者重新下載最新檔案完整覆蓋本機，**不要急著去改程式碼**
3. 如果搜得到但結果還是不對 → 才是真正的程式碼bug，繼續往下排查

**預防建議**：每次給使用者重大修改的檔案，可以附帶一句「請在VS Code搜尋`某個這次新增的關鍵字`確認真的換成新版」，降低使用者漏看版本不同步的機率。

## 症狀11：功能只在「先去過某個頁面」之後才正常，沒去過就出錯或給錯結果

**真實案例**：公告到期日選「至本學期為止」，如果使用者是直接開「新增公告」、沒有先點過「學期管理」頁面，算出來的到期日是錯的（fallback成6個月後，不是真正的學期結束日）。原因是這個功能讀的是一個全域快取變數（`SEMESTERS_ALL`），這個變數只有「學期管理」頁面的載入函式會去填，其他頁面的功能如果依賴這個快取，在快取還是空陣列`[]`的情況下就會用到fallback值或直接出錯，且**通常不會有任何錯誤訊息**，看起來像是「隨機性的bug」（因為使用者的操作順序每次不一定一樣，有時候剛好先去過那個頁面所以正常，有時候沒有）。

**根本原因**：用「某個頁面自己維護的全域快取陣列」當資料來源，而不是每次都重新查詢，省了API呼叫但犧牲了正確性保證。

**檢查方式**：任何函式如果讀取一個以`_`開頭或看起來像頁面專屬快取的陣列變數（如`SEMESTERS_ALL`、`_gradeSemesters`、`_conductSemesters`），先確認呼叫這個函式時，那個變數**保證**已經被填過，不能只假設「使用者應該會照順序操作」。

**正確做法**：改成呼叫共用的日期判斷函式（`getCurrentSemesterByDate()`，內部自己查詢，不依賴外部先填好的快取），不要依賴其他頁面是否已經被造訪過。

## 症狀12：is_current 這個欄位在同一份檔案裡被多處拿來當「預設學期」用，改一處不夠，要全面搜一次

**真實案例**：2026-07-04 統一「現在學期」判斷邏輯那次，一開始只發現時程提醒卡片跟儀表板用了`is_current`，修完之後才陸續發現操行成績管理、成績登錄、空白課程大綱列印、獎學金推薦新增期間，總共**6個不同的地方**都各自獨立寫了`.find(s=>s.is_current)`這段邏輯決定預設學期，是同一個anti-pattern被複製貼上了很多次。

**標準排查方式**：發現一處`is_current`被誤用當「預設學期」判斷後，**不要只修那一處**，全檔案搜一次：
```bash
grep -n "is_current" admin.html
```
逐一檢查每個出現點的語境——如果是`semesters.is_current`（決定排課可編輯範圍，正確用法，不要動）或`class_advisors.is_current`（決定導師是否現任，跟學期判斷完全無關，不要動）就跳過；如果是拿`semesters.is_current`去猜「現在是哪個學期」當某個功能的預設值，一律換成`getCurrentSemesterByDate()`。
