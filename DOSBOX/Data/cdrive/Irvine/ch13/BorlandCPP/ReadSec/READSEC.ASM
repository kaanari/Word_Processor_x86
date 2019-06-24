; readsec.asm - Chapter 13 sample.

; The ReadSector procedure is called from a 16-bit 
; DOS application written in Borland C++ 5.01.

Public _ReadSector

.model small
.386

LARGE_DISK = 1
SMALL_DISK = 0

.data
;--- Parameter block required for disk > 32MB
parmBlock label byte
sectorNumber dd   ?
sectorCount  dw   ?
bufferOfs    dw   ?
bufferSeg    dw   @data
;--------------------------

driveType dw ?

.code

; ReadSector --------------------------------------
;
; Read n sectors from a disk drive. 
; We currently number drives as: A=1, B=2, etc., 

_ReadSector proc near C
 ARG bufferPtr:word, startSector:dword, driveNumber:word, \
     numSectors:word
 
     enter 0,0
     mov   eax,startSector
     mov   sectorNumber,eax
     mov   ax,numSectors
     mov   sectorCount,ax     

     mov   ax,driveNumber
     call  GetDriveType  ; set driveType to 1 or 0
     cmp   driveType,LARGE_DISK
     jb    RS1           ; yes: skip to RS1

     ; Reading a disk > 32MB.
     dec   al            ; Drive A=0, B=1,...
     mov   bx,offset parmBlock
     mov   cx,-1         
     push  bufferPtr
     pop   bufferOfs
     int   25h           ; read the sector
     jmp   RS2           ; exit
     
RS1: ; Reading a disk <= 32MB.
     dec   al            ; Drive A=0, B=1,...
     mov   cx,numSectors 
     mov   bx,bufferPtr
     mov   dx,word ptr sectorNumber
     int   25h  
RS2: add   sp,2 
 
     leave
     ret
_ReadSector endp


; GetDriveType ---------------------------------
;
; Input: AL = drive number, where A = 1, B = 2,...
; Output: driveType = 1 or 0.
;------------------------------------------------

GetDriveType proc
     pusha
     mov   driveType,SMALL_DISK
     mov   dl,al   ; drive number (A=1, B=2)
     mov   ah,36h  ; Get Disk Free Space
     int   21h
     push  dx      ; save clusters/drive
     mul   cx      ; AX = bytes/cluster
     pop   dx
     mul   dx      ; DX:AX = bytes/drive
     cmp   dx,01F4h      ; less than 32 MB?
     jbe   E1            ; yes: exit
     mov   driveType,LARGE_DISK
E1:  popa
     ret
GetDriveType endp



end