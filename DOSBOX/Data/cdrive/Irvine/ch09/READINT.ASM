title READINT Procedure

.model small
.386
public readint
.code

; Readint ---------------------------------------------
;
; Reads a signed decimal number from standard input, in
; the range -32768 to +32767. Skips leading spaces. 
; Returns the 16-bit binary value of the number in AX. 
; No other registers are changed. 
;--------------------------------------------------------

.data
sign          dw  ?          
inputarea     db  10,0,10 dup(' ')    ; up to 9 digits
overflow_msg  db  0dh,0ah," <integer overflow> $"

.code
Readint proc
    push  ebx
    push  ecx
    push  edx
    push  si
    mov   dx,offset inputarea   ; input the string
    mov   ah,0Ah
    int   21h
    mov   si,offset inputarea+2
    mov   cx,0            ; scan for leading spaces
    mov   cl,inputarea+1  ; get number of chars entered
    or    cx,cx           ; any chars entered?
    jnz   A1              ; yes: continue
    mov   ax,0            ; no: set value to zero
    jmp   A8              ; exit procedure

A1: mov   al,[si]         ; get a character from buffer
    cmp   al,' '          ; space character found?
    jnz   A2              ; no: check for a sign
    inc   si              ; yes: point to next char
    loop  A1             
    jcxz  A8              ; quit if all spaces

A2: mov   sign,1          ; assume number is positive
    cmp   al,'-'          ; minus sign found?
    jnz   A3              ; no: look for plus sign
    mov   sign,-1         ; yes: sign is negative
    inc   si              ; point to next char
    jmp   A4        

A3: cmp   al,'+'          ; plus sign found?
    jnz   A4              ; no: must be a digit
    inc   si              ; yes: skip over the sign

A4: mov   ax,0            ; clear accumulator
    mov   bx,10           ; BX is the multiplier

A5: mov   dl,[si]         ; get character from buffer
    cmp   dl,'0'          ; character < '0'?
    jl    A8              ; yes: resolve sign and exit
    cmp   dl,'9'          ; character > '9'?
    jg    A8              ; yes: resolve sign and exit
    and   dx,000Fh        ; no: convert to binary
    push  dx              ; save the digit
    mul   bx              ; DX:AX = AX * BX
    pop   dx              ; restore the digit
    jo    A6              ; quit if result too large
    add   ax,dx           ; add new digit to AX
    jo    A6              ; quit if result too large
    inc   si              ; point to next digit
    jmp   A5              ; get another digit

    ; Overflow may have occurred.

A6: cmp   ax,8000h        ; If (AX <> 8000h) 
    jne   A7              
    cmp   sign,-1         ; or (sign <> -1),
    jne   A7              ; show the overflow message
    jmp   A8              ; else skip the overflow messsage                

A7: mov   dx,offset overflow_msg
    mov   ah,9
    int   21h
    mov   ax,0            ; set result to zero

A8: mul   sign            ; AX = AX * sign
    pop   si
    pop   edx
    pop   ecx
    pop   ebx
    ret
Readint endp

end 
