title  Multiword Addition Example        (MWADD.ASM)

; Demonstrates a procedure that will add multiword 
; operands together and store the sum in memory.

.model small
.stack 100h
.data
op1      dd    0A2B2A406h
op2      dd    080108700h
result   dw    3 dup(0)   ; stored as 2B06h,22C3h,0001h

.code
main proc         
    mov   ax,@data           ; initialize DS
    mov   ds,ax

   ;Add two doubleword operands

    mov   si,offset op1
    mov   di,offset op2
    mov   bx,offset result
    mov   cx,2               ; add 2 words
    call  Multiword_Add

    mov   ax,4C00h           ; exit program
    int   21h
main endp

; Multiword_Add
;
; Add any two multiword operands together. 
; When the procedure is called, SI and DI point 
; to the two operands, BX points to the destination 
; operand, and CX contains the number of words to 
; be added. No registers are changed.

.code
Multiword_Add proc
    pusha
    clc                ; clear the Carry flag

L1: mov   ax,[si]      ; get the first operand
    adc   ax,[di]      ; add the second operand
    pushf              ; save the Carry flag
    mov   [bx],ax      ; store the result
    add   si,2         ; advance all 3 pointers
    add   di,2
    add   bx,2
    popf               ; restore the Carry flag
    loop  L1           ; repeat for count passed in CX

    adc   word ptr [bx],0   ; add any leftover carry
    popa
    ret
Multiword_Add endp

end main


