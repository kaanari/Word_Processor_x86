title QuadWord Addition             (QWADD.ASM)

; Demonstrates a procedure that adds quadword
; operands.

.model small
.stack 100h
.386

.data
op1     dq  0A2B2A406B7C62938h
op2     dq  080108700A64938D2h
result  dd  3 dup(?)  
    ; sum:  122C32B075E0F620Ah

.code
main proc         
    mov   ax,@data   
    mov   ds,ax

    mov   si,offset op1
    mov   di,offset op2
    mov   bx,offset result
    mov   cx,2             ; counter
    call  Multi32_Add

    mov   ax,4C00h         ; exit program
    int   21h
main endp

; Multi32_Add
;
; Add two integers, consisting of multiple 
; doublewords. Input parameters: SI and DI point 
; to the two operands, BX points to the destination 
; operand, and CX contains the number of 
; doublewords to be added.

.code
Multi32_Add proc
    pusha
    clc                ; clear the Carry flag

L1: mov   eax,[si]     ; get the first operand
    adc   eax,[di]     ; add the second operand
    pushf              ; save the Carry flag
    mov   [bx],eax     ; store the result
    add   si,4         ; advance all 3 pointers
    add   di,4
    add   bx,4
    popf               ; restore the Carry flag
    loop  L1           ; repeat count

    mov  dword ptr [bx],0
    adc  dword ptr [bx],0 ; add leftover carry
    popa
    ret
Multi32_Add endp

end main


