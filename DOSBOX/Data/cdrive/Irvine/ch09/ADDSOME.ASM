Title The AddSome Procedure             (addsome.asm)

; Demonstration of the 'C' calling convention,
; with a variable number of parameters. The procedure
; returns the sum of up to 5 integers.

.model small, Pascal
.stack 100h
.286

.code

main proc
   mov ax,@data
   mov ds,ax

; Start by adding 4 integers:
   push 5
   push 6
   push 0Ah
   push 14h
   push 4        ; argument count
   call AddSome  ; sum will be in AX (29h)
   add  sp,10    ; clean up the stack

   push 1200h
   push 2033h
   push 2
   call AddSome
   add  sp,6

   mov ax,4c00h
   int 21h
main endp   

; Add two integers and return their sum.

AddSome proc 
    enter 0,0

    mov  cx,[bp+4]  ; get the count
    mov  ax,0
    mov  si,bp      ; point to last number
    add  si,6

L1: add  ax,[si]    ; add a number
    add  si,2       ; point to next
    loop L1         ; loop until done

    leave
    ret
AddSome endp


end main
