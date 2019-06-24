Title Procedure Parameters - 1             (proc1br.asm)

; Borland version. See proc1ms.asm for Microsoft version.

.model small, Pascal
.stack 100h

.data
x1 dw 10h
x2 dw 20h

theSum dw ?

.code

main proc
   mov ax,@data
   mov ds,ax

   call AddTwo, x1, x2, offset theSum

   mov ax,4c00h
   int 21h
main endp   

; Add two integers and return their sum.

AddTwo proc 
ARG val1:word, val2:word, sumPtr:word

    push ax
    push si
    mov  ax,val1     ; [bp + 8]
    add  ax,val2     ; [bp + 6]
    mov  si,sumPtr   ; [bp + 4]
    mov  [si],ax
    pop  si
    pop  ax
    ret

AddTwo endp


end main
