REM author/date Bernd Schultz (XPLM) / 2017-02-14
REM PLMGRB-39; Setting locally installed connector version by reading version- 
REM            marker-file.
REM APPPLM-957; Harald Weber (XPLM) 08-06-2020 Add env-var for Eplan connector
REM par: 1: name of CAD-system (AutoCad, Inventor, SolidWorks, Core, Eplan)
REM      2: connector-symbol   (ECA,     ECV,      CCM,        ECX,  EPLAN)
IF "%1" == "Eplan" (
  SET Destination=C:\Program Files\xPLM Solution GmbH\Eplan
) ELSE (
  SET Destination=C:\Program Files\xPLM Solution GmbH\ecx
)
SET Version_marker_file=XPlmE6%1%.txt
SET destfile=%Destination%\%Version_marker_file%
IF EXIST "%destfile%" (  
  goto :determine
) ELSE (
  goto :file_missing
)
:determine
set localCurVer=0
FOR /F "tokens=1*" %%a IN ('type "%destfile%"') DO SET localCurVer=%%a %%b
set localCurVer=%2%: %localCurVer%
goto :final
:file_missing
set localCurVer=CAD-system %1 not installed.
:final
set varnam=SFS_%2%_VER
set %varnam%=%localCurVer%