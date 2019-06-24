Title Using Macro Conditional Expressions

; Example created 4/27/1999, by Kip Irvine

.model small
.stack 100h

; The CalcSum16 macro issues a warning and exits if AX
; is passed as the second argument. The Text macro LINENUM
; must be defined first. Then, the % (expansion operator) 
; in the first column of the line containing the ECHO statement 
; causes LINENUM to be expanded into the source file line 
; number where the macro is being expanded. It is important 
; to define LINENUM inside the macro--otherwise, it just 
; returns the line number where LINENUM is declared. 
; (See the MASM 6.11 Programmers Guide, p.236.)

CalcSum16 macro op1, op2, sum
  ifidni <op2>,<AX>
    LINENUM TEXTEQU %(@LINE)
%   ECHO ** Error on line LINENUM: AX cannot be the second 
    ECHO ** argument when invoking the CalcSum16 macro.
    exitm
  endif
  mov  ax,op1
  add  ax,op2
  mov  sum,ax
endm

.data
val1 dw 12h
val2 dw 35h
val3 dw ?

.code
main proc
    mov  ax,@data
    mov  ds,ax
    CalcSum16 val1,val2,ax    ; AX = 0047h
    mov  bx,20h
    CalcSum16 bx,val2,val1    ; val1 = 0055h
    CalcSum16 ax,bx,cx        ; this is ok
    CalcSum16 bx,ax,cx        ; issues warning, generates no code

    mov  ax,4c00h
    int  21h
main endp
end main
