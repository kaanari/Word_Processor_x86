ORIGIN = PWB
ORIGIN_VER = 2.1.49
PROJ = WINCLOCK
PROJFILE = WINCLOCK.MAK
DEBUG = 1

CC  = cl
CFLAGS_G  = /G2 /W2 /GA /GEf /Zp /BATCH
CFLAGS_D  = /f /Zi /Od /Gs
CFLAGS_R  = /f- /Oe /Og /Os /Gs
CXX  = cl
CXXFLAGS_G  = /G2 /W2 /GA /GEf /Zp /BATCH
CXXFLAGS_D  = /f /Zi /Od /Gs
CXXFLAGS_R  = /f- /Oe /Og /Os /Gs
ASM  = ml
AFLAGS_G  = /W2 /DMODEL=small
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

FILES  = APPENTRY.ASM WINCLOCK.DEF WINCLOCK.RC WINCLOCK.ASM
DEF_FILE  = WINCLOCK.DEF
OBJS  = APPENTRY.obj WINCLOCK.obj
RESS  = WINCLOCK.res

all: $(PROJ).exe

.SUFFIXES:
.SUFFIXES: .obj .res .asm .rc
.SUFFIXES: .obj .res .asm .rc

APPENTRY.obj : APPENTRY.ASM
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoAPPENTRY.obj APPENTRY.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoAPPENTRY.obj APPENTRY.ASM
!ENDIF

WINCLOCK.res : WINCLOCK.RC winclock.ico
	$(RC) $(RCFLAGS1) /r /fo WINCLOCK.res WINCLOCK.RC

WINCLOCK.obj : WINCLOCK.ASM
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoWINCLOCK.obj WINCLOCK.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoWINCLOCK.obj WINCLOCK.ASM
!ENDIF


$(PROJ).exe : $(DEF_FILE) $(OBJS) $(RESS)
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
	$(RC) $(RCFLAGS2) $(RESS) $@


.asm.obj :
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /Fo$@ $<
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /Fo$@ $<
!ENDIF

.rc.res :
	$(RC) $(RCFLAGS1) /r /fo $@ $<


run: $(PROJ).exe
	WX $(WXFLAGS) $(PROJ).exe $(RUNFLAGS)

debug: $(PROJ).exe
	WX /p $(WXFLAGS) CVW $(CVFLAGS) $(PROJ).exe $(RUNFLAGS)
