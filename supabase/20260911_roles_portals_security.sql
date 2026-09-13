-- Easylearn Institute Progress 13: roles, linked portals and RLS hardening
-- Run after 20260911_reports_roles_settings_notifications.sql.

alter table public.teachers add column if not exists user_id uuid references auth.users(id) on delete set null;
create index if not exists idx_teachers_institute_user on public.teachers(institute_id,user_id);

create or replace function public.set_member_role(target_user_id uuid, new_role text)
returns boolean
language plpgsql security definer set search_path=public
as $$
declare caller_institute uuid; target_institute uuid;
begin
  if public.get_my_role() <> 'admin' then raise exception 'Only an institute admin can change member roles'; end if;
  if new_role not in ('admin','manager','teacher','staff','student') then raise exception 'Invalid role'; end if;
  select institute_id into caller_institute from public.profiles where id=auth.uid() limit 1;
  select institute_id into target_institute from public.profiles where id=target_user_id limit 1;
  if caller_institute is null or target_institute is distinct from caller_institute then raise exception 'Member is outside your institute'; end if;
  if target_user_id=auth.uid() and new_role<>'admin' then raise exception 'You cannot remove your own admin role'; end if;
  update public.profiles set role=new_role where id=target_user_id;
  return true;
end; $$;
grant execute on function public.set_member_role(uuid,text) to authenticated;

create or replace function public.link_member_record(target_user_id uuid, record_type text, record_id uuid)
returns boolean
language plpgsql security definer set search_path=public
as $$
declare caller_institute uuid; target_institute uuid;
begin
  if public.get_my_role() <> 'admin' then raise exception 'Only an institute admin can link portal accounts'; end if;
  select institute_id into caller_institute from public.profiles where id=auth.uid() limit 1;
  select institute_id into target_institute from public.profiles where id=target_user_id limit 1;
  if caller_institute is null or target_institute is distinct from caller_institute then raise exception 'Member is outside your institute'; end if;
  if record_type='student' then
    update public.students set user_id=target_user_id,updated_at=now() where id=record_id and institute_id=caller_institute;
  elsif record_type='teacher' then
    update public.teachers set user_id=target_user_id,updated_at=now() where id=record_id and institute_id=caller_institute;
  else raise exception 'Invalid record type'; end if;
  return true;
end; $$;
grant execute on function public.link_member_record(uuid,text,uuid) to authenticated;

alter table public.profiles enable row level security;
drop policy if exists "Members can view institute profiles" on public.profiles;
create policy "Members can view institute profiles" on public.profiles for select to authenticated using (institute_id=public.get_my_institute_id());
drop policy if exists "Admins can update institute profiles" on public.profiles;
create policy "Admins can update institute profiles" on public.profiles for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role()='admin') with check (institute_id=public.get_my_institute_id() and public.get_my_role()='admin');

-- Students: institute roles can manage/view; student can view only own row.
drop policy if exists "Institute members can view students" on public.students;
create policy "Institute members can view students" on public.students for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or user_id=auth.uid()));
drop policy if exists "Institute admins can insert students" on public.students;
create policy "Institute admins can insert students" on public.students for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute admins can update students" on public.students;
create policy "Institute admins can update students" on public.students for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute admins can delete students" on public.students;
create policy "Institute admins can delete students" on public.students for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Teachers/staff: everyone in the institute may read basic staff records; management changes them.
drop policy if exists "Institute members can view teachers" on public.teachers;
create policy "Institute members can view teachers" on public.teachers for select to authenticated using (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can insert teachers" on public.teachers;
create policy "Institute members can insert teachers" on public.teachers for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update teachers" on public.teachers;
create policy "Institute members can update teachers" on public.teachers for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete teachers" on public.teachers;
create policy "Institute members can delete teachers" on public.teachers for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Salaries are private management data.
drop policy if exists "Institute members can view salaries" on public.salaries;
create policy "Institute members can view salaries" on public.salaries for select to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can insert salaries" on public.salaries;
create policy "Institute members can insert salaries" on public.salaries for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update salaries" on public.salaries;
create policy "Institute members can update salaries" on public.salaries for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete salaries" on public.salaries;
create policy "Institute members can delete salaries" on public.salaries for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Fees: managers/admins operate; students read their own fees.
drop policy if exists "Institute members can view fees" on public.fees;
create policy "Institute members can view fees" on public.fees for select to authenticated using (institute_id=public.get_my_institute_id() and (public.can_manage_institute() or student_id in (select id from public.students where user_id=auth.uid())));
drop policy if exists "Institute members can insert fees" on public.fees;
create policy "Institute members can insert fees" on public.fees for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update fees" on public.fees;
create policy "Institute members can update fees" on public.fees for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete fees" on public.fees;
create policy "Institute members can delete fees" on public.fees for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Payment history: managers/admins operate; students read their own.
drop policy if exists "Institute members can view fee_payments" on public.fee_payments;
create policy "Institute members can view fee_payments" on public.fee_payments for select to authenticated using (institute_id=public.get_my_institute_id() and (public.can_manage_institute() or student_id in (select id from public.students where user_id=auth.uid())));
drop policy if exists "Institute members can insert fee_payments" on public.fee_payments;
create policy "Institute members can insert fee_payments" on public.fee_payments for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update fee_payments" on public.fee_payments;
create policy "Institute members can update fee_payments" on public.fee_payments for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete fee_payments" on public.fee_payments;
create policy "Institute members can delete fee_payments" on public.fee_payments for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Attendance: students read own; teachers/managers can record.
drop policy if exists "Institute members can view attendance" on public.attendance;
create policy "Institute members can view attendance" on public.attendance for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or student_id in (select id from public.students where user_id=auth.uid())));
drop policy if exists "Institute members can insert attendance" on public.attendance;
create policy "Institute members can insert attendance" on public.attendance for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
drop policy if exists "Institute members can update attendance" on public.attendance;
create policy "Institute members can update attendance" on public.attendance for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can delete attendance" on public.attendance;
create policy "Institute members can delete attendance" on public.attendance for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

-- Results: everyone may read within institute, students only own; academic staff may write.
drop policy if exists "Institute members can view results" on public.results;
create policy "Institute members can view results" on public.results for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or student_id in (select id from public.students where user_id=auth.uid())));
drop policy if exists "Institute members can insert results" on public.results;
create policy "Institute members can insert results" on public.results for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
drop policy if exists "Institute members can update results" on public.results;
create policy "Institute members can update results" on public.results for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can delete results" on public.results;
create policy "Institute members can delete results" on public.results for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

-- Notifications: read for own/broadcast; creation is management/teacher; only own can mark read.
drop policy if exists "Members can insert notifications" on public.notifications;
create policy "Members can insert notifications" on public.notifications for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

drop policy if exists "Members can delete own notifications" on public.notifications;
create policy "Members can delete own notifications" on public.notifications for delete to authenticated using (institute_id=public.get_my_institute_id() and user_id=auth.uid());

-- Courses and batches: management edits; all institute staff can read; students only assigned batches.
drop policy if exists "Institute members can view courses" on public.courses;
create policy "Institute members can view courses" on public.courses for select to authenticated
using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or id in (select course_id from public.batches b join public.batch_students bs on bs.batch_id=b.id where bs.student_id in (select id from public.students where user_id=auth.uid()))));
drop policy if exists "Institute admins can insert courses" on public.courses;
create policy "Institute admins can insert courses" on public.courses for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute admins can update courses" on public.courses;
create policy "Institute admins can update courses" on public.courses for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute admins can delete courses" on public.courses;
create policy "Institute admins can delete courses" on public.courses for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

drop policy if exists "Institute members can view batches" on public.batches;
create policy "Institute members can view batches" on public.batches for select to authenticated
using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))));
drop policy if exists "Institute members can insert batches" on public.batches;
create policy "Institute members can insert batches" on public.batches for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update batches" on public.batches;
create policy "Institute members can update batches" on public.batches for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete batches" on public.batches;
create policy "Institute members can delete batches" on public.batches for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Batch membership: only management can change it; members can read their own assignment.
drop policy if exists "Institute members can view batch_students" on public.batch_students;
create policy "Institute members can view batch_students" on public.batch_students for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or student_id in (select id from public.students where user_id=auth.uid())));
drop policy if exists "Institute members can insert batch_students" on public.batch_students;
create policy "Institute members can insert batch_students" on public.batch_students for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update batch_students" on public.batch_students;
create policy "Institute members can update batch_students" on public.batch_students for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete batch_students" on public.batch_students;
create policy "Institute members can delete batch_students" on public.batch_students for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());

-- Routine: staff read; teacher/manager manage; students see assigned-batch routine only.
drop policy if exists "Institute members can view routines" on public.routines;
create policy "Institute members can view routines" on public.routines for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or batch_id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))));
drop policy if exists "Institute members can insert routines" on public.routines;
create policy "Institute members can insert routines" on public.routines for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
drop policy if exists "Institute members can update routines" on public.routines;
create policy "Institute members can update routines" on public.routines for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can delete routines" on public.routines;
create policy "Institute members can delete routines" on public.routines for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

-- Homework and assignments: academic staff write; students read assigned-batch items.
DO $$
BEGIN
  IF to_regclass('public.homework') IS NOT NULL THEN
    EXECUTE 'drop policy if exists "Institute members can view homework" on public.homework';
    EXECUTE 'create policy "Institute members can view homework" on public.homework for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in (''admin'',''manager'',''teacher'',''staff'') or batch_id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))))';
    EXECUTE 'drop policy if exists "Institute members can insert homework" on public.homework';
    EXECUTE 'create policy "Institute members can insert homework" on public.homework for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in (''admin'',''manager'',''teacher''))';
    EXECUTE 'drop policy if exists "Institute members can update homework" on public.homework';
    EXECUTE 'create policy "Institute members can update homework" on public.homework for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in (''admin'',''manager'',''teacher'')) with check (institute_id=public.get_my_institute_id())';
    EXECUTE 'drop policy if exists "Institute members can delete homework" on public.homework';
    EXECUTE 'create policy "Institute members can delete homework" on public.homework for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in (''admin'',''manager'',''teacher''))';
  END IF;
  IF to_regclass('public.assignments') IS NOT NULL THEN
    EXECUTE 'drop policy if exists "Institute members can view assignments" on public.assignments';
    EXECUTE 'create policy "Institute members can view assignments" on public.assignments for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in (''admin'',''manager'',''teacher'',''staff'') or batch_id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))))';
    EXECUTE 'drop policy if exists "Institute members can insert assignments" on public.assignments';
    EXECUTE 'create policy "Institute members can insert assignments" on public.assignments for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in (''admin'',''manager'',''teacher''))';
    EXECUTE 'drop policy if exists "Institute members can update assignments" on public.assignments';
    EXECUTE 'create policy "Institute members can update assignments" on public.assignments for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in (''admin'',''manager'',''teacher'')) with check (institute_id=public.get_my_institute_id())';
    EXECUTE 'drop policy if exists "Institute members can delete assignments" on public.assignments';
    EXECUTE 'create policy "Institute members can delete assignments" on public.assignments for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in (''admin'',''manager'',''teacher''))';
  END IF;
END $$;

-- Exams and subjects: academic staff manage; students only read exams for assigned batches.
drop policy if exists "Institute members can view exams" on public.exams;
create policy "Institute members can view exams" on public.exams for select to authenticated using (institute_id=public.get_my_institute_id() and (public.get_my_role() in ('admin','manager','teacher','staff') or batch_id in (select batch_id from public.batch_students where student_id in (select id from public.students where user_id=auth.uid()))));
drop policy if exists "Institute members can insert exams" on public.exams;
create policy "Institute members can insert exams" on public.exams for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
drop policy if exists "Institute members can update exams" on public.exams;
create policy "Institute members can update exams" on public.exams for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can delete exams" on public.exams;
create policy "Institute members can delete exams" on public.exams for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

drop policy if exists "Institute members can insert exam subjects" on public.exam_subjects;
create policy "Institute members can insert exam subjects" on public.exam_subjects for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));
drop policy if exists "Institute members can update exam subjects" on public.exam_subjects;
create policy "Institute members can update exam subjects" on public.exam_subjects for update to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher')) with check (institute_id=public.get_my_institute_id());
drop policy if exists "Institute members can delete exam subjects" on public.exam_subjects;
create policy "Institute members can delete exam subjects" on public.exam_subjects for delete to authenticated using (institute_id=public.get_my_institute_id() and public.get_my_role() in ('admin','manager','teacher'));

-- Enquiries are management-only.
drop policy if exists "Institute members can view enquiries" on public.enquiries;
create policy "Institute members can view enquiries" on public.enquiries for select to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can insert enquiries" on public.enquiries;
create policy "Institute members can insert enquiries" on public.enquiries for insert to authenticated with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can update enquiries" on public.enquiries;
create policy "Institute members can update enquiries" on public.enquiries for update to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute()) with check (institute_id=public.get_my_institute_id() and public.can_manage_institute());
drop policy if exists "Institute members can delete enquiries" on public.enquiries;
create policy "Institute members can delete enquiries" on public.enquiries for delete to authenticated using (institute_id=public.get_my_institute_id() and public.can_manage_institute());
