# Authentication — Finalized

Includes real Supabase email/password login, registration, logout, forgot-password email, password recovery/update, session persistence, URL recovery detection, input validation, and user-friendly network/configuration errors.

## Local setup
1. Copy `.env.example` to `.env`.
2. Put the Supabase Project URL and Publishable/anon key in `.env`.
3. Run `npm.cmd install`.
4. Run `npm.cmd run dev`.

## Supabase Dashboard
Add these redirect URLs for local and production as appropriate:
- `http://localhost:5173/**`
- `https://easylearninstitute.vercel.app/**`

Never put a service_role/secret key in the frontend.
