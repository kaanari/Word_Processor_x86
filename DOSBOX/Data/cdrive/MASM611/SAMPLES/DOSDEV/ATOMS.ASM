;----------------------------------------------------------------------------;
; ATOMS.ASM:    A simple installable character device driver
;----------------------------------------------------------------------------;
; based on skeleton in The MS-DOS Encyclopedia, (c) 1988 Microsoft Press
;----------------------------------------------------------------------------;

	include dos.inc         ; macros to @ShowStr, etc...
	
	.model  tiny, c
	.386
	
;----------------------------------------------------------------------------;
;                           Typedefs & Prototypes 
;----------------------------------------------------------------------------;

NPBYTE  TYPEDEF NEAR PTR BYTE           ; near pointer to a byte
FPTR    TYPEDEF FAR PTR                 ; far pointer
NPTR    TYPEDEF NEAR PTR                ; near pointer
SEGPTR  TYPEDEF WORD                    ; segment selector
DEVLINK TYPEDEF SDWORD                  ; link to other devices
ATRIBUT TYPEDEF WORD                    ; device attribute word

st_len  PROTO NEAR, :NPBYTE, :SEGPTR    ; gets the length of string into ax
int2hex PROTO NEAR, :WORD, :NPBYTE      ; converts integers to hexadecimal
scan    PROTO NEAR, :NPBYTE, :SEGPTR    ; scans the command line

;----------------------------------------------------------------------------;
;                          Flags & Numeric Equates                
;----------------------------------------------------------------------------;

MaxCmd  EQU     24t             ; max command code for DOS 3.2+
cr      EQU     0Dh             ; carriage return
lf      EQU     0Ah             ; linefeed
eom     EQU     '$'             ; end-of-message signal
space   EQU     20h             ; ascii space
tab     EQU     09h             ; ascii tab

; definition of a Request Header structure so that we can access its elements. 
; this structure is not exhaustive at all: block device use some addresses for
; different purposes, and have data beyond the cmd_seg word.

REQ_HEADER      STRUCT 1t
	lengt   BYTE    ?               ; request header length
	unit    BYTE    ?               ; unit number (for Block Devs. only)
	code    BYTE    ?               ; command code
	stat    WORD    ?               ; status word
	reserv  QWORD   ?               ; reserved for DOS us
	media   BYTE    ?               ; Media ID    (for Block Devs. only)
	xfer    NPTR    ?               ; offset of data buffer
	xseg    SEGPTR  ?               ; segment of data buffer
	UNION
		xcount  WORD    ?       ; count of bytes in request, or
		cmd_off NPTR    ?       ; offset of CONFIG.SYS line
	ENDS
	cmd_seg SEGPTR  ?               ; segment of CONFIG.SYS line
REQ_HEADER      ENDS

; values for the different 'magic numbers' used with Device Drivers

fNEXTLINK   EQU -1              ; word to tell DOS to substitute by address of
				; next device
fCHARDEVICE EQU 8000h           ; bit to define device as a character device
fOPENCLOSE  EQU 0040h           ; bit to indicate that device supports open/close
fDONE       EQU 0100h           ; Status Done bit meaning device is done
fERROR      EQU 8000h           ; Status Error bit meaning error on operation
fWRITE_E    EQU 000Ah           ; Write Fault Error bit
fUNKNOWN_E  EQU 0003h           ; Unknown Command Error bit

; values for the search flags used by Write Routine

fDELETE EQU     2
fINSERT EQU     4
fSEARCH EQU     8

; value for buffer (atom memory) limits

BUFMINIMUM EQU  00400h  ; the minimum will be 1024 bytes
BUFMAXIMUM EQU  07FFFh  ; the maximum will be 32K. It can be less than that,
			; but not greater, because of the signed index for 
			; scasb operations.

;----------------------------------------------------------------------------;
;                             Code Segment                                   
;----------------------------------------------------------------------------;
	.code
	
	org     0               ; drivers should start at address 0000h
	                        ; this will cause a linker warning - ignore it.

Header:                         ; device driver header
	DEVLINK  fNEXTLINK       ; link to next device driver
	ATRIBUT fCHARDEVICE+fOPENCLOSE  ; device attribute word: 
					; char.device+open/close
	NPTR    Strat           ; 'Strat' entry point
	NPTR    Intr            ; 'Intr' entry point
	BYTE    'ATMS     '     ; logical device name (needs to be 8 chars)

;----------------------------------------------------------------------------;
; data variables
;----------------------------------------------------------------------------;

null     BYTE    0              ; dummy to do a quick erase of pAtomValue
pAtomVal NPBYTE  null           ; pointer to value of result of atom search
MemEnd   NPBYTE  AtomList       ; end of used memory:      initially AtomList
MaxMem   NPBYTE  AtomList       ; end of available memory: initially AtomList
lpHeader FPTR    0              ; far pointer to request header
		
;----------------------------------------------------------------------------;
; Dispatch table for the interrupt routine command codes                     
;----------------------------------------------------------------------------;

Dispatch:                       
	NPTR    Init            ;  0 = init driver 
	NPTR    Error           ;  1 = Media Check         (block devices only) 
	NPTR    Error           ;  2 = build BPB           (block devices only)
	NPTR    Error           ;  3 = I/O control read         (not supported)
	NPTR    Read            ;  4 = read (input) from device  (int 21h, 3Fh)
	NPTR    Error           ;  5 = nondestructive read      (not supported)  
	NPTR    Success         ;  6 = ret input status        (int 21h, 4406h) 
	NPTR    Error           ;  7 = flush device input buffer (not supportd)         
	NPTR    Write           ;  8 = write (output) to device  (int 21h, 40h)
	NPTR    Write           ;  9 = write with verify (== write)  (21h, 40h)
	NPTR    OutStat         ; 10 = ret output status       (int 21h, 4407h)
	NPTR    Error           ; 11 = flush output buffer      (not supported) 
	NPTR    Error           ; 12 = I/O control write        (not supported)
	NPTR    Success         ; 13 = device open               (int 21h, 3Dh)
	NPTR    Success         ; 14 = device close              (int 21h, 3Eh)
	NPTR    Error           ; 15 = removable media     (block devices only)
	NPTR    Error           ; 16 = Output until Busy   (mostly for spooler)
	NPTR    Error           ; 17 = not used
	NPTR    Error           ; 18 = not used
	NPTR    Error           ; 19 = generic IOCTL            (not supported)
	NPTR    Error           ; 20 = not used
	NPTR    Error           ; 21 = not used
	NPTR    Error           ; 22 = not used
	NPTR    Error           ; 23 = get logical device  (block devices only)
	NPTR    Error           ; 24 = set logical device  (block devices only)

;----------------------------------------------------------------------------;
; Strategy Routine
;----------------------------------------------------------------------------;
; device driver Strategy routine, called by MS-DOS kernel with
; ES:BX = address of request header
;----------------------------------------------------------------------------;

Strat   PROC FAR
	mov     word ptr cs:[lpHeader], bx      ; save the address of the 
	mov     word ptr cs:[lpHeader+2], es    ; request into 'lpHeader', and                  
	ret                                     ; back to MS-DOS kernel
Strat   ENDP

;----------------------------------------------------------------------------;
; Intr
;----------------------------------------------------------------------------;
; Device driver interrupt routine, called by MS-DOS kernel after call to     
; Strategy routine                                                           
; This routine basically calls the appropiate driver routine to handle the
; requested function. 
; Routines called by Intr expect:
;       ES:DI   will have the address of the request header
;       DS      will be set to cs
; These routines should only affect ax, saving es,di,ds at least
;
; Input: NONE   Output: NONE   -- data is transferred through request header
;
;----------------------------------------------------------------------------;

Intr    PROC FAR
	pusha                   ; save registers
	pushf                   ; save flags
	cld                     ; direction flag: go from low to high address
				
	mov     si, cs          ; make local data addressable
	mov     ds, si          ; by setting ds = cs
			
	les     di, [lpHeader]  ; ES:DI = address of req.header

	ASSUME  di:PTR REQ_HEADER ; to be able to use the REQ_HEADER offsets

	xor     ebx, ebx        ; erase ebx
	mov     bl,es:[di].code ; get EBX = command code (from req.header)
	
	.IF (bx > MaxCmd)                 ; check to make sure we have a valid
		call    Error             ; command code
	.ELSE                             ; else, call command-code routine,  
		call    NPTR PTR Dispatch[2*ebx] ; indexed from Dispatch table
	.ENDIF                            ; (Ebx used to allow scaling factors)

	or      ax, fDONE       ; merge Done bit into status and
	mov     es:[di].stat,ax ; store status into request header
	
	ASSUME  di:NOTHING      ; di will be something else now

	popf                    ; restore registers
	popa                    ; restore flags
	ret                     ; return to MS-DOS kernel
Intr    ENDP

; Command-code routines are called by the Interrupt routine via the dispatch
; table. Each routine should return AX = 0000H if function was completed
; successfully or AX = 8000h + error code if function failed.

;----------------------------------------------------------------------------;
; function 4 = read (input) from device                                      
;----------------------------------------------------------------------------;
; what the function basically does is transfer from the string that pAtomVal 
; points, to the buffer pointed to in the request header. the values have 
; to be loaded into ES:DI and DS:SI for the movsb instruction, and other
; checks are made to account for differences in sizes                                ; 
;----------------------------------------------------------------------------;

Read    PROC NEAR USES ds es di         

	lds     si, [lpHeader]          ; put request header address in DS:SI

	ASSUME  si:PTR REQ_HEADER       ; to use the REQ_HEADER offsets

	mov     cx, [si].xcount         ; load cx with the size of buffer
	mov     es, [si].xseg           ; load es with segment of buffer
	mov     di, [si].xfer           ; load di with offset of buffer

	ASSUME  si:NOTHING              ; si will be something else now
	
	mov     si, cs                  ; load ds with cs again
	mov     ds, si
	mov     si, pAtomVal            ; load si with the string's address

	INVOKE  st_len, si, ds          ; load length of pAtomVal into ax

	.IF     (cx > ax)               ; if cx > ax, then the buffer has space
		mov     bx, ax          ; to hold all the string. bx (used to
		mov     cx, ax          ; return number of chars transferred)
		rep     movsb           ; will hold the string length. We move
					; into cx the length of the string, 
					; and copy the result string into the 
					; buffer, with the 'rep movsb' instruct
	.ELSE
		mov     bx, cx          ; otherwise, bx will be the size of the
		dec     cx              ; the buffer. decrement cx so that we
		rep     movsb           ; leave the last char of the buffer
		xor     ax,ax           ; free to store a 0 to mark the end of
		stosb                   ; the string.
	.ENDIF

	les     di, [lpHeader]          ; re-load the request header

	ASSUME  di:PTR REQ_HEADER       ; to use the REQ_HEADER offsets

	mov     es:[di].xcount, bx      ; store the number of chars transferred

	ASSUME  di:NOTHING              ; di will be something else now

	mov     pAtomVal, offset null   ; set pAtomVal to null:won't read twice
	xor     ax, ax                  ; set status to OK
	ret                             ; return

Read    ENDP

;----------------------------------------------------------------------------;
; output (write) status: if there's still memory, fine. Otherwise, error
;----------------------------------------------------------------------------;

OutStat PROC NEAR       
	mov     ax, MemEnd      ; mov MemEnd into ax   
	inc     ax              ; increment ax (test space for 1 more char)
	.IF (ax < MaxMem)       ; if MemEnd less than MaxMem, we have space,
		xor     ax, ax  ; set status to OK
	.ELSE                   ; otherwise, set the Write Fault error  
		mov     ax, fERROR + fWRITE_E   
	.ENDIF
	ret
OutStat ENDP

;----------------------------------------------------------------------------;
; function 8 = write (output) to device from program
;----------------------------------------------------------------------------;
; big chunk of the program.
;        if string: 'variable', it's a search
;        if string: 'variable=' it's a delete
;        if string: 'variable=value' it's an insert
;----------------------------------------------------------------------------;

Write PROC NEAR USES si es di cx ds     
	LOCAL   func:BYTE, count:WORD, pAtom:NPTR, buf_seg:SEGPTR, buf_off:NPTR
		; func is used to see what function we're doing
		; count is used to store the length of the current atom
		; pAtom is used to point to the start of the current atom
		; buf_seg and buf_off point to the buffer to read from

	ASSUME  di:PTR REQ_HEADER       ; to use the REQ_HEADER offsets

	mov     ax, es:[di].xseg        ; load buf_seg with the buffer segment
	mov     buf_seg, ax     
	mov     cx, es:[di].xfer        ; load buf_off with the buffer offset
	mov     buf_off, cx     

	ASSUME  di:NOTHING              ; di will be something else now

	mov     es, ax                  ; load string into ES:DI
	mov     di, cx
	INVOKE  st_len, di, es          ; load string length into ax, since
					; we're not interested in xcount (for
					; safety reasons) 
	mov     count, ax               ; Store length in count
	mov     cx, ax                  ; and copy to cx


; find if we're doing a search, delete or insert

	mov     bx, cx          ; store the count temporarily 
	mov     al, '='         ; we will look in the string for a '='
	repnz   scasb           ; do the scanning
	.IF (ZERO?)             ; zero will be set if we found a '=',
		xor     al, al  ; in which case we have to see if it's a delete
		scasb           ; or insert: in a delete, the char after the 
				; '=' has to be a 0
		.IF (ZERO?)                     ; if there was a 0 after the =,
			mov     func,fDELETE    ; set the function to delete
		.ELSE
			mov     func,fINSERT    ; else, the function is insert
		.ENDIF
	.ELSE
		mov     func, fSEARCH   ; else (no '=' in string) it's a search
	.ENDIF
	inc     cx              ; cx holds amount of bytes after the '=', so 
	sub     bx, cx          ; by increasing it, cx holds # of bytes after
				; the variable name. If we substract cx from
				; the original length (in bx), bx will have 
				; the length of the variable only 

	.IF     (bx == 0)       ; if the length of the variable is 0 (i.e.      
		xor     ax, ax  ; string= "=....", then finish. set ax to OK
		jmp     wri_e   ; jump to the return place
	.ENDIF

	mov     pAtomVal, offset null   ; set pAtomVal to null. only a search 
					; will change this value, taken care
					; of in the loops below
	
; now go into the memory space and search for a matching variable. we will stop
; if we find a match or a variable that starts with a 0 (meaning no matches)

	mov     si, offset AtomList ; load SI the start of the driver memory
				    ; (pointed to by AtomList, of course)
		
.WHILE 1                        
	mov     pAtom, si       ; save the start of the current atom in memory
	INVOKE  st_len, si, ds  ; length of current atom will be in ax

	.IF (ax <= 1)           ; if the length of the current atom is 1 (never
		mov     di, si  ; can be 0), that means that we reached the end
		mov     si, ds  ; of the driver memory. set ES:DI to DS:SI, the 
		mov     es, si  ; end of memory, 
		.BREAK          ; and break from the loop
	.ENDIF                  

	mov     di, buf_off     ; restore di to the buffer offset
	mov     cx, bx          ; load into the count reg. the variable length  
		
	.IF     (cx >= ax)      ; if the length of the var.name is greater than
		add     si, ax  ; the whole atom length, it's sure not to be a 
		.CONTINUE       ; match. increase si by the length of the 
	.ENDIF                  ; current atom, and continue to next iteration
	
	repe    cmpsb           ; find the first non-matching character between
				; the current atom and the string buffer, for 
				; a maximum count of the length of the name
				
	.IF (!ZERO? || (byte ptr [si]!='='))            
		mov     si,pAtom; if we didn't stop because of two chars not
		add     si,ax   ; matching in the repe, or if the next char
	.CONTINUE               ; is not a '=' (i.e. comspec would match com),
	.ENDIF                  ; increase si by the length of the atom, and
				; go to the next iteration

; at this point we have found a match for the requested variable
				
	.IF     (func==fSEARCH) ; if we're doing a search,              
		inc     si      ; increment si (to skip over the '=')
		mov     pAtomVal,si     ; set pAtomVal to address of the char
	
	.ELSE                   ; else, we're doing a delete or insert: we have
				; to take the current atom out of the memory.
				; we will scan for the chars beyond our current
				; atom. then we shift those chars to a position
				; 'ax' places back. ax still holds the length
				; of the current atom
		mov     si,pAtom; set si to the beginning of the current atom,
		mov     di, ds  ; set ES:DI to be the same as DS:SI, since
		mov     es, di  ; scan uses ES:DI
		mov     di, si  

		add     di, ax  ; set DI to point to the char just after the
		mov     bx, ax  ; current atom. save atom length in bx.
		
		xor     al, al  ; clear al (will be used in the scan)
		mov     cx, -1  ; cx=-1 so that the reps only stop with a match

		.WHILE 1                ; a loop:
			dec     cx      ; decrease cx (because scasb doesn't)
			scasb           ; and test if it's a 0 (to signal end)
			.BREAK .IF ZERO?; break if the character matches
			repne   scasb   ; else repeat scanning (decrements cx)
		.ENDW                   ; until the next 0. then continue loop.

		not     cx      ; if cx=-(length+1), not cx=length (see st_len)

		mov     si,pAtom; get back to the beginning of the atom to
		mov     di, si  ; erase. the source for the movsb will be ahead
		add     si, bx  ; by bx chars (the atom length). 
		rep     movsb   ; move as many chars as left in memory

		dec     di      ; for the insert following, we'll want di to            
				; point to the end of memory. the rep took us
				; one beyond, so we decrement it.

		sub     MemEnd,bx       ; De-allocate the memory used by atom 
	
	.ENDIF                  ; of (func == fSEARCH)

	.BREAK                  ; break from the loop: one match is all we need

.ENDW                           ; actually, no one gets here. they either do a
				; continue or a break.

; if we're doing an insert, we'll do it at the end of the memory space

	.IF (func == fINSERT)   
		mov     ds, buf_seg     ; load DS:SI with the buffer to read from
		mov     si, buf_off
		mov     cx, count       ; cx and bx will have the count
		mov     bx, cx

		add     bx, cs:MemEnd   ; add to bx the end of memory

	; if we have a carry, it means that if bx > MaxMem, we don't have space
	; in our local AtomList. The bx>MaxMem test is not enough because if
	; MemEnd is high and adding cx goes over the segment boundary (starting
	; at 0000h), we wouldn't catch it with a bx >= MaxMem 

		.IF (CARRY? || bx >= cs:MaxMem)                         
			mov     ax, fERROR + fWRITE_E   ; set write fault error
			jmp     wri_e
		.ELSE
			mov     cs:MemEnd , bx          ; set new memory size
		.ENDIF
	
		rep     movsb           ; copy the buffer into our memory

		xor     ax, ax          ; add a null byte to the end of strings, 
		stosb                   ; to signal the end of memory
	.ENDIF  

	xor ax, ax              ; set status to OK

wri_e:  ret                     ; return!

Write ENDP

;----------------------------------------------------------------------------;
; Success: When the only thing the program needs to do is set status to OK 
;----------------------------------------------------------------------------;

Success PROC NEAR
	xor     ax, ax          ; set status to OK
	ret
Success ENDP

;----------------------------------------------------------------------------;
; error: set the status word to error: unknown command                       
;----------------------------------------------------------------------------;
Error   PROC    NEAR            
	mov     ax, fERROR + fUNKNOWN_E  ; error bit + "Unknown command" code
	ret                     
Error   ENDP

;----------------------------------------------------------------------------;
; st_len
; finds the length of the string pointed to by st_off and st_seg and stores it
; in ax. no other registers are affected
;----------------------------------------------------------------------------;

st_len  PROC NEAR USES es di cx, st_off:NPBYTE, st_seg:SEGPTR   
	mov     di, st_off      ; load string into ES:DI, since scas uses       
	mov     es, st_seg      ; those registers
	xor     al, al          ; clear al
	mov     cx, -1          ; by using cx=-1, repnz won't stop until 
	repnz   scasb           ; it finds a match. cx will be -(length-1) 
	not     cx              ; since we use two's complement, not cx=length!
	mov     ax, cx          ; mov length into ax, and
	ret                     ; return
st_len  ENDP    

								
;----------------------------------------------------------------------------;
;****************************************************************************;
;----------------------------------------------------------------------------;
;                                                                            ;
;       BEGINNING OF SPACE TO BE USED AS DRIVER MEMORY                       ;
;       ALL CODE AFTER ATOMLIST WILL BE ERASED BY THE DRIVER'S DATA          ; 
;       OR BY OTHER LOADED DRIVERS                                           ;
;                                                                            ;
;----------------------------------------------------------------------------;
;****************************************************************************;
;----------------------------------------------------------------------------;


;----------------------------------------------------------------------------;
;                    Initialization Data and Code               
; Only needed once, so after the driver is loaded and initialized it releases
; any memory that it won't use. The device allocates memory for its own use
; starting from 'AtomList'.
;----------------------------------------------------------------------------;

AtomList        BYTE 0
Ident           BYTE '*           ATOMS Device Driver             *',lf,cr,eom
Border          BYTE '*********************************************',lf,cr,eom
scan_default    BYTE '*     Using default value of 1024 bytes     *',lf,cr,eom
scan_ignore     BYTE '* Ignoring extra parameters in command line *',lf,cr,eom
scan_minimum    BYTE '* Minimum value of 1024 bytes  will be used *',lf,cr,eom
scan_overflow   BYTE '*  Maximum value of 32K bytes will be used  *',lf,cr,eom
HexDump         BYTE '*   Beginning atoms memory: '
Hex1            BYTE '0000h : '
Hex2            BYTE '0000h   *',cr,lf
		BYTE cr,'*   Ending atoms memory:            '
Hex3            BYTE '0000h   *',cr,lf,eom

;----------------------------------------------------------------------------;
; Init
;----------------------------------------------------------------------------;
; routine called only once to initialize the driver. It shows the startup 
; message, scans the config.sys command line, and tells MS-DOS how much memory
; it needs. Note that under DOS 5.0 the request header also tells you how  
; much memory you could use.
;----------------------------------------------------------------------------;

Init    PROC NEAR USES es di    

	@ShowStr Border                 ; use dos.inc macros to start the init
	@ShowStr Ident                  ; message

	INVOKE  int2hex, cs, ADDR Hex1  ; get starting segment in Hex
	INVOKE  int2hex,MaxMem,ADDR Hex2; get starting offset in Hex
	
	les     di, [lpHeader]          ; allow us to use the request values

	ASSUME  di:PTR REQ_HEADER       ; to use the REQ_HEADER OFFSETS

	; scan the config.sys command line
	INVOKE  scan, es:[di].cmd_off, es:[di].cmd_seg 
	
	add     ax, MemEnd              ; set ax to End of Memory relative to
					; previous end of memory.
	mov     MaxMem, ax              ; store the new value in MaxMem 
	mov     es:[di].xseg,cs         ; tell MS-DOS the end of our used 
	mov     es:[di].xfer,ax         ; memory (the break address)

	ASSUME  di:NOTHING              ; di will be something else now

	INVOKE  int2hex, ax, ADDR Hex3  ; Get ending offset in Hex 
	@ShowStr HexDump                ; print the Hex Dump of Memory bounds
	
	@ShowStr Border                 ; show the end of our initial message
	
	xor     ax, ax                  ; return status OK
	ret
Init    ENDP


;----------------------------------------------------------------------------;
; scan
;----------------------------------------------------------------------------;
; scans the string passed by ms-dos on initialization for the amount of
; memory to allocate to the driver. Since we get a pointer to the string
; after the '=', first scan over the filename and white space, then for the
; ASCII number and turn it into decimal.
; the string we'll get might have some white space (or not) before the device
; name, then the device name, then either the end-of-line (and we'd use the
; default values) or some white space and the end-of-line (same thing) or
; some white space and a number maybe followed by some white space or the end
; of line. If there's something after the number, we'll output the extra
; parameters warning.
;
; returns:    AX    = number of bytes to allocate
;----------------------------------------------------------------------------;

scan    PROC NEAR USES ds si, st_off:NPBYTE, st_seg:SEGPTR
	LOCAL   result          ; result will hold the amount to allocate
	
	mov     result, 0       ; clear the result variable
				
	mov     ds, st_seg      ; lodsb uses DS:SI as the source string 
	mov     si, st_off

	.REPEAT                 ; load from the string into the accumulator
		lodsb           ; while it's white space
	.UNTIL ((al!=tab) && (al!=space))

				; scan until we find a white space or the end
				; of the line (note that we don't test the 1st 
	.REPEAT                 ; character after the spaces: it has to be a 
		lodsb           ; letter o.w. DOS wouldn't load the driver)
	.UNTIL ((al==tab) || (al==space) || (al==cr) || (al==lf))

	.IF ((al==cr) || (al==lf))      ; if we found the end of line, we'll 
		jmp     scan_d          ; use the default values. jump there.
	.ENDIF

	.REPEAT                         ; scan for the next non-white space 
		lodsb
	.UNTIL ((al!=tab) && (al!=space))
	
	.IF ((al==cr) || (al==lf))      ; if we found the end of line, we'll 
		jmp     scan_d          ; use the default values. jump there.
	.ENDIF

	.REPEAT                         ; scan for the decimal numbers: 
		.IF ((al<'0')||(al>'9')); if it's not an ascii decimal number
		jmp     scan_i          ; ignore the parameter, use defaults
		.ENDIF
		cbw                     ; set ax to 0 (by extending al to ax)
		sub     ax, '0'         ; turn ax into a number 0-9
		mov     cx, ax          ; save the number in cx for a while,
		mov     ax, result      ; because ax will be used to multiply
		mov     bx, 10t         ; 'result' by 10, to add a 'digit' to
		mul     bx              ; the previous 'result'
		jc      scan_o          ; if we had an overflow, i.e. result
					; is more than ffffh, then use max.val
					; by jumping to the overflow section.   
		add     ax, cx          ; else, add the units to the multiplied 
		mov     result, ax      ; result, and store it where it goes
		lodsb
	.UNTIL ((al==tab) || (al==space) || (al==cr) || (al==lf))
					; when we find a space, tab, cr, or lf,
					; it's not an error: we've finished
					; the number scan.

	.IF ((al==cr) || (al==lf))      ; if we found the end of line, we'll 
		jmp     scan_d          ; use the result value so far.
	.ENDIF

	.REPEAT                         ; skip over the white space, again
		lodsb                   
	.UNTIL ((al!=tab) && (al!=space))

	.IF ((al==cr) || (al==lf))      ; if we found the end of line, we're 
		jmp     scan_d          ; fine, use the result value.
	.ENDIF
					; otherwise, we scanned something not
					; a space or end-of-line after the 
					; digits, so we drop into the ignore
					; warning display.
					
scan_i: 
					; we found something extra
	@ShowStr scan_ignore,cs         ; show the warning string
					; and drop into scan_d
		
scan_d:                                 
	push    cs                      ; make local data addressable (since
	pop     ds                      ; we rewrote ds in the scanner above)
	.IF (result == 0)               ; if we didn't scan anything into
		@ShowStr scan_default   ; result, show a warning that we will
		mov     ax, BUFMINIMUM  ; use the minimum. Set ax to minimum.
	.ELSEIF (result < BUFMINIMUM)   ; if the result is less than the 
		@ShowStr scan_minimum   ; minimum, display a warning and set 
		mov     ax, BUFMINIMUM  ; the buffer to the minimum
	.ELSEIF (result > BUFMAXIMUM)   ; if result is more than the maximum
		@ShowStr scan_overflow  ; display a message to inform the user
		mov     ax, BUFMAXIMUM  ; and set the buffer to the maximum
	.ELSE                           ; otherwise, result is acceptable
		mov     ax, result      ; set ax to result.
	.ENDIF                  
	ret                             ; return

scan_o:                                 ; overflows (request for >ffffh buffer)
	mov     result, BUFMAXIMUM+1    ; set ax to a value that will cause  
	jmp     scan_d                  ; scan_d to print out an overflow 
					; message and set buffer to 32K

scan    ENDP


;----------------------------------------------------------------------------;
; int2hex 
; Converts a WORD into its hexadecimal representation. 
; Based on Chapter 4 of the MASM Programmer's guide
;----------------------------------------------------------------------------;

; Table of hexadecimal digits
hex     BYTE    '0123456789ABCDEF'

int2hex PROC NEAR USES ax bx si, number:WORD, string:NPBYTE

	mov     bx, OFFSET hex          ; load table address
	mov     si, string

	mov     ax, number              ; load value to convert 
	shr     ax, 12                  ; shift right to get into table index
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si], al                ; store as last byte

	mov     ax, number              ; load value to convert 
	shr     ax, 8                   ; shift right to get into table index
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si+1], al              ; store as third to last byte

	mov     ax, number              ; load value to convert 
	shr     ax, 4                   ; shift right to get into table index
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si+2], al              ; store as second to last byte

	mov     ax, number              ; load value to convert 
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si+3], al              ; store as last byte in string

	ret

int2hex ENDP

	END
