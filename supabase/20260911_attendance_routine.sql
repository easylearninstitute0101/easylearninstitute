-- Easylearn Institute: attendance history + routine foundation
-- Run after the existing core/RLS migrations.

alter table public.routines enable row level security;
create index if not exists idx_routines_institute_day_time
  on public.routines(institute_id, day_of_week, start_time);
create index if not exists idx_attendance_institute_date
  on public.attendance(institute_id, date desc);

drop policy if exists "Institute members can view routines" on public.routines;
drop policy if exists "Institute members can insert routines" on public.routines;
drop policy if exists "Institute members can update routines" on public.routines;
drop policy if exists "Institute members can delete routines" on public.routines;

create policy "Institute members can view routines"
on public.routines for select to authenticated
using (institute_id = public.get_my_institute_id());

create policy "Institute members can insert routines"
on public.routines for insert to authenticated
with check (institute_id = public.get_my_institute_id());

create policy "Institute members can update routines"
on public.routines for update to authenticated
using (institute_id = public.get_my_institute_id())
with check (institute_id = public.get_my_institute_id());

create policy "Institute members can delete routines"
on public.routines for delete to authenticated
using (institute_id = public.get_my_institute_id());
