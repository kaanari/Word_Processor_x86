title  Subroutine Demonstration       (SUBS.ASM)

; This program calls two subroutines: one for 
; keyboard input, another to sum the elements 
; in an array of integers.

.model small
.stack 100h
.data
char  db  ?
array dw  100h,200h,300h,400h,500h
array_size equ 5
sum   dw  ?   ; (will equal 0F00h)

.code
main proc
    mov   ax,@data         ; set up the DS register
    mov   ds,ax

    call  input_char       ; input keyboard into AL
    mov   char,AL          ; store in a variable

    ; Prepare to call the calc_sum procedure:
    mov   bx,offset array  ; BX points to array
    mov   cx,array_size    ; CX = array count
    call  calc_sum         ; calculate sum
    mov   sum,ax           ; store in a variable

    mov   ax,4C00h       ; return to DOS
    int   21h
main endp

input_char proc   ; input a character from the keyboard
    mov   ah,1
    int   21h
    ret
input_char endp

;-----------------------------------------------------
; Calculate the sum of an array of integers pointed
; to by BX. The array size is in CX. Return value:
; the SUM in AX.
;-----------------------------------------------------
calc_sum proc 
     push  bx           ; save BX, CX
     push  cx
     mov   ax,0
CS1: add   ax,[bx]
     add   bx,2         ; point to next integer
     loop  CS1          ; repeat for array size
     pop   cx           ; restore BX, CX
     pop   bx
     ret                ; sum stored in AX
calc_sum endp

end main

