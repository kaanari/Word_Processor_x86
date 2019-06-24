
# Set this macro to 'VCNT' to use the Visual C++ tools.
# Set it to anything else to use the Win32 SDK tools.

TOOLS = VCNT


!IF "$(TOOLS)" == "VCNT"

CC = cl
LINK = link
IMPLIB = lib
ENTRY_DLL = DllMain

!ELSE

CC = cl386
LINK = link32
IMPLIB = lib32
LIBS = kernel32.lib libc.lib
ENTRY_DLL = DllMain@0
ENTRY = -entry:mainCRTStartup

!ENDIF



all : asmdll.dll cmain.exe

asmdll.dll : asmdll.obj asmdll.exp
    $(LINK) @<<
asmdll.obj
asmdll.exp
-entry:$(ENTRY_DLL)
$(LIBS)
-out:asmdll.dll
-dll
<<

asmdll.obj : asmdll.asm
    ml /c /coff asmdll.asm

asmdll.exp : asmdll.def asmdll.obj
    $(IMPLIB) -def:asmdll.def asmdll.obj -out:asmdll.lib -machine:i386

cmain.exe : cmain.obj asmdll.lib
    $(LINK) @<<
cmain.obj
asmdll.lib
-subsystem:console
$(ENTRY)
$(LIBS)
-out:cmain.exe
<<

cmain.obj : cmain.c
    $(CC) /Od /D_X86_ /c cmain.c


    
