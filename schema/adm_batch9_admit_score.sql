-- =====================================================================
-- 招生作業 第 9 批：正取最低分數
-- 2026-11-21
-- 前提：已執行 adm_batch1_review_tables.sql（adm_rounds）
--
-- admit_min_score  正取最低分數（空白＝不設）
-- admit_rule       正取名額與正取最低分數都有填時的處理規則：
--                    both  ＝兩者都要符合（最多 N 名且 ≥ 最低分數；不足額錄取）
--                    quota ＝名額優先（錄滿 N 名；最低分數只提醒）
--                    score ＝分數優先（≥ 最低分數全部正取，可能超過名額；名額只提醒）
-- 備取另依 waitlist_min_score（備取最低分數）判斷，不受正取最低分數影響。
-- =====================================================================

alter table public.adm_rounds add column if not exists admit_min_score numeric(6,2);
alter table public.adm_rounds add column if not exists admit_rule text not null default 'both';
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'adm_rounds_admit_min_score_chk') then
    alter table public.adm_rounds add constraint adm_rounds_admit_min_score_chk
      check (admit_min_score is null or (admit_min_score >= 0 and admit_min_score <= 100));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'adm_rounds_admit_rule_chk') then
    alter table public.adm_rounds add constraint adm_rounds_admit_rule_chk check (admit_rule in ('both', 'quota', 'score'));
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 驗證（請另開一次單獨執行）
-- ---------------------------------------------------------------------
-- select count(*) as new_cols from information_schema.columns
--  where table_name = 'adm_rounds' and column_name in ('admit_min_score','admit_rule');   -- 預期 2

-- ---------------------------------------------------------------------
-- 還原（需要時才執行）
-- ---------------------------------------------------------------------
-- alter table public.adm_rounds drop column if exists admit_rule;
-- alter table public.adm_rounds drop column if exists admit_min_score;
