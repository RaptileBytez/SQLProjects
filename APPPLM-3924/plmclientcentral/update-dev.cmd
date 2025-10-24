@echo off
:: Bart van der Linden 10-01-2019
::
:: Changes:
:: - Initial setup APPPLM-128
:: Todo:
:: - 

:: Set the default install folder and create if necessary
set L_Root=C:\Agile_E6.2.1
IF NOT EXIST "%L_Root%" (
 mkdir "%L_Root%"
)
:: initialize the W drive and application type
set W_Root=\\marel.net\common\PLM\PLMClient62
set ApplicationType=dev


:: Check if the remote (W drive) is accesible
if not exist w:\nul (
net use w: \\marel.net\common
w:
echo %date%	%time%	W drive mapped for %ApplicationType% update >> %TMP%\AgilePlmDFSlog.txt
)

:: Check if file is accesible from a unc path.
if not exist "%W_Root%\svr_client_upd.bat" (
net use w: /d
net use w: \\marel.net\common
w:
echo %date%	%time%	W drive mapped for UNC path for %ApplicationType% update >> %TMP%\AgilePlmDFSlog.txt
)

if not exist "%W_Root%\svr_client_upd.bat" (
	echo "%W_Root%\svr_client_upd.bat" not found. Please log off and log in again or contact your ICT helpdesk
	echo %date%	%time%	UNC path not found for %ApplicationType% update >> %TMP%\AgilePlmDFSlog.txt
    pause
	exit
)
CALL "%W_Root%\svr_client_upd.bat"
:EOF