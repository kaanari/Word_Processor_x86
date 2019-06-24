title translate_buffer subroutine    (translt.asm)

; This subroutine can be called from a C or
; C++ program.

.model small, C

.code
public TranslateBuffer

TranslateBuffer proc near, 
  bufptr:word, count:word, char:byte

	mov  bx,bufptr   ; get offset of buffer
	mov  cx,count    ; counter
	mov  dl,char     ; translate character
	cmp  cx,0        ; is count > 0?
	je   L2

    L1: xor byte ptr [bx],dl
	inc bx
	loop L1

    L2: ret

TranslateBuffer endp

end
