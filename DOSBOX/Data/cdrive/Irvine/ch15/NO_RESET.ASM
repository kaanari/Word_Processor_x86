title  Reset-Disabling program                  (NO_RESET.ASM)

.model tiny

; This program disables the usual DOS reset command 
; (Ctrl-Alt-Del), by intercepting the INT 9 keyboard 
; hardware interrupt.  It checks the shift status bits 
; in the DOS keyboard flag, and changes any Ctrl-Alt-Del
; to Alt-Del.  The computer can only be rebooted by 
; typing Ctrl+Alt+Right shift+Del.  Assemble, link, 
; and convert to a COM program by including the /t
; command on the TLINK command line.

rt_shift       equ   01h      ; Right shift key: bit 0
ctrl_key       equ   04h      ; CTRL key: bit 2
alt_key        equ   08h      ; ALT key: bit 3
del_key        equ   53h      ; scan code for DEL key
kybd_port      equ   60h      ; keyboard input port

.code
;code    segment 
;        assume cs:code,ds:code

    org   100h       ; this is a COM program

start:
    jmp   setup      ; jump to TSR installation routine

;   Memory-resident code begins here 

int9_handler proc far
    sti                      ; re-enable hardware interrupts
    pushf                    ; save regs & flags
    push  es
    push  ax
    push  di

;   Point ES:DI to the DOS keyboard flag byte:

L1: mov   ax,40h             ; DOS data segment is at 40h
    mov   es,ax             
    mov   di,17h             ; location of keyboard flag
    mov   ah,es:[di]         ; copy keyboard flag into AH

;   Test for the CTRL and ALT keys:

L2: 
    test  ah,ctrl_key        ; CTRL key held down?
    jz    L5                 ; no: exit
    test  ah,alt_key         ; ALT key held down?
    jz    L5                 ; no: exit

;   Test for the DEL and Right-shift keys:

L3: in    al,kybd_port       ; read keyboard port
    cmp   al,del_key         ; DEL key pressed?
    jne   L5                 ; no: exit
    test  ah,rt_shift        ; right shift key pressed?
    jnz   L5                 ; yes: allow system reset

L4: and   ah,not ctrl_key    ; no: turn off bit for CTRL 
    mov   es:[di],ah         ; store keyboard_flag

L5: pop   di                 ; restore regs & flags
    pop   ax
    pop   es
    popf              
    jmp   cs:[old_interrupt9]  ; jump to INT 9 routine

old_interrupt9   dd ?

int9_handler endp
end_ISR label byte

; --------------- (end of TSR program) ------------------

;   Save a copy of the original INT 9 vector, and set up
;   the address of our program as the new vector.  Terminate
;   this program and leave the INT9_HANDLER in memory.

setup:
    mov   ax,3509h           ; get INT 9 vector
    int   21h
    mov   word ptr old_interrupt9,bx    ; save INT 9 vector 
    mov   word ptr old_interrupt9+2,es

    mov   ax,2509h           ; set interrupt vector, INT 9
    mov   dx,offset int9_handler
    int   21h

    mov   dx,offset end_ISR  ; point to end of resident code
    int   27h                ; terminate and stay resident

end  start
