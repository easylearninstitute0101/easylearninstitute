# Fees & Payments module

Progress 5 adds a real Supabase-backed Fees & Payments flow.

## Supabase migration
Run `supabase/20260910_fees_module.sql` in Supabase SQL Editor after the existing core schema and earlier Easylearn migrations.

## Included
- Fee records per student
- Discount and due date
- Paid / partial / due calculation from payment history
- Cash, bKash, Nagad, Rocket and Bank methods
- Transaction reference and receipt number
- Payment history per fee
- Tenant-scoped RLS policies
