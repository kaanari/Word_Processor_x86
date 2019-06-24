title String Copy procedure           (strcpy.asm)

; Copy a string from a source location to a target
; location. Input parameters: DS:SI points to the 
; source, and ES:DI points to the target.

.model small
.286
.code
public Str_copy
extrn Str_length:proc

Str_copy proc
    pusha
    push   es         ; save ES:DI 
    push   di
    mov    ax,ds      ; get length of source
    mov    es,ax
    mov    di,si
    call   Str_length ; AX = length
    pop    di         ; restore ES:DI
    pop    es 
    inc    ax         ; add 1 for null byte
    mov    cx,ax      ; set CX to length
    cld               ; clear direction to up
    rep    movsb      ; copy the string
    popa
    ret
Str_copy endp

end