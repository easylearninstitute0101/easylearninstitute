-- Easylearn Institute: Reports + Roles + Institute Settings + Notifications
-- Idempotent migration. Run once in Supabase SQL Editor.

alter table public.profiles add column if not exists role text not null default 'admin';

-- Keep the first registered/profile owner as admin unless an existing role is already set.
update public.profiles set role='admin' where role is null or trim(role)='';

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('admin','manager','teacher','staff','student'));

create or replace function public.get_my_role()
returns text
language sql
security definer
set search_path=public
stable
as $$
  select coalesce((select role from public.profiles where id=auth.uid() limit 1),'admin');
$$;
grant execute on function public.get_my_role() to authenticated;

-- Admin/manager are the institute-management roles. This helper is reusable by future RLS policies.
create or replace function public.can_manage_institute()
returns boolean
language sql
security definer
set search_path=public
stable
as $$
  select public.get_my_role() in ('admin','manager');
$$;
grant execute on function public.can_manage_institute() to authenticated;

-- Institute settings fields (additive; existing data is preserved).
alter table public.institutes add column if not exists logo_url text;
alter table public.institutes add column if not exists phone text;
alter table public.institutes add column if not exists email text;
alter table public.institutes add column if not exists address text;
alter table public.institutes add column if not exists type text;
alter table public.institutes add column if not exists updated_at timestamptz not null default now();

-- Notification center.
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null default 'info' check(type in ('info','success','warning','alert')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user_created on public.notifications(institute_id,user_id,is_read,created_at desc);
alter table public.notifications enable row level security;

drop policy if exists "Members can view own notifications" on public.notifications;
create policy "Members can view own notifications" on public.notifications for select to authenticated
using (institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null));

drop policy if exists "Members can insert notifications" on public.notifications;
create policy "Members can insert notifications" on public.notifications for insert to authenticated
with check (institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null));

drop policy if exists "Members can update own notifications" on public.notifications;
create policy "Members can update own notifications" on public.notifications for update to authenticated
using (institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null))
with check (institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null));

drop policy if exists "Members can delete own notifications" on public.notifications;
create policy "Members can delete own notifications" on public.notifications for delete to authenticated
using (institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null));

-- Institute settings: only admin/manager can change the institute profile.
drop policy if exists "Admins can update institute settings" on public.institutes;
create policy "Admins can update institute settings" on public.institutes for update to authenticated
using (id=public.get_my_institute_id() and public.can_manage_institute())
with check (id=public.get_my_institute_id() and public.can_manage_institute());
