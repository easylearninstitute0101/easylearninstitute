-- Easylearn Institute Progress 25
-- Private storage + tenant-scoped photo/file access hardening.

alter table public.students add column if not exists photo_url text;
alter table public.teachers add column if not exists photo_url text;

update storage.buckets
set public = false,
    file_size_limit = 2097152,
    allowed_mime_types = array['image/jpeg','image/png','image/webp']
where id in ('student-photos','teacher-photos');

update public.students
set photo_url = regexp_replace(photo_url, '^.*/storage/v1/object/public/student-photos/', '')
where photo_url like '%/storage/v1/object/public/student-photos/%';

update public.teachers
set photo_url = regexp_replace(photo_url, '^.*/storage/v1/object/public/teacher-photos/', '')
where photo_url like '%/storage/v1/object/public/teacher-photos/%';

-- Student photos: tenant members may read their institute's objects;
-- only institute managers may write/delete.
drop policy if exists "Student photos view" on storage.objects;
drop policy if exists "Student photos upload" on storage.objects;
drop policy if exists "Student photos update" on storage.objects;
drop policy if exists "Student photos delete" on storage.objects;
create policy "Student photos tenant view" on storage.objects for select to authenticated
using (bucket_id = 'student-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text);
create policy "Student photos tenant upload" on storage.objects for insert to authenticated
with check (bucket_id = 'student-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute());
create policy "Student photos tenant update" on storage.objects for update to authenticated
using (bucket_id = 'student-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute())
with check (bucket_id = 'student-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute());
create policy "Student photos tenant delete" on storage.objects for delete to authenticated
using (bucket_id = 'student-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute());

-- Teacher photos: same tenant isolation and manager-only writes.
drop policy if exists "Teacher photos view" on storage.objects;
drop policy if exists "Teacher photos upload" on storage.objects;
drop policy if exists "Teacher photos update" on storage.objects;
drop policy if exists "Teacher photos delete" on storage.objects;
create policy "Teacher photos tenant view" on storage.objects for select to authenticated
using (bucket_id = 'teacher-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text);
create policy "Teacher photos tenant upload" on storage.objects for insert to authenticated
with check (bucket_id = 'teacher-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute());
create policy "Teacher photos tenant update" on storage.objects for update to authenticated
using (bucket_id = 'teacher-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute())
with check (bucket_id = 'teacher-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute());
create policy "Teacher photos tenant delete" on storage.objects for delete to authenticated
using (bucket_id = 'teacher-photos' and (storage.foldername(name))[1] = public.get_my_institute_id()::text and public.can_manage_institute());
