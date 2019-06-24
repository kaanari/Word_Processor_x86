Title Comparing Strings           (compare.asm)

; Revised version of the strcomp procedure. The old
; one didn't work properly if the source string was
; shorter than the target string. 

.model small
.code
public Str_compare

Str_compare proc
    push  ax
    push  dx
    push  si
    push  di

L1:
    mov  al,[si]
    mov  dl,[di]
    cmp  al,0    ; end of string1?
    jne  L2      ; no
    cmp  dl,0    ; yes: end of string2?
    jne  L2      ; no
    jmp  L5      ; yes, exit with ZF = 1

L2:
    inc  si      ; point to next
    inc  di
    cmp  al,dl   ; chars equal?
    je   L1      ; yes: continue loop    
                 ; no: exit with flags set
L5:
    pop  di
    pop  si
    pop  dx
    pop  ax
    ret
Str_compare endp

end 
