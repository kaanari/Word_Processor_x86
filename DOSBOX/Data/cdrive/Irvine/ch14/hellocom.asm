title HELLO Program in COM format   (HELLOCOM.ASM)

.model tiny
.code
org 100h       ; must be before main proc
main proc
     mov  ah,9
     mov  dx,offset hello_message
     int  21h
     mov  ax,4C00h
     int  21h
main endp

hello_message  db  'Hello, world!',0dh,0ah,'$'
end main
