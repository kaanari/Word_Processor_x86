title Str_ucase Procedure            (strucase.asm)

; Convert a string to all uppercase letters. 
; Input: DS:SI points to the string.

public Str_ucase

.model small
.code
Str_ucase proc
    push  ax
    push  si

L1: mov   al,[si]
    cmp   al,0
    je    L2
    and   al,11011111b
    inc   si
    jmp   L1

L2: pop   si
    pop   di
    ret  
Str_ucase endp

end