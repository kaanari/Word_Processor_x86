title The FindArray Procedure         (scasd.asm)

; This version uses hand-optimized assembly 
; language code with the SCASD instruction.

.386P
.model flat
public  _FindArray

true = 1
false = 0

; Stack parameters:
srchVal   equ  [ebp+08]
arrayPtr  equ  [ebp+12]
count     equ  [ebp+16]

.code
_FindArray proc near
     push  ebp
     mov   ebp,esp
     push  edi    

     mov   eax, srchVal    ; search value
     mov   ecx, count      ; number of items
     mov   edi, arrayPtr   ; pointer to array

     repne scasd           ; do the search
     jz    returnTrue      ; ZF = 1 if found

returnFalse:             
     mov   al, false     
     jmp   short exit

returnTrue:
     mov   al, true

exit:
     pop   edi
     pop   ebp
     ret   
_FindArray endp

end

