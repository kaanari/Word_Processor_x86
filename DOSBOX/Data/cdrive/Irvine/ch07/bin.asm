title  Display ASCII binary (BIN.ASM)

; This program displays a number in binary.

.model small
.stack 100h
.data
prompt db "Enter a decimal integer: ",0

.code 
extrn Clrscr:proc, Crlf:proc, Readint:proc, \
      Writestring:proc

main proc
   mov  ax,@data
   mov  ds,ax

   ; Prompt for an integer:
   
   call Clrscr
   mov  dx,offset prompt
   call Writestring
   call Readint
   call Crlf     
   mov   cx,16       ; number of bits in AX

L1:  
   shl   ax,1       ; shift AX left into Carry flag
   mov   dl,'0'     ; choose '0' as default digit
   jnc   L2         ; if no carry, then jump to L2
   mov   dl,'1'     ; else move '1' to DL
          
L2:  
   push  ax         ; save AX
   mov   ah,2       ; display DL
   int   21h
   pop   ax         ; restore AX
   loop  L1         ; shift another bit to left

   mov   ax,4C00h   ; exit program
   int   21h
main endp

end main

