;----------------------------------------------------------------------
;
;  FUNCTION:  AsmThreadProc (LPVOID)
;
;  PURPOSE:   A thread procedure which calculates position on the window
;             and draws a colored rectangle.  The color of the rectangle
;             is determined by the input parameter.
;
;  VARIABLES USED:
;
;    - horizontal, vertical:
;             Local integers used to indicate the next directional move the
;             rectangle will make.
;
;    - ulx, uly, Locals which are moved to ESI and EDI as an optimization.
;             Integers used for the Upper Left X corner and Upper
;             Upper Left Y position of the rectangle.
;
;    - rect:  A Local RECT structure used to determine the current size of 
;             the window (in case the user resizes it).
;
;    - hdc:   Local variable, HDC of the rectangle.
;
;    - Time:  A Local _SYSTEMTIME structure.  It's milli-second field is 
;             used to create an apparent random starting point for the
;             rectangles.
;
;    - hBrush:A Local handle to a Brush object, used to set the color of 
;             the rectangle.
;
;    - wdth,  height:
;             Local Integers used for the width and height of the rectangles.
;
;	 - hWind: Handle to a window that's shared with the main module, so that 
;             this procedure can draw to a window. External variable.
;
;	 - lpColor: Long pointer parameter that holds the address of the color of 
;               the bouncing rectangle. Passed from the main module.
;
;  CALLED BY:
;
;    MainWndProc();
;
;----------------------------------------------------------------------



.386							; .386 before .model, thus 32bit segments.
.model flat, C


.data
include asmthred.inc			; contains structures, variables, etc.

externdef hWind:dword			; Handle to a window shared with main the module so 
								; that the Assembly procedure can draw to the window.


AsmThreadProc PROTO C, lpColor:LPVOID



.code


AsmThreadProc PROC, lpColor:LPVOID

LOCAL   horizontal:dword, vertical:dword, rect1:RECT, handleDC:HDC, 
        Time:_SYSTEMTIME, hBrush:HANDLE, wdth:dword, height:dword

				
	mov		wdth, 20								; Height of box
	mov		height, 20								; Width of box.
		
	invoke	GetSystemTime, addr Time				; Get the time

	invoke GetClientRect, hWind, addr rect1			; Loop making sure the window exists.
	.while ( ! eax ) 
	invoke GetClientRect, hWind, addr rect1
	.endw


	xor		eax, eax								; Use Mod to get 
	mov		ax, word ptr Time.wMilliseconds			; random X position
	cdq
	idiv	dword ptr rect1.right
	mov		esi, edx								; X position is in ESI.
					

	xor		eax, eax								; Use Mod to get 
	mov		ax, word ptr Time.wMilliseconds			; random Y position
	cdq
	idiv	dword ptr rect1.bottom
	mov		edi, edx								; Y position is in EDI.


	xor		eax, eax								; Use MOD to pick random direction.
	mov		ax, time.wMilliseconds					
	cdq
	mov		ecx, 02h
	idiv	ecx


	mov horizontal, 1		
	.if ( edx == 0 ) 								
		mov	vertical, 1
	.else		
		mov	vertical, -1						
	.endif

	
	mov		ebx, lpColor
	mov		eax, [ebx]									; Set color as per 
	invoke	CreateSolidBrush, eax						; input parameter
	mov		hBrush, eax


	.while ( 1 ) 										; Do Forever..

		invoke GetClientRect, hWind, addr rect1
		
		mov eax, wdth
		add	eax, esi
		.if ( eax > rect1.right ) 						; check for right edge.
			mov	esi, rect1.right						; if so change direction.
			sub	esi, wdth															
			mov	horizontal, -1	
		.endif


		mov	eax, height
		add eax, edi
		.if ( eax > rect1.bottom )						; check for bottom edge
			mov	edi, rect1.bottom						; if so change direction.
			sub	edi, height			
			mov	vertical, -1
		.endif


		.if ( edi <= 1 ) 								; check for left edge
			mov	edi, 1									; if so change direction.
			mov vertical, 1
		.endif

		
		.if	( esi <= 1 ) 								; check for top edge.
			mov	esi, 1									; if so change direction.
			mov	horizontal, 1			  	
		.endif


		invoke 	GetDC, hWind							; get handle to DC
		mov		handleDC, eax

		invoke	SelectObject, handleDC, hBrush			; set brush color


		mov		eax, height
		add		eax, edi
		mov		ebx, wdth
		add		ebx, esi
		invoke	Rectangle, handleDC, esi, edi, ebx, eax ; draws a rectangle
		
		invoke	ReleaseDC, hWind, handleDC				; release DC
		
		add	esi, horizontal								; increment the X and
		add	edi, vertical								; Y positions.

	.endw
	
	ret	

AsmThreadProc endp

end
