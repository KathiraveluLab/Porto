@echo off
setlocal enabledelayedexpansion

echo ------------------------------------------------
echo Starting PORTO ^& Leo Environment Setup (Windows)
echo ------------------------------------------------

:: 1. Chocolatey Installation
where choco >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [1/6] Chocolatey not found. Attempting to install...
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install Chocolatey. Please run this script as Administrator.
        exit /b 1
    )
) else (
    echo [1/6] Chocolatey is already installed.
)

:: 2. System Dependencies via Choco
echo [2/6] Installing dependencies via Chocolatey...
choco install git erlang rustup-init openssl -y

:: 3. Rust Environment Setup
echo [3/6] Initializing Rust environment...
where cargo >nul 2>nul
if %ERRORLEVEL% neq 0 (
    rustup-init.exe -y
    set "PATH=%PATH%;%USERPROFILE%\.cargo\bin"
)

:: 4. Erlang Build Tooling (Rebar3)
echo [4/6] Setting up Rebar3...
if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
if not exist "%USERPROFILE%\.local\bin\rebar3" (
    powershell -Command "Invoke-WebRequest -Uri https://s3.amazonaws.com/rebar3/rebar3 -OutFile %USERPROFILE%\.local\bin\rebar3"
)

:: Create rebar3.cmd wrapper
echo @echo off > "%USERPROFILE%\.local\bin\rebar3.cmd"
echo escript "%%~dp0rebar3" %%* >> "%USERPROFILE%\.local\bin\rebar3.cmd"
set "PATH=%PATH%;%USERPROFILE%\.local\bin"

:: 5. Leo CLI Installation
echo [5/6] Installing Leo CLI from source...
set "SCRIPT_DIR=%~dp0"
set "LEO_DIR=%SCRIPT_DIR%..\leo"

if not exist "%LEO_DIR%" (
    set "LEO_DIR=%USERPROFILE%\leo"
)

if exist "%LEO_DIR%" (
    echo Found Leo at: %LEO_DIR%
    pushd "%LEO_DIR%"
    cargo install --path crates/leo
    popd
) else (
    echo Error: Leo source directory not found at %LEO_DIR%
    exit /b 1
)

:: 6. PORTO Compilation
echo [6/6] Compiling PORTO core...
pushd "%SCRIPT_DIR%core"
rebar3 compile
popd

echo ------------------------------------------------
echo Setup Complete!
echo Please restart your terminal or run: refreshenv
echo ------------------------------------------------
pause
