# Easylearn Institute — Final SQL run order

Run the SQL migrations in filename/date order. Existing tables/data must not be deleted.

Final production state includes:
1. Core schema + tenant RLS hardening
2. SaaS subscription tables/functions
3. Institute onboarding + trial subscription
4. Student/teacher photo storage security
5. Fees, attendance, routine, academics, finance, reports and notification alerts
6. Final SaaS Admin + Notice/Announcement security/runtime migration

## Super Admin bootstrap
The `platform_admins` table is intentionally protected. Add the UUID of the intended Super Admin's authenticated user from Supabase Authentication before using the SaaS Admin console:

```sql
insert into public.platform_admins(user_id)
values ('YOUR_AUTH_USER_UUID')
on conflict (user_id) do nothing;
```

Never put a service-role key in frontend code.

## Final 2026-09-13 production additions

The production project also received these final-pass migrations:

- `student_teacher_assignment_recorded_class_system_20260913_v3`
- `teacher_scope_assignment_recorded_security_20260913_v3`
- `restore_homework_and_academic_read_scope_20260913_v2`
- `assignment_submission_teacher_read_scope_20260913`
- `drop_legacy_assignment_policy_20260913`
- `harden_academic_trigger_function_execution_20260913`
- `restore_exams_results_enquiries_20260913`

The canonical source migration for the Student/Teacher feature is included as `20260913_student_teacher_assignment_recorded_class_final.sql`.
