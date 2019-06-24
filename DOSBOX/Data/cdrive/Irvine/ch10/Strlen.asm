title String Length                        (strlen.asm)

; Calculate the length of a string. Input parameters:
; ES:DI points to the string. Output: AX = length.

.model small
.code
public Str_length

Str_length proc
    push   cx
    push   di         ; save pointer to string
    mov    cx,0FFFFh  ; set CX to maximum word value
    mov    al,0       ; scan for null byte
    cld               ; direction = up
    repnz  scasb      ; compare AL to ES:[DI]
    dec    di         ; back up one position
    mov    ax,di      ; get ending pointer
    pop    di         ; retrieve starting pointer
    sub    ax,di      ; subtract start from end
    pop    cx
    ret               ; AX = string length
Str_length endp

end