; Console Library Demo Number 1           (CNSLDEM1.ASM)

; This program calls various I/O procedures
; in irvine.lib. Updated 1/31/1999.

.model small
.stack 100h

upperLeftCorner  = 0500h  ; row 5, column 0
lowerRightCorner = 144Fh  ; row 20, column 79
attribute = 1Fh           ; color = white on blue
greetingLoc = 060Fh       ; row 6, column 0

.data
greeting db "Welcome to Console Library Demo Number 1"
         db 0Dh,0Ah,0Dh,0Ah
         db "What is your name? ",0
numberPrompt db 0dh,0ah
         db "Please enter a signed 16-bit integer: ",0
userName db 50 dup(0)

.code
extrn Clrscr:proc, Crlf:proc, Gotoxy:proc 
extrn Readint:proc, Readstring:proc, Scroll:proc 
extrn Writeint:proc, Writeint_signed:proc, Writestring:proc

main proc
    mov ax,@data
    mov ds,ax

; Clear the screen, scroll a smaller blue window.
    call Clrscr  
    mov  cx,upperLeftCorner
    mov  dx,lowerRightCorner
    mov  bh,attribute
    call Scroll
   
; Move the cursor just below the upper-left corner
; of the smaller window, and display a greeting and
; ask for the user's name. 
    mov  dx,greetingLoc
    call Gotoxy   
    mov  dx,offset greeting
    call Writestring

; Input the user's name and store in a variable.
    mov  dx,offset userName    
    call Readstring
    
; Ask the user to enter a signed decimal integer.
    mov  dx,offset numberPrompt
    call Writestring

; Read the number and redisplay in signed decimal,
; hexadecimal, and binary.
    call Readint     ; number is now in AX
    call Crlf
    call Writeint_signed  ; display in signed decimal
    call Crlf
    mov  bx,16       ; display in hexadecimal
    call WriteInt    
    call Crlf
    mov  bx,2        ; display in binary
    call WriteInt

    mov ax,4C00h
    int 21h
main endp   
end main
