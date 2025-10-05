@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion
title u4pak Universal Tool - by porhe911

:: Detect Python
where py >nul 2>&1 && ( set "PY=py -3" ) || ( set "PY=python" )

:: Find u4pak.py
set "SCRIPT_DIR=%~dp0"
set "U4PAK=%SCRIPT_DIR%u4pak.py"
if not exist "%U4PAK%" if exist "%SCRIPT_DIR%u4pak-master\u4pak.py" set "U4PAK=%SCRIPT_DIR%u4pak-master\u4pak.py"
if not exist "%U4PAK%" (
  echo ERROR: u4pak.py not found in script directory
  pause
  exit /b 1
)

:: =============================================
:: AUTO-DETECT WHEN FILE/FOLDER DRAGGED ONTO BAT
:: =============================================
if not "%~1"=="" (
  echo [AUTO-MODE] Processing: %~1
  echo.
  
  if /i "%~x1"==".pak" (
    echo Detected: .pak file - UNPACKING
    echo.
    set "pakfile=%~1"
    call :UNPACK_AUTO
    echo.
    echo Operation completed! Press any key to exit...
    pause >nul
    exit /b 0
  )
  
  if exist "%~1\" (
    echo Detected: Folder - PACKING  
    echo.
    set "indir=%~1"
    call :PACK_AUTO
    echo.
    echo Operation completed! Press any key to exit...
    pause >nul
    exit /b 0
  )
  
  echo ERROR: Unknown file type or not a folder
  echo Drag either a .pak file or a folder
  echo.
  echo Press any key to exit...
  pause >nul
  exit /b 1
)

:: =============================================
:: MAIN MENU (if no file/folder dragged)
:: =============================================
:MENU
cls
echo ================================
echo    u4pak Universal Tool
echo       by porhe911
echo ================================
echo.
echo 1 - Unpack .pak file
echo 2 - Pack folder to .pak  
echo 3 - List .pak contents
echo 4 - Exit
echo.
echo DRAG ^& DROP: drag file/folder onto this bat
echo.
set /p "choice=Choose action (1/2/3/4): "
if "%choice%"=="" goto MENU

if "%choice%"=="1" goto UNPACK
if "%choice%"=="2" goto PACK  
if "%choice%"=="3" goto LIST
if "%choice%"=="4" goto END

echo Invalid choice! Press any key...
pause >nul
goto MENU

:UNPACK
echo.
:ASK_PAK
set "pakfile="
set /p "pakfile=Enter path to .pak file (or drag ^& drop here): "
set "pakfile=%pakfile:"=%"
if "%pakfile%"=="" goto ASK_PAK
if not exist "%pakfile%" (
  echo ERROR: File not found!
  goto ASK_PAK
)
call :UNPACK_AUTO
echo.
pause
goto MENU

:UNPACK_AUTO
for %%# in ("%pakfile%") do (
  set "PAKDIR=%%~dp#"
  set "PAKNAME=%%~n#"
)
set "outdir=%PAKDIR%%PAKNAME%_unpacked"
echo Unpacking "%pakfile%" to "%outdir%"...
%PY% "%U4PAK%" unpack -C "%outdir%" "%pakfile%"
if exist "%outdir%" (
  echo SUCCESS: Files extracted to "%outdir%"
) else (
  echo ERROR: Extraction failed!
)
goto :eof

:PACK
echo.
:ASK_DIR
set "indir="
set /p "indir=Enter folder path (or drag ^& drop here): "
set "indir=%indir:"=%"
if "%indir%"=="" goto ASK_DIR
if not exist "%indir%" (
  echo ERROR: Folder not found!
  goto ASK_DIR
)
call :PACK_AUTO
echo.
pause
goto MENU

:PACK_AUTO
for %%# in ("%indir%") do (
  set "PARENTDIR=%%~dp#"
  set "FOLDERNAME=%%~n#"
)
set "outpak=%PARENTDIR%%FOLDERNAME%.pak"

echo Packing folder "%indir%" to "%outpak%"...

pushd "%PARENTDIR%"
%PY% "%U4PAK%" pack "%outpak%" "%FOLDERNAME%"
if errorlevel 1 (
  echo Trying alternative command...
  %PY% "%U4PAK%" c "%outpak%" "%FOLDERNAME%"
)
popd

if exist "%outpak%" (
  echo SUCCESS: Created .pak file "%outpak%"
) else (
  echo ERROR: Packing failed!
)
goto :eof

:LIST
echo.
:ASK_LIST_PAK
set "pakfile="
set /p "pakfile=Enter path to .pak file to list contents: "
set "pakfile=%pakfile:"=%"
if "%pakfile%"=="" goto ASK_LIST_PAK
if not exist "%pakfile%" (
  echo ERROR: File not found!
  goto ASK_LIST_PAK
)

echo.
echo Listing contents of: %pakfile%
set "PAKNAME="
for %%# in ("%pakfile%") do (
  set "PAKNAME=%%~n#"
)
set "LISTFILE=%SCRIPT_DIR%%PAKNAME%_contents.txt"
echo Output will be saved to "%LISTFILE%"
echo ==================================
%PY% "%U4PAK%" list "%pakfile%" > "%LISTFILE%"
type "%LISTFILE%"
echo ==================================
if exist "%LISTFILE%" (
  echo Listing saved to "%LISTFILE%"
)
echo.
echo Press any key to continue...
pause >nul
goto MENU

:END
cls
echo ================================
echo    u4pak Universal Tool
echo       by porhe911
echo ================================
echo.
echo Thank you for using!
echo.
timeout /t 2 >nul
exit /b 0
