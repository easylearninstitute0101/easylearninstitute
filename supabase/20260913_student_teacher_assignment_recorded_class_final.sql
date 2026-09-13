-- Easylearn Institute — Student/Teacher Assignment + Recorded Class final hardening
-- Applied to production on 2026-09-13.
-- Assignment answers support text and an external HTTPS file URL (e.g. Google Drive/PDF link).
-- Recorded classes support HTTPS video URLs (YouTube links are embedded by the frontend).

create or replace function public.validate_academic_record()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from public.batches b where b.id=new.batch_id and b.institute_id=new.institute_id) then
    raise exception 'Selected batch does not belong to this institute';
  end if;
  if new.teacher_id is not null and not exists(select 1 from public.teachers t where t.id=new.teacher_id and t.institute_id=new.institute_id) then
    raise exception 'Selected teacher does not belong to this institute';
  end if;
  return new;
end; $$;

create table if not exists public.homework (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid not null references public.batches(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete set null,
  title text not null, description text, deadline date, attachment_url text, created_at timestamptz not null default now()
);
create index if not exists idx_homework_institute_batch on public.homework(institute_id,batch_id,created_at desc);
create index if not exists idx_homework_deadline on public.homework(institute_id,deadline);
alter table public.homework enable row level security;
drop trigger if exists trg_validate_homework on public.homework;
create trigger trg_validate_homework before insert or update on public.homework for each row execute function public.validate_academic_record();

create table if not exists public.recorded_classes (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  batch_id uuid not null references public.batches(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete set null,
  title text not null, description text, video_url text not null, lesson_date date,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint recorded_classes_video_url_chk check(video_url ~* '^https?://')
);
create index if not exists idx_recorded_classes_batch_date on public.recorded_classes(institute_id,batch_id,lesson_date desc,created_at desc);
alter table public.recorded_classes enable row level security;
create or replace function public.validate_recorded_class() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from public.batches b where b.id=new.batch_id and b.institute_id=new.institute_id) then raise exception 'Selected batch does not belong to this institute'; end if;
  if new.teacher_id is not null and not exists(select 1 from public.teachers t where t.id=new.teacher_id and t.institute_id=new.institute_id) then raise exception 'Selected teacher does not belong to this institute'; end if;
  return new;
end; $$;
drop trigger if exists trg_validate_recorded_class on public.recorded_classes;
create trigger trg_validate_recorded_class before insert or update on public.recorded_classes for each row execute function public.validate_recorded_class();

create table if not exists public.assignment_submissions (
  id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
  assignment_id uuid not null references public.assignments(id) on delete cascade, student_id uuid not null references public.students(id) on delete cascade,
  answer_text text, file_url text, submitted_at timestamptz not null default now(),
  status text not null default 'submitted' check(status in ('submitted','late','reviewed','returned')),
  marks numeric, feedback text, reviewed_at timestamptz, reviewed_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint assignment_submissions_answer_chk check(nullif(trim(coalesce(answer_text,'')),'') is not null or nullif(trim(coalesce(file_url,'')),'') is not null),
  constraint assignment_submissions_marks_chk check(marks is null or marks>=0)
);
create unique index if not exists uq_assignment_submission_student on public.assignment_submissions(assignment_id,student_id);
create index if not exists idx_assignment_submissions_assignment on public.assignment_submissions(institute_id,assignment_id,submitted_at desc);
create index if not exists idx_assignment_submissions_student on public.assignment_submissions(institute_id,student_id,submitted_at desc);
alter table public.assignment_submissions enable row level security;
create or replace function public.validate_assignment_submission() returns trigger language plpgsql security definer set search_path=public as $$
declare a_inst uuid; s_inst uuid;
begin
  select institute_id into a_inst from public.assignments where id=new.assignment_id;
  select institute_id into s_inst from public.students where id=new.student_id;
  if a_inst is null or s_inst is null or a_inst is distinct from new.institute_id or s_inst is distinct from new.institute_id then raise exception 'Assignment and student must belong to the same institute'; end if;
  if not exists(select 1 from public.batch_students bs join public.assignments a on a.batch_id=bs.batch_id where bs.student_id=new.student_id and a.id=new.assignment_id and bs.institute_id=new.institute_id) then raise exception 'Student is not enrolled in the assignment batch'; end if;
  return new;
end; $$;
drop trigger if exists trg_validate_assignment_submission on public.assignment_submissions;
create trigger trg_validate_assignment_submission before insert or update on public.assignment_submissions for each row execute function public.validate_assignment_submission();

-- The final policy definitions are maintained in the applied production migrations:
-- restore_homework_and_academic_read_scope_20260913_v2
-- teacher_scope_assignment_recorded_security_20260913_v3
-- assignment_submission_teacher_read_scope_20260913
-- drop_legacy_assignment_policy_20260913
-- Those migrations intentionally avoid Storage DDL because storage.objects is owned by Supabase's Storage subsystem.

revoke execute on function public.validate_academic_record() from public,anon,authenticated;
revoke execute on function public.validate_recorded_class() from public,anon,authenticated;
revoke execute on function public.validate_assignment_submission() from public,anon,authenticated;
