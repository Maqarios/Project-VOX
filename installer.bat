@echo off
setlocal
REM ===========================================================
REM Install Python via winget (if not already installed)
REM Then create a venv, install requirements, and run main.py
REM Run as Administrator
REM ===========================================================

echo [INFO] Checking for Python installation...

where python >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%V in ('python -V 2^>^&1') do set PYVER=%%V
    echo [INFO] Found %PYVER%
) ELSE (
    echo [WARN] Python not found. Attempting installation via winget...
    
    where winget >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        echo [ERROR] winget not found. Install winget or Python manually.
        pause
        exit /b 1
    )

    winget install --id Python.Python.3 --silent --accept-package-agreements --accept-source-agreements
    IF %ERRORLEVEL% NEQ 0 (
        echo [ERROR] winget failed to install Python.
        pause
        exit /b 1
    )

    echo [INFO] Python installed. Refreshing PATH...
    set "PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\Scripts;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312"
    
    where python >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Python still not found. You may need to restart this script.
        pause
        exit /b 1
    )
)

REM ===========================================================
REM Create virtual environment
REM ===========================================================

if exist .venv (
    echo [INFO] Existing .venv detected. Skipping creation.
) ELSE (
    echo [INFO] Creating virtual environment...
    python -m venv .venv
    IF %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to create .venv.
        pause
        exit /b 1
    )
)

REM ===========================================================
REM Install requirements
REM ===========================================================

IF NOT EXIST requirements.txt (
    echo [WARN] requirements.txt not found. Skipping package installation.
) ELSE (
    echo [INFO] Installing dependencies inside .venv...
    .venv\Scripts\python.exe -m pip install --upgrade pip
    .venv\Scripts\python.exe -m pip install -r requirements.txt

    IF %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install dependencies.
        pause
        exit /b 1
    )
)

echo [SUCCESS] Python environment setup complete.
pause
exit /b 0
