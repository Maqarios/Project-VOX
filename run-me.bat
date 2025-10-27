@echo off
setlocal
REM ===========================================================
REM Run main.py using the project's virtual environment
REM ===========================================================

if not exist ".venv\Scripts\python.exe" (
    echo Virtual environment not found. Creating one...
    python -m venv .venv
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to create virtual environment. Ensure Python is installed.
        pause
        exit /b 1
    )
    echo Installing dependencies...
    if exist requirements.txt (
        .venv\Scripts\python.exe -m pip install --upgrade pip
        .venv\Scripts\python.exe -m pip install -r requirements.txt
    )
)

if not exist "main.py" (
    echo main.py not found in the current directory.
    pause
    exit /b 1
)

echo Running main.py...
.venv\Scripts\python.exe main.py
echo.
pause
exit /b 0
