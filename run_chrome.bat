@echo off
echo Menyiapkan direktori build bebas-OneDrive lock...
if not exist "C:\Users\User\AppData\Local\PosUmkmBuild" mkdir "C:\Users\User\AppData\Local\PosUmkmBuild"
if not exist "build" mklink /J "build" "C:\Users\User\AppData\Local\PosUmkmBuild"

if not exist "C:\Users\User\AppData\Local\PosUmkmChromeDevice" mkdir "C:\Users\User\AppData\Local\PosUmkmChromeDevice"
if not exist ".dart_tool\chrome-device" mklink /J ".dart_tool\chrome-device" "C:\Users\User\AppData\Local\PosUmkmChromeDevice"

if not exist "C:\Users\User\AppData\Local\PosUmkmFlutterBuild" mkdir "C:\Users\User\AppData\Local\PosUmkmFlutterBuild"
if not exist ".dart_tool\flutter_build" mklink /J ".dart_tool\flutter_build" "C:\Users\User\AppData\Local\PosUmkmFlutterBuild"

echo Menjalankan POS UMKM di Google Chrome...
C:\flutter\bin\flutter.bat run -d chrome
