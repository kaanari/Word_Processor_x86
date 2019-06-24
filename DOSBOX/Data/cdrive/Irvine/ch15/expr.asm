title Expression Evaluation              (expr.asm)

; Chapter 15 example, using 8087 coprocessor.

.model small
.8087            ; enable 8087 instructions
.stack 100h

.data
op1    dd  6.0
op2    dd  2.0
op3    dd  5.0
result dd  ?

.code
main proc
     mov     ax, @data       ; initialize DS
     mov     ds, ax

     finit        ; initialize coprocessor
     fld op1      ; push op1 onto the stack
     fld op2      ; push op2 onto the stack
     fmul         ; multiply ST(1) by ST, pop result into ST
      fld op3      ; push op3 onto the stack
     fsub         ; subtract ST from ST(1), pop result into ST
     fwait        ; wait until previous instruction finished
     fstp result  ; pop stack into memory operand
 
     mov   ax,4c00h
     int   21h
main endp
end main
