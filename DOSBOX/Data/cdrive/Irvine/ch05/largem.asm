title Large Memory Model Example       (largem.asm)

; When mixing the Large model with a library assembled
; under the Small model, be sure to use NEAR PTR 
; operator when calling library procedures.

.model large   ; procedures are FAR by default
.stack 100h
.data
msg2 db "In the Sub_Far procedure",0dh,0ah,0

.code 
extrn Writestring:proc
main proc
     mov   ax,@data
     call  far ptr Sub_far 
     mov   ax,4C00h 
     int   21h
main endp

Sub_far proc
     mov   ds,ax
     mov  dx,offset msg2
     call near ptr Writestring
     ret
Sub_far endp    

end main
    