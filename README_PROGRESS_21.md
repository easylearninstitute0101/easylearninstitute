# Easylearn Institute — Progress 21

Batch + Student Enrollment milestone.

Verified implementation:
- Batch CRUD remains tenant-scoped.
- Active course/teacher/student lookups are institute-scoped.
- Students can be assigned/unassigned per batch.
- Enrollment writes include institute_id.
- Existing enrollment rows are detected before insert to prevent duplicate assignment.
- Unassignment is batch + institute scoped.
- Batch list includes a dedicated Students action.
- Student portal continues to read assigned batches through batch_students.
- Existing role/RLS structure is preserved; no frontend-only tenant security is introduced.

This is a development milestone, not the final production release.
