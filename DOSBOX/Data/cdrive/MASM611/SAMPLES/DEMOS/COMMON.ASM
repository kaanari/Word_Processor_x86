        .MODEL  small, pascal
        INCLUDE demo.inc

        .DATA
vconfig VIDCONFIG <>           ; Global video configuration structure

        .CODE

;* GetVidConfig - Determines current video configuration and initializes
;* the vconfig structure.
;*
;* Shows:   BIOS Interrupt - 10h, Function 0 (Set Video Mode)
;*                           10h, Function 0Fh (Get Current Video Mode)
;*                           10h, Function 1Ah (Video Display Combination)
;*
;* Uses:    vconfig - Video configuration structure, declared in the
;*          DEMO.INC include file.
;*
;* Params:  None
;*
;* Return:  None

GetVidConfig PROC

        mov     ax, 1A00h               ; Get video info for VGA
        int     10h
chkVGA:
        cmp     al, 1Ah                 ; Is VGA or MCGA present?
        jne     chkEGA                  ; No?  Then check for EGA

        cmp     bl, 2                   ; If VGA exists as secondary adapter,
        je      isCGA                   ;   check for CGA and mono as primary
        jb      isMONO
        cmp     bl, 5                   ; If EGA is primary, do normal
        jbe     chkEGA                  ;   EGA checking
chkMCGA:
        mov     vconfig.adapter, MCGA   ; Yes?  Assume MCGA
        mov     vconfig.display, COLOR
        cmp     bl, 8                   ; Correct assumption?
        ja      gotmode                 ; Yes?  Continue
isVGA:
        mov     vconfig.adapter, VGA    ; Assume it's VGA color
        je      gotmode                 ; Yes?  Continue
        mov     vconfig.display, MONO   ; No?  Must be VGA mono
        jmp     gotmode                 ; Finished with VGA, so jump
chkEGA:
        mov     ah, 12h                 ; Call EGA status function
        mov     bl, 10h
        sub     cx, cx                  ; Clear status bits
        int     10h
        jcxz    chkCGA                  ; If CX is unchanged, not EGA
isEGA:
        mov     vconfig.adapter, EGA    ; Set structure fields for EGA
        mov     vconfig.display, MONO   ; Assume EGA mono
        or      bh, bh                  ; Correct assumption?
        jnz     gotmode                 ; Yes?  Continue
        mov     vconfig.display, COLOR  ; No?  Must be EGA color
        jmp     gotmode                 ; Finished with EGA, so jump
chkCGA:
        int     11h                     ; Get equipment list
        and     al, 30h                 ; If bits 4-5 set, monochrome
        cmp     al, 30h                 ; Monochrome text mode?
        je      isMONO                  ; Yes?  Continue
isCGA:
        mov     vconfig.adapter, CGA    ; No?  Must be CGA
        mov     vconfig.display, COLOR
        jmp     gotmode
isMONO:
        mov     vconfig.adapter, MDA    ; Set MONO
        mov     vconfig.display, MONO
gotmode:
        mov     ah, 0Fh
        int     10h                     ; Get current mode
        mov     vconfig.mode, al        ; Record mode
        mov     vconfig.dpage, bh       ;   and current page
        mov     al, vconfig.display     ; Multiply display value
        cbw                             ;   (which is either 0 or 1)
        mov     bx, 800h                ;   by 800h, then add to 0B000h
        mul     bx                      ;   for segment address of
        add     ax, 0B000h              ;   video buffer
        add     ah, vconfig.dpage       ; Adding display page gives
        mov     vconfig.sgmnt, ax       ;   address of current page

        sub     ax, ax
        mov     es, ax
        mov     al, es:[44Ah]           ; Get number of display cols
        mov     vconfig.cols, al        ; Store in structure
        mov     vconfig.rows, 24        ; Assume bottom row # = 24
        cmp     vconfig.adapter, EGA    ; EGA or VGA?
        jl      exit                    ; No?  Exit
        mov     ax, 1130h               ; Yes?  Request character info
        sub     bh, bh                  ; Set BH to valid value
        push    bp                      ; BP will change, so save it
        int     10h                     ; Get number of rows/screen
        mov     vconfig.rows, dl        ; Keep in structure
        pop     bp                      ; Restore BP
exit:
        ret

GetVidConfig ENDP


;* GetCurPos - Gets current cursor position.
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  None
;*
;* Return:  Short integer with high byte = row, low byte = column

GetCurPos PROC USES bx dx

        mov     ah, 3                   ; Function 3
        mov     bh, vconfig.dpage
        int     10h                     ; Get cursor position
        mov     ax, dx
        ret

GetCurPos ENDP


;* SetCurPos - Sets cursor position.
;*
;* Shows:   BIOS Interrupt - 10h, Function 2 (Set Cursor Position)
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Row - Target row
;*          Col - Target column
;*
;* Return:  None

SetCurPos PROC USES bx dx,
        Row:WORD,
        Col:WORD

        mov     dh, BYTE PTR Row        ; DH = row
        mov     dl, BYTE ptr Col        ; DL = column
        mov     ah, 2                   ; Function 2
        mov     bh, vconfig.dpage       ; Current page
        int     10h                     ; Set cursor position
        ret

SetCurPos ENDP


;* StrWrite - Writes ASCIIZ string to video memory at specified row/column.
;*
;* Shows:   Instructions - lodsb     stosb
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Row - Row coordinate
;*          Col - Column coordinate
;*          Sptr - Pointer to string
;*
;* Return:  None

StrWrite PROC USES ds si di,
        Row:WORD,
        Col:WORD,
        Sptr:PTR BYTE

        GetVidOffset Row, Col           ; Get video offset for these coords
        mov     di, ax                  ; Copy to DI
        LoadPtr ds, si, Sptr            ; DS:SI points to string
        mov     es, vconfig.sgmnt       ; ES:DI points to video RAM
        .WHILE  1                       ; Loop forever (or until break)
        lodsb                           ; Get 1 character from string
        .BREAK .IF al == 0              ; Quit if null terminator

; For CGA systems, StrWrite waits for the video to begin a horizontal
; retrace before writing a character to memory. This avoids the problem
; of video snow inherent with some (though not all) color/graphics adapters.
; It also demonstrates a somewhat different approach to the problem than the
; one taken in the WinOpen and WinClose procedures.

        .IF vconfig.adapter != CGA      ; If not CGA, skip this step
        push    ax                      ; Save character
        mov     dx, 3DAh                ; Address of status register
        cli                             ; Disallow interruptions
        .REPEAT
        in      al, dx                  ; Read current video status
        .UNTIL  !(al & 1)               ; Until horizontal retrace done

        .REPEAT
        in      al, dx                  ; No?  Read status again
        .UNTIL  al & 1                  ; Until retrace starts
        pop     ax                      ; Recover character
        .ENDIF  ; CGA only

        stosb                           ; Write char to video buffer
        sti                             ; Reenable interrupts in case CGA
        inc     di                      ; Skip attribute byte
        .ENDW
        ret

StrWrite ENDP


;* StrInput - Gets input string from keyboard using BIOS. Signals idle
;* state by calling interrupt 28h while polling for keypress, making
;* the procedure useful in TSR programs. Terminates when ENTER or ESC
;* keys pressed.
;*
;* Shows:   DOS interrupt - Interrupt 28h (DOS Idle Interrupt)
;*
;* Params:  Row - Row coordinate
;*          Col - Column coordinate
;*          Max - Maximum allowable string length
;*          Sptr - Pointer to string
;*
;* Return:  Short integer with terminating char

StrInput PROC USES ds si,
        Row:WORD,
        Col:WORD,
        Max:WORD,
        Sptr:PBYTE

        LoadPtr ds, si, Sptr            ; DS:SI points to string
        add     Max, si
        dec     Max                     ; MAX now points to string limit

        .WHILE  1                       ; Get key until break or continue
loop1:
        INVOKE  StrWrite,               ; Display input string
                Row,
                Col,
                si
        mov     bx, si
        mov     dx, Col                 ; DL = cursor column

        .WHILE  (BYTE PTR [bx] != 0)    ; Scan string for null terminator
        inc     bx                      ; Else try next character
        inc     dx                      ;   and increment cursor column
        .ENDW

; Set cursor position, pass row and column
        INVOKE  SetCurPos,
                Row,
                dx

        call    GetKey                  ; Poll for keypress

        .BREAK  .IF al == ESCAPE || \   ; Exit if ESC or
                    al == CR            ;   ENTER key

        .IF     al == BACKSP || \       ; If BACKSPACE or LEFT,
                ah == LEFT              ;   handle it
        cmp     bx, si                  ; At first letter?
        jbe     loop1                   ; Yes?  Ignore BACKSPACE
        dec     bx                      ; No?  Point to preceding char
        dec     dx                      ; Decrement column
        mov     BYTE PTR [bx], ' '      ; Blank char
        push    bx                      ; Preserve pointer
        INVOKE  StrWrite,               ; Overwrite last char with blank
                Row,
                dx,
                bx

        pop     bx
        mov     BYTE PTR [bx], 0        ; Make last char the new terminator
        .CONTINUE                       ; Continue polling for keystrokes
        .ENDIF

        .CONTINUE .IF bx > Max          ; Ignore key if too many letters
        sub     ah, ah
        mov     [bx], ax                ; Store letter and null terminator
        .ENDW

        ret

StrInput ENDP


;* ClearBox - Clears portion of screen with specified fill attribute.
;*
;* Shows:   BIOS Interrupt - 10h, Function 6 (Scroll Up)
;*
;* Params:  Attr - Fill attribute
;*          Row1 - Top screen row of cleared section
;*          Col1 - Left column of cleared section
;*          Row2 - Bottom screen row of cleared section
;*          Col2 - Right column of cleared section
;*
;* Return:  None

ClearBox PROC,
        Attr:WORD,
        Row1:WORD,
        Col1:WORD,
        Row2:WORD,
        Col2:WORD

        mov     ax, 0600h               ; Scroll service
        mov     bh, BYTE PTR Attr       ; BH = fill attribute
        mov     ch, BYTE PTR Row1       ; CH = top row of clear area
        mov     cl, BYTE PTR Col1       ; CL = left column 
        mov     dh, BYTE PTR Row2       ; DH = bottom row of clear area
        mov     dl, BYTE PTR Col2       ; DL = right column
        int     10h                     ; Clear screen by scrolling up
        ret

ClearBox ENDP


;* DisableCga - Disables CGA video by reprogramming the control register.
;*
;* Shows:   Instructions - cli     sti
;*
;* Params:  None
;*
;* Return:  None

DisableCga PROC USES ax cx dx           ; Preserve registers

        mov     cx, -1                  ; Set maximum loop count
        mov     dx, 03DAh               ; Address of status register

        .REPEAT
        in      al, dx                  ; Get video status
        .UNTILCXZ !(al & 8)             ; Until retrace end/timeout
        cli                             ; Disallow interruptions
        mov     cx, -1                  ; Reset loop count

        .REPEAT
        in      al, dx                  ; Get video status
        .UNTILCXZ al & 8                ; Until retrace start/timeout

        sub     dx, 2                   ; DX = address of control reg
        mov     al, 1                   ; Value to disable CGA video
        out     dx, al                  ; Disable video
        sti                             ; Reenable interrupts
        ret

DisableCga ENDP


;* EnableCga - Enables CGA video by reprogramming the control register.
;*
;* Params:  None
;*
;* Return:  None

EnableCga PROC USES ax dx es                    ; Preserve registers

        sub     ax, ax
        mov     es, ax                          ; Point ES to low memory
        mov     al, es:[0465h]                  ; Get former mode setting
        mov     dx, 03D8h                       ; Address of control register
        out     dx, al                          ; Enable video
        ret

EnableCga ENDP


;* GetVer - Gets DOS version.
;*
;* Shows:   DOS Function - 30h (Get MS-DOS Version Number)
;*
;* Params:  None
;*
;* Return:  Short integer of form (M*100)+m, where M is major
;*          version number and m is minor version, or integer 
;*          is 0 if DOS version earlier than 2.0

GetVer  PROC

        mov     ah, 30h                 ; DOS Function 30h
        int     21h                     ; Get MS-DOS version number
        .IF     al == 0                 ; If version, version 1
        sub     ax, ax                  ; Set AX to 0
        .ELSE                           ; Version 2.0 or higher
        sub     ch, ch                  ; Zero CH and move minor
        mov     cl, ah                  ;   version number into CX
        mov     bl, 100
        mul     bl                      ; Multiply major by 10
        add     ax, cx                  ; Add minor to major*10
        .ENDIF
        ret                             ; Return result in AX

GetVer  ENDP


;* GetKey - Polls for keypress, calling Interrupt 28h while waiting. This
;* routine simulates Interrupt 16h, service 0, working directly with the
;* keyboard buffer. It should be used only by TSR programs.
;*
;* Bypassing BIOS to access the keyboard buffer is generally not recommended;
;* however, some applications incorrectly set up a handler for Interrupt 16h,
;* making them incompatible with TSRs that require keyboard input.
;*
;* Shows:   BIOS keyboard data area
;*
;* Params:  None
;*
;* Return:  AH = scan code
;*          AL = character

GetKey  PROC USES ds bx

        mov     ax, 40h                 ; Point DS to data area (see
        mov     ds, ax                  ;   "Keyboard Data Area" in Help)
        mov     ax, WORD PTR ds:[1Ah]   ; AX = pointer to head of kb buffer

        .REPEAT
        int     28h                     ; Call Int 28h to signal idle state
        cmp     ax, WORD PTR ds:[1Ch]   ; If head = tail, no key waiting,
        .UNTIL  !zero?                  ;   so continue polling

        mov     bx, ax
        mov     ax, WORD PTR [bx]       ; Get keypress from buffer head
        inc     bx                      ; Advance head position
        inc     bx
        .IF     bx >= WORD PTR ds:[82h] ; If advanced past end of buffer,
        mov     bx, WORD PTR ds:[80h]   ;   reset to beginning of buffer
        .ENDIF
        mov     WORD PTR ds:[1Ah], bx   ; Set new head pointer

        ret

GetKey  ENDP
        
        END
