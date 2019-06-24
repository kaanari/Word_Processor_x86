; Writestring procedure (chapter 10)

Writestring proc
    pusha
    push    ds           ; set ES to DS
    pop     es
    mov     di,dx        ; let ES:DI point to the string
    call    Str_length   ; get length of string in AX
    mov     cx,ax        ; CX = number of bytes to write
    mov     ah,40h       ; write to file or device
    mov     bx,1         ; choose standard output
    int     21h          ; call DOS
    popa
    ret
Writestring endp
