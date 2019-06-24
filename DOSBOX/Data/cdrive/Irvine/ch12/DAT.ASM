title Date Stamp Program                  (DAT.ASM)

; This program displays the name and date stamp for 
; each file matching a file specification entered   
; on the DOS command line. Uses macros and a 
; structure.

.model small
.stack 100h
.286
EOLN EQU <0dh,0ah>

FileControlBlock struc
           db 22 dup(?) ; header info - not used
  fileTime dw ?         ; time stamp of file
  fileDate dw ?         ; date stamp of file
  fileSize dd ?         ; size of file: not used
  fileName db 13 dup(0) ; name of file found by DOS
FileControlBlock ends

mWriteint macro value, radix:=<10>
    push  ax
    push  bx
    mov   ax,value
    mov   bx,radix
    call  Writeint
    pop   bx
    pop   ax   
endm

mWritestring macro aString
    push  dx
    mov   dx,offset aString
    call  Writestring
    pop   dx
endm
;-------------------------------------------------------
.data
filespec db  40 dup(0)      ; DOS command line
heading  db "Date Stamp Program             (DAT.EXE)"
         db  EOLN,EOLN,0
helpMsg  db "The correct syntax is:  "
         db "DAT [d:][path]filename[.ext]",EOLN,0
DTA      FileControlBlock <>
;-------------------------------------------------------
.code
extrn DOS_error:proc, Get_Commandtail:proc,   \
      Str_length:proc, Writeint:proc, Writestring:proc, \
      Crlf:proc

main proc
     mov   bx,ds
     mov   ax,@data              ; initialize DS, ES
     mov   ds,ax
     mov   es,ax
     mov   dx,offset filespec  ; get filespec from
     call  Get_Commandtail     ; the command line
     jc    A2                  ; quit if none found
     mWritestring heading
     call  findFirst         ; find first matching file
     jc    A3                ; quit if none found

A1:  call  decodeDate        ; separate the date stamp
     call  display_filename
     mov   ah,4Fh            ; find next matching file
     int   21h
     jnc   A1                ; continue searching
     jmp   A3                ; until no more matches

A2:  mWritestring helpMsg    ; display help

A3:  mov   ax,4C00h          ; exit program
     int   21h
main endp

; Find first file that matches the file
; specification entered on command line.

findFirst proc
     mov   ah,1Ah         ; set transfer address
     mov   dx,offset DTA
     int   21h
     mov   ah,4Eh         ; find first matching file
     mov   cx,0           ; normal attributes only
     mov   dx,offset filespec 
     int   21h
     jnc   B1             ; if DOS error occurred,
     call  DOS_error      ; display a message
B1:  ret
findFirst endp

; Translate the encoded bit format of a file's
;   date stamp.

.data
month    dw  ?    ; temporary storage for
day      dw  ?    ; month, day, year
year     dw  ?
.code
decodeDate proc
     mov   bx,offset DTA.fileDate
     mov   dx,[bx]           ; get the day
     mov   ax,dx
     and   ax,001Fh          ; clear bits 5-15
     mov   day,ax
     mov   ax,dx             ; get the month
     shr   ax,5              ; shift right 5 bits
     and   ax,000Fh          ; clear bits 4-15
     mov   month,ax
     mov   ax,dx             ; get the year
     shr   ax,9              ; shift right 9 bits
     add   ax,80             ; year is relative to 1980
     mov   year,ax
     ret
decodeDate endp

; Write both filename and date stamp to console.

display_filename proc
     mWritestring DTA.fileName
     call  fill_with_spaces
     mWriteint month
     call  write_dash        ; display a "-"
     mWriteint day
     call  write_dash        ; display a "-"
     mWriteint year
     call  Crlf
     ret
display_filename endp

; Pad right side of the filename with spaces.

fill_with_spaces proc
     mov   cx,15       ; max file size plus 3 spaces
     mov   di,offset DTA.fileName ; get length
     call  Str_length  ; AX = length of filename
     sub   cx,ax
     mov   ah,2        ; display character
     mov   dl,20h      ; space
E1:  int   21h         ; write spaces
     loop  E1          ; until CX = 0
     ret
fill_with_spaces endp

write_dash proc        ; write a hyphen
     push  ax
     push  dx
     mov   ah,2
     mov   dl,'-'
     int   21h
     pop   dx
     pop   ax
     ret
write_dash endp
end main
