-- ═══════════════════════════════════════════════════════════
-- 校庫填報：各表「補充說明」（admin v10.77）
-- 一張表＋一個學期一筆，例如 ('sch15','115-1','論文學分數不包含在學科學分裡。')
-- 在 Supabase SQL Editor 整段執行一次即可（可重複執行）
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS udb_report_notes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_code varchar(20) NOT NULL,          -- stu14 / sch14 / sch15 / tea12
  period      varchar(10) NOT NULL,          -- 學期標籤，例如 115-1
  note        text,
  updated_at  timestamptz DEFAULT now(),
  updated_by  uuid DEFAULT auth.uid(),
  CONSTRAINT udb_report_notes_uniq UNIQUE (report_code, period)
);

ALTER TABLE udb_report_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS udb_report_notes_admin ON udb_report_notes;
CREATE POLICY udb_report_notes_admin ON udb_report_notes FOR ALL
  USING (current_user_role() IN ('admin','director'))
  WITH CHECK (current_user_role() IN ('admin','director'));

-- 規則43：SQL Editor 建的表要另外 GRANT
GRANT ALL ON udb_report_notes TO authenticated;

-- 驗證（應回傳 1 列 policy）
SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename = 'udb_report_notes';
