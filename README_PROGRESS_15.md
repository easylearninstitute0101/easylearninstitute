# Easylearn Institute — Progress 15

Implemented the next production/business layer on top of Progress 14:

- SaaS subscription plans: Trial, Basic, Standard, Premium
- Per-institute subscription lifecycle: trial / active / past_due / suspended / cancelled / expired
- Automatic 30-day Trial subscription creation through a secure RPC
- Monthly/yearly billing-cycle fields
- Manual subscription payment submission for Cash, bKash, Nagad, Rocket and Bank
- Platform-admin-only payment approval/rejection RPC
- Subscription expiry refresh function
- Platform admin foundation
- Tenant-scoped audit log foundation
- RLS for plans, subscriptions, subscription payments, platform admins and audit logs

## SQL
Run after Progress 14:
`supabase/20260911_saas_subscription_lifecycle.sql`

Before using payment approval in production, add the intended Super Admin auth user UUID to `public.platform_admins`. Never expose a service-role key in the frontend.

This is still a development build, not the final production release.

## Frontend
- Added **Subscription & Billing** page for institute admins/managers.
- Automatically ensures a 30-day trial subscription exists for a newly initialized institute.
- Shows current plan/status/period limits.
- Shows available plans and lets an institute submit a payment against a requested plan.
- Payment submission is routed through a secure RPC and remains pending until platform review.
