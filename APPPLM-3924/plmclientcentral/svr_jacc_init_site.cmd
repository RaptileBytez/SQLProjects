@echo off
:: Bart van der Linden 12-01-2017
:: Set the file-server based on physical location or vpn login
:: CHG001 Added "" for PHYSICALLOC to prevent errors when environment var is not set.

:: 20-06-2018 Jos van den Houdt, physicalloc LXA added 
:: 06-02-2024 S.Diedershagen JIRA: APPPLM-2887 As a PLM user located in the GDC I want to connect to PLM without location issues
:: 25-09-2025 H.Hackenberg JIRA: APPPLM-3381 As an Azure user I want an Azure device connect to AZ1 physical location and AZ1 file server 
:: 24.10.2025 J.Wurm JIRA: APPPLM-3924 As a PLM User in JBT Marel domain I want to keep on using VPN possibilities to connect to Agile PLM

:: set the default file server, for example data center or Boxmeer
set DefFileServer=dc1

:: Get actual Windows version to saved in PLM
Powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File %ext_root%\bin\PLM_setOSVERSION.ps1

:: Get IP address of client adapter related to marel.net network
set plmmarelnetip=""
for /f %%a in ('Powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File %ext_root%\bin\IPdetailMarelNet.ps1 ^| findstr "10"') do (set plmmarelnetip=%%a)
REM IF %plmmarelnetip%=="" (
REM PowerShell -Command "Add-Type -AssemblyName PresentationFramework;[System.Windows.MessageBox]::Show('No IP address found. Please contact PLM Support')"
REM goto NOIP )

:: Get VPN IP address of client; if this is in specific range change the EPDDMSITE and set flag for VPN rights
set plmclientip=""
for /f %%a in ('Powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File %ext_root%\bin\IPdetail.ps1 ^| findstr "10"') do (set plmclientip=%%a)
::for /f "delims={, tokens=2" %%a in ('Powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File %ext_root%\bin\IPdetail.ps1 ^| findstr "{"') do (set plmclientip=%%a)
IF %plmclientip%=="" goto NOIP

:: From here on a VPN connection was detected
FOR /f "tokens=1,2,3,4 delims=." %%a in ("%plmclientip%") do set IP1=%%a&set IP2=%%b&set IP3=%%c&set IP4=%%d
set vpnusertype=VPN

:: === New AZURE VPN IP Ranges (APPPLM-3924)===
IF %IP1%==10 IF %IP2%=110 goto IP_5_US
IF %IP1%==10 IF %IP2%=120 goto IP_5_EMEA
IF %IP1%==10 IF %IP2%=130 goto IP_5_OCE
IF %IP1%==10 IF %IP2%=140 goto IP_5_APAC
IF %IP1%==10 IF %IP2%=150 goto IP_5_LATAM

REM No spaces behind set EPDDMSITE=pmt
IF %IP1%==10 IF %IP2%==111 goto IP_1

:: SOHO variant of VPN
IF %IP1%==10 IF %IP2%==112 goto IP_2

:: VPN (VIA AZURE)
IF %IP1%==10 IF %IP2% GEQ 85 IF %IP2% LEQ 89 goto IP_3

:: China variant of VPN
IF %IP1%==10 IF %IP2%==82 goto IP_4

:: No valid IP Address found
set EPDDMSITE=%DefFileServer%
set PHYSICALLOC=UNKNOWN
ECHO Unknown vpn connection (%plmclientip%), fileserver set to default:%EPDDMSITE%. 
pause

:NOIP
	set vpnusertype=NONE
	set EPDDMSITE=%DefFileServer%
	:: set the file-server for engineering locations
	IF "%PHYSICALLOC%"=="BOX" (set EPDDMSITE=pmt)
	IF "%PHYSICALLOC%"=="DON" (set EPDDMSITE=%DefFileServer%)
	IF "%PHYSICALLOC%"=="GAI" (set EPDDMSITE=gam)
	IF "%PHYSICALLOC%"=="DSM" (set EPDDMSITE=dsm)
	IF "%PHYSICALLOC%"=="PRC" (set EPDDMSITE=bra)
	IF "%PHYSICALLOC%"=="NRA" (set EPDDMSITE=%DefFileServer%)
	IF "%PHYSICALLOC%"=="COL" (set EPDDMSITE=col)
	IF "%PHYSICALLOC%"=="GRB" (set EPDDMSITE=grb)
	IF "%PHYSICALLOC%"=="AAR" (set EPDDMSITE=aar)
	IF "%PHYSICALLOC%"=="STO" (set EPDDMSITE=sto)
	IF "%PHYSICALLOC%"=="GUP" (set EPDDMSITE=gup)
	:: set the fileserver for locations exceptions
	IF "%PHYSICALLOC%"=="MVD" (set EPDDMSITE=bra)
	IF "%PHYSICALLOC%"=="BNE" (set EPDDMSITE=gam)
	IF "%PHYSICALLOC%"=="LXA" (set EPDDMSITE=dsm)
	IF "%PHYSICALLOC%"=="DC1" (set EPDDMSITE=dc1)
	IF "%PHYSICALLOC%"=="EIN" (set EPDDMSITE=dc1)
	:: APPPLM-3381
	IF "%PHYSICALLOC%"=="AZ1" (set EPDDMSITE=dc1)
	IF "%PHYSICALLOC%"=="" (
		set EPDDMSITE=%DefFileServer%
		ECHO default fileserver set, no PHYSICALLOC found
		pause
		)
	goto :EOF

:IP_1
	IF %IP3%==68 (
					set PHYSICALLOC=APAC
					set EPDDMSITE=%DefFileServer%
				)					
	IF %IP3%==69 ( 
					REM IS THIS APAC
					set PHYSICALLOC=APAC
					set EPDDMSITE=%DefFileServer%
				)
	IF %IP3%==66 ( 
					set PHYSICALLOC=AMER
					set EPDDMSITE=gam
				)
	IF %IP3%==67 ( 
					set PHYSICALLOC=AMER
					set EPDDMSITE=gam
				)   
	IF %IP3% GEQ 96 IF %IP3% LEQ 127 ( 
					set PHYSICALLOC=AMER
					set EPDDMSITE=gam
				)  
	IF %IP3% GEQ 128 IF %IP3% LEQ 159 (
					set PHYSICALLOC=AMER
					set EPDDMSITE=gam
				)     
	IF %IP3% GEQ 32 IF %IP3% LEQ 47 ( 
					set PHYSICALLOC=EMEA
					set EPDDMSITE=%DefFileServer%
				)  
	IF %IP3% GEQ 48 IF %IP3% LEQ 63 ( 
					set PHYSICALLOC=EMEA
					set EPDDMSITE=%DefFileServer%
				) 
	IF %IP3%==70  ( 
					set PHYSICALLOC=OCE
					set EPDDMSITE=%DefFileServer%
				) 
	IF %IP3%==71  ( 
					set PHYSICALLOC=OCE
					set EPDDMSITE=%DefFileServer%
				)    
	IF %IP3%==64  ( 
					set PHYSICALLOC=AMER-S
					set EPDDMSITE=gam
				)    
	IF %IP3%==65  ( 
					set PHYSICALLOC=AMER-S
					set EPDDMSITE=gam
				)
	goto :EOF
				
:IP_2
	set PHYSICALLOC=AMER
	set EPDDMSITE=gam
	set vpnusertype=SOHO
	goto :EOF

:IP_3
	::MarelVPN-EMEA
	IF %IP2%==85  ( 
					set PHYSICALLOC=EMEA
					set EPDDMSITE=%DefFileServer%
				)
	::MarelVPN-ASOU
	IF %IP2%==86  ( 
					set PHYSICALLOC=OCE
					set EPDDMSITE=%DefFileServer%
				) 			
	::MarelVPN-APAC
	IF %IP2%==87  ( 
					set PHYSICALLOC=APAC
					set EPDDMSITE=%DefFileServer%
				)
	::MarelVPN-AMER
	IF %IP2%==88  ( 
					set PHYSICALLOC=AMER
					set EPDDMSITE=gam
				) 
	::MarelVPN-LATAM
	IF %IP2%==89  ( 
					set PHYSICALLOC=AMER-S
					set EPDDMSITE=gam
				)
	goto :EOF
	
:IP_4
	::MarelVPN-China
	IF %IP3% GEQ 32 IF %IP3% LEQ 47  ( 
					set PHYSICALLOC=CHINA
					set EPDDMSITE=%DefFileServer%
				)				
    goto :EOF		

:IP_5_US
	::JBTMarel Azure-VPN US (APPPLM-3924)
	set PHYSICALLOC=AMER
	set EPDDMSITE=gam
	goto :EOF

:IP_5_EMEA
	::JBTMarel Azure-VPN EMEA (APPPLM-3924)
	set PHYSICALLOC=EMEA
	set EPDDMSITE=%DefFileServer%
	goto :EOF

:IP_5_OCE
	::JBTMarel Azure-VPN Oceania (APPPLM-3924)
	set PHYSICALLOC=OCE
	set EPDDMSITE=%DefFileServer%
	goto :EOF

:IP_5_APAC
	::JBTMarel Azure-VPN APAC (APPPLM-3924)
	set PHYSICALLOC=APAC
	set EPDDMSITE=%DefFileServer%
	goto :EOF

:IP_5_LATAM
	::JBTMarel Azure-VPN LATAM (APPPLM-3924)
	set PHYSICALLOC=AMER-S
	set EPDDMSITE=gam
	goto :EOF		