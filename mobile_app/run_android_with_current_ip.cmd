@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0tools\run_with_current_ip.ps1" %*
endlocal
