@echo off
setlocal
cd /d "%~dp0"
echo [1/3] Checking Flutter...
flutter --version || goto :error
if not exist "android" (
  echo [2/3] Generating Android/iOS/web project folders...
  flutter create . || goto :error
) else (
  echo [2/3] Flutter platform folders already exist.
)
echo [3/3] Installing packages...
flutter pub get || goto :error
echo.
echo Setup complete. Put your Supabase values in lib\core\app_config.dart if needed.
echo Then run: flutter run
pause
exit /b 0
:error
echo.
echo Setup failed. Please run: flutter doctor
pause
exit /b 1
