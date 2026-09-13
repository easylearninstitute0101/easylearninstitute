-- Easylearn Institute: Homework + Assignment foundation
create table if not exists public.homework (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid not null references public.batches(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete set null,
  title text not null, description text, deadline date, attachment_url text, created_at timestamptz not null default now()
);
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid not null references public.batches(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete set null,
  title text not null, description text, deadline date, attachment_url text, created_at timestamptz not null default now()
);
create index if not exists idx_homework_institute_batch on public.homework(institute_id,batch_id,created_at desc);
create index if not exists idx_assignments_institute_batch on public.assignments(institute_id,batch_id,created_at desc);
alter table public.homework enable row level security;
alter table public.assignments enable row level security;
drop policy if exists "Institute members can view homework" on public.homework;
drop policy if exists "Institute members can insert homework" on public.homework;
drop policy if exists "Institute members can update homework" on public.homework;
drop policy if exists "Institute members can delete homework" on public.homework;
create policy "Institute members can view homework" on public.homework for select to authenticated using (institute_id=public.get_my_institute_id());
create policy "Institute members can insert homework" on public.homework for insert to authenticated with check (institute_id=public.get_my_institute_id());
create policy "Institute members can update homework" on public.homework for update to authenticated using (institute_id=public.get_my_institute_id()) with check (institute_id=public.get_my_institute_id());
create policy "Institute members can delete homework" on public.homework for delete to authenticated using (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can view assignments" on public.assignments;
drop policy if exists "Institute members can insert assignments" on public.assignments;
drop policy if exists "Institute members can update assignments" on public.assignments;
drop policy if exists "Institute members can delete assignments" on public.assignments;
create policy "Institute members can view assignments" on public.assignments for select to authenticated using (institute_id=public.get_my_institute_id());
create policy "Institute members can insert assignments" on public.assignments for insert to authenticated with check (institute_id=public.get_my_institute_id());
create policy "Institute members can update assignments" on public.assignments for update to authenticated using (institute_id=public.get_my_institute_id()) with check (institute_id=public.get_my_institute_id());
create policy "Institute members can delete assignments" on public.assignments for delete to authenticated using (institute_id=public.get_my_institute_id());
