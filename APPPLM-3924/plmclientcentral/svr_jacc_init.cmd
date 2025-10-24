REM MyDestinationIs:[C:\Agile_E621/axalant/cmd/]
REM IAmPartOfComponent:[JavaClient]
REM MyValidOperationSystemIs:[Windows]
@echo off
REM $Id: tpl_jacc.cmd,v 34.216 2023/01/17 02:48:46 ebondoc Exp $
:: TODO do we need to do anything with JACC_HOME to set JACC_HOME=$APPDATA\e61
:: check why setlocal was in place
set ep_root=%L_Root%\%ApplicationType%
SET cax_lgv_dat=C:\ECP\lgv_dat

REM setlocal
set JAVA_HOME=%ep_root%\jre8_x86

if not exist "%JAVA_HOME%\bin\javaw.exe" (
  echo No "%JAVA_HOME%\bin\javaw.exe" found
  echo Is plm_root: "%JAVA_HOME%" set correctly?
  pause
  exit
)

rem - Needed for AutoVue integration:
if not exist "%JAVA_HOME%\jre\" goto jreIsActive
set PATH=%JAVA_HOME%\jre\bin;%PATH%
:jreIsActive
set axalant_root=%ep_root%\axalant
set ext_root=%ep_root%\ext
set jlib=%ext_root%\bin\java
set EP_MACH=intel-ms-nt6.1

set PATH=%axalant_root%\bin\%EP_MACH%;%ext_root%\bin\%EP_MACH%;%PATH%
set CLASSPATH=%axalant_root%\bin\java\jacc.jar
set CLASSPATH=%CLASSPATH%;%axalant_root%\ini
set CLASSPATH=%CLASSPATH%;%axalant_root%\bin\java\agile-jacc-images.jar

rem - Go to lib directory to keep classpath short
pushd %jlib%

rem - Essential libraries
set CLASSPATH=%CLASSPATH%;log4j-1.2-api-2.20.0.jar
set CLASSPATH=%CLASSPATH%;log4j-api-2.20.0.jar
set CLASSPATH=%CLASSPATH%;log4j-core-2.20.0.jar
set CLASSPATH=%CLASSPATH%;foxtrot-core-4.0.jar
set CLASSPATH=%CLASSPATH%;jide-action-3.7.11.jar
set CLASSPATH=%CLASSPATH%;jide-common-3.7.11.jar
set CLASSPATH=%CLASSPATH%;jide-components-3.7.11.jar 
set CLASSPATH=%CLASSPATH%;jide-dialogs-3.7.11.jar
set CLASSPATH=%CLASSPATH%;jide-dock-3.7.11.jar
set CLASSPATH=%CLASSPATH%;jide-grids-3.7.11.jar
set CLASSPATH=%CLASSPATH%;jide-plaf-jdk7-3.7.11.jar
set CLASSPATH=%CLASSPATH%;jide-properties-3.7.11.jar
set CLASSPATH=%CLASSPATH%;httpclient-4.5.13.jar
set CLASSPATH=%CLASSPATH%;httpcore-4.4.14.jar
set CLASSPATH=%CLASSPATH%;httpmime-4.5.13.jar
set CLASSPATH=%CLASSPATH%;commons-codec-1.15.jar
set CLASSPATH=%CLASSPATH%;commons-logging-1.2-f4fdecd.jar
rem - XML support
set CLASSPATH=%CLASSPATH%;dom4j-2.1.3.jar
set CLASSPATH=%CLASSPATH%;jaxen-1.2.0.jar
set CLASSPATH=%CLASSPATH%;xercesImpl-2.12.2.jar
set CLASSPATH=%CLASSPATH%;xml-apis-1.4.01.jar
rem - Workflow editor
set CLASSPATH=%CLASSPATH%;jviews-diagrammer-redist-9.3.jar
set CLASSPATH=%CLASSPATH%;jviews-framework-all-redist-9.3.jar
set CLASSPATH=%CLASSPATH%;batik-jviews-svggen-9.3.jar
set CLASSPATH=%CLASSPATH%;icu4j-58.2.jar
set CLASSPATH=%CLASSPATH%;svgdom-1.0.jar
rem - ASE
set CLASSPATH=%CLASSPATH%;batik-all-1.16.jar
set CLASSPATH=%CLASSPATH%;sac-1.3.jar
rem - OfficeSuite
set CLASSPATH=%CLASSPATH%;comfyj-2.13.jar
set CLASSPATH=%CLASSPATH%;comfyj-native-2.13.jar
set CLASSPATH=%CLASSPATH%;jniwrap-3.11.jar
set CLASSPATH=%CLASSPATH%;slf4j-api-2.0.7.jar
set CLASSPATH=%CLASSPATH%;slf4j-reload4j-2.0.7.jar
set CLASSPATH=%CLASSPATH%;winpack-3.11.jar
set CLASSPATH=%CLASSPATH%;commons-io-2.8.0.jar
rem - XPLM Structure Browser Plug-in (Marel customized section) ---------------
set CLASSPATH=%CLASSPATH%;browser\
set CLASSPATH=%CLASSPATH%;browser\*
rem - Groovy Plugin
set CLASSPATH=%CLASSPATH%;groovy-3.0.8.jar
set CLASSPATH=%CLASSPATH%;groovy-console-3.0.8.jar
set CLASSPATH=%CLASSPATH%;groovy-swing-3.0.8.jar
rem - Waffle 
set CLASSPATH=%CLASSPATH%;waffle-jna-3.0.0.jar
set CLASSPATH=%CLASSPATH%;jna-5.6.0.jar
set CLASSPATH=%CLASSPATH%;jna-platform-5.6.0.jar


rem Maximum heap size for Java VM
set VM_OPTS=-Xmx512M

REM start "Agile e6 JavaClient" "%JAVA_HOME%\bin\javaw.exe" %VM_OPTS% -Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel -Djava.security.auth.login.config="%ep_root%\axalant\ini\jacc-jaas.conf" -Djacc.home="$APPDATA\e62" -Djacc.defaults="%ep_root%\axalant\ini\jacc.defaults" -Djacc.imageDir="%ep_root%\axalant\bmp" -DEP_MACH="%EP_MACH%" -Daxalant_root="%axalant_root%" -Dep_root="%ep_root%" com.agile.jacc.e6.Jacc %*
REM endlocal


