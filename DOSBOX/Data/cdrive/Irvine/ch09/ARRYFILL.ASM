Title Array Fill Procedure                  (arryfill.asm)

.model small
.stack 100h
.386

ARRAY_COUNT = 100
.data
array dw ARRAY_COUNT dup(0)

.code
extrn Crlf:proc, Writestring:proc, Random_Range:proc
extrn Writelong:proc

main proc
    mov ax,@data
    mov ds,ax
    mov es,ax

; Call the NEAR procedure:
    ;push  offset array
    ;push  ARRAY_COUNT
    ;call  ArrayFill

; Pass 32-bit pointer to the array:
    mov   ax,seg array
    push  seg array
    push  offset array
    push  ARRAY_COUNT
    call  ArrayFillF

    mov ax,4c00h
    int 21h
main endp

; Fill an array with random integers. Stack 
; parameters: (1) 16-bit offset of the array, 
; (2) the array size.

ArrayFill proc near
     push bp
     mov  bp,sp
     pusha
     
     mov  si,[bp+6]  ; offset of array
     mov  cx,[bp+4]  ; array size
    
AF1: mov  eax,10000h    ; get rand 0 - FFFFh
     call Random_Range  
     mov  [si],ax
     add  si,2
     Loop AF1

     popa
     pop  bp
     ret  4     ; adjust the stack
ArrayFill endp

; Uses 32-bit data pointer:

ArrayFillF proc
     push bp
     mov  bp,sp
     pusha
     push ds

     mov  ax,[bp+8]  ; segment of array
     mov  ds,ax
     mov  si,[bp+6]  ; offset of array
     mov  cx,[bp+4]  ; array size
    
LF1: mov  eax,10000h    ; get rand 0 - FFFFh
     call Random_Range  
     mov  [si],ax
     add  si,2
     Loop LF1

     pop  ds
     popa
     pop  bp
     ret  6     ; adjust the stack
ArrayFillF endp


end main