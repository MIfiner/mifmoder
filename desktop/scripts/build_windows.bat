@echo off
setlocal enabledelayedexpansion

echo =============================================
echo   Building LightGram Desktop for Windows x64
echo =============================================

set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR%..
set BUILD_DIR=%ROOT_DIR%\build_win

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

echo Configuring CMake (MSVC 2022 x64)...
cmake -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_BUILD_TYPE=Release ^
    "%ROOT_DIR%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] CMake configuration failed.
    exit /b %ERRORLEVEL%
)

echo Building LightGram Desktop (Release)...
cmake --build . --config Release --target lightgram-desktop test_lightgram --parallel
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed.
    exit /b %ERRORLEVEL%
)

echo Deploying Qt dependencies using windeployqt...
windeployqt.exe --no-translations --compiler-runtime .\Release\LightGram.exe

echo Running automated test suite...
set QT_QPA_PLATFORM=offscreen
.\Release\test_lightgram.exe
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Tests failed.
    exit /b %ERRORLEVEL%
)

echo Verifying application startup...
.\Release\LightGram.exe --version
.\Release\LightGram.exe --smoke-test
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Application smoke test failed.
    exit /b %ERRORLEVEL%
)

echo Generating NSIS Installer and Portable ZIP...
cpack -G "NSIS;ZIP" -C Release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] CPack packaging failed.
    exit /b %ERRORLEVEL%
)

if exist "LightGram-1.0.0-Windows-x64.exe" (
    copy /Y "LightGram-1.0.0-Windows-x64.exe" "LightGram-1.0.0-Windows-x64-Setup.exe"
)

echo =============================================
echo  Windows build complete!
echo =============================================
dir LightGram-1.0.0-Windows-x64*
