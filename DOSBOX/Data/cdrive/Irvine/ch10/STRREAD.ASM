title Str_read                  (strread.asm)

; Read a sequence of bytes from a file or device,
; stopping when the default delimiter value is
; encountered. Input parameters: DX points to the input
; buffer, BX = file/device handle, CX = maximum number
; of bytes to read.


DOS_READ_HANDLE = 3Fh

.model small
.286
.code
public Str_read
extrn delimiter:byte

Str_read proc
    LOCAL count:word
    pusha
    mov  count,0
L1:
    mov  ah,DOS_READ_HANDLE
    push cx
    mov  cx,1          ; read one byte
    int  21h           ; from file/device
    pop  cx
    jc   L2
    mov  si,dx         ; points to buffer
    mov  al,[si]       ; get current byte
    cmp  al,delimiter  ; delimiter found?
    je   L2            ; yes: quit reading
    inc  count         ; add to counter
    inc  dx            ; next buffer address
    loop L1            ; continue until CX = 0

L2: mov  [si],0        ; insert null byte
    popa
    ret
Str_read endp

end