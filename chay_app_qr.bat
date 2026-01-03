@echo off
echo Dang chuan bi khoi dong Ung dung Quan Ly Bao Hanh (QR)...
cd /d "%~dp0"
if exist "windows" (
    echo Dang build va chay ung dung tren Windows...
    flutter run -d windows
) else (
    echo Loi: Khong tim thay thu muc ma nguon Windows.
)
pause
