@echo off
setlocal

REM =========================
REM CONFIG
REM =========================
set VERSION=%1
set APP_NAME=Piscigranja
set INSTALLER_NAME=PiscigranjaInstaller.exe
set ISS_FILE=instalador.iss

IF "%VERSION%"=="" (
    echo ❌ Debes pasar la version. Ejemplo:
    echo release.bat 1.0.2
    exit /b
)

echo.
echo =========================
echo 🚀 INICIANDO RELEASE %VERSION%
echo =========================

REM =========================
REM 1. BUILD FLUTTER
REM =========================
echo.
echo 🔧 Building Flutter...
flutter clean
flutter pub get
flutter build windows

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Error en build
    exit /b
)

REM =========================
REM 2. ACTUALIZAR VERSION EN ISS
REM =========================
echo.
echo ✏️ Actualizando version en .iss...

powershell -Command "(Get-Content %ISS_FILE%) -replace 'AppVersion=.*', 'AppVersion=%VERSION%' | Set-Content %ISS_FILE%"

REM =========================
REM 3. COMPILAR INSTALADOR
REM =========================
echo.
echo 📦 Generando instalador...

"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" %ISS_FILE%

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Error generando instalador
    exit /b
)

REM =========================
REM 4. CREAR RELEASE EN GITHUB
REM =========================
echo.
echo 🌐 Creando release en GitHub...

set TAG=v%VERSION%

gh release create %TAG% ^
output\%INSTALLER_NAME% ^
--title "Version %VERSION%" ^
--notes "Release automatica version %VERSION%"

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Error subiendo release
    exit /b
)

echo.
echo =========================
echo ✅ RELEASE COMPLETADO
echo =========================
pause