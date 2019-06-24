title Str_getline              (strgetl.asm)

; Read a sequence of bytes from a file or device,
; stopping when the end of line (0Dh,0Ah) is
; encountered. Input parameters: DX points to the input
; buffer, BX = file/device handle, CX = maximum number
; of bytes to read. Return value: AX = number of 
; bytes actualy read, not counting the end of line.

DOS_READ_HANDLE = 3Fh

.model small
.286
.code
public Str_getline

Str_getline proc
    LOCAL count:word
    pusha
    mov  count,0
L1:
    mov  ah,DOS_READ_HANDLE
    push cx            ; save loop count
    mov  cx,1          ; read one byte
    int  21h           ; from file/device
    pop  cx            ; restore loop count
    jc   L2
    mov  si,dx         ; points to buffer
    mov  al,[si]       ; get current byte
    cmp  al,0Dh        ; carriage return found?
    jne  L2            ; no: continue reading   
    mov  ah,DOS_READ_HANDLE ; yes: read a byte
    int  21h           ; and discard linefeed
    mov  [si],0        ; insert null byte
    jmp  L3            ; and exit
    
L2: inc  count         ; add to counter
    inc  dx            ; next buffer address
    loop L1            ; continue until CX = 0

L3: popa
    mov  ax,count      ; character count
    ret
Str_getline endp

end