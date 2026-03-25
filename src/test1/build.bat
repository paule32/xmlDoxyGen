:: ---------------------------------------------------------------
:: \file build.bat
:: \note (c) 2026 by Jens Kallup - paule32 aka Blacky Cat
::       all rights reserved.
:: ---------------------------------------------------------------
@echo off
setlocal EnableDelayedExpansion
chcp 1252 >nul

echo Prepare directories...
rm -rf out

mkdir out
mkdir out\dark
mkdir out\dark\de
mkdir out\dark\en

mkdir out\light
mkdir out\light\de
mkdir out\light\en

cp -R src\assets out\assets

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
:: CHM-Verzeichnis vorbereiten
:: ==========================================
if not exist out\chm mkdir out\chm

::copy /Y out\de\html\dBaseHelp_de.chm out\chm\
::copy /Y out\en\html\dBaseHelp_en.chm out\chm\

:: ==========================================
:: Master CHM kompilieren
:: ==========================================
::set HHC="C:\Program Files (x86)\HTML Help Workshop\hhc.exe"

::pushd out\chm
::%HHC% master.hhp
::popd

echo ==========================================
echo   Done / Fertig.
echo ==========================================

python scripts\convert_xml_to_html_fragments.py ^
    out\dark\de\xml xslt ^
    -o out --full-pages --template template2.html

endlocal
pause
