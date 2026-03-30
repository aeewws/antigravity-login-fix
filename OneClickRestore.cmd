@echo off
setlocal
title Antigravity Login Fix - One Click Restore
echo.
echo [antigravity-login-fix] Restoring from backup...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore.ps1" -Force
set "EXITCODE=%errorlevel%"
echo.
if "%EXITCODE%"=="0" (
  echo Restore finished successfully.
) else (
  echo Restore failed with exit code %EXITCODE%.
)
echo.
pause
exit /b %EXITCODE%
