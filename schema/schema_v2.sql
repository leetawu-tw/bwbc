-- ============================================================
-- 福智佛教學院 課程管理系統
-- Supabase PostgreSQL Schema v2.0（依現有資料庫 information_schema 重新產生）
-- 產生日期：2026-07-04
-- 說明：
--   本檔案取代 v1.0（2026-05-18），依 Supabase SQL Editor 查詢
--   information_schema.columns + information_schema.table_constraints
--   的實際回傳結果重建，確保跟目前線上資料庫結構一致。
--   v1.0 缺少的表格（開發過程中新增，原檔未同步更新）：
--   semester_calendar_events, grade_periods, grade_entries, grade_assignments,
--   conduct_grades, class_advisors, class_sessions, attendance_records,
--   teacher_attendance_records, presentation_*（畢業論文計畫發表會全套）,
--   scholarship_*（獎學金推薦全套）, poll_*（課堂即時投票全套）,
--   thesis_pending_reviews, adjunct_pay_rates, adjunct_payroll, adjunct_payroll_days,
--   announcements, meetings, meeting_attendees, meeting_notifications, todos,
--   attachments, audit_log, course_equivalencies
--
--   本檔案不含：VIEW、FUNCTION、TRIGGER、RLS POLICY、INDEX、bak_* 備份表
--   （備份表為特定時間點快照，不屬於正式schema，故略過；如需要可另外查詢）
--   FOREIGN KEY 目標為 null 的欄位（如 author_id/owner_id）推測是參照
--   Supabase Auth 的 auth.users，而非 public.users，已在對應位置加註解
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- LAYER 1：基礎學術設定
-- ============================================================

-- academic_years
CREATE TABLE academic_years (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  year SMALLINT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (year)
);

-- semesters
CREATE TABLE semesters (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  academic_year SMALLINT NOT NULL,
  semester_num SMALLINT NOT NULL,
  label VARCHAR NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT false,
  PRIMARY KEY (id),
  UNIQUE (label),
  CHECK (semester_num IN (1,2))
);

-- course_axes
CREATE TABLE course_axes (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  code VARCHAR NOT NULL,
  name_zh VARCHAR NOT NULL,
  name_en VARCHAR,
  color_hex VARCHAR,
  sort_order SMALLINT DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- course_series
CREATE TABLE course_series (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  axis_id UUID,
  name_zh VARCHAR NOT NULL,
  name_en VARCHAR,
  sort_order SMALLINT DEFAULT 0,
  PRIMARY KEY (id),
  FOREIGN KEY (axis_id) REFERENCES course_axes(id)
);

-- courses
CREATE TABLE courses (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  code VARCHAR NOT NULL,
  name_zh VARCHAR NOT NULL,
  name_en VARCHAR,
  axis_id UUID,
  series_id UUID,
  credits SMALLINT DEFAULT 2 NOT NULL,
  req_type VARCHAR DEFAULT 'sel'::character varying NOT NULL,
  series_group VARCHAR,
  sequence_num SMALLINT,
  is_cycling BOOLEAN DEFAULT false,
  prev_course_id UUID,
  active BOOLEAN DEFAULT true,
  description TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  is_digital BOOLEAN DEFAULT false,
  is_audit BOOLEAN DEFAULT false,
  inactive_reason TEXT,
  PRIMARY KEY (id),
  UNIQUE (code),
  FOREIGN KEY (axis_id) REFERENCES course_axes(id),
  FOREIGN KEY (prev_course_id) REFERENCES courses(id),
  FOREIGN KEY (series_id) REFERENCES course_series(id),
  CHECK (credits >= 0),
  CHECK (req_type IN ('req','sel','go'))
);

-- course_equivalencies
CREATE TABLE course_equivalencies (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  course_a_id UUID,
  course_b_id UUID,
  note TEXT,
  PRIMARY KEY (id),
  UNIQUE (course_a_id,course_b_id),
  FOREIGN KEY (course_a_id) REFERENCES courses(id),
  FOREIGN KEY (course_b_id) REFERENCES courses(id)
);

-- course_prerequisites
CREATE TABLE course_prerequisites (
  course_id UUID NOT NULL,
  prerequisite_id UUID NOT NULL,
  is_required BOOLEAN DEFAULT false,
  PRIMARY KEY (course_id,prerequisite_id),
  FOREIGN KEY (course_id) REFERENCES courses(id),
  FOREIGN KEY (prerequisite_id) REFERENCES courses(id)
);

-- classrooms
CREATE TABLE classrooms (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  code VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  building VARCHAR,
  floor SMALLINT,
  capacity SMALLINT,
  features JSONB DEFAULT '[]'::jsonb,
  is_offsite BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- course_groups
CREATE TABLE course_groups (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name VARCHAR NOT NULL,
  semester_id UUID,
  required_count SMALLINT DEFAULT 1,
  description TEXT,
  PRIMARY KEY (id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

-- graduation_requirements
CREATE TABLE graduation_requirements (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  cohort_from SMALLINT NOT NULL,
  cohort_to SMALLINT,
  req_credits SMALLINT NOT NULL,
  sel_credits SMALLINT NOT NULL,
  thesis_credits SMALLINT DEFAULT 6,
  total_min SMALLINT DEFAULT 36,
  notes TEXT,
  PRIMARY KEY (id)
);

-- thesis_requirements
CREATE TABLE thesis_requirements (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  cohort_from SMALLINT NOT NULL,
  cohort_to SMALLINT,
  thesis_credits SMALLINT DEFAULT 6,
  min_advisor_meetings SMALLINT DEFAULT 0,
  ethics_required BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  stages JSONB DEFAULT '["申請指導教授", "確認論文題目", "送件學倫審查", "完成論文撰寫"]'::jsonb,
  PRIMARY KEY (id)
);

-- ============================================================
-- LAYER 2：開課、選課與課綱
-- ============================================================

-- course_offerings
CREATE TABLE course_offerings (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  course_id UUID NOT NULL,
  semester_id UUID NOT NULL,
  classroom_id UUID,
  day SMALLINT,
  start_time TIME,
  end_time TIME,
  time_raw VARCHAR,
  group_id UUID,
  max_students SMALLINT,
  is_summer BOOLEAN DEFAULT false,
  is_cancelled BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  week_pattern VARCHAR DEFAULT 'every'::character varying,
  target_cohort SMALLINT,
  attendance_affects_grade BOOLEAN DEFAULT false,
  PRIMARY KEY (id),
  UNIQUE (course_id,semester_id),
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
  FOREIGN KEY (course_id) REFERENCES courses(id),
  FOREIGN KEY (group_id) REFERENCES course_groups(id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id),
  CHECK (day >= 1 AND day <= 5)
);

-- offering_teachers
CREATE TABLE offering_teachers (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  offering_id UUID NOT NULL,
  teacher_id UUID NOT NULL,
  role VARCHAR DEFAULT '共同授課'::character varying,
  weeks VARCHAR,
  sort_order SMALLINT DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE (offering_id,teacher_id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- offering_staff
CREATE TABLE offering_staff (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  offering_id UUID NOT NULL,
  student_id UUID NOT NULL,
  role VARCHAR NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (offering_id,student_id,role),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  CHECK (role IN ('angel','ta','av','recorder'))
);

-- enrollment_settings
CREATE TABLE enrollment_settings (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  semester_id UUID NOT NULL,
  open_at TIMESTAMPTZ NOT NULL,
  close_at TIMESTAMPTZ NOT NULL,
  drop_deadline TIMESTAMPTZ,
  min_credits_default SMALLINT DEFAULT 2,
  min_credits_senior SMALLINT DEFAULT 0,
  max_credits_normal SMALLINT DEFAULT 12,
  max_credits_with_approval SMALLINT DEFAULT 15,
  withdraw_deadline TIMESTAMPTZ,
  PRIMARY KEY (id),
  UNIQUE (semester_id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

-- enrollments
CREATE TABLE enrollments (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  student_id UUID NOT NULL,
  offering_id UUID NOT NULL,
  semester_id UUID NOT NULL,
  status VARCHAR DEFAULT 'pending'::character varying,
  over_credit_request BOOLEAN DEFAULT false,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  director_note TEXT,
  drop_at TIMESTAMPTZ,
  final_grade VARCHAR,
  enrolled_at TIMESTAMPTZ DEFAULT now(),
  withdraw_at TIMESTAMPTZ,
  PRIMARY KEY (id),
  UNIQUE (student_id,offering_id),
  FOREIGN KEY (approved_by) REFERENCES users(id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  CHECK (status IN ('pending','confirmed','rejected','dropped','waitlist','withdrawn')),
  CHECK (status IN ('pending','confirmed','rejected','dropped','waitlist','withdrawn'))
);

-- conflict_log
CREATE TABLE conflict_log (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  semester_id UUID,
  offering_a_id UUID,
  offering_b_id UUID,
  conflict_type VARCHAR NOT NULL,
  affected_id UUID,
  resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID,
  detected_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (offering_a_id) REFERENCES course_offerings(id),
  FOREIGN KEY (offering_b_id) REFERENCES course_offerings(id),
  FOREIGN KEY (resolved_by) REFERENCES users(id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

-- syllabi
CREATE TABLE syllabi (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  offering_id UUID NOT NULL,
  overview_zh TEXT,
  overview_en TEXT,
  objectives JSONB DEFAULT '[]'::jsonb,
  methods JSONB DEFAULT '[]'::jsonb,
  assessment JSONB DEFAULT '[]'::jsonb,
  weeks JSONB DEFAULT '[]'::jsonb,
  bibliography JSONB DEFAULT '{"optional": [], "required": []}'::jsonb,
  notes TEXT,
  pdf_url VARCHAR,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID,
  digital_info JSONB DEFAULT '{}'::jsonb,
  prerequisite_note TEXT,
  cohort_note TEXT,
  ta_needed BOOLEAN,
  ta_requirement_note TEXT,
  PRIMARY KEY (id),
  UNIQUE (offering_id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (updated_by) REFERENCES users(id)
);

-- ============================================================
-- LAYER 3：使用者、教職員、學生
-- ============================================================

-- users
CREATE TABLE users (
  id UUID NOT NULL,
  email VARCHAR NOT NULL,
  role VARCHAR DEFAULT 'teacher'::character varying NOT NULL,
  teacher_id UUID,
  student_id UUID,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  roles TEXT[] DEFAULT '{}'::text[],
  permissions JSONB DEFAULT '{}'::jsonb,
  display_name TEXT,
  department TEXT,
  institute_roles JSONB DEFAULT '[]'::jsonb,
  PRIMARY KEY (id),
  UNIQUE (email),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  CHECK (role IN ('admin','staff','viewer','teacher','student','director'))
);

-- teachers
CREATE TABLE teachers (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name_zh VARCHAR NOT NULL,
  name_en VARCHAR,
  teacher_type VARCHAR DEFAULT 'external'::character varying NOT NULL,
  title VARCHAR,
  affiliation VARCHAR,
  email VARCHAR,
  phone VARCHAR,
  photo_url VARCHAR,
  profile_url VARCHAR,
  bio_zh TEXT,
  bio_en TEXT,
  expertise TEXT[] DEFAULT '{}'::text[],
  series_group VARCHAR,
  show_profile BOOLEAN DEFAULT true,
  active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  experiences JSONB DEFAULT '[]'::jsonb,
  cert_no VARCHAR,
  is_adjunct BOOLEAN DEFAULT false,
  adjunct_type VARCHAR,
  adjunct_rank VARCHAR,
  education TEXT,
  display_order INTEGER DEFAULT 0,
  current_positions JSONB DEFAULT '[]'::jsonb,
  PRIMARY KEY (id),
  UNIQUE (email),
  CHECK (teacher_type IN ('full_time','adjunct','external','guest'))
);

-- students
CREATE TABLE students (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  student_code CHAR NOT NULL,
  name_zh VARCHAR NOT NULL,
  name_en VARCHAR,
  cohort SMALLINT,
  status VARCHAR DEFAULT 'active'::character varying,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  email VARCHAR,
  gender CHAR,
  birth_date DATE,
  nationality VARCHAR DEFAULT 'TW'::character varying,
  id_number VARCHAR,
  school_email VARCHAR,
  personal_email VARCHAR,
  phone VARCHAR,
  address TEXT,
  address_hr TEXT,
  emergency_name VARCHAR,
  emergency_relation VARCHAR,
  emergency_phone VARCHAR,
  enrolled_date DATE,
  expected_graduate DATE,
  actual_graduate DATE,
  prev_education TEXT,
  prev_school VARCHAR,
  guang_lun_class VARCHAR,
  housing VARCHAR,
  photo_url VARCHAR,
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (email),
  UNIQUE (school_email),
  UNIQUE (student_code),
  CHECK (student_code ~ '^\d{8}$'),
  CHECK (gender IS NULL OR gender IN ('M','F','O')),
  CHECK (housing IS NULL OR housing IN ('self_home','eco_village','off_campus','commute','other')),
  CHECK (status IN ('active','leave','graduated','withdrawn'))
);

-- class_advisors
CREATE TABLE class_advisors (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  cohort VARCHAR,
  teacher_id UUID,
  role VARCHAR NOT NULL,
  start_semester UUID NOT NULL,
  end_semester UUID,
  is_current BOOLEAN DEFAULT true,
  reason TEXT,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (end_semester) REFERENCES semesters(id),
  FOREIGN KEY (start_semester) REFERENCES semesters(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  CHECK (role IN ('advisor','director','dean','vice_principal','principal'))
);

-- ============================================================
-- LAYER 4：課堂與點名
-- ============================================================

-- class_sessions
CREATE TABLE class_sessions (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  offering_id UUID NOT NULL,
  session_date DATE NOT NULL,
  is_makeup BOOLEAN DEFAULT false,
  original_date DATE,
  notes VARCHAR,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (offering_id,session_date),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id)
);

-- attendance_records
CREATE TABLE attendance_records (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  session_id UUID NOT NULL,
  student_id UUID NOT NULL,
  status VARCHAR NOT NULL,
  recorded_by UUID,
  recorded_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (session_id,student_id),
  FOREIGN KEY (recorded_by) REFERENCES users(id),
  FOREIGN KEY (session_id) REFERENCES class_sessions(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  CHECK (status IN ('present','absent','leave','late','online'))
);

-- teacher_attendance_records
CREATE TABLE teacher_attendance_records (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  session_id UUID NOT NULL,
  teacher_id UUID NOT NULL,
  status VARCHAR NOT NULL,
  recorded_by UUID,
  recorded_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (session_id,teacher_id),
  FOREIGN KEY (recorded_by) REFERENCES users(id),
  FOREIGN KEY (session_id) REFERENCES class_sessions(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  CHECK (status IN ('present','online','absent','leave'))
);

-- ============================================================
-- LAYER 5：成績與操行
-- ============================================================

-- grade_periods
CREATE TABLE grade_periods (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  semester_id UUID NOT NULL,
  grade_type VARCHAR NOT NULL,
  open_at TIMESTAMPTZ,
  close_at TIMESTAMPTZ,
  grade_scale JSONB DEFAULT '[{"max": 100, "min": 90, "label": "優秀"}, {"max": 89, "min": 80, "label": "良好"}, {"max": 79, "min": 70, "label": "中等"}, {"max": 69, "min": 60, "label": "及格"}, {"max": 59, "min": 0, "label": "不及格"}]'::jsonb NOT NULL,
  is_active BOOLEAN DEFAULT false,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (semester_id,grade_type),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id),
  CHECK (grade_type IN ('academic','conduct'))
);

-- grade_assignments
CREATE TABLE grade_assignments (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  grade_period_id UUID NOT NULL,
  offering_id UUID NOT NULL,
  teacher_id UUID NOT NULL,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (grade_period_id,offering_id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (grade_period_id) REFERENCES grade_periods(id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- grade_entries
CREATE TABLE grade_entries (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  grade_period_id UUID NOT NULL,
  grade_type VARCHAR NOT NULL,
  offering_id UUID,
  cohort VARCHAR,
  teacher_id UUID NOT NULL,
  student_id UUID NOT NULL,
  score NUMERIC,
  grade_label VARCHAR,
  is_withdrawn BOOLEAN DEFAULT false,
  is_suspended BOOLEAN DEFAULT false,
  notes TEXT,
  status VARCHAR DEFAULT 'draft'::character varying,
  submitted_at TIMESTAMPTZ,
  is_locked BOOLEAN DEFAULT false,
  locked_at TIMESTAMPTZ,
  unlocked_by UUID,
  unlocked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  confirmed_by UUID,
  confirmed_at TIMESTAMPTZ,
  confirm_note TEXT,
  unlock_reason TEXT,
  PRIMARY KEY (id),
  UNIQUE (grade_period_id,offering_id,student_id,teacher_id),
  FOREIGN KEY (confirmed_by) REFERENCES users(id),
  FOREIGN KEY (grade_period_id) REFERENCES grade_periods(id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  FOREIGN KEY (unlocked_by) REFERENCES users(id),
  CHECK (grade_type IN ('academic','conduct')),
  CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
  CHECK ((grade_type='academic' AND offering_id IS NOT NULL) OR (grade_type='conduct' AND cohort IS NOT NULL)),
  CHECK (status IN ('draft','submitted','confirmed'))
);

-- conduct_grades
CREATE TABLE conduct_grades (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  student_id UUID NOT NULL,
  semester_id UUID NOT NULL,
  base_score SMALLINT DEFAULT 85 NOT NULL,
  advisor_adj SMALLINT DEFAULT 3 NOT NULL,
  director_adj SMALLINT DEFAULT 3 NOT NULL,
  merit_demerit SMALLINT DEFAULT 0 NOT NULL,
  advisor_id UUID,
  advisor_submitted_at TIMESTAMPTZ,
  director_submitted_at TIMESTAMPTZ,
  status VARCHAR DEFAULT 'draft'::character varying NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (student_id,semester_id),
  FOREIGN KEY (advisor_id) REFERENCES teachers(id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  CHECK (advisor_adj >= -5 AND advisor_adj <= 5),
  CHECK (director_adj >= -5 AND director_adj <= 5),
  CHECK (status IN ('draft','submitted'))
);

-- ============================================================
-- LAYER 6：教學意見調查
-- ============================================================

-- surveys
CREATE TABLE surveys (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  semester_id UUID NOT NULL,
  round VARCHAR NOT NULL,
  title VARCHAR NOT NULL,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  status VARCHAR DEFAULT 'draft'::character varying NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by VARCHAR,
  PRIMARY KEY (id),
  UNIQUE (semester_id,round),
  FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

-- survey_questions
CREATE TABLE survey_questions (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  sort_order SMALLINT DEFAULT 0 NOT NULL,
  question_text TEXT NOT NULL,
  type VARCHAR DEFAULT 'single'::character varying NOT NULL,
  options JSONB DEFAULT '[]'::jsonb,
  required BOOLEAN DEFAULT true,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id)
);

-- survey_responses
CREATE TABLE survey_responses (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  survey_id UUID NOT NULL,
  offering_id UUID NOT NULL,
  teacher_id UUID,
  enrollment_id UUID NOT NULL,
  question_id UUID NOT NULL,
  answer TEXT,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (enrollment_id) REFERENCES enrollments(id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (question_id) REFERENCES survey_questions(id),
  FOREIGN KEY (survey_id) REFERENCES surveys(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- survey_tokens
CREATE TABLE survey_tokens (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  survey_id UUID NOT NULL,
  enrollment_id UUID NOT NULL,
  offering_id UUID NOT NULL,
  student_id UUID NOT NULL,
  teacher_id UUID,
  token VARCHAR NOT NULL,
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (survey_id,enrollment_id),
  UNIQUE (token),
  FOREIGN KEY (enrollment_id) REFERENCES enrollments(id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (survey_id) REFERENCES surveys(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- ============================================================
-- LAYER 7：課堂即時投票
-- ============================================================

-- poll_sets
CREATE TABLE poll_sets (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  teacher_id UUID NOT NULL,
  title VARCHAR NOT NULL,
  is_active BOOLEAN DEFAULT false,
  current_question_index SMALLINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- poll_questions
CREATE TABLE poll_questions (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  poll_set_id UUID NOT NULL,
  sort_order SMALLINT DEFAULT 0 NOT NULL,
  question_text TEXT NOT NULL,
  question_type VARCHAR DEFAULT 'single'::character varying NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (poll_set_id) REFERENCES poll_sets(id)
);

-- poll_options
CREATE TABLE poll_options (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  question_id UUID NOT NULL,
  sort_order SMALLINT DEFAULT 0 NOT NULL,
  option_text VARCHAR NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (question_id) REFERENCES poll_questions(id)
);

-- poll_responses
CREATE TABLE poll_responses (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  question_id UUID NOT NULL,
  option_id UUID NOT NULL,
  device_token VARCHAR NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (question_id,device_token),
  FOREIGN KEY (option_id) REFERENCES poll_options(id),
  FOREIGN KEY (question_id) REFERENCES poll_questions(id)
);

-- ============================================================
-- LAYER 8：畢業論文
-- ============================================================

-- thesis_progress
CREATE TABLE thesis_progress (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  student_id UUID,
  stage SMALLINT DEFAULT 0 NOT NULL,
  advisor_id UUID,
  research_direction TEXT,
  advisor_applied_at TIMESTAMPTZ,
  advisor_note TEXT,
  advisor_approved BOOLEAN,
  advisor_approved_at TIMESTAMPTZ,
  title_zh TEXT,
  title_en TEXT,
  title_confirmed_at TIMESTAMPTZ,
  ethics_submitted_at TIMESTAMPTZ,
  ethics_case_no VARCHAR,
  ethics_approved_at TIMESTAMPTZ,
  ethics_note TEXT,
  defense_date DATE,
  completed_at TIMESTAMPTZ,
  final_grade VARCHAR,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  advisor_status VARCHAR DEFAULT NULL::character varying,
  title_status VARCHAR DEFAULT NULL::character varying,
  ethics_status VARCHAR DEFAULT NULL::character varying,
  suggested_stage SMALLINT DEFAULT 0,
  stage_overridden BOOLEAN DEFAULT false,
  admin_note TEXT,
  PRIMARY KEY (id),
  UNIQUE (student_id),
  FOREIGN KEY (advisor_id) REFERENCES teachers(id),
  FOREIGN KEY (student_id) REFERENCES students(id)
);

-- thesis_advisors
CREATE TABLE thesis_advisors (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  thesis_id UUID,
  teacher_id UUID,
  advisor_role VARCHAR DEFAULT 'main'::character varying,
  sort_order SMALLINT DEFAULT 0,
  status VARCHAR DEFAULT '申請中'::character varying,
  applied_at TIMESTAMPTZ DEFAULT now(),
  approved_at TIMESTAMPTZ,
  note TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  FOREIGN KEY (thesis_id) REFERENCES thesis_progress(id)
);

-- thesis_title_history
CREATE TABLE thesis_title_history (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  thesis_id UUID,
  title_zh TEXT,
  title_en TEXT,
  changed_at TIMESTAMPTZ DEFAULT now(),
  reason TEXT,
  changed_by TEXT,
  PRIMARY KEY (id),
  FOREIGN KEY (thesis_id) REFERENCES thesis_progress(id)
);

-- thesis_pending_reviews
CREATE TABLE thesis_pending_reviews (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  thesis_id UUID,
  student_id UUID,
  review_type VARCHAR,
  content JSONB,
  status VARCHAR DEFAULT 'pending'::character varying,
  requested_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by TEXT,
  note TEXT,
  PRIMARY KEY (id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (thesis_id) REFERENCES thesis_progress(id)
);

-- ============================================================
-- LAYER 9：畢業論文計畫發表會
-- ============================================================

-- presentation_events
CREATE TABLE presentation_events (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  type VARCHAR NOT NULL,
  semester_id UUID NOT NULL,
  event_date DATE NOT NULL,
  start_time TIME,
  duration_minutes_per_person SMALLINT,
  location VARCHAR,
  manual_status VARCHAR,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  score_criteria JSONB DEFAULT '[{"name": "研究背景與動機", "weight": 25}, {"name": "文獻回顧與理論基礎", "weight": 25}, {"name": "研究設計", "weight": 25}, {"name": "佛法應用與跨域整合能力", "weight": 25}]'::jsonb,
  grade_levels JSONB DEFAULT '[{"min": 98, "label": "特優"}, {"min": 90, "label": "優良"}, {"min": 80, "label": "良好"}, {"min": 0, "label": "待改進"}]'::jsonb,
  PRIMARY KEY (id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id),
  CHECK (manual_status IN ('ongoing','completed')),
  CHECK (type IN ('thesis_proposal','summary_report'))
);

-- presentation_judges
CREATE TABLE presentation_judges (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  event_id UUID NOT NULL,
  teacher_id UUID,
  name VARCHAR NOT NULL,
  title VARCHAR,
  meal_pref VARCHAR,
  sort_order SMALLINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (event_id) REFERENCES presentation_events(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- presentation_participants
CREATE TABLE presentation_participants (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  event_id UUID NOT NULL,
  student_id UUID NOT NULL,
  title_zh TEXT,
  intro_text TEXT,
  sort_order SMALLINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (event_id,student_id),
  FOREIGN KEY (event_id) REFERENCES presentation_events(id),
  FOREIGN KEY (student_id) REFERENCES students(id)
);

-- presentation_scores
CREATE TABLE presentation_scores (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  participant_id UUID NOT NULL,
  judge_id UUID NOT NULL,
  criteria_scores JSONB DEFAULT '[]'::jsonb,
  total_score NUMERIC,
  comment TEXT,
  signed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (participant_id,judge_id),
  FOREIGN KEY (judge_id) REFERENCES presentation_judges(id),
  FOREIGN KEY (participant_id) REFERENCES presentation_participants(id)
);

-- presentation_attachments
CREATE TABLE presentation_attachments (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  participant_id UUID NOT NULL,
  file_type VARCHAR NOT NULL,
  file_name VARCHAR NOT NULL,
  storage_path VARCHAR NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (participant_id) REFERENCES presentation_participants(id),
  CHECK (file_type IN ('論文','PPT','其他'))
);

-- presentation_share_links
CREATE TABLE presentation_share_links (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  event_id UUID NOT NULL,
  label VARCHAR,
  token VARCHAR DEFAULT encode(gen_random_bytes(16), 'hex'::text) NOT NULL,
  participant_scope JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (token),
  FOREIGN KEY (event_id) REFERENCES presentation_events(id)
);

-- ============================================================
-- LAYER 10：獎學金推薦
-- ============================================================

-- scholarship_categories
CREATE TABLE scholarship_categories (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  name VARCHAR NOT NULL,
  sort_order SMALLINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id)
);

-- scholarship_types
CREATE TABLE scholarship_types (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  category_id UUID NOT NULL,
  name VARCHAR NOT NULL,
  type_kind VARCHAR NOT NULL,
  external_link VARCHAR,
  sort_order SMALLINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (category_id) REFERENCES scholarship_categories(id),
  CHECK (type_kind IN ('subject_excellence','service','link_external','coming_soon'))
);

-- scholarship_periods
CREATE TABLE scholarship_periods (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  type_id UUID NOT NULL,
  semester_id UUID NOT NULL,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  manual_closed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (semester_id) REFERENCES semesters(id),
  FOREIGN KEY (type_id) REFERENCES scholarship_types(id)
);

-- scholarship_recommendations
CREATE TABLE scholarship_recommendations (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  period_id UUID NOT NULL,
  offering_id UUID NOT NULL,
  teacher_id UUID NOT NULL,
  student_id UUID NOT NULL,
  reason TEXT NOT NULL,
  sort_order SMALLINT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (period_id,offering_id,sort_order),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (period_id) REFERENCES scholarship_periods(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id),
  CHECK (sort_order IN (1,2,3))
);

-- scholarship_confirmations
CREATE TABLE scholarship_confirmations (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  period_id UUID NOT NULL,
  offering_id UUID NOT NULL,
  confirmed_at TIMESTAMPTZ DEFAULT now(),
  confirmed_by UUID,
  PRIMARY KEY (id),
  UNIQUE (period_id,offering_id),
  FOREIGN KEY (confirmed_by) REFERENCES users(id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (period_id) REFERENCES scholarship_periods(id)
);

-- ============================================================
-- LAYER 11：兼任教師鐘點費
-- ============================================================

-- adjunct_pay_rates
CREATE TABLE adjunct_pay_rates (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  rank_name VARCHAR NOT NULL,
  hourly_rate INTEGER NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (rank_name)
);

-- adjunct_payroll
CREATE TABLE adjunct_payroll (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  teacher_id UUID NOT NULL,
  year_month VARCHAR NOT NULL,
  total_hours NUMERIC DEFAULT 0 NOT NULL,
  hourly_rate INTEGER DEFAULT 0 NOT NULL,
  lecture_fee INTEGER DEFAULT 0 NOT NULL,
  lecture_fee_override BOOLEAN DEFAULT false,
  transport_fee INTEGER DEFAULT 0 NOT NULL,
  transport_note TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (teacher_id,year_month),
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- adjunct_payroll_days
CREATE TABLE adjunct_payroll_days (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  payroll_id UUID NOT NULL,
  class_date DATE NOT NULL,
  mode VARCHAR DEFAULT 'inperson'::character varying NOT NULL,
  hours NUMERIC DEFAULT 0 NOT NULL,
  offering_id UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (offering_id) REFERENCES course_offerings(id),
  FOREIGN KEY (payroll_id) REFERENCES adjunct_payroll(id)
);

-- ============================================================
-- LAYER 12：行事曆、公告、會議、待辦
-- ============================================================

-- semester_calendar_events
CREATE TABLE semester_calendar_events (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  semester_id UUID NOT NULL,
  event_key VARCHAR,
  event_label VARCHAR NOT NULL,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ NOT NULL,
  sort_order SMALLINT DEFAULT 0,
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE (semester_id,event_key),
  FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

-- announcements
CREATE TABLE announcements (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  target TEXT DEFAULT 'admin'::text,
  expires_at TIMESTAMPTZ,
  expire_type TEXT,
  is_active BOOLEAN DEFAULT true,
  author_id UUID,
  author_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  -- FOREIGN KEY (author_id) REFERENCES auth.users(id)  -- Supabase auth schema，非public
);

-- meetings
CREATE TABLE meetings (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  title TEXT NOT NULL,
  meeting_date DATE,
  start_time TIME,
  end_time TIME,
  location TEXT,
  description TEXT,
  status TEXT DEFAULT 'upcoming'::text,
  minutes TEXT,
  author_id UUID,
  author_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  -- FOREIGN KEY (author_id) REFERENCES auth.users(id)  -- Supabase auth schema，非public
);

-- meeting_attendees
CREATE TABLE meeting_attendees (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  meeting_id UUID,
  name TEXT NOT NULL,
  title TEXT,
  affiliation TEXT,
  attendee_type TEXT DEFAULT 'custom'::text,
  ref_id UUID,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (meeting_id) REFERENCES meetings(id)
);

-- meeting_notifications
CREATE TABLE meeting_notifications (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  meeting_id UUID,
  email TEXT NOT NULL,
  name TEXT,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  FOREIGN KEY (meeting_id) REFERENCES meetings(id)
);

-- todos
CREATE TABLE todos (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'medium'::text,
  expires_at TIMESTAMPTZ,
  expire_type TEXT,
  is_done BOOLEAN DEFAULT false,
  is_shared BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  owner_id UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id),
  -- FOREIGN KEY (owner_id) REFERENCES auth.users(id)  -- Supabase auth schema，非public
);

-- ============================================================
-- LAYER 13：附件與稽核
-- ============================================================

-- attachments
CREATE TABLE attachments (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  ref_type TEXT NOT NULL,
  ref_id UUID NOT NULL,
  filename TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id)
);

-- audit_log
CREATE TABLE audit_log (
  id UUID DEFAULT gen_random_uuid() NOT NULL,
  user_id UUID,
  action VARCHAR NOT NULL,
  table_name VARCHAR NOT NULL,
  record_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT now(),
  user_email TEXT,
  user_name TEXT,
  category TEXT,
  target_name TEXT,
  detail TEXT,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
