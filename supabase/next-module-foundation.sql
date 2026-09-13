-- Easylearn Institute: next-module foundation
-- Safe intent: create missing Courses support and indexes; do not drop existing tables/data.

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null,
  description text,
  duration text,
  fee numeric(12,2) not null default 0,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint courses_status_check check (status in ('active','inactive'))
);

alter table public.courses enable row level security;

create index if not exists courses_institute_id_idx on public.courses(institute_id);
create unique index if not exists courses_institute_name_uidx on public.courses(institute_id, lower(name));

-- Tenant isolation. Uses the helper already established for Students.
drop policy if exists "Institute members can view courses" on public.courses;
drop policy if exists "Institute admins can insert courses" on public.courses;
drop policy if exists "Institute admins can update courses" on public.courses;
drop policy if exists "Institute admins can delete courses" on public.courses;

create policy "Institute members can view courses"
on public.courses for select to authenticated
using (institute_id = public.get_my_institute_id());

create policy "Institute admins can insert courses"
on public.courses for insert to authenticated
with check (institute_id = public.get_my_institute_id());

create policy "Institute admins can update courses"
on public.courses for update to authenticated
using (institute_id = public.get_my_institute_id())
with check (institute_id = public.get_my_institute_id());

create policy "Institute admins can delete courses"
on public.courses for delete to authenticated
using (institute_id = public.get_my_institute_id());

-- Useful tenant indexes on already-existing core tables.
create index if not exists batches_institute_id_idx on public.batches(institute_id);
create index if not exists batch_students_institute_id_idx on public.batch_students(institute_id);
create index if not exists attendance_institute_date_idx on public.attendance(institute_id, date);
create index if not exists fees_institute_student_idx on public.fees(institute_id, student_id);
create index if not exists fee_payments_institute_student_idx on public.fee_payments(institute_id, student_id);
create index if not exists routines_institute_batch_idx on public.routines(institute_id, batch_id);
create index if not exists expenses_institute_date_idx on public.expenses(institute_id, expense_date);
create index if not exists salaries_institute_month_idx on public.salaries(institute_id, month);
