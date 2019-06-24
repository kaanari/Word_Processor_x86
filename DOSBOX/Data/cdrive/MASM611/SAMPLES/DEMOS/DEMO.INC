BUFFERSIZE      EQU     2048            ; Buffer size in bytes for disk I/O

MDA             EQU     0               ; Adapter constants
CGA             EQU     1
MCGA            EQU     2
EGA             EQU     3
VGA             EQU     4
MONO            EQU     0               ; Display constants
COLOR           EQU     1

BACKSP          EQU     08              ; ASCII code for BACKSPACE key
TAB             EQU     09              ; ASCII code for TAB key
LF              EQU     10              ; ASCII code for line feed
CR              EQU     13              ; ASCII code for ENTER key
ESCAPE          EQU     27              ; ASCII code for ESCAPE key
LEFT            EQU     75              ; Scan code for LEFT arrow
CRLF            EQU     0A0Dh           ; Value for carriage return/line feed

; Bit masks for shift status
shIns           EQU   80h
shCaps          EQU   40h
shNum           EQU   20h
shScroll        EQU   10h
shAlt           EQU   08h
shCtl           EQU   04h
shLeft          EQU   02h
shRight         EQU   01h

;* LoadPtr - Macro to load far address into segment:register pair, or
;* near address into register.
;*
;* Params:  sgmnt - Segment to be loaded with segment address
;*          reg - Register to be loaded with offset address
;*          pointer - Pointer to address
;*
;* Shows:   Instructions - lds     les
;*          Directives - MACRO     IF        IFIDNI     ELSE
;*                       ELSE      IFENDIF   .ERR       ENDM
;*          Operators - < >       ;;

LoadPtr MACRO sgmnt, reg, pointer       ;; Macro definition
    IF @DataSize                        ;; If far pointer, and
        IFIDNI <sgmnt>, <ds>            ;;   if 1st argument is DS,
            lds reg, pointer            ;;   load DS:reg with far address
        ELSEIFIDNI <sgmnt>, <es>        ;;   or if 1st argument is ES,
            les reg, pointer            ;;   load ES:reg with far address
        ELSE                            ;; Generate error if not DS or ES
            .ERR <First argument must be DS or ES>
        ENDIF
    ELSE                                ;; If near pointer,
        IFIDNI <sgmnt>, <es>            ;;   and if segment is ES,
            push ds                     ;;   ensure ES points to
            pop  es                     ;;   same segment as DS
        ENDIF
        mov reg, pointer                ;; Then load reg with near address
    ENDIF
ENDM

;* GetVidOffset - Macro to determine offset in video segment that corresponds
;* to given screen coordinates.
;*
;* Params:  Row - Screen row (top line = 0)
;*          Col - Screen column (leftmost column = 0)

GetVidOffset MACRO Row, Col
    mov ax, Row
    mov bl, vconfig.cols
    mul bl
    add ax, Col
    shl ax, 1
ENDM

;* Vector - Macro to read current interrupt vector, store it, and replace it.
;*
;* Shows:   Equates - @CodeSize     @code
;*
;* Params:  num - Vector number
;*          old - Pointer to doubleword for storing old vector
;*          new - Pointer to new handler

Vector MACRO num, old, new              ;; Macro definition
    push ds                             ;; Save DS and ES registers
    push es
    mov  ah, 35h                        ;; AH = DOS function number
    mov  al, num                        ;; AL = interrupt number
    int  21h                            ;; Get Interrupt Vector
    mov  WORD PTR old[0], bx            ;; Store it
    mov  WORD PTR old[2], es
    IF @CodeSize                        ;; If medium or large model,
        lds dx, new                     ;;    load DS from parameter
    ELSE
        mov bx, @code                   ;; Else ensure DS points to
        mov ds, bx                      ;;    to code segment
        mov dx, WORD PTR new            ;; DS:DX equals new vector
    ENDIF
    mov ah, 25h                         ;; AH = DOS function number
    int 21h                             ;; Set Interrupt Vector
    pop es                              ;; Restore ES and DS
    pop ds
ENDM

PBYTE   TYPEDEF      PTR BYTE   ; Pointer to byte
PWORD   TYPEDEF      PTR WORD   ; Pointer to word
PSWORD  TYPEDEF      PTR SWORD  ; Pointer to integer
PDWORD  TYPEDEF      PTR DWORD  ; Pointer to integer
NPBYTE  TYPEDEF NEAR PTR BYTE   ; Near pointer to byte
FPBYTE  TYPEDEF FAR  PTR BYTE   ; Far pointer to byte
FPVOID  TYPEDEF FAR  PTR        ; Far pointer to void
PSEG    TYPEDEF WORD            ; Segment value

; Structure for video configuration
VIDCONFIG       STRUCT
  mode          BYTE    ?
  dpage         BYTE    ?
  rows          BYTE    ?
  cols          BYTE    ?
  display       BYTE    ?
  adapter       BYTE    ?
  sgmnt         WORD    ?
VIDCONFIG       ENDS
PVIDCONFIG      TYPEDEF PTR VIDCONFIG

; Structure for FindFirst and FindNext
FILEINFO        STRUCT
  pad           BYTE    21 DUP (?)      ; pad to 43 bytes
  attrib        BYTE    ?               ; file attribute
  time          WORD    ?               ; file time
  date          WORD    ?               ; file date
  count         DWORD   ?               ; file size
  filename      BYTE    13 DUP (?)      ; filename
FILEINFO        ENDS
PFILEINFO       TYPEDEF PTR FILEINFO

; Structure for disk statistics
DISKSTAT        STRUCT
  total         WORD    ?               ; Total clusters
  avail         WORD    ?               ; Available clusters
  sects         WORD    ?               ; Sectors per cluster
  bytes         WORD    ?               ; Bytes per sector
DISKSTAT        ENDS
PDISKSTAT       TYPEDEF PTR DISKSTAT

; Structure for parameter block
PARMBLK         STRUCT
  env           PSEG    ?               ; Segment of environment block
  taddr         FPBYTE  ?               ; Segment:offset address of tail
  fcb1          FPBYTE  ?               ; Segment:offset address of 1st FCB
  fcb2          FPBYTE  ?               ; Segment:offset address of 2nd FCB
PARMBLK         ENDS
PPARMBLK        TYPEDEF PTR PARMBLK

; Prototypes from COMMON.ASM
GetVer          PROTO PASCAL
GetVidConfig    PROTO PASCAL 
StrWrite        PROTO PASCAL Row:WORD, Col:WORD, Sptr:PBYTE
ClearBox        PROTO PASCAL Attr:WORD, Row1:WORD, Col1:WORD,
                                        Row2:WORD, Col2:WORD
DisableCga      PROTO PASCAL 
EnableCga       PROTO PASCAL 
SetCurPos       PROTO PASCAL Row:WORD, Col:WORD
GetCurPos       PROTO PASCAL 
StrInput        PROTO PASCAL Row:WORD, Col:WORD, Max:WORD, Sptr:PBYTE

; Prototypes from MISC.ASM
WinOpen         PROTO PASCAL Row1:WORD, Col1:WORD,
                             Row2:WORD, Col2:WORD, Attr:WORD
WinClose        PROTO PASCAL Adr:WORD
SetCurSize      PROTO PASCAL Scan1:WORD, Scan2:WORD
GetCurSize      PROTO PASCAL 
GetShift        PROTO PASCAL 
GetMem          PROTO PASCAL
GetKeyClock     PROTO PASCAL Row:WORD, Col:WORD
VeriAnsi        PROTO PASCAL 
VeriPrint       PROTO PASCAL 
VeriCop         PROTO PASCAL
SetLineMode     PROTO PASCAL Line:WORD
Pause           PROTO PASCAL Duration:WORD
Sound           PROTO PASCAL Freq:WORD, Duration:WORD
WriteTTY        PROTO PASCAL Sptr:PBYTE, icolor:WORD
Colors          PROTO PASCAL Logic:WORD, Attr:WORD,
                             Row1:WORD, Col1:WORD, Row2:WORD, Col2:WORD
Exec            PROTO PASCAL Spec:PBYTE, Block:PPARMBLK,
                             CtrBrk:PTR FAR,
                             CtrlC:PTR FAR,
                             Criterr:PTR FAR
BinToHex        PROTO PASCAL Num:WORD, Sptr:PBYTE
NewBlockSize    PROTO PASCAL Adr:WORD, Resize:WORD
Initialize      PROTO PASCAL
                EXTERNDEF    IntToAsc:PROC


; Prototypes from MATH.ASM
AddLong         PROTO PASCAL Long1:SDWORD, Long2:SDWORD
SubLong         PROTO PASCAL Long1:SDWORD, Long2:SDWORD
ImulLong        PROTO PASCAL Long1:SDWORD, Long2:SDWORD
MulLong         PROTO PASCAL Long1:DWORD, Long2:DWORD
IdivLong        PROTO PASCAL Long1:SDWORD, Short2:SWORD, Remn:PSWORD
DivLong         PROTO PASCAL Long1:DWORD, Short2:WORD, Remn:PWORD
Quadratic       PROTO PASCAL aa:DWORD, bb:DWORD, cc:DWORD,
                             r1:PDWORD, r2:PDWORD

; Prototypes from FILE.ASM
ChangeDrive     PROTO PASCAL Drive:WORD
GetDiskSize     PROTO PASCAL Drive:WORD, Disk:PDISKSTAT
SetDta          PROTO PASCAL Dta:FPBYTE
GetDta          PROTO PASCAL Dta:FPBYTE
ReadCharAttr    PROTO PASCAL Attr:PWORD
GetCurDir       PROTO PASCAL Spec:PBYTE
GetCurDrive     PROTO PASCAL
CopyFile        PROTO PASCAL Imode:WORD, Fspec1:PBYTE, Fspec2:PBYTE
DelFile         PROTO PASCAL Fspec:PBYTE
MakeDir         PROTO PASCAL Pspec:PBYTE
RemoveDir       PROTO PASCAL Pspec:PBYTE
ChangeDir       PROTO PASCAL Pspec:PBYTE
GetAttribute    PROTO PASCAL Fspec:PBYTE
SetAttribute    PROTO PASCAL Attr:WORD, Fspec:PBYTE
RenameFile      PROTO PASCAL Fspec1:PBYTE, Fspec2:PBYTE
GetFileTime     PROTO PASCAL Handle:WORD, Sptr:PBYTE
FindFirst       PROTO PASCAL Attr:WORD, Fspec:PBYTE, Finfo:PFILEINFO
FindNext        PROTO PASCAL Finfo:PFILEINFO
UniqueFile      PROTO PASCAL Attr:WORD, Pspec:PBYTE
OpenFile        PROTO PASCAL Access:WORD, Fspec:PBYTE
CloseFile       PROTO PASCAL Handle:WORD
CreateFile      PROTO PASCAL Attr:WORD, Fspec:PBYTE
CreateNewFile   PROTO PASCAL Attr:WORD, Fspec:PBYTE
ReadFile        PROTO PASCAL Handle:WORD, Len:WORD, Pbuff:PBYTE
WriteFile       PROTO PASCAL Handle:WORD, Sptr:PBYTE
Rewind          PROTO PASCAL Handle:WORD
GetFileSize     PROTO PASCAL Handle:WORD
GetStr          PROTO PASCAL Strbuf:PBYTE, Maxlen:WORD
StrCompare      PROTO PASCAL Sptr1:PBYTE, Sptr2:PBYTE, Len:WORD
StrFindChar     PROTO PASCAL Ichar:SBYTE, Sptr:PBYTE, Direct:WORD


;* Global variables defined with EXTERNDEF are public in the module
;* in which they are defined, and external in other modules in which
;* they are used.
;*
;* Shows:   Directive             - EXTERNDEF
;*          Predefined text macro - @CurSeg

        .DATA
        EXTERNDEF   vconfig:VIDCONFIG   ; Video configuration
        EXTERNDEF   _psp:PSEG           ; Segment of Program Segment Prefix
        EXTERNDEF   _env:PSEG           ; Segment of environment block
@CurSeg ENDS                            ; End .DATA so any subsequent
                                        ;   include is outside segment
