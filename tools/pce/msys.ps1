# Runs a tools/pce/*.sh script in the MSYS2 UCRT64 shell from PowerShell (the Terminal panel), so the user
# can watch it. Usage: & .\tools\pce\msys.ps1 build_run   (or recompile_build, build, run)
param([Parameter(Mandatory = $true)][string]$Script)
$env:MSYSTEM = 'UCRT64'; $env:CHERE_INVOKING = '1'
& 'D:\Apps\msys64\usr\bin\bash.exe' -l "D:/Compiling/BotW-Native/tools/pce/$Script.sh"
