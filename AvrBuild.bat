@ECHO OFF
"D:\AVRS4\AvrAssembler2\avrasm2.exe" -S "D:\myAVR\RF02\labels.tmp" -fI -W+ie -C V2E -o "D:\myAVR\RF02\RF02.hex" -d "D:\myAVR\RF02\RF02.obj" -e "D:\myAVR\RF02\RF02.eep" -m "D:\myAVR\RF02\RF02.map" "D:\myAVR\RF02\RF02.asm"
