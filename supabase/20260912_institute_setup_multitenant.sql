-- Easylearn Institute: true institute onboarding / multi-tenant setup
-- Run after the existing core, roles and SaaS migrations.

create or replace function public.create_my_institute(
  p_name text,
  p_phone text default null,
  p_email text default null,
  p_type text default null,
  p_address text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_existing uuid;
  v_inst uuid;
  v_trial_plan uuid;
begin
  if v_user is null then
    raise exception 'You must be logged in';
  end if;
  if nullif(trim(p_name), '') is null then
    raise exception 'Institute name is required';
  end if;

  select institute_id into v_existing
  from public.profiles
  where id = v_user;

  if v_existing is not null then
    raise exception 'Your account is already linked to an institute';
  end if;

  insert into public.institutes(name, phone, email, type, address, status)
  values(trim(p_name), nullif(trim(p_phone),''), nullif(trim(p_email),''), nullif(trim(p_type),''), nullif(trim(p_address),''), 'active')
  returning id into v_inst;

  update public.profiles
  set institute_id = v_inst,
      full_name = coalesce(nullif(full_name,''), coalesce((select raw_user_meta_data->>'full_name' from auth.users where id=v_user), full_name))
  where id = v_user;

  if not exists(select 1 from public.subscription_plans where name='Trial') then
    insert into public.subscription_plans(name,monthly_price,yearly_price,max_students,max_teachers,features)
    values('Trial',0,0,100,10,'{"attendance":true,"fees":true,"academics":true,"reports":true,"portals":true}'::jsonb);
  end if;
  select id into v_trial_plan from public.subscription_plans where name='Trial' limit 1;
  if v_trial_plan is not null then
    insert into public.subscriptions(institute_id,plan_id,status,billing_cycle,starts_at,trial_ends_at,current_period_start,current_period_end)
    values(v_inst,v_trial_plan,'trial','monthly',now(),now()+interval '30 days',now(),now()+interval '30 days');
  end if;

  insert into public.audit_logs(institute_id,actor_user_id,action,entity_type,entity_id,details)
  values(v_inst,v_user,'institute_created','institute',v_inst::text,jsonb_build_object('name',trim(p_name)));

  return v_inst;
end;
$$;
grant execute on function public.create_my_institute(text,text,text,text,text) to authenticated;

create index if not exists idx_profiles_institute_id on public.profiles(institute_id);
