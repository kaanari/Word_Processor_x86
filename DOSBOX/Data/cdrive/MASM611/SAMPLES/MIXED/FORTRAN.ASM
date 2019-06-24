; Power2 routine called by FMAIN.FOR
; Assemble with ML /c FORTRAN.ASM

        .MODEL LARGE, FORTRAN

Power2  PROTO  FORTRAN, factor:FAR PTR SWORD, power:FAR PTR SWORD

        .CODE

Power2  PROC   FORTRAN, factor:FAR PTR SWORD, power:FAR PTR SWORD

        les     bx, factor
        mov     ax, ES:[bx]
        les     bx, power
        mov     cx, ES:[bx]
        shl     ax, cl
        ret
Power2  ENDP
        END
