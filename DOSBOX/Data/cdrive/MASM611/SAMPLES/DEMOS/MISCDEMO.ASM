;* MISCDEMO - Invokes many of the assembly example procedures, most of them
;* demonstrating assembly language instructions and calls to the system BIOS.
;* MISCDEMO demonstrates how to:
;*
;*         -   determine hardware information
;*         -   display time and date while waiting for keystrokes
;*         -   play notes of any frequency on the speaker
;*         -   change the line mode for EGA or VGA systems
;*         -   create nondestructive pop-up windows
;*         -   execute another program as a child process
;*         -   create primitive handlers for Interrupts 1Bh, 23h, and 24h
;*         -   use procedures callable by C in assembly programs
;*         -   use simplified segment directives
;*         -   write model-independent procedures
;*         -   declare and initialize data with DUP, BYTE, WORD, and DWORD
;*         -   create structures with the STRUCT directive
;*         -   declare macros
;*         -   set up a dispatch table
;*
;* MISCDEMO.EXE is built from the following files:
;*    MISCDEMO.ASM - Main program
;*    MISC.ASM     - Assembly procedures for MISCDEMO
;*    COMMON.ASM   - Assembly procedures shared by other example programs
;*    DEMO.INC     - Include file with macros, structure declarations
;*
;* Procedures:  GetVidConfig    GetCurPos       VeriPrint       GetPSP
;*              WinOpen         VeriAnsi        VeriCop         GetVer
;*              WinClose        StrWrite        SetLineMode     NewBlockSize
;*              SetCurSize      GetKeyClock     BinToHex        IntToAsc
;*              SetCurPos       GetShift        Sound           Colors
;*              GetCurSize      GetMem          Pause           Exec
;*              WriteTTY        Initialize

        .DOSSEG
        .MODEL  small, pascal, os_dos
        INCLUDE demo.inc

NewBreak        PROTO   FAR
NewCtrlC        PROTO   FAR
NewCritErr      PROTO   FAR
DispMenu        PROTO   NEAR
Press           PROTO   NEAR
GetVidinfo      PROTO   NEAR
GetMemInfo      PROTO   NEAR
CheckPrinter    PROTO   NEAR
CheckAnsi       PROTO   NEAR
CheckCoproc     PROTO   NEAR
GetConfig       PROTO   NEAR
Speaker         PROTO   NEAR
SetLines        PROTO   NEAR
PopWindows      PROTO   NEAR
SetAttrs        PROTO   NEAR
ExecPgm         PROTO   NEAR

        .STACK
        .DATA

PGMSIZE EQU     500h                    ; Maximum program size in paragraphs
F1      EQU     59                      ; Extended code for first option key
F7      EQU     65                      ; Extended code for last option key
CLKROW  EQU     0                       ; Row for on-screen clock
CLKCOL  EQU     62                      ; Column for on-screen clock

;* Box - Macro to color portion of screen for effect. Not to be confused with
;* the WinOpen procedure, which is far more capable.
;*
;* Params:  Row1 - Screen row at top of box
;*          Col1 - Screen column at left side of box
;*          Row2 - Screen row at bottom of box
;*          Col2 - Screen column at right side of box

Box MACRO Row1, Col1, Row2, Col2
    LOCAL sk
    mov ax, 0600h                       ;; Scroll service
    mov bh, Filmono                     ;; Fill attribute
    .IF vconfig.adapter != MDA          ;; If color,
    mov bh, Filcolr                     ;;   use color fill attribute
    .ENDIF
    mov ch, Row1
    mov cl, Col1                        ;; CX = row/col for upper left
    mov dh, Row2
    mov dl, Col2                        ;; DX = row/col for lower right
    int 10h                             ;; Blank window area on screen
ENDM

OldMode BYTE    ?                       ; Original video mode
OldCurs WORD    ?                       ; Original cursor coordinates
KeepSeg PSEG    ?                       ; Segment addr, orig screen
Filcolr BYTE    1Fh, 20h, 3Bh, 4Eh      ; Color fill attributes
Filmono BYTE    70h, 89h, 78h, 1        ; Monochrome fill attributes
Fill    BYTE    7                       ; Default attribute for menu
Filsub  BYTE    ?                       ; Fore/background colors in submenu

PresMsg BYTE    ". . . press a key to continue", 0
yes     BYTE    "yes"
no      BYTE    "no "

; Main menu text

Menu1   BYTE    "***  MISC Demonstration Program  ***", 0
Menu2   BYTE    "F1  System Configuration", 0
Menu3   BYTE    "F2  Speaker Test", 0
Menu4   BYTE    "F3  Toggle Line Mode", 0
Menu5   BYTE    "F4  Windows", 0
Menu6   BYTE    "F5  Screen Colors", 0
Menu7   BYTE    "F6  Exec Program", 0
Menu8   BYTE    "Select an option, or press ESC to quit:", 0

; Option F1 - System Configuration

MonoStr BYTE    "monochrome"
ClrStr  BYTE    "color     "
AdapStr BYTE    "MDA CGA MCGAEGA VGA "
VidMsg1 BYTE    "Adapter:                 xxxx", 0
VidMsg2 BYTE    "Display:                 xxxxxxxxxx", 0
VidMsg3 BYTE    "Mode:                    xx", 0
VidMsg4 BYTE    "Rows:                    xx", 0
MemMsg1 BYTE    "Total memory:            xxxx Kb", 0
MemMsg2 BYTE    "Available memory:        xxxx Kb", 0
PrnMsg  BYTE    "Printer ready:           xxx", 0
AnsiMsg BYTE    "ANSI driver installed:   xxx", 0
CopMsg  BYTE    "Coprocessor installed:   xxx", 0
LEN1    EQU     LENGTHOF CopMsg - 4

; Option F3 - Toggle Line Mode

LineMsg BYTE    "Line mode reset available only for EGA or VGA", 0

; Option F4 - Windows

WinMsg  BYTE    "WINDOW x", 0
LEN3    EQU     LENGTHOF WinMsg - 2

; Option F5  Screen Colors

CMsg1   BYTE    "Toggle                   Step", 0
CMsg2   BYTE    "컴컴컴컴컴컴컴컴         컴컴컴컴컴컴컴컴컴", 0
CMsg3   BYTE    "B  blink                 ", 27, 26, "  foreground", 0
CMsg4   BYTE    "I  intensity             ", 24, 25, "  background", 0
CMsg5   BYTE    "Foreground:  press F, then color number 0-7", 0
CMsg6   BYTE    "Background:  press A, then color number 0-7", 0
CMsg7   BYTE    "Color Numbers", 0
CMsg8   BYTE    "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�", 0
CMsg9   BYTE    "0  black                     4  red", 0
CMsg10  BYTE    "1  blue                      5  magenta", 0
CMsg11  BYTE    "2  green                     6  brown", 0
CMsg12  BYTE    "3  cyan                      7  white", 0
CMsg13  BYTE    "Toggle", 0
CMsg14  BYTE    "컴컴컴컴컴컴컴�", 0
CMsg15  BYTE    "B  blink", 0
CMsg16  BYTE    "I  intensity", 0
CMsg17  BYTE    "U  underline", 0
CMsg18  BYTE    "R  reverse", 0

; Option F6 - Exec Program

RetMsg  BYTE    "Return code:  "
Recode  BYTE    6 DUP (?)               ; ASCII string for return code
ExecMsg BYTE    "Enter program file spec (including .COM or .EXE):", 0
TailMsg BYTE    "Enter command-line argument(s):", 0
Fspec   BYTE    50, 50 DUP (?)          ; File specification (max length = 50)
Tail    BYTE    50, 50 DUP (?)          ; Command-line tail (max length = 50)
Fcblk1  BYTE    0                       ; Allocate space for 1st FCB
        BYTE    11 DUP (0)
        BYTE    25 DUP (0)
Fcblk2  BYTE    0                       ; Allocate space for 2nd FCB
        BYTE    11 DUP (0)
        BYTE    25 DUP (0)
pb      PARMBLK <>                      ; Parameter block structure

; Initialize dispatch table with offsets for internal procedures.

TPROC   TYPEDEF PROTO           ; Procedure type
PPROC   TYPEDEF PTR TPROC       ; Pointer to procedure with no arguments

; Table of procedures
DispTbl PPROC   GetConfig, Speaker, SetLines,
                PopWindows, SetAttrs, ExecPgm

        .CODE
        .STARTUP

        ; Initialize _psp and _env variables
        INVOKE  Initialize

        ; Return unused memory to DOS
        ; Pass PSP segment address and memory block allocated to program
        INVOKE  NewBlockSize, _psp, PGMSIZE

        ; Initialize global configuration data
        INVOKE  GetVidConfig

        mov     al, vconfig.rows
        mov     OldMode, al             ; Preserve original line mode

        ; Get current cursor position
        INVOKE  GetCurPos

        mov     OldCurs, ax             ; Store it

        ; Preserve original screen and put up window
        ; Pass top, left, bottom, right, and attribute
        INVOKE  WinOpen, 0, 0, vconfig.rows, 79, 07h

        mov     KeepSeg, ax             ; Keep segment address
        .IF     AX == 0                 ; If window not opened successfully,
        .EXIT   1                       ;   exit with return code = 1
        .ENDIF

        .WHILE 1

        ; Display main menu
        INVOKE  DispMenu

        ; Highlight on-screen clock with macro
        Box CLKROW, CLKCOL-1, CLKROW, CLKCOL + 17

        ; Poll for keyboard selection while updating time
        ; Pass row and column
        INVOKE  GetKeyClock, CLKROW, CLKCOL

        .BREAK .IF al == ESCAPE         ; Quit loop if ESC key

        .CONTINUE .IF (ah < F1) || (ah > F7) ; Ignore if not a function
                                             ;   key between F1 and F7?

        xchg    al, ah                  ; Yes?  Make AX = AH
        sub     al, F1                  ; Normalize to 0
        shl     al, 1                   ; Double to make word index
        mov     bx, ax                  ; BX = index to table

        ; Call the current procedure from call table
        INVOKE  DispTbl[bx]

        .ENDW                           ; Loop for another key

        mov     al, OldMode             ; Get original line mode
        .IF     al != vconfig.rows      ; If not same as current mode,

        inc     ax                      ;   increment to 25/43/50

        ; Restore line mode, pass lines
        INVOKE  SetLineMode, ax

        .ENDIF

        ; Restore original screen, pass segment of screen contents
        INVOKE  WinClose, KeepSeg

        mov     ax, OldCurs

        ; Restore cursor to original place
        ; Pass row and column
        INVOKE  SetCurPos, BYTE PTR OldCurs[1], BYTE PTR OldCurs[0]

        .EXIT   0                       ; Exit wih return code 0


;* DispMenu - Displays main menu.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Return:  None

DispMenu PROC NEAR

        mov     ax, 0600h               ; Scroll screen service
        mov     bh, Fill                ; Menu display attribute
        sub     cx, cx                  ; From row 0, col 0
        mov     dh, vconfig.rows        ;   to bottom row,
        mov     dl, 79                  ;   rightmost column
        int     10h                     ; Clear entire screen

        ; Display menu
        ; For each line pass row, column, and string address
        INVOKE StrWrite,  4, 21, ADDR Menu1
        INVOKE StrWrite,  8, 28, ADDR Menu2
        INVOKE StrWrite,  9, 28, ADDR Menu3
        INVOKE StrWrite, 10, 28, ADDR Menu4
        INVOKE StrWrite, 11, 28, ADDR Menu5
        INVOKE StrWrite, 12, 28, ADDR Menu6
        INVOKE StrWrite, 13, 28, ADDR Menu7
        INVOKE StrWrite, 17, 18, ADDR Menu8

        ; Park cursor at prompt, pass row and column
        INVOKE  SetCurPos, 17, 18 + (LENGTHOF Menu8) + 2

        ret

DispMenu ENDP



;* Press - Displays a prompt, then waits for a key press.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Return:  None

Press   PROC NEAR

        ; Write string, pass row, column, and string address
        INVOKE StrWrite, vconfig.rows, 50, ADDR PresMsg

        ; Park cursor at prompt, pass row and column
        INVOKE  SetCurPos, vconfig.rows, 48

        ; Poll for keyboard selection while updating time
        ; Pass row and column
        INVOKE  GetKeyClock, CLKROW, CLKCOL

        ret

Press   ENDP



;* GetVidinfo - Initializes video configuration message for display.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Return:  None

GetVidinfo PROC NEAR

        push    ds
        pop     es                      ; Point ES to data segment
        mov     al, 4                   ; Find index to 4-character
        mul     vconfig.adapter         ;   group in string
        add     ax, OFFSET AdapStr      ; Point AX to proper group
        mov     si, ax                  ; Put pointer in SI
        lea     di, VidMsg1[LEN1]       ; Point to 1st line of message
        mov     cx, 2                   ; Copy 4 letters (adapter
        rep     movsw                   ;   designation) to message

        mov     si, OFFSET MonoStr      ; Assume display is monochrome
        .IF     vconfig.display != MONO ; If color display,
        mov     si, OFFSET ClrStr       ;   point to "color" string
        .ENDIF
        lea     di, VidMsg2[LEN1]       ; Point to 2nd line of message
        mov     cx, 5                   ; Copy 10 chars ("monochrome"
        rep     movsw                   ;   or "color     ") to msg

        ; Note that IntToAsc can't be invoked because of its
        ; register calling convention
        mov     al, vconfig.mode
        cbw                             ; AX = video mode
        call    IntToAsc                ; Convert AX to ASCII
        xchg    ah, al                  ; Flip bytes for word write
        mov     WORD PTR VidMsg3[LEN1], ax  ; Insert in message string

        mov     al, vconfig.rows
        cbw
        inc     ax                      ; AX = number of screen rows
        call    IntToAsc                ; Convert to ASCII
        xchg    ah, al                  ; Flip bytes for word write
        mov     WORD PTR VidMsg4[LEN1], ax  ; Insert in message string
        ret

GetVidinfo ENDP



;* GetMemInfo - Initializes memory information message.
;*
;* Return:  None

GetMemInfo PROC NEAR

        ; Get total memory in DX, available memory in AX
        INVOKE  GetMem

        push    ax
        mov     ax, dx
        call    IntToAsc                ; Convert AX to ASCII
        xchg    dh, dl                  ; Flip bytes for word write
        xchg    ah, al
        mov     WORD PTR MemMsg1[LEN1], dx      ; Insert in message
        mov     WORD PTR MemMsg1[LEN1+2], ax    ;   string
        pop     ax                              ; Recover avail memory #
        call    IntToAsc                        ; Convert to ASCII
        xchg    dh, dl                          ; Flip bytes for word write
        xchg    ah, al
        mov     WORD PTR MemMsg2[LEN1], dx      ; Insert in message
        mov     WORD PTR MemMsg2[LEN1+2], ax    ;   string
        ret

GetMemInfo ENDP


;* CheckPrinter - Initializes printer status message.
;*
;* Shows:   Instruction - movsb
;*
;* Return:  None

CheckPrinter PROC NEAR

        push    ds
        pop     es                      ; Point ES to data segment
        mov     si, OFFSET yes          ; Assume answer is "yes"

        ; Check if printer ready
        INVOKE  VeriPrint

        .IF     al == 0                 ; If not ready,
        mov     si, OFFSET no           ;   point to "no" answer
        .ENDIF
        lea     di, PrnMsg[LEN1]        ; Point to print message
        mov     cx, 3                   ; Copy 3 letters (either "yes"
        rep     movsb                   ;   or "no ") to message
        ret

CheckPrinter ENDP



;* CheckAnsi - Initializes status message for ANSI driver.
;*
;* Return:  None

CheckAnsi PROC NEAR

        push    ds
        pop     es                      ; Point ES to data segment
        mov     si, OFFSET yes          ; Assume answer is "yes"

        ; Check if ANSI driver is installed
        INVOKE  VeriAnsi

        .IF     al == 0                 ; If not installed,
        mov     si, OFFSET no           ;   point to "no" answer
        .ENDIF
        lea     di, AnsiMsg[LEN1]       ; Point to ansi message
        mov     cx, 3                   ; Copy 3 letters (either "yes"
        rep     movsb                   ;   or "no ") to message
        ret

CheckAnsi ENDP



;* CheckCoproc - Initializes coprocessor status message.
;*
;* Return:  None

CheckCoproc PROC NEAR

        push    ds
        pop     es                      ; Point ES to data segment
        mov     si, OFFSET yes          ; Assume answer is "yes"

        ; Check for coprocessor
        INVOKE  VeriCop

        .IF     al == 0                 ; If not installed:
        mov     si, OFFSET no           ; Point to "no" answer
        .ENDIF
        lea     di, CopMsg[LEN1]        ; Point to coprocessor message
        mov     cx, 3                   ; Copy 3 letters (either "yes"
        rep     movsb                   ;   or "no ") to message
        ret

CheckCoproc ENDP


;* GetConfig - Displays system configuration information.

GetConfig PROC NEAR

        INVOKE  GetVidinfo              ; Initialize video message
        INVOKE  GetMemInfo              ; Initialize memory message
        INVOKE  CheckPrinter            ; Initialize printer message
        INVOKE  CheckAnsi               ; Initialize ANSI driver msg
        INVOKE  CheckCoproc             ; Initialize coprocessor msg

        Box 4, 13, 20, 67               ; Clear screen with box

        ; Display configuration information
        ; For each line, pass row, column, and string address
        INVOKE  StrWrite,  6, 23, ADDR VidMsg1
        INVOKE  StrWrite,  7, 23, ADDR VidMsg2
        INVOKE  StrWrite,  8, 23, ADDR VidMsg3
        INVOKE  StrWrite,  9, 23, ADDR VidMsg4
        INVOKE  StrWrite, 11, 23, ADDR MemMsg1
        INVOKE  StrWrite, 12, 23, ADDR MemMsg2
        INVOKE  StrWrite, 14, 23, ADDR PrnMsg
        INVOKE  StrWrite, 16, 23, ADDR AnsiMsg
        INVOKE  StrWrite, 18, 23, ADDR CopMsg

        ; Prompt for keypress
        INVOKE  Press

        ret

GetConfig ENDP



;* Speaker - Sounds speaker with ascending frequencies.
;*
;* Return:  None

Speaker PROC NEAR

        sub     ax, ax
        .REPEAT
        add     ax, 100                 ; Start with frequency 100
        push    ax                      ; Save frequency

        ; Beep speaker, pass frequency and duration
        INVOKE  Sound, ax, 1

        pop     ax                      ; Recover frequency
        .UNTIL  ax > 3000               ; Continue to frequency 3000
        ret

Speaker ENDP



;* SetLines - Toggles between 25/43-line mode for EGA or 25/43/50-line mode
;* for VGA.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Return:  None

SetLines PROC NEAR

        mov     al, 25                  ; Assume toggle to 25 line
        cmp     vconfig.rows, 49        ; Current mode 50 lines?
        je      toggle25                ; Yes?  Toggle VGA to 25-line
        cmp     vconfig.rows, 42        ; Current mode 43 lines?
        jne     toggle43                ; No?  Must be 25
        cmp     vconfig.adapter, EGA    ; Yes?  And is adapter EGA?
        je      toggle25                ; Yes?  Then toggle to 25 line
        mov     al, 50                  ; No?  Toggle VGA to 50 line
        jmp     toggle25
toggle43:
        mov     al, 43                  ; If currently 25 lines, make
                                        ;   either EGA or VGA 43 lines
toggle25:
        ; Change line mode, pass lines
        INVOKE  SetLineMode, ax

        .IF     al == 0                 ; If no error,
        INVOKE  GetVidConfig            ;   update configuration structure
        .ELSE                           ; Else,
        Box 16, 13, 20, 67              ;   display error message

        ; Write line message, pass row, column, and string address
        INVOKE  StrWrite, 18, 17, ADDR LineMsg

        INVOKE  Press
        .ENDIF

        ret

SetLines ENDP



;* PopWindows - Demonstrates windowing with the WinOpen and WinClose
;* procedures.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Return:  None

PopWindows PROC NEAR

        LOCAL Row1:WORD, Col1:WORD, Row2:WORD, Col2:WORD
        LOCAL Index:BYTE, Adr[4]:WORD, Csize:WORD

        ; Get current cursor size
        INVOKE  GetCurSize

        mov     Csize, ax               ; Store it
        or      al, 100000y             ; Set 5th bit for cursor off
        mov     bl, al

        ; Set cursor size
        ; Pass arbitrary top and bottom lines with visibility bit off
        INVOKE  SetCurSize, BYTE PTR Csize[1], bl

        mov     WinMsg[LEN3], "0"       ; Initialize window message
        mov     Row1, 4                 ; Initialize window coords
        mov     Col1, 10
        mov     Row2, 20
        mov     Col2, 34
        mov     Index, 0
        mov     cx, 4                   ; Open 4 windows
        .REPEAT
        push    cx                      ; Save loop counter
        mov     al, Index
        mov     bx, OFFSET Filmono      ; BX points to fill attributes
        .IF     vconfig.display != MONO ; If not monochrome,
        mov     bx, OFFSET Filcolr      ;   repoint to color attributes
        .ENDIF
        xlat                            ; Get attributes in succession

        ; Save old window and open new
        ; Pass top, left, bottom, right, and attribute in AX
        INVOKE  WinOpen, Row1, Col1, Row2, Col2, ax

        pop     di                      ; Recover counter in DI
        push    di                      ;   and save it again
        dec     di
        shl     di, 1                   ; Make DI a word index
        mov     Adr[di], ax             ; Save address of allocated
                                        ;   block returned by WinOpen
        inc     WinMsg[LEN3]            ; Increment window number
        mov     bx, Row1
        add     bl, 2                   ; Message row
        mov     cx, Col1
        add     cl, 9                   ; Message column

        ; Write window message, pass row, column, and string address
        INVOKE StrWrite, bx, cx, ADDR WinMsg

        ; Pause, pass 18 ticks (about 1 second)
        INVOKE  Pause, 18

        add     Row1, 2                 ; Adjust coordinates for
        add     Col1, 13                ;   next window
        sub     Row2, 2
        add     Col2, 13
        inc     Index
        pop     cx                      ; Recover counter
        .UNTILCXZ

        mov     cx, 4                   ; Close 4 windows
        sub     di, di                  ; DI = index to addresses

        .REPEAT
        push    cx                      ; Save loop counter

        ; Close a window, pass address of the window
        INVOKE  WinClose, Adr[di]

        ; Pause, pass 18 ticks (about 1 second)
        INVOKE  Pause, 18

        add     di, 2                   ; Point to next address
        pop     cx                      ; Recover counter
        .UNTILCXZ                       ; Close another window

        mov     ax, Csize               ; Get original cursor size

        ; Set cursor size, pass top and bottom lines
        INVOKE  SetCurSize, BYTE PTR Csize[1], BYTE PTR Csize[0]

        ret

PopWindows ENDP



;* SetAttrs - Changes display attributes for the main menu.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Return:  None

SetAttrs PROC NEAR

        Box 3, 12, 23, 68
        .IF     vconfig.adapter == MDA  ; If monochrome?

        ; Write monochrome menu
        ; For each line, pass row, column, and string address
        INVOKE StrWrite,  8, 32, ADDR CMsg13
        INVOKE StrWrite,  9, 32, ADDR CMsg14
        INVOKE StrWrite, 10, 36, ADDR CMsg15
        INVOKE StrWrite, 11, 36, ADDR CMsg16
        INVOKE StrWrite, 12, 36, ADDR CMsg17
        INVOKE StrWrite, 13, 36, ADDR CMsg18

        mov     al, Filmono             ; Initialize Filsub variable
        mov     Filsub, al              ;   for monochrome

        .ELSE

        ; Write color menu
        ; For each line, pass row, column, and string address
        INVOKE StrWrite,  4, 18, ADDR CMsg1
        INVOKE StrWrite,  5, 18, ADDR CMsg2
        INVOKE StrWrite,  6, 22, ADDR CMsg3
        INVOKE StrWrite,  7, 22, ADDR CMsg4
        INVOKE StrWrite, 10, 18, ADDR CMsg5
        INVOKE StrWrite, 11, 18, ADDR CMsg6
        INVOKE StrWrite, 14, 18, ADDR CMsg7
        INVOKE StrWrite, 15, 18, ADDR CMsg8
        INVOKE StrWrite, 16, 22, ADDR CMsg9
        INVOKE StrWrite, 17, 22, ADDR CMsg10
        INVOKE StrWrite, 18, 22, ADDR CMsg11
        INVOKE StrWrite, 19, 22, ADDR CMsg12

        mov     al, Filcolr             ; Initialize Filsub variable
        mov     Filsub, al              ;   for color
        .ENDIF

        ; Write menu message
        INVOKE StrWrite, 22, 15, ADDR Menu8

        ; Park cursor at prompt, pass row and column
        INVOKE  SetCurPos, 22, 56

        .WHILE   1

        ; Poll for keyboard selection while updating time
        ; Pass row and column
        INVOKE  GetKeyClock, CLKROW, CLKCOL

        .BREAK .IF al == ESCAPE         ; Quit if ESC key

        .IF (al >= 'a') && (al <= 'z')  ; Convert letters to uppercase
        and     al, 5Fh                 ;   to make comparisons easier
        .ENDIF

        cmp     al, 'B'                 ; Request blink toggle?
        je      blink
        cmp     al, 'I'                 ; Request intensity toggle?
        je      intense
        mov     bl, Filsub              ; Get window display attribute
        cmp     vconfig.adapter, MDA    ; Monochrome?
        jne     iscolor                 ; No?  Jump to color selections
        cmp     al, 'U'                 ; Request underline toggle?
        je      underline
        .CONTINUE .IF al != 'R'         ; If not reverse toggle,
                                        ;   skip invalid key

; With cross-toggling between reverse, normal, and underline, three
; bit settings can exist in monochrome:  x111x000 for reverse, x000x111 for
; normal, and x000x001 for underline. Changing between the three involves
; more than simply using XOR to determine the current attribute; each
; condition must check for the other two.

reverse:
        .IF     bl & 1                  ; If reverse video off,
        or      bl, 00000111y           ;   ensure normal bits are on
        .ENDIF

        xor     bl, 01110111y           ; Toggle for reverse/normal
        mov     cl, 6                   ; Set code for MOV
        jmp     switch

underline:
        .IF     bl & 1                  ; If reverse video on,
        and     bl, 10001111y           ;   clear bits 4-6
        or      bl, 00000111y           ;   and set bits 0-2
        .ENDIF

        xor     bl, 00000110y           ; Toggle bits 1-2 for underline
        mov     cl, 6                   ; Set code for MOV
        jmp     switch

; Blink and intensity use the same bits for color and monochrome.

blink:
        mov     bl, 10000000y           ; Set bit 7 for blink
        mov     cl, 4                   ; Set code for XOR
        jmp     switch

intense:
        mov     bl, 00001000y           ; Set bit 3 for intensity
        mov     cl, 4                   ; Set code for XOR
        jmp     switch

; Enter this section only for color displays. First check for arrow keys,
; which increment or decrement the foreground or background bits of the
; current attribute stored in the variable Filsub. If arrow keys are not
; pressed, check for the F or A keys, which request specific colors for the
; foreground or background colors.

iscolor:
        mov     ch, bl                  ; Copy current attribute to CH
        .IF     ah == 72                ; If up arrow,
        mov     cl, 4                   ;   increment bits 4-6
        shr     ch, cl                  ;   to next background color
        inc     ch
        and     ch, 00000111y
        shl     ch, cl
        mov     dl, 10001111y           ; Set background mask
        jmp     step
        .ENDIF

        .IF     ah == 75                ; If left arrow,
        inc     ch                      ;   increment bits 0-2
        and     ch, 00000111y           ;   to next foreground color
        mov     dl, 11111000y           ; Set foreground mask
        jmp     step
        .ENDIF

        .IF     ah == 77                ; If right arrow,
        dec     ch                      ;   decrement bits 0-2
        and     ch, 00000111y           ;   to previous foreground color
        mov     dl, 11111000y           ; Set foreground mask
        jmp     step
        .ENDIF

        .IF     ah == 80                ; If down arrow,
        mov     cl, 4                   ;   decrement bits 4-6
        shr     ch, cl                  ;   to previous background color
        dec     ch
        and     ch, 00000111y
        shl     ch, cl
        mov     dl, 10001111y           ; Set background mask
step:
        and     bl, dl                  ; Mask out fore or back bits
        or      bl, ch                  ; Copy into original attribute
        mov     Filsub, bl              ; Store the new submenu color
        mov     cl, 6                   ; Request move operation in
        jmp     switch                  ;   Colors procedure
        .ENDIF

; This section checks for the F or A keys; if found it checks again for
; a number key between 0 and 7, then inserts the correct foreground or
; background bit pattern into the current fill attribute.

        sub     cx, cx                  ; Clear flag for foreground request
        .IF     al == 'A'               ; If background request,
        inc     cx                      ;   set flag for background request
        .ELSE
        .CONTINUE .IF al != 'F'         ; If not foreground request, continue
        .ENDIF

        push    cx

        ; Poll for keyboard selection while updating time
        ; Pass row and column
        INVOKE  GetKeyClock, CLKROW, CLKCOL

        pop     cx                      ; Recover flag

        .CONTINUE .IF (al < '0') || (al > '7') ; Ignore invalid key

        xor     al, '0'                 ; Convert ASCII numeral into binary
        mov     dl, 11111000y           ; Set foreground mask
        .IF     cx != 0                 ; Skip if foreground request
        mov     cl, 4                   ; Otherwise shift bits 0-2
        shl     al, cl                  ;   to positions 4-6
        mov     dl, 10001111y           ; Set background mask
        .ENDIF

        mov     bl, Filsub
        and     bl, dl                  ; Mask out fore or back bits
        or      bl, al                  ; Insert number into fore or back bits
        mov     Filsub, bl              ; Store the new submenu color
        mov     cl, 6                   ; Request move
switch:

        ; Set new attributes in a window
        ; Pass logic code (CX), attribute (BX), top, left, bottom, right
        INVOKE  Colors, cx, bx, 3, 12, 23, 68

        mov     ah, 8                   ; Function 8, get char/attribute
        mov     bh, vconfig.dpage
        int     10h                     ; Get attribute in AH
        mov     Fill, ah                ; New fill variable for main menu
        mov     Filsub, ah              ;   and for submenu
        .ENDW
        ret

SetAttrs ENDP



;* ExecPgm - Executes a specified program as a child process.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*          pb - Parameter block structure, declared in the DEMO.INC file
;*
;* Return:  None

ExecPgm PROC NEAR

        Box 16, 13, 20, 67

        ; Display prompt for file spec, pass row, column, and string address
        INVOKE StrWrite, 17, 16, ADDR ExecMsg

        ; Set cursor position below prompt, pass row and column
        INVOKE  SetCurPos, 19, 16

        mov     ah, 0Ah                 ; Request DOS to read keyboard
        mov     dx, OFFSET Fspec        ;   input into Fspec string
        int     21h                     ; Read Buffered Keyboard Input

        Box 16, 13, 20, 67

        ; Display prompt for command tail
        INVOKE StrWrite, 17, 16, ADDR TailMsg

        ; Set cursor position below prompt, pass row and column
        INVOKE  SetCurPos, 19, 16

        mov     ah, 0Ah                 ; Request DOS to read keyboard
        mov     dx, OFFSET Tail         ;   input into tail string
        int     21h                     ; Read Buffered Keyboard Input

        sub     bh, bh                  ; Clear BH
        mov     si, OFFSET Fspec        ; DS:SI points to file spec string
        mov     bl, [si+1]              ; BL = number of chars in spec
        mov     BYTE PTR [si+bx+2], 0   ; Terminate string with 0

        mov     ax, _env                ; Get segment address of environment
        mov     pb.env, ax              ; Copy it to parameter block
        mov     ax, @data               ; AX points to data segment
        lea     bx, Tail[1]             ; BX points to command-line tail
        mov     WORD PTR pb.taddr[0], bx; Copy address of command-line tail
        mov     WORD PTR pb.taddr[2], ax;   to parameter block

        mov     bx, OFFSET Fcblk1       ; BX points to first FCB
        mov     WORD PTR pb.fcb1[0], bx ; Copy address of first FCB
        mov     WORD PTR pb.fcb1[2], ax ;   to parameter block
        mov     bx, OFFSET Fcblk2       ; BX points to second FCB
        mov     WORD PTR pb.fcb2[0], bx ; Copy address of second FCB
        mov     WORD PTR pb.fcb2[2], ax ;   to parameter block

; At this point, the program file is specified, the command-line tail is set,
; and the parameter block is properly initialized. The Exec procedure will
; take care of loading the FCBs with command-line arguments and resetting
; interrupt vectors. Now blank the screen in preparation for executing the
; process and pass the five pointers to the Exec procedure.

        mov     ax, 0600h               ; AH = scroll service, AL = 0
        mov     bh, 7                   ; Blank with normal attribute
        sub     cx, cx                  ; From row 0, col 0
        mov     dh, vconfig.rows        ;   to bottom row
        mov     dl, 79                  ;   and rightmost column
        int     10h                     ; Blank screen

        ; Set cursor at top of screen, pass row and column
        INVOKE  SetCurPos, 0, 0


        ; Exec specified program
        INVOKE  Exec,
                ADDR Fspec[2],          ; File spec
                ADDR pb,                ; Parameter block structure
                NewBreak,               ; New handlers for CTRL+BREAK,
                NewCtrlC,               ;   CTRL+C,
                NewCritErr              ;   and Critical Error


        .IF     ax != -1                ; If successful:

        ; Convert return code to string
        ; Pass return code (AX) and address of string buffer
        INVOKE  BinToHex, ax, ADDR Recode

        ; Update video structure
        INVOKE  GetVidConfig

        Box CLKROW, CLKCOL-1, CLKROW, CLKCOL+17 ; Highlight on-screen clock
        Box vconfig.rows, 0, vconfig.rows, 79   ; Highlight bottom row
        mov     dl, vconfig.rows

        ; Display return code at bottom
        INVOKE StrWrite, dx, 0, ADDR RetMsg

        ; Wait for keypress
        INVOKE  Press
        .ELSE
        mov     ax, 0E07h               ; Write ASCII 7 character
        int     10h                     ;   (bell) to console
        .ENDIF

        ret

ExecPgm ENDP



;* The following three procedures are primitive handlers for Interrupt 1Bh
;* (CTRL+BREAK), Interrupt 23h (CTRL+C), and Interrupt 24h (Critical Error).
;* The purpose of an interrupt handler in this context is to prevent termina-
;* tion of both parent and child processes when the interrupt is invoked.
;* Such handlers often set flags to signal to a process that the interrupt
;* has been called.

;* NewBreak - Handler for Interrupt 1Bh.

NewBreak PROC   FAR

        sti                             ; Reenable interrupts
        push    ax                      ; Preserve AX register
        mov     al, 20h                 ; Send end-of-interrupt signal
        out     20h, al                 ;   to interrupt controller
        pop     ax                      ; Recover AX register
        iret                            ; Return from handler
                                        ;   without taking action
NewBreak ENDP


;* NewCtrlC - Handler for Interrupt 23h.

NewCtrlC PROC   FAR

        iret                            ; Return from handler
                                        ;   without taking action
NewCtrlC ENDP


;* NewCritErr - Handler for Interrupt 24h.

NewCritErr PROC FAR

        sub     al, al                  ; Tell DOS to ignore error
        iret                            ; Return from handler
                                        ;   without taking action
NewCritErr ENDP

        END
