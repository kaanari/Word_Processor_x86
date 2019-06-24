title Character Filtering          (XLAT.ASM)

; This program filters input from the console 
; by screening out all ASCII codes less than 
; 32 or greater than 127. Uses INT 16h, 
; direct keyboard input.

.model small
.stack 100h
INPUT_LENGTH = 20

.data
validchars label byte
  db 32 dup(0)    ; invalid chars: 0-31
  db 96 dup(0FFh) ; valid chars:   32-127
  db 128 dup(0)   ; invalid chars: 128-255

.code
main proc
    mov   ax,@data              
    mov   ds,ax
    mov   bx,offset validchars 
    mov   cx,INPUT_LENGTH

getchar:
    mov   ah,0       ; keyboard input
    int   16h        ; char is in AL
    mov   dl,al      ; save copy in DL
    xlat  validchars ; look up char in AL
    or    al,al      ; invalid char?
    jz    getchar    ; yes: get another
    mov   ah,2       ; no: output the char
    int   21h 
    loop  getchar

    mov   ax,4C00h 
    int   21h
main endp

end main
