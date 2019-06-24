Title Link Library Demo Program (lnkdemo.asm)

; This program calls various I/O procedures
; in the link library.

.model small
.stack 100h

WhiteOnBlue = 1Fh
GreetingLoc = 0400h

.data
greeting db "Link Library Demo Program"
   db 0dh,0ah,0dh,0ah
   db "What is your name? ",0
   
numberPrompt db 0dh,0ah
   db "Please enter a 16-bit integer: ",0
userName db 50 dup(0)
pressAnyKey db 0dh,0ah,0dh,0ah,"Press any key...",0

.code
extrn Clrscr:proc, Crlf:proc, Gotoxy:proc, \
  Readint:proc, Readstring:proc, Scroll:proc, \
  Readkey:proc, Writeint:proc, Writestring:proc

main proc
   mov ax,@data
   mov ds,ax

; Clear the screen, scroll a blue window.

   call Clrscr
   mov  cx,0400h  ; upper-left corner
   mov  dx,0B28h  ; lower-right corner
   mov  bh,WhiteOnBlue
   call Scroll
   
; Display a greeting and ask for the 
; user's name.

   mov  dx,GreetingLoc
   call Gotoxy
   mov  dx,offset greeting
   call Writestring
   mov  dx,offset userName
   call Readstring
   
; Ask the user to enter a signed decimal integer.
; Redisplay the number in hexadecimal and binary.

   mov  dx,offset numberPrompt
   call Writestring
   call Readint         ; input an integer
   call Crlf
   mov  bx,16           ; display in hexadecimal
   call Writeint
   call Crlf
   mov  bx,2            ; display in binary
   call Writeint   

   mov  dx,offset pressAnyKey
   call Writestring
   call Readkey
   call Clrscr
   mov ax,4c00h    ; end program
   int 21h
main endp   

end main
