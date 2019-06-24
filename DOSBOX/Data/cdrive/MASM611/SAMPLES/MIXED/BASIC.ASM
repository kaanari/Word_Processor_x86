; Called by BASMAIN.BAS
; Assemble with ML /c BASIC.ASM

        .MODEL  medium

Power2  PROTO   PASCAL, Factor:PTR WORD, Power:PTR WORD
        .CODE
Power2  PROC    PASCAL, Factor:PTR WORD, Power:PTR WORD

        mov     bx, WORD PTR Factor   ; Load Factor into
        mov     ax, [bx]              ;  AX
        mov     bx, WORD PTR Power    ; Load Power into
        mov     cx, [bx]              ;   CX
        shl     ax, cl                ; AX = AX * (2 to power of CX)
                
        ret
Power2  ENDP     

        END
