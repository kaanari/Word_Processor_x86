title Creating a Linked List  (list.asm)

; This program shows how the STRUC directive
; and the REPT directive can be combined to 
; create a linked list at assembly time.

.model small
.stack 100h

NUMBER_OF_NODES = 5
COUNT = 0

ListNode struc 
  NodeData dw ?
  NextPtr  dw ?
ends

.data

LinkedList label word
rept NUMBER_OF_NODES
  COUNT = COUNT + 1
  ListNode < COUNT, ($ + 2) >
endm

.code
extrn Writeint:proc, Crlf:proc

main proc
     mov  ax,@data
     mov  ds,ax

     mov  si,offset LinkedList
     mov  cx,NUMBER_OF_NODES

L1:  mov  ax,[si].NodeData
     mov  bx,10
     call Writeint         ; display node contents
     call Crlf
     mov  si,[si].NextPtr  ; pointer to next node
     Loop L1

     mov  ax,4C00h
     int  21h
main endp

end main

