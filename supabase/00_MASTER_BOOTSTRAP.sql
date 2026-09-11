-- Easylearn Institute — single bootstrap / repair script
-- Safe to run on the existing Supabase project. It creates missing tables,
-- adds missing columns, repairs functions/RLS, and installs financial RPCs.

create extension if not exists pgcrypto;

-- ============================================================
-- 1. CORE TENANT / PROFILE
-- ============================================================
create table if not exists public.institutes (
  id uuid primary key default gen_random_uuid(), name text not null,
  logo_url text, phone text, email text, address text, type text,
  status text not null default 'active', created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  auth_user_id uuid, institute_id uuid references public.institutes(id) on delete set null,
  role text not null default 'admin', name text, phone text, email text,
  status text not null default 'active', created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists auth_user_id uuid;
alter table public.profiles add column if not exists institute_id uuid;
alter table public.profiles add column if not exists role text default 'admin';
alter table public.profiles add column if not exists name text;
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists status text default 'active';
alter table public.profiles add column if not exists created_at timestamptz default now();
alter table public.profiles add column if not exists updated_at timestamptz default now();

create or replace function public.get_my_institute_id()
returns uuid language sql security definer stable set search_path=public as $$
  select institute_id from public.profiles where id=auth.uid() limit 1;
$$;
grant execute on function public.get_my_institute_id() to authenticated;

create or replace function public.ensure_my_institute()
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_uid uuid:=auth.uid();
begin
  if v_uid is null then raise exception 'You must be logged in'; end if;
  select institute_id into v_id from public.profiles where id=v_uid;
  if v_id is not null then return v_id; end if;
  insert into public.institutes(name,status) values('Easylearn Institute','active') returning id into v_id;
  update public.profiles set institute_id=v_id, auth_user_id=coalesce(auth_user_id,v_uid), email=coalesce(email,(select email from auth.users where id=v_uid)), updated_at=now() where id=v_uid;
  return v_id;
end;
$$;
grant execute on function public.ensure_my_institute() to authenticated;

create or replace function public.get_my_role()
returns text language sql security definer stable set search_path=public as $$
  select coalesce(nullif(lower(role),''),'admin') from public.profiles where id=auth.uid() limit 1;
$$;
grant execute on function public.get_my_role() to authenticated;

create or replace function public.can_manage_institute()
returns boolean language sql security definer stable set search_path=public as $$
  select coalesce(public.get_my_role() in ('admin','manager','institute_admin','super_admin'),false);
$$;
grant execute on function public.can_manage_institute() to authenticated;

-- Create profile + tenant for new registrations. Existing rows are untouched.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_inst uuid;
begin
  insert into public.institutes(name,status) values(coalesce(new.raw_user_meta_data->>'institute_name','Easylearn Institute'),'active') returning id into v_inst;
  insert into public.profiles(id,auth_user_id,institute_id,role,name,email,status)
  values(new.id,new.id,v_inst,'admin',coalesce(new.raw_user_meta_data->>'full_name',''),new.email,'active')
  on conflict(id) do update set auth_user_id=excluded.auth_user_id, email=excluded.email;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- ============================================================
-- 2. CORE OPERATION TABLES — create if absent, add missing fields
-- ============================================================
create table if not exists public.students (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, user_id uuid,
 student_id text not null, full_name text not null, phone text, email text,
 guardian_name text, guardian_phone text, address text, date_of_birth date, gender text,
 admission_date date default current_date, status text not null default 'active', photo_url text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.teachers (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, auth_user_id uuid,
 user_id uuid, name text, full_name text, photo_url text, phone text, email text,
 designation text default 'Teacher', joining_date date, salary numeric(12,2) default 0,
 status text not null default 'active', created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.courses (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, name text not null,
 description text, duration text, fee numeric(12,2) default 0, status text not null default 'active',
 created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.batches (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, course_id uuid,
 teacher_id uuid, name text not null, room text, start_date date, end_date date,
 fee numeric(12,2) default 0, status text not null default 'active', created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.batch_students (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, student_id uuid not null,
 batch_id uuid not null, enrollment_date date default current_date, status text not null default 'active'
);
create table if not exists public.attendance (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, student_id uuid not null,
 batch_id uuid not null, date date not null, status text not null, recorded_by uuid, note text, created_at timestamptz default now()
);
create table if not exists public.fees (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, student_id uuid not null,
 fee_type text, amount numeric(12,2) not null default 0, discount numeric(12,2) not null default 0,
 due_amount numeric(12,2) not null default 0, due_date date, billing_month date, status text not null default 'due', created_at timestamptz default now()
);
create table if not exists public.fee_payments (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, student_id uuid,
 fee_id uuid, amount numeric(12,2) not null default 0, method text, transaction_reference text,
 receipt_number text, collected_by uuid, paid_at timestamptz not null default now(), created_at timestamptz default now()
);
create table if not exists public.routines (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, batch_id uuid,
 teacher_id uuid, day_of_week text, start_time time, end_time time, topic text, room text, created_at timestamptz default now()
);
create table if not exists public.expenses (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, category text,
 amount numeric(12,2) not null default 0, method text default 'Cash', description text,
 expense_date date default current_date, added_by uuid, created_at timestamptz default now()
);
create table if not exists public.salaries (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, staff_id uuid,
 month date, basic numeric(12,2) default 0, bonus numeric(12,2) default 0, deduction numeric(12,2) default 0,
 payable numeric(12,2) default 0, paid numeric(12,2) default 0, due numeric(12,2) default 0,
 payment_date date, method text, created_at timestamptz default now()
);

-- Existing deployments: add the exact columns the Flutter app expects.
alter table public.students add column if not exists photo_url text;
alter table public.teachers add column if not exists user_id uuid;
alter table public.teachers add column if not exists name text;
alter table public.teachers add column if not exists full_name text;
alter table public.teachers add column if not exists photo_url text;
alter table public.teachers add column if not exists phone text;
alter table public.teachers add column if not exists email text;
alter table public.teachers add column if not exists designation text default 'Teacher';
alter table public.teachers add column if not exists joining_date date;
alter table public.teachers add column if not exists salary numeric(12,2) default 0;
alter table public.teachers add column if not exists status text default 'active';
alter table public.teachers add column if not exists updated_at timestamptz default now();
alter table public.batches add column if not exists course_id uuid;
alter table public.batches add column if not exists teacher_id uuid;
alter table public.batches add column if not exists name text;
alter table public.batches add column if not exists room text;
alter table public.batches add column if not exists start_date date;
alter table public.batches add column if not exists end_date date;
alter table public.batches add column if not exists fee numeric(12,2) default 0;
alter table public.batches add column if not exists status text default 'active';
alter table public.batches add column if not exists updated_at timestamptz default now();
alter table public.routines add column if not exists batch_id uuid;
alter table public.routines add column if not exists teacher_id uuid;
alter table public.routines add column if not exists day_of_week text;
alter table public.routines add column if not exists start_time time;
alter table public.routines add column if not exists end_time time;
alter table public.routines add column if not exists topic text;
alter table public.routines add column if not exists room text;
alter table public.routines add column if not exists created_at timestamptz default now();
alter table public.fees add column if not exists student_id uuid;
alter table public.fees add column if not exists fee_type text;
alter table public.fees add column if not exists amount numeric(12,2) default 0;
alter table public.fees add column if not exists discount numeric(12,2) default 0;
alter table public.fees add column if not exists due_amount numeric(12,2) default 0;
alter table public.fees add column if not exists due_date date;
alter table public.fees add column if not exists billing_month date;
alter table public.fees add column if not exists status text default 'due';
alter table public.fee_payments add column if not exists fee_id uuid;
alter table public.fee_payments add column if not exists student_id uuid;
alter table public.fee_payments add column if not exists amount numeric(12,2) default 0;
alter table public.fee_payments add column if not exists method text;
alter table public.fee_payments add column if not exists transaction_reference text;
alter table public.fee_payments add column if not exists receipt_number text;
alter table public.fee_payments add column if not exists collected_by uuid;
alter table public.fee_payments add column if not exists paid_at timestamptz default now();
alter table public.expenses add column if not exists category text;
alter table public.expenses add column if not exists amount numeric(12,2) default 0;
alter table public.expenses add column if not exists method text default 'Cash';
alter table public.expenses add column if not exists description text;
alter table public.expenses add column if not exists expense_date date default current_date;
alter table public.expenses add column if not exists added_by uuid;
alter table public.salaries add column if not exists staff_id uuid;
alter table public.salaries add column if not exists month date;
alter table public.salaries add column if not exists basic numeric(12,2) default 0;
alter table public.salaries add column if not exists bonus numeric(12,2) default 0;
alter table public.salaries add column if not exists deduction numeric(12,2) default 0;
alter table public.salaries add column if not exists payable numeric(12,2) default 0;
alter table public.salaries add column if not exists paid numeric(12,2) default 0;
alter table public.salaries add column if not exists due numeric(12,2) default 0;
alter table public.salaries add column if not exists payment_date date;
alter table public.salaries add column if not exists method text;

-- Backfill teacher display name where an old schema used full_name.
update public.teachers set name=coalesce(nullif(name,''),full_name) where name is null or name='';
update public.teachers set full_name=coalesce(nullif(full_name,''),name) where full_name is null or full_name='';

-- ============================================================
-- 3. ACADEMIC / COMMUNICATION / SAAS TABLES
-- ============================================================
create table if not exists public.homework (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, batch_id uuid, teacher_id uuid,
 title text not null, description text, deadline date, attachment_url text, created_at timestamptz default now()
);
create table if not exists public.assignments (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, batch_id uuid, teacher_id uuid,
 title text not null, description text, deadline date, attachment_url text, created_at timestamptz default now()
);
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, batch_id uuid, name text not null,
 exam_date date, created_at timestamptz default now()
);
create table if not exists public.exam_subjects (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, exam_id uuid not null,
 subject_name text not null, total_marks numeric(10,2) default 100
);
create table if not exists public.results (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, exam_id uuid not null,
 exam_subject_id uuid, student_id uuid not null, marks numeric(10,2), grade text, remarks text, created_at timestamptz default now()
);
create table if not exists public.enquiries (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, name text not null, phone text,
 course_id uuid, batch_id uuid, source text, notes text, follow_up_date date, status text not null default 'new', created_at timestamptz default now()
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), institute_id uuid, recipient_user_id uuid, user_id uuid,
 title text not null, body text, message text, type text default 'info', read_at timestamptz, is_read boolean default false, created_at timestamptz default now()
);
create table if not exists public.subscription_plans (
 id uuid primary key default gen_random_uuid(), name text not null, description text, price numeric(12,2), monthly_price numeric(12,2) default 0,
 yearly_price numeric(12,2) default 0, billing_period text default 'monthly', limits_json jsonb default '{}'::jsonb,
 features_json jsonb default '{}'::jsonb, max_students integer, max_teachers integer, features jsonb default '{}'::jsonb,
 status text not null default 'active'
);
create table if not exists public.subscriptions (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, plan_id uuid, status text not null default 'trial',
 trial_start timestamptz default now(), trial_end timestamptz default now()+interval '30 days', start_date timestamptz,
 end_date timestamptz, billing_cycle text default 'monthly', starts_at timestamptz, trial_ends_at timestamptz,
 current_period_start timestamptz, current_period_end timestamptz, created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists public.subscription_payments (
 id uuid primary key default gen_random_uuid(), institute_id uuid not null, subscription_id uuid,
 amount numeric(12,2) not null, method text, transaction_reference text, proof_url text, status text default 'pending',
 reviewed_by uuid, reviewed_at timestamptz, rejection_reason text, payment_date date, note text, created_at timestamptz default now()
);
create table if not exists public.platform_admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz default now());
create table if not exists public.audit_logs (
 id uuid primary key default gen_random_uuid(), institute_id uuid, actor_user_id uuid, action text not null,
 entity_type text, entity_id uuid, metadata_json jsonb default '{}'::jsonb, created_at timestamptz default now()
);

-- ============================================================
-- 4. INDEXES / INTEGRITY
-- ============================================================
create unique index if not exists uq_students_institute_student_id on public.students(institute_id,student_id) where student_id is not null;
create unique index if not exists uq_batch_students on public.batch_students(institute_id,batch_id,student_id);
create unique index if not exists uq_attendance on public.attendance(institute_id,batch_id,student_id,date);
create unique index if not exists uq_receipt on public.fee_payments(institute_id,receipt_number) where receipt_number is not null;
create index if not exists idx_students_tenant on public.students(institute_id,status);
create index if not exists idx_batches_tenant on public.batches(institute_id,status);
create index if not exists idx_fees_tenant on public.fees(institute_id,student_id,status,due_date);
create index if not exists idx_payments_tenant on public.fee_payments(institute_id,paid_at desc);
create index if not exists idx_attendance_tenant on public.attendance(institute_id,batch_id,date);
create index if not exists idx_routines_tenant on public.routines(institute_id,batch_id);
create index if not exists idx_expenses_tenant on public.expenses(institute_id,expense_date);
create index if not exists idx_salaries_tenant on public.salaries(institute_id,month);

-- ============================================================
-- 5. RLS — tenant isolation
-- ============================================================
create or replace function public.is_super_admin() returns boolean language sql security definer stable set search_path=public as $$
 select exists(select 1 from public.platform_admins where user_id=auth.uid()) or public.get_my_role()='super_admin';
$$;
grant execute on function public.is_super_admin() to authenticated;

-- Apply RLS to every tenant table. Policies are deliberately based on server-side tenant lookup.
do $$
declare t text; begin
  foreach t in array array['institutes','profiles','students','teachers','courses','batches','batch_students','attendance','fees','fee_payments','routines','expenses','salaries','homework','assignments','exams','exam_subjects','results','enquiries','notifications','subscriptions','subscription_payments','audit_logs'] loop
    execute format('alter table public.%I enable row level security',t);
  end loop;
end $$;

-- Helper creates the same four tenant policies if the table has institute_id.
do $$
declare t text; begin
  foreach t in array array['students','teachers','courses','batches','batch_students','attendance','fees','fee_payments','routines','expenses','salaries','homework','assignments','exams','exam_subjects','results','enquiries','subscriptions','subscription_payments','audit_logs'] loop
    execute format('drop policy if exists "tenant_select" on public.%I',t);
    execute format('drop policy if exists "tenant_insert" on public.%I',t);
    execute format('drop policy if exists "tenant_update" on public.%I',t);
    execute format('drop policy if exists "tenant_delete" on public.%I',t);
    execute format('create policy "tenant_select" on public.%I for select to authenticated using (institute_id=public.get_my_institute_id() or public.is_super_admin())',t);
    execute format('create policy "tenant_insert" on public.%I for insert to authenticated with check (institute_id=public.get_my_institute_id() or public.is_super_admin())',t);
    execute format('create policy "tenant_update" on public.%I for update to authenticated using (institute_id=public.get_my_institute_id() or public.is_super_admin()) with check (institute_id=public.get_my_institute_id() or public.is_super_admin())',t);
    execute format('create policy "tenant_delete" on public.%I for delete to authenticated using (institute_id=public.get_my_institute_id() or public.is_super_admin())',t);
  end loop;
end $$;

-- Student own-data policy is layered on top of tenant policy for reads; admin/staff remain tenant scoped.
drop policy if exists "student_own_read" on public.students;
create policy "student_own_read" on public.students for select to authenticated using (institute_id=public.get_my_institute_id() and (user_id=auth.uid() or public.get_my_role() <> 'student'));

-- Profiles: own profile or super admin.
drop policy if exists "profile_self_read" on public.profiles;
drop policy if exists "profile_self_update" on public.profiles;
create policy "profile_self_read" on public.profiles for select to authenticated using (id=auth.uid() or public.is_super_admin());
create policy "profile_self_update" on public.profiles for update to authenticated using (id=auth.uid() or public.is_super_admin()) with check (id=auth.uid() or public.is_super_admin());

-- Institutes: member can read own, admin can update own, super admin can see all.
drop policy if exists "institute_read" on public.institutes;
drop policy if exists "institute_update" on public.institutes;
create policy "institute_read" on public.institutes for select to authenticated using (id=public.get_my_institute_id() or public.is_super_admin());
create policy "institute_update" on public.institutes for update to authenticated using (id=public.get_my_institute_id() or public.is_super_admin()) with check (id=public.get_my_institute_id() or public.is_super_admin());

-- Notifications may be global or tenant-specific; recipient can see own global messages.
drop policy if exists "notification_select" on public.notifications;
drop policy if exists "notification_insert" on public.notifications;
drop policy if exists "notification_update" on public.notifications;
create policy "notification_select" on public.notifications for select to authenticated using ((institute_id is null and (recipient_user_id=auth.uid() or user_id=auth.uid() or public.is_super_admin())) or institute_id=public.get_my_institute_id() or public.is_super_admin());
create policy "notification_insert" on public.notifications for insert to authenticated with check (institute_id is null or institute_id=public.get_my_institute_id() or public.is_super_admin());
create policy "notification_update" on public.notifications for update to authenticated using (institute_id=public.get_my_institute_id() or recipient_user_id=auth.uid() or user_id=auth.uid() or public.is_super_admin()) with check (institute_id=public.get_my_institute_id() or recipient_user_id=auth.uid() or user_id=auth.uid() or public.is_super_admin());

-- ============================================================
-- 6. FINANCIAL RPC: atomic payment + receipt + fee due update
-- ============================================================
create or replace function public.create_payment_and_receipt(
 p_fee_id uuid, p_amount numeric, p_method text, p_transaction_reference text default null
) returns jsonb language plpgsql security definer set search_path=public as $$
declare f public.fees%rowtype; v_paid numeric; v_due numeric; v_receipt text; v_id uuid;
begin
 if auth.uid() is null then raise exception 'You must be logged in'; end if;
 if p_amount is null or p_amount<=0 then raise exception 'Payment amount must be greater than zero'; end if;
 select * into f from public.fees where id=p_fee_id and institute_id=public.get_my_institute_id() for update;
 if not found then raise exception 'Fee not found'; end if;
 select coalesce(sum(amount),0) into v_paid from public.fee_payments where fee_id=f.id and institute_id=f.institute_id;
 v_due:=greatest(0,coalesce(f.amount,0)-coalesce(f.discount,0)-v_paid);
 if p_amount>v_due then raise exception 'Payment exceeds current due amount'; end if;
 v_receipt:='EL-'||to_char(now(),'YYYYMMDDHH24MISSMS')||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6);
 insert into public.fee_payments(institute_id,student_id,fee_id,amount,method,transaction_reference,receipt_number,collected_by,paid_at)
 values(f.institute_id,f.student_id,f.id,p_amount,p_method,p_transaction_reference,v_receipt,auth.uid(),now()) returning id into v_id;
 v_paid:=v_paid+p_amount; v_due:=greatest(0,coalesce(f.amount,0)-coalesce(f.discount,0)-v_paid);
 update public.fees set due_amount=v_due,status=case when v_due=0 then 'paid' when v_paid>0 then 'partial' else 'due' end where id=f.id;
 insert into public.audit_logs(institute_id,actor_user_id,action,entity_type,entity_id,metadata_json) values(f.institute_id,auth.uid(),'payment_created','fee_payment',v_id,jsonb_build_object('amount',p_amount,'receipt',v_receipt));
 return jsonb_build_object('payment_id',v_id,'receipt_number',v_receipt,'due_amount',v_due);
end;
$$;
grant execute on function public.create_payment_and_receipt(uuid,numeric,text,text) to authenticated;

-- ============================================================
-- 7. SUBSCRIPTION HELPERS
-- ============================================================
create or replace function public.ensure_trial_subscription() returns uuid language plpgsql security definer set search_path=public as $$
declare v_inst uuid:=public.get_my_institute_id(); v_id uuid; begin
 if v_inst is null then raise exception 'Institute not found'; end if;
 select id into v_id from public.subscriptions where institute_id=v_inst order by created_at desc limit 1;
 if v_id is null then insert into public.subscriptions(institute_id,status,trial_start,trial_end,trial_ends_at,current_period_start,current_period_end) values(v_inst,'trial',now(),now()+interval '30 days',now()+interval '30 days',now(),now()+interval '30 days') returning id into v_id; end if;
 return v_id; end;
$$;
grant execute on function public.ensure_trial_subscription() to authenticated;

create or replace function public.refresh_subscription_status() returns void language plpgsql security definer set search_path=public as $$
begin update public.subscriptions set status='expired',updated_at=now() where status='trial' and trial_end<now(); end; $$;
grant execute on function public.refresh_subscription_status() to authenticated;

create or replace function public.submit_subscription_payment(p_subscription_id uuid,p_requested_plan_id uuid,p_amount numeric,p_method text,p_reference text default null,p_payment_date date default current_date,p_note text default null) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_inst uuid:=public.get_my_institute_id(); begin
 if p_amount<=0 then raise exception 'Amount must be greater than zero'; end if;
 if not exists(select 1 from public.subscriptions where id=p_subscription_id and institute_id=v_inst) then raise exception 'Subscription not found'; end if;
 insert into public.subscription_payments(institute_id,subscription_id,amount,method,transaction_reference,status,payment_date,note) values(v_inst,p_subscription_id,p_amount,p_method,p_reference,'pending',p_payment_date,p_note) returning id into v_id;
 update public.subscriptions set plan_id=p_requested_plan_id,updated_at=now() where id=p_subscription_id;
 return v_id; end;
$$;
grant execute on function public.submit_subscription_payment(uuid,uuid,numeric,text,text,date,text) to authenticated;

-- Seed one configurable plan only if none exists; pricing is clearly editable, not a business truth.
do $$ begin if not exists(select 1 from public.subscription_plans) then insert into public.subscription_plans(name,description,monthly_price,yearly_price,status) values('Starter','Configurable starter plan',0,0,'active'); end if; end $$;

-- Storage bucket for student photos.
insert into storage.buckets(id,name,public) values('student-photos','student-photos',true) on conflict(id) do nothing;

-- Refresh PostgREST schema cache.
notify pgrst,'reload schema';

select 'Easylearn Master Bootstrap completed' as status;
