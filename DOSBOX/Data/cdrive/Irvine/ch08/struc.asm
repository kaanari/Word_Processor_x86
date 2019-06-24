title Structure Input Example         (STRUC.ASM)

; This program demonstrates the STRUC directive.

.model small
.stack 100h

STUNUMBER_SIZE = 7
LASTNAME_SIZE = 20
ACTIVE_STATUS = 1
STUDENT_COUNT = 2

typStudent struc
   IdNum     db  STUNUMBER_SIZE + 1 dup(?)
   Lastname  db  LASTNAME_SIZE + 1  dup(?)
   Credits   dw  ?
   Status    db  ?
typStudent ends

.data
progTitle db  "Student Structure Demonstration",0
srec typStudent <>   ; create a blank student

; Initialize and declare a structure variable:
rec2 typStudent <"1234","Baker",32,ACTIVE_STATUS>

allStudents typStudent STUDENT_COUNT dup( <> )

.code
extrn Clrscr:proc, Writestring:proc, Readstring:proc
extrn Crlf:proc, Readint:proc

main proc
     mov  ax,@data
     mov  ds,ax

     call Clrscr
     mov  dx,offset progTitle
     call Writestring
     call Crlf

     mov  si,offset srec
     call InputStudent

; Use a loop to input an array
; of students.

     mov  si,offset allStudents
     mov  cx,STUDENT_COUNT

L1:  call InputStudent
     add  si,SIZE typStudent
     Loop L1

     mov  ax,4C00h
     int  21h
main endp

; Input the fields for a single student from
; the console. Input parameter: SI points to the
; typStudent object.

InputStudent proc
     push ax
     push cx
     push dx

     mov  dx,si          ; base-indexed 
     add  dx,IdNum
     mov  cx,STUNUMBER_SIZE
     call Readstring
     call Crlf
 
     mov  dx, si
     add  dx,LastName
     mov  cx,LASTNAME_SIZE
     call Readstring
     call Crlf

     call Readint
     mov  [si].Credits,ax
     call Crlf
     mov  [si].Status, ACTIVE_STATUS

     pop  dx
     pop  cx
     pop  ax
     ret
InputStudent endp


end main

