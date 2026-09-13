-- Easylearn Institute — Expense Management hardening
-- Safe to run after the existing expenses/business-finance migrations.

alter table public.expenses add column if not exists category text;
alter table public.expenses add column if not exists amount numeric(12,2) not null default 0;
alter table public.expenses add column if not exists method text default 'Cash';
alter table public.expenses add column if not exists description text;
alter table public.expenses add column if not exists expense_date date;
alter table public.expenses add column if not exists added_by uuid;

create index if not exists idx_expenses_institute_date_created
  on public.expenses(institute_id, expense_date desc, created_at desc);
create index if not exists idx_expenses_institute_method
  on public.expenses(institute_id, method);

alter table public.expenses drop constraint if exists expenses_amount_positive;
alter table public.expenses add constraint expenses_amount_positive check (amount > 0);

-- Normalize payment methods used by the application.
alter table public.expenses drop constraint if exists expenses_method_check;
alter table public.expenses add constraint expenses_method_check
  check (method is null or method in ('Cash','bKash','Nagad','Rocket','Bank'));

alter table public.expenses enable row level security;

drop policy if exists "Institute members can view expenses" on public.expenses;
drop policy if exists "Institute members can insert expenses" on public.expenses;
drop policy if exists "Institute members can update expenses" on public.expenses;
drop policy if exists "Institute members can delete expenses" on public.expenses;

create policy "Institute members can view expenses" on public.expenses
for select to authenticated
using (institute_id = public.get_my_institute_id());

create policy "Expense management can insert" on public.expenses
for insert to authenticated
with check (institute_id = public.get_my_institute_id() and public.can_manage_institute());

create policy "Expense management can update" on public.expenses
for update to authenticated
using (institute_id = public.get_my_institute_id() and public.can_manage_institute())
with check (institute_id = public.get_my_institute_id() and public.can_manage_institute());

create policy "Expense management can delete" on public.expenses
for delete to authenticated
using (institute_id = public.get_my_institute_id() and public.can_manage_institute());

-- Server-side validation so financial records cannot bypass frontend checks.
create or replace function public.validate_expense_record()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.amount is null or new.amount <= 0 then
    raise exception 'Expense amount must be greater than zero';
  end if;
  if new.expense_date is null then
    raise exception 'Expense date is required';
  end if;
  if new.method is null or new.method not in ('Cash','bKash','Nagad','Rocket','Bank') then
    raise exception 'Invalid expense payment method';
  end if;
  if new.category is null or btrim(new.category) = '' then
    new.category := 'Other';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_expense_record on public.expenses;
create trigger trg_validate_expense_record
before insert or update on public.expenses
for each row execute function public.validate_expense_record();
