# Easylearn Institute — Progress 13

This build advances the Blueprint's role/permission and login-portal requirements.

Added:
- Admin-only Roles & Permissions screen.
- Secure role-change RPC: admin can assign admin/manager/teacher/staff/student.
- Secure portal-link RPC connecting an auth account to a student or teacher record.
- Teacher `user_id` field.
- Student portal: own profile, batches, fees, attendance and results.
- Teacher portal: assigned batches, routine, homework and assignments.
- Role-aware dashboard and navigation restrictions.
- RLS hardening so students cannot read other students' financial/attendance/result records and non-management roles cannot edit management/finance data through the client.

Remaining major production work includes Storage/photo upload, receipts, recurring fees, full reports/audit logs, SaaS subscription + Super Admin, automated notifications, comprehensive UX states, E2E/RLS testing, backup/recovery and release hardening.
