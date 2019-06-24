;* SHOWUTIL.ASM - Module containing various routines used by SHOW

        TITLE   ShowUtil
        .MODEL  small, pascal

        INCLUDE show.inc

        .CODE

;* GetNamePos - Given a file specification potentially including filename,
;* directory, and/or drive, return the position of the first character
;* of the filename.
;*
;* Params: pchSpec - address of file spec
;*
;* Return: Near pointer to position of name portion of file spec

GetNamePos PROC USES di si,
        pchSpec:PTR BYTE

        push    ds
        pop     es
        mov     di, pchSpec             ; Load address of filename
        mov     si, di                  ; Save copy

        sub     cx, cx                  ; Use CX as count
        sub     dx, dx                  ; Use DX as found flag
        sub     ax, ax                  ; Search for null

        .REPEAT
        .IF BYTE PTR es:[di] == '\'     ; For each backslash,
        mov     si, di                  ;   save position and
        inc     dx                      ;   set flag to true
        .ENDIF
        inc     cx                      ; Count it
        scasb                           ; Get next character
        .UNTIL  zero?

        .IF     dx != 0                 ; If found backslash,
        mov     ax, si                  ;   return position in AX
        inc     ax

        .ELSE                           ; Else search for colon
        mov     di, si                  ; Restore start of name
        mov     ax, ":"                 ; Search for colon
        repne   scasb

        .IF     zero?                   ; If colon,
        mov     ax, di                  ;   return position in DX:AX
        .ELSE                           ; Else,
        mov     ax, si                  ;   return original address
        .ENDIF
        .ENDIF

        ret

GetNamePos ENDP


;* GoBack - Purpose   Searches backward through buffer
;*
;* Params:   CX has number of lines
;*           ES:DI has buffer position
;*           AL has 10 (line feed character)
;*
;* Return:   None
;*
;* Modifies: Updates yCur and offBuf

GoBack  PROC

        neg     cx                      ; Make count positive
        mov     dx, cx                  ; Save a copy
        inc     cx                      ; One extra to go up one
        .IF     di == 0                 ; If start of file, done
        ret
        .ENDIF

        .REPEAT
        push    cx                      ; Save count
        mov     cx, 0FFh                ; Load maximum character count
        .IF     cx >= SWORD PTR di      ; If near start of buffer,
        mov     cx, di                  ;   search only to start
        .ENDIF
        std                             ; Go backward
        repne   scasb                   ; Find last previous LF
        cld                             ; Go forward
        jcxz    atstart                 ; If not found, must be at start
        pop     cx
        .UNTILCXZ

        .IF     yCur == 0FFFFh          ; If end of file flag,
        add     di, 2                   ;   adjust for cr/lf,
        mov     offBuf, di              ;   save position,
        call    EndCount                ;   count back to get line number,
        mov     yCur, ax                ;   store line count
        ret
        .ENDIF

        sub     yCur, dx                ; Calculate line number
        jg      positive
        mov     yCur, 1                 ; Set to 1 if negative
positive:
        add     di, 2                   ; Adjust for cr/lf
        mov     offBuf, di              ; Save position
        ret
atstart:
        pop     cx
        sub     di, di                  ; Load start of file
        mov     yCur, 1                 ; Line 1
        mov     offBuf, di              ; Save position
        ret

GoBack  ENDP


;* GoForeward - Skips forward through a buffer of text a specified
;* number of lines.
;*
;* Params:  CX - number of text lines to skip
;*          ES:DI - starting buffer position
;*          AL has 10 (line-feed character)
;*
;* Return:  None
;*
;* Modifes: yCur, offBuf, bx, cx, di

GoForeward PROC

        cld                             ; Go forward
        mov     dx, cx                  ; Copy count

        .REPEAT
        push    cx                      ; Save count
        mov     cx, 0FFh                ; Load maximum character count
        mov     bx, cbBuf               ; Get end of file

        sub     bx, di                  ; Characters to end of file
        .IF     cx >= bx                ; If less than maximum per line,
        mov     cx, bx                  ;   adjust
        .ENDIF

        repne   scasb                   ; Find next LF
        pop     cx


        .IF     !zero? || (di >= cbBuf) ; If LF not found or beyond end,
        mov     di, offBuf              ;   restore original position
        ret                             ;   and quit
        .ENDIF
        .UNTILCXZ

        add     yCur, dx                ; Calculate line number
        mov     offBuf, di              ; Save position
        ret

GoForeward ENDP


;* EndCount - Skips backward through a buffer of text, counting each
;* text line.
;*
;* Params: ES:DI - buffer position (end of file)
;*
;* Return: Number of lines counted

EndCount PROC USES di dx cx

        std                             ; Backward
        mov     al, 13                  ; Search for CR
        mov     dx, -1                  ; Initialize (first will inc to 0)

        .REPEAT
        inc     dx                      ; Adjust count
        mov     cx, 0FFh                ; Load maximum character count

        .IF     SWORD PTR cx >= di      ; If near start of buffer,
        mov     cx, di                  ;   search only to start
        .ENDIF

        repne   scasb                   ; Find last previous CR
        .UNTIL  !zero?                  ; If not found, must be at start

        mov     ax, dx                  ; Return count
        cld                             ; Forward
        ret

EndCount ENDP


;* BinToStr - Converts an unsigned integer to a string. User is
;* responsible for providing a large enough buffer. The string is
;* not null terminated.
;*
;* Params: i - Integer to be converted
;*         pch - Pointer to character buffer to receive string
;*
;* Return: Number of character in string.

BinToStr PROC,
        i:WORD,
        pch:PTR BYTE

        mov     ax, i
        mov     di, pch

        sub     cx, cx                  ; Clear counter
        mov     bx, 10                  ; Divide by 10

; Convert and save on stack backwards

        .REPEAT
        sub     dx, dx                  ; Clear top
        div     bx                      ; Divide to get last digit as remainder
        add     dl, "0"                 ; Convert to ASCII
        push    dx                      ; Save on stack
        .UNTILCXZ ax == 0               ;   until quotient is 0

; Take off the stack and store forward

        neg     cx                      ; Negate and save count
        mov     dx, cx

        .REPEAT
        pop     ax                      ; Get character
        stosb                           ; Store it
        .UNTILCXZ
        mov     ax, dx                  ; Return digit count

        ret

BinToStr ENDP


        END
