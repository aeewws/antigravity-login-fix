@echo off
setlocal
title Antigravity Login Fix - One Click Check
echo.
echo [antigravity-login-fix] Checking current patch status...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check.ps1"
set "EXITCODE=%errorlevel%"
echo.
pause
exit /b %EXITCODE%
