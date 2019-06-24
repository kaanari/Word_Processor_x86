Title Testing the Macro Library (mactest.asm)

.model small
.stack 100h
.386
include ..\..\library\macros.inc  ; macro library

.data
helloMsg db "Hi there, world!",0dh,0ah,0

.code
extrn Clrscr:proc

main proc
    mStartup
    call Clrscr

    mDisplaystr helloMsg


    mExitDOS 0
main endp
   
end main
