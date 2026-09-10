-- Easylearn Institute: bootstrap a tenant for every new auth user.
-- Run this once in Supabase SQL Editor.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_institute_id uuid;
  display_name text;
begin
  display_name := coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'My Institute');

  insert into public.institutes (name, email, status)
  values (display_name || ' Institute', new.email, 'active')
  returning id into new_institute_id;

  insert into public.profiles (id, institute_id, role, full_name, email, status)
  values (
    new.id,
    new_institute_id,
    'INSTITUTE_ADMIN',
    display_name,
    new.email,
    'active'
  )
  on conflict (id) do update
    set institute_id = excluded.institute_id,
        role = excluded.role,
        full_name = excluded.full_name,
        email = excluded.email,
        status = excluded.status;

  return new;
end;
$$;

 drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
