title Comparing Signed Numbers      (LGSMAL.ASM)

; This program displays the largest and smallest
; values in an array of signed integers.

.model small
.stack 100h

.data
largest  dw  ?
smallest dw  ?

array dw  -1,2000,-421,32767,500,0,-26,-4000
arrayCount = 8

largemsg db "Largest value:  ",0
smallmsg db "Smallest value: ",0

.code
extrn Clrscr:proc, Crlf:proc, Writeint_signed:proc, \
      Writestring:proc

main proc
    mov  ax,@data        ; initialize DS
    mov  ds,ax
    mov  di,offset array
    mov  ax,[di]         ; get first element
    mov  largest,ax      ; initialize largest
    mov  smallest,ax     ; initialize smallest
    mov  cx,arrayCount   ; loop counter

A1: mov  ax,[di]         ; get array value
    cmp  ax,smallest     ; [DI] >= smallest?
    jge  A2              ; yes: skip
    mov  smallest,ax     ; no: move [DI] to smallest

A2: cmp  ax,largest      ; [DI] <= largest?
    jle  A3              ; yes: skip
    mov  largest,ax      ; no: move [DI] to largest

A3: add  di,2            ; point to next number
    loop A1              ; repeat the loop until CX=0

    call ShowResults
    mov  ax,4C00h        ; return to DOS
    int  21h
main endp

; Display the largest and smallest values.

ShowResults proc   
    mov   dx,offset largemsg
    call  Writestring
    mov   ax,largest
    call  Writeint_signed
    call  CrLf
    mov   dx,offset smallmsg
    call  Writestring
    mov   ax,smallest
    call  Writeint_signed    
    call  CrLf
    ret
ShowResults endp    

end main
