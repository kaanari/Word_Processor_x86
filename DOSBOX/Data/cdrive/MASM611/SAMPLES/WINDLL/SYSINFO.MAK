ORIGIN = PWB
ORIGIN_VER = 2.1.49
PROJ = sysinfo
PROJFILE = sysinfo.mak
DEBUG = 1

CC  = cl
CFLAGS_G  = /W2 /ASw /GD /Zp /BATCH /DWINVER=0x0300
CFLAGS_D  = /f /Zi /Od /Gs
CFLAGS_R  = /f- /Oe /Og /Os /Gs
CXX  = cl
CXXFLAGS_G  = /W2 /ASw /GD /Zp /BATCH /DWINVER=0x0300
CXXFLAGS_D  = /f /Zi /Od /Gs
CXXFLAGS_R  = /f- /Oe /Og /Os /Gs
ASM  = ml
AFLAGS_G  = /Cx /W2
AFLAGS_D  = /Zi
AFLAGS_R  = /nologo
MAPFILE_D  = NUL
MAPFILE_R  = NUL
LFLAGS_G  = /BATCH /ONERROR:NOEXE
LFLAGS_D  = /CO /NOFA
LFLAGS_R  = /NOFA
LLIBS_G  = LIBW.LIB
LINKER	= link
ILINK  = ilink
LRF  = echo > NUL
ILFLAGS  = /a /e
RC  = rc
IMPLIB	= implib
RCFLAGS2  = /30

FILES  = SYSINFO.ASM SYSINFO.DEF DLLENTRY.ASM
DEF_FILE  = SYSINFO.DEF
OBJS  = SYSINFO.obj DLLENTRY.obj

all: $(PROJ).dll

.SUFFIXES:
.SUFFIXES:
.SUFFIXES: .obj .asm

SYSINFO.obj : SYSINFO.ASM
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoSYSINFO.obj SYSINFO.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoSYSINFO.obj SYSINFO.ASM
!ENDIF

DLLENTRY.obj : DLLENTRY.ASM
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoDLLENTRY.obj DLLENTRY.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoDLLENTRY.obj DLLENTRY.ASM
!ENDIF


$(PROJ).dll : $(DEF_FILE) $(OBJS)
!IF $(DEBUG)
	$(LRF) @<<$(PROJ).lrf
$(RT_OBJS: = +^
) $(OBJS: = +^
)
$@
$(MAPFILE_D)
$(LIBS: = +^
) +
$(LLIBS_G: = +^
) +
$(LLIBS_D: = +^
)
$(DEF_FILE) $(LFLAGS_G) $(LFLAGS_D);
<<
!ELSE
	$(LRF) @<<$(PROJ).lrf
$(RT_OBJS: = +^
) $(OBJS: = +^
)
$@
$(MAPFILE_R)
$(LIBS: = +^
) +
$(LLIBS_G: = +^
) +
$(LLIBS_R: = +^
)
$(DEF_FILE) $(LFLAGS_G) $(LFLAGS_R);
<<
!ENDIF
	$(LINKER) @$(PROJ).lrf
	$(IMPLIB) $*.lib $@


.asm.obj :
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /Fo$@ $<
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /Fo$@ $<
!ENDIF


run: $(PROJ).dll


debug: $(PROJ).dll
