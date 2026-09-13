-- Easylearn Institute FINAL: SaaS Admin + Notice/Announcement + security runtime
-- This migration is already applied to the production Supabase project.

-- Runtime/platform functions
create or replace function public.is_platform_admin()
returns boolean language sql security definer set search_path=public stable as $$
  select exists(select 1 from public.platform_admins where user_id=auth.uid());
$$;
grant execute on function public.is_platform_admin() to authenticated;

create or replace function public.get_platform_admin_overview()
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_institutes jsonb; v_payments jsonb; v_amount numeric;
begin
  if not public.is_platform_admin() then raise exception 'Platform admin access required'; end if;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) into v_institutes
  from (select i.id,i.name,i.status,i.created_at,sp.name plan_name,s.status subscription_status,s.current_period_end period_end
        from public.institutes i
        left join lateral (select * from public.subscriptions s0 where s0.institute_id=i.id order by s0.created_at desc limit 1) s on true
        left join public.subscription_plans sp on sp.id=s.plan_id) x;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb),coalesce(sum(x.amount),0) into v_payments,v_amount
  from (select p.id,p.institute_id,p.amount,p.method,p.transaction_reference,p.payment_date,p.created_at,i.name institute_name,sp.name requested_plan_name
        from public.subscription_payments p join public.institutes i on i.id=p.institute_id
        left join public.subscription_plans sp on sp.id=p.requested_plan_id where p.status='pending') x;
  return jsonb_build_object('institutes',v_institutes,'pending_payments',v_payments,'pending_amount',v_amount);
end; $$;
grant execute on function public.get_platform_admin_overview() to authenticated;

-- Notice/announcement fields and secure creator RPC
alter table public.notifications add column if not exists audience_role text check(audience_role in ('admin','manager','teacher','staff','student') or audience_role is null);
alter table public.notifications add column if not exists priority text not null default 'normal' check(priority in ('normal','important','urgent'));
alter table public.notifications add column if not exists expires_at timestamptz;
alter table public.notifications add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.notifications add column if not exists source_type text;
alter table public.notifications add column if not exists source_id text;
create unique index if not exists uq_notifications_source on public.notifications(institute_id,source_type,source_id) where source_type is not null and source_id is not null;

create or replace function public.create_notice(p_title text,p_message text,p_audience_role text default null,p_priority text default 'normal',p_expires_at timestamptz default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_inst uuid; v_role text; v_id uuid;
begin
  v_inst:=public.get_my_institute_id(); if v_inst is null then raise exception 'Institute not found'; end if;
  v_role:=public.get_my_role(); if v_role not in ('admin','manager') then raise exception 'Only admin or manager can create notices'; end if;
  if p_title is null or length(trim(p_title))=0 then raise exception 'Notice title is required'; end if;
  if p_message is null or length(trim(p_message))=0 then raise exception 'Notice message is required'; end if;
  if p_audience_role is not null and p_audience_role not in ('admin','manager','teacher','staff','student') then raise exception 'Invalid audience'; end if;
  if p_priority not in ('normal','important','urgent') then raise exception 'Invalid priority'; end if;
  insert into public.notifications(institute_id,user_id,title,message,type,is_read,audience_role,priority,expires_at,created_by)
  values(v_inst,null,trim(p_title),trim(p_message),'notice',false,p_audience_role,p_priority,p_expires_at,auth.uid()) returning id into v_id;
  return v_id;
end; $$;
grant execute on function public.create_notice(text,text,text,text,timestamptz) to authenticated;

-- RLS is enabled on every application table in the final database; notifications are role-targeted.
drop policy if exists "easylearn_notifications_all" on public.notifications;
drop policy if exists "final_notifications_select" on public.notifications;
create policy "final_notifications_select" on public.notifications for select to authenticated using(
  institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null)
  and (audience_role is null or audience_role=public.get_my_role()) and (expires_at is null or expires_at>now())
);
drop policy if exists "final_notifications_update" on public.notifications;
create policy "final_notifications_update" on public.notifications for update to authenticated using(
  institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null)
  and (audience_role is null or audience_role=public.get_my_role())
) with check(
  institute_id=public.get_my_institute_id() and (user_id=auth.uid() or user_id is null)
  and (audience_role is null or audience_role=public.get_my_role())
);
