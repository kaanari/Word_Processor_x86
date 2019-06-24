title Sector Display Program              (SECTOR.ASM)

; This program reads and displays disk sectors on the 
; default drive, starting at sector 0. 
; Last update: 5/5/98

.model small
.stack 100h
.386
extrn Clrscr:proc, Get_Disksize:proc, GotoXY:proc, \
      Readkey:proc, Writelong:proc, Writestring:proc

Setcursor macro row,col
   push dx
   mov  dh, row
   mov  dl, col
   call Gotoxy
   pop  dx
endm

EOLN equ <0dh,0ah>
ESC_KEY = 1Bh
DATA_ROW = 5
DATA_COL = 0
SECTOR_SIZE = 512

.data
driveSize  db  0  ; = 1 if drive > 32 MB
row        db  ?
col        db  ?
currDrive  db  ?
line       db  EOLN,79 dup(0C4h),EOLN,0

;- Parameter block for disks over 32MB ---
 parmBlock label byte
 sectorNum    dd   2000h
 sectorCount  dw   1
 bufferOfs    dw   buffer
 bufferSeg    dw   @data
;------------------------------------------

buffer  db  SECTOR_SIZE dup(0),0

heading db "Sector Display Program (sector.exe)"
    db EOLN,"Press Esc to quit, or any key to continue..."
    db EOLN,"Reading sector: ",0

error_message db EOLN,"DOS error occurred while trying "
   db "to read the sector.", EOLN, "Returning to DOS.",0

.code
main  proc
     mov   ax,@data
     mov   ds,ax
     call  GetDriveType

A1:  call  Clrscr
     mov   dx,offset heading  ; display screen heading
     call  Writestring
     call  ReadSector
     jc    A2                 ; quit if DOS error
     call  DisplaySector
     call  Readkey
     cmp   al,ESC_KEY         ; Esc pressed?
     je    A3                 ; yes: quit
     inc   sectorNum          ; next sector
     jmp   A1                 ; repeat the loop

A2:  mov   dx,offset error_message ; "DOS error ..."
     call  Writestring
     call  ReadKey

A3:  call  Clrscr
     mov   ax,4C00h           ; return to DOS
     int   21h
main endp

ReadSector proc
     mov   al,currDrive      ; current drive number
     cmp   driveSize,1       ; drive size <= 32 MB?
     jb    B1                ; yes: skip
     mov   bx,offset parmBlock ; no, point to parms
     mov   cx,-1             ; CX must be -1
     int   25h               ; read the sector
     jmp   B2                ; exit

B1:  mov   cx,1              ; read 1 floppy sector
     mov   bx,offset buffer
     mov   dx,word ptr sectorNum 
     int   25h               ; read disk sector

B2:  add   sp,2       ; remove old flags from stack
     ret
ReadSector endp


; Display all of the sector data.

DisplaySector proc
     mov   eax,sectorNum       ; display sector number
     mov   bx,10               ; with decimal radix
     call  Writelong
     mov   dx,offset line      ; display horizontal line
     call  Writestring
     mov   si,offset buffer    ; point to buffer
     mov   row,DATA_ROW
     mov   col,DATA_COL
     SetCursor row,col

  ; Display the buffer with INT 10h rather than
  ; INT 21h, to avoid filtering ASCII control codes.

     mov   cx,SECTOR_SIZE    ; loop counter
     mov   bh,0              ; video page 0

C1:  push  cx                ; save loop counter
     mov   ah,0Ah            ; display character
     mov   al,[si]           ; get byte from buffer
     mov   cx,1              ; display it
     int   10h
     call  MoveCursor
     inc   si                ; point to next byte
     pop   cx                ; restore loop counter
     loop  C1                ; repeat the loop
     ret
DisplaySector endp


; Advance the cursor to the next column,
; check for possible wraparound on screen.

MoveCursor proc
     cmp   col,79     ; last column?
     jae   D1         ; yes: go to next row
     inc   col        ; no: increment column
     jmp   D2

D1:  mov   col,0      ; next row
     inc   row

D2:  Setcursor row,col
     ret
MoveCursor endp


; Get the drive size and set a flag if 
; the drive is over 32MB.

GetDriveType proc
     mov   ah,19h        ; get default drive
     int   21h           ; AL = drive number
     mov   currDrive,al
     call  Get_Disksize  ; result in DX:AX
     cmp   dx,01F4h      ; less than 32 MB?
     jbe   E1            ; yes: exit
     mov   driveSize,1   ; no: set flag
E1:  ret
GetDriveType endp

end main
