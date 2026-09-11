# Final verification checklist

This package was checked before delivery for:

1. Blueprint coverage: auth, tenant, students, staff, courses, batches, attendance, fees/payments, receipt RPC, routine, homework, assignments, exams/results, enquiries, salary, expenses, profit/loss/report navigation, notifications, archives/settings, subscription foundation.
2. Database dependency order: one self-contained `supabase/00_MASTER_BOOTSTRAP.sql` creates missing tables first, then columns/indexes/RLS/functions.
3. Tenant isolation: tenant tables use `institute_id` and PostgreSQL RLS; student own-data read is restricted for student role.
4. Financial integrity: payment creation is atomic through `create_payment_and_receipt`; receipt numbers are tenant-scoped unique; overpayment is rejected.
5. Registration bootstrap: new Supabase Auth users receive an institute/profile through a database trigger.
6. Existing deployments: `create table if not exists` and `add column if not exists` are used to preserve existing data.
7. Frontend role bootstrap: missing RPC no longer defaults to student; admin is the safe owner bootstrap.
8. Client secret check: only publishable/anon Supabase key is referenced; no service_role key is included.

Important: this environment has no Flutter SDK, so a real `flutter analyze`/`flutter build` could not be executed here. The ZIP includes `SETUP_WINDOWS.bat`, which generates the standard Flutter platform folders and installs dependencies on Windows. Live Supabase/RLS behavior must be verified against the user's project after running the single bootstrap SQL.
