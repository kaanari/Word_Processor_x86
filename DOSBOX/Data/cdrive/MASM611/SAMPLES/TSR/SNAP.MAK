ORIGIN = PWB
ORIGIN_VER = 2.1.49
PROJ = snap
PROJFILE = snap.mak
DEBUG = 1

CC  = cl
CFLAGS_G  = /W2 /BATCH /FR$*.sbr
CFLAGS_D  = /f /Zi /Od
CFLAGS_R  = /f- /Ot /Oi /Ol /Oe /Og /Gs
CXX  = cl
CXXFLAGS_G  = /W2 /BATCH /FR$*.sbr
CXXFLAGS_D  = /f /Zi /Od
CXXFLAGS_R  = /f- /Ot /Oi /Ol /Oe /Og /Gs
ASM  = ml
AFLAGS_G  = /Cx /W2 /FR$*.sbr
AFLAGS_D  = /Zi
AFLAGS_R  = /nologo
MAPFILE_D  = NUL
MAPFILE_R  = NUL
LFLAGS_G  = /NOI /BATCH
LFLAGS_D  = /CO /FAR
LFLAGS_R  = /EXE /FAR
LINKER	= link
ILINK  = ilink
LRF  = echo > NUL
ILFLAGS  = /a /e
BRFLAGS  =  /o $(PROJ).bsc
BSCMAKE  = bscmake
SBRPACK  = sbrpack
NMAKEBSC1  = set
NMAKEBSC2  = nmake
BROWSE	= 1
PACK_SBRS  = 1

FILES  = SNAP.ASM INSTALL.ASM HANDLERS.ASM ..\DEMOS\COMMON.ASM
OBJS  = SNAP.obj INSTALL.obj HANDLERS.obj ..\DEMOS\COMMON.obj
SBRS  = SNAP.sbr INSTALL.sbr HANDLERS.sbr ..\DEMOS\COMMON.sbr

all: $(PROJ).exe

.SUFFIXES:
.SUFFIXES:
.SUFFIXES: .obj .sbr .asm

SNAP.obj : SNAP.ASM ..\demos\demo.inc tsr.inc
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoSNAP.obj SNAP.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoSNAP.obj SNAP.ASM
!ENDIF

SNAP.sbr : SNAP.ASM ..\demos\demo.inc tsr.inc
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FRSNAP.sbr SNAP.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FRSNAP.sbr SNAP.ASM
!ENDIF

INSTALL.obj : INSTALL.ASM tsr.inc
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoINSTALL.obj INSTALL.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoINSTALL.obj INSTALL.ASM
!ENDIF

INSTALL.sbr : INSTALL.ASM tsr.inc
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FRINSTALL.sbr INSTALL.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FRINSTALL.sbr INSTALL.ASM
!ENDIF

HANDLERS.obj : HANDLERS.ASM tsr.inc
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoHANDLERS.obj HANDLERS.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoHANDLERS.obj HANDLERS.ASM
!ENDIF

HANDLERS.sbr : HANDLERS.ASM tsr.inc
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FRHANDLERS.sbr HANDLERS.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FRHANDLERS.sbr HANDLERS.ASM
!ENDIF

..\DEMOS\COMMON.obj : ..\DEMOS\COMMON.ASM ..\demos\demo.inc
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /Fo..\DEMOS\COMMON.obj ..\DEMOS\COMMON.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /Fo..\DEMOS\COMMON.obj ..\DEMOS\COMMON.ASM
!ENDIF

..\DEMOS\COMMON.sbr : ..\DEMOS\COMMON.ASM ..\demos\demo.inc
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FR..\DEMOS\COMMON.sbr ..\DEMOS\COMMON.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FR..\DEMOS\COMMON.sbr ..\DEMOS\COMMON.ASM
!ENDIF


$(PROJ).exe : $(OBJS)
	-$(NMAKEBSC1) MAKEFLAGS=
	-$(NMAKEBSC2) $(NMFLAGS) -f $(PROJFILE) $(PROJ).bsc
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

$(PROJ).bsc : $(SBRS)
	$(BSCMAKE) @<<
$(BRFLAGS) $(SBRS)
<<


.asm.obj :
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /Fo$@ $<
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /Fo$@ $<
!ENDIF

.asm.sbr :
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FR$@ $<
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FR$@ $<
!ENDIF


run: $(PROJ).exe
	$(PROJ).exe $(RUNFLAGS)

debug: $(PROJ).exe
	CV $(CVFLAGS) $(PROJ).exe $(RUNFLAGS)
