-- Easylearn Institute production fee-payment authorization hardening.
-- This migration is intentionally small and idempotent.
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
  update public.fees set paid_amount=v_paid,due_amount=v_due,status=v_status where id=v_fee.id and institute_id=v_institute_id;
  return jsonb_build_object('payment_id',v_payment_id,'fee_id',v_fee.id,'receipt_number',v_receipt,'paid_amount',v_paid,'due_amount',v_due,'status',v_status);
end;
$function$;
grant execute on function public.create_payment_and_receipt(numeric,uuid,text,text) to authenticated;
revoke execute on function public.create_payment_and_receipt(numeric,uuid,text,text) from anon;
