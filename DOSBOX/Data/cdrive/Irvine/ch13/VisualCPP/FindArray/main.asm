	TITLE	C:\Data\AsmBook3\Samples\ch13\VisualCPP\FindArray\main.cpp
	.386P
include listing.inc
if @Version gt 510
.model FLAT
else
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
_DATA	SEGMENT DWORD USE32 PUBLIC 'DATA'
_DATA	ENDS
CONST	SEGMENT DWORD USE32 PUBLIC 'CONST'
CONST	ENDS
_BSS	SEGMENT DWORD USE32 PUBLIC 'BSS'
_BSS	ENDS
_TLS	SEGMENT DWORD USE32 PUBLIC 'TLS'
_TLS	ENDS
;	COMDAT ??_C@_0CA@INPN@Enter?5an?5integer?5to?5find?5?$FL0?5to?5?$AA@
_DATA	SEGMENT DWORD USE32 PUBLIC 'DATA'
_DATA	ENDS
;	COMDAT ??_C@_02HFBK@?3?5?$AA@
_DATA	SEGMENT DWORD USE32 PUBLIC 'DATA'
_DATA	ENDS
;	COMDAT ??_C@_0BI@EFPF@Your?5number?5was?5found?4?6?$AA@
_DATA	SEGMENT DWORD USE32 PUBLIC 'DATA'
_DATA	ENDS
;	COMDAT ??_C@_0BM@BDGI@Your?5number?5was?5not?5found?4?6?$AA@
_DATA	SEGMENT DWORD USE32 PUBLIC 'DATA'
_DATA	ENDS
;	COMDAT ?lock@ios@@QAAXXZ
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ?unlock@ios@@QAAXXZ
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ?unlockbuf@ios@@QAAXXZ
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ?gptr@streambuf@@IBEPADXZ
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ?setf@ios@@QAEJJJ@Z
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ?rdbuf@ios@@QBEPAVstreambuf@@XZ
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ??4istream@@IAEAAV0@ABV0@@Z
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ??6ostream@@QAEAAV0@P6AAAV0@AAV0@@Z@Z
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ??6ostream@@QAEAAV0@D@Z
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ?flush@@YAAAVostream@@AAV1@@Z
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT ??4iostream@@IAEAAV0@PAVstreambuf@@@Z
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
;	COMDAT _main
_TEXT	SEGMENT PARA USE32 PUBLIC 'CODE'
_TEXT	ENDS
FLAT	GROUP _DATA, CONST, _BSS
	ASSUME	CS: FLAT, DS: FLAT, SS: FLAT
endif
PUBLIC	_main
PUBLIC	??_C@_0CA@INPN@Enter?5an?5integer?5to?5find?5?$FL0?5to?5?$AA@ ; `string'
PUBLIC	??_C@_02HFBK@?3?5?$AA@				; `string'
PUBLIC	??_C@_0BI@EFPF@Your?5number?5was?5found?4?6?$AA@ ; `string'
PUBLIC	??_C@_0BM@BDGI@Your?5number?5was?5not?5found?4?6?$AA@ ; `string'
EXTRN	?cin@@3Vistream_withassign@@A:BYTE		; cin
EXTRN	??6ostream@@QAEAAV0@PBD@Z:NEAR			; ostream::operator<<
EXTRN	??6ostream@@QAEAAV0@H@Z:NEAR			; ostream::operator<<
EXTRN	?cout@@3Vostream_withassign@@A:BYTE		; cout
EXTRN	_rand:NEAR
EXTRN	_FindArray2:NEAR
EXTRN	__chkstk:NEAR
EXTRN	??5istream@@QAEAAV0@AAJ@Z:NEAR			; istream::operator>>
;	COMDAT ??_C@_0CA@INPN@Enter?5an?5integer?5to?5find?5?$FL0?5to?5?$AA@
; File C:\Data\AsmBook3\Samples\ch13\VisualCPP\FindArray\main.cpp
_DATA	SEGMENT
??_C@_0CA@INPN@Enter?5an?5integer?5to?5find?5?$FL0?5to?5?$AA@ DB 'Enter a'
	DB	'n integer to find [0 to ', 00H		; `string'
_DATA	ENDS
;	COMDAT ??_C@_02HFBK@?3?5?$AA@
_DATA	SEGMENT
??_C@_02HFBK@?3?5?$AA@ DB ': ', 00H			; `string'
_DATA	ENDS
;	COMDAT ??_C@_0BI@EFPF@Your?5number?5was?5found?4?6?$AA@
_DATA	SEGMENT
??_C@_0BI@EFPF@Your?5number?5was?5found?4?6?$AA@ DB 'Your number was foun'
	DB	'd.', 0aH, 00H				; `string'
_DATA	ENDS
;	COMDAT ??_C@_0BM@BDGI@Your?5number?5was?5not?5found?4?6?$AA@
_DATA	SEGMENT
??_C@_0BM@BDGI@Your?5number?5was?5not?5found?4?6?$AA@ DB 'Your number was'
	DB	' not found.', 0aH, 00H			; `string'
_DATA	ENDS
;	COMDAT _main
_TEXT	SEGMENT
_array$ = -40000
_searchVal$ = -40004
_main	PROC NEAR					; COMDAT
; File C:\Data\AsmBook3\Samples\ch13\VisualCPP\FindArray\main.cpp
; Line 7
	mov	eax, 40004				; 00009c44H
	call	__chkstk
	push	esi
	push	edi
; Line 12
	lea	esi, DWORD PTR _array$[esp+40012]
	mov	edi, 10000				; 00002710H
$L1345:
; Line 13
	call	_rand
	mov	DWORD PTR [esi], eax
	add	esi, 4
	dec	edi
	jne	SHORT $L1345
; Line 17
	push	OFFSET FLAT:??_C@_02HFBK@?3?5?$AA@	; `string'
	push	32767					; 00007fffH
	push	OFFSET FLAT:??_C@_0CA@INPN@Enter?5an?5integer?5to?5find?5?$FL0?5to?5?$AA@ ; `string'
	mov	ecx, OFFSET FLAT:?cout@@3Vostream_withassign@@A
	call	??6ostream@@QAEAAV0@PBD@Z		; ostream::operator<<
	mov	ecx, eax
	call	??6ostream@@QAEAAV0@H@Z			; ostream::operator<<
	mov	ecx, eax
	call	??6ostream@@QAEAAV0@PBD@Z		; ostream::operator<<
; Line 18
	lea	eax, DWORD PTR _searchVal$[esp+40012]
	mov	ecx, OFFSET FLAT:?cin@@3Vistream_withassign@@A
	push	eax
	call	??5istream@@QAEAAV0@AAJ@Z		; istream::operator>>
; Line 20
	mov	edx, DWORD PTR _searchVal$[esp+40012]
	lea	ecx, DWORD PTR _array$[esp+40012]
	push	10000					; 00002710H
	push	ecx
	push	edx
	call	_FindArray2
	add	esp, 12					; 0000000cH
	test	al, al
	je	SHORT $L1351
; Line 21
	push	OFFSET FLAT:??_C@_0BI@EFPF@Your?5number?5was?5found?4?6?$AA@ ; `string'
; Line 22
	jmp	SHORT $L1376
$L1351:
; Line 23
	push	OFFSET FLAT:??_C@_0BM@BDGI@Your?5number?5was?5not?5found?4?6?$AA@ ; `string'
$L1376:
	mov	ecx, OFFSET FLAT:?cout@@3Vostream_withassign@@A
	call	??6ostream@@QAEAAV0@PBD@Z		; ostream::operator<<
; Line 28
	pop	edi
	xor	eax, eax
	pop	esi
	add	esp, 40004				; 00009c44H
	ret	0
_main	ENDP
_TEXT	ENDS
END
