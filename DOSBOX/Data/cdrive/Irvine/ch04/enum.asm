Title Enumerated Constants           (enum1.asm)

; TASM only

.model small
.stack 100h
.386

bigVal = -4290000000

ColorType enum {
  black, blue
  green = 1234h, cyan }

.data
winColor ColorType green

.code 
main proc
   mov ax,@data
   mov ds,ax

   mov  ax,winColor

   mov  winColor, 12
   mov  winColor, blue

   mov ax,4c00h
   int 21h
main endp


end main   


