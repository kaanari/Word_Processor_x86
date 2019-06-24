; Include file for example DLL

DATA_BASE	EQU	400h		; Base address of BIOS data area
EQUIP		EQU	10h		; Offset to equipment list
KB		EQU	17h		; Offset to keybord status word
VIDMODE		EQU	49h		; Offset to video mode byte
DATA_LIM	EQU	VIDMODE		; Read limit for BIOS data area
ROM_BASE	EQU	0FFFF0h		; Base address of ROM release date
ROM_LIM		EQU	10h		; Read limit for release date
DATE_OFF	EQU	5		; Release date offset from seg FFFFh

FRENCH		EQU	'RF'		; Reverse 1st two letters (FRE)
SPANISH		EQU	'SE'		; (ESP)
GERMAN		EQU	'ED'		; (DEU)
ITALIAN		EQU	'TI'		; (ITA)
SWEDISH		EQU	'VS'		; (SVE)

STRZ		TYPEDEF	BYTE		; Null-terminated string
WINAPI		TEXTEQU	<FAR PASCAL>	; For Win API prototypes

; Prolog and epilog for DLL exported far functions

Prolog	MACRO
	mov	ax, ds			; Must be 1st, since Windows overwrites
	nop				; Placeholder for 3rd byte
	inc	bp			; Push odd BP.  Not required, but
	push	bp			;   allows CodeView to recognize stack
	mov	bp, sp			; Set up stack frame to access params
	push	ds			; Save DS
	mov	ds, ax			; Point DS to DLL's data segment
	ENDM

Epilog	MACRO
	pop	ds			; Recover original DS
	pop	bp			;   and BP+1
	dec	bp			; Reset to original BP
	ENDM

; Exported routines
GetSysTime	PROTO	FAR PASCAL
GetSysDate	PROTO	FAR PASCAL
GetSysInfo	PROTO	FAR PASCAL

; Structures
QUALTIME	STRUCT				; Qualified time hh:mm:ss
  wHour		WORD	?			; Hour
  cSep1		BYTE	?			; Separator character
  wMin		WORD	?			; Minute
  cSep2		BYTE	?			; Separator character
  wSec		WORD	?			; Seconds
  cPad		BYTE	' '			; Padded space
  szTail	BYTE	'xx'			; '  ', 'am', or 'pm'
  cZero		BYTE	0			; Terminate with null
QUALTIME	ENDS

SYSINFO		STRUCT				; Current system information
  szWinVer	STRZ	'xx.xx', 0		; Windows version in ASCIIZ
  szDOSVer	STRZ	'xx.xx', 0		; DOS version in ASCIIZ
  bCoproc	BYTE	?			; Math coprocessor installed?
  cFloppy	BYTE	?			; Number of floppy disk drives
  wKbStatus	WORD	?			; Keyboard status
  cVidMode	BYTE	?			; Current video mode
  cProcType	BYTE	?			; Processor type (0,1,2,3,etc.)
  szROM		STRZ	9 DUP (0)		; ROM release date
SYSINFO		ENDS
