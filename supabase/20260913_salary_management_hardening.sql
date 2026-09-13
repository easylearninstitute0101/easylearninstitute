-- Easylearn Institute — Salary Management hardening
-- Safe to run after 20260911_staff_salary.sql

create unique index if not exists uq_salaries_institute_staff_month
  on public.salaries(institute_id, staff_id, month)
  where staff_id is not null and month is not null;

create index if not exists idx_salaries_institute_payment_date
  on public.salaries(institute_id, payment_date desc);

create or replace function public.validate_salary_record()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_payable numeric(12,2);
  v_due numeric(12,2);
begin
  if new.basic < 0 or new.bonus < 0 or new.deduction < 0 or new.paid < 0 then
    raise exception 'Salary amounts cannot be negative';
  end if;
  v_payable := round(new.basic + new.bonus - new.deduction, 2);
  if v_payable < 0 then
    raise exception 'Deduction cannot exceed basic plus bonus';
  end if;
  if new.paid > v_payable then
    raise exception 'Paid amount cannot exceed payable salary';
  end if;
  new.payable := v_payable;
  new.due := round(greatest(0, v_payable - new.paid), 2);
  if new.paid > 0 and new.payment_date is null then
    new.payment_date := current_date;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_salary_record on public.salaries;
create trigger trg_validate_salary_record
before insert or update on public.salaries
for each row execute function public.validate_salary_record();

-- Management-only writes; all authenticated institute members may read.
drop policy if exists "Institute members can insert salaries" on public.salaries;
drop policy if exists "Institute members can update salaries" on public.salaries;
drop policy if exists "Institute members can delete salaries" on public.salaries;
create policy "Salary management can insert" on public.salaries
for insert to authenticated
with check (institute_id = public.get_my_institute_id() and public.can_manage_institute());
create policy "Salary management can update" on public.salaries
for update to authenticated
using (institute_id = public.get_my_institute_id() and public.can_manage_institute())
with check (institute_id = public.get_my_institute_id() and public.can_manage_institute());
create policy "Salary management can delete" on public.salaries
for delete to authenticated
using (institute_id = public.get_my_institute_id() and public.can_manage_institute());
