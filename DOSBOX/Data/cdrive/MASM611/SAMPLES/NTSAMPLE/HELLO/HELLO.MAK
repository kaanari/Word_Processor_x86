

# Set this macro to 'VCNT' to use the Visual C++ tools.
# Set it to anything else to use the Win32 SDK tools.

TOOLS = VCNT

!IF "$(TOOLS)" == "VCNT"

LINK = link

!ELSE

LINK = link32

!ENDIF


all:
      ml /c /coff hello.asm
      $(LINK) -subsystem:console -entry:_start -out:hello.exe \
	 hello.obj kernel32.lib
