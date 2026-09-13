-- Easylearn Institute Progress 19
-- Teacher/Staff management + Teacher Portal hardening.

alter table public.teachers add column if not exists photo_url text;

insert into storage.buckets (id, name, public)
values ('teacher-photos', 'teacher-photos', true)
on conflict (id) do update set public = true;

alter table storage.objects enable row level security;

drop policy if exists "Teacher photos view" on storage.objects;
create policy "Teacher photos view" on storage.objects
for select to authenticated
using (bucket_id = 'teacher-photos');

drop policy if exists "Teacher photos upload" on storage.objects;
create policy "Teacher photos upload" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'teacher-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
);

drop policy if exists "Teacher photos update" on storage.objects;
create policy "Teacher photos update" on storage.objects
for update to authenticated
using (
  bucket_id = 'teacher-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
)
with check (
  bucket_id = 'teacher-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
);

drop policy if exists "Teacher photos delete" on storage.objects;
create policy "Teacher photos delete" on storage.objects
for delete to authenticated
using (
  bucket_id = 'teacher-photos'
  and (storage.foldername(name))[1] = public.get_my_institute_id()::text
  and public.can_manage_institute()
);
