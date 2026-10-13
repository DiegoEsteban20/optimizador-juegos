@echo off
chcp 65001 >NUL
cd /d "%~dp0"
if /I "%~1"=="navegadores" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "Optimizar.ps1" -CerrarNavegadores
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "Optimizar.ps1"
)
