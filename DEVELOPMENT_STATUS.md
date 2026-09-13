# Easylearn Institute — Development Status

## Current build: Progress 16

### Implemented
- Supabase Auth + email confirmation/reset
- Multi-institute context and tenant-scoped RLS foundation
- Students CRUD/search/status actions + student photo upload
- Courses CRUD
- Batches CRUD + teacher/course assignment
- Batch ↔ student assignment
- Fees, payments, due calculation/history + monthly fee generation
- Printable payment receipts
- Attendance + history + Leave state
- Routine
- Teachers/Staff + salary
- Expenses + monthly Profit/Loss
- Homework + Assignments
- Exams + Subjects + Results
- Enquiries
- Monthly Reports dashboard
- Institute Settings
- Notifications center
- Role foundation and admin role management
- Student portal with account linking
- Teacher portal with account linking
- Role-aware dashboard and module routing
- RLS hardening for major academic/financial modules
- SaaS subscription plans and 30-day trial lifecycle
- Manual subscription payment submission
- Platform-admin approval/rejection foundation
- Tenant-scoped audit log foundation

### Progress 16 authentication hardening
- Supabase configuration guard and clearer network errors
- Session persistence and recovery URL handling
- Dedicated forgot-password screen
- Password recovery/update screen
- Registration email validation and safer error messages
- `.env.example` and authentication setup documentation

### Progress 18 student management hardening
- Student profile view and photo preview
- Student portal profile photo display
- Explicit account-linking model preserved for student logins

## Still required before production/final release
1. Automated notification rules (due reminders, attendance alerts, subscription expiry alerts).
2. Full report suite, export/download formats and archives.
3. Complete loading/empty/error/offline UX; replace remaining development alerts/prompts.
4. Production compile + browser/mobile E2E test + RLS cross-tenant test.
5. Backup/recovery, logging and error monitoring review.
6. Final UI polish and full Bangla/English localization toggle.
7. Production Super Admin console and controlled platform-admin onboarding.
8. Payment gateway integration if online automatic payments are desired.
9. Final release packaging and deployment verification.

This is still a development build, not the final production release.
