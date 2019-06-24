title  32-bit division             (divide.asm)

.model small
.stack 100h
.386
.data

.code 
extrn Clrscr:proc, Crlf:proc, Readint:proc, \
      Writestring:proc

.data
dividend  dq   0000000800300020h
divisor   dd   00000100h

.code
main proc
   mov  ax,@data
   mov  ds,ax

mov    edx,dword ptr dividend + 4   ; high doubleword
mov    eax,dword ptr dividend       ; low doubleword
div    divisor     ; EAX = 08003000h, EDX = 00000020h      


   mov   ax,4C00h   ; exit program
   int   21h
main endp

end main

