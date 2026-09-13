-- Easylearn Institute production alignment + security hardening
-- Safe/idempotent migration for the current production schema.

alter table public.fees add column if not exists billing_month date;
update public.fees set billing_month=date_trunc('month',created_at)::date where billing_month is null;
create index if not exists idx_fees_institute_billing_month on public.fees(institute_id,billing_month);
create unique index if not exists uq_fees_monthly_student_type on public.fees(institute_id,student_id,fee_type,billing_month) where billing_month is not null and fee_type is not null;

alter table public.fee_payments add column if not exists receipt_number text;
create unique index if not exists uq_fee_payments_receipt on public.fee_payments(institute_id,receipt_number) where receipt_number is not null;

alter table public.expenses add column if not exists method text;
update public.expenses set method='Cash' where method is null;
alter table public.expenses alter column method set default 'Cash';

create unique index if not exists uq_attendance_institute_batch_student_date
  on public.attendance(institute_id,batch_id,student_id,attendance_date);

-- Payment rows are immutable; creation is performed by the atomic RPC below.
drop policy if exists "Institute members can insert fee_payments" on public.fee_payments;
drop policy if exists "Institute members can update fee_payments" on public.fee_payments;
drop policy if exists "Institute members can delete fee_payments" on public.fee_payments;

create or replace function public.create_my_institute(p_name text,p_phone text default null,p_email text default null,p_type text default null,p_address text default null)
returns uuid language plpgsql security definer set search_path=public as $function$
declare v_user uuid:=auth.uid(); v_existing uuid; v_inst uuid; v_trial_plan uuid;
begin
  if v_user is null then raise exception 'You must be logged in'; end if;
  if nullif(trim(p_name),'') is null then raise exception 'Institute name is required'; end if;
  select institute_id into v_existing from public.profiles where id=v_user;
  if v_existing is not null then raise exception 'Your account is already linked to an institute'; end if;
  insert into public.institutes(name,phone,email,type,address,status)
  values(trim(p_name),nullif(trim(p_phone),''),nullif(trim(p_email),''),nullif(trim(p_type),''),nullif(trim(p_address),''),'active')
  returning id into v_inst;
  update public.profiles set institute_id=v_inst where id=v_user;
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
$function$;

create or replace function public.create_payment_and_receipt(p_amount numeric,p_fee_id uuid,p_method text,p_transaction_reference text default null)
returns jsonb language plpgsql security definer set search_path=public as $function$
declare
  v_user_id uuid:=auth.uid(); v_institute_id uuid; v_fee record; v_payment_id uuid; v_receipt text;
  v_paid numeric; v_due numeric; v_status text;
begin
  if v_user_id is null then raise exception 'You must be logged in'; end if;
  if p_amount is null or p_amount<=0 then raise exception 'Payment amount must be greater than zero'; end if;
  select institute_id into v_institute_id from public.profiles where id=v_user_id limit 1;
  if v_institute_id is null then raise exception 'Institute not found'; end if;
  if not public.can_manage_institute() then raise exception 'Only institute management can record payments'; end if;
  if lower(coalesce(trim(p_method),'')) not in ('cash','bkash','nagad','rocket','bank') then raise exception 'Invalid payment method'; end if;
  select id,institute_id,student_id,amount,coalesce(discount,0) discount,coalesce(paid_amount,0) paid_amount
  into v_fee from public.fees where id=p_fee_id and institute_id=v_institute_id for update;
  if not found then raise exception 'Fee not found'; end if;
  v_due:=greatest(0,coalesce(v_fee.amount,0)-v_fee.discount-v_fee.paid_amount);
  if p_amount>v_due then raise exception 'Payment amount cannot exceed current due amount'; end if;
  v_payment_id:=gen_random_uuid();
  v_receipt:='EL-'||to_char(current_date,'YYYYMMDD')||'-'||upper(substr(replace(v_payment_id::text,'-',''),1,8));
  insert into public.fee_payments(id,institute_id,fee_id,student_id,amount,payment_method,transaction_id,payment_date,received_by,receipt_number)
  values(v_payment_id,v_institute_id,v_fee.id,v_fee.student_id,p_amount,lower(trim(p_method)),nullif(trim(p_transaction_reference),''),current_date,v_user_id,v_receipt);
  v_paid:=v_fee.paid_amount+p_amount;
  v_due:=greatest(0,coalesce(v_fee.amount,0)-v_fee.discount-v_paid);
  v_status:=case when v_due<=0 then 'paid' when v_paid>0 then 'partial' else 'unpaid' end;
  update public.fees set paid_amount=v_paid,due_amount=v_due,status=v_status
  where id=v_fee.id and institute_id=v_institute_id;
  return jsonb_build_object('payment_id',v_payment_id,'fee_id',v_fee.id,'receipt_number',v_receipt,'paid_amount',v_paid,'due_amount',v_due,'status',v_status);
end;
$function$;

create or replace function public.ensure_my_institute()
returns uuid language plpgsql security definer set search_path=public as $function$
declare v_user_id uuid:=auth.uid(); v_institute_id uuid;
begin
  if v_user_id is null then raise exception 'You must be logged in'; end if;
  select institute_id into v_institute_id from public.profiles where id=v_user_id limit 1;
  return v_institute_id;
end;
$function$;

create or replace function public.get_my_role()
returns text language sql security definer set search_path=public stable as $function$
select coalesce((select role::text from public.profiles where id=auth.uid() limit 1),'student');
$function$;

create or replace function public.refresh_subscription_status()
returns void language plpgsql security definer set search_path=public as $function$
begin
  update public.subscriptions set status='expired',updated_at=now()
  where status='trial' and trial_ends_at is not null and trial_ends_at<now();
  update public.subscriptions set status='expired',updated_at=now()
  where status='active' and current_period_end is not null and current_period_end<now();
end;
$function$;

create or replace function public.set_member_role(target_user_id uuid,new_role text)
returns boolean language plpgsql security definer set search_path=public as $function$
declare caller_institute uuid; target_institute uuid;
begin
  if public.get_my_role()<>'admin' then raise exception 'Only an institute admin can change member roles'; end if;
  if new_role not in ('admin','manager','teacher','staff','student') then raise exception 'Invalid role'; end if;
  select institute_id into caller_institute from public.profiles where id=auth.uid() limit 1;
  select institute_id into target_institute from public.profiles where id=target_user_id limit 1;
  if caller_institute is null or target_institute is distinct from caller_institute then raise exception 'Member is outside your institute'; end if;
  if target_user_id=auth.uid() and new_role<>'admin' then raise exception 'You cannot remove your own admin role'; end if;
  update public.profiles set role=new_role where id=target_user_id;
  return true;
end;
$function$;

create or replace function public.link_member_record(target_user_id uuid,record_type text,record_id uuid)
returns boolean language plpgsql security definer set search_path=public as $function$
declare caller_institute uuid; target_institute uuid;
begin
  if public.get_my_role()<>'admin' then raise exception 'Only an institute admin can link portal accounts'; end if;
  select institute_id into caller_institute from public.profiles where id=auth.uid() limit 1;
  select institute_id into target_institute from public.profiles where id=target_user_id limit 1;
  if caller_institute is null or target_institute is distinct from caller_institute then raise exception 'Member is outside your institute'; end if;
  if record_type='student' then
    update public.students set user_id=target_user_id,updated_at=now() where id=record_id and institute_id=caller_institute;
  elsif record_type='teacher' then
    update public.teachers set user_id=target_user_id,updated_at=now() where id=record_id and institute_id=caller_institute;
  else raise exception 'Invalid record type'; end if;
  return true;
end;
$function$;

revoke execute on all functions in schema public from public;
revoke execute on all functions in schema public from anon;

grant execute on function public.can_manage_institute() to authenticated;
grant execute on function public.create_my_institute(text,text,text,text,text) to authenticated;
grant execute on function public.create_notice(text,text,text,text,timestamptz) to authenticated;
grant execute on function public.create_payment_and_receipt(numeric,uuid,text,text) to authenticated;
grant execute on function public.ensure_my_institute() to authenticated;
grant execute on function public.ensure_trial_subscription() to authenticated;
grant execute on function public.get_my_institute_id() to authenticated;
grant execute on function public.get_my_role() to authenticated;
grant execute on function public.get_platform_admin_overview() to authenticated;
grant execute on function public.is_institute_admin(uuid) to authenticated;
grant execute on function public.is_institute_member(uuid) to authenticated;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.review_subscription_payment(uuid,text,text) to authenticated;
grant execute on function public.refresh_subscription_status() to authenticated;
grant execute on function public.set_member_role(uuid,text) to authenticated;
grant execute on function public.link_member_record(uuid,text,uuid) to authenticated;
grant execute on function public.submit_subscription_payment(uuid,uuid,numeric,text,text,date,text) to authenticated;

revoke execute on function public.handle_new_user() from public,anon,authenticated;
revoke execute on function public.rls_auto_enable() from public,anon,authenticated;

alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon;
