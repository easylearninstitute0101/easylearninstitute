# Easylearn Institute — Progress 14

Implemented next production modules on top of Progress 13:
- Student photo upload using Supabase Storage (`student-photos`)
- Student photo display in student list and edit form
- Corrected new student creation so `user_id` stays NULL until an admin explicitly links a portal account
- Printable payment receipts with institute/student/payment details and browser print
- Monthly fee generation by active batch, billing month, fee type, amount and due date
- Duplicate protection for monthly fees using a tenant-scoped unique index

## SQL run order
Run this migration **after** the Progress 13 security migration:
`supabase/20260911_student_photos_monthly_receipts.sql`

Do not expose a Supabase service-role key in the frontend.
