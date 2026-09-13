-- Easylearn Institute: Exam + Subject + Marks + Grade hardening
-- Run after 20260911_exams_results_enquiries.sql

alter table public.results
  add constraint results_marks_nonnegative check (marks >= 0) not valid;

create index if not exists idx_results_institute_exam_subject_student
  on public.results(institute_id, exam_id, exam_subject_id, student_id);

create or replace function public.validate_exam_result()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total numeric;
begin
  select total_marks into v_total
  from public.exam_subjects
  where id = new.exam_subject_id
    and exam_id = new.exam_id
    and institute_id = new.institute_id;
  if v_total is null then
    raise exception 'Invalid exam subject for this exam';
  end if;
  if new.marks < 0 or new.marks > v_total then
    raise exception 'Marks must be between 0 and %', v_total;
  end if;
  if new.grade is null or btrim(new.grade) = '' then
    new.grade := case
      when new.marks / v_total * 100 >= 80 then 'A+'
      when new.marks / v_total * 100 >= 70 then 'A'
      when new.marks / v_total * 100 >= 60 then 'A-'
      when new.marks / v_total * 100 >= 50 then 'B'
      when new.marks / v_total * 100 >= 40 then 'C'
      when new.marks / v_total * 100 >= 33 then 'D'
      else 'F'
    end;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_exam_result on public.results;
create trigger trg_validate_exam_result
before insert or update on public.results
for each row execute function public.validate_exam_result();
