;
; szSearch - An example of 32 bit assembly programming using MASM 6.1
;
; Purpose: search a buffer (rgbSearch) of length cbSearch for the
;          first occurance of szTok (null terminated string).
;
; Method: A variation of the Boyer-Moore method.
;        Determine length of szTok (n)
;        set array of flags (rgfInTok) to true for each character in
;                szTok
;        set current position of search to rgbSearch (pbCur)
;	
;        compare current position to szTok by searching backwards from
;                nth position. When a comparison fails at position
;                (m), check to see if the current character in
;                rgbSearch is in szTok by using rgfInTok. If not, set
;                pbCur to pbCur+(m)+1 and restart compare. If pbCur is
;                reached, increment pbCur and restart compare.
;
;        reset rgfInTok to all 0 for next instantiation of the routine.

.386
.model flat,stdcall

FALSE	EQU	0
TRUE	EQU	NOT FALSE

.data
	; flags buffer - data initialized to FALSE. We will 
	; set the appropriate flags to TRUE during initialization
	; of szSearch and reset them to FALSE before exit.
	rgfInTok	db 256 dup(FALSE);

.code

PBYTE	TYPEDEF PTR BYTE

szSearch PROC PUBLIC USES esi edi, 
	rgbSearch:PBYTE, 
	cbSearch:DWORD, 
	szTok:PBYTE

	; Initialize flags buffer. This tells us if a character is in
	; the search token - Note how we use eax as an index
	; register. This can be done with all extended registers.
	mov	esi,szTok
	xor	eax,eax
	.REPEAT
		lodsb
		mov	BYTE PTR rgfInTok[eax],TRUE
	.UNTIL (!AL)

	; save count of szTok bytes in edx
	mov	edx,esi
	sub	edx,szTok
	dec	edx

	; esi will always point to beginning of szTok
	mov	esi,szTok

	; edi will point to current search position
	; it will also contain the return value
	mov	edi,rgbSearch

	; store pointer to end of rgbSearch in ebx
	mov	ebx,edi
	add	ebx,cbSearch
	sub	ebx,edx

	; initialize ecx with length of szTok	
	mov	ecx,edx
	.WHILE ( ecx != 0 )
		; mov index to current characters to compare
		dec	ecx
		mov	al,[edi+ecx]

		; if the current byte in the buffer doesn't exist in the 
		; search token, increment buffer pointer to current position 
		; +1 and start over. This can skip up to 'edx'
		; bytes and reduce search time.
		.IF  !(rgfInTok[eax])
			add	edi,ecx
			inc	edi
			; initialize ecx with length of szTok
			mov	ecx,edx
		; otherwise, if the characters match, continue on as if
		; we have a matching token
		.ELSEIF (al == [esi+ecx])
		      .CONTINUE
		; finally, if we have searched all szTok  characters, 
		; and land here, we have a mismatch and we increment 
		; our pointer into rgbSearch by one and start over.
		.ELSEIF (!ecx)
			inc	edi
			mov	ecx,edx
		.ENDIF
		
		; verify that we haven't searched beyond the buffer.
		.IF	(edi > ebx) 
			; error value
			mov	edi,0
			.BREAK
		.ENDIF
	.ENDW

	; restore flags in rgfInTok to 0 (for next time).
	mov	esi,szTok
	xor	eax,eax
	.REPEAT
		lodsb
		mov	BYTE PTR rgfInTok[eax],FALSE
	.UNTIL !AL

	; put return value in eax
	mov	eax,edi
	ret
szSearch ENDP

end

