-- Progress 27: Result + Marksheet + Student Progress
-- Uses existing exams, exam_subjects, results and batch_students tables.
create index if not exists idx_results_institute_student_created
  on public.results(institute_id, student_id, created_at desc);

create index if not exists idx_results_institute_exam_student
  on public.results(institute_id, exam_id, student_id);

-- Keep result records tenant-scoped and prevent duplicate subject rows per student.
create unique index if not exists uq_results_exam_subject_student
  on public.results(institute_id, exam_subject_id, student_id);
