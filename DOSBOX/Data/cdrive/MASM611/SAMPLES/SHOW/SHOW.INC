;* SHOW.INC - Include file used by SHOW.
;* Contains constants, prototypes, and global variables.

; Constants
LINE_POS        EQU     6       ; Position of line number string
FILE_POS        EQU     6       ; Position of filename string
X_MAX           EQU     80      ; Number of columns
STAT_CLR        EQU     030h    ; Status line color - black on cyan
STAT_BW         EQU     070h    ; Status line B&W - black on white
SCRN_CLR        EQU     017h    ; Screen color - white on blue
SCRN_BW         EQU     007h    ; Screen B&W - white on black

NAME_MAX	EQU	66	; DOS maximum file specification
SEG_CLR 	EQU	0B800h	; Color address
SEG_MONO        EQU     0B000h  ; Monochrome address

; Prototypes
Show            PROTO
GetNamePos      PROTO pchSpec:PTR BYTE
GetVid          PROTO
Pager           PROTO cLines:SWORD
GoBack          PROTO
GoForeward      PROTO
EndCount        PROTO
BinToStr        PROTO i:WORD, pch:PTR BYTE
Quit            PROTO
ShowLine	PROTO fpBuffer:FAR PTR BYTE, y:WORD, attr:BYTE
IsEGA           PROTO
CellFill        PROTO yStart:WORD, cbCell:WORD, celFill:WORD
FillTab         PROTO


; Global variables

        .DATA
        EXTERNDEF       atSta:BYTE, atScr:BYTE, segBuf:WORD, offBuf:WORD
        EXTERNDEF       cbBuf:WORD, stLine:BYTE, yMax:WORD, yCur:WORD
	EXTERNDEF	segVid:WORD, fCGA:BYTE, celCur:WORD, atCur:BYTE
	EXTERNDEF	celScr:WORD

@CurSeg ENDS		; End current
