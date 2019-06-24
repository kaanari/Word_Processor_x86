;----------------------------------------------------------------------------;
;                               SYSDATA.ASM                                  ;
;----------------------------------------------------------------------------;
; Sample program that accesses the SYSINFO.DLL functions.                    ;
;----------------------------------------------------------------------------;

		.model  small, pascal, nearstack
		.286

		?WINPROLOGUE = 1
		include win.inc                 ; Converted from WINDOWS.H
		include dll.inc                 ; SYSINFO.DLL definitions
		include sysdata.inc             ; equates for dialog controls

;----------------------------------------------------------------------------;
;                        Prototypes & External Definitions                   ;
;----------------------------------------------------------------------------;

NPBYTE          TYPEDEF NEAR PTR BYTE

WinMain         PROTO PASCAL, hInstance:HANDLE,  hPrevInstance:HANDLE,
			lpszCmdLine:LPSTR, nCmdShow:SWORD
WndProc         PROTO FAR PASCAL,  :HWND, :WORD, :SWORD, :SDWORD
SetDlg          PROTO,      :HWND
SetKeyb         PROTO,      :HWND
SetTime         PROTO,      :HWND
int2hex         PROTO,      :WORD, :NPBYTE
SetItem         PROTO,      :HWND, :WORD, :WORD

extern __astart:proc            ; When Windows load an app, it expects astart
				; to have the necessary start-up code. We get
				; astart from APPENTRY.ASM

;----------------------------------------------------------------------------;
;                             Numeric Equates                                ;
;----------------------------------------------------------------------------;

TIMER_SECS       EQU    1000t           ; timer interval: 1000 mill = 1 second
fNUMLOCK         EQU    020h            ; Flags within the Keyboard Status word
fCAPLOCK         EQU    040h            ; that indicate different key modes
fSHIFTS          EQU    003h
fCONTROL         EQU    004h


;----------------------------------------------------------------------------;
;                               Data Segments                                ;
;----------------------------------------------------------------------------;

	.const 

szAppName       SBYTE   "SysData",0                   
szSysIcon       SBYTE   "SysIcon",0
szTooManyTimers SBYTE   "Too many clocks or timers!",0

szError         SBYTE   "Error",0

szCoNotInst     SBYTE   "Not Found",0
szCoInst        SBYTE   "Found",0

szOff           SBYTE   "Off",0
szOn            SBYTE   "On",0

hex             BYTE    '0123456789ABCDEF'      ; Table of hexadecimal digits
						; for int2hex function
ProcTable       NPBYTE  sz8086
		NPBYTE  sz80186
		NPBYTE  sz80286
		NPBYTE  sz80386
		NPBYTE  sz80486

sz8086          SBYTE   "8086",0
sz80186         SBYTE   "80186",0
sz80286         SBYTE   "80286",0
sz80386         SBYTE   "80386",0
sz80486         SBYTE   "80486",0

		.data

HexValue        BYTE    "xxxxh",0
Initialized     BYTE    0
		
;----------------------------------------------------------------------------;
;                               Code Segment                                 ;
;----------------------------------------------------------------------------;

		.code

;----------------------------------------------------------------------------;
;                               WinMain                                      ;
;----------------------------------------------------------------------------;
;                                                                            ;
; Main routine called by Windows in program start. If no previous instances, ;
; sets up a window class and registers it, then sets up the message loop.    ;
;                                                                            ;
;----------------------------------------------------------------------------;

WinMain         PROC,   hInstance:HANDLE,  hPrevInstance:HANDLE,
			lpszCmdLine:LPSTR, nCmdShow:SWORD
		LOCAL   msg:MSG, wndclass:WNDCLASS

		; Local variables: msg: message to be used in the message loop
		;                  wndclass: temp. to store window class
		;                  x,y Start-Client: Size of Initial Window
;
;--- Check for previous instances
;
		.IF (hPrevInstance == 0)

			lea     di, wndclass    ; because we use a NEARSTACK,
			ASSUME  di:PTR WNDCLASS ; ss=ds

			mov     WORD PTR [di].lpfnWndProc,   LROFFSET WndProc
			mov     WORD PTR [di].lpfnWndProc+2, SEG WndProc

			mov     [di].cbWndExtra, DLGWINDOWEXTRA

			xor     ax,ax
			mov     [di].style,ax 
			mov     [di].cbClsExtra, ax

			INVOKE  LoadIcon, hInstance, ADDR szSysIcon 
			mov     [di].hIcon, ax 

			mov     ax, hInstance
			mov     [di].hInstance, ax

			INVOKE  LoadCursor, NULL, IDC_ARROW
			mov     [di].hCursor, ax

			mov     [di].hbrBackground, COLOR_WINDOW +1

			xor     ax, ax
			mov     WORD PTR [di].lpszMenuName,   ax
			mov     WORD PTR [di].lpszMenuName+2, ax

			mov     WORD PTR [di].lpszClassName,   OFFSET szAppName
			mov     WORD PTR [di].lpszClassName+2, ds

			INVOKE  RegisterClass, di
			.IF (ax == 0)
				mov     ax, FALSE
				jmp     doRet
			.ENDIF

			ASSUME  di:NOTHING        

		.ENDIF     ;--- End of IF (hPrevInstance == 0)

	INVOKE  CreateDialog, hInstance, ADDR szAppName, 0, NULL
	mov     si, ax
	INVOKE  ShowWindow, si, nCmdShow

;---- Create Timer for Window

		INVOKE  SetTimer, si, 1, TIMER_SECS, NULL
		.IF (ax == 0)
			INVOKE  MessageBox, si,ADDR szTooManyTimers, 
					    ADDR szAppName,
					    MB_ICONEXCLAMATION OR MB_OK
			mov     ax, FALSE
			INVOKE PostQuitMessage, 0               ; Quit.
		.ENDIF

;---- Message Loop

		.WHILE TRUE

			INVOKE  GetMessage,    ADDR msg, NULL, 0, 0

			.BREAK .IF (ax == 0)

			INVOKE  TranslateMessage, ADDR msg
			INVOKE  DispatchMessage,  ADDR msg

		.ENDW

		mov     ax, msg.wParam
doRet:
		ret

WinMain         ENDP


;----------------------------------------------------------------------------;
;                                  SetTime                                   ;
;                                                                            ;
; Reads the System Time with GetSysTime, sets up the Dialog Item TIME_TEXT   ;
; with the resulting string. Then does the same for DATE_TEXT.               ;
;----------------------------------------------------------------------------;

SetTime PROC, hDlg:HWND

		INVOKE  GetSysTime
		INVOKE  SetDlgItemText, hDlg, TIME_TEXT, dx::ax
		INVOKE  GetSysDate
		INVOKE  SetDlgItemText, hDlg, DATE_TEXT, dx::ax

		ret
SetTime ENDP


;----------------------------------------------------------------------------;
;                                  SetKeyb                                   ;
;                                                                            ;
; Assumes DI has the keyboard status. Gets the control's text into buffer.   ;
; If the control's status has changed (if buffer+1 is not what it would be   ;
; set to) then set it to On or Off, otherwise return                         ;
;----------------------------------------------------------------------------;

SetItem PROC, hDlg:HWND, item:WORD, flag:WORD
		LOCAL   buffer[3]:BYTE

	INVOKE  GetDlgItemText, hDlg, item, ADDR buffer, 3
	
	mov     bx, di
	and     bx, flag
	.IF bx
		.IF (byte ptr buffer+1 != 'n')       ; 'n' means we have 'On'
			mov     bx, OFFSET szOn
		.ELSE
			jmp     doRet
		.ENDIF
	.ELSE
		.IF (byte ptr buffer+1 != 'f')       ; 'f' means we have 'Off'
			mov     bx, OFFSET szOff
		.ELSE
			jmp     doRet
		.ENDIF
	.ENDIF
	INVOKE  SetDlgItemText, hDlg, item, ds::bx

doRet:  
	ret

SetItem ENDP


;----------------------------------------------------------------------------;
;                                  SetKeyb                                   ;
;                                                                            ;
; Reads the keyboard status with GetSysInfo, then uses SetItem to set the    ;
; appropiate controls in the dialog box.                                     ;
;----------------------------------------------------------------------------;

SetKeyb PROC, hDlg:HWND

		INVOKE  GetSysInfo
		mov     es, dx
		mov     si, ax
		ASSUME  SI:PTR SYSINFO
		mov     di, es:[si].wKbStatus
		INVOKE  SetItem, hDlg, NUMLOCK,fNUMLOCK
		INVOKE  SetItem, hDlg, CAPLOCK,fCAPLOCK
		INVOKE  SetItem, hDlg, CONTROL,fCONTROL
		INVOKE  SetItem, hDlg, SHIFTS, fSHIFTS
		ASSUME  SI:NOTHING

		ret
SetKeyb ENDP

;----------------------------------------------------------------------------;
;                                  SetDlg                                    ;
;                                                                            ;
; Reads the System Time with GetSysTime, sets up the Dialog Item TIME_TEXT   ;
; with the resulting string. Then does the same for DATE_TEXT. Then gets the ;
; other system information with GetSysInfo and sets the appropiate Dialog    ;
; Items. Note that KEYBSTAT and VIDEOMODE take the hex of the value returned.;
; Since ES is not guaranteed to be preserved, have to restore it after every ;
; SetDlgItemInt or Text. A table is used to look up the processor type.      ;
;----------------------------------------------------------------------------;

SetDlg  PROC, hDlg:HWND

		INVOKE  SetTime, hDlg
		INVOKE  SetKeyb, hDlg

		INVOKE  GetSysInfo
		mov     di, dx
		mov     si, ax

		ASSUME  SI:PTR SYSINFO

		lea     ax, [si].szWinVer
		INVOKE  SetDlgItemText, hDlg, WINVERSION, di::ax
		lea     ax, [si].szDOSVer
		INVOKE  SetDlgItemText, hDlg, DOSVERSION, di::ax
		lea     ax, [si].szROM
		INVOKE  SetDlgItemText, hDlg, ROMBIOS, di::ax

		mov     es, di
		mov     al, es:[si].cFloppy
		INVOKE  SetDlgItemInt, hDlg, FLOPPIES, al, FALSE

		mov     es, di
		mov     bl, es:[si].cVidMode
		INVOKE  int2hex, bl, ADDR HexValue
		INVOKE  SetDlgItemText, hDlg, VIDEOMODE, ADDR HexValue

		mov     es, di
		.IF es:[si].bCoproc
			mov     ax, OFFSET szCoInst
		.ELSE
			mov     ax, OFFSET szCoNotInst
		.ENDIF
		INVOKE  SetDlgItemText, hDlg, COPROC, ds::ax
		
		mov     es, di
		mov     bl, es:[si].cProcType
		.IF (bl < 5)
			xor     bh, bh
			shl     bx, 1
			mov     ax, ProcTable[bx]
		.ELSE
			mov     ax, OFFSET szError
		.ENDIF
		INVOKE  SetDlgItemText, hDlg, PROCTYPE, ds::ax

		ASSUME  SI:NOTHING

		ret
		
SetDlg  ENDP
		

;----------------------------------------------------------------------------;
; int2hex 
; Converts a WORD into its hexadecimal representation. 
; Based on Chapter 4 of the MASM Programmer's guide
;----------------------------------------------------------------------------;

int2hex PROC NEAR USES ax bx si, number:WORD, string:NPBYTE

	mov     bx, OFFSET hex          ; load table address
	mov     si, string

	mov     ax, number              ; load value to convert 
	shr     ax, 12                  ; shift right to get into table index
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si], al                ; store as last byte

	mov     ax, number              ; load value to convert 
	shr     ax, 8                   ; shift right to get into table index
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si+1], al              ; store as third to last byte

	mov     ax, number              ; load value to convert 
	shr     ax, 4                   ; shift right to get into table index
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si+2], al              ; store as second to last byte

	mov     ax, number              ; load value to convert 
	and     ax, 0000Fh              ; remove all but least-significant byte
	xlat                            ; translate
	mov     [si+3], al              ; store as last byte in string

	ret

int2hex ENDP


;----------------------------------------------------------------------------;
;                                  WndProc                                   ;
;                                                                            ;
; Because this is a Dialog Box/Window, we cannot intercept the WM_CREATE     ;
; message to set up the initial values of the Dialog Box. We have to wait for;
; the timer or the keyboard status to change to set values. Initialized is a ;
; flag to determine if the other values need to be set.                      ;
; If we get a timer message, set the time and date.                          ;
; If we get a KEYDOWN or KEYUP message, set the Keyboard Status              ;
; If we get a WININICHANGE, SETFOCUS, or SYSKEYUP, some data could change.   ;
;       Reset the dialog items                                               ; 
; A Close Window will get us out.                                            ;
;----------------------------------------------------------------------------;

WndProc         PROC FAR PASCAL, hWnd:HWND, iMessage:WORD, wParam:SWORD,
				 lParam:SDWORD
		; Windows gives us: the handle of the Window, the Message ID,
		; and two parameters for the message


		.IF (iMessage == WM_TIMER)
			.IF Initialized
				INVOKE  SetTime, hWnd
			.ELSE
				mov     Initialized, TRUE
				INVOKE  SetDlg, hWnd
			.ENDIF                  
			
		.ELSEIF (iMessage == WM_KEYDOWN) || (iMessage == WM_KEYUP)
			.IF Initialized
				INVOKE  SetKeyb, hWnd
			.ELSE
				mov     Initialized, TRUE
				INVOKE  SetDlg, hWnd
			.ENDIF                  
			
		.ELSEIF (iMessage == WM_SETFOCUS) || (iMessage == WM_SYSKEYUP)\
			|| (iMessage == WM_WININICHANGE)
			INVOKE  SetDlg, hWnd
			jmp doDefault

		.ELSEIF (iMessage==WM_DESTROY)
			INVOKE  KillTimer, hWnd, 1
			INVOKE  PostQuitMessage, 0

		.ELSE
doDefault:
			INVOKE  DefWindowProc, hWnd, iMessage, wParam,lParam
			jmp doRet

		.ENDIF

		mov ax, 0
		cwd
doRet:
		ret

WndProc         ENDP


		END  __astart   ; so that the code of the application will
					; start with the Windows start-up code



