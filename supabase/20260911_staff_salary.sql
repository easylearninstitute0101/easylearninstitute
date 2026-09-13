-- Easylearn Institute: Teachers/Staff + Salary module
-- Run after the existing core schema/RLS migrations.

alter table public.teachers add column if not exists phone text;
alter table public.teachers add column if not exists email text;
alter table public.teachers add column if not exists designation text default 'Teacher';
alter table public.teachers add column if not exists joining_date date;
alter table public.teachers add column if not exists salary numeric(12,2) not null default 0;
alter table public.teachers add column if not exists status text not null default 'active';
alter table public.salaries add column if not exists staff_id uuid;
alter table public.salaries add column if not exists month date;
alter table public.salaries add column if not exists basic numeric(12,2) not null default 0;
alter table public.salaries add column if not exists bonus numeric(12,2) not null default 0;
alter table public.salaries add column if not exists deduction numeric(12,2) not null default 0;
alter table public.salaries add column if not exists payable numeric(12,2) not null default 0;
alter table public.salaries add column if not exists paid numeric(12,2) not null default 0;
alter table public.salaries add column if not exists due numeric(12,2) not null default 0;
alter table public.salaries add column if not exists payment_date date;
alter table public.salaries add column if not exists method text;

create index if not exists idx_teachers_institute_status on public.teachers(institute_id,status);
create index if not exists idx_salaries_institute_month on public.salaries(institute_id,month desc);
create index if not exists idx_salaries_institute_staff_month on public.salaries(institute_id,staff_id,month desc);

alter table public.teachers enable row level security;
alter table public.salaries enable row level security;

drop policy if exists "Institute members can view teachers" on public.teachers;
drop policy if exists "Institute members can insert teachers" on public.teachers;
drop policy if exists "Institute members can update teachers" on public.teachers;
drop policy if exists "Institute members can delete teachers" on public.teachers;
create policy "Institute members can view teachers" on public.teachers for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert teachers" on public.teachers for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update teachers" on public.teachers for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete teachers" on public.teachers for delete to authenticated using (institute_id = public.get_my_institute_id());

drop policy if exists "Institute members can view salaries" on public.salaries;
drop policy if exists "Institute members can insert salaries" on public.salaries;
drop policy if exists "Institute members can update salaries" on public.salaries;
drop policy if exists "Institute members can delete salaries" on public.salaries;
create policy "Institute members can view salaries" on public.salaries for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert salaries" on public.salaries for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update salaries" on public.salaries for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete salaries" on public.salaries for delete to authenticated using (institute_id = public.get_my_institute_id());
