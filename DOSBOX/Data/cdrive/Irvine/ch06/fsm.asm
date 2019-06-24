Title Finite State Machine           (fsm.asm)

; Chapter 6 example. Implementation of finite 
; state machine that accepts an integer with an 
; optional leading sign. 
; Last Update: 4/26/98.

.model small
.stack 100h

DOS_CHAR_INPUT = 1
ENTER_KEY = 0Dh

.data
InvalidInputMessage db "Invalid input",0dh,0ah,0

.code
extrn Writestring:proc, Crlf:proc, Clrscr:proc

main proc
   mov  ax,@data
   mov  ds,ax   
   call Clrscr

StateA:
   call Getnext       ; read next char into AL
   cmp al,'+'         ; leading + sign?
   je StateB          ; go to State B
   cmp al,'-'         ; leading - sign?
   je StateB          ; go to State C
   call Isdigit       ; ZF = 1 if AL contains a digit
   jz StateC
   call DisplayError  ; invalid input found
   jmp Exit

StateB:
   call Getnext       ; read next char into AL
   call Isdigit       ; ZF = 1 if AL contains a digit
   jz StateC
   call DisplayError  ; invalid input found
   jmp Exit

StateC:
   call Getnext       ; read next char into AL
   jz   Exit          ; quit if Enter pressed
   call Isdigit       ; ZF = 1 if AL contains a digit
   jz StateC
   call DisplayError  ; invalid input found
   jmp Exit

Exit:
   call Crlf
   mov  ax,4c00h
   int  21h
main endp

; Read char from standard input into AL,
; set ZF = 1 if Enter key was read.

Getnext proc
    mov  ah,DOS_CHAR_INPUT ; read standard input
    int  21h               ; AL = character
    cmp  al,ENTER_KEY
    ret
Getnext endp

; Set ZF = 1 if the character in AL is a digit.

Isdigit proc
    cmp  al,'0'
    jb   A1
    cmp  al,'9'
    ja   A1
    test  ax,0     ; set ZF = 1
A1: ret
Isdigit endp

; Display error message.

DisplayError proc
    push dx
    mov  dx,offset InvalidInputMessage
    call WriteString
    call Crlf
    pop  dx
    ret
DisplayError endp

end main
