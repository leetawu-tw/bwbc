-- =====================================================================
-- 權限模組 admission（招生作業）一次性補齊（conventions 規則 6）
-- 對應 admin.html v10.83：PERM_KEYS / PERM_LABELS / DEFAULT_PERM_PRESETS 已加入 admission
-- 只補「缺少 admission key」的權限範本，已設定過的不會被覆蓋；可重複執行。
-- 請分段執行（SQL Editor 一次只顯示最後一段結果，規則 48）。
--
-- ⚠️ 不處理 users 表的 staff 帳號（2026-11-19 實測）：
--   1. users 表有 trigger trg_prevent_users_privilege_escalation，SQL Editor 沒有登入身分，
--      直接 UPDATE permissions 會被還原（RETURNING 看得到列，但值沒變），不要為此關閉 trigger。
--   2. 也不需要補：系統慣例是「缺 key＝無權限」（admin.html normalizePerm()、SQL adm_perm_level() 都這樣判斷），
--      現有 staff 帳號本來就有很多模組沒有 key。要開放招生權限，在 admin.html「帳號管理」逐人設定即可。
-- =====================================================================

-- ① 權限範本（permission_presets）：admin 範本＝admin、主管唯讀＝read、其餘＝none
UPDATE public.permission_presets
SET permissions = coalesce(permissions, '{}'::jsonb) || jsonb_build_object('admission',
      CASE preset_key WHEN 'admin' THEN 'admin' WHEN 'viewer' THEN 'read' ELSE 'none' END)
WHERE jsonb_typeof(coalesce(permissions, '{}'::jsonb)) = 'object'
  AND NOT (coalesce(permissions, '{}'::jsonb) ? 'admission')
RETURNING preset_key, permissions->>'admission' AS admission;

-- ② 驗證：要回傳 0（沒有缺 admission 的權限範本）
SELECT count(*) AS presets_missing
FROM public.permission_presets
WHERE NOT (coalesce(permissions, '{}'::jsonb) ? 'admission');

-- ③ 驗證：admission 的值只能是 none / read / write / admin（範本與已設定的帳號）
SELECT 'preset' AS src, preset_key AS who, permissions->>'admission' AS v FROM public.permission_presets
WHERE permissions ? 'admission' AND permissions->>'admission' NOT IN ('none','read','write','admin')
UNION ALL
SELECT 'user', email, permissions->>'admission' FROM public.users
WHERE permissions ? 'admission' AND permissions->>'admission' NOT IN ('none','read','write','admin')
LIMIT 50;
