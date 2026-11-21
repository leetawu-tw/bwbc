-- =====================================================================
-- 招生作業 第 8 批：面試當天臨時改場
-- 2026-11-21
-- 前提：已執行 adm_batch7_sessions.sql（adm_sessions、adm_applicants.session_id／interview_no）
--
-- 考生原本的組別、組號維持不變（已公告、已印在文件上），另外記錄當天實際在哪一組面試：
--   actual_session_id      實際面試的組別（null＝照原組）
--   session_change_note    改場原因（例：塞車，改至第 4 組）
-- 這兩欄不受「分組鎖定」限制（鎖定保護只檢查 session_id、interview_no），當天鎖定後也能登記。
-- =====================================================================

alter table public.adm_applicants add column if not exists actual_session_id   uuid references public.adm_sessions(id) on delete set null;
alter table public.adm_applicants add column if not exists session_change_note text;
create index if not exists adm_applicants_actual_session on public.adm_applicants (actual_session_id);

-- ---------------------------------------------------------------------
-- 驗證（請另開一次單獨執行）
-- ---------------------------------------------------------------------
-- select count(*) as new_cols from information_schema.columns
--  where table_name = 'adm_applicants' and column_name in ('actual_session_id','session_change_note');   -- 預期 2

-- ---------------------------------------------------------------------
-- 還原（需要時才執行）
-- ---------------------------------------------------------------------
-- alter table public.adm_applicants drop column if exists session_change_note;
-- alter table public.adm_applicants drop column if exists actual_session_id;
