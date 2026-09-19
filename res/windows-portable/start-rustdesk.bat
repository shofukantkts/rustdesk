@echo off
rem ============================================================
rem  RustDesk portable launcher (viewer / control side)
rem  First run: copies RustDesk2.toml (server endpoints etc.)
rem  into %APPDATA%\RustDesk\config\ then starts rustdesk.exe.
rem  Later runs: keeps the machine's own config untouched.
rem  NOTE: run this bat instead of rustdesk.exe directly, or the
rem  preconfigured endpoints will not be applied.
rem ============================================================
setlocal
set "CFGDIR=%APPDATA%\RustDesk\config"
if not exist "%CFGDIR%\RustDesk2.toml" (
    mkdir "%CFGDIR%" 2>nul
    copy /y "%~dp0RustDesk2.toml" "%CFGDIR%\RustDesk2.toml" >nul && echo [config] endpoints imported.
) else (
    echo [config] %CFGDIR%\RustDesk2.toml already exists, kept as-is.
)
start "" "%~dp0rustdesk.exe"
endlocal
