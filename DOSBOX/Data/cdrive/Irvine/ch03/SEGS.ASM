Title User-defined Segments               (segs.asm)
; last update: 3/5/98

.model small
.stack 100h

data1 segment 'DATA'  ; specify class type
  value1 db  1
data1 ends                                                 

data2 segment 'DATA'
  value2 db  2
data2 ends

.code
main proc
    mov   ax,seg value1   ; use the SEG operator
    mov   ds,ax           ; to obtain segment address

    mov   al,ds:value1    ; explicit segment override

; or do the following:

    assume ds:data1       ; use ASSUME
    mov   al,value1       ; result: AL = 1  

    mov   ax,data2        ; use the segment name
    mov   es,ax                           

    assume es:data2       ; this is required
    mov   al,value2       ; result: AL = 2

    mov ax,4c00h
    int 21h
main endp   
end main
