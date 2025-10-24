@echo off
:: Bart van der Linden 12-01-2017
:: Set the file-server based on the availability of fileservers for the environment 
:: set the default file server, data center or Boxmeer
:: 25-09-2025 H.Hackenberg JIRA: APPPLM-3381 As an Azure user I want an Azure device connect to AZ1 physical location and AZ1 file server 

set DefFileServer=dc1
:: set the default development application server.
set PLMDEVSRV=VDC1PLMASDEV01.marel.net

:: Read the environment and set to lowercase
pushd %W_Root%
CALL "set_env.cmd" %*

if %PLMenvironment%==marelbld (
	set EPDDMSITE=%DefFileServer%
	goto :EOF)
if %PLMenvironment%==marelpqe (
	set PLMDEVSRV=VDC1PLMASDEV02.marel.net
	set EPDDMSITE=%DefFileServer%
	goto :EOF)
if %PLMenvironment%==oneplm (
	set EPDDMSITE=%DefFileServer%
	set PLMDEVSRV=VDC1PLMASDEV02.marel.net
	goto :EOF)
if %PLMenvironment%==cptone (
	set EPDDMSITE=%DefFileServer%
	set PLMDEVSRV=VDC1PLMASDEV02.marel.net
	goto :EOF)
if %PLMenvironment%==cpttwo (
	set EPDDMSITE=%DefFileServer%
	goto :EOF)
if %PLMenvironment%==sandbox (
	set EPDDMSITE=%DefFileServer%
	set PLMDEVSRV=VDC1PLMASDEV02.marel.net
	goto :EOF)
if %PLMenvironment%==plmref621 (
	set EPDDMSITE=%DefFileServer%
	goto :EOF)
if %PLMenvironment%==plm_qs goto QS_ENV	
		
set EPDDMSITE=%DefFileServer%
ECHO Environment %PLMenvironment% unknown , fileserver set to default:%EPDDMSITE%. 
Pause

:QS_ENV
	if %EPDDMSITE%==bra (set EPDDMSITE=%DefFileServer%)
	if %EPDDMSITE%==col (set EPDDMSITE=%DefFileServer%)
	if %EPDDMSITE%==aar (set EPDDMSITE=%DefFileServer%)
	if %EPDDMSITE%==sto (set EPDDMSITE=%DefFileServer%)
	if %EPDDMSITE%==nra (set EPDDMSITE=%DefFileServer%)
	if %EPDDMSITE%==gup (set EPDDMSITE=%DefFileServer%)
	:: APPPLM-3381
	if %EPDDMSITE%==az1 (set EPDDMSITE=%DefFileServer%)
	goto :EOF