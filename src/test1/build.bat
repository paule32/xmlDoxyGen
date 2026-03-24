:: ---------------------------------------------------------------
:: \file build.bat
:: \note (c) 2026 by Jens Kallup - paule32 aka Blacky Cat
::       all rights reserved.
:: ---------------------------------------------------------------
@echo off
setlocal EnableDelayedExpansion
chcp 1252 >nul

mkdir out
mkdir out\dark
mkdir out\dark\de
mkdir out\dark\en

mkdir out\light
mkdir out\light\de
mkdir out\light\en

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

mv out\chm    ..\..\test2
mv out\dark   ..\..\test2
mv out\de     ..\..\test2
mv out\en     ..\..\test2
mv out\light  ..\..\test2
mv out\xml    ..\..\test2

python scripts\convert_xml_to_html_fragments.py xml xslt -o out --full-pages --template template2.html
mkdir out\css
mkdir out\img
mkdir out\js
mkdir out\vendors
rm -rf out\chm
rm -rf out\dark
rm -rf out\light
rm -rf out\de
rm -rf out\en
rm -rf out\xml
xcopy /E /I /Y css     out\css
xcopy /E /I /Y img     out\img
xcopy /E /I /Y js      out\js
xcopy /E /I /Y vendors out\vendors

endlocal
pause
