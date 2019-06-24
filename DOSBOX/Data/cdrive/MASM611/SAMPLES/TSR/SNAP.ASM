        .MODEL  small, pascal
        .DOSSEG
        INCLUDE ..\demos\demo.inc
        INCLUDE tsr.inc

        .STACK
        .DATA

DEFAULT_COLR    EQU     1Eh             ; Default = white on blue (color)
DEFAULT_MONO    EQU     70h             ; Default = reverse video (mono)

; Set ALT+LEFT SHIFT+S as hot key combination. To set multiple shift
; keys, OR the appropriate values together for the shift value (HOT_SHIFT).

HOT_SCAN        EQU     1Fh             ; Hot key scan code (S)
HOT_SHIFT       EQU     shAlt OR shLeft ; Shift value (ALT+LEFT SHIFT)
HOT_MASK        EQU     (shIns OR shCaps OR shNum OR shScroll) XOR 0FFh

ROW1            EQU     9               ; Query box begins on row 9
ROW2            EQU     14              ;   and ends on row 14
HEIGHT          EQU     ROW2 - ROW1 + 1 ; Number of rows in query box

Box     BYTE    '旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커', 0
        BYTE    '�  Enter filename                      �', 0
        BYTE    '�  (press Esc to cancel):              �', 0
        BYTE    '�                                      �', 0
        BYTE    '�                                      �', 0
boxend  BYTE    '읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸', 0
LEN     EQU     (LENGTHOF boxend) - 1

OldPos  WORD    ?                       ; Original cursor position
Handle  WORD    ?                       ; File handle number
Filez   BYTE    (LEN - 3) DUP(0)        ; ASCIIZ string for file spec

; Fill attribute for query box. This is changed by running SNAP with
; the /Cx switch, where x = new display attribute in hexadecimal. For
; example, to change the colors to yellow on brown for a color monitor,
; enter
;         SNAP /C6E
; where the first digit specifies the background color and the second
; digit the foreground color. Typical values for x on a monochrome
; system are
;       07 normal                 70 reverse video
;       0F high intensity         78 reverse video, high intensity

BoxFill BYTE    DEFAULT_MONO            ; Assume monochrome

; Buffer overlays two sets of data:  first, the screen text and attributes
; replaced by the query box; second, the text captured from the screen, with
; room for 50 rows of 82 characters, including carriage return/linefeed.
; The largest overlay determines the allocated size for Buffer.

MAXROW          EQU     50              ; Maximum number of screen rows
MAXCOL          EQU     80              ; Maximum number of screen columns
QUERY_SIZ       EQU     2 * ((HEIGHT * LEN) + 3)
SCREEN_SIZ      EQU     MAXROW * (MAXCOL+2)

IF SCREEN_SIZ GT QUERY_SIZ              ; Allocate space for whichever
  Buffer  BYTE    SCREEN_SIZ DUP(?)     ;   is larger:  screen text or
ELSE                                    ;   query box
  Buffer  BYTE    QUERY_SIZ DUP(?)
ENDIF


        .CODE

;* Snap - Main procedure for resident program. Called from the Activate
;* procedure when TSR is invoked by the proper key combination.
;*
;* Params:  DS, ES = @data
;*
;* Return:  None

Snap    PROC    FAR

        INVOKE  GetVidConfig            ; Get video information

        mov     al, vconfig.mode        ; AL = video mode
        .IF     (al <= 3) || (al == 7)  ; If text mode:

        INVOKE  GetCurPos               ; Get original cursor coordinates
        mov     OldPos, ax              ;   and store them
        call    OpenBox                 ; Display query box

        mov     bl, vconfig.cols        ; Calculate column
        sub     bl, LEN
        shr     bl, 1
        add     bl, 3

        INVOKE  StrInput,               ; Request input
                ROW1 + 4,               ; Row
                bl,                     ; Column
                LEN - 4,                ; Maximum string length
                ADDR Filez              ; Address of string buffer

        push    ax                      ; Save terminating keypress
        call    CloseBox                ; Restore screen to original state
        pop     ax                      ; Recover key
        .IF     al != ESCAPE            ; If ESC key not pressed:
        call    OpenSnapFile            ; Open (or create) file

        .IF     !carry?                 ; If okay,
        call    Capture                 ;   write screen to file
        .ELSE
        mov     ax, 0E07h               ; Write bell character
        int     10h                     ;   (ASCII 7) to console
        .ENDIF                          ; End file-okay test
        .ENDIF                          ; End ESC test

        mov     ax, OldPos              ; Recover original cursor position
        mov     bl, ah

        INVOKE  SetCurPos,              ; Restore cursor
                bx, ax                  ; Pass cursor row and column

        .ENDIF                          ; End text mode test

        retf                            ; Far return to Activate procedure

Snap    ENDP


;* OpenBox - Saves portion of screen to Buffer, then opens a box.
;*
;* Uses:    vconfig - Video configuration structure
;*
;* Params:  None
;*
;* Return:  None

OpenBox PROC

        mov     dh, ROW1                ; DH = top screen row for box
        mov     dl, vconfig.cols
        sub     dl, LEN
        shr     dl, 1                   ; DL = left col for centered box
        push    dx                      ; Save coords
        sub     ch, ch
        mov     cl, dh                  ; CX = row
        sub     dh, dh                  ; DX = column
        GetVidOffset cx, dx
        mov     si, ax                  ; Get video offset in SI
        mov     bx, HEIGHT              ; BX = number of window rows
        mov     cx, LEN                 ; CX = number of columns

        push    ds
        pop     es
        mov     di, OFFSET Buffer       ; Point ES:DI to hold buffer
        mov     ax, si
        stosw                           ; Copy video offset to buffer
        mov     ax, bx
        stosw                           ; Number of rows to buffer
        mov     ax, cx
        stosw                           ; Number of cols to buffer
        mov     al, vconfig.cols
        shl     ax, 1                   ; AX = number of video cells/row
        mov     ds, vconfig.sgmnt       ; DS = video segment

        .REPEAT
        push    si                      ; Save ptr to start of line
        push    cx                      ;   and number of columns
        .IF     vconfig.adapter == CGA  ; If CGA adapter,
        INVOKE  DisableCga              ;   disable video
        .ENDIF
        rep     movsw                   ; Copy one row to buffer
        .IF     vconfig.adapter == CGA  ; If CGA adapter,
        INVOKE  EnableCga               ;   reenable CGA video
        .ENDIF
        pop     cx                      ; Recover number of columns
        pop     si                      ;   and start of line
        add     si, ax                  ; Point to start of next line
        dec     bx                      ; Decrement row counter
        .UNTIL  zero?                   ; Loop while rows remain

; Screen contents (including display attributes) are now copied to buffer.
; Next open window, overwriting the screen portion just saved.

        push    es
        pop     ds                      ; Restore DS

        mov     ax, 0600h               ; Scroll service
        mov     bh, BoxFill             ; BH = fill attribute
        pop     cx                      ; CX = row/col for upper left
        mov     dh, ROW2
        mov     dl, cl
        add     dl, LEN
        dec     dl                      ; DX = row/col for lower right
        int     10h                     ; Blank window area on screen

; Write box frame and text to screen

        mov     dx, cx                  ; DX = row/col for upper left
        mov     si, OFFSET Box          ; Point to text
        mov     cx, HEIGHT              ; Number of rows in box

        .REPEAT
        push    dx                      ; Save coordinates
        sub     bh, bh
        mov     bl, dh                  ; BX = row
        sub     dh, dh                  ; DX = column   
        INVOKE  StrWrite, bx, dx, si    ; Display one line of box
        pop     dx                      ; Recover coordinates
        inc     dh                      ; Next screen row
        add     si, LEN                 ; Point to next line in box
        inc     si
        .UNTILCXZ

        ret

OpenBox ENDP


;* CloseBox - Restores the original screen text to close the window
;* previously opened by the OpenBox procedure
;*
;* Uses:    vconfig - Video configuration structure
;*
;* Params:  None
;*
;* Return:  None

CloseBox PROC

        mov     si, OFFSET Buffer
        lodsw
        mov     di, ax                  ; DI = video offset of window
        lodsw
        mov     bx, ax                  ; BX = number of window rows
        lodsw
        mov     cx, ax                  ; CX = number of columns

        mov     al, vconfig.cols
        shl     ax, 1                   ; AX = number of video cells/row

        .REPEAT
        push    di                      ; Save ptr to start of line
        push    cx                      ;   and number of columns
        .IF     vconfig.adapter == CGA  ; If CGA adapter,
        INVOKE  DisableCga              ;   disable video
        .ENDIF
        rep     movsw                   ; Copy one row to buffer
        .IF     vconfig.adapter == CGA  ; If CGA adapter,
        INVOKE  EnableCga               ;   reenable CGA video
        .ENDIF
        pop     cx                      ; Recover number of columns
        pop     di                      ;   and start of line
        add     di, ax                  ; Point to start of next line
        dec     bx                      ; Decrement row counter
        .UNTIL  zero?                   ; Loop while rows remain

        ret

CloseBox ENDP


;* OpenSnapFile - Opens or creates specified file. Resets file pointer to
;* end of file so that subsequent text is appended to bottom of file.
;*
;* Params:  DS:SI = Pointer to file spec
;*
;* Return:  None

OpenSnapFile PROC

        mov     ax, 3D01h               ; Request DOS to open file
        mov     dx, OFFSET Filez        ; DS:DX points to file specification
        int     21h                     ; Open File
        .IF     carry?                  ; If it doesn't exist,
        mov     ah, 3Ch                 ;   request create file
        sub     cx, cx                  ;   with normal attributes
        int     21h                     ; Create File
        .ENDIF

        .IF     !carry?                 ; If no error,
        mov     Handle, ax              ;   store file handle
        mov     bx, ax
        mov     ax, 4202h               ; Request DOS to reset file pointer
        sub     cx, cx                  ;   to end of file
        sub     dx, dx
        int     21h                     ; Set file pointer
        .ENDIF
        ret

OpenSnapFile ENDP


;* Capture - Copies screen text to Buffer, then writes Buffer to file.
;*
;* Uses:    vconfig - Video configuration structure
;*
;* Params:  None
;*
;* Return:  None

Capture PROC

        mov     es, vconfig.sgmnt       ; ES points to video segment address
        sub     si, si                  ; ES:SI points to 1st video byte
        sub     bx, bx                  ; BX = index to capture buffer
        mov     dx, 3DAh                ; DX = address of CGA status register

        .REPEAT
        sub     ch, ch
        mov     cl, vconfig.cols        ; CX = number of columns in line
        mov     di, cx
        dec     di
        shl     di, 1                   ; ES:DI points to video byte for
        add     di, si                  ;   last column in line

        .REPEAT
        .IF     vconfig.adapter == CGA  ; If CGA,
        cli                             ;   disallow interruptions
        .REPEAT
        in      al, dx                  ; Read current video status
        .UNTIL  !(al & 1)               ;   until horizontal retrace done
        .REPEAT
        in      al, dx                  ; Read video status
        .UNTIL  al & 1                  ;   until horizontal retrace starts
        .ENDIF                          ; End CGA retrace check

        mov     al, es:[di]             ; Get screen char, working backward
        sti                             ; Reenable interrupts in case CGA
        sub     di, 2                   ; DI points to next character
        .UNTILCXZ (al != ' ')           ; Scan for last nonblank character

        .IF     !zero?                  ; If nonblank char found,
        inc     cx                      ;   adjust column counter
        mov     di, si                  ; ES:DI points to start of line

        .REPEAT
        .IF     vconfig.adapter == CGA  ; If CGA,
        cli                             ;   disallow interruptions
        .REPEAT
        in      al, dx                  ; Read current video status
        .UNTIL  !(al & 1)               ;   until horizontal retrace done
        .REPEAT
        in      al, dx                  ; Read video status
        .UNTIL  al & 1                  ;   until horizontal retrace starts
        .ENDIF                          ; End CGA retrace check

        mov     al, es:[di]             ; Get character, working forward
        sti
        add     di, 2                   ; DI points to next character
        mov     Buffer[bx], al          ; Copy to buffer
        inc     bx
        .UNTILCXZ
        .ENDIF                          ; End check for nonblank char

        mov     WORD PTR Buffer[bx], CRLF; Finish line with return/line feed
        add     bx, 2
        mov     al, vconfig.cols
        sub     ah, ah
        shl     ax, 1
        add     si, ax                  ; SI points to start of next line
        dec     vconfig.rows            ; Decrement row count
        .UNTIL  sign?                   ; Repeat for next screen row

        mov     ah, 40h                 ; Request DOS Function 40h
        mov     cx, bx                  ; CX = number of bytes to write
        mov     bx, Handle              ; BX = file handle
        mov     dx, OFFSET Buffer       ; DS:DX points to buffer
        int     21h                     ; Write to file
        .IF     (ax != cx)              ; If number of bytes written !=
        stc                             ;   number requested, set carry
        .ENDIF                          ;   flag to indicate failure

        pushf                           ; Save carry flag
        mov     ah, 3Eh                 ; Request DOS Function 3Eh
        int     21h                     ; Close file
        popf                            ; Recover carry
        ret

Capture ENDP


@CurSeg ENDS

;* INSTALLATION SECTION - The following code and data are used only
;* during SNAP's installation phase. When the program terminates
;* through Function 31h, the above code and data remain resident;
;* memory occupied by the following code and data segments is returned
;* to the operating system.
        
DGROUP  GROUP INSTALLCODE, INSTALLDATA

INSTALLDATA SEGMENT WORD PUBLIC 'DATA2'

IDstr   BYTE    'SNAP DEMO TSR', 0      ; Multiplex identifier string

INSTALLDATA ENDS

INSTALLCODE SEGMENT PARA PUBLIC 'CODE2'
        ASSUME  ds:@data

Begin   PROC    NEAR

        mov     ax, DGROUP
        mov     ds, ax                  ; Initialize DS
        mov     ah, 15
        int     10h                     ; Get Video Mode
        .IF     al != 7                 ; If not default monochrome,
        mov     BoxFill, DEFAULT_COLR   ;   reset to default color value
        .ENDIF

; Before calling any of the TSR procedures, initialize global data

        INVOKE  InitTsr,                ; Initialize data
                es,                     ; Segment of PSP
                ADDR IDstr,             ; Far address of multiplex ID string
                ADDR BoxFill            ; Far address of memory shared
                                        ;   with multiplex handler
        .IF     ax == WRONG_DOS         ; If DOS version less than 2.0,
        jmp     exit                    ;   exit with message
        .ENDIF

; This section gets the command-line argument to determine task:
;    No argument   = install
;    /D or -D      = deinstall
;    /Cx or -Cx    = change box-fill attribute to value x

        mov     al, 'd'                 ; Search command line for
        call    GetOptions              ;   /D or -D argument
        cmp     ax, NO_ARGUMENT         ; No argument?
        je      installtsr              ; If so, try to install
        cmp     ax, OK_ARGUMENT         ; /D argument found?
        je      deinstalltsr            ; If so, try to deinstall
        mov     al, 'c'                 ; Else search command line for
        call    GetOptions              ;   /C or -C argument
        cmp     ax, BAD_ARGUMENT        ; If neither /D or /C arguments,
        je      exit                    ;   quit with error message

; This section changes the fill attribute of SNAP's query box. It converts
; to binary the two-digit hex number following the /C argument, calls the
; multiplex handler to find the address of the attribute variable stored in
; shared memory, then resets the attribute to the new value. It does not
; verify that the value specified in the command line is a valid two-digit
; hex number.

        mov     ax, es:[di+1]           ; AH = low digit, AL = high digit
        mov     cx, 2                   ; Process two digits

        .REPEAT
        sub     al, '0'                 ; Convert digit to binary
        .IF     (al > 9)                ; If not digit 0-9,
        and     al, 00011111y           ;   mask out lower-case bit
        sub     al, 7                   ; Convert A to 10, B to 11, etc.
        .ENDIF
        xchg    ah, al                  ; Get next digit in AL
        .UNTILCXZ

        mov     cl, 4
        shl     al, cl                  ; Multiply high digit by 16
        or      al, ah                  ; AL = binary value of attribute
        push    ax                      ; Save new attribute

        mov     al, 2                   ; Request function 2
        call    CallMultiplex           ; Get shared memory addr in ES:DI
        .IF     ax != IS_INSTALLED      ; If TSR is not installed,
        pop     ax                      ;   clean stack and
        mov     ax, CANT_ACCESS         ;   quit with error message
        jmp     exit
        .ELSE                           ; If TSR is installed,
        pop     ax                      ;   recover new fill attribute in AL
        mov     es:[di], al             ; Write it to resident shared memory
        mov     ax, OK_ACCESS           ; Signal successful completion
        jmp     exit
        .ENDIF

; This section sets up the TSR's interrupt handlers and
; makes the program memory-resident

installtsr:
        push    es                      ; Preserve PSP address

        mov     ax, @code
        mov     es, ax
        mov     bx, OFFSET Snap         ; ES:BX points to Snap
        INVOKE  Install,                ; Install handlers
                HOT_SCAN,               ; Scan code of hot key
                HOT_SHIFT,              ; Bit value of hot key
                HOT_MASK,               ; Bit mask for shift hot key
                es::bx                  ; Far address of Snap procedure

        pop     es                      ; Recover PSP address
        or      ax, ax                  ; If nonzero return code,
        jnz     exit                    ;   exit with appropriate message
        INVOKE  GetResidentSize,        ; Get size of resident block
                es
        INVOKE  KeepTsr,                ; Make TSR memory-resident
                ax                      ; AX = size of block in paragraphs

; This section deinstalls the resident TSR from memory

deinstalltsr:

        INVOKE  Deinstall               ; Unchain interrupt handlers

        .IF     ax > OK_ARGUMENT        ; If successful,
        INVOKE  FreeTsr,                ;   deinstall TSR by freeing memory
                ax                      ; Address of resident seg
        .ENDIF                          ; Else exit with message
exit:
        INVOKE  FatalError,             ; Exit to DOS with message
                ax                      ; Error number

Begin   ENDP

INSTALLCODE ENDS

        END     Begin
