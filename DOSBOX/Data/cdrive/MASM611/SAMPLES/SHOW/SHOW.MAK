ORIGIN = PWB
ORIGIN_VER = 2.1.49
PROJ = show
PROJFILE = show.mak
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
LINKER  = link
ILINK  = ilink
LRF  = echo > NUL
ILFLAGS  = /a /e
BRFLAGS  =  /o $(PROJ).bsc
BSCMAKE  = bscmake
SBRPACK  = sbrpack
NMAKEBSC1  = set
NMAKEBSC2  = nmake
BROWSE  = 1
PACK_SBRS  = 1

FILES  = PAGER.ASM SHOW.ASM SHOWUTIL.ASM
OBJS  = PAGER.obj SHOW.obj SHOWUTIL.obj
SBRS  = PAGER.sbr SHOW.sbr SHOWUTIL.sbr

all: $(PROJ).exe

.SUFFIXES:
.SUFFIXES:
.SUFFIXES: .obj .sbr .asm

PAGER.obj : PAGER.ASM show.inc
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoPAGER.obj PAGER.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoPAGER.obj PAGER.ASM
!ENDIF

PAGER.sbr : PAGER.ASM show.inc
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FRPAGER.sbr PAGER.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FRPAGER.sbr PAGER.ASM
!ENDIF

SHOW.obj : SHOW.ASM show.inc 
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoSHOW.obj SHOW.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoSHOW.obj SHOW.ASM
!ENDIF

SHOW.sbr : SHOW.ASM show.inc 
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FRSHOW.sbr SHOW.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FRSHOW.sbr SHOW.ASM
!ENDIF

SHOWUTIL.obj : SHOWUTIL.ASM show.inc
!IF $(DEBUG)
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_D) /FoSHOWUTIL.obj SHOWUTIL.ASM
!ELSE
	$(ASM) /c $(AFLAGS_G) $(AFLAGS_R) /FoSHOWUTIL.obj SHOWUTIL.ASM
!ENDIF

SHOWUTIL.sbr : SHOWUTIL.ASM show.inc
!IF $(DEBUG)
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_D) /FRSHOWUTIL.sbr SHOWUTIL.ASM
!ELSE
	$(ASM) /Zs $(AFLAGS_G) $(AFLAGS_R) /FRSHOWUTIL.sbr SHOWUTIL.ASM
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
