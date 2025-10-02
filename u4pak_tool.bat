@echo off
setlocal EnableExtensions DisableDelayedExpansion
title u4pak Tool (unpack/pack)

:: Python launcher
where py >nul 2>&1 && ( set "PY=py -3" ) || ( set "PY=python" )

:: Locate u4pak.py
set "SCRIPT_DIR=%~dp0"
set "U4PAK=%SCRIPT_DIR%u4pak.py"
if not exist "%U4PAK%" if exist "%SCRIPT_DIR%u4pak-master\u4pak.py" set "U4PAK=%SCRIPT_DIR%u4pak-master\u4pak.py"
if not exist "%U4PAK%" (
  echo ERROR: u4pak.py not found near this .bat
  pause & exit /b 1
)

:MENU
cls
echo ================================
echo        u4Pak Tool by porhe911
echo ================================
echo.
echo 1 - Unpack (.pak ^> files)
echo 2 - Pack   (files ^> .pak)
echo 3 - Exit
echo.
choice /C 123 /N /M "Select action (1/2/3): "
if errorlevel 3 goto END
if errorlevel 2 goto PACK
if errorlevel 1 goto UNPACK
goto MENU

:UNPACK
echo.
:ASK_PAK
set "pakfile="
set /p "pakfile=Enter full path to .pak file: "
set "pakfile=%pakfile:"=%"
if not exist "%pakfile%" (
  echo ERROR: File not found. Try again.
  goto ASK_PAK
)

for %%# in ("%pakfile%") do ( set "PAKDIR=%%~dp#" & set "PAKNAME=%%~n#" )
set "outdir=%PAKDIR%%PAKNAME%_unpacked"
if not exist "%outdir%" mkdir "%outdir%" >nul 2>&1

echo INFO: Unpacking to "%outdir%" ...
%PY% "%U4PAK%" unpack -C "%outdir%" "%pakfile%"
echo DONE: Extracted to "%outdir%"
pause
goto MENU

:PACK
echo.
:ASK_DIR
set "indir="
set /p "indir=Enter folder to pack (root with falcon/Content/...): "
set "indir=%indir:"=%"
if not exist "%indir%" (
  echo ERROR: Folder not found. Try again.
  goto ASK_DIR
)

for %%# in ("%indir%") do ( set "INPARENT=%%~dp#" & set "INNAME=%%~n#" )
set "outpak=%INPARENT%pak_from_%INNAME%.pak"

echo INFO: Packing to "%outpak%" ...
%PY% "%U4PAK%" pack "%outpak%" "%indir%"
echo DONE: Built "%outpak%"
pause
goto MENU

:END
endlocal
exit /b 0