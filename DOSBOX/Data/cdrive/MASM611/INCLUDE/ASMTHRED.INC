;
; Includes only the necessary structures, variables and procedures 
; for the Asmthred.asm sample.
; 

LPVOID		TYPEDEF		PTR 
PVOID		TYPEDEF		PTR 
HANDLE		TYPEDEF		PVOID
HWND		TYPEDEF		HANDLE
HDC			TYPEDEF		HANDLE
COLORREF	TYPEDEF		DWORD
HGDIOBJ		TYPEDEF		HANDLE
LONG		TYPEDEF		DWORD


_SYSTEMTIME		STRUCT 4t
wYear		WORD		?
wMonth		WORD		?
wDayOfWeek	WORD		?
wDay		WORD		?
wHour		WORD		?
wMinute		WORD		?
wSecond		WORD		?
wMilliseconds		WORD		?
_SYSTEMTIME		ENDS

LPSYSTEMTIME		TYPEDEF		PTR _SYSTEMTIME



tagRECT		STRUCT 4t
left		LONG		?
top			LONG		?
right		LONG		?
bottom		LONG		?
tagRECT		ENDS

LPRECT		TYPEDEF		PTR tagRECT
RECT		TYPEDEF		tagRECT


@proto_286		TYPEDEF		PROTO STDCALL :LPSYSTEMTIME
GetSystemTime		PROTO		@proto_286

@proto_1200		TYPEDEF		PROTO STDCALL :HWND, :LPRECT
GetClientRect		PROTO		@proto_1200

@proto_1160		TYPEDEF		PROTO STDCALL :HWND
GetDC		PROTO		@proto_1160

@proto_1163		TYPEDEF		PROTO STDCALL :HWND, :HDC
ReleaseDC		PROTO		@proto_1163

@proto_675		TYPEDEF		PROTO STDCALL :COLORREF
CreateSolidBrush		PROTO		@proto_675

@proto_789		TYPEDEF		PROTO STDCALL :HDC, :HGDIOBJ
SelectObject		PROTO		@proto_789

@proto_776		TYPEDEF		PROTO STDCALL :HDC, :SDWORD, :SDWORD, :SDWORD, :SDWORD
Rectangle		PROTO		@proto_776

