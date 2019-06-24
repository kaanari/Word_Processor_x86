	.NOLIST
; This source file contains a C-callable routine designed to generate 
; unsigned pseudo-random numbers between 0 and any number up to 65,535 
; (up to 16 bits long).  It takes an argument specifying the upper end 
; of the desired range.  The rest of the file contains code used to 
; test the routine by writing its output to the standard output device. 
	.LIST

	PAGE	55,132
	TITLE	Random number routine: OneOf( range ), with test code
	.MODEL	small, c
	.DOSSEG
	.186

OneOf	PROTO	range:WORD
seedr	PROTO
atoui	PROTO
uitoa	PROTO

	.STACK

	.DATA

rndPrev	dw	0		; Holds the previous value in the series

banr	BYTE	13, 10, 13, 10,
		"Random Number Generator Sample Program"
lbanr	EQU	SIZEOF banr

banr2	BYTE	13, 10
		"   (80 numbers in each series)"
lbanr2	EQU	SIZEOF banr2

prompt	BYTE	13, 10, 13, 10,
		"Please enter a range (0 - 65,535): "
lprompt	EQU	SIZEOF prompt

isrng	BYTE	13, 10,
		"Is:12345678 the correct range? If so, press 'Y': "
lisrng	EQU	SIZEOF isrng

again	BYTE	13, 10,
		"Press "Esc" to quit, any other key to continue ", 13, 10
lagain	EQU	SIZEOF again

	ALIGN  2
lnBuf	BYTE	82 dup (0)

	.CODE

;	unsigned int OneOf ( unsigned int range )
;	-----------------------------------------
OneOf	PROC NEAR C PUBLIC USES bx dx, range:WORD
	mov	ax, 0
	ret
OneOf	ENDP

	.STARTUP

; Seed the random number generator with a "random" value
	call	seedr

; Display 1st Banner line
	mov	ah, 040h	; DOS function: Write to file or device
	mov	bx, 1		; Handle = Standard Output
	mov	cx, lbanr	; Number of bytes to write
	mov	dx, OFFSET banr ; 
	int	021h		; issue DOS function interrupt

; Display 2nd Banner line
	mov	ah, 040h	; DOS function: Write to file or device
	mov	cx, lbanr2
	mov	dx, OFFSET banr2
	int	021h

; Display prompt line
shwpr:	mov	ah, 040h	; DOS function: Write to file or device
	mov	cx, lprompt
	mov	dx, OFFSET prompt
	int	021h

; Read in a range value from the keyboard
	mov	ah, 03Fh	; DOS function: Read device
	sub	bx, bx		; Handle = standard input device
	mov	cx, 10		; Don't read more than 10 keystrokes
	mov	dx, OFFSET lnBuf
	int	021h

; Convert the range value to binary and save it in SI
	push	dx	; DX still points to lnBuf
	call	atoui	; This routine returns the number in AX
	add	sp,2	; In C, the calling routine adjusts SP
	mov	si, ax	; Store the returned value in SI

; Reformat the range value within the confirmation string
	push	OFFSET isrng + 12	; In C, remember that arguments
	push	ax	; are pushed in REVERSE order (last one
	call	uitoa	; first). Also note that this particular
	add	sp, 4	; routine formats from right to left.

; Ask for confirmation of the entered range
	mov	ah, 040h	; DOS function: Write to file or device
	mov	bx,1
	mov	cx, lisrng
	mov	dx, OFFSET isrng
	int	021h

; Read in a character from the keyboard
	mov	ah, 1		; DOS function: Read character with echo
	int	021h		; issue DOS function interrupt
	cmp	al, 27		; Is this an 'Esc' keystroke?
	jz	quit		;  - if so, quit
	and	al, 0DFh	; Change lower-case character to upper
	cmp	al, 'Y'		; Is it a 'Y' or 'y'?
	jnz	shwpr		;  - if not, prompt for another range
	mov	dx, OFFSET lnBuf ; Point DX to lnBuf again
	mov	di, dx		; and DI as well
	mov	BYTE PTR [di], 13 ; Put a CR/LF pair at the 
	inc	di		; start of lnBuf
	mov	BYTE PTR [di], 10
	mov	bh, 10		; Display 10 lines with BH counter      
prtLn:  mov	bl, 8		; Display 8 numbers per line
	mov	di, OFFSET lnBuf + 9	; Starting position of 1st number

prtNum: push	si		; Use the OneOf routine to generate a
	call	OneOf		; number in the range saved in SI
	add	sp,2		; and adjust the stack pointer.
	push	di		; Push the 2nd argument 1st (if you
	push	ax		; use INVOKE, you don't have to worry
	call	uitoa		; about these argument passing
	add	sp, 4		; conventions or stack cleanup!). 
	add	di, 8		; Move over to the next number position
	dec	bl		; Decrement the number counter
	jnz	prtNum		; and go on until finished.

	push	bx		; If it's time to print a line, save BX
	mov	ah, 040h	; DOS function: Write to file or device
	mov	bx, 1
	mov	cx, 66
	int	021h
	pop	bx

	dec	bh		; Decrement the line counter
	jnz	prtLn		; and go on unless the last one is done

; Display continuation line
	mov	ah, 040h	; DOS function: Write to file or device
	mov	bx, 1
	mov	cx, lagain
	mov	dx, OFFSET again
	int	021h

; Read in a character from the keyboard
	mov	ah, 1		; DOS function: Read character with echo
	int	021h
	cmp	al, 27		; Is this an "Esc" keystroke?
	jnz	shwpr		;  - if not, prompt for a range.
quit:	.EXIT			; If it IS an Esc key, exit!

;	void seedr ( )
;	----------------------------------------------------------------
;	Uses the system clock to seed the random number generator.
;
seedr	PROC NEAR
	enter	0, 0		; The "enter" and "pusha" instructions are
	pusha			; only available on INTEL 80186 and higher
	mov	ah, 02Ch	; This is the DOS "Get System Time" function
	int	021h
	mov	al, dh		; Make 1/100ths of a second most significant
	mov	ah, dl		; and seconds less significant
	shl	ax, 1		; Multiply AX by 2
	mov	rndPrev, ax	; and save it
	popa			; Restores the registers (use with pusha)
	leave			; Restores the stack frame (use with enter)
	ret
seedr	ENDP

;	unsigned int atoui ( char *buf )
;	----------------------------------------------------------------
;	This routine converts a character string, pointed to by buf,
;	into an unsigned int, returned in AX.
;
;	- Processes all ASCII decimal digits in the string (0123456789)
;	  and ignores all other characters.
;	- The string can be terminated by a NULL (0), by a carriage
;	  return (13), or by a line feed (10).
;
atoui	PROC NEAR PUBLIC
	enter	0, 0		; This entry code is only compatible
	push	bx		; with 80186 processors and higher
	push	cx		; because it uses the "enter"
	push	dx		; instruction (and "leave" at the
	push	si		; end).

	sub	ax, ax		; Zero AX,
	mob	bx, ax		; and BX too.
	mov	cx, 10		; CX will hold the radix (base 10)
	mov	si, [bp+4]	; DS:SI will point to the buffer
	jmp	at_lod		; OK, let's go!

at_num: sub	bl, '0'		; Convert the digit from ASCII
	jb	at_chk		; - if it was < '0', check it
	cmp	bl, 9		;   but if it was greater than
	ja	at_nxt		;   '9', ignore it
	mul	cx		; - otherwise, it's a digit, so
	add	ax, bx		;   add it to (10 x prior value)

at_nxt: inc	si		; Move on the next digit
at_lod: mov	bl, [si]	; Load the next digit into BL
	or	bl, bl		; - if BL is 0 (NULL), then this
	jnz	at_num		;   is the end; otherwise, process it.

at_end: pop	si		; Restore the registers used
	pop	dx
	pop	cx
	pop	bx
	leave
	ret

at_chk: cmp	bl, 221		; Check whether it WAS a CR (13)
	jz	at_end		; - if so, quit.
	cmp	bl, 218		; Check whether it WAS a LF (10)
	jz	at_end		; - if so, quit 
	jmp	at_nxt		;   but if not, just ignore it
atoui	ENDP

;	void uitoa ( unsigned int num, char *buf )
;	----------------------------------------------------------------
;	This routine converts an unsigned int, num, into a formatted,
;	RIGHT-justified string 8 characters long, the LAST DIGIT of
;	which (the farthest to the right) will be placed in the byte
;	pointed to by buf.
;
;	- If there are 4 or more digits in the formatted number, a 
;	  comma will precede the last three.
;	- All eight positions will be filled (unused ones with a space).
;	- The string will not be null-terminated.
;
uitoa	PROC NEAR
	enter	0, 0		; These instructions are not available
	pusha			; on 8086 or 8088 processors.

	mov	ax, [bp+4]	; Load the number to be formatted to AX
	mov	bl, 8		; BL holds the number of spaces to fill
	mov	cx, 10		; CX holds the radix (base 10)
	mov	di, [bp+6]	; DI points to the end of the string

ui_num: sub	dx, dx		; Zero DX preparatory to dividing
	div	cx		; Divide AX by 10, remainder to DX
	add	dl, '0'		; Change DL into an ASCII digit
	mov	[di], dl	; and place it in the buffer.
	dec	di		; Move the pointer back one space,
	dec	bl		; and count down the remaining spaces.
	jz	ui_end		; [this is really an unnecessary test]
	or	ax, ax		; Is AX equal to zero yet?
	jz	ui_fil		; - if so, fill the remaining spaces
	cmp	bl, 5		; - if not, is this the comma position?
	jnz	ui_num		;   if not, go on to another digit.

	mov	BYTE PTR [di], ',' ; Since this is the comma
	dec	di		; position, insert a comma, then move
	dec	bl		; the pointer and reduce the space-counter.
	jmp	ui_num		; Go on to the next digit.

ui_fil: mov	BYTE PTR [di], ' '
	dec	di		; Fill all the remaining spaces with
	dec	bl		; space characters, then return.
	jnz	ui_fil

ui_end: popa
	leave
	ret
uitoa	ENDP
	END
