        .modeL  small, pascal, os_dos
        INCLUDE demo.inc

        .DATA
_psp    PSEG    ?               ; Segment of PSP
_env    PSEG    ?               ; Segment of environment

        .CODE

;* WinOpen - Saves portion of screen to allocated memory, then opens a window
;* with specified fill attribute. See also the WinClose procedure.
;*
;* Shows:   DOS Function - 48h (Allocate Memory Block)
;*          Instructions - movsw      stosw     rep
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Row1 - Row at top of window
;*          Col1 - Column at left edge of window
;*          Row2 - Row at bottom of window
;*          Col2 - Column at right edge of window
;*          Attr - Fill attribute for window
;*
;* Return:  Short integer with segment address of allocated buffer, or
;*          0 if unable to allocate memory

WinOpen PROC USES ds di si,
        Row1:WORD, Col1:WORD, Row2:WORD, Col2:WORD, Attr:WORD

        GetVidOffset Row1, Col1         ; Get offset in video segment
        mov     si, ax                  ; SI = video offset for window
        mov     bx, Row2
        sub     bx, Row1
        inc     bx                      ; BX = number of window rows
        mov     cx, Col2
        sub     cx, Col1
        inc     cx                      ; CX = number of columns

        mov     ax, cx                  ; Compute number of video
        mul     bl                      ;   cells in window
        add     ax, 3                   ; Plus 3 additional entries
        shr     ax, 1                   ; Shift right 3 times to
        shr     ax, 1                   ;   multiply by 2 bytes/cell,
        shr     ax, 1                   ;   divide by 16 bytes/paragraph
        inc     ax                      ; Add a paragraph
        push    bx                      ; Save number of rows
        mov     bx, ax                  ; BX = number of paragraphs
        mov     ah, 48h                 ; Request DOS Function 48h
        int     21h                     ; Allocate Memory Block
        pop     bx

        .IF     carry?                  ; If unsuccessful,
        sub     ax, ax                  ;   return null pointer
        .ELSE
        mov     es, ax                  ; Point ES:DI to allocated
        sub     di, di                  ;   buffer
        mov     ax, si
        stosw                           ; Copy video offset to buffer
        mov     ax, bx
        stosw                           ; Number of rows to buffer
        mov     ax, cx
        stosw                           ; Number of cols to buffer
        mov     ax, 160                 ; Number of video cells/row
        mov     ds, vconfig.sgmnt       ; DS = video segment

        .REPEAT
        push    si                      ; Save ptr to start of line
        push    cx                      ;   and number of columns

; For CGA adapters, WinOpen avoids screen "snow" by disabling the video prior
; to block memory moves, then reenabling it. Although this technique can
; result in brief flickering, it demonstrates the fastest way to access a
; block in the CGA video buffer without causing display snow. See also the
; StrWrite procedure for another solution to the problem of CGA snow.

        .IF     vconfig.adapter == CGA  ; If not CGA adapter,
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
        .UNTIL  zero?                   ; Until no rows remain

; Screen contents (including display attributes) are now copied to buffer.
; Next open window, overwriting the screen portion just saved.

        mov     ax, 0600h               ; Scroll service
        mov     bh, BYTE PTR Attr       ; Fill attribute
        mov     cx, Col1                ; CX = row/col for upper left
        mov     ch, BYTE PTR Row1
        mov     dx, Col2                ; DX = row/col for lower right
        mov     dh, BYTE PTR Row2
        int     10h                     ; Blank window area on screen
        mov     ax, es                  ; Return address of allocated
        .ENDIF                          ;   segment
        ret

WinOpen ENDP


;* WinClose - "Closes" a window previously opened by the WinOpen procedure.
;* See also the WinOpen procedure.
;*
;* Shows:   DOS Function - 49h (Release Memory Block)
;*          Instructions - lodsw
;*          Operators - : (segment override)     SEG
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Adr - Segment address of buffer that holds screen contents
;*                saved in WinOpen procedure
;*
;* Return:  None

WinClose PROC USES ds di si,
        Adr:WORD

        mov     ds, Adr                 ; DS:SI points to buffer
        sub     si, si
        lodsw
        mov     di, ax                  ; DI = video offset of window
        lodsw
        mov     bx, ax                  ; BX = number of window rows
        lodsw
        mov     cx, ax                  ; CX = number of columns

        mov     ax, SEG vconfig.sgmnt
        mov     es, ax                  ; Point ES to data segment
        push    es:vconfig.sgmnt
        pop     es                      ; ES = video segment
        mov     ax, 160                 ; Number of video cells/row

        .REPEAT
        push    di                      ; Save ptr to start of line
        push    cx                      ;   and number of columns

; Disable CGA video prior to memory move to avoid screen snow. (See the
; WinOpen and StrWrite procedures for further discussions on CGA snow.)

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
        .UNTIL  zero?                   ;   until no rows remain

        mov     ah, 49h                 ; Request DOS Function 49h
        mov     es, Adr
        int     21h                     ; Release Memory Block
        ret

WinClose ENDP


;* SetCurSize - Sets cursor size.
;*
;* Shows:   BIOS Interrupt - 10h, Function 1 (Set Cursor Type)
;*
;* Params:  Scan1 - Starting scan line
;*          Scan2 - Ending scan line
;*
;* Return:  None

SetCurSize PROC,
        Scan1:WORD, Scan2:WORD

        mov     cx, Scan2               ; CL = ending scan line
        mov     ch, BYTE PTR Scan1      ; CH = starting scan line
        mov     ah, 1                   ; Function 1
        int     10h                     ; Set Cursor Type
        ret

SetCurSize ENDP


;* GetCurSize - Gets current cursor size.
;*
;* Shows:   BIOS Interrupt - 10h, Function 3 (Get Cursor Position)
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  None
;*
;* Return:  Short integer with high byte = top scan line,
;*                             low byte  = bottom scan line

GetCurSize PROC

        mov     ah, 3                   ; Function 3
        mov     bh, vconfig.dpage
        int     10h                     ; Get Cursor Position
        mov     ax, cx                  ; Return cursor size
        ret

GetCurSize ENDP


;* GetShift - Gets current shift status. Checks for extended keyboard,
;* and, if available, returns additional shift information.
;*
;* Shows:   BIOS Interrupt - 16h, Functions 2 and 12h (Get Keyboard Flags)
;*
;* Params:  None
;*
;* Return:  Long integer
;*          high word = 0 for nonextended keyboard
;*                      1 for extended keyboard
;*          low word has following bits set when indicated keys are pressed:
;*          0 - Right SHIFT                   8 - Left CTRL
;*          1 - Left SHIFT                    9 - Left ALT
;*          2 - CTRL                         10 - Right CTRL
;*          3 - ALT                          11 - Right ALT
;*          4 - SCROLL LOCK active           12 - SCROLL LOCK pressed
;*          5 - NUM LOCK active              13 - NUM LOCK pressed
;*          6 - CAPS LOCK active             14 - CAPS LOCK pressed
;*          7 - INSERT toggled               15 - SYS REQ pressed

GetShift PROC

        sub     dx, dx                  ; Assume nonextended keyboard
        mov     ah, 2                   ;   and use Function 2
        mov     es, dx                  ; Point ES to low memory
        .IF     BYTE PTR es:[496h] & 16 ; If extended keyboard installed,
        inc     dx                      ;   set high word of return code
        mov     ah, 12h                 ;   and use Function 12h
        .ENDIF
        int     16h                     ; Get Keyboard Flags
        ret

GetShift ENDP


;* GetKeyClock - Waits for keystroke while updating time at specified location
;* on screen.
;*
;* Shows:   BIOS Interrupt - 16h, Functions 0 and 10h (Read Character)
;*                           16h, Functions 1 and 11h (Get Keyboard Status)
;*          DOS Functions - 2Ah (Get Date)
;*                          2Ch (Get Time)
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Row - Screen row for clock display
;*          Col - Screen column for clock display
;*
;* Return:  Short integer with key scan code in high byte and ASCII
;*          character code in low byte. Low byte is 0 for special
;*          keys (such as the "F" keys), which don't generate characters.

        .DATA
        PUBLIC  datestr
datestr BYTE    "  -  -     :  :  ", 0  ; Date/time string
        .CODE

GetKeyClock PROC,
        Row:WORD, Col:WORD

        LOCAL   service:BYTE

        INVOKE  GetShift                ; Check for extended keyboard
        mov     service, 11h            ; Assume Function 11h
        .IF     dx != 1                 ; If no extended keyboard,
        mov     service, 1              ;   use Function 1
        .ENDIF

        .WHILE  1
        mov     ah, service
        int     16h                     ; Get Keyboard Status
        .BREAK  .IF !zero?              ; If no key yet, update clock

; If not monochrome, color text, or black and white, skip clock update
; and poll keyboard again.

        .CONTINUE .IF (vconfig.mode != 7) \
                   && (vconfig.mode != 3) \
                   && (vconfig.mode != 2)

; If 80-column text, get date and time from DOS before again
; polling keyboard, and display at upper right corner of screen.

        mov     ah, 2Ch                 ; Request time
        int     21h                     ; Get Time
        mov     dl, dh
        push    dx                      ; Save seconds,
        push    cx                      ;   minutes,
        mov     cl, ch                  ;   and
        push    cx                      ;   hours
        mov     ah, 2Ah                 ; Request date
        int     21h                     ; Get Date
        sub     cx, 1900                ; Subtract century, CL = year
        push    cx                      ; Save year,
        push    dx                      ;   day,
        mov     dl, dh                  ;   and
        push    dx                      ;   month

        mov     cx, 6
        sub     bx, bx

        .REPEAT
        pop     ax                      ; Recover all 6 numbers in AL
        aam                             ; Convert to unpacked BCD
        xchg    al, ah                  ; Switch bytes for word move
        or      ax, "00"                ; Make ASCII numerals
        mov     WORD PTR datestr[bx], ax; Copy to string
        add     bx, 3                   ;   at every third byte
        .UNTILCXZ

        INVOKE  StrWrite, Row, Col, ADDR datestr
        .ENDW                           ; Loop again for keypress

        mov     ah, service             ; 1 or 11h, depending on keybd
        dec     ah                      ; Set AH to 0 or 10h
        int     16h                     ; Get key to remove it from
        ret                             ;   keyboard buffer

GetKeyClock ENDP


;* GetPSP - Gets address of Program Segment Prefix. For DOS 3.0 or higher.
;*
;* Shows:   DOS Function - 62h (Get PSP Address)
;*          Instruction - call
;*
;* Params:  None
;*
;* Return:  Short integer with PSP segment address
;*          or 0 if DOS version below 3.0

GetPSP  PROC

        INVOKE  GetVer                  ; Get DOS version number
        .IF     ax >= 300               ; If DOS 3.0 or higher:
        mov     ah, 62h                 ;   query DOS for PSP,
        int     21h                     ;   get PSP Address,
        mov     ax, bx                  ;   return in AX
        .ELSE                           ; Else 2.0:
        sub     ax, ax                  ; For version 2, return 0
        .ENDIF
        ret

GetPSP  ENDP


;* GetMem - Gets total size of memory and determines the largest amount of
;* unallocated memory available. GetMem invokes DOS Function 48h (Allocate
;* Memory) to request an impossibly large memory block. DOS denies the re-
;* quest, but returns instead the size of the largest block available. This
;* is the amount that GetMem returns to the calling program. See the WinOpen
;* procedure for an example of calling Function 48h to allocate unused memory.
;*
;* Shows:   BIOS Interrupt - 12h (Get Conventional Memory Size)
;*          Instructions - push     pop      ret
;*
;* Params:  None
;*
;* Return:  Long integer, high word = total memory in kilobytes (KB)
;*                        low word  = largest block of available memory (KB)

GetMem  PROC

        int     12h                     ; Get total memory in kilobytes
        push    ax                      ; Save size of memory
        mov     ah, 48h                 ; Request memory allocation
        mov     bx, 0FFFFh              ; Ensure request is denied for
                                        ;   impossibly large block
        int     21h                     ; Get largest available block in BX
        mov     ax, bx                  ; Copy to AX
        mov     cl, 6                   ; Convert paragraphs to kilobytes by
        shr     ax, cl                  ;   dividing by 64
        pop     dx                      ; Recover total in DX
        ret                             ; Return long integer DX:AX

GetMem  ENDP


;* VeriPrint - Checks if LPT1 (PRN) is available.
;*
;* Shows:   BIOS Interrupt - 17h (Parallel Port Printer Driver)
;*
;* Params:  None
;*
;* Return:  Short integer, 1 for yes or 0 for no

VeriPrint PROC

        mov     ah, 2                   ; Check printer status for
        sub     dx, dx                  ;   parallel printer (port 0)
        int     17h
        xchg    dx, ax                  ; Put 0 (for error) in AX

; If all error bits are off and both operation bits are on, return 1

        .IF     !(dh & 00101001y) && (dh & 10010000y)
        inc     ax                      ; Return 1
        .ENDIF
        ret

VeriPrint ENDP


;* IntToAsc - Converts integer to ASCII string. This procedure is useful
;* only for assembly language and is not intended to be callable by C.
;*
;* Shows:   Instructions - aam     xchg
;*
;* Entry:   AX = integer (9999 max)
;*
;* Return:  DX:AX = 4-digit ASCII number

IntToAsc PROC

        cwd                             ; Zero DX register
        mov     cx, 100                 ; Divide AX by 100, yields
        div     cx                      ;   AX=quotient, DX=remainder
        aam                             ; Make digits unpacked BCD
        or      ax, "00"                ; Convert to ASCII
        xchg    ax, dx                  ; Do same thing for DX
        aam
        or      ax, "00"
        ret                             ; Return DX:AX = ASCII number

IntToAsc ENDP


;* VeriAnsi - Checks for ANSI driver by writing ANSI sequence to report
;* cursor position. If report compares with position returned from
;* GetCurPos procedure, then ANSI driver is operating.
;*
;* Shows:   DOS Functions - 06h (Direct Console I/O)
;*                          0Ch (Flush Input Buffer and then Input)
;*
;* Params:  None
;*
;* Return:  Short integer, 1 for yes or 0 for no

        .DATA
        PUBLIC report
report  DB      ESCAPE, "[6n$"          ; ANSI Report Cursor sequence
        .CODE

VeriAnsi PROC

        ; Get cursor position from BIOS
        INVOKE  GetCurPos
        mov     cx, ax                  ; Save it in CX
        mov     dx, OFFSET report       ; ANSI string to get position
        mov     ah, 9                   ; Request DOS String Output
        int     21h                     ; Write ANSI escape sequence

        mov     ah, 6                   ; Skip Esc character in
        mov     dl, 0FFh                ;   keyboard buffer
        int     21h
        jz      e_exit                  ; If no key, ANSI not loaded
        mov     ah, 6                   ; Skip '[' character
        int     21h
        jz      e_exit                  ; If no key, ANSI not loaded
        mov     ah, 6                   ; Get 1st digit of cursor row
        int     21h
        jz      e_exit                  ; If no key, ANSI not loaded
        mov     bh, al                  ; Store in BH
        mov     ah, 6                   ; Get 2nd digit of cursor row
        int     21h
        jz      e_exit                  ; If no key, ANSI not loaded
        mov     bl, al                  ; Store in BL
        mov     al, ch                  ; Get original row # in AL
        cbw                             ; AX = row # from GetCurPos
        inc     ax                      ; Add 1 to it
        call    IntToAsc                ; Make ASCII digits
        cmp     ax, bx                  ; ANSI and BIOS reports match?
        jne     e_exit                  ; No?  Then ANSI not loaded

        mov     ax, 0C06h               ; Flush remaining ANSI keys
        mov     dl, 0FFh                ;   from buffer
        int     21h
        mov     ax, 1                   ; Set 1 for true
        jmp     exit                    ;   and exit
e_exit:
        sub     ax, ax                  ; Set 0 return code if no
exit:
        ret                             ;   ANSI driver installed

VeriAnsi ENDP


;* VeriCop - Checks for coprocessor.
;*
;* Shows:   BIOS Interrupt - 11h (Get Equipment Configuration)
;*
;* Params:  None
;*
;* Return:  Short integer, 1 for yes or 0 for no

VeriCop PROC

        int     11h                     ; Check peripherals
        test    al, 2                   ; Coprocessor?
        mov     ax, 0                   ; Assume no, don't alter flags
        .IF     !zero?
        inc     ax                      ; Set to 1
        .ENDIF
        ret

VeriCop ENDP


;* SetLineMode - Sets line mode for EGA or VGA.
;*
;* Shows:   BIOS Interrupt - 10h, Function 11h (Character Generator Interface)
;*                           10h, Function 12h (Video Subsystem Configuration)
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Line - Requested line mode (25, 43, or 50)
;*
;* Return:  Short integer with error code
;*          0 if successful
;*          1 if error

SetLineMode PROC,
        Line:WORD

        .IF     vconfig.adapter >= EGA  ; If EGA or VGA:
        mov     ax, Line                ; Check for valid parameter
        cmp     al, 25
        je      line25
        cmp     al, 43
        je      line43
        cmp     al, 50
        je      line50
        jmp     e_exit                  ; If not 25, 43, or 50, exit w/ error
line25:
        mov     al, 11h                 ; Set for EGA 25-line mode
        cmp     vconfig.adapter, EGA    ; EGA?
        je      linemode                ; Yes?  Continue
        mov     ax, 1202h               ; No?  Function 12h for VGA
        mov     bl, 30h                 ; AL = 2 for 400 scan lines
        int     10h                     ; Reset to 400 scan lines
        mov     ax, 0003                ; Reset mode (Function 0)
        int     10h                     ;   to mode 3 (80-col text)
        mov     al, 14h                 ; Request 8x16 char matrix
        jmp     linemode
line43:
        mov     al, 12h                 ; Set for EGA 43-line mode
        cmp     vconfig.adapter, EGA    ; EGA?
        je      linemode                ; Yes?  Continue
        mov     ax, 1201h               ; No?  Function 12h for VGA
        mov     bl, 30h                 ; AL = 1 for 350 scan lines
        int     10h                     ; Reset to 350 scan lines
        mov     ax, 0003                ; Reset mode (Function 0)
        int     10h                     ;   to mode 3 (80-col text)
        mov     al, 12h                 ; Request 8x8 character matrix
        jmp     linemode
line50:
        cmp     vconfig.adapter, VGA    ; VGA?
        jne     e_exit                  ; No?  Exit with error
        mov     ax, 1202h               ; Yes?  Function 12h
        mov     bl, 30h                 ; AL = 2 for 400 scan lines
        int     10h                     ; Reset to 400 scan lines
        mov     ax, 0003                ; Reset mode (Function 0)
        int     10h                     ;   to mode 3 (80-col text)
        mov     al, 12h                 ; Request 8x8 character matrix
linemode:
        sub     bl, bl                  ; Use table 0
        mov     ah, 11h                 ; Request Function 11h
        int     10h                     ; Set new line mode

        mov     ah, 12h                 ; Select alternate print
        mov     bl, 20h                 ;   screen for EGA and VGA
        int     10h

        cmp     vconfig.adapter, VGA    ; VGA?
        je      exit                    ; Yes?  Then exit
        cmp     Line, 12h               ; If EGA 43-line mode, set
        je      port                    ;   cursor through port to
                                        ;   avoid cursor emulation bug

        ; Set normal cursor size, pass top and bottom scan lines
        INVOKE  SetCurSize, 6, 7
        jmp     exit
port:
        mov     dx, 03D4h               ; Video controller address
        mov     ax, 060Ah               ; Set AH = 06h (cursor start)
                                        ;     AL = 0Ah (register #)
        out     dx, ax                  ; Update port
        mov     ax, 000Bh               ; Set AH = 00h (cursor end)
                                        ;     AL = 0Bh (register #)
        out     dx, ax                  ; Update port
        jmp     exit                    ; Normal exit
        .ENDIF  ; EGA or VGA
e_exit:
        mov     ax, 1                   ; Set error code
        jmp     exit2
exit:
        sub     ax, ax                  ; Clear error code
exit2:
        ret

SetLineMode ENDP


;* Pause - Waits for specified number of clocks to elapse, then returns.
;*
;* Shows:   BIOS Interrupt - 1Ah, Function 0 (Real-Time Clock Driver)
;*          Operators - LOCAL     []
;*
;* Params:  Duration - Desired duration in clocks, where
;*                     18 clocks = approx 1 second
;*
;* Return:  None

Pause   PROC,
        Duration:WORD

        LOCAL tick:DWORD

        sub     ah, ah
        int     1Ah                     ; Get Clock Count in CX:DX
        add     dx, Duration            ; Add pause time to it
        adc     cx, 0
        mov     WORD PTR tick[0], dx    ; Result is target time;
        mov     WORD PTR tick[2], cx    ;   keep in local variable

        .REPEAT
        int     1Ah                     ; Poll clock until target time
        .UNTIL  (dx >= WORD PTR tick[0]) || (cx >= WORD PTR fileinfo.time[2])
        ret

Pause   ENDP


;* Sound - Sounds speaker with specified frequency and duration.
;*
;* Shows:   Instructions - in           out
;*
;* Params:  Freq - Desired frequency of sound in hertz
;*          Duration - Desired duration in clocks, where
;*                     18 clocks = approx 1 second
;*
;* Return:  None

Sound   PROC,
        Freq:WORD, Duration:WORD

        mov     al, 0B6h                ; Initialize channel 2 of
        out     43h, al                 ;   timer chip
        mov     dx, 12h                 ; Divide 1,193,182 hertz
        mov     ax, 34DEh               ;   (clock frequency) by
        div     Freq                    ;   desired frequency
                                        ; Result is timer clock count
        out     42h, al                 ; Low byte of count to timer
        mov     al, ah
        out     42h, al                 ; High byte of count to timer
        in      al, 61h                 ; Read value from port 61h
        or      al, 3                   ; Set first two bits
        out     61h, al                 ; Turn speaker on

        ; Pause, pass duration of delay
        INVOKE  Pause, Duration

        in      al, 61h                 ; Get port value
        xor     al, 3                   ; Kill bits 0-1 to turn
        out     61h, al                 ;   speaker off
        ret

Sound   ENDP


;* WriteTTY - Displays ASCIIZ string at cursor position, in either text
;* or graphics mode.
;*
;* Shows:   BIOS Interrupt - 10h, Function 0Eh (Write Character in TTY Mode)
;*
;* Uses:    vconfig - Video configuration structure (initialized
;*          by calling the GetVidConfig procedure)
;*
;* Params:  Sptr - Pointer to ASCIIZ string
;*          icolor - Color index (for graphics mode only)
;*
;* Return:  None

WriteTTY PROC USES ds si,
        Sptr:PBYTE, icolor:WORD

        mov     bx, icolor              ; BL = color index
        mov     bh, vconfig.dpage       ; BH = current display page
        LoadPtr ds, si, Sptr
        mov     cx, -1                  ; Set loop counter to maximum
        mov     ah, 14                  ; Function 14

        .REPEAT
        lodsb                           ; Get character from string
        .BREAK .IF al == 0              ; Exit if NULL string terminator
        int     10h                     ; No?  Display, advance cursor
        .UNTILCXZ

        ret

WriteTTY ENDP


;* Colors - Alters screen colors within a specified area by using bit
;* or move operations on display attribute bytes in video memory.
;*
;* Shows:   Instructions - not     rol     ror     and     xor     or
;*
;* Params:  Logic - Code number, 0 = NOT    2 = ROR     4 = XOR    6 = MOV
;*                               1 = ROL    3 = AND     5 = OR
;*          Attr - Attribute mask
;*          Row1 - Row at top of window
;*          Col1 - Column at left edge of window
;*          Row2 - Row at bottom of window
;*          Col2 - Column at right edge of window
;*
;* Return:  None

Colors  PROC USES ds si,
        Logic:WORD, Attr:WORD, Row1:WORD, Col1:WORD, Row2:WORD, Col2:WORD

        GetVidOffset Row1, Col1         ; Get offset in video segment
        inc     ax
        mov     si, ax                  ; SI = offset for 1st attr byte
        mov     bx, Row2
        sub     bx, Row1
        inc     bx                      ; BX = number of window rows
        mov     cx, Col2
        sub     cx, Col1
        inc     cx                      ; CX = number of columns

        mov     ds, vconfig.sgmnt       ; DS = video segment
        mov     ax, Attr                ; AL = mask for and, xor, and or

        .REPEAT
        push    si                      ; Save ptr to start of line
        push    cx                      ;   and number of columns

; Disable CGA video prior to memory access to avoid screen snow. (See the
; WinOpen and StrWrite procedures for further discussions on CGA snow.)

        .IF     vconfig.adapter == CGA  ; If CGA adapter:
        INVOKE  DisableCga              ; Yes?  Disable video
        .ENDIF

        cmp     Logic, 1                ; Rotate left?
        jl      c_not                   ; If less, do NOT
        je      c_rol                   ; If equal, do ROL
        cmp     Logic, 3                ; And?
        jl      c_ror                   ; If less, do ROR
        je      c_and                   ; If equal, do AND
        cmp     Logic, 5                ; Or?
        jl      c_xor                   ; If less, do XOR
        je      c_or                    ; If equal, do OR
c_mov:
        mov     BYTE PTR [si], al       ; MOV attr parameter
        add     si, 2                   ;   into attribute byte
        loop    c_mov
        jmp     c_done
c_or:
        or      BYTE PTR [si], al       ; OR with attr parameter
        add     si, 2
        loop    c_or
        jmp     c_done
c_xor:
        xor     BYTE PTR [si], al       ; XOR with attr parameter
        add     si, 2
        loop    c_xor
        jmp     c_done
c_and:
        and     BYTE PTR [si], al       ; AND with attr parameter
        add     si, 2
        loop    c_and
        jmp     c_done
c_ror:
        ror     BYTE PTR [si], 1        ; Rotate right 1 bit
        add     si, 2
        loop    c_ror
        jmp     c_done
c_rol:
        rol     BYTE PTR [si], 1        ; Rotate left 1 bit
        add     si, 2
        loop    c_rol
        jmp     c_done
c_not:
        not     BYTE PTR [si]           ; Flip bits
        add     si, 2
        loop    c_not
c_done:
        .IF     vconfig.adapter == CGA  ; If CGA,
        INVOKE  EnableCga               ;   reenable CGA video
        .ENDIF

        pop     cx                      ; Recover number of columns
        pop     si                      ; Recover offset for start of line
        add     si, 160                 ; Point to start of next line
        dec     bx                      ; Decrement row counter
        .UNTIL  zero?                   ; Loop while rows remain
        ret

Colors  ENDP


;* Exec - Executes a child process.  Exec handles the usual chores associated
;* with spawning a process:  (1) parsing the command line tail and loading the
;* FCBs with the first two arguments; (2) setting and restoring the vectors
;* for Interrupts 1Bh, 23h, and 24h; and (3) querying DOS for the child's
;* return code.
;*
;* Shows:   DOS Functions - 29h (Parse Filename)
;*                          25h (Set Interrupt Vector)
;*                          35h (Get Interrupt Vector)
;*                          4Bh (Execute Program)
;*                          4Dh (Get Return Code)
;*
;* Params:  Spec - Pointer to ASCIIZ specification for program file
;*                 (must include .COM or .EXE extension)
;*          Block - Pointer to parameter block structure
;*          CtrBrk - Pointer to new CTRL+BREAK (Interrupt 1Bh) handler
;*          CtrlC - Pointer to new CTRL+C (Interrupt 23h) handler
;*          Criterr - Pointer to new Critical Error (Interrupt 24h) handler
;*
;* Return:  Short integer with child return code, or -1 for EXEC error

Exec    PROC USES ds si di,
        Spec:PBYTE, Block:PPARMBLK, CtrBrk:PTR FAR,
        CtrlC:PTR FAR, Criterr:PTR FAR

        Vector 1Bh, Old1Bh, CtrBrk      ; Save, replace Int 1Bh vector
        Vector 23h, Old23h, CtrlC       ; Save, replace Int 23h vector
        Vector 24h, Old24h, Criterr     ; Save, replace Int 24h vector

        LoadPtr ds, bx, Block           ; Point DS:BX to parameter block
        push    ds                      ; Save segment address
        les     di, (PARMBLK PTR [bx]).fcb1    ; Point ES:DI to first FCB
        lds     si, (PARMBLK PTR [bx]).taddr   ; Point DS:SI to command-line
                                               ;   tail
        inc     si                      ; Skip over count byte

        mov     ax, 2901h               ; Set AH to request Function 29h
                                        ; AL = flag to skip leading blanks
        int     21h                     ; Parse command-line into first FCB
        pop     es                      ; Recover seg addr of parameter block
        les     di, (PARMBLK PTR es:[bx]).fcb2   ; Point ES:DI to second FCB
        mov     ax, 2901h               ; Request DOS Function #29h again
        int     21h                     ; Parse command-line into second FCB

        push    bp                      ; Save only important register
        mov     WORD PTR cs:OldStk[0], sp
        mov     WORD PTR cs:OldStk[2], ss
        LoadPtr es, bx, Block           ; ES:BX points to param block
        LoadPtr ds, dx, Spec            ; DS:DX points to path spec
        mov     ax, 4B00h               ; AH = DOS Function 4Bh
                                        ; AL = 0 for load and execute
        int     21h                     ; Execute Program
        mov     sp, WORD PTR cs:OldStk[0] ; Reset stack pointers
        mov     ss, WORD PTR cs:OldStk[2]
        pop     bp                      ; Recover saved register

; Restore vectors for Interrupts 1Bh, 23h, and 24h.

        mov     ax, 251Bh               ; AH = DOS Function 25h
                                        ; AL = interrupt number
        lds     dx, cs:Old1Bh           ; DS:DX = original vector
        int     21h                     ; Set Interrupt 1Bh Vector
        mov     al, 23h                 ; AL = interrupt number
        lds     dx, cs:Old23h           ; DS:DX = original vector
        int     21h                     ; Set Interrupt 23h Vector
        mov     al, 24h                 ; AL = interrupt number
        lds     dx, cs:Old24h           ; DS:DX = original vector
        int     21h                     ; Set Interrupt 24h Vector

        mov     ax, -1                  ; Set error code
        .IF     !carry?                 ; If no EXEC error:
        mov     ah, 4Dh                 ; Request child's code
        int     21h                     ; Get Return Code
        sub     ah, ah                  ; Make short integer
        .ENDIF
        ret

Old1Bh  FPVOID  ?                       ; Keep vectors for Interrupts
Old23h  FPVOID  ?                       ;   1Bh, 23h, and 24h in code
Old24h  FPVOID  ?                       ;   segment, but nonexecutable
OldStk  FPVOID  ?                       ; Keep stack pointer

Exec    ENDP


;* BinToHex - Converts binary word to 6-byte hexadecimal number in
;* ASCIIZ string. String is right justified and includes "h" radix.
;*
;* Shows:   Instruction - xlat
;*
;* Params:  Num - Number to convert to hex string
;*          Sptr - Pointer to 6-byte string
;*
;* Return:  None

        .DATA
hex     BYTE    "0123456789ABCDEF"      ; String of hex numbers

        .CODE
BinToHex PROC USES di,
        Num:WORD, Sptr:PBYTE

        LoadPtr es, di, Sptr            ; Point ES:DI to 6-byte string
        mov     bx, OFFSET hex          ; Point DS:BX to hex numbers
        mov     ax, Num                 ; Number in AX
        mov     cx, 2                   ; Loop twice for two bytes

        .REPEAT
        xchg    ah, al                  ; Switch bytes
        push    ax                      ; Save number
        shr     al, 1                   ; Shift high nibble to low
        shr     al, 1
        shr     al, 1
        shr     al, 1
        xlat                            ; Get equivalent ASCII number in AL
        stosb                           ; Copy to 6-byte string, increment DI
        pop     ax                      ; Recover number
        push    ax                      ; Save it again
        and     al, 00001111y           ; Mask out high nibble
        xlat                            ; Get equivalent ASCII number in AL
        stosb                           ; Copy to 6-byte string, increment DI
        pop     ax                      ; Recover number
        .UNTILCXZ                       ; Do next byte
        mov     ax, 'h'                 ; Put null, 'h' radix in AX
        stosw                           ; Copy to last two bytes in string
        ret

BinToHex ENDP


;* NewBlockSize - Adjusts size of allocated memory block.
;*
;* Shows:   DOS Function - 4Ah (Resize Memory Block)
;*
;* Params:  Adr - Segment address of block
;*          Resize - Requested block size in paragraphs
;*
;* Return:  Short integer error code
;*          0 if successful
;*          1 if error

NewBlockSize PROC,
        Adr:WORD, Resize:WORD

        mov     ax, Adr                 ; Get block address
        mov     es, ax                  ; Point ES to block
        mov     bx, Resize              ; New block size
        mov     ah, 4Ah                 ; Function number
        int     21h                     ; Resize Memory Block
        ret

NewBlockSize ENDP


;* Initialize - Initializes global variables _psp and _env, which are defined
;* in the DEMO.INC include file. If used with a DOS version less than 3.0,
;* this procedure will not produce valid results unless it is called before
;* changing the ES register. This is because at program entry ES points to
;* the Program Segment Prefix (PSP).
;*
;* Params:  None
;*
;* Return:  None

Initialize PROC

        INVOKE  GetPSP                  ; Get segment address of PSP
        .IF     ax == 0                 ; If less than DOS 3.0,
        mov     es, ax                  ;   reload ES with PSP address
        .ENDIF

        mov     _psp, es                ; Initialize variable with PSP address
        mov     ax, es:[2Ch]            ; Get environment seg from PSP
        mov     _env, ax                ; Store it
        ret

Initialize ENDP

        END
