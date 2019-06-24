;* SHOW.ASM - Text file displayer for DOS.

        TITLE   Show
        .MODEL  small, pascal   ; This code also works in tiny model
        .DOSSEG

        INCLUDE show.inc
        INCLUDE dos.inc
        INCLUDE bios.inc

        .STACK

        .DATA

; Status line

stLine  BYTE    "Line: 12345 "
stFile  BYTE    "File: 12345678.123  "
        BYTE    "Quit: Q  Next: ESC  Move:   PGUP PGDN HOME END"

; Variables for	screen handling

yCur    WORD    1
yMax    WORD    24              ; Number of rows - status line takes one more
iMode   BYTE    0               ; Initial mode
iPage   BYTE    0               ; Initial display page
atInit  BYTE    0               ; Initial attribute
shCsr   WORD    0               ; Initial cursor shape
bCsrSta BYTE    0               ; 0 = cursor visible, position unchanged
                                ; 1 = cursor invisible, position unchanged
                                ; 2 = cursor invisible, position changed

fNewVid BYTE    0               ; Video change flag
fCGA    BYTE    1               ; CGA flag - default yes

segVid  WORD    SEG_CLR         ; Video buffer address - default color

atSta   BYTE    STAT_CLR        ; Status line color
celScr  LABEL   WORD            ; Cell (character and attribute)
chScr   BYTE    ' '             ; Initialize to space
atScr   BYTE    SCRN_CLR        ; Screen color

; Buffer variables

fpBuf   LABEL   FAR PTR
offBuf  WORD    0               ; Position in buffer (offset)
segBuf  WORD    0               ; Base of buffer (segment)
cbBuf   WORD    0               ; Length of buffer

; File information

hFileIn WORD    0               ; Holds file handle on open

; Buffer for file spec and structure for file info

achBuf  BYTE    NAME_MAX, ?     ; Buffer format for string input
stFiles BYTE    NAME_MAX DUP (0); File spec string
fiFiles FILEINFO <>             ; Wild card entry structure
cFiles  WORD    0               ; Count of 1 or 0 files remaining

; Messages

stMsg1  BYTE    13, 10, 13, 10, "Enter filename: $"
stMsg2  BYTE    13, 10, "File problem. Try again? $"
stMsg3  BYTE    13, 10, "File too large: $"
stMsg4  BYTE    13, 10, "Memory problem.", 13, 10, "$"
stMsg5  BYTE    13, 10, "Must have DOS 2.0 or higher", 13, 10, "$"

; Call table

achKeys BYTE    71, 72, 73, 79, 80, 81, 'q', 'Q'; Key table
afnKeys WORD    HomeKey                         ; Corresponding procedures
        WORD    UpKey
        WORD    PgUpKey
        WORD    EndKey
        WORD    DownKey
        WORD    PgDnKey
        WORD    Quit
        WORD    Quit
        WORD    UnknownKey

        .CODE
        .STARTUP

; Adjust memory allocation (works for tiny or small model)

        mov     bx, sp                  ; Convert stack pointer to paragraphs
        mov     cl, 4                   ;   to get stack size
        shr     bx, cl
        mov     ax, ss                  ; Add SS to get end of program
        add     ax, bx
        mov     bx, es                  ; Get start of program
        sub     ax, bx                  ; Subtract start from end
        inc     ax
        @ModBlock ax                    ; Release memory after program

; Check DOS

        @GetVer                         ; Get DOS version
        .IF     al < 2                  ; Requires DOS 2.0
        @ShowStr stMsg5                 ;   else error and quit
        int     20h
        .ENDIF

; Get command line and copy to filename buffer

        mov     di, 80h                 ; PSP offset of command line
        mov     bl, es:[di]             ; Get length from first byte
        sub     bh, bh
        or      bx, bx
        je      Prompter

        mov     WORD PTR es:[bx+81h], 0 ; Convert to ASCIIZ
        mov     al, ' '                 ; Character to check for
        inc     di                      ; Advance beyond count
        mov     cx, 0FFFFh              ; Don't let count interfere
        repe    scasb                   ; Find first nonspace
        dec     di                      ; Adjust

        mov     si, di                  ; Filename source
        mov     di, OFFSET stFiles      ; Name buffer destination
        mov     bx, ds                  ; Save segment registers
        mov     dx, es
        mov     ds, dx                  ; DS = ES
        mov     es, bx                  ; ES = DS
        mov     cx, NAME_MAX            ; Count = max filename allowed

        .REPEAT
        lodsb                           ; Copy characters
        .BREAK .IF (al == ' ') || (al == 0) ; Stop at space or null
        stosb
        .UNTILCXZ                       ; Until name exceeds max

        mov     ds, bx                  ; Restore segments
        mov     es, dx
        mov     BYTE PTR [di], 0
        jmp     FindFile
NoFile:

        @ShowStr stMsg2                 ; Prompt to try again
        @GetChar 0, 1, 0
        and     al, 11011111y           ; Convert key to upper case
        .IF     al != 'Y'               ; If not yes,
        jmp     quit                    ;   quit
        .ENDIF

; Prompt for file

Prompter:
        @ShowStr stMsg1                 ; Prompt for file
        @GetStr achBuf, 0               ; Get response as ASCIIZ

; Find first (or only) file in file spec

FindFile:

        @SetDTA <OFFSET fiFiles>        ; Set DTA to file info structure
                                        ; Don't need DTA for anything else,
                                        ;   so no need to restore it
        @GetFirst stFiles,0             ; Find a matching file

        jc      NoFile                  ; If not found, prompt for new
        inc     cFiles                  ; Some files remaining

        INVOKE  GetVid

; Main program loop to process files

        .REPEAT

; Copy filename to file spec

        mov     bCsrSta, 2              ; Cursor hidden, position unchanged
        INVOKE  GetNamePos,             ; Get filename position in file spec
                ADDR stFiles

        mov     si, OFFSET fiFiles.fiFileName   ; Point to source name
        push    ds                      ; ES = DS
        pop     es
        mov     di, ax                  ; Load address from return value

        .REPEAT                         ; Copy to (and including) null
        movsb
        .UNTIL BYTE PTR [si-1] == 0

; Copy filename to status line

        mov     si, OFFSET fiFiles.fiFileName   ; Point to source name
        mov     di, OFFSET stFile[FILE_POS]     ; Point to status line

        sub     cx, cx                  ; Count characters
        .REPEAT
        lodsb                           ; Copy to (but excluding) null
        .BREAK .IF al == 0
        stosb
        inc     cx
        .UNTIL  0

        mov     bx, 12                  ; Calculate blank spaces to fill
        sub     bx, cx
        mov     al, ' '                 ; Fill rest of name space with blanks
        mov     cx, bx
        rep     stosb

; Skip any file that is larger than 64K

        .IF     WORD PTR fiFiles.fiSize[2] != 0 ; Error if high word isn't 0
        mov     bCsrSta, 1              ; Cursor hidden, position unchanged

        @ShowStr stMsg3                 ; Display error string and filename
        @Write   fiFiles.fiFileName, cx, 1

        .IF     cFiles                  ; If files remaining,
        @GetChar 0                      ;   get a key
        .ENDIF
        .ENDIF

; Allocate dynamic memory for file buffer

        mov     ax, WORD PTR fiFiles.fiSize[0]  ; Get length
        mov     cbBuf, ax               ; Save
        mov     offBuf, 0
        mov     cl, 4                   ; Convert to paragraphs
        shr     ax, cl
        inc     ax                      ; Zero adjust

        @GetBlock ax                    ; Try to allocate 64K
        .IF     carry?                  ; Display error and quit if
        @ShowStr stMsg4                 ;   request failed
        jmp     Quit
        .ENDIF
        mov     segBuf, ax              ; Save buffer segment

; Open file and read contents into buffer

        @OpenFile stFiles, 0            ; Try to open
        jc      NoFile                  ; If fail, get a new file
        mov     hFileIn, ax             ; Save handle

        push    ds
        @Read   fpBuf, cbBuf, hFileIn   ; Read file
        pop     ds
        .IF     carry?
        jmp     NoFile                  ; If read error try again
        .ENDIF

; Search back for EOF marker and adjust	if necessary

        mov     di, cbBuf               ; Load file length
        dec     di                      ;   and adjust
        mov     es, segBuf
        std                             ; Look backward for 255 characters
        mov     cx, 0FFh
        .IF     cx >= di
        mov     cx, di
        .ENDIF

        mov     al, 1Ah                 ; Search for EOF marker
        repne   scasb
        cld
        .IF     cx != 0                 ; If found,
        inc     di                      ;   adjust and save file size
        mov     cbBuf, di
        .ENDIF

; Show a screen of text and allow commands

        INVOKE  Show

        @CloseFile hFileIn              ; Yes? Close file
        @FreeBlock segBuf               ; Release buffer

        @GetNext

        .IF     carry?
        dec     cFiles
        .ENDIF
        .UNTIL  !cFiles

; Fall through to Quit

Quit    PROC

        cmp     bCsrSta, 1              ; Check cursor status
        jg      csrvislast              ; 2 - Make cursor visible on last line
        je      csrvis                  ; 1 - Make cursor visible
        jmp     csrasis                 ; 0 - Leave cursor as is

csrvislast:
        mov     dx, yMax                ; Load last row and first column
        xchg    dl, dh
        mov     cx, dx                  ; Make row the same
        mov     dl, 79
        @Scroll 0, atInit               ; Clear last line to original color
        sub     dl, dl                  ; Column 0
        @SetCsrPos                      ; Set cursor
csrvis:                                 ; Fall through
                                        ; Restore cursor attribute
        @SetCsrSize <BYTE PTR shCsr[1]>, <BYTE PTR shCsr[0]>

csrasis:
        .IF     fNewVid == 1
        @SetMode iMode                  ; Restore video mode, page, and cursor
        @SetPage iPage
        .ENDIF

        .EXIT   0                       ; Quit

Quit    ENDP


Show    PROC

; Display first page

        mov     yCur, 1                 ; Reinitialize
        INVOKE  Pager,                  ; Start at 0
                0

; Handle keys

        .REPEAT

        @GetChar 0, 0, 0                ; Get a key

        .BREAK .IF al == 27             ; If ESC get out for next file

        ; If null or E0 (for extended keyboard), it's an extended key
        .IF     (al == 0) || (al == 0E0h)
        @GetChar 0, 0, 0                ; Get extended code
        .ENDIF

        push    ds                      ; ES = DS
        pop     es
        mov     di, OFFSET achKeys      ; Load address and length of key list
        mov     cx, LENGTHOF achKeys + 1
        repne   scasb                   ; Find position and point to key
        sub     di, OFFSET achKeys + 1
        shl     di, 1                   ; Adjust pointer for word addresses
        call    afnKeys[di]             ; Call procedure
        .UNTIL  0

        ret
Show    ENDP

HomeKey:
        mov     offBuf, 0               ; HOME - set position to 0
        mov     yCur, 1
        INVOKE  Pager, offBuf
        retn

UpKey:
        INVOKE  Pager, -1               ; UP - scroll backward 1 line
        retn

PgUpKey:
        mov     ax, yMax                ; PGUP - Page back
        neg     ax
        INVOKE  Pager, ax
        retn

EndKey:
        mov     ax, cbBuf               ; END - Get last byte of file
        dec     ax                      ; Zero adjust
        mov     offBuf, ax              ; Make it the file position
        mov     yCur, -1                ; Set illegal line number as flag
        mov     ax, yMax                ; Page back
        neg     ax
        INVOKE  Pager, ax
        retn

DownKey:
        INVOKE  Pager, 1                ; DOWN - scroll forward 1 line
        retn

PgDnKey:
        INVOKE  Pager, yMax             ; PGDN - page forward
        retn

UnknownKey:
        retn                            ; Ignore unknown key


;* GetVid - Gets the video mode and sets related global variables.
;*
;* Params: None
;*
;* Return: Number of lines in current mode (25, 43, or 50)

GetVid  PROC

; Adjust for current mode and and video adapter

        INVOKE  IsEGA                   ; EGA (or VGA)?
        .IF     ax != 0                 ; If 0 must be CGA or MA
        mov     yMax, ax                ; Load rows
        dec     fCGA                    ; Not CGA
        .ENDIF

        @GetMode                        ; Get video mode
        mov     iMode, al               ; Save initial mode and page
        mov     iPage, bh
        mov     dl, al                  ; Work on copy
        cmp     dl, 7                   ; Is it mono 7?
        je      loadmono                ; Yes? Set mono
        cmp     dl, 15                  ; Is it mono 15?
        jne     graphchk                ; No? Check graphics
loadmono:
        mov     segVid, SEG_MONO        ; Load mono address
        mov     atSta, STAT_BW          ; Set B&W defaults for status line
        mov     atScr, SCRN_BW          ;   and screen background
        dec     fCGA                    ; Not CGA
        cmp     al, 15                  ; Is it mono 15?
        jne     exit                    ; No? Done
        mov     dl, 7                   ; Yes? Set standard mono
        jmp     chmode
graphchk:
        cmp     dl, 7                   ; 7 or higher?
        jg      color                   ; 8 to 14 are color (7 and 15 done)
        cmp     dl, 4                   ; 4 or higher?
        jg      bnw                     ; 5 and 6 are probably black and white
        je      color                   ; 4 is color
        test    dl, 1                   ; Even?
        jz      bnw                     ; 0 and 2 are black and white
color:                                  ; 1 and 3 are color
        cmp     dl, 3                   ; 3?
        je      exit                    ; Yes? Done
        mov     dl, 3                   ; Change mode to 3
        jmp     chmode
bnw:
        mov     atSta, STAT_BW          ; Set B&W defaults for status line
        mov     atScr, SCRN_BW          ;   and screen background
        cmp     dl, 2                   ; 2?
        je      exit                    ; Yes? Done
        mov     dl, 2                   ; Make it 2
chmode:
        @SetMode dl                     ; Set video mode
        @SetPage 0                      ; Set video page
        mov     fNewVid, 1              ; Set flag
exit:
        @GetCsr                         ; Get cursor shape (ignore position)
        mov     shCsr, cx               ; Save shape
        @GetCharAtr                     ; Read the cell at the cursor
        mov     atInit, ah              ; Save attribute
        @SetCsrSize 20h, 20h            ; Turn off cursor (invisible shape)

        ret

GetVid  ENDP


        END
