-- ============================================================
-- 遠距教學課程 教學品質調查（2026-10-14 已於正式資料庫執行）
-- 設計：不新增調查/連結，數位課程(courses.is_digital=true)的填答連結
--       在原本一般題之後多帶出 kind='remote' 的 8 題。
-- 1. survey_questions 新增 kind 欄位（既有題目 = 'general'）
-- 2. 放入 8 題遠距題（sort_order 101~108；第1~7題五級滿意度、第8題開放題選填）
-- 3. 更新 get_survey_form_by_token / submit_survey_response
-- ⚠️ 步驟2 以 question_text 判斷是否已存在；若之後改過題目文字再重跑本檔，會重複新增，
--    要改題目請直接 UPDATE（見檔案最後的範例），不要重跑整份。
-- ============================================================

ALTER TABLE survey_questions
  ADD COLUMN IF NOT EXISTS kind varchar NOT NULL DEFAULT 'general';

ALTER TABLE survey_questions DROP CONSTRAINT IF EXISTS survey_questions_kind_check;
ALTER TABLE survey_questions
  ADD CONSTRAINT survey_questions_kind_check CHECK (kind IN ('general','remote'));

INSERT INTO survey_questions (sort_order, question_text, type, options, required, active, kind)
SELECT v.sort_order, v.question_text, v.type, v.options::jsonb, v.required, true, 'remote'
FROM (VALUES
  (101, '您對「同步」遠距教學軟體的使用滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (102, '您對「非同步」遠距教學軟體的使用滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (103, '您對教師實施「同步」遠距教學的滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (104, '您對教師實施「非同步」遠距教學的滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (105, '您對 Moodle 或 Elearning 平台能完整紀錄學生學習歷程的滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (106, '您對 Moodle 或 Elearning 平台的整體使用滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (107, '您對教師在遠距教學期間，提供各項學習協助的滿意度？', 'single', '["非常滿意","滿意","尚可","不滿意","非常不滿意"]', true),
  (108, '對於學校提供的遠距教學服務與整體規劃，請寫下您的具體建議與回饋：', 'text', '[]', false)
) AS v(sort_order, question_text, type, options, required)
WHERE NOT EXISTS (
  SELECT 1 FROM survey_questions q WHERE q.kind = 'remote' AND q.question_text = v.question_text
);

CREATE OR REPLACE FUNCTION public.get_survey_form_by_token(p_token text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_token_row survey_tokens%ROWTYPE;
  v_survey_row surveys%ROWTYPE;
  v_course JSON;
  v_teacher_name TEXT;
  v_questions JSON;
  v_is_digital BOOLEAN := false;
BEGIN
  SELECT * INTO v_token_row FROM survey_tokens WHERE token = p_token;
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'invalid_token');
  END IF;

  SELECT * INTO v_survey_row FROM surveys WHERE id = v_token_row.survey_id;
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'survey_not_found');
  END IF;

  SELECT json_build_object('name_zh', name_zh, 'code', code, 'time_raw', time_raw)
  INTO v_course
  FROM v_course_schedule WHERE offering_id = v_token_row.offering_id;

  IF v_token_row.teacher_id IS NOT NULL THEN
    SELECT name_zh INTO v_teacher_name FROM teachers WHERE id = v_token_row.teacher_id;
  END IF;

  SELECT COALESCE(c.is_digital, false) INTO v_is_digital
  FROM course_offerings o JOIN courses c ON c.id = o.course_id
  WHERE o.id = v_token_row.offering_id;
  v_is_digital := COALESCE(v_is_digital, false);

  SELECT json_agg(json_build_object(
    'id', id, 'question_text', question_text, 'type', type,
    'options', options, 'required', required, 'sort_order', sort_order,
    'kind', kind
  ) ORDER BY (kind = 'remote'), sort_order)
  INTO v_questions
  FROM survey_questions
  WHERE active = true
    AND (kind = 'general' OR (kind = 'remote' AND v_is_digital));

  RETURN json_build_object(
    'token_used', v_token_row.used,
    'is_digital', v_is_digital,
    'survey', json_build_object(
      'id', v_survey_row.id, 'title', v_survey_row.title, 'status', v_survey_row.status,
      'start_at', v_survey_row.start_at, 'end_at', v_survey_row.end_at
    ),
    'course', v_course,
    'teacher_name', v_teacher_name,
    'questions', COALESCE(v_questions, '[]'::json)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_survey_response(p_token text, p_answers jsonb)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_token_row survey_tokens%ROWTYPE;
  v_answer JSONB;
  v_is_digital BOOLEAN := false;
BEGIN
  SELECT * INTO v_token_row FROM survey_tokens WHERE token = p_token;
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'invalid_token');
  END IF;

  IF v_token_row.used THEN
    RETURN json_build_object('success', false, 'error', 'already_used');
  END IF;

  SELECT COALESCE(c.is_digital, false) INTO v_is_digital
  FROM course_offerings o JOIN courses c ON c.id = o.course_id
  WHERE o.id = v_token_row.offering_id;
  v_is_digital := COALESCE(v_is_digital, false);

  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    IF EXISTS (
      SELECT 1 FROM survey_questions q
      WHERE q.id = (v_answer->>'question_id')::uuid
        AND (q.kind = 'general' OR v_is_digital)
    ) THEN
      INSERT INTO survey_responses (survey_id, offering_id, teacher_id, enrollment_id, question_id, answer)
      VALUES (
        v_token_row.survey_id, v_token_row.offering_id, v_token_row.teacher_id, v_token_row.enrollment_id,
        (v_answer->>'question_id')::uuid, v_answer->>'answer'
      );
    END IF;
  END LOOP;

  UPDATE survey_tokens SET used = true, used_at = now() WHERE id = v_token_row.id;

  RETURN json_build_object('success', true);
END;
$function$;

-- 之後要改題目文字或選項，直接 UPDATE，例如：
-- UPDATE survey_questions SET question_text = '新的題目文字'
-- WHERE kind = 'remote' AND sort_order = 105;
SELECT kind, count(*) AS 題數 FROM survey_questions GROUP BY kind ORDER BY kind;
