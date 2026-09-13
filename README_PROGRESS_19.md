# Easylearn Institute — Progress 19

Teacher/Staff Management + Teacher Portal enhancement.

Added teacher/staff photo support using a dedicated `teacher-photos` Supabase Storage bucket with institute-scoped management policies. Teacher management now displays and stores profile photos, and the Teacher Portal shows the linked teacher's photo when available.

Run `supabase/20260913_teacher_staff_portal.sql` after the existing migrations.
