.model small
.stack 100h


DRIVE_A = 0
SECTOR_SIZE = 512

.data
buffer db SECTOR_SIZE dup(0FFh)
sectorNum   dw 63Fh    ; last sector on 1.44MB disk
sectorCount dw 1

.code
main proc
    mov ax,@data
    mov ds,ax
    

write_sector:
    mov   al,DRIVE_A
    mov   cx,sectorCount
    mov   dx,sectorNum
    mov   bx,offset buffer
    int   26h
    add   sp,2             ; remove old flags

    mov ax,4c00h
    int  21h
main endp

end main
