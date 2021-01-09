@echo off
color Blue
SetLocal EnableDelayedExpansion
title Editeur de cia trop coool
set HMRTver=1.0
set HMRTch=[Stable]     
mode con:cols=57 lines=25
cd %~dp0
::============ USER VARIABLES =============================
:: ciaName: Input File (HomeMenu) NO EXTENSION
:: expName: Output File (HomeMenu_edited) NO EXTENSION
:: SDDrive: Letter for the SD Drive

set HMRTdir=HMRT
set LogFile="%~dp0\LZ.log"
set ciaName=CiaFile
set expName=%ciaName%_edited
:START
set SDDrive=

::========================================================

cd %HMRTdir%
if NOT [%1]==[] (
	if "%~x1"==".cia" (
		set ciaName=%~n1
		set expName=%ciaName%_edited
	) else if "%~x1"==".bin" (
		goto LZDECOMPRESSOR
	)
)

set usrchoice="0"
title Editeur de cia trop coool
cls
echo. #=====================================================#
echo. ^|                   Editeur de CIA :D                 ^|
echo. ^|                     C'est coool                     ^|
echo. ^|                                                     ^|
echo. ^|     Le cia a editer doit s'appeller CiaFile.cia     ^|
echo. #=====================================================#
echo.
echo.   Pour Extraire le CIA, tapez [1]
echo.   Pour Build le CIA, Tapez [2]
echo.   Pour Tout clean, Tapez [3]
echo.   Pour Copier dans la SD, Tapez [4]
echo.   Pour Decompresser tous les fichiers LZ, Tapez [5]
echo.   Pour Recompresser tous les fichiers LZ, Tapez [6]
echo.   Pour Tout faire (1, 5, Modif, 6, 2, 3, 4), Tapez [7]
echo.   Pour se barrer de la, Tapez [Q]
echo.
CHOICE /n /c:1234567Q /m "> Tapes ton numero de CB:"
set usrchoice=%errorlevel%
cls
if "%usrchoice%"=="1" goto EXTRACT
if "%usrchoice%"=="2" goto BUILD
if "%usrchoice%"=="3" goto CLEAN
if "%usrchoice%"=="4" goto COPYSD
if "%usrchoice%"=="5" goto DECOMP
if "%usrchoice%"=="6" goto RECOMP
if "%usrchoice%"=="8" goto EOF
if NOT "%usrchoice%"=="7" goto START 

:EXTRACT
title Extraction...

if NOT exist "%~dp0\%ciaName%.cia" (
echo Euh... Je trouve pas ton cia.
echo Tu peux soit glisser ton cia ici
echo Ou alors le taper ci-dessous:
echo.
set /p ciaName="Entre le nom du fichier sans extention stp: "
)
del SystemApp*
ctrtool.exe --content=SystemApp "%~dp0\%ciaName%.cia"
FOR %%S in (SystemApp.0000.*) do (
	set cxi0=%%~nxS
)
3dstool.exe -xvtf cxi %cxi0% --header NCCH.Header --exh DecryptedExHeader.bin --exefs DecryptedExeFS.bin --romfs DecryptedRomFS.bin --logo Logo.bcma.LZ --plain PlainRGN.bin
3dstool.exe -xuvtf exefs DecryptedExeFS.bin --exefs-dir ..\ExtractedExeFS --header ExeFS.Header
3dstool.exe -xvtf romfs DecryptedRomFS.bin --romfs-dir ..\ExtractedRomFS
if NOT "%usrchoice%"=="7" goto START 

:DECOMP
cd %~dp0
echo LZ Decompressionlog [%date:~0%] >> %LogFile%
echo =====================================================>> %LogFile%
set /a cntT=0
set /a cntS=0
title Home Menu Rebuilding Tool [Decompressor]
for /R %%F in (*lz.bin) do (
	set /a cntT=!cntT!+1
    	set fn=%%~nF
    	set file=!fn:~0,-3!.!fn:~-2,2!
	echo Decompressing: !file!
	%HMRTdir%\3dstool -uvf "%%F" --compress-type lzex --compress-out "%%~nF.lz" > NUL
	if exist "%%~nF.lz" (
		del "%%F" > NUL
		move "%%~nF.lz" "%%~dpF!file!" > NUL
		echo [%time:~0,8%] %%~nxF decompressed! >> %LogFile%
		set /a cntS=!cntS!+1
	) else (
		echo [%time:~0,8%] %%~nxF couldn't be decompressed >> %LogFile%
	)
	cls
)
echo [%time:~0,8%] Finished %cntS%/%cntT% decompressed >> %LogFile%
echo =====================================================>> LZ.log
cd %HMRTdir%
if NOT "%usrchoice%"=="7" goto START 

echo Tout le contenu a ete extrait :D
echo Les fichiers .LZ ont ete decompresse
echo Fait tes modifs maintenant :)
%SystemRoot%\explorer.exe "%~dp0ExtractedRomFS"
echo.
echo Appuie sur n'importe quelle touche
echo pour tout recompresser et build le cia.
pause>nul


:RECOMP
cd %~dp0
echo LZ Recompressionlog [%date:~0%] >> %LogFile%
echo =====================================================>> %LogFile%
title Compression...
set /a cntT=0
set /a cntS=0
for /R %%F in (*.lz) do (
	set /a cntT=!cntT!+1
	cls
	echo Compressing: "%%~nxF"
	%HMRTdir%\3dstool -zvf "%%F" --compress-type lzex --compress-out "%%~nF_LZ.bin"
	::%HMRTdir%\LZ -c lz11 "%%F" "%%~nF_LZ.bin" > NUL
	if exist "%%~nF_LZ.bin" (
		del "%%F"  > NUL
		move "%%~nF_LZ.bin" "%%~dpnF_LZ.bin"  > NUL
		echo [%time:~0,8%] %%~nxF compressed! >> %LogFile%
		set /a cntS=!cntS!+1
	)
)
echo [%time:~0,8%] Finished %cntS%/%cntT% compressed >> %LogFile%
echo =====================================================>> %LogFile%
cd %HMRTdir%
if NOT "%usrchoice%"=="7" goto START 

:BUILD
title Build...
if "%expName%"=="" (
echo No name specified for the CIA file. 
echo You can specify a default name
echo in the USER VARIABLES.(example expName=HomeMenu^)
echo.
set /p expName="Entre le nom du fichier sans extention stp: "
)

del ..\ExtractedRomFS\*.bak
3dstool.exe -cvtf romfs CustomRomFS.bin --romfs-dir ..\ExtractedRomFS
3dstool.exe -czvtf exefs CustomExeFS.bin --exefs-dir ..\ExtractedExeFS --header ExeFS.Header
FOR %%S in (SystemApp.0000.*) do (
	set cxi0=%%~nxS
)
3dstool.exe -cvtf cxi %cxi0% --header NCCH.Header --exh DecryptedExHeader.bin --exefs CustomExeFS.bin --romfs CustomRomFS.bin --logo Logo.bcma.LZ --plain PlainRGN.bin
::makerom.exe -f cia -content %cxi0%:0:0x%cxi0:~-4,4% -o "%~dp0\%expName%.cia"
makerom.exe -f cia -content %cxi0%:0 -o "%~dp0\%expName%.cia"
if NOT "%usrchoice%"=="7" goto START 
echo.

:CLEAN
title Clean...
cd %~dp0
rmdir ExtractedRomFS /s /q
rmdir ExtractedExeFS /s /q
del *.log
cd %HMRTdir% & del *.bin *.Header SystemApp.* *.log

if NOT "%usrchoice%"=="7" goto START 

:COPYSD
title Copie dans la SD...
echo Recherche d'une SD valide...
for /f "tokens=1,2,3,4" %%a in ('wmic logicaldisk get caption^,drivetype^,filesystem^,volumename') do (
	if "%%b"=="2" if "%%c"=="FAT32" if exist "%%a\Nintendo 3DS\" set SDDrive=%%a&set SDName=%%d
)
if "%SDDrive%"=="" (
	echo.
	echo Impossible de trouver la SD.
	pause>nul
	goto START
)
cd %~dp0
md %SDDrive%\gm9\out 2> nul
if NOT exist "%expName%.cia" ( 
echo Copying %ciaName%.cia to %SDName% [%SDDrive%]
copy "%ciaName%.cia" "%SDDrive%\gm9\out\%ciaName%.cia" 
) else (
echo Copying %expName%.cia to %SDName% [%SDDrive%]
copy "%expName%.cia" "%SDDrive%\gm9\out\%ciaName%_edited.cia" )
ping -n 2 127.0.0.1 > NUL
cd %HMRTdir%
goto START

:LZDECOMPRESSOR

title Décompresseur de .LZ
cd /d %~dp0
echo LZ Compressionlog [%date:~0%] >> %LogFile%
set /a cntT=0
set /a cntS=0
echo =====================================================>> %LogFile%
for %%F in (%*) do (
	set /a cntT=!cntT!+1
    	set fn=%%~nF
    	set file=!fn:~0,-3!.!fn:~-2,2!
	echo Decompressing: !file!
	%HMRTdir%\3dstool -uvf %%F --compress-type lz --compress-out !file! > NUL
	if exist !file! (
		del %%F > NUL
		move !file! "%%~dpF!file!" > NUL
		echo [%time:~0,8%] %%~nxF decompressed! >> %LogFile%
		set /a cntS=!cntS!+1
	) else (
		echo [%time:~0,8%] %%~nxF couldn't be decompressed >> %LogFile%
	)
	cls
)
echo [%time:~0,8%] Finished %cntS%/%cntT% decompressed >> %LogFile%
echo =====================================================>> %LogFile%

:EOF
