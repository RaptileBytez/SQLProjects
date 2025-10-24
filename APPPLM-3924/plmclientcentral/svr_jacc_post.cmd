@echo off
:: Bart van der Linden 10-01-2019
::
:: Changes:
:: - Initial setup APPPLM-128
:: Todo:
:: - check behavior: -Djava.security.auth.login.config="%ep_root%\axalant\ini\jacc-jaas.conf" >> currently removed
:: - -Djacc.backgroundIcon=W:\PLM\icons\bck\marel621Dev.jpg >> added to set to force white background.

:: Set the connector variables to load into the client.
:: PLMGRB-39; Setting locally installed connector version in env-vars:
::            SFS_CCM_VER, SFS_ECA_VER, SFS_ECV_VER, SFS_ECX_VER
:: APPPLM-957; Harald Weber (XPLM) 08-06-2020 Add env-var for Eplan connector:
::            SFS_EPLAN_VER
::set curDirectory=%~dp0
call "setCurConnVer.bat" SolidWorks CCM
call "setCurConnVer.bat" AutoCad ECA
call "setCurConnVer.bat" Inventor ECV
call "setCurConnVer.bat" Core ECX
call "setCurConnVer.bat" Eplan EPLAN

::Get OS Version to log in the login history table
For /f "tokens=2 delims=[]" %%G in ('ver') Do (set _version=%%G) 
For /f "tokens=2,3,4 delims=. " %%G in ('echo %_version%') Do (set _major=%%G& set _minor=%%H& set _build=%%I)
pushd %jlib%
:: call java client
REM start "Agile e6 JavaClient" "%JAVA_HOME%\bin\javaw.exe" %VM_OPTS% -Djava.security.auth.login.config="%ep_root%\axalant\ini\jacc-jaas.conf" -Djacc.home="$APPDATA\e62" -Djacc.defaults="%ep_root%\axalant\ini\jacc.defaults" -Djacc.backgroundIcon=W:\PLM\icons\bck\marel621Dev.jpg -DEP_MACH="%EP_MACH%" -DEP_DDM_SITE="%EPDDMSITE%" -DEP_PVM_SITE="%EPDDMSITE%" -DSFS_OS_VER="%_major%.%_minor%" -Daxalant_root="%axalant_root%" -Dep_root="%ep_root%" com.agile.jacc.e6.Jacc -d 16087 %*
start "Agile e6 JavaClient" "%JAVA_HOME%\bin\javaw.exe" %VM_OPTS% -Djacc.home="C:\LocalData\Agile\e62" -Djacc.defaults="%ep_root%\axalant\ini\jacc.defaults" -DAutoVue.UseAltJVue=%ep_root% -Djacc.backgroundIcon=W:\PLM\icons\bck\marel621Dev.jpg -DEP_MACH="%EP_MACH%" -DEP_DDM_SITE="%EPDDMSITE%" -DEP_PVM_SITE="%EPDDMSITE%" -DSFS_OS_VER="%_major%.%_minor%" -Daxalant_root="%axalant_root%" -Dep_root="%ep_root%" com.agile.jacc.e6.Jacc -d 16087 %*