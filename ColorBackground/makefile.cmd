@echo off
echo "Assembling source code..."
start "" ../dasm.exe *.asm -f3 -v0 -ocartridge.bin
rem See website https://8bitworkshop.com/ to debug code