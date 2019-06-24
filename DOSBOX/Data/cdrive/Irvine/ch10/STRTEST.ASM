title String Library Test Program        (strtest.asm)

.model small
.stack 100h
.data
MAXWORDS = 10
WORDSIZE = 30
CONSOLE_INPUT = 0
CONSOLE_OUTPUT = 1

WORDCount dw ?
loopCount dw ?
smallest  dw WORDSIZE dup(0), 0
WORDList  db MAXWORDS dup( WORDSIZE dup(0), 0 )
prompt1   db "Enter a word (blank to quit): ",0
firstMsg  db "The first word (alphabetically) is ",0

.code
extrn Str_compare:proc, Str_copy:proc, Str_getline:proc
extrn Str_length:proc, Str_write:proc, Str_ucase:proc
extrn Crlf:proc

main proc
     mov  ax,@data
     mov  ds,ax
     mov  es,ax
    
     call Input_All_Words
     call Find_Lowest_Word

     mov  ax,4C00h      ; end program
     int  21h
main endp

     
Input_All_Words proc     
; Input a list of words and store in an array.

     mov  si,offset wordList
     mov  cx,MAXWORDS        ; loop counter

L1:  mov  loopCount,cx       ; save loop counter
     mov  dx,offset prompt1  ; ask for a word
     mov  bx,CONSOLE_OUTPUT
     call Str_write         

     mov  dx,si              ; input a word
     mov  bx,CONSOLE_INPUT
     mov  cx,WORDSIZE
     call Str_getline
     call Crlf

     mov  di,si        ; get the word's length
     call Str_length   ; (AX = length)
     or   ax,ax        ; if the length is zero then
     jz   L2           ;    exit the loop
     add  si,WORDSIZE  ; else point to next row
     mov  cx,loopCount ;   restore loop counter
     loop L1           ;   and get another word

L2:  mov  wordCount,MAXWORDS  ; calc number of words
     mov  cx,loopCount
     sub  wordCount,cx
     ret
Input_All_Words endp


Find_Lowest_Word proc
; Determine which word is lowest alphabetically
; and copy it to a separate variable.

     mov  si,offset wordList  ; copy first word to smallest
     mov  di,offset smallest
     call Str_copy
     mov  cx,wordCount  ; initialize the loop counter

L3:  call Str_compare   ; SI (current string) < DI (smallest)?
     jae  L4            ; no: skip next instruction
     call Str_copy      ; yes: copy SI (current) to DI (smallest)  
L4:  add  si,WORDSIZE   ; point to next row
     Loop L3            ; repeat for the other strings

; Display the lowest word in uppercase letters.
     call Crlf
     mov  dx,offset firstMsg
     mov  bx,CONSOLE_OUTPUT
     call Str_write
     mov  si,offset smallest   
     call Str_ucase     ; convert to uppercase
     mov  dx,si
     call Str_write     ; display on console
     call Crlf
     ret
Find_Lowest_Word endp

end main
