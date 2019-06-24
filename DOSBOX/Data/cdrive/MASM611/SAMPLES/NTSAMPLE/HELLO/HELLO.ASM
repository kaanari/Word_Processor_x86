.386
.MODEL flat, stdcall

STD_OUTPUT_HANDLE EQU -11

GetStdHandle PROTO NEAR32 stdcall,
    nStdHandle:DWORD

WriteFile PROTO NEAR32 stdcall,
    hFile:DWORD, lpBuffer:NEAR32, nNumberOfBytesToWrite:DWORD,
    lpNumberOfBytesWritten:NEAR32, lpOverlapped:NEAR32

ExitProcess PROTO NEAR32 stdcall,
    dwExitCode:DWORD

.STACK 4096

.DATA

msg DB "Hello, world.", 13, 10
written DD 0
hStdOut DD 0

.CODE
_start:
    INVOKE  GetStdHandle,
        STD_OUTPUT_HANDLE      ; Standard output handle
    mov hStdOut, eax

    INVOKE  WriteFile,
        hStdOut,               ; File handle for screen
        NEAR32 PTR msg,        ; Address of string
        LENGTHOF msg,          ; Length of string
        NEAR32 PTR written,    ; Bytes written
        0                      ; Overlapped mode

    INVOKE  ExitProcess,
        0                      ; Result code for parent process

PUBLIC _start
END

