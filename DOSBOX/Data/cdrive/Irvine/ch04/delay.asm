Title Measuring Time in Seconds        (delay.asm)

.model small
.stack 100h
.386
.code
extrn Delay_seconds:proc

main proc
   mov ax,@data
   mov ds,ax

   mov  eax,10
   call Delay_seconds

   mov ax,4c00h
   int 21h
main endp   

end main
