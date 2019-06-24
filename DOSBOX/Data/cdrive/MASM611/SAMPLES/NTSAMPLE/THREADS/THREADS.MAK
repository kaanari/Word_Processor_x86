
# This is the make file for use with the Win32 SDK tools.

!include <ntwin32.mak>

threads.exe : threads.obj asmthred.obj
    $(link) @<<
$(ldebug)
$(guilflags)
$(guilibs)
threads.obj
asmthred.obj
-out:$@
<<

threads.obj : threads.c
    $(cc) $(cdebug) $(cflags) $(cvars) threads.c

asmthred.obj : asmthred.asm
    ml /c /Zi /coff asmthred.asm
