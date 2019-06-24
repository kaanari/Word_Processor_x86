title  Segment Example (main module,  SEG2.ASM)

extrn var2:word, subroutine_1:proc

cseg  segment byte public 'CODE'
assume cs:cseg,ds:dseg, ss:sseg

main proc
   mov   ax,dseg        ; initialize DS
   mov   ds,ax

   mov   ax,var1        ; local variable
   mov   bx,var2        ; external variable
   call  subroutine_1   ; external procedure

   mov   ax,4C00h
   int   21h
main endp
cseg  ends

dseg segment word public 'DATA'   ; local data segment
   var1  dw  1000h
dseg ends

sseg segment stack       ; stack segment
   db  100h dup('S')
sseg ends

end main
