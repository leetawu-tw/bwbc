-- ═══════════════════════════════════════════════════════════
-- 校庫填報 教12：專任教師授課時數（admin v10.78）
-- 1. 職級費率設定加上「每週基本授課時數」
-- 2. 新增 udb_teacher_load：每學期 × 每位專任老師一筆
-- 在 Supabase SQL Editor 整段執行一次即可（可重複執行）
-- ═══════════════════════════════════════════════════════════

-- 1. 每週基本授課時數（教授 8、副教授 9、助理教授 9）
ALTER TABLE adjunct_pay_rates ADD COLUMN IF NOT EXISTS weekly_base_hours numeric(4,1);
UPDATE adjunct_pay_rates SET weekly_base_hours = 8 WHERE rank_name = '教授'     AND weekly_base_hours IS NULL;
UPDATE adjunct_pay_rates SET weekly_base_hours = 9 WHERE rank_name = '副教授'   AND weekly_base_hours IS NULL;
UPDATE adjunct_pay_rates SET weekly_base_hours = 9 WHERE rank_name = '助理教授' AND weekly_base_hours IS NULL;

-- 2. 教12 每學期資料
CREATE TABLE IF NOT EXISTS udb_teacher_load (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  semester_id      uuid NOT NULL REFERENCES semesters(id),
  teacher_id       uuid NOT NULL REFERENCES teachers(id),
  rank_name        varchar(10),              -- 職級（教授／副教授／助理教授），空白時依職稱判斷
  unit_code        integer DEFAULT 7504,     -- 7504 佛法應用研究所／3163 佛法與科學研究中心
  actual_hours     numeric(5,1),             -- 實際每週授課時數（空白＝依課表自動計算）
  admin_hours      numeric(5,1),             -- 兼任行政職或執行專案計畫
  thesis_hours     numeric(5,1),             -- 論文指導教授
  merit_hours      numeric(5,1),             -- 教學、研究、服務績效卓著者
  new_hours        numeric(5,1),             -- 新進或擔任客、講座
  course_hours     numeric(5,1),             -- 課程安排因素
  leave_hours      numeric(5,1),             -- 申請休假、進修或研究等
  secondment_hours numeric(5,1),             -- 借調或合聘教師
  other_hours      numeric(5,1),             -- 其他
  other_reason     text,                     -- 其他原因
  note             text,                     -- 補充說明
  updated_at       timestamptz DEFAULT now(),
  updated_by       uuid DEFAULT auth.uid(),
  CONSTRAINT udb_teacher_load_uniq UNIQUE (semester_id, teacher_id)
);

ALTER TABLE udb_teacher_load ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS udb_teacher_load_admin ON udb_teacher_load;
CREATE POLICY udb_teacher_load_admin ON udb_teacher_load FOR ALL
  USING (current_user_role() IN ('admin','director'))
  WITH CHECK (current_user_role() IN ('admin','director'));
GRANT ALL ON udb_teacher_load TO authenticated;   -- 規則43

-- 驗證：應看到三個職級的基本時數，以及 1 列 policy
SELECT rank_name, hourly_rate, weekly_base_hours FROM adjunct_pay_rates ORDER BY hourly_rate DESC;
