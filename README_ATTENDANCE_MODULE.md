# Attendance Module

Progress 6 adds real Supabase attendance entry.

## UI flow
1. Open Attendance.
2. Select an active Batch.
3. Select a Date.
4. Assigned students load from `batch_students`.
5. Mark each student Present / Absent / Late and optionally add a note.
6. Save Attendance. Existing records for the same institute + batch + student + date are upserted.

## Database migration
Run `supabase/20260911_attendance_module.sql` in Supabase SQL Editor after the existing core/RLS migrations.

The migration adds tenant-safe indexes, a unique attendance key for daily upserts, and RLS policies.
