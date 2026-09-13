-- Easylearn Institute: Fees/Due hardening
-- Keeps fee balances authoritative in the database.

create or replace function public.validate_fee_payment_link()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fee_institute uuid;
  v_fee_amount numeric;
  v_fee_discount numeric;
  v_paid_other numeric;
begin
  select institute_id, amount, discount
    into v_fee_institute, v_fee_amount, v_fee_discount
  from public.fees
  where id = new.fee_id;

  if v_fee_institute is null then
    raise exception 'Fee record not found';
  end if;
  if new.institute_id <> v_fee_institute then
    raise exception 'Fee and payment institute do not match';
  end if;
  if new.amount <= 0 then
    raise exception 'Payment amount must be greater than zero';
  end if;

  select coalesce(sum(amount),0) into v_paid_other
  from public.fee_payments
  where fee_id = new.fee_id
    and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);

  if v_paid_other + new.amount > greatest(0, v_fee_amount - coalesce(v_fee_discount,0)) then
    raise exception 'Payment exceeds the current fee balance';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_fee_payment_link on public.fee_payments;
create trigger trg_validate_fee_payment_link
before insert or update on public.fee_payments
for each row execute function public.validate_fee_payment_link();

create or replace function public.refresh_fee_balance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fee_id uuid;
  v_amount numeric;
  v_discount numeric;
  v_paid numeric;
begin
  v_fee_id := coalesce(new.fee_id, old.fee_id);
  if v_fee_id is null then return coalesce(new, old); end if;

  select amount, discount into v_amount, v_discount
  from public.fees where id = v_fee_id;

  if v_amount is null then return coalesce(new, old); end if;

  select coalesce(sum(amount),0) into v_paid
  from public.fee_payments where fee_id = v_fee_id;

  update public.fees
  set due_amount = greatest(0, v_amount - coalesce(v_discount,0) - v_paid),
      status = case
        when greatest(0, v_amount - coalesce(v_discount,0) - v_paid) <= 0 then 'paid'
        when v_paid > 0 then 'partial'
        else 'due'
      end,
      updated_at = now()
  where id = v_fee_id;

  if tg_op = 'UPDATE' and old.fee_id is distinct from new.fee_id then
    select amount, discount into v_amount, v_discount from public.fees where id = old.fee_id;
    if v_amount is not null then
      select coalesce(sum(amount),0) into v_paid from public.fee_payments where fee_id = old.fee_id;
      update public.fees
      set due_amount = greatest(0, v_amount - coalesce(v_discount,0) - v_paid),
          status = case
            when greatest(0, v_amount - coalesce(v_discount,0) - v_paid) <= 0 then 'paid'
            when v_paid > 0 then 'partial'
            else 'due'
          end,
          updated_at = now()
      where id = old.fee_id;
    end if;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_refresh_fee_balance on public.fee_payments;
create trigger trg_refresh_fee_balance
after insert or update or delete on public.fee_payments
for each row execute function public.refresh_fee_balance();

-- Recalculate all existing fee balances once after installing the triggers.
update public.fees f
set due_amount = greatest(0, f.amount - coalesce(f.discount,0) - coalesce(p.paid,0)),
    status = case
      when greatest(0, f.amount - coalesce(f.discount,0) - coalesce(p.paid,0)) <= 0 then 'paid'
      when coalesce(p.paid,0) > 0 then 'partial'
      else 'due'
    end,
    updated_at = now()
from (
  select f2.id, coalesce(sum(fp.amount),0) paid
  from public.fees f2
  left join public.fee_payments fp on fp.fee_id = f2.id
  group by f2.id
) p
where f.id = p.id;
