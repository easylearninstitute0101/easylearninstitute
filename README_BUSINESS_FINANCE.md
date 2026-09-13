# Business Finance — Progress 9

This milestone adds real Supabase-backed Expenses and monthly Profit/Loss views.

## Supabase migration
Run:
`supabase/20260911_business_finance.sql`

## Rules
- All expense rows are tenant-scoped by `institute_id` and protected by RLS.
- Expense amount must be greater than zero.
- Profit/Loss is calculated as fee collections minus general expenses minus salary paid for the selected month.
- Salary is displayed separately in the calculation so payroll cost is visible.
