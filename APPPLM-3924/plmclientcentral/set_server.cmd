@echo off
:: Bart van der Linden 18-02-2019
:: - Procedure to get the server from the parameters.
:: Changes:
:: - 
:: Todo:
:: - 

:: make the input string lowercase
set par=%*
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "par=%%par:%%~i%%"

:: Split the input string
FOR /f "tokens=1,2,3,4,5,6 delims= " %%a in ("%par%") do set IP1=%%a&set IP2=%%b&set IP3=%%c&set IP4=%%d&set IP5=%%e&set IP6=%%f

:: define where the environment is located in the input string
for /f "tokens=1-6" %%a IN ("%par%") DO (
	if %%a==-h (set srv=%%b)
	if %%b==-h (set srv=%%c)
	if %%c==-a (set srv=%%d)
	if %%d==-a (set srv=%%e)
	if %%e==-a (set srv=%%f)
)

set PLMserver=%srv%