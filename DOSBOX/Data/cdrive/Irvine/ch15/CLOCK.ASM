Title Reading the Real-Time Clock (clock.asm)

.model small
.stack 100h

.code
extrn Crlf:proc, Writebcd:proc  

main proc
    mov  ax,@data
    mov  ds,ax
    
    call RealClockTime
    
    mov  ax,4C00h
    int  21h
main endp

;---------------------------------------------
; Read and display the real time clock

RealClockTime proc near
    mov   ah,2
    int   1Ah    ; CH=hrs, CL=min, DH=sec, DL=dst flag
    mov   al,ch
    call  Writebcd ; write the hours
    mov   dl,':'
    call  outChar
    mov   al,cl
    call  Writebcd ; write the minutes
    mov   dl,':'
    call  outChar
    mov   al,dh
    call  Writebcd ; write the seconds
    call  crlf
    ret
RealClockTime endp

outChar proc    ; display char in DL
    push  ax
    mov   ah,2
    int   21h
    pop   ax
    ret
outChar endp
end main

