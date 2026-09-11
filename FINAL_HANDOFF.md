# Easylearn Institute — Final Handoff

This package is the consolidated final pass for the current Flutter web build.

## Included
- Flutter source project
- Premium blue/white UI pass
- Dashboard counts load independently, so a payment-query problem cannot blank the other counts
- Dashboard summary arrows open the matching module
- Quick actions refresh dashboard data after returning
- Fees compatibility for `fee_type`, `discount`, and `due_amount`
- Idempotent Supabase compatibility/RLS patch

## One-time Supabase step
Open Supabase SQL Editor and run the complete file:
`supabase/FINAL_COMPATIBILITY_PATCH.sql`

This is intended to be safe to run on the current database.

## Local build
From the project folder:
`flutter pub get`
then:
`flutter build web --release`

The deployable web output is `build/web`.

## Important
This package is production-oriented, but a true store/release certification still requires the final environment's build/signing, QA, and deployment checks.
