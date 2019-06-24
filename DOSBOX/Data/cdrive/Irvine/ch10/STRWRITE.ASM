title Str_write Procedure            (strwrite.asm)

; Write a null-terminated string to a file or device.
; Input parameters: DS:DX points to the string, and
; BX = file/device handle (console = 1).

public Str_write
extrn Str_length:proc

DOS_WRITE_HANDLE = 40h
.model small
.286
.code

Str_write proc
    pusha
    
    push  ds   ; copy ds:dx to es:di
    push  dx
    pop   di
    pop   es
    call  Str_length  ; get length of string
    mov   cx,ax       ; the string length
    mov   ah,DOS_WRITE_HANDLE
    int   21h

    popa
    ret  
Str_write endp

end