@echo off
setlocal enabledelayedexpansion
REM ===========================================================
REM Whisper model cache uninstaller for Hugging Face Hub
REM Lets user delete all or select specific models
REM ===========================================================

set "CACHE_DIR=C:\Users\%USERNAME%\.cache\huggingface\hub"

echo 🧭 Whisper cache directory: "%CACHE_DIR%"
if not exist "%CACHE_DIR%" (
    echo ⚠️  Whisper cache directory not found.
    pause
    exit /b 0
)

REM -----------------------------------------------------------
REM Gather subdirectories (Whisper models)
REM -----------------------------------------------------------
set "count=0"
for /d %%D in ("%CACHE_DIR%\*") do (
    set /a count+=1
    set "model!count!=%%~nxD"
)

if %count% EQU 0 (
    echo No Whisper models found in cache.
    pause
    exit /b 0
)

echo.
echo 📦 Found Whisper models:
for /l %%I in (1,1,%count%) do echo   %%I^) !model%%I!

echo.
echo What do you want to do?
echo   [1] Delete ALL models
echo   [2] Choose specific models
echo   [Q] Quit
echo.

set /p "CHOICE=Enter choice: "

if /i "%CHOICE%"=="1" goto :delete_all
if /i "%CHOICE%"=="2" goto :choose_models
if /i "%CHOICE%"=="q" goto :end

echo Invalid choice.
pause
exit /b 1

REM -----------------------------------------------------------
:delete_all
echo.
set /p "CONFIRM=Delete ALL Whisper models? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo ❎ Operation cancelled.
    goto :end
)

for /l %%I in (1,1,%count%) do (
    set "model=!model%%I!"
    echo 🗑️  Deleting "!model!" ...
    rmdir /s /q "%CACHE_DIR%\!model!"
)
echo ✅ All Whisper models deleted successfully.
goto :end

REM -----------------------------------------------------------
:choose_models
echo.
echo Enter the numbers of the models you want to delete (e.g. 1 3 5):
set /p "SELECTION=> "

for %%N in (%SELECTION%) do (
    if %%N LEQ %count% (
        set "model=!model%%N!"
        echo 🗑️  Deleting "!model!" ...
        rmdir /s /q "%CACHE_DIR%\!model!"
    ) else (
        echo ⚠️  Invalid model number: %%N
    )
)
echo ✅ Selected models deleted successfully.
goto :end

REM -----------------------------------------------------------
:end
echo.
pause
exit /b 0
