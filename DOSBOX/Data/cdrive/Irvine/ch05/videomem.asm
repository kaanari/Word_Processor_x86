; Title Direct Video Demonstration (videomem.asm)

; Chapter 5 example. Uses Borland extensions to
; show another way of calling the Writestring_direct
; procedure.

.model small,Pascal
.286
.stack 100h

Gray = 7
Blue = 1
BlueOnGray = (Gray SHL 4) OR Blue

.data
msg_str  db "This is written to VRAM.",0

.code
extrn Writestring_direct:proc

;Write_direct ------------------------------------
;
; This is a "shell" procedure that simplifies the
; calling of Writestring_direct. It uses the 
; Borland extensions to the CALL statement.
;
; Last Update: 4/18/98

Write_direct proc
arg stringPtr:word, row:byte, col:byte, attrib:byte
   pusha
   mov  si,stringPtr         ; string pointer
   mov  dh,row               ; row
   mov  dl,col               ; column
   mov  ah,attrib            ; attribute
   call Writestring_direct
   popa
   ret   
Write_direct endp

main proc
   mov ax,@data
   mov ds,ax

   mov  si,offset msg_str
   mov  dh,8
   mov  dl,10
   mov  ah,BlueOnGray
   call Writestring_direct

   call Write_direct, offset msg_str, 12, 10, BlueOnGray

   mov ax,4c00h
   int 21h
main endp   


end main
