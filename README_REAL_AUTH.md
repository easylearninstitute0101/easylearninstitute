# Easylearn Institute — Real Registration & Login

This version uses Supabase Auth for real email/password registration and login.

## Setup

1. Create a Supabase project.
2. In Supabase Dashboard, open Connect/API and copy the Project URL and Publishable key.
3. Create a file named `.env` in the project root.
4. Copy `.env.example` into `.env` and replace the two placeholder values.
5. Run `npm.cmd install`.
6. Run `npm.cmd run dev`.

Email/password Auth is enabled by default. Hosted Supabase projects normally require email confirmation before a new account can sign in. Add `http://localhost:5173/**` as a redirect URL if needed.

Important: never put a Supabase service_role/secret key in this frontend. Only the publishable/anon key belongs in `.env`.
