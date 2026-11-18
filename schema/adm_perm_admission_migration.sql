-- =====================================================================
-- 權限模組 admission（招生作業）一次性補齊（conventions 規則 6）
-- 對應 admin.html v10.83：PERM_KEYS / PERM_LABELS / DEFAULT_PERM_PRESETS 已加入 admission
-- 只補「缺少 admission key」的記錄，已設定過的不會被覆蓋；可重複執行。
-- 請分段執行（SQL Editor 一次只顯示最後一段結果，規則 48）。
-- =====================================================================

-- ① 權限範本（permission_presets）：admin 範本＝admin、主管唯讀＝read、其餘＝none
UPDATE public.permission_presets
SET permissions = coalesce(permissions, '{}'::jsonb) || jsonb_build_object('admission',
      CASE preset_key WHEN 'admin' THEN 'admin' WHEN 'viewer' THEN 'read' ELSE 'none' END)
WHERE NOT (coalesce(permissions, '{}'::jsonb) ? 'admission')
RETURNING preset_key, permissions->>'admission' AS admission;

-- ② staff 帳號：缺 admission key 的一律補 'none'（要開放的人，之後在「帳號管理」個別設定）
UPDATE public.users
SET permissions = coalesce(permissions, '{}'::jsonb) || '{"admission":"none"}'::jsonb
WHERE role = 'staff' AND NOT (coalesce(permissions, '{}'::jsonb) ? 'admission')
RETURNING email, permissions->>'admission' AS admission;

-- ③ 驗證：兩個數字都要是 0（沒有殘留缺 key 的記錄）
SELECT
  (SELECT count(*) FROM public.permission_presets WHERE NOT (coalesce(permissions,'{}'::jsonb) ? 'admission')) AS presets_missing,
  (SELECT count(*) FROM public.users WHERE role = 'staff' AND NOT (coalesce(permissions,'{}'::jsonb) ? 'admission')) AS staff_missing;

-- ④ 驗證：admission 的值只能是 none / read / write / admin（不應出現 true/false 或其他字）
SELECT 'preset' AS src, preset_key AS who, permissions->>'admission' AS v FROM public.permission_presets
WHERE permissions->>'admission' NOT IN ('none','read','write','admin')
UNION ALL
SELECT 'user', email, permissions->>'admission' FROM public.users
WHERE role = 'staff' AND permissions->>'admission' NOT IN ('none','read','write','admin')
LIMIT 50;
