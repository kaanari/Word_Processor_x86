title  Control-Break Handler               (CTRLBK.ASM)

.model small
.stack 100h
.data
msg label byte
 db 'Ctrl-Break demonstration. (CTRLBK.EXE).',0dh,0ah
 db 'This program disables Ctrl-Break. Press any'
 db  0dh,0ah
 db 'keys on the keyboard, and press ESC to return to DOS.'
 db  0dh,0ah,0

.code
extrn Writestring:proc

main  proc
    mov   ax,@data
    mov   ds,ax
    mov   dx,offset msg  ; display greeting message
    call  Writestring

install_handler:
    push  ds          ; save DS
    mov   ax,@code    ; initialize DS 
    mov   ds,ax
    mov   ah,25h      ; set interrupt vector
    mov   al,23h      ; for interrupt 23h
    mov   dx,offset break_handler 
    int   21h
    pop   ds          ; restore DS

L1: mov   ah,1        ; wait for a key, echo it
    int   21h
    cmp   al,1Bh      ; ESC pressed?
    jnz   L1          ; no: continue
    mov   ax,4C00h    ; yes: exit program
    int   21h
main  endp

; The following routine executes when Ctrl-Break
; is pressed.

break_handler proc 
    push  ax
    push  dx
    mov   ah,2      ; sound a beep
    mov   dl,7
    int   21h
    pop   dx
    pop   ax
    iret
break_handler endp

end main


