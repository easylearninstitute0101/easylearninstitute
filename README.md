# Easylearn Institute — Flutter Final Build

Canonical target: Flutter + Supabase/PostgreSQL, Bangla/English, BDT, multi-tenant RLS.

## One-time setup
1. Install Flutter and run `flutter doctor`.
2. Open this folder in Android Studio or VS Code.
3. Run `flutter pub get`.
4. In `lib/core/app_config.dart`, put your Supabase URL and publishable key.
5. In Supabase SQL Editor, run `supabase/00_MASTER_BOOTSTRAP.sql` once.
6. Run `flutter run`.

The app intentionally uses only the Supabase publishable/anon key on the client. Never put a service_role key in Flutter.

## Included modules
Auth, institute setup/trial, dashboard, students, staff, courses, batches, batch enrollment, attendance, fees/payments/receipts, routine, homework, assignments, exams/results, enquiries, salary, expenses, profit/loss, reports, notifications, archives/settings, subscriptions.

## Production note
This package is a complete implementation baseline and must still pass the live Supabase/RLS, device, Play Store/App Store and production monitoring checks described in the Blueprint before public release.
