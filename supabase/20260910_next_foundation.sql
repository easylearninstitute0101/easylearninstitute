-- Easylearn Institute: next backend foundation
-- Run after the existing core schema/RLS migration.

create index if not exists idx_students_institute_status
  on public.students(institute_id, status);

create index if not exists idx_batch_students_institute_batch
  on public.batch_students(institute_id, batch_id);

create index if not exists idx_fees_institute_student_status
  on public.fees(institute_id, student_id, status);

create index if not exists idx_fee_payments_institute_student_paid_at
  on public.fee_payments(institute_id, student_id, paid_at desc);

create index if not exists idx_attendance_institute_batch_date
  on public.attendance(institute_id, batch_id, date);

create index if not exists idx_routines_institute_batch
  on public.routines(institute_id, batch_id);

create index if not exists idx_expenses_institute_date
  on public.expenses(institute_id, expense_date);

create index if not exists idx_salaries_institute_staff_month
  on public.salaries(institute_id, staff_id, month);

-- Student IDs must be unique inside an institute.
create unique index if not exists uq_students_institute_student_id
  on public.students(institute_id, student_id);
