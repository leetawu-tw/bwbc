# RLS Policy 清單

> 產生日期：2026-07-06　資料來源：即時查詢 `pg_tables`/`pg_policies`/`pg_proc`
> 本文件記錄「哪張表有沒有RLS、有幾條policy」的盤點結果，以及權限判斷函式的運作邏輯。
> 各表policy的**詳細判斷條件**（qual/with_check），除了本次新增的8張表以外，尚未逐一查詢記錄——如需要可另外查詢補齊。

---

## 一、權限判斷架構

系統的寫入權限，最終都是靠三個包裝函式，底層共用同一個 `current_user_perm_level(perm_key)`：

```sql
current_user_perm_level(perm_key text) RETURNS text  -- 回傳 'admin'/'write'/'read'/'none'
  role = 'admin'  → 一律回傳 'admin'（admin對任何perm_key都bypass，不受permissions欄位限制）
  role = 'viewer' → 一律回傳 'read'
  role = 'staff'  → 查 users.permissions ->> perm_key：
                      'true'         → 'admin'
                      'false'        → 'none'
                      'admin'/'write'/'read' → 原樣回傳
                      其他（含未設定的key）→ 'none'
  其他角色（teacher/student/director）→ 一律 'none'

current_user_can_write(perm_key)  ⇔ perm_level IN ('write','admin')
current_user_can_delete(perm_key) ⇔ perm_level = 'admin'
current_user_can_read(perm_key)   ⇔ perm_level IN ('read','write','admin')
```

**目前系統裡實際在用的 perm_key**（對應員工權限管理頁面可以勾選的分類）：
`announcements`、`classrooms`、`courses`、`logs`、`meetings`、`open_courses`、`scholarship`、`semesters`、`students`、`surveys`、`teachers`、`thesis`、`todos`

**重要**：新增RLS policy時，優先沿用上面這些既有key，不要隨便發明新key——除非同時也去員工權限管理頁面加上對應的toggle，不然staff永遠無法被授權到新key（admin不受影響，永遠bypass）。

---

## 二、命名慣例（兩種寫法都有人用）

**簡單型（2條policy，適合偶爾維護的參考/設定資料）**：
```sql
CREATE POLICY {table}_public_read ON {table} FOR SELECT USING (true);
CREATE POLICY {table}_write ON {table} FOR ALL
  USING (current_user_can_write('{perm_key}'))
  WITH CHECK (current_user_can_write('{perm_key}'));
```

**精細型（4條policy，適合頻繁CRUD、需要區分刪除權限的核心資料）**：
```sql
CREATE POLICY {table}_read   ON {table} FOR SELECT USING (true);
CREATE POLICY {table}_insert ON {table} FOR INSERT WITH CHECK (current_user_can_write('{perm_key}'));
CREATE POLICY {table}_update ON {table} FOR UPDATE
  USING (current_user_can_write('{perm_key}')) WITH CHECK (current_user_can_write('{perm_key}'));
CREATE POLICY {table}_delete ON {table} FOR DELETE USING (current_user_can_delete('{perm_key}'));
```

---

## 三、全表 RLS 狀態盤點（2026-07-06查詢，不含bak_*備份表）

### 3.1 刻意不開RLS（使用者確認過的設計決定，不要動）

| 表 | 說明 |
|---|---|
| `surveys` | 教學意見調查主檔 |
| `survey_questions` | 調查題目 |
| `survey_responses` | 填答內容——**信任學生填答環境**，刻意不設RLS |
| `survey_tokens` | 填答連結/完成狀態 |

### 3.2 本次新增RLS（2026-07-06，8張表，詳細policy見第四節）

| 表 | perm_key | read | write |
|---|---|---|---|
| `academic_years` | semesters | 公開 | current_user_can_write |
| `course_axes` | courses | 公開 | current_user_can_write |
| `course_series` | courses | 公開 | current_user_can_write |
| `course_groups` | courses | 公開 | current_user_can_write |
| `course_prerequisites` | courses | 公開 | current_user_can_write |
| `graduation_requirements` | courses | 公開 | current_user_can_write |
| `enrollment_settings` | open_courses | 公開 | current_user_can_write |
| `conflict_log` | open_courses | **限current_user_can_read**（內部工具，不公開） | current_user_can_write |

### 3.3 已有RLS（此前已完成，僅列policy數量，詳細判斷條件未逐一記錄）

| 表 | policy數 | 表 | policy數 |
|---|---|---|---|
| adjunct_pay_rates | 2 | offering_staff | 2 |
| adjunct_payroll | 2 | offering_teachers | 2 |
| adjunct_payroll_days | 2 | poll_options | 3 |
| announcements | 4 | poll_questions | 3 |
| attachments | 4 | poll_responses | 4 |
| attendance_records | 2 | poll_sets | 3 |
| audit_log | 2 | presentation_attachments | 2 |
| class_advisors | 6 | presentation_events | 2 |
| class_sessions | 2 | presentation_judges | 2 |
| classrooms | 2 | presentation_participants | 2 |
| conduct_grades | 4 | presentation_scores | 2 |
| course_equivalencies | 4 | presentation_share_links | 2 |
| course_offerings | 4 | scholarship_categories | 2 |
| courses | 4 | scholarship_confirmations | 2 |
| enrollments | 9 | scholarship_periods | 2 |
| grade_assignments | 4 | scholarship_recommendations | 2 |
| grade_entries | 4 | scholarship_types | 2 |
| grade_periods | 4 | semester_calendar_events | 2 |
| meeting_attendees | 4 | semesters | 4 |
| meeting_notifications | 4 | students | 9 |
| meetings | 4 | syllabi | 4 |
| teacher_attendance_records | 2 | teachers | 4 |
| thesis_advisors | 2 | thesis_pending_reviews | 2 |
| thesis_progress | 4 | thesis_requirements | 2 |
| thesis_title_history | 2 | todos | 4 |
| users | 3 | | |

**如果之後要逐一核對這些表的policy內容是否合理**（例如懷疑某張表的權限設定跟預期不符），可以用這段查詢單張表：
```sql
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies WHERE schemaname='public' AND tablename='{表名}';
```

---

## 四、本次新增的8張表——完整policy SQL

```sql
-- academic_years（學年度）── key: semesters
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
CREATE POLICY academic_years_public_read ON academic_years FOR SELECT USING (true);
CREATE POLICY academic_years_write ON academic_years FOR ALL
  USING (current_user_can_write('semesters')) WITH CHECK (current_user_can_write('semesters'));

-- course_axes（課程軸）／course_series（課程系列）／course_groups（課群）
-- course_prerequisites（先修課程關聯）／graduation_requirements（畢業學分門檻）── key: courses
-- （四張表policy結構完全相同，只換表名）
CREATE POLICY {table}_public_read ON {table} FOR SELECT USING (true);
CREATE POLICY {table}_write ON {table} FOR ALL
  USING (current_user_can_write('courses')) WITH CHECK (current_user_can_write('courses'));

-- enrollment_settings（選課開放/截止設定）── key: open_courses
CREATE POLICY enrollment_settings_public_read ON enrollment_settings FOR SELECT USING (true);
CREATE POLICY enrollment_settings_write ON enrollment_settings FOR ALL
  USING (current_user_can_write('open_courses')) WITH CHECK (current_user_can_write('open_courses'));

-- conflict_log（排課衝突紀錄）── key: open_courses，內部工具不公開讀取
CREATE POLICY conflict_log_read ON conflict_log FOR SELECT USING (current_user_can_read('open_courses'));
CREATE POLICY conflict_log_write ON conflict_log FOR ALL
  USING (current_user_can_write('open_courses')) WITH CHECK (current_user_can_write('open_courses'));
```

---

## 五、B3權限測試方法（可重複使用）

不用真的切換帳號登入，直接在SQL Editor模擬身份：
```sql
SELECT set_config('request.jwt.claims', '{"sub":"<某帳號的uid>"}', true);
SELECT current_user_can_write('courses'), current_user_can_write('open_courses');
```
每組`set_config`+查詢要分開執行（一次貼整段只會顯示最後一組結果）。

**2026-07-06測試結果**（6種身份 × courses/semesters/open_courses/teachers/classrooms 五個key，全部符合預期）：
admin全部true；staff依`permissions`JSON各key設定值正確反映；teacher/student一律false（寫入）；`conflict_log`讀取權限則依`open_courses`這個key的read等級判斷。
