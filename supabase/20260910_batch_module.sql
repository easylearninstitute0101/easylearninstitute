-- Easylearn Institute: Batch module hardening
-- Run after the existing core schema and Courses migration.

create index if not exists idx_batches_institute_course on public.batches(institute_id, course_id);
create index if not exists idx_batches_institute_teacher on public.batches(institute_id, teacher_id);
create index if not exists idx_batch_students_institute_student on public.batch_students(institute_id, student_id);

alter table public.batches enable row level security;
alter table public.batch_students enable row level security;

drop policy if exists "Institute members can view batches" on public.batches;
drop policy if exists "Institute members can insert batches" on public.batches;
drop policy if exists "Institute members can update batches" on public.batches;
drop policy if exists "Institute members can delete batches" on public.batches;
create policy "Institute members can view batches" on public.batches for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert batches" on public.batches for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update batches" on public.batches for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete batches" on public.batches for delete to authenticated using (institute_id = public.get_my_institute_id());

drop policy if exists "Institute members can view batch_students" on public.batch_students;
drop policy if exists "Institute members can insert batch_students" on public.batch_students;
drop policy if exists "Institute members can update batch_students" on public.batch_students;
drop policy if exists "Institute members can delete batch_students" on public.batch_students;
create policy "Institute members can view batch_students" on public.batch_students for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert batch_students" on public.batch_students for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update batch_students" on public.batch_students for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete batch_students" on public.batch_students for delete to authenticated using (institute_id = public.get_my_institute_id());

-- Prevent duplicate student assignment to the same batch.
create unique index if not exists uq_batch_students_institute_batch_student
  on public.batch_students(institute_id, batch_id, student_id);
