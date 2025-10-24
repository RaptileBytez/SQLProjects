@echo off
:: Holger Hackenberg 24-01-2019
:: cmd to add REG entries with every jacc start up
:: Changes:
:: - 
:: Todo:

set PLMENV=%PLMenvironment%
set PLMSRV=%PLMserver%
set plm_root=%L_Root%\%ApplicationType%
:: delete reg settings (in principle only needed for win10 for some reason)
REG DELETE HKEY_CURRENT_USER\Software\Agile\OfficeSuite /f > nul 2> nul

:: add reg settings
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v Application /t REG_SZ /d %PLMENV% /f > nul 2> nul
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v Client /t REG_SZ /d Java-Client /f > nul 2> nul
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v Host /t REG_SZ /d %PLMSRV% /f > nul 2> nul
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v Path /t REG_SZ /d %plm_root% /f > nul 2> nul
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v Port /t REG_SZ /d 16087 /f > nul 2> nul
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v Topic /t REG_SZ /d :t:1:h:localhost:r:44444 /f > nul 2> nul
REG ADD HKEY_CURRENT_USER\Software\Agile\OfficeSuite /v User /t REG_SZ /d %EDBUSER% /f > nul 2> nul