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

**規則**：每次新增一種「誰能看到誰的資料」的新關係（如「導師可以看自己帶的學生」「所長可以看全部學生」），都要去檢查相關表（如`students`）現有的RLS policy清單，**不要假設舊policy會自動涵蓋新關係**。

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

## 18. schema.sql 只是初始snapshot，會漂移過時——重大改動前先跟資料庫核對

**規則**：`schema.sql` 是專案建立初期（v1.0，2026-05-18）的一次性snapshot，之後新增的表（例如 `semester_calendar_events`、`grade_periods`、`presentation_*`全套、`scholarship_*`全套等）**不會自動同步回這個檔案**。任何要動到資料庫結構判斷、或牽涉多張表關聯分析的重大改動之前，不要只看 `schema.sql` 就下結論，要先請使用者在 Supabase SQL Editor 跑以下兩段查詢，取得目前真正的欄位與constraint，再核對：

```sql
-- 欄位
SELECT t.table_name, c.column_name, c.data_type, c.is_nullable, c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, c.ordinal_position;

-- constraint（PK/FK/UNIQUE/CHECK）
SELECT tc.table_name, tc.constraint_name, tc.constraint_type, kcu.column_name,
       ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name, cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name AND tc.constraint_type = 'FOREIGN KEY'
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name AND tc.constraint_type = 'CHECK'
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type, kcu.column_name;
```

**根本原因**：程式碼裡實際的query語句（`sb.from('表名').select(...)`）比`schema.sql`更能反映當下真實用到的欄位，但query語句看不到constraint、預設值、FK關聯，兩者要交叉比對才完整。單靠其中一邊都可能做出錯誤判斷（例如漏掉某張表已經多了一個新欄位，或誤以為某個FK不存在）。

**發現於**：2026-07盤點「加退選截止時間」多套判斷邏輯不一致問題時，發現`schema.sql`缺少至少20張後續新增的表，包含當時正在討論的`semester_calendar_events`本身。

## 19. 讀VIEW的欄位前，先確認VIEW真的SELECT了那個欄位——不要假設join的表有什麼欄位就會自動出現

**規則**：前端程式碼裡如果用到 `xxx.find(c => c.某欄位)` 這種寫法，先去確認資料來源（尤其是VIEW）的SELECT語句裡有沒有真的列出`某欄位`。JOIN了某張表不代表那張表的所有欄位都會出現在VIEW的輸出裡——VIEW只回傳明確寫在SELECT裡的欄位。

**根本原因**：這種bug最陰險的地方是**不會報錯，也不會讓畫面明顯壞掉**。`c.is_current`讀到`undefined`，`.find()`回傳`undefined`，程式碼裡常常有fallback（例如「找不到current就用陣列第一個」），所以功能表面上「還是動的」，只是背後那段篩選/預設值邏輯完全沒有真正執行——例如`teacher.html`的「課堂點名」學期篩選（只顯示本學期+勾選才顯示過去），因為`v_course_schedule`沒有把`semesters.is_current`帶出來，`curLabel`永遠是`null`，導致篩選條件`if (!curLabel) return true`讓所有學期（包含未來）全部顯示，功能形同沒有在篩選，但介面上完全看不出異狀。

**檢查方式**：
```sql
-- 直接看某個VIEW的定義，確認SELECT清單
SELECT pg_get_viewdef('view名稱', true);
```
或直接翻 `views.sql` 對照程式碼裡實際用到的欄位名稱逐一核對，尤其是`is_current`、`is_active`這類「感覺應該存在但其實是另一張表的欄位」的旗標欄位最容易漏。

## 20. 「已經做好、確認測試通過的功能」反覆消失——這是專案知識庫版本管理的結構性問題，不是單次意外

**現象**：2026-07-04 發現 `admin.html` 的「課程幹部指派」功能（TA/視聽/小天使/點名者，`offering_staff`表）完全消失，但資料庫本身的表、欄位、view都還在——查證後發現這個功能是 2026-07-03 那次對話裡開發完成的，`User_Manual`也記載了（第34.2節），但**這次對話一開始拿到的專案 `admin.html` 檔案，內容是更早的版本，沒有包含這段**。這不是單一次意外，是同一類問題（症狀1「功能消失」）第二次發生在同一個專案，前一次是 `schema.sql` 缺了20張表。

**根本原因**：Claude 每次新對話開始時，是從**這個Claude Project裡存的檔案**（`/mnt/project/`底下，唯讀）當作起點去複製、修改。這份專案檔案**不會自動跟使用者本機/GitHub上實際部署的版本同步**——如果某次對話做完修改、確認測試通過、push到GitHub/Netlify之後，**沒有把同一份修改後的檔案也重新上傳更新進這個Claude Project**，下一次開新對話時，Claude拿到的還是舊版本，那次做的東西等於在「Claude的認知裡」消失了，後續的修改都是疊加在舊版本上，越晚發現、要救回來的東西越多。

**新規則（Claude端可以主動執行，不用依賴使用者記得）**：

**這個repo是public（`leetawu-tw/bwbc`），Claude可以直接用`bash_tool`的`curl`連`raw.githubusercontent.com`抓取，不需要使用者授權或提供token。**

1. **任何一次對話，只要任務涉及要對 `admin.html`/`teacher.html`/`student.html` 動修改（不只是讀取），開始動手改之前，先執行這個檢查：**
   ```bash
   curl -s "https://raw.githubusercontent.com/leetawu-tw/bwbc/main/admin.html" -o /tmp/admin_gh.html
   diff /mnt/project/admin.html /tmp/admin_gh.html | head -50
   wc -l /mnt/project/admin.html /tmp/admin_gh.html
   ```
   （檔名代入`teacher.html`/`student.html`同樣做）
2. **如果diff結果是空白、行數也一致** → Project裡的檔案跟GitHub一致，可以放心從Project檔案開始工作。
3. **如果diff結果不是空白** → **不要用Project裡的版本當基底**，改用剛抓下來的GitHub版本（`/tmp/admin_gh.html`）當工作基底，把這次要做的修改套用上去。做完後同時提醒使用者：這次工作是在GitHub版本上進行的，Project裡的舊檔案已經跟實際狀況不一致，事後需要更新Project。
4. **如果連線失敗**（網路設定不允許連`raw.githubusercontent.com`，或repo變成private）→ 退回症狀1的手動排查方式（翻對話記錄、看commit history網頁），不要因為連不上就跳過這個檢查步驟直接假設Project檔案是對的。

**已發生過的真實案例（2026-07-04）**：同一次對話裡發現Project版`admin.html`缺了兩批功能——先是「課程幹部指派」（`offering_staff`），後來擴大盤點才發現還缺「班級導師管理」「操行成績管理」「成績登錄後台」「兼課鐘點費核銷」「獎學金推薦」五大模組，整整少了6000多行。用上述GitHub diff方法一次性抓出GitHub版本（13955行）跟Project版本（7825行）的落差，直接用GitHub版當新基底重新套用當天的修改，比逐個功能翻對話記錄快非常多。**這已經是同一個專案第二次發生「Project檔案落後、需要救回」的狀況（上一次是`schema.sql`缺20張表），只是這次是前端程式碼、影響更直接。**

**驗證有效（2026-07-05）**：隔天開新對話，任務是修一個儀表板顯示bug，一開始就照這條規則先做GitHub diff檢查，馬上發現Project版還是舊的v4.0（7693行），而GitHub已經是前一天修完的14056行版本——代表使用者那次push完之後又忘記同步更新Project。因為有先做這個檢查，直接改用GitHub版本當基底往下查bug，完全沒有走冤枉路。**這條規則證實真的有攔下問題，繼續維持。**

## 21. 改變一個變數的「意義」時，要往下追蹤所有用到這個變數的地方，不能只改定義那一行

**真實案例**：2026-07-05，儀表板課程數統計卡片顯示「本學期/新學期」的開課數對調了。原因：`curSem`這個變數原本的意義是「`is_current`手動標記的那個學期」（管理員排課時會提前把`is_current`設到下學期，所以`curSem`實際上長期代表「準備中的新學期」，`prevSem`才代表「真正在跑的本學期」）。前一輪把`curSem`的算法改成「依日期判斷的真正現在學期」後，**只改了`curSem`怎麼算出來，沒有檢查下游`s1Label`（本學期）／`s2Label`（新學期）這兩個標籤原本是根據舊的變數意義去對應的**（`s1Label=prevSem`、`s2Label=curSem`），導致變數的新意義（`curSem`=真正本學期）跟標籤位置（`s2`=新學期）對不起來，兩個學期的開課數顯示對調。

**根本原因**：變數名稱從頭到尾都叫`curSem`，人在改動當下容易只盯著「怎麼算出這個變數的值」，忽略了這個變數在檔案裡其他地方被引用時，**當初取這個名字的人是根據舊的語意去設計後續邏輯的**，換了語意不代表用到它的地方會自動跟著換。

**預防方式**：任何時候要修改一個既有變數的計算邏輯（尤其是像`is_current`→日期判斷這種語意轉換），**先`grep`這個變數名稱在同一個函式（或同一個檔案）裡出現的所有地方**，逐一確認每個用法當初的設計假設是什麼，跟新語意還合不合——不要只改賦值那一行就收工。這次的教訓具體來說：`curSem`原意「is_current標記」隱含「可能是未來學期」，改成「日期判斷」後隱含「一定是正在進行的學期」，這兩種意義下「這個變數的下一個/上一個學期該叫什麼」完全相反，必須連著改。

## 22. 測試RLS權限矩陣，不用真的切換帳號登入——用SQL模擬身份即可

**做法**：`current_user_can_write(perm_key)`這類權限函式底層都是靠`auth.uid()`查`users`表，而`auth.uid()`實際上是讀`request.jwt.claims`這個session設定值裡的`sub`欄位。在SQL Editor裡可以直接用`set_config`模擬成任何一個帳號，不用真的登入：

```sql
SELECT set_config('request.jwt.claims', '{"sub":"<某個使用者的uid>"}', true);
SELECT current_user_can_write('courses'), current_user_can_write('open_courses');
```

**注意事項**：
- 每組`set_config`+查詢要**分開執行**（SQL Editor一次貼整段執行通常只顯示最後一段結果，前面的會被蓋掉），或者每跑完一組就手動記錄結果再往下貼下一組
- 這個方法只測**權限判斷函式本身**的邏輯，不是真的去讀寫表（不會弄髒任何資料），如果要測「policy在真實查詢情境下有沒有生效」，還是要搭配至少一次真實帳號登入操作驗證（尤其是第一次上線一批新policy時）
- 找測試帳號時，直接查`users`表挑幾個有代表性的權限組合（例如`permissions->>'courses'`分別是`'admin'`/`'write'`/`'read'`/`null`各挑一個），比自己臨時建測試帳號快很多

**真實案例**：2026-07-06 補測「RLS補強8張表 + B3 staff權限測試」這個懸置超過一週的待辦項目，用這個方法一次測完6種身份×多個permission key的組合，全部在SQL Editor裡幾分鐘內完成，不用真的申請/切換6個不同帳號登入。

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

## 30. 在「全域共用」的表新增分類欄位（如 survey_questions.kind）後，必須先盤點所有讀取這張表的地方，並先跑 SQL 再上前端

**規則**：`survey_questions` 這類表是全域共用的（沒有 survey_id），所有 `active=true` 的題目會出現在每一份調查。要讓某一批資料只在特定情境出現（例如只給數位課程的遠距教學題），做法是加一個分類欄位（`kind`），但**加欄位只是第一步**，要同時處理：

1. **盤點所有讀取點**：`grep -n "survey_questions" admin.html teacher.html student.html survey.html`，再加上資料庫函式（`get_survey_form_by_token`、`submit_survey_response`）。每一處都要決定「這裡要不要包含新分類」，漏掉一處就會出現不該出現的題目（例如一般統計頁多出一堆沒人填的遠距題）。
2. **判斷放在後端，不要只靠前端篩選**：是否帶出遠距題（課程是不是數位課程）在 RPC 內判斷，送出時 RPC 也要擋掉不該收的答案，不能只靠前端隱藏。
3. **部署順序：先執行 SQL，再上前端**。前端帶 `.neq('kind','remote')` 之類的篩選時，資料庫還沒有該欄位會直接查詢失敗；反過來，只跑 SQL 不更新前端，舊前端會把新題目當成一般題顯示。
4. **兩套量表不要共用同一組常數**：一般題是「非常同意…非常不同意（中間：普通）」，遠距題是「非常滿意…非常不滿意（中間：尚可）」。統計程式依選項文字比對計分，共用 `SCALE`/`SCORE` 會讓整題算成 0 筆。
5. **改題目文字用 UPDATE，不要重跑建立題目的 SQL**：新增段落以題目文字判斷是否存在，文字改過再重跑會重複新增一批。

**真實案例**：2026-10-13～14，新增「遠距教學課程 教學品質調查」。資料庫加 `kind` 欄位與 8 題之後，admin／teacher 的統計頁各有一處 `from('survey_questions')`，不加篩選就會在每一科的一般統計裡多出 8 題空白題目；兩處補上 `.neq('kind','remote')`，遠距題改由獨立區塊顯示。

**檢查方式**：新增任何「只對一部分資料適用」的內容時，先問「現有所有讀取這張表的地方，各自該不該看到它？」再動手。

## 31. 改既有表的欄位型別／長度前，先查「生成欄位、視圖、索引」的相依，用「暫存→移除→修改→重建→比對」流程，整段放在同一個交易

**規則**：要對 `students.student_code` 這類被其他物件依賴的欄位做 `ALTER COLUMN ... TYPE`（或改 CHECK），先查清楚有誰依賴它，不要直接改：
```sql
-- 生成欄位及計算式
SELECT a.attname, pg_get_expr(d.adbin, d.adrelid) AS expression, a.attgenerated
FROM pg_attribute a JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attrelid = 'public.students'::regclass AND a.attgenerated <> '';
-- 依賴某欄位的視圖
SELECT DISTINCT v.relname FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid JOIN pg_class v ON v.oid = r.ev_class
JOIN pg_attribute a ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
WHERE d.refobjid = 'public.students'::regclass AND a.attname = '欄位名' AND v.relname <> 'students';
-- 相關索引、policy 另外用 pg_indexes / pg_policies 查
```

**標準流程（`DO $$ ... END $$` 一整段＝單一交易，失敗全部還原）**：
1. 備份依賴物件：視圖用 `pg_get_viewdef(oid,true)` ＋ `reloptions` ＋ `relacl` 存進變數/暫存表；生成欄位用 `pg_get_expr(adbin, adrelid)` 讀出計算式；另備份生成欄位目前的值到暫存表。
2. 移除依賴物件（`DROP VIEW`、`DROP COLUMN` 生成欄位）。
3. 修改（改型別、CHECK 等）。
4. 重建：生成欄位用 `format('ALTER TABLE ... ADD COLUMN x smallint GENERATED ALWAYS AS (%s) STORED', 計算式)`，補回索引；視圖用 `CREATE VIEW ... AS 備份定義`，再用 `aclexplode(relacl)` 還原 GRANT。
5. **比對**：重建後的生成欄位值跟備份逐筆比對，有任何不同就 `RAISE EXCEPTION` 讓整段還原。

**根本原因**：`ALTER COLUMN TYPE` 遇到生成欄位會報 `cannot alter type of a column used by a generated column`，遇到視圖會報被視圖使用；而 Supabase SQL Editor 一次執行整段時，錯誤會讓整段回滾，才不會留下「改一半」的狀態。

**真實案例**：2026-10-18，學分班學號是 10 碼，`students.student_code` 是 `char(8)` 加 `CHECK ^\d{8}$`。`cohort` 是「取學號前 3 碼」的生成欄位，`v_student_advisors`、`v_presentation_participants_public` 兩個視圖依賴相關欄位，依序造成兩次失敗，最後用上述流程一次完成（改 `varchar(10)`、CHECK 改 8 或 10 碼、重建 `cohort` 與兩個視圖，並比對 55 位學生的 `cohort` 不變）。**別用「先猜計算式」的寫法，一律從資料庫動態讀出計算式再重建。**

## 32. 非正式學生（學分班）放在 `students` 表，用 `student_type` 區分；所有「學生統計」類功能都要排除 `student_type <> 'regular'`

**設計（2026-10-18）**：
- `students.student_type`：`regular`（預設，一般生）、`audit`（隨班附讀）、`credit_program`（學分專班）。學號 10 碼（一般生 8 碼），`chk_student_code` 允許 8 或 10 碼。
- Email 存 `personal_email`；不產生 `@bwbc.edu.tw` 學校信箱，也不建立登入帳號（學分班不登入學生端）。
- 選課沿用 `enrollments`（狀態 `confirmed`）。因此「選課人數、點名單、教學意見調查連結」這幾個從 `enrollments` 讀資料的功能**自動涵蓋**學分班，不需要另外一套名單。
- `cohort`（屆別）由學號前 3 碼算出，對學分班沒有意義（同一個人各學期沿用第一次的學號），**學分班不參與任何屆別統計**，不要把它改成手動輸入。

**必須遵守**：
1. 任何讀取 `students` 做「統計」「完成度」「畢業」「導師」「論文」的功能，都要加 `student_type = 'regular'` 的條件，否則學分班同學會混進一般生的分母；新增這類功能時主動加。**2026-10-19～23 已完成**：選課統計分析、選課完成度總覽、推薦選課缺漏名單、成績彙總、操行成績（產生名單、非在學名單）、學生資料、工讀生簽到、發表會參加者、班級導師名單共 11 處已加 `.eq('student_type','regular')`。新增功能時比照辦理，不要憑印象判斷。
2. 學分班匯入不可覆蓋一般生：學號對到 `student_type='regular'` 的列一律擋下。
3. 「正式功能」（一般生匯入、學號格式驗證 `^\d{8}$`）維持 8 碼，不要因為學分班放寬而一起放寬。
4. **名單類功能要含學分班、統計類功能要排除**：點名單、選課學生名單、成績登錄、空白評分表、教學意見調查連結要列學分班（他們佔座位、要點名、要發問卷），人數寫成「一般生 ＋ 學分班 N 人」；成績照常登錄與保存，但不進任何統計。
5. **學分班加選只能選 `courses.is_audit = true` 的課**：加選視窗、新增學生視窗的課程下拉、Excel 匯入三處同一規則。`is_audit`（開放隨班附讀）與 `is_digital`（數位課程）是不同欄位，不要混用。
6. 獎學金推薦目前只靠資料檢查（2026-10-23 SQL 查得 0 筆），程式端沒有排除；若日後發現學分班被推薦，補 `student_type = 'regular'`。

詳細見 `User_Manual_V14.md` 第 70 節。

## 33. 「批次產生記錄」的功能（如問卷連結）要能補產生，並依學生狀態過濾

**規則**：
1. **產生功能要有補產生的入口**：原本「🎫 產生填答連結」只在調查為「草稿」時顯示，調查一開放就沒有按鈕，晚加選的學生（如學分班）永遠補不上連結。批次產生要靠唯一鍵（`UNIQUE(survey_id, enrollment_id)`）與「已存在就略過」保證可重複執行，並在開放中也提供「補產生」按鈕。
2. **產生時過濾不該有的人**：略過 `students.status` 為 `leave`（休學）、`withdrawn`（退學）的學生。系統慣例是休學只改學生狀態，不動選課記錄，所以只看 `enrollments.status='confirmed'` 一定會把休學的人算進去。
3. **已產生的連結不自動刪除**：需要時用 SQL 只刪 `used=false` 的（已填答的保留）。先 `SELECT` 預覽名單，確認後再 `DELETE`。
4. 用 SQL 補產生時，條件必須與程式一致（含休學／退學過濾），並用 `WITH ins AS (INSERT ... RETURNING ...) SELECT count(*) FROM ins` 取得新增筆數；**舊版的補產生 SQL 沒有休學條件，不要重複執行**。

## 34. 判斷「這學期有沒有開這門課」一律要排除已停開／停用的開課

**規則**：凡是用 `course_offerings` 判斷「有開課」「有授課」的地方，都要加 `.eq('is_active', true).eq('is_cancelled', false)`。停開只是把 `is_cancelled` 標成 `true`，開課記錄與 `offering_teachers` 都還在，不加條件就會把停開的課算進去。

**真實案例**：2026-10-17，兼課鐘點費核銷頁，課程停開後吳昌衛、林君昱仍出現在清單（程式只看 `offering_teachers`，沒有排除停開的開課）。修法：載入授課資訊時加上述兩個條件。

**檢查方式**：新增或修改「授課／有開課」判斷時，`grep -n "course_offerings" admin.html`，確認每一處是否該排除停開；診斷用 SQL 也要同時印出 `is_active`、`is_cancelled`，只印「有幾筆」會被停開的課誤導。

## 35. 休學是「學生狀態」、停修是「課程狀態」，兩者不能混用；學期層級的學籍要看「該學期結束當下」

> 2026-10-24 重寫：原規則寫「休學只改學生狀態，不動選課記錄」，與實際作法不符，已更正。

**規則**：
1. **兩種狀態分開存、分開顯示**：`students.status`（`leave` 休學、`withdrawn` 退學…）是學生整體狀態；`enrollments.status`（`withdrawn` = 停修…）是單一課程的狀態。休學不是停修，絕對不要把休學的課顯示成「停修」。
2. **標記方式**：admin 把學生狀態改成休學／退學時，跳出視窗列出該學期 `confirmed` 的課，確認後寫入 `enrollments.status='withdrawn'`、`withdraw_at`、`withdraw_reason`，**原因欄開頭固定為「休學」或「退學」**（可在後面自行補充，例如「休學：家庭因素」）。原因空白或其他文字 = 正式停修。顯示層一律依「原因開頭」轉成休學／退學／停修。這樣既有的「排除 `withdrawn`」邏輯不用改，復學後也不會誤把休學學期的課當成有效修課。**復學不恢復舊課，須重新選課。**
3. **顯示順序**：該學期學籍（休學／退學）→ 選課標記（原因開頭）→ 停修 → 退選 → 類別（一般生／隨班附讀／學分專班）。
4. **人數**：「選課總人數」「修課學生數」不算休學、退學、停修，但這些同學仍列名單並標示（灰底、各週格子寫狀態、不可編輯）。有學分班時寫 `16 ＋ 學分班 5 人`。名單一般生在前、學分班在後，序號連續。
5. **學期層級要看「該學期結束當下」的學籍，不是 `students.status` 的現在值**：用 `student_status_history`（排除 `is_applied=false`）取「學期結束日（含）以前的最後一筆」；最早一筆之前用該筆的 `old_status`；完全沒有歷程才退回現在狀態。例：某同學 115-1 才休學，114-2 的名單與人數仍要當正常修課。**學期中途休學 = 整個學期視為休學**。
6. **各角色讀得到什麼不同**：admin 讀得到歷程，用上述算法。**老師帳號的 RLS 讀不到 `student_status_history`**，改用折衷：學期已結束 → 只看選課記錄上的標記、忽略學生現在學籍；學期尚未結束 → 同時併用現在學籍。**學生帳號**要先建 `student_status_history_self_read` policy（只能 SELECT 自己的列）才讀得到，讀不到時功能自動略過，不要報錯。
7. **兩種休學情境都要記錄**：(a) 學期開始前就沒註冊 → 沒有任何選課記錄，只有歷程，成績單與學生修課紀錄要靠歷程顯示「該學期：休學」；(b) 學期中途申請 → 已有選課，需要標記（規則 2）。累計休學學期數 = 已開始的學期中、結束當下為休學的學期數。
8. **歷程資料可能不乾淨**：系統上線前就休學的人可能沒有歷程；也曾出現重複的「在學→休學」、或「休學→休學」（續休）。完全沒有歷程的人不要推算休學學期；續休要用明確的流程處理，不要寫 leave→leave 記錄。
9. **同步處**（改其中一處必須檢查其他處）：行政端點名單（列印＋Excel）、空白評分表（xlsx／CSV）、查看成績、開課記錄「已選 X 人」、成績單 PDF／Excel／含操行總成績單、成績彙總畫面與匯出 Excel、老師端選課學生名單／成績登錄／課堂點名與點名記錄 Excel／我的課程人數、學生端選課按鈕／已選課程／歷年已選課程。

**根本原因**：曾把「學生休學」處理成「批次標記停修」，造成狀態混用——休學的課被顯示成停修、復學後無法區分；又曾直接拿學生「現在」的狀態去套所有學期，導致後來才休學的人把過去正常學期也標成休學。

**檢查方式**：新增或修改任何「列出修課學生」或「依學期顯示學籍」的功能時：select 要帶 `enrollments.status`、`withdraw_reason` 與 `students.status`、`student_type`；查詢條件用 `.in('status',['confirmed','withdrawn'])`；學期層級的學籍用歷程算；再由程式依規則 3 決定標示、依規則 4 決定是否計入人數。

## 36. 匯出給 Excel 開啟的檔案：10 碼學號與欄寬

**規則**：
1. CSV 裡的學號要寫成文字格式（`="1142401007"`），否則 Excel 會把 10 碼學號顯示成 1.14E+09。批次匯入成績要能讀回這種寫法（去掉 `="` 與 `"`）。
2. CSV 無法設定欄寬；需要欄寬時改匯出 `.xlsx`（SheetJS，`ensureXlsxLib()` 載入），並設定 `ws['!cols']`；學號姓名同一欄時寬度至少 24。CSV 可保留給需要純文字的情況。
3. 老師端目前只匯出 `.xlsx`／`.csv`，匯入仍只收 CSV（刻意不做 `.xlsx` 匯入）。
4. 欄位順序、標頭用同一個函式或同一份規格，避免行政端與老師端各寫一套。

**真實案例**：2026-10-22，學分班 10 碼學號在 Excel CSV 顯示 1.14E+09，改文字格式後仍有 2 碼被欄寬截斷，最後新增「匯出 Excel」並加寬欄位。


## 37. 日期字串（yyyy-mm-dd）全程當字串處理；只要轉成 Date 物件再轉回來，就有 ±1 天的時區地雷

> 補回：原記於 2026-07-02 的規則（當時編號 18），7/7 後的 skill 版本漏掉，2026-10-23 從舊對話找回。

**規則**：
1. 日期欄位（`class_date`、`start_date`、`change_deadline` …）存進資料庫、`<input type="date">`、字串比對、排序、`.slice()` 都直接用字串，永遠安全。
2. 需要「迴圈走過每一天」或「算星期幾」時，用 `new Date(y, m-1, d)` 取 `getDay()`，但**輸出回字串時用 y/m/d 數字手動拼**（`${y}-${String(m).padStart(2,'0')}-${String(d).padStart(2,'0')}`），**不要用 `.toISOString().slice(0,10)`**。
3. `new Date("2026-06-02")` 會被當成 UTC 午夜解析，與 `new Date(2026,5,2)`（本地午夜）不同；兩種混著用、或其中一種再 `toISOString()`，在台灣（UTC+8）就會差一天。

**真實案例**：兼課鐘點費「依課表帶入」（`prefillFromSchedule()`）用 `dt.toISOString().slice(0,10)` 存日期，本地午夜轉 UTC 後往前推一天，週二的課被存成週一的日期。

**唯一例外**：`new Date().toISOString().slice(0,10)` 只用來當匯出檔名的日期戳，誤差最多幾小時，不影響可讀性，不用改。

## 38. 定期用單一查詢整批盤查全資料庫的 RLS，不要只檢查剛動到的表

> 補回：原記於 2026-07-03（當時編號 19）。

**規則**：大改版或排查權限問題時，跑一次全庫盤查：
```sql
SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname='public' ORDER BY tablename;
SELECT tablename, policyname, cmd FROM pg_policies WHERE schemaname='public' ORDER BY tablename;
```
比對兩種異常：① 有 policy 但 `rowsecurity=false`（policy 等於白寫）；② 完全沒有 policy（可能是刻意公開，也可能是漏洞）。逐一確認是刻意還是遺漏。

**真實案例**：2026-06-25 寫文件時整批 dump schema，才發現 `courses`／`teachers`／`course_offerings` 三張核心表 policy 寫好卻從沒開 RLS，`offering_teachers`／`classrooms` 則完全沒 policy，已存在好幾週沒人發現。

**刻意例外（需向使用者確認現況）**：2026-07 使用者曾確認教學意見調查四張表（`surveys`／`survey_tokens`／`survey_questions`／`survey_responses`）刻意不開 RLS。盤查時看到這幾張沒開不要擅自開啟，先問使用者現在是否仍是這個決定。

## 39. 產生或解析 Word 文件（套版、匯入）的常見坑

> 補回：原記於 2026-07-03（當時編號 20）。原文只找回重點，細節以實際測試為準。

1. **`\n` 不會變成 Word 換行**：套版置換文字時，換行要用 Word 的換行標記，不能直接塞 `\n`。
2. **mammoth 轉 HTML 會產生 `<br>`**：解析時要把 `<br>` 當換行處理，否則多行內容會黏在一起。
3. **動態表格列**：資料筆數不固定的表格，要複製範本列再填入，不能假設列數固定。
4. **表格定位不要靠表頭文字或相對位置**：最穩的做法是把整份文件所有表格的所有列攤平成一個陣列，逐列比對固定的「標籤文字」去抓值；不同表格的標籤通常不重複。
5. **新增或修改套版功能前，先解壓範本 .docx，確認 `word/document.xml` 裡「真的有」`{{XXX}}`／`[[XXX]]` 標記**。本專案踩過兩次：以為範本有標記，置換邏輯其實從沒生效，下載的檔案只是範本換個檔名，沒人發現。

## 40. 匯入會覆蓋既有資料時，先做「新舊比對、逐欄選擇」，不要靜默覆蓋

> 補回：原記於 2026-07-03（當時編號 21）。

**規則**：目標記錄已有資料時，不要匯入完直接存檔。流程是「讀舊資料 → 與新資料逐欄並排 → 使用者每欄選舊或新（預設新）→ 預覽 → 再按一次儲存才寫入」，中間沒有任何一步是靜默覆蓋。新舊相同的欄位自動變暗、標示不用選。

**批次比對編號時**：不要只在「目前畫面篩選範圍」（例如只查選定學期）找，找不到要再查資料庫全集，否則會把「資料存在、只是不在篩選範圍」誤判成「找不到」。更好的做法是讓使用者選「優先比對範圍」，並保留全集查詢當備援。

**可重用**：這個比對框架同樣適用「從舊學期複製」等其他資料來源。

## 41. 工具列按鈕超過 5～6 顆，就收進下拉選單

> 補回：原記於 2026-07-03（當時編號 22）。

**規則**：一個功能區的按鈕一路橫排，筆電就放不下、手機更糟。超過 5～6 顆就依性質分成 2～3 個下拉選單（例如「列印／範本」「大綱匯入」「資料」），只留最常用的一顆（如「＋新增」）獨立。下拉選單要：點外面自動收起、點項目執行後自動收起、手機寬度（≤600px）改成貼齊左右兩側並加大字體與間距。

**排版陷阱**：標題若設了 `flex:1`，後面接的選單會被推很遠；要另放一個獨立的 `flex:1` 空白區塊把按鈕推到右邊，不要依賴標題本身的 flex。

## 42. Supabase Storage 路徑（key）不能含中文或任何非 ASCII 字元

> 補回：原記於 2026-07-03（當時編號 23）。

**症狀**：`.upload(path, file)` 的 `path` 含中文，直接回 `Invalid key`；改用 `encodeURIComponent()` 也不行，會變 `400 Bad Request`，因為 `%` 本身不在允許字元內。

**規則**：路徑只用英數字與 `-` `_` `.` `/`；中文姓名、原始檔名只存資料庫欄位（如 `file_name`）給畫面顯示，與 Storage 底層路徑脫鉤。
```js
// ❌ const path = `${eventId}/${studentCode}_${studentName}/${file.name}`;
// ❌ const path = `${eventId}/${encodeURIComponent(studentName)}/...`;
// ✅ const ext = file.name.split('.').pop();
//    const path = `${eventId}/${studentCode}/${Date.now()}.${ext}`;
```
新增任何上傳功能、組路徑前，先檢查有沒有姓名、課程名稱、原始檔名這類可能含中文的變數。這個坑踩過兩次（公佈欄附件、畢業論文發表會附件）。

## 43. 用 SQL Editor 建新表，要另外 GRANT；只做 RLS 不夠

> 補回：原記於 2026-07-03（當時編號 24）。

**規則**：GRANT（資料表層級權限）在 RLS（列層級）之前檢查，缺 GRANT 會直接 `42501 permission denied for table xxx`，連 policy 都還沒機會生效。新建表後要補：
```sql
GRANT SELECT ON 表名 TO anon;            -- 只有需要公開讀取時
GRANT ALL ON 表名 TO authenticated;
-- 序號欄位另補：GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
```
`GRANT ALL ON ALL TABLES` 只涵蓋執行當下已存在的表；要讓之後新建的表自動授權，可設 `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;`。GRANT 與 RLS 兩者獨立，都要規劃。

## 44. 同一個顯示邏輯被複製在多處（三個 portal、畫面 vs 匯出檔）時，改一處就要全部搜尋一遍

**規則**：admin／teacher／student 三個檔案沒有共用模組，畫面、列印、Excel／CSV 匯出也常是各自一套程式。只要改了「怎麼判斷」或「怎麼顯示」，立刻用關鍵字或函式名稱搜尋全部檔案、全部出口，逐一確認。

**真實案例**（2026-10-24）：
1. 首頁「重要時程提醒」：admin 已把「已開始、尚未結束的期間型事件」歸到「本學期進行中」，student、teacher 是複製的舊版，仍放在「即將到來」，三個首頁看起來不一致。
2. 成績彙總：畫面名單已加「休學」標籤，但「匯出彙總 Excel」是另一套程式，漏改，使用者看 Excel 看不出誰休學。
3. 成績單「本學期修讀」標籤：累計或整學年的成績單其實是合計，標籤卻寫死「本學期」，改成依範圍帶入「累計修讀」「XXX 學年度修讀」；PDF、Excel、「查看」彈窗三處都要一起改。

**檢查方式**：改動前先 `grep` 該段文字或函式名稱，列出所有命中處；改完再 grep 一次確認沒有漏網。交付時在更新紀錄寫明「影響範圍」。

## 45. 需要呼叫第三方 API（如 Anthropic）時：用 Supabase Edge Function 當中繼，金鑰只放 Secrets

**規則**：
1. 純前端網頁**不能**放 API 金鑰。做法：前端 `sb.functions.invoke('函式名', {body})` → Supabase Edge Function → 第三方 API。金鑰存在 Edge Functions 的 Secrets（名稱如 `ANTHROPIC_API_KEY`），不進 GitHub、不進任何 html。
2. 函式內必須自己檢查身分：用呼叫者的 `Authorization` 建 `createClient`，`auth.getUser()` 確認已登入，再查 `users.role` 是否為 admin／director；Verify JWT 保持開啟。
3. 只送「匿名且必要」的資料（例如教學意見：統計與開放題文字，不含姓名／學號）；送出前用 `confirm()` 告知筆數與會產生費用；學生寫的文字要當資料處理（提示詞明講裡面的指令一律忽略）。
4. 分批呼叫（每門課一次、最多同時 3 次，最後再做總覽），避免單次請求太大或逾時；單次輸入設上限。
5. 費用概念：教學意見調查 11 門課、274 則回饋，一次約 US$0.13；每學期期中期末各一次，一年不到 US$1。用「手動儲值」，不要開自動儲值。
6. API Key 設有到期日時（建議 1 年），到期前先建新 Key 並更新 Supabase Secret，否則功能會突然失效。
7. `SUPABASE_ANON_KEY` 已標示棄用（新名稱 `SUPABASE_PUBLISHABLE_KEYS`），目前仍可用；之後要改。
8. 函式原始碼備份在版本庫 `schema/survey-ai-analysis/`（`index.ts`、`README.md`）；Supabase 網頁上貼的版本與它要保持一致。
9. 測試下載、列印這類「只用到結果」的功能時，用瀏覽器 Console 塞假資料，不要為了測試重複呼叫付費 API。

---

## 46. 任何「選學期」的下拉選單，預設一律是「本學期」，不是清單第一筆

**問題**：學期清單通常由新到舊排序，直接取第一筆，進頁面就落在「還沒開始的下一學期」（例如現在是 115-1，卻預設 115-2）。使用者每次都要手動改，而且容易在錯的學期看資料、做事。

**規則**：
1. 預設值用 admin.html 共用函式 `getCurrentSemesterByDate()`（依今天日期判斷，不依賴 `is_current`；今天不在任何學期內時取最近的一個），不要取 `sems[0]`。
2. 寫法：`const cur = await getCurrentSemesterByDate(); AD.sem = (cur && sems.includes(cur.label)) ? cur.label : (sems[0]||'');`——找不到才退回最新一筆。
3. 只有「使用者還沒選過」時才套預設；使用者自己切換過的學期要保留。
4. 新做任何與學期有關的頁面，動工時就要照這條做；做完測試第一步就是確認進頁面時顯示的是本學期。
5. 教師端／學生端要判斷本學期時，沿用各自既有的日期判斷邏輯（見規則 44，不要自己再寫第三套）。

**實例**：admin v10.73「課程教學（檢視）」第一版預設成 115-2，被使用者看出來，當場修正。

---

## 47. 三端「以課程為中心」的入口命名與結構：新功能掛在課程入口之下，不要另開獨立選單

**三端入口對照（2026-10-24 定案）**：

| 角色 | 入口名稱 | 進去之後 |
|---|---|---|
| 管理端 | 側邊欄群組「選課與課程教學」 | 「課程教學（檢視）」：選學期→選課程→分頁「單元／教材與作業／討論／討論統計」，**唯讀** |
| 教師端 | 「📚 我的教學」（舊名：我的課程） | 課程卡片按「📝 課程教學」→ 課程小卡入口：🗂 單元管理、📝 教材與作業、💬 討論區 |
| 學生端 | 「🎓 我的選課」（舊名：我的課程） | 本學期每門課依單元整理教材、作業、討論 |
| 學生端 | 「📚 加退選」（舊名：選課） | 加選、退選、選課單列印、歷年已選課程 |

**規則**：
1. 與某一門課有關的新功能（教材、作業、討論、測驗…），入口一律放在「課程入口」裡，不要再加獨立的側邊欄項目；三端同步，管理端對應的檢視頁也放在「選課與課程教學」群組。
2. 學生端「選課」改名「加退選」是為了避免與「我的選課」撞名；之後新增選單名稱前，先看三端現有名稱有沒有重複或太像。
3. 改名只改「顯示文字」（側邊欄、頁面標題、麵包屑、課程卡片按鈕），不要動 `showSection('…')`、`id`、`sec-…` 這些內部識別名稱，否則連動的函式、反白判斷會壞。改完要 grep 整份檔案的舊名稱，包含麵包屑（teacher 有 6 處）與提示文字。
4. 子畫面（單元管理、教材與作業、討論區…）沒有自己的側邊欄項目，要在 `showSection()` 的「反白對應表」裡掛回「我的教學」，否則進去後側邊欄沒有任何項目反白。
5. 麵包屑（頁面上方「我的教學／課名／討論區」那一排）每一層都要能點回去；從下拉選單換課程時，麵包屑的課名與 `CUR_HUB` 要同步更新（`tdSyncHub()`）。
6. 版面寬度：教師端與學生端的 `.main` 都不限制最大寬度（`max-width:none`），避免兩端畫面一個撐滿、一個置中。
7. **有順序的清單（單元、題目、類別、設備…）一律「滑鼠拖曳＋▲▼按鈕」兩種都要有**（2026-10-24 決定）：拖曳方便大幅移動，▲▼ 在只差一列或觸控螢幕（HTML5 拖曳在觸控螢幕不能用）時好用。
   - 教師端共用函式 `dragSortBind(wrap, rowSel, onMove)`（teacher v3.48，在單元管理上線）：列的最左邊放 `<span class="drag-handle">⠿</span>`，**只有按住把手才能拖**（避免點按鈕、選取文字時誤拖），拖曳時用藍線（`.drag-over-top`／`.drag-over-bottom`）提示放開的位置。新增有順序的清單時直接沿用，不要再寫新的一套。管理端目前各處（表單、法規、設備管理）各有自己的拖曳實作，新做的時候可參考同樣的操作方式。
   - 排序要**整批重新編號**（0、1、2…），只把有變動的列寫回資料庫；寫入失敗要提示並重新載入。不要用「兩列交換 sort_order」的做法：交換後若本機物件的 sort_order 沒同步，連續調整會寫錯；兩列的 sort_order 相同時交換等於沒換。
   - ▲▼ 與拖曳呼叫同一個函式（`moveUnit(index,dir)` → `reorderUnits(from,to)`），確保兩種操作結果一致。
   - 新增項目時 `sort_order` 取目前最大值＋1。
   - 尚未套用：教師端出題的題目順序（`moveQuestion`，仍是舊的交換做法，且有「題目版本鎖定」要先處理）。

---

## 48. 新做「管理端唯讀檢視頁」之前，先把 RLS 政策查清楚；SQL Editor 一次只顯示最後一段結果

**規則**：
1. 要讓 admin 看教師端／學生端才有的資料前，先用 `pg_policies` 查相關表有沒有 admin 可讀的政策（本專案的做法：`current_user_role() = 'admin'` 或 `staff` 且 `current_user_can_read('…')`）。確認可讀才動工；不可讀才補 SQL，不要先寫畫面再猜。
2. Storage 檔案要另外查 `storage.objects` 的政策（`course-materials`、`course-videos` 兩個 bucket 的讀取政策都已包含 admin／staff）。
3. 管理端開啟檔案一律用 `createSignedUrl()` 再 `window.open`，不要公開 bucket。
4. **Supabase SQL Editor 一次執行多段查詢，只會顯示最後一段的結果**——要查多件事就一段一段分開跑，或用 `union all` 合成一個結果。
5. staff 權限 key（如 `course_materials`）若沒有出現在 admin.html 的 `PERM_KEYS`，側邊欄項目就維持 `data-perm="__admin_only"`，不要擅自開放給 staff。
6. 檢視頁的資料載入，主要資料與輔助資料（例如單元對應課次、繳交人數）要分開處理，輔助資料失敗不能讓整頁空白。
