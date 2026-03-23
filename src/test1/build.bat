:: ---------------------------------------------------------------
:: \file build.bat
:: \note (c) 2026 by Jens Kallup - paule32 aka Blacky Cat
::       all rights reserved.
:: ---------------------------------------------------------------
@echo off
setlocal EnableDelayedExpansion
chcp 1252 >nul
:: ==========================================
:: Deutsche Doku
:: ==========================================
echo Building German documentation...
pushd src
..\doxygen Doxyfile_de.dark
if errorlevel 1 exit /b 1
popd

:: ==========================================
:: Englische Doku
:: ==========================================
echo Building English documentation...
pushd src
..\doxygen Doxyfile_en.dark
if errorlevel 1 exit /b 1
popd

:: ==========================================
:: Doku Codepage konvertieren
:: ==========================================
::python utf8tocp1252.py

:: ==========================================
:: HelpNDoc.com Dateien kopieren
:: ==========================================
xcopy /E /I /Y lib out\de\html\lib
xcopy /E /I /Y css out\de\html\css
xcopy /E /I /Y js  out\de\html\js

xcopy /E /I /Y lib out\en\html\lib
xcopy /E /I /Y css out\en\html\css
xcopy /E /I /Y js  out\en\html\js

:: ==========================================
:: CHM-Verzeichnis vorbereiten
:: ==========================================
if not exist out\chm mkdir out\chm
if not exist out\xml mkdir out\xml

copy /Y out\de\html\dBaseHelp_de.chm out\chm\
copy /Y out\en\html\dBaseHelp_en.chm out\chm\

:: ==========================================
:: Master CHM kompilieren
:: ==========================================
set HHC="C:\Program Files (x86)\HTML Help Workshop\hhc.exe"

%HHC% out\chm\master.hhp

echo ==========================================
echo   Fertig.
echo ==========================================

::python scripts\convert_xml_to_html_fragments.py xml xslt -o out --full-pages --template example_template.html
endlocal
pause
