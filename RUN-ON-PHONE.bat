@echo off
REM ============================================================
REM  Kengtung Guide - run the app on the USB-connected phone
REM  Just double-click this file.
REM ============================================================
title Kengtung Guide - running on phone
cd /d "%~dp0"

echo.
echo   Kengtung Guide
echo   ==============
echo.
echo   Looking for your phone...
echo.

adb devices

echo.
echo   If you do not see a line ending in "device" above:
echo     - check the USB cable is a DATA cable
echo     - unlock the phone and tap Allow on the popup
echo     - set USB mode to "File transfer"
echo.
echo   Starting the app. First build may take a minute.
echo.
echo   While it runs:
echo      r  = hot reload  (instant UI update)
echo      R  = hot restart (reload places.json too)
echo      q  = quit
echo.

flutter run

echo.
echo   The app has stopped.
pause
