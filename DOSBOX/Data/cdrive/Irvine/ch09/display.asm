Title DisplayStr Procedure     (display.asm)

.model small
.code
public DisplayStr

; Display a string pointed to by DX.

displayStr proc  
    push  ax    ; save AX 
    mov   ah,9  ; function: display a string 
    int   21h   ; call DOS
    pop   ax    ; restore AX
    ret
displayStr endp

end       ; no label next to the END directive!
