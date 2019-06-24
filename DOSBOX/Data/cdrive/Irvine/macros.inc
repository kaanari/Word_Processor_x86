; MACROS.INC - Macro Library 
; For Irvine: Assembly Language for the IBM-PC, 
; 3rd Edition.

; This file should be included in any source program
; invoking the macros. The program must also link to
; irvine.lib.

; Macros in this file, with parameter names:

;mCondCall macro cond,procname     
;mCompJmp macro dest,flag,source,label
;mDisplaystr macro string
;mDisplaystr_at macro row,col,string
;mExitdos macro ecode
;mGetyesno macro prompt
;mGotoXY macro row, column
;mJx&cond macro dest
;mLongloop macro dest

;mMove macro dest,source
;mMult16 macro dest,source
;mPrompt_Readint macro row,col,prompt,dest
;mPrompt_Readstring macro row,col,prompt,dest,max
;mPutchar macro char 
;mRepeatchar macro char,count
;mShl macro dest,count
;mStartup macro
;mWriteint macro value, radix
;mWriteliteral macro text
;m&styp macro dest,count (<shl,shr,sal,sar,rol,
;       ror,rcl,rcr>)

;------------------------------------------------
; Simulations of 80286 instructions:

;mENTER
;mLEAVE
;mPUSHA
;mPOPA
;mSET&cond
;-------------------------------------------------
extrn Crlf:proc, Readint:proc, Readstring:proc, \
      Writeint:proc, Writestring:proc

; If <cond> flag is true, call the
; procedure <procname>.

mCondCall macro cond,procname
     local L1,L2
     j&cond short L1
     jmp short L2
 L1: call procname
 L2: exitm
endm

; Compare <dest> to <source>; if <flag> is 
; true, jump to <label>.

mCompJmp macro dest,flag,source,label
    cmp     dest,source
    j&flag  short label
endm

; Display a null-terminated string.

mDisplaystr macro string
     push ax
     push dx
     mov  dx,offset string
     call Writestring
     pop  dx
     pop  ax
endm

; Display a string at row,col on console

mDisplaystr_at macro row,col,string
    mGotoXY  row,col       ;; call mGotoXY macro
    mDisplaystr string     ;; call mDisplaystr macro
endm

; Exit to DOS, return a status code

mExitdos macro ecode
    mov  ah,4Ch
    mov  al,ecode
    int  21h
endm 

; Show a prompt, wait for a keystroke. 
; Set the Zero flag if either "y" or "Y" 
; was pressed.

mGetyesno macro prompt
    mWriteliteral prompt  ;; display a prompt 
    mov  ah,1
    int  21h
    and  al,11011111b     ;; convert to uppercase
    cmp  al,'Y'           ;; set ZF if Y pressed
endm

; Jump eXtended (JX_): Conditionally jump
; to a NEAR label (anywhere in the segment).

irp cond,<a,na,b,nb,e,ne,z,nz,g,ng,l,nl,c,nc,o,no,p,np>
  jx&cond macro dest
    local  L1,L2
    j&cond short L1   ;; condition true?
    jmp short L2      ;; no:  exit
  L1: jmp near dest   ;; yes: jump to destination
  L2:
  endm
endm

; Display a literal prompt at <row>,<col>. Then
; input an integer and store it at <dest>.

mPrompt_Readint macro row,col,prompt,dest
    mGotoXY row,col
    mWriteliteral prompt
    call Readint   ;; read integer into AX
    mov  dest,ax
endm

; Display a literal prompt at <row>,<col>. Then input a 
; null-terminated string and store it at <dest>. Maximum 
; characters = <max>.

mPrompt_Readstring macro row,col,prompt,dest,max
    mGotoXY row,col
    mWriteliteral prompt
    push  cx
    push  dx
    mov   dx,offset dest
    mov   cx,max
    call  Readstring
    pop   dx
    pop   cx
endm

; Loop to a near label.

mLongloop macro dest
    local A1,A2
    loop  A1           ;; loop to short label
    jmp   short A2
A1: jmp   dest         ;; jump to destination
A2: 
endm

; Locate the cursor at <row>, <column> on 
; video page 0.

mGotoXY macro  row, column
     push   ax
     push   bx
     push   dx
     mov    bx,0        ;; choose page 0
     mov    ah,2        ;; locate cursor
     mov    dh,row    
     mov    dl,column
     int    10h         ;; call the BIOS 
     pop    dx
     pop    bx
     pop    ax
endm

; Move a word or byte from memory to memory.
; The TYPE operator returns 0 for registers.

mMove macro  dest,source
    push ax
    mov  bx,type dest
    if (type dest) EQ 1    ;; 8-bit type?
      mov   al,source      ;; yes: use AL
      mov   dest,al
    else
      if (type dest) EQ 2  ;; 16-bit type?
        mov   ax,source    ;; yes: use AX
        mov   dest,ax
      endif
    endif
    pop  ax
endm

; Multiply two 16-bit memory operands, returning
; the 32-bit product in DX:AX. Limitation: The 
; <source> argument cannot be AX.

mMult16 macro  dest,source
    push  ax
    mov   ax,dest       ;; AX = destination 
    mov   dx,source     ;; DX = source
    mul   dx            ;; DX:AX = product
    pop   ax
endm

; Output a character to the console.

mPutchar macro char 
    mov   ah,2
    mov   dl,char
    int   21h
endm             

; Output a character <count> times.

mRepeatchar macro char,count
    local L1  
    mov  cx,count
    mov  ah,2
    mov  dl,char
L1: int  21h     
    loop L1
endm

; Set DS and ES to the data segment location.

mStartup macro 
    mov   ax,@data    ;; initialize DS, ES
    mov   ds,ax       ;; to the data segment
    mov   es,ax
endm

; The following macro generates eight macros with 
; the names mSHL, mSHR, mSAL, mSAR, mROL, mROR, 
; mRCL, AND mRCR. The shift count may be any value
; between 0-255, as an immediate operand, register,
; or memory operand.

irp styp,<shl,shr,sal,sar,rol,ror,rcl,rcr>
  m&styp macro dest,count
    push cx
    mov  cl,count
    styp dest,cl
    pop  cx
  endm
endm

; Write an integer to the console

mWriteint macro  value, radix
     push  ax        ;; save AX, BX
     push  bx
     mov   ax,value  ;; value to be displayed
     mov   bx,radix  ;; radix to be used
     call  Writeint  ;; display AX on console
     pop   bx
     pop   ax
endm

; The mWriteliteral macro writes a string literal  
; to standard output. <text> is a string surrounded 
; by quotes or string delimiters <...>.

mWriteliteral macro text
    local string
    push   ax
    push   dx
    mov    dx,offset string
    call   Writestring
    pop    dx
    pop    ax
.data                  ;; local data
string  db  text,0     ;; define the string
.code
endm

;==========================================================
; MACROS THAT SIMULATE 80286 INSTRUCTIONS ON THE 8086/8088
;==========================================================

; Create a stack frame for a procedure that contains
; <localBytes> bytes of stack space reserved for its 
; local variables.

mENTER macro localBytes
    push  bp
    mov   bp,sp
    sub   sp,localBytes
endm

; Restore the stack pointer to the point that it 
; was before the mENTER macro created space for
; local procedure variables.

mLEAVE macro 
    mov   sp,bp
    pop   bp
endm

; Push the general-purpose and index registers on 
; the stack. Simulates the PUSHA instruction from 
; the 80286, except that SP is not saved.

mPUSHA macro
    push  ax
    push  cx
    push  dx
    push  bx
    push  bp
    push  si
    push  di
endm

; Pop the general-purpose, index, and stack registers
; from the stack. Simulates the POPA instruction from 
; the 80286. (Note that POPA just discards the value
; of SP that was pushed on the stack by the PUSHA
; instruction.)

mPOPA macro
    pop   di
    pop   si
    pop   bp
    pop   bx
    pop   dx
    pop   cx
    pop   ax
endm

; The mSET&cond macro sets the byte specified in the
; operand to 1 if <cond> is true. Or, it sets the byte
; to 0 if <cond> is false. Synonyms are omitted.

irp cond,<E,NE,A,AE,B,BE,Z,NZ,G,GE,L,LE,S,NS,C,NC,O,NO,PE,PO>
  mSET&cond macro byteVal
    Local L1, L2
    j&cond short L1
    mov    byteVal,0
    jmp    short L2
L1: mov    byteVal,1
L2:
  endm
endm

