@echo off
setlocal enabledelayedexpansion

REM =========================
REM CONFIG
REM =========================
set VERSION=%1
set APP_NAME=Piscigranja
set INSTALLER_NAME=Instalador_Piscigranja.exe
set ISS_FILE=installer.iss

echo.
echo =========================
echo 🚀 RELEASE AUTOMATICO
echo =========================

REM =========================
REM VALIDAR VERSION
REM =========================
IF "%VERSION%"=="" (
    echo ❌ Debes pasar la version
    echo Ejemplo: release.bat 1.0.2
    exit /b 1
)

set TAG=v%VERSION%

REM =========================
REM VALIDAR GIT
REM =========================
git rev-parse --is-inside-work-tree >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Este proyecto no es un repositorio Git
    exit /b 1
)

REM =========================
REM VALIDAR LOGIN GITHUB
REM =========================
gh auth status >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ No estas logueado en GitHub CLI
    echo Ejecuta: gh auth login
    exit /b 1
)

REM =========================
REM VERIFICAR SI YA EXISTE EL TAG
REM =========================
gh release view %TAG% >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo ❌ Ya existe una release con la version %VERSION%
    exit /b 1
)

REM =========================
REM BUILD FLUTTER
REM =========================
echo.
echo 🔧 Building Flutter...
flutter clean
flutter pub get
flutter build windows

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Error en build Flutter
    exit /b 1
)

REM =========================
REM VALIDAR BUILD
REM =========================
IF NOT EXIST build\windows\x64\runner\Release\%APP_NAME%.exe (
    echo ❌ No se encontro el EXE generado
    exit /b 1
)

REM =========================
REM ACTUALIZAR VERSION EN .ISS
REM =========================
echo.
echo ✏️ Actualizando version en installer.iss...

powershell -Command "(Get-Content %ISS_FILE%) -replace 'AppVersion=.*', 'AppVersion=%VERSION%' | Set-Content %ISS_FILE%"

REM =========================
REM COMPILAR INSTALADOR
REM =========================
echo.
echo 📦 Generando instalador...

set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

IF NOT EXIST %ISCC% (
    echo ❌ No se encontro Inno Setup en:
    echo %ISCC%
    exit /b 1
)

%ISCC% %ISS_FILE%

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Error compilando instalador
    exit /b 1
)

REM =========================
REM VALIDAR INSTALADOR
REM =========================
IF NOT EXIST output\%INSTALLER_NAME% (
    echo ❌ No se genero el instalador
    exit /b 1
)

REM =========================
REM CREAR RELEASE
REM =========================
echo.
echo 🌐 Subiendo a GitHub...

gh release create %TAG% ^
output\%INSTALLER_NAME% ^
--title "Version %VERSION%" ^
--notes "Release automatica version %VERSION%"

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Error creando release
    exit /b 1
)

echo.
echo =========================
echo ✅ RELEASE COMPLETADO %VERSION%
echo =========================

pause