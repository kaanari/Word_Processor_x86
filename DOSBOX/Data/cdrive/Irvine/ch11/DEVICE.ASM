Title Test the Get_Deviceparms procedure (device.asm)

; Chapter 11 example.

.model small
.stack 100h
.386

; Define the mShow macro, that simplifies the 
; repeated display of disk information.
;--------------------------------------------
mShow macro prompt, value
local aPrompt
.data
aPrompt db prompt,0
.code
    mov  dx,offset aPrompt
    call Writestring    
    xor  eax,eax
    if   (type value) eq 1   ;; byte?
         mov al,[si].&value
    elseif (type value) eq 2 ;; word?
         mov ax,[si].&value
    else                     ;; dword?
         mov eax,[si].&value  
    endif   
    mov  bx,10
    call Writelong
    call Crlf
endm
;-----------------------------------

include disks.inc   ; disk parameter structure

.code
extrn Writelong:proc, Crlf:proc, WriteString:proc
extrn Get_Deviceparms:proc

main proc
    mov   ax,@data
    mov   ds,ax

    mov   bl,0                ; default drive
    call  Get_Deviceparms
    mov   si,ax
    call  Crlf

    mShow "Device type:              ", deviceType
    mShow "Device attributes:        ", deviceAttributes
    mShow "Sectors per cluster:      ", sectorsPerCluster
    mShow "Number of FATs:           ", numberOfFATs
    mShow "Max Root Dir Entries:     ", maxRootDirEntries
    mShow "Reserved Sectors:         ", reservedSectors
    mShow "Sectors per FAT:          ", sectorsPerFAT
    mShow "Sectors per track:        ", sectorsPerTrack
    mShow "Number of drive heads:    ", numberOfHeads
    mShow "Number of hidden sectors: ", numHiddenSectors

    ; Check for a large disk, using 32-bit sector count.
    cmp   [si].numberOfSectors, 0
    je    L1
    mShow "Total Number of Sectors:  ", numberOfSectors
    jmp   L2
L1: mShow "Total Number of Sectors:  ", numberSectorsLong

L2: mov ax,4c00h
    int 21h
main endp
end main
