;------------------------------------------------------------------------
;
; Asm DLL functions. 
;
; Receives: char, short, int, and long passed by value and reference, 
;
; Returns: True (1) for success or False (0) for failure
;
;------------------------------------------------------------------------



.386					; .386 before .model gives 32 bit segments and code.
.model flat, stdcall	

.code


;
; Signed integers passed by value.
; 

VSIntTest PROC NEAR int1:SBYTE, int2:SDWORD, int3:SWORD, int4:SDWORD

  mov al, int1			; int1 is on the local stack for this proc.
  cmp al, 80h			; Was the param passed correctly ?
  jne VSError 			; NO, so jump to error handler.
  mov int1, 1           ; YES, modify it on the stack.


  mov eax, int2			; do the same here...
  cmp eax, 0ffffffffh
  jne VSError                                          
  mov int2, 1                                          


  mov ax, int3  
  cmp ax, 7fffh   
  jne VSError
  mov int3, 1


  mov eax, int4   
  cmp eax, 80000000h
  jne VSError
  mov int4, 1


  mov eax, 1 			; No errors then return ok.
  jmp VSDone

VSError:
  xor eax, eax          ; Errors found then return false.

VSDone:
  ret					; leave proc.

VSIntTest ENDP


;
; Signed integers passed by reference.
;

RSIntTest PROC NEAR int1:DWORD, int2:DWORD, int3:DWORD, int4:DWORD

  mov ebx, int1				; int1 is a 4 byte pointer to a byte, so
  mov al, byte ptr[ebx]     ; move the contents of the address to AL.
  cmp al, 80h               ; Was the pointer param passed correctly ?
  jne RSError				; NO, so jump to error handler.
  mov byte ptr[ebx], 1 		; YES, we have the address of the param so 
							; we'll modify it in the data segment.

  mov ebx, int2				; do the same below...
  mov eax, dword ptr[ebx]                 
  cmp eax, 0ffffffffh
  jne RSError
  mov dword ptr[ebx], 1                   


  mov ebx, int3
  mov ax, [ebx]
  cmp ax, 7fffh                           
  jne RSError
  mov word ptr[ebx], 1                    


  mov ebx, int4
  mov eax, dword ptr[ebx]                 
  cmp eax, 80000000h
  jne RSError
  mov dword ptr[ebx], 1                   


  mov eax, 1                ; No errors then return ok.       
  jmp RSDone

RSError:
  xor eax, eax    			; Errors found then return false.

RSDone:
  ret						; leave proc.

RSIntTest ENDP


;
; DllMain is required for all DLL's.
;

DllMain PROC NEAR stdcall	

  mov eax, 1				; Return true to caller. 

  ret 12					; Cleanup the stack since we don't use any
  							; of the params passed from the caller. 

DllMain ENDP

END
