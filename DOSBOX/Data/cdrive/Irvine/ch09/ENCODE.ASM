title Character Encoding Program      (ENCODE.ASM)

; This program reads an input file and encodes
; the output using the XLAT instruction.    
; To run it, redirect input on the DOS/Windows
; command line. For example:  
;
;            encode < input.txt

.model small
.stack 100h
.data 
codetable label byte
  db   48 dup(0)    ; no translation
  db  '4590821367'  ; ASCII codes 48-57
  db   7 dup (0)    ; no translation
  db  'GVHZUSOBMIKPJCADLFTYEQNWXR'
  db   6 dup (0)    ; no translation
  db  'gvhzusobmikpjcadlftyeqnwxr'
  db   133 dup(0)   ; no translation

.code 
main proc
    mov   ax,@data
    mov   ds,ax
    mov   bx,offset codetable

getchar:
    mov    ah,6       ; console input, no wait
    mov    dl,0FFh    ; specify input request
    int    21h        ; call DOS
    jz     quit       ; quit, no input waiting
    mov    dl,al      ; save char in DL
    xlat   codetable  ; translate the char
    cmp    al,0       ; not translatable?
    je     putchar    ; yes: write it as is
    mov    dl,al      ; no: move new char to DL

putchar:
    mov    ah,2       ; write DL to output
    int    21h        ; call DOS
    jmp    getchar    ; get another char

quit:
    mov    ax,4C00h   ; exit program
    int    21h
main endp
end main
