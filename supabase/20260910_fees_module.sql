-- Easylearn Institute: Fees & Payments module
-- Run after the existing core schema/RLS migration.

-- Add only missing fields so existing data is preserved.
alter table public.fees add column if not exists student_id uuid;
alter table public.fees add column if not exists amount numeric(12,2) not null default 0;
alter table public.fees add column if not exists fee_type text;
alter table public.fees add column if not exists discount numeric(12,2) not null default 0;
alter table public.fees add column if not exists due_amount numeric(12,2) not null default 0;
alter table public.fees add column if not exists due_date date;
alter table public.fees add column if not exists status text not null default 'due';

alter table public.fee_payments add column if not exists fee_id uuid;
alter table public.fee_payments add column if not exists student_id uuid;
alter table public.fee_payments add column if not exists amount numeric(12,2) not null default 0;
alter table public.fee_payments add column if not exists method text;
alter table public.fee_payments add column if not exists transaction_reference text;
alter table public.fee_payments add column if not exists receipt_number text;
alter table public.fee_payments add column if not exists collected_by uuid;
alter table public.fee_payments add column if not exists paid_at timestamptz not null default now();

create index if not exists idx_fees_institute_due_date on public.fees(institute_id, due_date);
create index if not exists idx_fees_institute_status on public.fees(institute_id, status);
create index if not exists idx_fee_payments_institute_paid_at on public.fee_payments(institute_id, paid_at desc);

alter table public.fees enable row level security;
alter table public.fee_payments enable row level security;

drop policy if exists "Institute members can view fees" on public.fees;
drop policy if exists "Institute members can insert fees" on public.fees;
drop policy if exists "Institute members can update fees" on public.fees;
drop policy if exists "Institute members can delete fees" on public.fees;
create policy "Institute members can view fees" on public.fees for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert fees" on public.fees for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update fees" on public.fees for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete fees" on public.fees for delete to authenticated using (institute_id = public.get_my_institute_id());

drop policy if exists "Institute members can view fee_payments" on public.fee_payments;
drop policy if exists "Institute members can insert fee_payments" on public.fee_payments;
drop policy if exists "Institute members can update fee_payments" on public.fee_payments;
drop policy if exists "Institute members can delete fee_payments" on public.fee_payments;
create policy "Institute members can view fee_payments" on public.fee_payments for select to authenticated using (institute_id = public.get_my_institute_id());
create policy "Institute members can insert fee_payments" on public.fee_payments for insert to authenticated with check (institute_id = public.get_my_institute_id());
create policy "Institute members can update fee_payments" on public.fee_payments for update to authenticated using (institute_id = public.get_my_institute_id()) with check (institute_id = public.get_my_institute_id());
create policy "Institute members can delete fee_payments" on public.fee_payments for delete to authenticated using (institute_id = public.get_my_institute_id());

-- Receipt numbers are unique inside an institute when present.
create unique index if not exists uq_fee_payments_institute_receipt
  on public.fee_payments(institute_id, receipt_number)
  where receipt_number is not null;
