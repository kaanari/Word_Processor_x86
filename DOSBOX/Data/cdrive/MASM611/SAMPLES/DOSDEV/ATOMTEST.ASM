;----------------------------------------------------------------------------;
; ATOMTEST.ASM: A minimal tester for the atoms device driver		     ;
;----------------------------------------------------------------------------;
; A simple test of ATMS, with minimal error testing. It reads a string from  ;
; the keyboard, writes it to the device, and immediately reads from the      ;
; device. It also uses itoh to give the length of the result string returned ;
; by the driver. Quit by inputting nothing or by CTRL+C			     ;
;									     ;
; To communicate with the ATMS driver, we first open it as if it were	     ;
; a file, using @Openfile. The system will return a handle, with which,	     ;
; we can begin communicating to the driver.                                  ;
;                                                                            ;
; By passing a null terminated string to @Write, you can do the following    ;
;         if string =  '<variable>', search for <variable>                   ;
;         if string =  '<variable>=' delete <variable>                       ;
;         if string =  '<variable>=value' insert <variable>                  ;
; This allows us to 'browse' the data stored by ATMS.                        ;
;                                                                            ;
; Calling @Read will return the current <variable> text.                     ;
;----------------------------------------------------------------------------;

	include	dos.inc			; contains all the @ macros

       	.model  small, c, os_dos
       	.386
	.dosseg
        .stack
	.data

dname   BYTE    'ATMS',0
handle  WORD    0
sMenu	BYTE	cr,lf,'     ATMS Sample Device Driver',cr,lf,
		cr,lf,'     Select Device Function',cr,lf,
			cr,lf,'     1. Write to Device Only',
		cr,lf,'     2. Read from Device Only',
		cr,lf,'     3. Inquire Device Output Status',
		cr,lf,'     0. Quit',
		cr,lf,'     Other Keys: Write & Read',
		cr,lf,'                 Until Return',cr,lf,eom
sPrompt BYTE	cr,lf,'     Please Press a Key: ',eom		
sInput  BYTE 	cr,lf, 'Input? ', eom
sError  BYTE	cr,lf,lf,'Error: Could not open the driver',cr,lf,eom
sQuit	BYTE	cr,lf,lf,'Quit',cr,lf,eom
outBuf	BYTE	140 dup (?)
output  BYTE    cr,lf
value 	BYTE    '0000: '
inBuf   BYTE    140 dup (?)
inLen	WORD	SIZEOF inBuf
outLen  WORD    SIZEOF outBuf
cr      EQU     0Dh             	
lf      EQU     0Ah             	
eom     EQU     '$'             	
; Table of hexadecimal digits used for the hex translation
hex	BYTE	'0123456789ABCDEF'

	.code

int2hex PROTO, :WORD, :WORD

        .startup
START: 
	@Openfile dname, 42h		; open the driver named 'ATMS' for
					; read/write, no_deny access
	jc error			; carry will be set if error
	mov	handle, ax		; o.w. the handle is in ax

	mov	ax, 4401h		; function 4401h: set device data
	mov	bx, handle		; handle of device from Openfile
	mov	dx, 00a0h		; status: it's a device (bit 7)
	int	21h			; and it's in raw/binary mode (bit 5)
					; and do the interrupt

Menu_Loop:

	@ShowStr sMenu			; show the menu
	
	.WHILE 1	

	@ShowStr sPrompt		; show the prompt
	@GetChar			; get character into ax

	push	ax			; save ax for later
	@ShowChar cr,lf			; for formatting
	pop	ax			; now is the time
	
	.IF (al == '0')			; if the user wants to quit

	jmp quit			; then quit

	.ELSEIF (al == '1')		; 1 would be write to device:
					; code is somewhat repeated since other
					; (in lower loop) is different
					
	@ShowStr sInput			; show a friendly input? message
			
	@Read 	outBuf, outLen		; read from keyboard (no handle)

	.BREAK 	.IF (ax==2)		; read from keyboard appends a '$'
					; after the cr. if we have only cr'$'
					; then end the loop
	
	mov	bx, ax			; we'll need to use a base pointer 
	mov	outBuf[bx-2],0		; to set the 'cr' to a 0 (null) so that
					; the driver can handle the string

	@Write	outBuf, outLen, handle  ; write the string to the device, the
					; actual count is not necessary

	.ELSEIF (al == '2')		; 2: read only

	call do_read			; do the read

	.ELSEIF (al == '3')

	mov	bx, handle		; get handle into BX
	mov	ax, 4407h		; function 4407h: Check Dev.Output Stat
	int	21h			; do the interrupt
	.IF CARRY?			; carry set means error
	@ShowStr sQuit			; here you could handle errors
	.ENDIF	

	.ELSE

	jmp 	Input_Loop
	

	.ENDIF				; continue the other loop

	.ENDW
	
;---- loop that reads from keyboard, writes to device, and reads from device
;     until nothing inputed

Input_Loop:
	.WHILE 1			; loop for input

	@ShowStr sInput			; show a friendly input? message
			
	@Read 	outBuf, outLen		; read from keyboard (no handle)

	.IF (ax==2)			; read from keyboard appends a '$'
	jmp Menu_Loop			; after the cr. if we have only cr'$'
	.ENDIF				; then end the loop
	
	mov	bx, ax			; we'll need to use a base pointer 
	mov	outBuf[bx-2],0		; to set the 'cr' to a 0 (null) so that
					; the driver can handle the string

	@Write	outBuf, outLen, handle  ; write the string to the device, the
					; actual count is not necessary

	call 	do_read			; do a read

	.ENDW				; cycle the loop
	
quit:	@ShowStr sQuit  		; quit: print the quit message
	.exit				; and exit

error:  @ShowStr sError			; error: print the error message
	jmp	quit			; and go to quit
	

;----------------------------------------------------------------------------;
; do_read: reads from device, calls int2hex, prints output. since it's used  ;
; in two places, it's a routine						     ;
;----------------------------------------------------------------------------;

do_read PROC
 
	@Read	inBuf, inLen, handle	; read from the device into the inBuf

	mov	bx,ax			; again need to use a base pointer
	mov	inBuf[bx-1], cr		; set the '\0' to a cr
	mov	inBuf[bx],lf		; set a lf after that
	mov	inBuf[bx+1],eom		; and the end-of-message after that

	INVOKE	int2hex,ax,ADDR value   ; int2hex will write to the '0000'

	@ShowStr output			; show the value (followed by inBuf)

	ret
	
do_read ENDP

;----------------------------------------------------------------------------;
; int2hex 								     ;
; Converts a WORD into its hexadecimal representation. 			     ;
; Based on Chapter 4 of the MASM Programmer's guide			     ;
;----------------------------------------------------------------------------;

int2hex	PROC USES ax bx si, number:WORD, string:WORD

	mov	bx, OFFSET hex		; load table address
	mov	si, string

	mov	ax, number		; load value to convert	
	and	ax, 0F000h		; mask out all but the first byte
	shr	ax, 12			; shift
	xlat				; translate
	mov	[si], al		; store

	mov	ax, number		; load value to convert	
	and	ax, 00F00h		; mask out all but the second byte
	shr	ax, 8			; shift
	xlat				; translate
	mov	1[si], al		; store

	mov	ax, number		; load value to convert	
	and	ax, 000F0h		; mask out all but the third byte
	shr	ax, 4			; shift right to get into table index
	xlat				; translate
	mov	2[si], al		; store as second to last byte

	mov	ax, number		; load value to convert	
	and	ax, 0000Fh		; mask out all but the last byte
	xlat				; translate
	mov	3[si], al		; store as last byte in string

	ret

int2hex	ENDP

	END    
