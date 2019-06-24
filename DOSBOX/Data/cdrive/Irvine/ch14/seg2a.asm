title  Segment Example       (submodule, SEG2A.ASM)

public subroutine_1, var2

cseg  segment byte public 'CODE'
assume cs:cseg, ds:dseg

subroutine_1 proc           ; called from MAIN
    mov   ah,9
    mov   dx,offset msg
    int   21h
    ret
subroutine_1 endp

cseg ends

dseg segment word public 'DATA'

var2  dw  2000h                ; accessed by MAIN 
msg   db  'Now in Subroutine_1'
      db   0Dh,0Ah,'$'

dseg ends
end
