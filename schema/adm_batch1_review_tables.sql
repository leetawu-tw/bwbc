-- =====================================================================
-- 佛法應用研究所 招生書審與面試成績系統
-- 第 1 批：書審相關資料表 + RLS
-- 只新增 adm_ 開頭的物件，不修改任何既有資料表。
-- 執行方式：Supabase → SQL Editor → 整段貼上 → Run（可重複執行）
-- 面試場次（adm_sessions、adm_session_slots）留待面試批次再建立。
-- 修改紀錄沿用既有 audit_log，不另建表。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. 權限判斷函式（沿用 admin.html 的權限矩陣）
--    admin → 'admin'
--    staff → users.permissions->'admission'（none/read/write/admin；
--            舊資料若為 true/false，比照 normalizePerm() 轉成 admin/none）
--    其他  → 'none'
--    security definer：users 表若有 RLS，函式仍能讀到本人那一列。
-- ---------------------------------------------------------------------
create or replace function public.adm_perm_level()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select case
      when u.role = 'admin' then 'admin'
      when u.role = 'staff' then
        case
          when jsonb_typeof(u.permissions -> 'admission') = 'boolean'
            then case when (u.permissions ->> 'admission')::boolean then 'admin' else 'none' end
          when u.permissions ->> 'admission' in ('none','read','write','admin')
            then u.permissions ->> 'admission'
          else 'none'
        end
      else 'none'
    end
    from public.users u
    where u.id = auth.uid()
  ), 'none');
$$;

create or replace function public.adm_can_read()
returns boolean language sql stable security definer set search_path = public
as $$ select public.adm_perm_level() in ('read','write','admin'); $$;

create or replace function public.adm_can_write()
returns boolean language sql stable security definer set search_path = public
as $$ select public.adm_perm_level() in ('write','admin'); $$;

revoke all on function public.adm_perm_level() from public, anon;
revoke all on function public.adm_can_read()   from public, anon;
revoke all on function public.adm_can_write()  from public, anon;
grant execute on function public.adm_perm_level() to authenticated;
grant execute on function public.adm_can_read()   to authenticated;
grant execute on function public.adm_can_write()  to authenticated;

-- updated_at 自動更新
create or replace function public.adm_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 1. adm_rounds 招考梯次
-- ---------------------------------------------------------------------
create table if not exists public.adm_rounds (
  id                   uuid primary key default gen_random_uuid(),
  code                 text not null unique,                 -- 116-1、116-2
  academic_year        int  not null,                        -- 入學學年度 116
  term                 smallint not null check (term in (1,2)),
  track                text not null check (track in ('甄試入學','考試入學')),
  name                 text not null,                        -- 116 學年度甄試入學
  pass_threshold       numeric(5,2) default 70,              -- 進入面試門檻；null = 不設門檻
  weight_review        numeric(5,2) not null default 0,      -- 總成績 a%（書審）
  weight_interview     numeric(5,2) not null default 100,    -- 總成績 b%（面試）
  admit_quota          int not null default 15,              -- 正取名額
  waitlist_max         int,                                  -- 備取名額上限；null = 不限
  waitlist_min_score   numeric(5,2),                         -- 備取最低分；null = 不限
  tie_breakers         jsonb not null default '[]'::jsonb,   -- 同分比序：criterion id 或 'interview_total' 的陣列
  decimals             smallint not null default 2,
  age_base_date        date,                                 -- 年齡計算基準日（預設報名截止日）
  key_dates            jsonb not null default '{}'::jsonb,   -- 報名截止、公告、面試、成績通知、複查、放榜、報到
  spread_alert         numeric(5,2) not null default 15,     -- 委員給分差距提示門檻
  near_counties        text[] not null default '{}',         -- 勾選為「雲林附近」的縣市
  interview_settings   jsonb not null default '{}'::jsonb,   -- 面試時間預設值、試場（面試批次使用）
  roster_mask_mode     text not null default 'id_only'
                         check (roster_mask_mode in ('id_only','id_masked_name')),
  review_locked_at     timestamptz,                          -- 書審成績鎖定時間
  admission_locked_at  timestamptz,                          -- 錄取名單鎖定時間
  created_by           uuid default auth.uid(),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint adm_rounds_weight_sum check (weight_review + weight_interview = 100)
);

-- ---------------------------------------------------------------------
-- 2. adm_criteria 評分項目（書審 / 面試）
-- ---------------------------------------------------------------------
create table if not exists public.adm_criteria (
  id            uuid primary key default gen_random_uuid(),
  round_id      uuid not null references public.adm_rounds(id) on delete cascade,
  stage         text not null check (stage in ('review','interview')),
  name          text not null,                    -- 依當年度簡章，例如 個人經歷與省思
  weight        numeric(5,2) not null check (weight >= 0 and weight <= 100),
  max_score     numeric(5,2) not null default 100,
  sort_order    int not null default 0,
  import_label  text,                             -- 匯入 Excel 時對照的欄名（可留空，預設用 name）
  created_at    timestamptz not null default now(),
  unique (round_id, stage, name)
);
-- 各階段權重合計 100% 由前端檢查（跨列條件不適合用 check constraint）

-- ---------------------------------------------------------------------
-- 3. adm_reviewers 委員
-- ---------------------------------------------------------------------
create table if not exists public.adm_reviewers (
  id             uuid primary key default gen_random_uuid(),
  round_id       uuid not null references public.adm_rounds(id) on delete cascade,
  stage          text not null check (stage in ('review','interview')),
  teacher_id     uuid references public.teachers(id) on delete restrict,
  external_name  text,                            -- 外聘委員（不在教師管理中）
  code           text,                            -- 委員代號 A、B、C、D（面試總表用）
  sort_order     int not null default 0,
  created_at     timestamptz not null default now(),
  constraint adm_reviewers_who check (teacher_id is not null or nullif(trim(external_name),'') is not null)
);
create unique index if not exists adm_reviewers_round_stage_teacher
  on public.adm_reviewers (round_id, stage, teacher_id) where teacher_id is not null;

-- ---------------------------------------------------------------------
-- 4. adm_applicants 考生
--    不存身分證字號、戶籍地址。
-- ---------------------------------------------------------------------
create table if not exists public.adm_applicants (
  id                   uuid primary key default gen_random_uuid(),
  round_id             uuid not null references public.adm_rounds(id) on delete cascade,
  reg_no               text,                       -- 報名序號
  exam_no              text not null,              -- 考生編號 RLG26001
  name                 text not null,
  gender               text,
  birth_date           date,
  email                text,                       -- 註冊信箱
  phone                text,
  mobile               text,
  mail_zip             text,
  mail_address         text,                       -- 通訊地址
  county               text,                       -- 由通訊地址取出，可手改
  township             text,                       -- 鄉鎮（判斷古坑用）
  emergency_name       text,
  emergency_relation   text,
  emergency_phone      text,
  applicant_identity   text,                       -- 報考身份別
  edu_qualification    text,                       -- 報考學歷（學歷 / 同等學力）
  edu_level            text,                       -- 教育程度：學士、碩士、專科…
  grad_year            int,
  grad_month           int,
  school_name          text,
  school_short         text,                       -- 學校簡稱（備註字串用，可手改）
  dept_name            text,
  equivalent_note      text,                       -- 同等學歷（力）內容
  background_override  text,                       -- 手動覆寫的基本背景字串；null = 系統自動產生
  research_tag         text,                       -- 承辦人選定的研究類型（分組用）
  review_note          text,                       -- 書審備註
  interview_note       text,                       -- 面試備註
  time_request         jsonb,                      -- 面試時段需求（面試批次使用）
  attendance           text check (attendance in ('present','absent')),
  result               text check (result in ('admitted','waitlisted','rejected')),
  waitlist_no          int,
  enroll_status        text check (enroll_status in ('pending','enrolled','declined')),
  student_no           text,                       -- 轉入學生資料後的學號
  imported_at          timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (round_id, exam_no)
);
create index if not exists adm_applicants_round on public.adm_applicants (round_id);

-- ---------------------------------------------------------------------
-- 5. adm_scores 分數（一位委員 × 一位考生 × 一個項目 = 一筆）
-- ---------------------------------------------------------------------
create table if not exists public.adm_scores (
  id            uuid primary key default gen_random_uuid(),
  round_id      uuid not null references public.adm_rounds(id) on delete cascade,
  applicant_id  uuid not null references public.adm_applicants(id) on delete cascade,
  reviewer_id   uuid not null references public.adm_reviewers(id) on delete cascade,
  criterion_id  uuid not null references public.adm_criteria(id) on delete cascade,
  score         numeric(5,2) check (score >= 0 and score <= 100),
  source        text not null default 'manual' check (source in ('import','manual','paste')),
  updated_by    uuid default auth.uid(),
  updated_at    timestamptz not null default now(),
  unique (applicant_id, reviewer_id, criterion_id)
);
create index if not exists adm_scores_round on public.adm_scores (round_id);

-- ---------------------------------------------------------------------
-- 6. adm_comments 委員評語與研究類型建議（一位委員 × 一位考生 = 一筆）
-- ---------------------------------------------------------------------
create table if not exists public.adm_comments (
  id            uuid primary key default gen_random_uuid(),
  round_id      uuid not null references public.adm_rounds(id) on delete cascade,
  applicant_id  uuid not null references public.adm_applicants(id) on delete cascade,
  reviewer_id   uuid not null references public.adm_reviewers(id) on delete cascade,
  comment       text,
  research_tag  text,                              -- 委員在評分表填的研究類型
  updated_by    uuid default auth.uid(),
  updated_at    timestamptz not null default now(),
  unique (applicant_id, reviewer_id)
);

-- ---------------------------------------------------------------------
-- 7. updated_at triggers
-- ---------------------------------------------------------------------
drop trigger if exists adm_rounds_touch     on public.adm_rounds;
drop trigger if exists adm_applicants_touch on public.adm_applicants;
drop trigger if exists adm_scores_touch     on public.adm_scores;
drop trigger if exists adm_comments_touch   on public.adm_comments;
create trigger adm_rounds_touch     before update on public.adm_rounds     for each row execute function public.adm_touch_updated_at();
create trigger adm_applicants_touch before update on public.adm_applicants for each row execute function public.adm_touch_updated_at();
create trigger adm_scores_touch     before update on public.adm_scores     for each row execute function public.adm_touch_updated_at();
create trigger adm_comments_touch   before update on public.adm_comments   for each row execute function public.adm_touch_updated_at();

-- ---------------------------------------------------------------------
-- 8. 鎖定保護：書審鎖定後不能新增 / 修改 / 刪除書審分數；
--    錄取名單鎖定後不能動面試分數。要改分數必須先在系統「解鎖」（清空鎖定時間）。
-- ---------------------------------------------------------------------
create or replace function public.adm_guard_locked_scores()
returns trigger language plpgsql as $$
declare
  v_round_id     uuid;
  v_criterion_id uuid;
  v_stage        text;
  v_locked       timestamptz;
begin
  v_round_id     := coalesce(new.round_id, old.round_id);
  v_criterion_id := coalesce(new.criterion_id, old.criterion_id);
  select c.stage into v_stage from public.adm_criteria c where c.id = v_criterion_id;
  select case when v_stage = 'review' then r.review_locked_at else r.admission_locked_at end
    into v_locked
    from public.adm_rounds r where r.id = v_round_id;
  if v_locked is not null then
    raise exception '此梯次的%成績已鎖定，請先解鎖再修改', case when v_stage = 'review' then '書審' else '面試' end;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists adm_scores_lock on public.adm_scores;
create trigger adm_scores_lock
  before insert or update or delete on public.adm_scores
  for each row execute function public.adm_guard_locked_scores();

-- ---------------------------------------------------------------------
-- 9. RLS：讀 = admission 權限 read 以上；寫 = write 以上
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['adm_rounds','adm_criteria','adm_reviewers','adm_applicants','adm_scores','adm_comments']
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

-- =====================================================================
-- 10.（可選）建立 116-1 梯次、書審項目與四位書審委員
--     確認上面都成功後再執行這一段；委員依 teachers.name_zh 對應。
-- =====================================================================
/*
with r as (
  insert into public.adm_rounds (code, academic_year, term, track, name, pass_threshold,
                                 weight_review, weight_interview, admit_quota, age_base_date, key_dates)
  values ('116-1', 116, 1, '甄試入學', '116 學年度甄試入學', 70, 0, 100, 15, '2026-11-18',
          '{"apply_deadline":"2026-11-18","interview_list":"2026-12-01","interview":["2026-12-19","2026-12-20"],
            "score_notice":"2026-12-23","review_period":["2026-12-24","2026-12-28"],
            "announce":"2026-12-30","enroll":["2027-01-04","2027-01-05"],"waitlist_from":"2027-01-06"}'::jsonb)
  on conflict (code) do nothing
  returning id
)
insert into public.adm_criteria (round_id, stage, name, weight, sort_order)
select r.id, v.stage, v.name, v.weight, v.sort_order
from r, (values
  ('review',    '個人經歷與省思',     50, 1),
  ('review',    '學習規劃與研究構想', 50, 2),
  ('interview', '學習動機',           50, 1),
  ('interview', '學習潛力',           50, 2)
) as v(stage, name, weight, sort_order);

insert into public.adm_reviewers (round_id, stage, teacher_id, code, sort_order)
select r.id, s.stage, t.id, chr(64 + v.ord), v.ord
from public.adm_rounds r
cross join (values ('review'), ('interview')) as s(stage)
join (values ('曾旭正',1), ('鍾昆原',2), ('張筱雯',3), ('王坤德',4)) as v(name, ord) on true
join public.teachers t on t.name_zh = v.name
where r.code = '116-1'
on conflict do nothing;

-- 檢查：應該看到 4 個項目、8 位委員（書審 4 + 面試 4）
select c.stage, c.name, c.weight from public.adm_criteria c join public.adm_rounds r on r.id = c.round_id where r.code = '116-1' order by c.stage, c.sort_order;
select a.stage, coalesce(t.name_zh, a.external_name) as reviewer, a.code from public.adm_reviewers a
  left join public.teachers t on t.id = a.teacher_id
  join public.adm_rounds r on r.id = a.round_id where r.code = '116-1' order by a.stage, a.sort_order;
*/

-- =====================================================================
-- 復原（如需整批移除，取消註解後執行）
-- =====================================================================
/*
drop table if exists public.adm_comments, public.adm_scores, public.adm_applicants,
                     public.adm_reviewers, public.adm_criteria, public.adm_rounds cascade;
drop function if exists public.adm_guard_locked_scores();
drop function if exists public.adm_touch_updated_at();
drop function if exists public.adm_can_write();
drop function if exists public.adm_can_read();
drop function if exists public.adm_perm_level();
*/
