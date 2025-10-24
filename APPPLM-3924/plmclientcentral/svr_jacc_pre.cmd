@echo off
:: Bart van der Linden 07-01-2019
:: - pre actions before starting the client.
:: Changes:
:: - moved svr_office_suite.cmd to jacc.cmd
:: Todo:
:: -  

:: --- Define the application type: production or development.

:: Read the environment and set to lowercase
pushd %W_Root%
CALL "set_env.cmd" %*
:: Read the server and set to lowercase
pushd %W_Root%
CALL "set_server.cmd" %*

:: Define the application type
IF "%PLMenvironment%"=="plmref621" (
	set ApplicationType=dev
	goto :EOF)
IF "%PLMenvironment%"=="marelplm"  (
	set ApplicationType=prod
	goto :EOF)
IF "%PLMenvironment%"=="cptone"    (
	set ApplicationType=dev
	goto :EOF)
IF "%PLMenvironment%"=="marelpqe"  (
	set ApplicationType=dev
	goto :EOF)
IF "%PLMenvironment%"=="plm_qs"    (
	set ApplicationType=dev
	goto :EOF)
IF "%PLMenvironment%"=="marelbld"  (
	set ApplicationType=dev
	goto :EOF)
IF "%PLMenvironment%"=="oneplm"  (
	set ApplicationType=dev
	goto :EOF)
IF "%PLMenvironment%"=="sandbox"  (
	set ApplicationType=dev
	goto :EOF)	
IF "%PLMenvironment%"=="" (
		set ApplicationType=prod
		ECHO ApplicationType for %PLMenvironment% could not be determined. Is the environment provided?
		ECHO %*
		ECHO The production client will be used.
		pause
		goto :EOF)

ECHO ApplicationType for %PLMenvironment% could not be determined, is the environment provide?
ECHO If this is your first login, please logoff windows and try again.
ECHO In other situations: Please contact itsupport.plm@marel.com
PAUSE
EXIT
