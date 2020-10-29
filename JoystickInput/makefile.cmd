@echo off
echo "Assembling source code..."
start "" ../dasm.exe *.asm -f3 -v0 -ocartridge.bin -lcartridge.lst -scartridge.sym
rem See website https://8bitworkshop.com/ to debug code
rem Use Stella emulator: https://stella-emu.github.io/