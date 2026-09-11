-- Easylearn Institute — final compatibility patch
-- Safe to run on the existing project. It only adds missing fee columns,
-- refreshes PostgREST, and ensures the core tenant policies exist.

alter table public.fees
  add column if not exists fee_type text;

alter table public.fees
  add column if not exists discount numeric(12,2) not null default 0;

alter table public.fees
  add column if not exists due_amount numeric(12,2) not null default 0;

update public.fees
set due_amount = greatest(0, coalesce(amount,0) - coalesce(discount,0))
where due_amount is null or due_amount = 0;

-- Core tenant policies. Existing policies with other names are left untouched.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='students' and policyname='final_students_select') then
    create policy final_students_select on public.students for select to authenticated
      using (institute_id = public.get_my_institute_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='students' and policyname='final_students_insert') then
    create policy final_students_insert on public.students for insert to authenticated
      with check (institute_id = public.get_my_institute_id());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='teachers' and policyname='final_teachers_select') then
    create policy final_teachers_select on public.teachers for select to authenticated
      using (institute_id = public.get_my_institute_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='teachers' and policyname='final_teachers_insert') then
    create policy final_teachers_insert on public.teachers for insert to authenticated
      with check (institute_id = public.get_my_institute_id());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='batches' and policyname='final_batches_select') then
    create policy final_batches_select on public.batches for select to authenticated
      using (institute_id = public.get_my_institute_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='batches' and policyname='final_batches_insert') then
    create policy final_batches_insert on public.batches for insert to authenticated
      with check (institute_id = public.get_my_institute_id());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='fees' and policyname='final_fees_select') then
    create policy final_fees_select on public.fees for select to authenticated
      using (institute_id = public.get_my_institute_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='fees' and policyname='final_fees_insert') then
    create policy final_fees_insert on public.fees for insert to authenticated
      with check (institute_id = public.get_my_institute_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='fees' and policyname='final_fees_update') then
    create policy final_fees_update on public.fees for update to authenticated
      using (institute_id = public.get_my_institute_id())
      with check (institute_id = public.get_my_institute_id());
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='fee_payments' and policyname='final_fee_payments_select') then
    create policy final_fee_payments_select on public.fee_payments for select to authenticated
      using (institute_id = public.get_my_institute_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='fee_payments' and policyname='final_fee_payments_insert') then
    create policy final_fee_payments_insert on public.fee_payments for insert to authenticated
      with check (institute_id = public.get_my_institute_id());
  end if;
end $$;

notify pgrst, 'reload schema';
