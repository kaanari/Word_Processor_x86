; Bitmap Display Program        (bitmap.asm)

; The ShowBMP procedure loads a Windows type BMP file
; and display it on the screen. Input parameters: 
; DS:DX points to an ASCIIZ string containing the 
; BMP file path. The maximum resolution is 320x200, with 
; 256 colors. (by Diego Escala, Miami, Florida)

.model  small
.186
.code

extrn   OpenInputFile:proc, CloseFile:proc

PUBLIC  ShowBMP

ShowBMP proc
pusha                           ; Save registers
call    OpenInputFile           ; Open file pointed to by DS:DX
jc      FileErr                 ; Error? Display error message and quit
mov     bx,ax                   ; Put the file handle in BX
call    ReadHeader              ; Reads the 54-byte header containing file info
jc      InvalidBMP              ; Not a valid BMP file? Show error and quit
call    ReadPal                 ; Read the BMP's palette and put it in a buffer
push    es
call    InitVid                 ; Set up the display for 320x200 VGA graphics
call    SendPal                 ; Send the palette to the video registers
call    LoadBMP                 ; Load the graphic and display it
call    CloseFile               ; Close the file
pop     es

jmp     ProcDone

FileErr:
mov     ah,9
mov     dx,offset msgFileErr
int     21h
jmp     ProcDone

InvalidBMP:
mov     ah,9
mov     dx,offset msgInvBMP
int     21h

ProcDone:
popa                            ; Restore registers
ret
ShowBMP endp

; Check the first two bytes of the file. If they do not
; match the standard beginning of a BMP header ("BM"), 
; the carry flag is set.

CheckValid proc
clc
mov     si,offset Header
mov     di,offset BMPStart
mov     cx,2                    ; BMP ID is 2 bytes long.
CVloop:
mov     al,[si]                 ; Get a byte from the header.
mov     dl,[di]
cmp     al,dl                   ; Is it what it should be?
jne     NotValid                ; If not, set the carry flag.
inc     si
inc     di
loop    CVloop

jmp     CVdone

NotValid:
stc

CVdone:
ret
CheckValid      endp

GetBMPInfo      proc
; This procedure pulls some important BMP info from the header
; and puts it in the appropriate variables.

mov     ax,header[0Ah]          ; AX = Offset of the beginning of the graphic.
sub     ax,54                   ; Subtract the length of the header
shr     ax,2                    ; and divide by 4
mov     PalSize,ax              ; to get the number of colors in the BMP
                                ; (Each palette entry is 4 bytes long).
mov     ax,header[12h]          ; AX = Horizontal resolution (width) of BMP.
mov     BMPWidth,ax             ; Store it.
mov     ax,header[16h]          ; AX = Vertical resolution (height) of BMP.
mov     BMPHeight,ax            ; Store it.
ret
GetBMPInfo      endp

InitVid proc
; This procedure initializes the video mode and makes ES point to
; video memory.

mov     ax,13h
int     10h                     ; Set video mode to 320x200x256.
push    0A000h
pop     es                      ; ES = A000h (video segment).
ret
InitVid endp

LoadBMP proc
; BMP graphics are saved upside-down.  This procedure reads the graphic
; line by line, displaying the lines from bottom to top.  The line at
; which it starts depends on the vertical resolution, so the top-left
; corner of the graphic will always be at the top-left corner of the screen.

; The video memory is a two-dimensional array of memory bytes which
; can be addressed and modified individually.  Each byte represents
; a pixel on the screen, and each byte contains the color of the
; pixel at that location.

mov     cx,BMPHeight            ; We're going to display that many lines
ShowLoop:
push    cx
mov     di,cx                   ; Make a copy of CX
shl     cx,6                    ; Multiply CX by 64
shl     di,8                    ; Multiply DI by 256
add     di,cx                   ; DI = CX * 320, and points to the first
                                ; pixel on the desired screen line.

mov     ah,3fh
mov     cx,BMPWidth
mov     dx,offset ScrLine
int     21h                     ; Read one line into the buffer.

cld                             ; Clear direction flag, for movsb.
mov     cx,BMPWidth
mov     si,offset ScrLine
rep     movsb                   ; Copy line in buffer to screen.

pop     cx
loop    ShowLoop
ret
LoadBMP endp

; This procedure checks to make sure the file is a valid BMP, 
; and gets some information about the graphic.

ReadHeader proc
mov     ah,3fh
mov     cx,54
mov     dx,offset Header
int     21h                     ; Read file header into buffer.

call    CheckValid              ; Is it a valid BMP file?
jc      RHdone                  ; No? Quit.
call    GetBMPInfo              ; Otherwise, process the header.

RHdone:
ret
ReadHeader endp

; Read the video palette.

ReadPal proc
mov     ah,3fh
mov     cx,PalSize              ; CX = Number of colors in palette.
shl     cx,2                    ; CX = Multiply by 4 to get size (in bytes)
                                ; of palette.
mov     dx,offset palBuff
int     21h                     ; Put the palette into the buffer.
ret
ReadPal endp

SendPal proc
; This procedure goes through the palette buffer, sending information about
; the palette to the video registers.  One byte is sent out
; port 3C8h, containing the number of the first color in the palette that
; will be sent (0=the first color).  Then, RGB information about the colors
; (any number of colors) is sent out port 3C9h.

mov     si,offset palBuff       ; Point to buffer containing palette.
mov     cx,PalSize              ; CX = Number of colors to send.
mov     dx,3c8h
mov     al,0                    ; We will start at 0.
out     dx,al
inc     dx                      ; DX = 3C9h.
sndLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB.

mov     al,[si+2]               ; Get red value.
shr     al,2                    ; Max. is 255, but video only allows
                                ; values of up to 63.  Dividing by 4
                                ; gives a good value.
out     dx,al                   ; Send it.
mov     al,[si+1]               ; Get green value.
shr     al,2
out     dx,al                   ; Send it.
mov     al,[si]                 ; Get blue value.
shr     al,2
out     dx,al                   ; Send it.

add     si,4                    ; Point to next color.
                                ; (There is a null chr. after every color.)
loop    sndLoop
ret
SendPal endp

.data
Header          label word
HeadBuff        db 54 dup('H')
palBuff         db 1024 dup('P')
ScrLine         db 320 dup(0)

BMPStart        db 'BM'

PalSize         dw ?
BMPHeight       dw ?
BMPWidth        dw ?

msgInvBMP       db "Not a valid BMP file.",7,0Dh,0Ah,24h
msgFileErr      db "Error opening file.",7,0Dh,0Ah,24h
end

