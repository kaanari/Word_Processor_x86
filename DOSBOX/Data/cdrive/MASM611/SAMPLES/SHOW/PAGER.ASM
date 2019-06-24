;* PAGER.ASM - Module containing routines for paging through a file and
;* writing text to the screen buffer. Works with main module SHOW.ASM.


	.MODEL  small, pascal, os_dos   ; This code also works in tiny model

	INCLUDE show.inc

	.CODE

;* Pager - Displays status line and all the text lines for a screen.
;*
;* Params: cLines - lines to scroll (negative up, positive down)
;*
;* Uses:   Global variables: segBuf, offBuf, yCur
;*
;* Return: None

Pager   PROC,
	cLines:SWORD

	mov     es, segBuf              ; Initialize buffer position
	mov     di, offBuf

	mov     cx, cLines              ; Get line count
	mov     ax, 10                  ; Search for linefeed

	or      cx, cx                  ; Argument 0?
	jg      forward                 ; If above, forward
	jl      backward                ; If below, backward
	jmp     showit                  ; If equal, done
backward:
	call    GoBack                  ; Adjust backward
	jmp     showit                  ; Show screen
forward:
	call    GoForeward              ; Adjust forward

; Write line number to status line

showit:
	cld                             ; Forward
	push    di                      ; Save
	push    ds                      ; ES = DS
	pop     es

	INVOKE  BinToStr,               ; Write line number as string
		yCur,
		ADDR stLine[LINE_POS]

; Fill in status line

	mov     cx, 6                   ; Seven spaces to fill
	sub     cx, ax                  ; Subtract those already done
	mov     al, ' '                 ; Fill with space
	rep     stosb

	INVOKE  ShowLine,               ; Write to screen
		ADDR stLine,            ; Far pointer to line
		0,                      ; Line number
		atSta                   ; Attribute

	pop     di
	mov     si, di                  ; Update position
	mov     cx, yMax                ; Lines per screen

	.REPEAT
	mov     bx, yMax                ; Lines per screen
	inc     bx                      ; Adjust for 0
	sub     bx, cx                  ; Calculate current row
	push    cx                      ; Save line number
	mov     es, segBuf              ; Reload

	INVOKE  ShowLine,               ; Write line to screen
		es::si,                 ; Far pointer to text
		bx,                     ; Line number
		atScr                   ; Attribute

	pop     cx                      ; Restore line number
	mov     si, ax                  ; Get returned position

	dec     cx                      ; Count the line
	.UNTIL  (ax >= cbBuf) || !cx    ; Continue if more lines and not CX
	jcxz    exit                    ; Done if more lines,
					;   else fill screen with spaces
	mov     al, cl                  ; Columns * remaining lines
	mov     dl, X_MAX               ;   is count of cells to fill
	mul     dl
	mov     dx, ax                  ; Save in DX (INVOKE uses AX)

	sub     cx, yMax                ; Calculate starting line
	neg     cx
	inc     cx

	INVOKE  CellFill,               ; Write space cells
		cx,                     ; Starting line
		dx,                     ; Cells to write
		celScr                  ; Cell to write
exit:
	ret

Pager   ENDP


;* WriteNCell - Macro to write a cell one or more times. For CGA, the
;* macro writes during horizontal retrace. Note that this is a macro
;* even though it may result in more code than if it were a procedure.
;* This is because writes to the screen buffer are a speed bottleneck
;* that only occur at a few key points in the program. The extra
;* size cost is worth paying.
;*
;* Uses:   ES:DI has screen buffer position
;*         AX has cell
;*         DX should have port number for rescan check if CGA
;*
;* Params: isCGA - One of the following:
		CGA     EQU     1
		NoCGA   EQU     0
;*
;*         count - If blank, write cell in AX once. If count given, write
;*         cell in AX count times. Note that the count is optimized for a
;*         CX argument. The argument should normally be blank or CX.

WriteNCell MACRO isCGA:REQ, count:=<1>

    IF isCGA EQ 0                       ; First handle non-CGA
	IFIDNI <count>, <1>             ; Special case one cell
	    stosw
	ELSE
	    IFDIFI <count>, <cx>        ; Load count if necessary
		mov  cx, count
	    ENDIF
	    rep  stosw                  ; Do repeated sequence
	ENDIF
    ELSE
	IFIDNI <count>, <1>             ; Special case one cell
	    push    ax                  ; Save character
	    .REPEAT
	    in      al, dx              ; Look in the port
	    shr     al, 1               ;   until it goes low
	    .UNTIL  !carry?
	    cli
	    .REPEAT
	    in      al, dx              ; Look in the port
	    shr     al, 1               ;   until it goes high
	    .UNTIL  carry?
	    pop     ax                  ; Restore and write it
	    stosw
	    sti
	ELSE
	    IFDIFI <count>, <cx>        ; Load count if necessary
		mov  cx, count
	    ENDIF
	    .REPEAT
	    push    ax                  ; Save character
	    .REPEAT
	    in      al, dx              ; Look in the port
	    shr     al, 1               ;   until it goes low
	    .UNTIL  !carry?
	    cli
	    .REPEAT
	    in      al, dx              ; Look in the port
	    shr     al, 1               ;   until it goes high
	    .UNTIL  carry?
	    pop     ax                  ; Restore and write it
	    stosw
	    sti
	    .UNTILCXZ
	ENDIF
    ENDIF
ENDM

;* ShowLine - Writes a line to the screen buffer.
;*
;* Params: fpBuffer - Far pointer to line to write
;*         y - Line number
;*         attr - Attribute
;*
;* Return: None

ShowLine PROC USES si di ds,
	fpBuffer:FAR PTR BYTE,
	y:WORD,
	attr:BYTE

	sub     dx, dx                  ; Zero
	.IF     fCGA                    ; User port number as CGA flag
	mov     dx, 03DAh               ; Load port #
	.ENDIF
	mov     es, segVid              ; Load screen buffer segment
	lds     si, fpBuffer            ; Buffer segment
	mov     cx, X_MAX               ; Cells per row
	mov     ax, y                   ; Starting row
	mov     bx, X_MAX * 2           ; Bytes per row
	mul     bl                      ; Figure columns per row
	mov     di, ax                  ; Load as destination
	mov     bx, di                  ; Save start for tab calculation
	mov     ah, attr                ; Attribute
movechar:
	lodsb                           ; Get character
	cmp     al, 13                  ; CR?
	je      fillspc
	cmp     al, 9                   ; Tab?
	jne     notab
	call    FillTab                 ; Yes? Fill with spaces
	jcxz    nextline                ; If beyond limit, done
	jmp     movechar
notab:
	or      dx, dx                  ; CGA?
	je      notab2
	WriteNCell CGA                  ; Yes? Write during retrace
	loop    movechar                ; Duplicate code here and below
	jmp     nextline                ;   is worth cost in tight loop
notab2:
	WriteNCell NoCGA                ; Write
	loop    movechar
	jmp     nextline                ; Done
fillspc:
	mov     al, ' '                 ; Fill with space

	.IF     dx != 0                 ; CGA?
	WriteNCell CGA, cx
	inc     si                      ; Adjust
	jmp     exit                    ; Done
	.ENDIF
	WriteNCell NoCGA, cx
	inc     si                      ; Adjust for LF
	jmp     exit                    ; Done
nextline:
	mov     ah, 10                  ; Search for next line feed
	.REPEAT
	lodsb                           ; Load and compare
	.UNTILCXZ al == ah
exit:
	mov     ax, si                  ; Return position
	ret

ShowLine ENDP


;* CellFill - Fills a portion of the screen with a specified
;* character/attribute cell.
;*
;* Params: yStart - Starting line
;*         cbCell - Number of cells
;*         celFill - Attribute and character
;*
;* Return: None

CellFill PROC,
	yStart:WORD,
	cbCell:WORD,
	celFill:WORD

	mov     dx, 03DAh               ; Load port #
	mov     cx, yStart              ; Starting line
	mov     al, X_MAX * 2           ; Convert line to starting offset
	mul     cl
	mov     di, ax                  ; Make it the target
	mov     es, segVid              ; Load screen buffer segment
	mov     cx, cbCell              ; Characters to fill
	mov     ax, celFill             ; Attribute
	.IF     fCGA                    ; Write cells
	WriteNCell CGA, cx
	.ELSE
	WriteNCell NoCGA, cx
	.ENDIF

	ret

CellFill ENDP


;* FillTab - Writes spaces for tab to screen.
;*
;* Input:  BX points to start of line
;*         DI points to current position
;*
;* Return: None

FillTab PROC

	push    bx
	push    cx

	sub     bx, di                  ; Get current position in line
	neg     bx
	shr     bx, 1                   ; Divide by 2 bytes per character

	mov     cx, 8                   ; Default count 8
	and     bx, 7                   ; Get modulus
	sub     cx, bx                  ; Subtract
	mov     bx, cx                  ; Save modulus

	mov     al, ' '                 ; Spaces
	.IF     dx != 0                 ; Write cells
	WriteNCell CGA, cx
	.ELSE
	WriteNCell NoCGA, cx
	.ENDIF
	pop     cx
	sub     cx, bx                  ; Adjust count
	.IF     sign?
	sub     cx, cx                  ; Make negative count 0
	.ENDIF
	pop     bx
	ret

FillTab ENDP


;* IsEGA - Determines if the current adapter can handle more than 25
;* lines per screen (usually an EGA or VGA).
;*
;* Params: None
;*
;* Return: 0 if no CGA or MONO, lines per screen if EGA/VGA

IsEGA   PROC

	mov     ah, 12h                 ; Call EGA status function
	mov     bl, 10h
	sub     cx, cx                  ; Clear status bits
	int     10h
	sub     ax, ax                  ; Segment 0 and assume no EGA
	jcxz    noega                   ; If status still clear, no EGA

	mov     es, ax                  ; ES=0
	test    BYTE PTR es:[487h], 1000y; Test active bit
	jnz     noega                   ; If set, not active
	mov     ax, 1130h               ; Get EGA information
	int     10h
	mov     al, dl                  ; Return lines per screen
	cbw
noega:
	ret

IsEGA   ENDP


	END
