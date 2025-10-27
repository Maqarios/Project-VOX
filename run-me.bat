@echo off
setlocal enabledelayedexpansion
REM ===========================================================
REM Project Manager
REM Provides installer, runner, and uninstaller options
REM ===========================================================

title Project Manager
color 0A

echo ============================================
echo            Project Manager
echo ============================================
echo [1] Install (setup Python, venv, deps, run main.py)
echo [2] Run (execute main.py using existing venv)
echo [3] Uninstall (delete cache/models/.venv)
echo [Q] Quit
echo ============================================
echo.
set /p "CHOICE=Enter your choice: "

if /i "%CHOICE%"=="1" goto :install
if /i "%CHOICE%"=="2" goto :run
if /i "%CHOICE%"=="3" goto :uninstall
if /i "%CHOICE%"=="q" goto :end

echo Invalid choice.
timeout /t 2 >nul
goto :end


REM ===========================================================
:install
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

REM Create venv
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

REM Install requirements
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

echo [INFO] Running main.py...
if not exist "main.py" (
    echo [ERROR] main.py not found.
    pause
    exit /b 1
)
.venv\Scripts\python.exe main.py
echo [SUCCESS] Installation and run complete.
timeout /t 3 >nul
goto :end


REM ===========================================================
:run
if not exist ".venv\Scripts\python.exe" (
    echo [WARN] Virtual environment not found. Creating one...
    python -m venv .venv
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    if exist requirements.txt (
        .venv\Scripts\python.exe -m pip install --upgrade pip
        .venv\Scripts\python.exe -m pip install -r requirements.txt
    )
)

if not exist "main.py" (
    echo [ERROR] main.py not found.
    pause
    exit /b 1
)

echo [INFO] Running main.py...
start "" /wait ".venv\Scripts\python.exe" main.py
echo [INFO] Script finished.
timeout /t 3 >nul
goto :end


REM ===========================================================
:uninstall
set "BASE_DIR=C:\Users\%USERNAME%\.cache"
set "HUG_DIR=%BASE_DIR%\huggingface\hub"
set "VENV_DIR=.venv"

echo Hugging Face cache directory: "%HUG_DIR%"
if not exist "%HUG_DIR%" (
    echo Cache directory not found.
    goto :check_venv
)

set "count=0"
for /d %%D in ("%HUG_DIR%\*") do (
    set /a count+=1
    set "model!count!=%%~nxD"
)

echo.
if %count% EQU 0 (
    echo No cached models found under "%HUG_DIR%".
    set /p "DELALL=Delete the entire .cache and .venv directories instead? (y/N): "
    if /i "%DELALL%"=="y" goto :delete_all_confirm
    goto :end
)

echo Found Hugging Face model folders:
for /l %%I in (1,1,%count%) do echo   %%I^) !model%%I!
echo.
echo What do you want to do?
echo   [1] Delete ALL models and caches (.cache + .venv)
echo   [2] Choose specific models to delete
echo   [Q] Quit
echo.
set /p "UCHOICE=Enter choice: "

if /i "%UCHOICE%"=="1" goto :delete_all_confirm
if /i "%UCHOICE%"=="2" goto :choose_models
if /i "%UCHOICE%"=="q" goto :end
goto :end

:delete_all_confirm
set /p "CONFIRM=Are you sure you want to DELETE the entire .cache and .venv directories? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Operation cancelled.
    goto :end
)

echo Deleting "%BASE_DIR%" ...
rmdir /s /q "%BASE_DIR%"
if exist "%BASE_DIR%" (
    echo Failed to delete "%BASE_DIR%".
) else (
    echo .cache deleted successfully.
)

:check_venv
if exist "%VENV_DIR%" (
    echo Deleting "%VENV_DIR%" ...
    rmdir /s /q "%VENV_DIR%"
    if exist "%VENV_DIR%" (
        echo Failed to delete "%VENV_DIR%".
    ) else (
        echo .venv deleted successfully.
    )
)
timeout /t 3 >nul
goto :end

:choose_models
echo Enter the numbers of the models to delete (e.g. 1 3 5):
set /p "SELECTION=> "
for %%N in (%SELECTION%) do (
    if %%N LEQ %count% (
        set "model=!model%%N!"
        echo Deleting "!model!" ...
        rmdir /s /q "%HUG_DIR%\!model!"
    ) else (
        echo Invalid model number: %%N
    )
)
echo Selected models deleted successfully.
timeout /t 3 >nul
goto :end


REM ===========================================================
:end
endlocal
exit
