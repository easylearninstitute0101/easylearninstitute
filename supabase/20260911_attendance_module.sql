-- Easylearn Institute: Attendance module
-- Run after the existing core schema and RLS migrations.

alter table public.attendance enable row level security;

create index if not exists idx_attendance_institute_batch_date
  on public.attendance(institute_id, batch_id, date);

create index if not exists idx_attendance_institute_student_date
  on public.attendance(institute_id, student_id, date desc);

create unique index if not exists uq_attendance_institute_batch_student_date
  on public.attendance(institute_id, batch_id, student_id, date);

drop policy if exists "Institute members can view attendance" on public.attendance;
drop policy if exists "Institute members can insert attendance" on public.attendance;
drop policy if exists "Institute members can update attendance" on public.attendance;
drop policy if exists "Institute members can delete attendance" on public.attendance;

create policy "Institute members can view attendance"
on public.attendance for select to authenticated
using (institute_id = public.get_my_institute_id());

create policy "Institute members can insert attendance"
on public.attendance for insert to authenticated
with check (institute_id = public.get_my_institute_id());

create policy "Institute members can update attendance"
on public.attendance for update to authenticated
using (institute_id = public.get_my_institute_id())
with check (institute_id = public.get_my_institute_id());

create policy "Institute members can delete attendance"
on public.attendance for delete to authenticated
using (institute_id = public.get_my_institute_id());

-- Allowed values used by the application: present, absent, late.
-- If the existing table has a status CHECK constraint with different casing,
-- align it with these lowercase values before using the module.
