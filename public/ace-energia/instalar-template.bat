@echo off
:: ACE Desk Energia - instala o ajudante de hibernacao neste PC
:: (gerado pelo ACE Desk para o PC __ACE_ID__)
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%USERDOMAIN%\%USERNAME%' -Verb RunAs"
  exit /b
)
set "ACEUSER=%~1"
if "%ACEUSER%"=="" set "ACEUSER=%USERDOMAIN%\%USERNAME%"
set "REL=%USERPROFILE%\Downloads\ACE-Desk-Energia-relatorio.txt"
if not exist "%USERPROFILE%\Downloads" set "REL=%TEMP%\ACE-Desk-Energia-relatorio.txt"
echo Instalando o ajudante de energia do ACE Desk...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; $f=Join-Path $env:TEMP 'ace-energia-instalar.ps1'; Invoke-WebRequest -Uri '__ACE_URL__/ace-energia/instalar.ps1' -OutFile $f -UseBasicParsing; & $f -Url '__ACE_URL__' -Id '__ACE_ID__' -Token '__ACE_TOKEN__' -User '%ACEUSER%' -Report '%REL%'"
echo.
echo Pronto! Pode fechar esta janela e avisar o Claude.
pause
