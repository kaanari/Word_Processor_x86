Title The Writeint Procedure        (writeint.asm)

public Writeint

; Writes a 16-bit unsigned binary integer to standard 
; output. Input parameters: AX = value, BX = radix.
; Last update: 4/7/99

.model small
.286
.data

buffer    db  16 dup(' ')             ; buffer to hold chars
bufferEnd label byte
xtable    db  '0123456789ABCDEF'      ; translate table

.code
Writeint proc
     pusha

     mov   cx,0
     mov   di,offset bufferEnd    

L1:  mov   dx,0            ; clear dividend to zero
     div   bx              ; divide AX by the radix
     xchg  ax,dx           ; exchange quotient, remainder
     push  bx              
     mov   bx,offset xtable; translate table
     xlat                  ; look up ASCII digit
     pop   bx              
     dec   di              ; back up in buffer
     mov   [di],al         ; move digit into buffer
     xchg  ax,dx           ; swap quotient into AX

     inc   cx              ; increment digit count
     or    ax,ax           ; quotient = 0?
     jnz   L1              ; no: divide again

     ; Display the buffer using CX as a counter.

L2:  mov   ah,2            ; function: display character
     mov   dl,[di]         ; character to be displayed 
     int   21h             ; call DOS
     inc   di              ; point to next character
     loop  L2

     popa
     ret
Writeint endp

end
