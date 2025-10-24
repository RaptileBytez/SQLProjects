@echo off
:: Bart van der Linden 07-01-2019
:: - Procedure to get the environment from the parameters.
:: Changes:
:: - Initial setup APPPLM-128
:: Todo:
:: - 

:: make the input string lowercase
set par=%*
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "par=%%par:%%~i%%"

:: Split the input string
FOR /f "tokens=1,2,3,4,5,6 delims= " %%a in ("%par%") do set IP1=%%a&set IP2=%%b&set IP3=%%c&set IP4=%%d&set IP5=%%e&set IP6=%%f

:: define where the environment is located in the input string
for /f "tokens=1-6" %%a IN ("%par%") DO (
	if %%a==-a (set env=%%b)
	if %%b==-a (set env=%%c)
	if %%c==-a (set env=%%d)
	if %%d==-a (set env=%%e)
	if %%e==-a (set env=%%f)
)

set PLMenvironment=%env%