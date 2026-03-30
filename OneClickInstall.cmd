@echo off
setlocal
title Antigravity Login Fix - One Click Install
echo.
echo [antigravity-login-fix] Running one-click install...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Force
set "EXITCODE=%errorlevel%"
echo.
if "%EXITCODE%"=="0" (
  echo Install finished successfully.
) else (
  echo Install failed with exit code %EXITCODE%.
)
echo.
pause
exit /b %EXITCODE%
