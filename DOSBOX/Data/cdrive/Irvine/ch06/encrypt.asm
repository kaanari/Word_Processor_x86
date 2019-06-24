Title Encryption Program               (encrypt.asm)

.model small
.stack 100h

XORVAL = 239     ; any value between 0-255

.code
main proc
     mov   ax,@data
     mov   ds,ax

L1:  
     mov   ah,6        ; direct console input 
     mov   dl,0FFh     ; don't wait for character
     int   21h         ; AL = character
     jz    L2          ; quit if ZF = 1 (EOF)
     xor   al,XORVAL
     mov   ah,2        ; write to output
     mov   dl,al
     int   21h
     jmp   L1          ; repeat the loop

L2:  
     mov   ax,4C00h    ; return to DOS
     int   21h
main endp

end  main
