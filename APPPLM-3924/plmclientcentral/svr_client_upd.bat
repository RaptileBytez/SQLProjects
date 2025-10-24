@echo off
:: Bart van der Linden 07-01-2019
:: 
:: Changes:
:: - removal of office connector setup
:: Todo:
:: - 















:: Setting variables
SET SourceFolder=%W_Root%\%ApplicationType%
SET TargetFolder=%L_Root%\%ApplicationType%
SET Version_marker_file=version.txt

:: Check current and latest version
IF EXIST %TargetFolder%\%Version_marker_file% (
FOR /F "tokens=1*" %%a IN (%TargetFolder%\%Version_marker_file%) DO SET Current_version=%%a %%b
GOTO :Source_check
) ELSE (
SET Current_version=Could not be determined...
)

:Source_check
SET EXIT=NO
IF EXIST %SourceFolder%\%Version_marker_file% (
FOR /F "tokens=1*" %%i IN (%SourceFolder%\%Version_marker_file%) DO SET Latest_version=%%i %%j
) ELSE (
SET Latest_version=Could not be determined!?
SET EXIT=YES
)
)

IF "%Current_version%"=="%Latest_version%" (
GOTO :EOF
)

ECHO Comparing version marker files:
ECHO.
ECHO ----------------------------------
ECHO Current local version: %Current_version%
ECHO Latest version:        %Latest_version%
ECHO ----------------------------------
ECHO.
IF "%EXIT%"=="YES" GOTO :Error

ECHO Robocopy:

::Excluded version.txt to prevent copy issue with a open client and added single copy for the version.txt file
%W_ROOT%\ROBOCOPY %SourceFolder% %TargetFolder% /E /PURGE /XD .git /XF .gitignore version.txt
copy %SourceFolder%\version.txt %TargetFolder%\version.txt
GOTO :EOF

:Error
ECHO Something went wrong here... Please contact itsupport.plm@marel.com
PAUSE
GOTO :EOF

:EOF

