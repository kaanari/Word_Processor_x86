;  Called from main program in CMAIN.C
;  Assemble with ML /c C.ASM

        .MODEL  small, c

Power2  PROTO C factor:SWORD, power:SWORD
        .CODE

Power2  PROC  C factor:SWORD, power:SWORD
        mov     ax, factor    ; Load Arg1 into AX
        mov     cx, power     ; Load Arg2 into CX
        shl     ax, cl        ; AX = AX * (2 to power of CX)
                              ; Leave return value in AX
	ret
Power2  ENDP
	END
