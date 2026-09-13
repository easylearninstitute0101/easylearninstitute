-- Easylearn Institute: Expenses + Profit/Loss foundation
-- Run after the existing core schema/RLS migrations.

alter table public.expenses add column if not exists category text;
alter table public.expenses add column if not exists amount numeric(12,2) not null default 0;
alter table public.expenses add column if not exists method text default 'Cash';
alter table public.expenses add column if not exists description text;
alter table public.expenses add column if not exists expense_date date;
alter table public.expenses add column if not exists added_by uuid;

create index if not exists idx_expenses_institute_date on public.expenses(institute_id, expense_date desc);
create index if not exists idx_expenses_institute_category on public.expenses(institute_id, category);

alter table public.expenses enable row level security;

drop policy if exists "Institute members can view expenses" on public.expenses;
drop policy if exists "Institute members can insert expenses" on public.expenses;
drop policy if exists "Institute members can update expenses" on public.expenses;
drop policy if exists "Institute members can delete expenses" on public.expenses;
create policy "Institute members can view expenses" on public.expenses for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert expenses" on public.expenses for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update expenses" on public.expenses for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete expenses" on public.expenses for delete to authenticated using (institute_id = public.get_my_institute_id());

-- Business validation. Keep finalized financial data auditable; do not silently delete finalized payment rows.
alter table public.expenses drop constraint if exists expenses_amount_positive;
alter table public.expenses add constraint expenses_amount_positive check (amount > 0);
