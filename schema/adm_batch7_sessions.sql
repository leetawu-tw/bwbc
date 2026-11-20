-- =====================================================================
-- 招生作業 第 7 批：面試分組與場次
-- 2026-11-21（含委員迴避、特殊需求）
-- 前提：已執行 adm_batch1_review_tables.sql（adm_can_read / adm_can_write、adm_rounds、adm_applicants）
--
-- 1. adm_sessions          面試組別（＝場次）：順序、各時間點
-- 2. adm_applicants 加欄位  session_id（所屬組別）、interview_no（組號，如 23、A1）
-- 3. adm_rounds 加欄位      sessions_locked_at（分組鎖定時間）
-- 4. 鎖定保護 trigger        分組鎖定後，資料庫直接擋下組別與組號的變動
-- 5. adm_applicants 加欄位  special_needs（特殊需求：行動不便、延長時間、視訊面試…）
-- 6. adm_recusals          委員迴避（書審、面試都適用；迴避的委員不評該考生，平均時不計）
-- 7. RLS 與 GRANT           與第 1 批相同：讀取 adm_can_read()、寫入 adm_can_write()
--
-- 面試設定（日期、試場、時間規則、地區簡稱、公告顯示）存在既有的 adm_rounds.interview_settings（jsonb），不需改結構。
-- 考生時間要求存在既有的 adm_applicants.time_request（jsonb）：
--   { "rules": [ {"kind":"am"} | {"kind":"pm"} | {"kind":"session","seq":1}
--               | {"kind":"after","time":"11:00"} | {"kind":"before","time":"14:00"} ],
--     "text": "自由文字（只顯示提醒）" }
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. adm_sessions 面試組別（一組＝一場）
--    seq：組別順序 1～35（組別碼 1～9、A～Z）；時間一律存 'HH:MM' 字串
--    不設 unique(round_id, seq)：拖曳調換組別順序時會逐筆更新，暫時重複是正常的
-- ---------------------------------------------------------------------
create table if not exists public.adm_sessions (
  id              uuid primary key default gen_random_uuid(),
  round_id        uuid not null references public.adm_rounds(id) on delete cascade,
  seq             int  not null check (seq between 1 and 35),
  report_time     text check (report_time  ~ '^\d{2}:\d{2}$'),   -- 報到
  intro_start     text check (intro_start  ~ '^\d{2}:\d{2}$'),   -- 小組互動（考生自介）開始
  intro_end       text check (intro_end    ~ '^\d{2}:\d{2}$'),   -- 小組互動結束
  start_time      text check (start_time   ~ '^\d{2}:\d{2}$'),   -- 團體面試開始
  end_time        text check (end_time     ~ '^\d{2}:\d{2}$'),   -- 團體面試結束
  times_manual    boolean not null default false,                 -- true＝承辦人手改過時間，重新計算時不覆蓋
  note            text,                                           -- 備註（公告「備註」欄可手改；空白＝系統自動產生地區組成）
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists adm_sessions_round on public.adm_sessions (round_id, seq);

drop trigger if exists adm_sessions_touch on public.adm_sessions;
create trigger adm_sessions_touch before update on public.adm_sessions
  for each row execute function public.adm_touch_updated_at();

-- ---------------------------------------------------------------------
-- 2. adm_applicants：所屬組別、組號
--    組號兩碼：第 1 碼組別（1～9、A～Z），第 2 碼組內序號（1～9，依考生編號由小到大）
-- ---------------------------------------------------------------------
alter table public.adm_applicants add column if not exists session_id   uuid references public.adm_sessions(id) on delete set null;
alter table public.adm_applicants add column if not exists interview_no text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'adm_applicants_interview_no_chk') then
    alter table public.adm_applicants add constraint adm_applicants_interview_no_chk
      check (interview_no is null or interview_no ~ '^[1-9A-Z][1-9]$');
  end if;
end $$;
create index if not exists adm_applicants_session on public.adm_applicants (session_id);

-- ---------------------------------------------------------------------
-- 3. adm_rounds：分組鎖定時間
-- ---------------------------------------------------------------------
alter table public.adm_rounds add column if not exists sessions_locked_at timestamptz;

-- ---------------------------------------------------------------------
-- 4. 鎖定保護：分組鎖定後不能改組別、組號、場次時間
-- ---------------------------------------------------------------------
create or replace function public.adm_guard_locked_sessions()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  rid uuid;
  locked timestamptz;
begin
  if tg_table_name = 'adm_sessions' then
    rid := coalesce(new.round_id, old.round_id);
  else
    -- adm_applicants：只檢查組別、組號有沒有變
    if new.session_id is not distinct from old.session_id
       and new.interview_no is not distinct from old.interview_no then
      return new;
    end if;
    rid := new.round_id;
  end if;
  select sessions_locked_at into locked from public.adm_rounds where id = rid;
  if locked is not null then
    raise exception '此梯次的面試分組已鎖定，請先解除鎖定再修改';
  end if;
  return coalesce(new, old);
end $$;
revoke all on function public.adm_guard_locked_sessions() from public, anon;

drop trigger if exists adm_sessions_lock on public.adm_sessions;
create trigger adm_sessions_lock before insert or update or delete on public.adm_sessions
  for each row execute function public.adm_guard_locked_sessions();

drop trigger if exists adm_applicants_session_lock on public.adm_applicants;
create trigger adm_applicants_session_lock before update on public.adm_applicants
  for each row execute function public.adm_guard_locked_sessions();

-- ---------------------------------------------------------------------
-- 5. adm_applicants：特殊需求（印在試務人員用的場次表、報到表）
-- ---------------------------------------------------------------------
alter table public.adm_applicants add column if not exists special_needs text;

-- ---------------------------------------------------------------------
-- 6. adm_recusals 委員迴避：一位委員 × 一位考生 = 一筆
--    reviewer_id 指向 adm_reviewers（委員本身就分書審／面試階段）
-- ---------------------------------------------------------------------
create table if not exists public.adm_recusals (
  id             uuid primary key default gen_random_uuid(),
  round_id       uuid not null references public.adm_rounds(id) on delete cascade,
  reviewer_id    uuid not null references public.adm_reviewers(id) on delete cascade,
  applicant_id   uuid not null references public.adm_applicants(id) on delete cascade,
  reason         text,                                   -- 例：親屬、師生、同事
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (reviewer_id, applicant_id)
);
create index if not exists adm_recusals_round on public.adm_recusals (round_id);

drop trigger if exists adm_recusals_touch on public.adm_recusals;
create trigger adm_recusals_touch before update on public.adm_recusals
  for each row execute function public.adm_touch_updated_at();

-- ---------------------------------------------------------------------
-- 7. RLS 與 GRANT（同第 1 批）
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['adm_sessions','adm_recusals']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_select', t);
    execute format('drop policy if exists %I on public.%I', t || '_insert', t);
    execute format('drop policy if exists %I on public.%I', t || '_update', t);
    execute format('drop policy if exists %I on public.%I', t || '_delete', t);
    execute format('create policy %I on public.%I for select to authenticated using (public.adm_can_read())', t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.adm_can_write())', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.adm_can_write()) with check (public.adm_can_write())', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.adm_can_write())', t || '_delete', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 8. 驗證（請另開一次單獨執行；SQL Editor 只顯示最後一個結果）
-- ---------------------------------------------------------------------
-- select
--   (select count(*) from information_schema.columns where table_name = 'adm_sessions')                                   as sessions_cols,  -- 預期 12
--   (select count(*) from information_schema.columns where table_name = 'adm_recusals')                                   as recusal_cols,   -- 預期 7
--   (select count(*) from information_schema.columns where table_name = 'adm_applicants'
--      and column_name in ('session_id','interview_no','special_needs'))                                                   as applicant_cols, -- 預期 3
--   (select count(*) from information_schema.columns where table_name = 'adm_rounds' and column_name = 'sessions_locked_at') as round_col,     -- 預期 1
--   (select count(*) from pg_policies where tablename in ('adm_sessions','adm_recusals'))                                  as policies,       -- 預期 8
--   (select bool_and(relrowsecurity) from pg_class where relname in ('adm_sessions','adm_recusals'))                      as rls_on;         -- 預期 true

-- ---------------------------------------------------------------------
-- 還原（需要時才執行）
-- ---------------------------------------------------------------------
-- drop table if exists public.adm_recusals;
-- alter table public.adm_applicants drop column if exists special_needs;
-- drop trigger if exists adm_applicants_session_lock on public.adm_applicants;
-- alter table public.adm_applicants drop column if exists interview_no;
-- alter table public.adm_applicants drop column if exists session_id;
-- alter table public.adm_rounds drop column if exists sessions_locked_at;
-- drop table if exists public.adm_sessions;
-- drop function if exists public.adm_guard_locked_sessions();
