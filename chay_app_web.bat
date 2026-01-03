@echo off
echo Dang chuan bi khoi dong Ung dung Quan Ly Bao Hanh (Web/Chrome)...
cd /d "%~dp0"
if exist "web" (
    echo Dang build va chay ung dung tren Chrome...
    flutter run -d chrome
) else (
    echo Loi: Khong tim thay thu muc ma nguon Web.
)
pause
