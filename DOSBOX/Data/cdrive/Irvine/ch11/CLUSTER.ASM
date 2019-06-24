title  Cluster Display Program           (CLUSTER.ASM)

; This program reads the directory of drive A, decodes 
; the file allocation table, and displays the list of  
; clusters allocated to each file. 
; Last update: 5/5/98

; The following attributes are specific to 
; 1.44MB diskettes:
;-------------------------------------------------
FATSectors = 9   ; num sectors, first copy of FAT
DIRSectors = 14  ; num sectors, root directory
DIR_START = 19   ; starting directory sector num
;-------------------------------------------------

Directory struc
  fileName   db 8 dup(?)
  extension  db 3 dup(?)
  attribute  db ?
  reserved   db 10 dup(?)
  time       dw ?
  date       dw ?
  startingCluster dw ?
  fileSize   dd ?
ends

.model small
.stack 100h
.286
SECTOR_SIZE = 512
DRIVE_A = 0
FAT_START = 1    ; starting sector of FAT
EOLN equ <0dh,0ah>
ENTRIES_PER_SECTOR = SECTOR_SIZE / (size Directory)

.data
heading  label byte
  db  'Cluster Display Program           (CLUSTER.EXE)'
  db   EOLN,EOLN,'The following clusters are allocated '
  db  'to each file:',EOLN,EOLN,0

fattable dw ((FATSectors * SECTOR_SIZE) / 2) dup(?)  
dirbuf Directory (DIRSectors * ENTRIES_PER_SECTOR) dup(<>)
driveNumber db ?

.code
extrn Clrscr:proc, Crlf:proc, Writestring:proc, \
      Writeint:proc

main proc
     call  Initialize
     mov   ax,offset dirbuf
     mov   ax,offset driveNumber
     call  LoadFATandDir
     jc    A3                  ; quit if we failed
     mov   si,offset dirbuf    ; point to the directory

A1:  cmp   [si].filename,0     ; entry never used?
     je    A3                  ; yes: must be the end
     cmp   [si].filename,0E5h  ; entry deleted?
     je    A2                  ; yes: skip to next entry
     cmp   [si].filename,2Eh   ; parent directory?
     je    A2                  ; yes: skip to next entry
     cmp   [si].attribute, 0Fh ; extended filename?
     je    A2
     test  [si].attribute,18h  ; vol or directory name?
     jnz   A2                  ; yes: skip to next entry
     call  displayClusters     ; must be a valid entry

A2:  add   si,32               ; point to next entry
     jmp   A1
A3:  mov   ax,4C00h            ; return to DOS
     int   21h
main endp

LoadFATandDir proc   ; load FAT and root directory
     pusha

   ; Load the FAT
     mov   al,DRIVE_A
     mov   cx,FATsectors
     mov   dx,FAT_START
     mov   bx,offset fattable
     int   25h             ; read sectors
     add   sp,2            ; pop old flags off stack

   ; Load the Directory
     mov   cx,DIRsectors     
     mov   dx,DIR_START
     mov   bx,offset dirbuf
     int   25h
     add   sp,2
     popa
     ret
LoadFATandDir endp

DisplayClusters proc        ; SI points to directory
     push  ax
     call  displayFilename  ; display the filename
     mov   ax,[si+1Ah]      ; get first cluster
C1:  cmp   ax,0FFFh         ; last cluster?
     je    C2               ; yes: quit
     mov   bx,10            ; choose decimal radix
     call  WriteInt         ; display the number
     call  writeSpace       ; display a space
     call  next_FAT_entry   ; returns cluster # in AX
     jmp   C1               ; find next cluster
C2:  call  crlf
     pop   ax
     ret
DisplayClusters endp

WriteSpace proc
     push  ax
     mov   ah,2       ; function: display character
     mov   dl,20h     ; 20h = space
     int   21h
     pop   ax
     ret
WriteSpace endp

; Find next cluster in the FAT
; Input: AX = current cluster number
; Output: AX = new cluster number

Next_FAT_entry proc 
     push   bx               ; save regs
     push   cx
     mov    bx,ax            ; copy the number
     shr    bx,1             ; divide by 2
     add    bx,ax            ; new cluster offset
     mov    dx,fattable[bx]  ; DX = new cluster value
     shr    ax,1             ; old cluster even?
     jc     E1               ; no: keep high 12 bits
     and    dx,0FFFh         ; yes: keep low 12 bits
     jmp    E2
E1:  shr    dx,4             ; shift 4 bits to the right
E2:  mov    ax,dx            ; return new cluster number
     pop    cx               ; restore regs
     pop    bx
     ret
Next_FAT_entry endp

DisplayFilename proc
     mov   byte ptr [si+11],0 ; SI points to filename
     mov   dx,si
     call  Writestring
     mov   ah,2               ; display a space
     mov   dl,20h
     int   21h
     ret
DisplayFilename endp

Initialize proc
     mov   ax,@data   ; initialize DS, ES
     mov   ds,ax
     mov   es,ax
     call  ClrScr
     mov   dx,offset heading ; display program heading
     call  Writestring
     ret
Initialize endp

end main
