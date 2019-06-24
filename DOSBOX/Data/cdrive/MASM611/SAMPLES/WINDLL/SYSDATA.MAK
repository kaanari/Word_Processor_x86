ORIGIN = PWB
ORIGIN_VER = 2.1.49
PROJ = SYSDATA
PROJFILE = SYSDATA.MAK
DEBUG = 1

CC	= cl
CFLAGS_G  = /W2 /GA /GEf /Zp /BATCH /DWINVER=0x0300
CFLAGS_D  = /f /Zi /Od /Gs
CFLAGS_R  = /f- /Oe /Og /Os /Gs
CXX  = cl
CXXFLAGS_G	= /W2 /GA /GEf /Zp /BATCH /DWINVER=0x0300
CXXFLAGS_D	= /f /Zi /Od /Gs
CXXFLAGS_R	= /f- /Oe /Og /Os /Gs
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
RC	= rc
RCFLAGS2  = /30
H2INC  = h2inc

FILES  = APPENTRY.ASM SYSDATA.ASM SYSDATA.DEF SYSDATA.RC SYSINFO.LIB\
		SYSDATA.INC
DEF_FILE  = SYSDATA.DEF
OBJS  = APPENTRY.obj SYSDATA.obj
LIBS_EXT  = SYSINFO.LIB
LIBS  = $(LIBS_EXT)
RESS  = SYSDATA.res

all: $(PROJ).exe

.SUFFIXES:
.SUFFIXES: .obj .inc .res .asm .h .rc
.SUFFIXES: .obj .res .asm .rc

APPENTRY.obj : APPENTRY.ASM
!IF $(DEBUG)
		$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoAPPENTRY.obj APPENTRY.ASM
!ELSE
		$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoAPPENTRY.obj APPENTRY.ASM
!ENDIF

SYSDATA.obj : SYSDATA.ASM dll.inc SYSDATA.INC
!IF $(DEBUG)
		$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoSYSDATA.obj SYSDATA.ASM
!ELSE
		$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoSYSDATA.obj SYSDATA.ASM
!ENDIF

SYSDATA.res : SYSDATA.RC sysdata.h sysdata.ico
		$(RC) $(RCFLAGS1) /r /fo SYSDATA.res SYSDATA.RC


$(PROJ).exe : $(DEF_FILE) $(OBJS) $(LIBS) $(RESS)
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

.h.inc :
		$(H2INC) $<

run: $(PROJ).exe
		WX $(WXFLAGS) $(PROJ).exe $(RUNFLAGS)

debug: $(PROJ).exe
		WX /p $(WXFLAGS) CVW $(CVFLAGS) $(PROJ).exe $(RUNFLAGS)
