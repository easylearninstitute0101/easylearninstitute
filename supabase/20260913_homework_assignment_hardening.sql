-- Easylearn Institute: Homework + Assignment hardening
-- Keep academic records strictly tenant-consistent and validate referenced batch/teacher.
create or replace function public.validate_academic_record()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.batches b where b.id = new.batch_id and b.institute_id = new.institute_id) then
    raise exception 'Selected batch does not belong to this institute';
  end if;
  if new.teacher_id is not null and not exists (select 1 from public.teachers t where t.id = new.teacher_id and t.institute_id = new.institute_id) then
    raise exception 'Selected teacher does not belong to this institute';
  end if;
  if new.deadline is not null and new.deadline < current_date - 3650 then
    raise exception 'Deadline is not valid';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_homework on public.homework;
create trigger trg_validate_homework before insert or update on public.homework for each row execute function public.validate_academic_record();
drop trigger if exists trg_validate_assignments on public.assignments;
create trigger trg_validate_assignments before insert or update on public.assignments for each row execute function public.validate_academic_record();

create index if not exists idx_homework_deadline on public.homework(institute_id, deadline);
create index if not exists idx_assignments_deadline on public.assignments(institute_id, deadline);

-- Re-apply role-aware tenant policies.
drop policy if exists "Institute members can view homework" on public.homework;
drop policy if exists "Institute members can insert homework" on public.homework;
drop policy if exists "Institute members can update homework" on public.homework;
drop policy if exists "Institute members can delete homework" on public.homework;
create policy "Institute members can view homework" on public.homework for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or batch_id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))));
create policy "Institute members can insert homework" on public.homework for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
create policy "Institute members can update homework" on public.homework for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
create policy "Institute members can delete homework" on public.homework for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

drop policy if exists "Institute members can view assignments" on public.assignments;
drop policy if exists "Institute members can insert assignments" on public.assignments;
drop policy if exists "Institute members can update assignments" on public.assignments;
drop policy if exists "Institute members can delete assignments" on public.assignments;
create policy "Institute members can view assignments" on public.assignments for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or batch_id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))));
create policy "Institute members can insert assignments" on public.assignments for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
create policy "Institute members can update assignments" on public.assignments for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
create policy "Institute members can delete assignments" on public.assignments for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
