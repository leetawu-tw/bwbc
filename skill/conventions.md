# BWBC 開發規範（寫程式碼前要主動遵守的規則）

每一條都附「根本原因／證據」，方便理解為什麼要這樣做，不是憑空規定。

## 1. 列印/匯出模板字串禁止完整 closing tag

**規則**：任何用 `window.open()` + `w.document.write()` 產生列印頁面的函式，模板字串裡如果含有 `</body>`、`</html>`、`</script>`，必須拆開寫成字串接續形式：

```javascript
// ❌ 不要這樣
w.document.write(`...內容...</body></html>`);

// ✅ 要這樣
w.document.write(`...內容...</bo'+'dy></ht'+'ml>`);
```

CSS 在列印模板裡也適用同樣規則（`<sty'+'le>`）。

**根本原因**：VS Code Live Server 會偵測頁面裡第一個出現的 `</body>`，在它前面注入自動刷新（reload）的 script。如果這個標籤其實是藏在 JS 模板字串裡（不是真正的頁面結尾），Live Server 會把注入程式碼插進模板字串中間，直接截斷 JavaScript，造成 `Unexpected end of input` 之類的語法錯誤——而且 `node --check` 檢查原始檔案時看不出問題，因為錯誤是 Live Server 注入後才發生的。

## 2. 三區獨立滾動佈局的正確寫法

**規則**：
```css
.topbar  { position: fixed; top:0; left:0; right:0; }
.sidebar { overflow-y: auto; /* 自己捲動 */ }
.content { overflow-y: auto; /* 自己捲動 */ }
```
topbar 固定，sidebar 跟 content 各自獨立捲動。**不要**對一個本身會被父層捲動帶著移動的容器套 `position:sticky` 來模擬固定效果——這樣做不會生效，且很難排查為什麼沒生效。

**根本原因**：這個架構曾經被反覆嘗試又 revert 超過 7 次（同一天內），原因是每次都用 sticky/fixed 的局部修補去解，而不是從版面結構整體設計。

## 3. CSS overflow 單軸設定的隱藏規則

**規則**：如果要讓表格表頭固定（sticky thead），外層容器必須同時滿足：
```css
.wrap { max-height: 一個明確的數值; overflow: auto; }
```
不能只寫 `overflow-x: auto` 然後期待 `overflow-y` 維持 `visible`。

**根本原因**：CSS 規格規定，當 `overflow-x` 和 `overflow-y` 只設定一個非 `visible` 的值時，瀏覽器會強制把另一軸也變成 `auto`（即使你明寫 `visible` 也會被蓋掉）。這個容器如果沒有明確高度限制，永遠不會真正產生捲動，sticky 元素就會跟著父層一起被捲走，看起來像「沒有生效」。

## 4. delete-then-reinsert 模式的防呆

**規則**：任何「先刪除某個關聯的全部記錄，再重新整批寫入」的儲存邏輯（例如課程教師、會議出席名單），存檔前必須加防呆：

```javascript
if (原本資料庫裡有記錄 && 現在要寫入的陣列是空的) {
  if (!confirm('⚠️ 這會清空原本的關聯記錄，確定嗎？')) return;
}
```

**根本原因**：如果畫面上的陣列因為非同步載入沒跑完、或邏輯錯誤而是空的，使用者按下儲存時，這個模式會把資料庫裡原本的記錄全部刪光，且不會寫回任何東西，使用者完全不會發現，直到下次要用才發現資料消失。已造成至少一次整學期的課程教師關聯資料遺失。

## 5. 新增 HTML 元素前先確認 CSS class 已存在

**規則**：寫 `class="xxx"` 之前，先在同一份檔案的 `<style>` 區塊 grep 確認 `xxx` 有沒有被定義過。優先沿用既有命名（`tbl-wrap`、`btn-pri`、`btn-sec`、`btn-sm`、`badge`、`badge-ok`、`badge-warn`、`finput`、`fselect`、`frow`、`frow-2`、`flabel`），不要自己取一個聽起來合理但其實沒人定義過的名字（如 `data-table`、`table-wrap`、`btn-secondary`）。

**根本原因**：CSS class 名稱打錯/沒定義，瀏覽器不會報錯，只會悄悄套用預設樣式，畫面看起來「壞掉」但沒有任何錯誤訊息可以追，很容易被誤判成「設計風格問題」而不是「程式漏接」。同樣道理也適用於 `onclick="someFunction()"`——呼叫前先確認這個函式真的存在，不要假設它應該存在。

## 6. 權限欄位格式變更的標準流程

**規則**：任何時候要新增/修改 `permissions` JSONB 欄位的 key，必須依序做：
1. 更新前端常數定義（`PERM_KEYS`、`PERM_LABELS`、`PERM_PRESETS`）
2. 寫一次性 migration SQL，把資料庫裡舊格式/缺 key 的記錄一次補齊或轉換
3. 跑驗證查詢，確認沒有殘留的孤兒格式

**根本原因**：曾經發生過布林值跟四級字串混用、key 名稱對不上（如 `audit` vs `logs`）同時存在的情況，導致前端讀取時某些權限直接讀不到、顯示成空白，使用者以為自己沒設定，但其實是 key 名稱對不上。

## 7. Magic Link 重新導向設定

**規則**：
```javascript
emailRedirectTo: window.location.origin + window.location.pathname
```
不要用 `window.location.href`。

**根本原因**：`href` 包含 URL hash（`#...`），會讓 Supabase 的重新導向邏輯出錯，使用者點信箱裡的連結後可能卡在登入畫面或被導到錯誤位置。

## 8. Git 偵測不到變更時的標準做法

**規則**：如果 Git 明顯看不出檔案有差異（`git status` 顯示沒有變更，但你確定改過），在檔案最開頭加一行版本註解：
```html
<!-- BWBC Admin v4.0 2026-06-08 -->
```
每次有實質修改就更新這行的版本號和日期。

**根本原因**：Windows 環境下 CRLF 換行符跟 Git 預期的 LF 不一致，有時會讓 Git 的 diff 演算法誤判「內容沒變」，導致修改後 commit 不會真的包含新內容。

## 9. 新建 Storage Bucket 的標準三步驟

**規則**：
1. Supabase Dashboard → Storage → New bucket（依用途決定 Public 開關：公開顯示用 Public，機密檔案用 Private）
2. 即使是 Public bucket，**仍要額外開 RLS policy 給寫入動作**：
   ```sql
   CREATE POLICY "xxx upload" ON storage.objects
   FOR INSERT TO authenticated
   WITH CHECK (bucket_id = '你的bucket名稱');
   ```
3. 如果程式用 `upsert:true` 覆蓋檔案，要額外加 UPDATE policy。

**根本原因**：「Public bucket」這個設定**只開放讀取**，上傳/更新/刪除預設仍然被 RLS 擋住。這個認知落差導致教師照片上傳、公告附件上傳都重複卡住過，錯誤訊息（`new row violates row-level security` 或 `403`）其實已經講得很清楚，但容易被忽略去查別的方向。

## 10. 新增/刪除功能後要清查殘留引用

**規則**：刪除一個資料庫 view、table 或前端函式之前（或之後），全專案 grep 一次這個名稱，確認沒有其他地方還在引用它。

**根本原因**：曾經發生過前端程式碼呼叫 `v_student_advisors` 這個 view，但這個 view 從來沒有真正被建立過——可能是規劃階段就寫好呼叫程式碼，後來那個功能被拿掉但呼叫沒清掉，執行到那一行時會報錯或安靜失敗，導致畫面對應欄位永遠空白。

## 11. 角色/權限預設值選保守安全的方向

**規則**：任何「預設值」的設計，優先選「萬一設錯了，後果是權限太多而不是功能被誤鎖」的方向。例如帳號角色辨識失敗時的 fallback，要設成權限較高的角色，而不是權限較低的角色。

**根本原因**：曾經把預設角色設成 `staff`，結果某些帳號因為辨識邏輯沒命中，被意外限制了功能，使用者一時抓不出原因。改成預設 `admin` 之後，最壞情況只是某人多了不該有的權限（可以事後修正），不會卡住正常使用。

## 12. SQL 直接寫入 auth.users 建立帳號的標準流程

**規則**：絕對不要只 `INSERT INTO auth.users` 就以為帳號建好了。SQL 直接寫入帳號表，必須同時處理兩件事，否則帳號「看起來存在」但密碼登入會失敗：

**① 同步建立 `auth.identities` 記錄**：
```sql
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at, last_sign_in_at)
SELECT
  gen_random_uuid(), au.id, au.id::text, 'email',
  jsonb_build_object('sub', au.id::text, 'email', au.email,
    'email_verified', (au.email_confirmed_at IS NOT NULL), 'phone_verified', false),
  au.created_at, au.created_at, au.created_at
FROM auth.users au
LEFT JOIN auth.identities ai ON ai.user_id = au.id
WHERE ai.user_id IS NULL;
```

**② 確認幾個 token 欄位是空字串 `''`，不是 `NULL`**：
```sql
UPDATE auth.users
SET confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    phone_change_token = COALESCE(phone_change_token, ''),
    reauthentication_token = COALESCE(reauthentication_token, '')
WHERE confirmation_token IS NULL OR recovery_token IS NULL
   OR email_change_token_new IS NULL OR email_change IS NULL
   OR email_change_token_current IS NULL OR phone_change_token IS NULL
   OR reauthentication_token IS NULL;
```

**根本原因**：
- 缺 `auth.identities`：Supabase 的 email/password 登入機制需要 `auth.users` 跟 `auth.identities` 同時有對應記錄，只用官方 API（`signUp()`、`auth.admin.createUser()`）建立帳號時這兩張表會自動同步寫好；**只有跳過官方 API、直接 SQL INSERT 才會漏掉**這張表，造成密碼登入失敗，但帳號在畫面上看起來完全正常（email、密碼欄位都有值）。
- Token 欄位是 NULL：Supabase 登入伺服器（GoTrue，Go 語言寫的）讀這幾個欄位用的是不可為空的 `string` 型別，遇到資料庫 `NULL` 會直接讓底層轉型出錯，回傳 **500**（不是密碼錯的400）。同樣只有 SQL 直接 INSERT 才會中，因為沒明確給值就會是 NULL；官方 API 建立帳號時內部都會自動填空字串。

**判斷口訣**：登入失敗回 400 → 密碼或帳號本身的問題；回 **500** → 先懷疑是 SQL 直接寫入帳號造成的資料格式問題，照上面兩步檢查。

## 13. SQL 批次建立帳號後的驗證 SOP
每次用 SQL 批次建立帳號後，固定跑這兩條確認沒有遺漏：
```sql
-- 確認沒有缺 identities 的帳號
SELECT COUNT(*) FROM auth.users au
LEFT JOIN auth.identities ai ON ai.user_id = au.id WHERE ai.user_id IS NULL;

-- 確認沒有 NULL token 欄位
SELECT COUNT(*) FROM auth.users
WHERE confirmation_token IS NULL OR recovery_token IS NULL
   OR email_change_token_new IS NULL OR email_change IS NULL
   OR email_change_token_current IS NULL OR phone_change_token IS NULL
   OR reauthentication_token IS NULL;
```
兩條都要回傳 0 才算過關，不要只憑「畫面上帳號看起來有資料」就判斷成功。

## 14. Supabase Storage 抓取「會被覆蓋更新」的檔案，一定要繞開CDN快取

**規則**：如果某個 Storage bucket 裡的檔案是「會員/admin之後還會重新上傳覆蓋更新」的類型（例如範本檔案、設定檔），前端抓取時**絕對不能只用 `sb.storage.from(bucket).download(path)` 預設方式**，必須改成：

```javascript
const { data: signed } = await sb.storage.from(bucket).createSignedUrl(path, 60);
const bustUrl = signed.signedUrl + (signed.signedUrl.includes('?') ? '&' : '?') + '_t=' + Date.now();
const res = await fetch(bustUrl, { cache: 'no-store' });
const buf = await res.arrayBuffer();
```

**根本原因**：Supabase Storage 背後是接CDN的，直接用 `.download()` 打的是一個固定不變的網址（同一個bucket+路徑每次都是同一個URL），瀏覽器/CDN很容易把這個請求的回應快取住。如果檔案內容更新了（重新上傳覆蓋同名檔案），使用者端抓到的可能還是**舊版內容**，而且**不會有任何錯誤訊息**——程式邏輯完全正確、檔案也確實更新了，但抓到手的就是舊的，非常難排查（這次花了大量來回排查時間，一度誤判成「程式碼重複定義」「範本檔案本身有問題」，最後才確認是這個）。

**判斷口訣**：如果「程式邏輯檢查沒問題、範本/設定檔案內容本身也確認沒問題，但結果還是反映舊內容」，**先懷疑 Storage CDN 快取**，不要往別的方向繞遠路。

**不受影響的情況**：如果檔案是「上傳後就不會再變動」的類型（如使用者大頭照、附件，每次都是新檔名或新路徑），不會踩到這個問題，不需要套用這個寫法，避免過度設計。

## 15. 新增「資料表的人員角色」時，務必同步檢查RLS有沒有認識這種新關係

**規則**：每次新增一種「誰能看到誰的資料」的新關係（如「導師可以看自己帶的學生」「所長可以看全部學生」「TA可以看自己帶的課程的選課學生」），都要去檢查相關表（如`students`、`enrollments`）現有的RLS policy清單，**不要假設舊policy會自動涵蓋新關係**。

**根本原因**：RLS policy是針對「已知的關係」寫的（如本系統最早只有「老師能看自己開課班的修課學生」這條），新增的角色關係（導師、所長、TA）完全是陌生身份，會被舊policy擋下來，但因為**其他不受RLS管控的欄位（如直接讀取的成績數字）依然正常顯示**，會造成「部分欄位有值、部分欄位空白」這種詭異的半成功現象，比起整頁全部失敗更難第一時間聯想到是權限問題。

**判斷口訣**：畫面上「有些欄位正常、有些欄位（尤其是join出來的關聯資料如姓名）空白」，且沒有任何錯誤訊息，先查 `pg_policies` 確認新角色有沒有被涵蓋：
```sql
SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = '你懷疑的表';
```

## 16. 修改既有表的enum-like欄位（如role）前，先查真正的CHECK constraint，不要憑空設計選項

**規則**：要在UI加一個下拉選單對應資料庫某個「看起來像分類」的欄位（如 `role`/`status`/`type`）之前，先查清楚資料庫實際允許哪些值，不要自己設計一套看起來合理的選項：
```sql
SELECT con.conname, pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = '你的表名' AND con.contype = 'c';
```

**根本原因**：自己設計的選項（如「正導師/副導師」）很可能跟資料庫實際的CHECK constraint（如只允許`advisor`/`director`/`dean`等）完全不符，存檔時才會報 `violates check constraint` 錯誤——而且這種表常常承載比表面名稱看起來更廣的用途（如`class_advisors`同時也記錄所長/教育長等職務歷史），不能只看表名跟需求就推測欄位的允許範圍。

## 17. 「已存在的記錄不覆蓋」這種防呆邏輯，要意識到依賴資料變動後會產生孤兒快照

**規則**：任何「批次建立記錄時，已存在的不重複建立/不覆蓋」的邏輯（如操行成績的「產生本學期名單」），如果記錄裡有某個欄位是**從別的表算出來、存成快照**的（如`advisor_id`從`v_student_advisors`算出），要清楚意識到：**如果來源資料在快照之後才異動，舊記錄的快照值不會自動跟著更新**。

**根本原因**：這類設計的本意是保護「已經有人填過的資料不被誤蓋掉」，但如果使用者操作順序是「先建立批次記錄、後來才補上游資料（如導師指派）」，會產生一批「快照值是舊的/空的」的孤兒記錄，且系統不會主動提示，需要事後手動寫SQL補：
```sql
UPDATE 子表 t SET 快照欄位 = 來源.正確值
FROM 來源表 來源
WHERE t.關聯鍵 = 來源.關聯鍵 AND t.快照欄位 IS NULL;
```
**設計時可以考慮**：如果這類「先建立、後補上游資料」的操作順序很常見，可以額外提供一個「重新整理快照值（不影響使用者已填的其他欄位）」的按鈕，不要只靠admin自己想到要寫SQL補。

## 27. admin.html/teacher.html/student.html三個portal如果做同一件事（例如「依日期判斷現在學期」），要用同名函式，不要各自重複寫一份邏輯

**規則**：這三個檔案是各自獨立的HTML檔案，沒有共用的JS模組機制，所以「同一個邏輯在三個檔案分別實作」是常態，沒辦法完全避免。但**至少函式名稱要一致**，不要出現「同一件事，這個portal叫`getCurrentSemesterByDate()`，另一個portal卻是寫成一段inline邏輯、算完存進全域變數，完全沒有獨立函式」這種不一致——這種不一致會導致：
1. 幫某個portal新增功能時，很自然會假設「其他portal有的共用函式，這裡應該也有」，直接照抄呼叫，結果因為函式根本不存在而整個功能壞掉（真實案例見下）
2. 就算邏輯上是對的，兩份各自維護的程式碼未來很容易在修bug時只改一邊、忘記改另一邊，造成三個portal對「現在學期」的認定不一致

**真實案例**：2026-07-16，幫`student.html`做「TA申請」功能時，直接呼叫了`getCurrentSemesterByDate()`——因為這個函式在`admin.html`/`teacher.html`裡本來就有、用得很順手，下意識以為`student.html`也會有。結果`student.html`原本是把同樣的邏輯直接寫在登入流程（`enterApp`）裡，算一次存進全域變數`ACTIVE_SEM_ID`，根本沒有獨立成函式，導致「TA申請」頁面直接報錯`getCurrentSemesterByDate is not defined`。

**處理方式**：發現這種不一致時，不是只在student.html裡改成呼叫「一個假裝存在的函式」，而是**把原本inline的邏輯抽成獨立函式，函式名稱、參數、回傳格式都跟其他portal對齊**，登入流程改成呼叫這個新函式（不再自己重複寫一份），這樣以後其他新功能也能直接呼叫，不會再犯同樣的錯。

**檢查方式**：幫任何一個portal寫新功能，只要用到「現在學期」「現在使用者」這類跨portal共通的概念，**先確認三個檔案裡函式名稱是不是一致**，不要假設「其他portal有、這裡應該也有」，也不要假設「這裡有、其他portal應該也有」——直接搜尋確認。

**特別注意**：不是每個「看起來像的東西」都該統一。`student.html`額外有一個`CURRENT_SEM_ID`（選課學期，看`enrollment_settings`的選課開放時段），這是admin/teacher.html沒有、也不需要的概念，因為只有學生需要同時知道「現在修哪學期的課」跟「現在能選哪學期的課」這兩件不同的事。統一之前要先判斷：這是「同一件事、兩種寫法」（該統一），還是「表面像、其實是不同概念」（不該硬統一）。

## 28. 任何「上傳檔案」或「顯示已上傳檔案」的功能，一律要主動附上「👁 線上看」，不用使用者提醒

**規則**：只要功能涉及PDF/Word/PPT/Excel這類檔案的上傳或顯示（不限於哪個角色、哪個頁面），一律要包含：
1. **線上看**：PDF用瀏覽器原生`<iframe>`嵌入，Word/PPT/Excel用微軟線上檢視器（`https://view.officeapps.live.com/op/embed.aspx?src={encodeURIComponent(url)}`）
2. **排版位置**：獨立的圓角膠囊按鈕「👁 線上看」放在檔名前面，跟公佈欄一致：`[👁 線上看] [📎 檔名 (大小)]`，不要做成小圖示塞在檔名同一行最右邊
3. 判斷副檔名決定要不要顯示線上看按鈕（只有`pdf`/`doc`/`docx`/`ppt`/`pptx`/`xls`/`xlsx`才需要）
4. 如果檔案存在private bucket（用signed URL），線上看按鈕的onclick要**點擊當下即時產生新的signed URL**，不要用列表載入時就先產生好、可能已經過期的舊URL
5. `openViewer(encodedUrl, ext, fileName)`這個函式在`admin.html`/`teacher.html`/`student.html`三個檔案裡都已經有現成的，直接複製貼上就好，不用重新設計

**這條規則適用範圍是「所有」檔案顯示功能，不是只有「新做的」才要加**：
- 新功能：動手做的當下就要包含線上看，不用等使用者事後要求
- **既有功能**：如果之後修改到任何既有的檔案上傳/顯示功能，也要**順便**檢查有沒有線上看，沒有就補上，不用等使用者發現才提醒

**真實案例**：這條規則明明已經在成績彙總、常用表單、學倫審查文件這幾個「新做的」功能上都確實套用了，卻漏掉了**最早、最基本的公佈欄附件顯示**（`student.html`/`teacher.html`裡老師學生看公告附件的地方）——因為那段程式碼寫得比這條規則本身還早，規則生效後沒有回頭檢查既有功能，直到2026-07-18被使用者發現才補上。**教訓**：新增這類規則之後，要主動想一下「這個系統裡還有沒有其他地方，做的是同一件事但寫得比這條規則早」，不要只套用在新功能上。

## 29. 補角色RLS政策時，查詢裡有巢狀select（nested join）的話，每一層被帶出來的子表都要各自檢查、各自補政策

**規則**：發現某張表（如`enrollments`）缺少某個角色（如TA）的可讀政策而補上之後，如果原本的查詢是巢狀select、還帶出了其他表的欄位（例如 `sb.from('enrollments').select('student_id, students(id, name_zh)')` 這種寫法），**被巢狀帶出來的那張子表（這裡是`students`）也要單獨檢查一次它自己的RLS政策清單，不能只顧到最外層那張表就以為整條資料通了**。

**根本原因**：PostgREST 處理巢狀select時，外層表跟被帶出的子表是**各自獨立套用RLS**的兩件事。外層表（`enrollments`）的政策通過，不代表子表（`students`）的政策也會通過；子表被RLS擋下來的那幾筆，PostgREST不會把整筆外層資料排除，而是把子表欄位安靜地填成`null`，前端如果後面接了`.filter(Boolean)`把`null`的筆數濾掉，就會在畫面上呈現「少幾筆」，而且**不同使用者看到的『少的是誰』可能還不一樣**（因為各自可能透過其他無關的身份關係，巧合地對子表裡的某幾筆有讀取權限）——這種「同一段邏輯、不同人看到不同結果」的現象比起「全有全無」的失敗更難第一時間聯想到是RLS問題。

**真實案例**：2026-09-28，「TA課程管理／全班完成度總覽」補完`enrollments_ta_read`政策後，仍有TA反映「應該9人的名單只看到8人，而且每個TA看到的人數/缺的人還不一樣」，追查後發現是`students`表本身沒有對應的TA可讀政策，詳見`troubleshooting.md`症狀15。

**檢查方式**：任何時候幫某個角色新增一條表的RLS政策前，先看這張表在程式碼裡的查詢語法，**有沒有巢狀帶出其他表**（select字串裡出現`表名(欄位...)`的形式），有的話那些被帶出的表也要一併檢查、一併補政策，不要分次發現、分次補（容易漏掉，且每次都要重新debug才會發現）。
