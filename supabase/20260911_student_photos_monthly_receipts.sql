-- Easylearn Institute Progress 14
-- Student photos, monthly fee generation support and receipt hardening.

alter table public.students add column if not exists photo_url text;

alter table public.fees add column if not exists billing_month date;
create index if not exists idx_fees_institute_billing_month on public.fees(institute_id, billing_month);

-- Duplicate protection for monthly fee generation.
create unique index if not exists uq_fees_monthly_student_type
  on public.fees(institute_id, student_id, fee_type, billing_month)
  where billing_month is not null;

-- Private-by-default student photo bucket. The frontend uses public URLs, so the
-- bucket itself is public while upload/delete access remains controlled by policies.
insert into storage.buckets (id, name, public)
values ('student-photos', 'student-photos', true)
on conflict (id) do update set public = true;

alter table storage.objects enable row level security;

drop policy if exists "Student photos view" on storage.objects;
create policy "Student photos view" on storage.objects
for select to authenticated
using (bucket_id = 'student-photos');

drop policy if exists "Student photos upload" on storage.objects;
create policy "Student photos upload" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'student-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
);

drop policy if exists "Student photos update" on storage.objects;
create policy "Student photos update" on storage.objects
for update to authenticated
using (
  bucket_id = 'student-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
)
with check (
  bucket_id = 'student-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
);

drop policy if exists "Student photos delete" on storage.objects;
create policy "Student photos delete" on storage.objects
for delete to authenticated
using (
  bucket_id = 'student-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
);
