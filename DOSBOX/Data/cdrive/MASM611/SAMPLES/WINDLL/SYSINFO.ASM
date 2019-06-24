;* SYSINFO.ASM
;*
;* Assembly-language source for example DLL.  SYSINFO.DLL contains three
;* library routines, which any Windows process can call:
;*
;*	GetSysTime	Returns a ptr to a string "hh:mm:ss xx" where
;*			hh:mm:ss = hour:min:sec.  If country not USA,
;*			string is 24-hour time.  Otherwise, string is
;*			12-hour American format, with xx = "am" or "pm".
;*
;*	GetSysDate	Returns a ptr to a string "day, month xx, xxxx".
;*			day and month are translated to one of six
;*			different languages:  English, French, Spanish,
;*			German, Italian, or Swedish.
;*
;*	GetSysInfo	Returns a ptr to a structure containing various
;*			data from the the BIOS data areas.


.MODEL	medium, pascal, farstack
.286

INCLUDE dll.inc
INCLUDE	win.inc

.DATA
TaskHead	BYTE	16 DUP(0)		; 1st paragraph reserved
						;   for Windows task header

DayEng		STRZ	'Sunday', 0,	   'Monday', 0,		'Tuesday', 0
		STRZ	'Wednesday', 0,	   'Thursday', 0,	'Friday', 0
		STRZ	'Saturday', 0

DayFre		STRZ	'dimanche', 0,	   'lundi', 0,		'mardi', 0
		STRZ	'mercredi', 0,	   'jeudi', 0,		'vendredi', 0
		STRZ	'samedi', 0

DaySpa		STRZ	'domingo', 0,	   'lunes', 0,		'martes', 0
		STRZ	'miÇrcoles', 0,	   'jueves', 0,		'viernes', 0
		STRZ	's†bado', 0

DayGer		STRZ	'Sonntag', 0,	   'Montag', 0,		'Dienstag', 0
		STRZ	'Mittwoch', 0,	   'Donnerstag', 0,	'Freitag', 0
		STRZ	'Samstag', 0

DayIta		STRZ	'domenica', 0,	   'lunedç', 0,		'martedç', 0
		STRZ	'mercoledç', 0,	   'giovedç', 0,	'venerdç', 0
		STRZ	'sabato', 0

DaySwe		STRZ	'sîndag', 0,	   'mandag', 0,		'tisdag', 0
		STRZ	'onsdag', 0,	   'torsdag', 0,	'fredag', 0
		STRZ	'lîrdag', 0

MonEng		STRZ	'January', 0,	   'February', 0,	'March', 0
		STRZ	'April', 0,	   'May', 0,		'June', 0
		STRZ	'July', 0,	   'August', 0,		'September', 0
		STRZ	'October', 0,	   'November', 0,	'December', 0

MonFre		STRZ	'janvier', 0,	   'fevrier', 0,	'mars', 0
		STRZ	'avril', 0,	   'mai', 0,		'juin', 0
		STRZ	'juillet', 0,	   'aoñt', 0,		'septembre', 0
		STRZ	'octobre', 0,	   'novembre', 0,	'dÇcembre', 0

MonSpa		STRZ	'enero', 0,	   'febrero', 0,	'marzo', 0
		STRZ	'abril', 0,	   'mayo', 0,		'junio', 0
		STRZ	'julio', 0,	   'agosto', 0,		'septiembre', 0
		STRZ	'octubre', 0,	   'noviembre', 0,	'diciembre', 0

MonGer		STRZ	'Januar', 0,	   'Februar', 0,	'MÑrz', 0
		STRZ	'April', 0,	   'Mai', 0,		'Juni', 0
		STRZ	'Juli', 0,	   'August', 0,		'September', 0
		STRZ	'Oktober', 0,	   'November', 0,	'Dezember', 0

MonIta		STRZ	'gennaio', 0,	   'febbraio', 0,	'marzo', 0
		STRZ	'aprile', 0,	   'maggio', 0,		'giugno', 0
		STRZ	'luglio', 0,	   'agosto', 0,		'septtembre', 0
		STRZ	'ottobre', 0,	   'nobembre', 0,	'dicembre', 0

MonSwe		STRZ	'januari', 0,	   'februari', 0,	'mars', 0
		STRZ	'april', 0,	   'maj', 0,		'juni', 0
		STRZ	'juli', 0,	   'augusti', 0,	'september', 0
		STRZ	'oktober', 0,	   'november', 0,	'december', 0

Sect		STRZ	'intl', 0		; Section in WIN.INI file
Ent1		STRZ	'sLanguage', 0		; Windows language
Ent2		STRZ	'sTime', 0		; Windows time separator
Language	STRZ	'ENU', 0		; Default language (Amer Eng)
Separator	STRZ	':', 0			; Default time separator

sys		SYSINFO<>			; System info structure
time		QUALTIME<>			; Time structure hour:min:sec
Date		STRZ	32 DUP(0)		; Full date string

; indx = array index for days and months:
;	0 = English		4 = Spanish		 8 = Italian
;	2 = French		6 = German		10 = Swedish
indx		WORD	0
days		NPSTR	DayEng, DayFre, DaySpa, DayGer, DayIta, DaySwe
months		NPSTR	MonEng, MonFre, MonSpa, MonGer, MonIta, MonSwe

; Array of processor types
procs		BYTE	WF_CPU086, WF_CPU186, WF_CPU286, WF_CPU386, WF_CPU486


.CODE
LibMain		PROC	FAR PASCAL

;
; Get international language
;
		INVOKE	GetProfileString, ADDR Sect, ADDR Ent1, ADDR Language,
					  ADDR Language, SIZEOF Language
;
; Get time separator char
;
		INVOKE	GetProfileString, ADDR Sect, ADDR Ent2, ADDR Separator,
					  ADDR Separator, SIZEOF Separator

		mov	al, Separator		; AL = time separator char
		mov	time.cSep1, al		; Separator char is same
		mov	time.cSep2, al		;   between hh:mm and mm:ss
		sub	bx, bx			; BX = language index
		mov	ax, WORD PTR Language	; AX = 1st two letters of lang
		and	ax, 5F5Fh		; Capitalize both letters
		.IF ( ax == FRENCH )
		mov	bl, 2			; If French, index = 2
		.ENDIF
		.IF ( ax == SPANISH )
		mov	bl, 4			; If Spanish, index = 4
		.ENDIF
		.IF ( ax == GERMAN )
		mov	bl, 6			; If German, index = 6
		.ENDIF
		.IF ( ax == ITALIAN )
		mov	bl, 8			; If Italian, index = 8
		.ENDIF
		.IF ( ax == SWEDISH )
		mov	bl, 10			; If Swedish, index = 10
		.ENDIF

		mov	indx, bx		; Initialize indx
		ret				; Return to LibEntry

LibMain		ENDP



; Internal (non-exported) routines
;---------------------------------

;* IntToAsc
;*
;* Converts integer in AL to ASCII digits.  Reverses digits on exit,
;* so '12' becomes '21'.  This allows caller to write the result to
;* memory as a word value.
;*
;* Entry:	AX	= binary digit 0-9,999
;* Return:	DX:AX	= ASCII chars

IntToAsc	PROC NEAR USES cx
		cwd			; Zero DX register
		mov	cx, 100		; Divide AX by 100, yields
		div	cx		;   AX = quotient, DX = remainder
		aam			; Make digits unpacked BCD
		or	ax, '00'	; Convert to ASCII digits
		xchg	ah, al		; Reverse digits to make big-ended
		xchg	dx, ax		; Do same thing for DX
		aam
		or	ax, '00'
		xchg	ah, al		; Reverse digits to make big-ended
		ret			; Return DX:AX = ASCII number
IntToAsc	ENDP



; Exported library routines
;--------------------------
OPTION	PROLOGUE:None			; Disable automatic prolog/epilog
OPTION	EPILOGUE:None			;   generation for DLL routines

;* GetSysTime
;*
;* Places qualified time in 12-byte ASCIIZ string "hh:mm:ss xx", where
;* hh:mm:ss = hour:min:sec.  If indx > 0 (indicating country not USA),
;* string is 24-hour international time.  Otherwise, string is 12-hour
;* American format, and xx = "am" or "pm".
;*
;* Entry:	none
;* Return:	DX:AX = far pointer to ASCIIZ time string

GetSysTime	PROC	FAR EXPORT

		Prolog				; Prologue macro
		mov	ah, 2Ch			; DOS service 2Ch
		call	DOS3Call		; Get System Time
		mov	ax, '  '		; Assume xx = blank
		.IF (!indx)			; If language = English,
		mov	ax, 'ma'		;   assume xx = 'am'
		.IF (ch >= 12)			; If afternoon, and if after
		.IF	!zero?			;   1:00 pm, reset hour
		sub	ch, 12			;   in CH to 12-hour clock
		.ENDIF
		mov	al, 'p'			; Also set xx = 'pm'
		.ENDIF
		.ENDIF
		push	dx			; Save seconds
		mov	WORD PTR time.szTail, ax; Place 'am', 'pm', or blank
		mov	al, ch
		cbw				; AX = hour
		call	IntToAsc		; Convert to ASCII chars
		mov	time.wHour, ax		;   and place in structure
		mov	al, cl
		cbw				; AX = minute
		call	IntToAsc		; Convert to ASCII chars
		mov	time.wMin, ax		;   and place in structure
		pop	ax			; AH = seconds
		mov	al, ah
		cbw				; AX = seconds
		call	IntToAsc		; Convert to ASCII chars
		mov	time.wSec, ax		;   and place in structure

		mov	dx, ds			; Return far ptr to time
		mov	ax, OFFSET time		;   string in DX:AX
		Epilog				; Epilogue macro
		ret

GetSysTime	ENDP



;* GetSysDate
;*
;* Creates qualified date in English, French, Spanish, German, Italian, 
;* or Swedish.  For the sake of simplicity, English is assumed for other 
;* countries, though the code can be easily extended to include other 
;* languages.
;*
;* Entry:	none
;* Return:	DX:AX = far pointer to ASCIIZ date string

GetSysDate	PROC	FAR EXPORT USES si di

		Prolog				; Prologue macro
		mov	ah, 2Ah			; DOS service 2Ah
		call	DOS3Call		; Get System Date
		push	cx			; Save year
		push	ds
		pop	es			; ES = DS
		mov	bx, indx		; BX = language index
		mov	di, days[bx]		; ES:DI points to array
		cbw				;    of ASCIIZ strings
		xchg	ah, al			; AH = day of week (0-7)
						; AL = 0
		.WHILE	( ah )			; Count AH strings to find
		mov	cl, 255			;   current day
	repne	scasb				; Scan for end of string
		dec	ah			; Decrement counter
		.ENDW

		mov	si, di			; DS:SI points to day string
		mov	di, OFFSET Date		; ES:DI points to buffer
		.REPEAT
		lodsb				; Copy ASCIIZ day to
		stosb				;   buffer until null
		.UNTIL	( !al )			;   terminator

		dec	di			; ES:DI points to end of day
		mov	ax, ' ,'		; Follow day with ', '
		stosw
		mov	si, di			; Save current buffer position
		mov	di, months[bx]		; ES:DI points to array
		sub	al, al			;   of ASCIIZ strings
		dec	dh			; DH = number of month:

		.WHILE	( dh )			;   0=Jan, 1=Feb, etc.
		mov	cl, 255
	repne	scasb				; Scan for end of string
		dec	dh			; Decrement counter
		.ENDW

		xchg	si, di			; DS:SI points to month string
		.REPEAT				; ES:DI points to buffer
		lodsb				; Copy ASCIIZ month to
		stosb				;   buffer until null
		.UNTIL	( !al )			;   terminator

		mov	BYTE PTR [di-1], ' '	; Follow month with space
		mov	al, dl
		cbw				; AX = day of month
		call	IntToAsc		; Convert to ASCII
		stosw				; Copy after month
		mov	ax, ' ,'		;   and follow it with
		stosw				;   comma
		pop	ax			; AX = year (1980 to 2099)
		call	IntToAsc		; Convert to ASCII
		xchg	dx, ax			; AX = 1st two digits ('19')
		stosw				; Write to string
		xchg	dx, ax			; AX = last two digits
		stosw				; Write to string
		sub	al, al			; Terminate string with null
		stosb				;   to make ASCIIZ

		mov	dx, ds			; Return far ptr to Date
		mov	ax, OFFSET Date		;   string in DX:AX
		Epilog				; Epilogue macro
		ret

GetSysDate	ENDP



;* GetSysInfo
;*
;* Place the following system information in structure type SysInfo:
;*
;*	* Windows version
;*	* DOS version
;*	* keyboard status (see Help, Interrupt 16h, for keyboard flags)
;*	* number of floppy disk drives
;*	* math coprocessor installed?
;*	* video mode
;*	* processor type:	0 = 8086/88
;*				1 = 80186
;*				2 = 80286
;*				3 = 80386
;*				4 = 80486
;*	* ROM release date
;*
;* Entry:	none
;* Return:	DX:AX = far pointer to structure

GetSysInfo	PROC	FAR EXPORT

		Prolog				; Prologue macro

;
; Create ASCIIZ strings in structure with version numbers
; of Windows and DOS -- '03.10' and '05.00', for example
;
		INVOKE	GetVersion
		mov	bx, dx			; Save DOS version
		push	ax
		cbw				; AX = major Win version
		call	IntToAsc		; Make it ASCII
		mov	WORD PTR sys.szWinVer, ax
		pop	ax			; Recover minor version
		xchg	ah, al
		cbw				; AX = minor Win version
		call	IntToAsc		; Make it ASCII
		mov	WORD PTR sys.szWinVer[3], ax
		mov	ax, bx			; Recover DOS version
		xchg	ah, al
		cbw				; AX = major DOS version
		call	IntToAsc		; Make it ASCII
		mov	WORD PTR sys.szDOSVer, ax
		mov	ax, bx
		cbw				; AX = minor DOS version
		call	IntToAsc		; Make it ASCII
		mov	WORD PTR sys.szDOSVer[3], ax

;
; Read various information from BIOS data area at segment 40h
;
		INVOKE	AllocSelector, ds	; Get new selector
		INVOKE	SetSelectorBase,	; Set it to BIOS data
			ax, DATA_BASE		;   area at 40:0000
		push	ax			; Save selector
		INVOKE	SetSelectorLimit,
			ax, DATA_LIM		; Set read limit 
		pop	es			; ES points to data
		mov	al, es:[EQUIP]		; Get equipment list
		and	al, 10y			; Mask bit 2
		shr	al, 1			; AL = TRUE if math
		mov	sys.bCoproc, al		;   coprocessor found
		mov	al, es:[EQUIP]		; Get list again
		and	al, 11000000y		; Mask bits 6-7
		rol	al, 1			; Rotate bits 6-7
		rol	al, 1			;   to bits 0-1
		inc	ax			; AL = number of	
		mov	sys.cFloppy, al		;   floppy disk drives
		mov	ax, es:[KB]		; AX = keyboard status
		mov	sys.wKbStatus, ax	; Keep it
		mov	al, es:[VIDMODE]	; AL = current vid mode
		mov	sys.cVidMode, al	; Keep it
		INVOKE	FreeSelector, es	; Free selector

;
; Get processor type:  0=8086, 1=80186, 2=80286, etc.
;
		INVOKE	GetWinFlags		; AL = return flags
		mov	ah, -1			; Initialize processor type
		mov	bx, -1			; Initialize array index
		mov	cx, LENGTHOF procs	; CX = number of elements

@@:		inc	ah			; Type = 0 for 8086, 1 for 186,
		inc	bx			;   2 for 286, etc
		test	al, procs[bx]		; Test return flags
		loopz	@B			; Loop until bits match
		mov	sys.cProcType, ah	; Store processor type

;
; Read ROM release date from address FFFF:0005
;
		INVOKE	AllocSelector, ds	; Get new selector
		INVOKE	SetSelectorBase,	; Set it to start of
			ax, ROM_BASE		;   segment FFFF:0000
		push	ds			; Save local data segment addr
		push	ax			; Save new selector
		INVOKE	SetSelectorLimit,
			ax, ROM_LIM		; Set read limit
		push	ds
		pop	es			; Point ES:DI to hold buffer
		mov	di, OFFSET sys.szROM	;   (target) in structure
		pop	ds			; Point DS:SI to source
		mov	si, DATE_OFF		;   at FFFF:0005
		mov	cx, LENGTHOF sys.szROM-1; CX = string length
	rep	movsb				; Copy release date to buffer
		mov	ax, ds			; DS will be invalid when freed,
		pop	ds			;    so restore orig DS now
		INVOKE	FreeSelector, ax	; Free allocated selector

		mov	dx, ds			; Return far pointer
		mov	ax, OFFSET sys		;   to structure in DX:AX
		Epilog				; Epilogue macro
		ret

GetSysInfo	ENDP



;* Place WEP procedure in its own code segment, set as PRELOAD FIXED
;* in the SYSINFO.DEF module-definition file
;*
CODE2	SEGMENT WORD 'CODE'
	ASSUME	cs:CODE2

;* WEP
;*
;* Windows Exit Procedure called by Windows before unloading.
;* 
;* Entry:	wExitCode = 0 if unloading SYSINFO
;*			  = 1 if Windows shutting down
;* Return:	AX	  = 1 to signal okay

WEP		PROC	FAR EXPORT

		Prolog
		mov	ax, TRUE		; Return AX = 1
		Epilog
		ret

WEP		ENDP

CODE2	ENDS

END
