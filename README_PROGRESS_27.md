# Progress 27 — Result + Marksheet + Student Progress

Implemented on top of the existing Progress 26 exam/result module.

- Results Center for management, teachers/staff and students.
- Student-wise result history across exams.
- Exam-wise total, percentage, grade and performance trend.
- Best/average/latest progress summary.
- Subject-wise result history with remarks.
- Printable academic marksheet with institute/student/exam metadata.
- Browser print support for marksheet.
- Student role is restricted to their own result/progress view.
- Added tenant-scoped result performance indexes and uniqueness hardening.

Migration: `supabase/20260913_result_marksheet_progress.sql`
