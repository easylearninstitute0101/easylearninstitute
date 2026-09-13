-- Easylearn Institute: Exams, Results and Enquiries
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
 batch_id uuid not null references public.batches(id) on delete cascade, name text not null, exam_date date not null, created_at timestamptz not null default now()
);
create table if not exists public.exam_subjects (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
 exam_id uuid not null references public.exams(id) on delete cascade, subject_name text not null, total_marks numeric(10,2) not null check(total_marks>0)
);
create table if not exists public.results (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
 exam_id uuid not null references public.exams(id) on delete cascade, exam_subject_id uuid not null references public.exam_subjects(id) on delete cascade,
 student_id uuid not null references public.students(id) on delete cascade, marks numeric(10,2) not null check(marks>=0), grade text, remarks text, created_at timestamptz not null default now(),
 unique(institute_id,exam_subject_id,student_id)
);
create table if not exists public.enquiries (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null references public.institutes(id) on delete cascade,
 name text not null, phone text, course_id uuid references public.courses(id) on delete set null, batch_id uuid references public.batches(id) on delete set null,
 source text, notes text, follow_up_date date, status text not null default 'new' check(status in ('new','contacted','interested','admitted','not_interested','lost')), created_at timestamptz not null default now()
);
create index if not exists idx_exams_institute_batch_date on public.exams(institute_id,batch_id,exam_date desc);
create index if not exists idx_exam_subjects_institute_exam on public.exam_subjects(institute_id,exam_id);
create index if not exists idx_results_institute_student on public.results(institute_id,student_id,exam_id);
create index if not exists idx_enquiries_institute_status on public.enquiries(institute_id,status,created_at desc);

alter table public.exams enable row level security;
alter table public.exam_subjects enable row level security;
alter table public.results enable row level security;
alter table public.enquiries enable row level security;

-- Institute-level policies. Student-specific read restrictions should be tightened when student portal roles are enabled.
create policy "Institute members can view exams" on public.exams for select to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can insert exams" on public.exams for insert to authenticated with check(institute_id=public.get_my_institute_id());
create policy "Institute members can update exams" on public.exams for update to authenticated using(institute_id=public.get_my_institute_id()) with check(institute_id=public.get_my_institute_id());
create policy "Institute members can delete exams" on public.exams for delete to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can view exam subjects" on public.exam_subjects for select to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can insert exam subjects" on public.exam_subjects for insert to authenticated with check(institute_id=public.get_my_institute_id());
create policy "Institute members can update exam subjects" on public.exam_subjects for update to authenticated using(institute_id=public.get_my_institute_id()) with check(institute_id=public.get_my_institute_id());
create policy "Institute members can delete exam subjects" on public.exam_subjects for delete to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can view results" on public.results for select to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can insert results" on public.results for insert to authenticated with check(institute_id=public.get_my_institute_id());
create policy "Institute members can update results" on public.results for update to authenticated using(institute_id=public.get_my_institute_id()) with check(institute_id=public.get_my_institute_id());
create policy "Institute members can delete results" on public.results for delete to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can view enquiries" on public.enquiries for select to authenticated using(institute_id=public.get_my_institute_id());
create policy "Institute members can insert enquiries" on public.enquiries for insert to authenticated with check(institute_id=public.get_my_institute_id());
create policy "Institute members can update enquiries" on public.enquiries for update to authenticated using(institute_id=public.get_my_institute_id()) with check(institute_id=public.get_my_institute_id());
create policy "Institute members can delete enquiries" on public.enquiries for delete to authenticated using(institute_id=public.get_my_institute_id());
