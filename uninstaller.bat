@echo off
setlocal enabledelayedexpansion
REM ===========================================================
REM Hugging Face cache uninstaller
REM Allows deleting specific models or the entire .cache
REM ===========================================================

set "BASE_DIR=C:\Users\%USERNAME%\.cache"
set "HUG_DIR=%BASE_DIR%\huggingface\hub"

echo Hugging Face cache directory: "%HUG_DIR%"
if not exist "%HUG_DIR%" (
    echo Cache directory not found.
    pause
    exit /b 0
)

REM -----------------------------------------------------------
REM List models
REM -----------------------------------------------------------
set "count=0"
for /d %%D in ("%HUG_DIR%\*") do (
    set /a count+=1
    set "model!count!=%%~nxD"
)

echo.
if %count% EQU 0 (
    echo No cached models found under "%HUG_DIR%".
    echo.
    set /p "DELALL=Delete the entire .cache directory instead? (y/N): "
    if /i "%DELALL%"=="y" goto :delete_all_confirm
    echo Operation cancelled.
    pause
    exit /b 0
)

echo Found Hugging Face model folders:
for /l %%I in (1,1,%count%) do echo   %%I^) !model%%I!
echo.

REM -----------------------------------------------------------
REM Ask user action
REM -----------------------------------------------------------
echo What do you want to do?
echo   [1] Delete ALL models and caches (.cache directory)
echo   [2] Choose specific models to delete
echo   [Q] Quit
echo.
set /p "CHOICE=Enter choice: "

if /i "%CHOICE%"=="1" goto :delete_all_confirm
if /i "%CHOICE%"=="2" goto :choose_models
if /i "%CHOICE%"=="q" goto :end

echo Invalid choice.
pause
exit /b 1

REM -----------------------------------------------------------
:delete_all_confirm
echo.
set /p "CONFIRM=Are you sure you want to DELETE the entire .cache directory? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Operation cancelled.
    goto :end
)

echo Deleting "%BASE_DIR%" ...
rmdir /s /q "%BASE_DIR%"

if exist "%BASE_DIR%" (
    echo Failed to delete "%BASE_DIR%". Check permissions.
) else (
    echo Entire .cache directory deleted successfully.
)
goto :end

REM -----------------------------------------------------------
:choose_models
echo.
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
goto :end

REM -----------------------------------------------------------
:end
echo.
pause
exit /b 0
