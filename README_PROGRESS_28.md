# Progress 28 — Salary Management

Completed salary management on top of the existing staff/salary foundation.

- Monthly salary records with basic, bonus, deduction, payable, paid and due.
- Automatic server-side payable/due validation.
- Prevents negative amounts and overpayment.
- Prevents duplicate payroll entries for the same staff/month.
- Monthly filter and staff search.
- Payroll summary: payable, paid and due.
- Edit and delete salary records.
- Payment method/date tracking.
- Management-only salary writes with tenant-scoped RLS.
- Existing Profit/Loss salary-paid calculation remains compatible.

Migration: `supabase/20260913_salary_management_hardening.sql`
