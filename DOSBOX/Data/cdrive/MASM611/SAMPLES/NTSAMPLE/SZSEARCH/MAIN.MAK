
# Set this macro to 'VCNT' to use the Visual C++ tools.
# Set it to anything else to use the Win32 SDK tools.

TOOLS = VCNT


!IF "$(TOOLS)" == "VCNT"

CC = cl
LINK = link
LFLAGS =

!ELSE

CC = cl386
LINK = link32
LFLAGS = -subsystem:console -entry:mainCRTStartup -machine:i386
LIBS = libc.lib kernel32.lib

!ENDIF


main.exe : main.obj szsearch.obj
    $(LINK) $(LFLAGS) @<<
main.obj
szsearch.obj
-out:$@
$(LIBS)
<<

main.obj : main.c
    $(CC) /c main.c

szsearch.obj : szsearch.asm
    ml /c /coff szsearch.asm
