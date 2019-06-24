Title Procedure Parameters - 1             (proc1ms.asm)

; Microsoft Version: See proc1.asm for Borland version.

.model small, Pascal
.stack 100h

.data
x1 dw 10h
x2 dw 20h

theSum dw ?

.code
; Microsoft requires a procedure prototype if the 
; INVOKE statement occurs before the actual procedure.

AddTwo PROTO near Pascal val1:word, val2:word, \
       sumPtr:word

main proc
   mov ax,@data
   mov ds,ax

   INVOKE AddTwo, x1, x2, ADDR theSum

   mov ax,4c00h
   int 21h
main endp   

; Add two integers and return their sum.

AddTwo proc near Pascal val1:word, val2:word, \
       sumPtr:word

    push ax
    push si
    mov  ax,val1 
    add  ax,val2 
    mov  si,sumPtr
    mov  [si],ax
    pop  si
    pop  ax
    ret

AddTwo endp


end main
