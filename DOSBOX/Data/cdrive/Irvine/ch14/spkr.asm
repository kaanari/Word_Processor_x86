title Speaker Demo Program               (SPKR.ASM)  

;---------------------------------------------------
; This program plays a series of ascending notes on 
; an IBM-PC or compatible computer.                 
;--------------------------------------------------- 
 
.model small
.stack 100h

speaker  equ  61h        ; address of speaker port
timer    equ  42h        ; address of timer port
delay    equ  0D000h     ; delay between notes

.code
main proc
     in    al,speaker     ; get speaker status
     push  ax             ; save status
     or    al,00000011b   ; set lowest 2 bits
     out   speaker,al     ; turn speaker on
     mov   al,60          ; starting pitch

L2:  out   timer,al       ; timer port: pulses speaker 

   ; Create a delay loop so we can hear the 
   ; changing pitches.

     mov    cx,14         ; repeat outer loop 14 times
L3:  push   cx
     mov    cx,delay  
L3a: loop   L3a
     pop    cx
     loop   L3    

     sub   al,1           ; raise pitch
     jnz   L2             ; play another note
     pop  ax              ; get original status
     and  al,11111100b    ; clear lowest 2 bits
     out  speaker,al

     mov  ax,4c00h
     int  21h
main endp 

end main
