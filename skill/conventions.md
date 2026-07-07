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

**根本原因**：RLS policy是針對「已知的關係」寫的（如本系統最早只有「老師能看自己開課班的修課學生」這條），新增的角色關係（導師、所長）完全是陌生身份，會被舊policy擋下來，但因為**其他不受RLS管控的欄位（如直接讀取的成績數字）依然正常顯示**，會造成「部分欄位有值、部分欄位空白」這種詭異的半成功現象，比起整頁全部失敗更難第一時間聯想到是權限問題。

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
