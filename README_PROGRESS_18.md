# Easylearn Institute — Progress 18

## Student Management + Photo + Student Portal hardening
- Student list now includes a dedicated View Profile action.
- Student profile page shows photo, identity, contact, guardian, admission and address details.
- Student photo upload keeps JPG/PNG/WebP validation and 2 MB limit.
- Added live photo preview before save.
- New student creation remains unlinked (`user_id = null`) until an admin explicitly links a student account.
- Student Portal now displays the linked student's stored photo when available.
- Existing Supabase-backed student CRUD, status actions, search/filter and portal data remain intact.

This is a development build; production auth, RLS, storage and E2E verification remain required before release.
