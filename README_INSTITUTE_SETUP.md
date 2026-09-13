# Easylearn Institute — Multi-Institute & Institute Setup

Progress 16+ adds a true onboarding path for accounts that are not linked to an institute.

## Migration
Run:
`supabase/20260912_institute_setup_multitenant.sql`

## Flow
Register/Login → if profile has no `institute_id` → Institute Setup → Create Institute → automatic 30-day Trial → Dashboard.

Existing users already linked to an institute continue directly to their dashboard.

The browser never chooses an arbitrary existing institute. The secure RPC creates the new tenant and links the authenticated profile server-side.
