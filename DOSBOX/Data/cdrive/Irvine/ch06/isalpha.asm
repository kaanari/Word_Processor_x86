title Test Alphabetic Input         (ISALPHA.ASM)

; This program reads and displays characters 
; until a non-alphabetic character is entered.

.model small
.stack 100h
.code 
main proc
    mov  ax,@data
    mov  ds,ax

L1: mov  ah,1       ; input a character
    int  21h        ; AL = character
    call Isalpha    ; test value in AL
    jnz  exit       ; exit if not alphabetic
    jmp  L1         ; continue loop

exit: 
    mov   ax,4C00h  ; return to DOS
    int   21h
main endp

; Isalpha sets ZF = 1 if the character
; in AL is alphabetic.

Isalpha proc
    push ax           ; save AX
    and  al,11011111b ; clear bit 5
    cmp  al,'A'       ; check 'A'..'Z' range
    jb   B1
    cmp  al,'Z'
    ja   B1
    test ax,0         ; ZF = 1 
B1: pop ax            ; restore AX
    ret
Isalpha endp

end main

