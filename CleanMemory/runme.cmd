@echo off
echo "Assembling source code..."
start "" ../dasm.exe cleanmemory.asm -f3 -v0 -ocartridge.bin
