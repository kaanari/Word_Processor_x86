        .MODEL  small, pascal
        INCLUDE tsr.inc

;* INSTALLATION SECTION - The following code and data are used only
;* during the TSR's installation phase. When the program terminates
;* through Function 31h, memory occupied by the following code and
;* data segments is returned to the operating system.

DGROUP  GROUP INSTALLCODE, INSTALLDATA

INSTALLDATA SEGMENT WORD PUBLIC 'DATA2' ; Data segment for installation phase

        PUBLIC  _MsgTbl

_MsgTbl WORD    Msg0                    ; Deinstalled okay
        WORD    Msg1                    ; Installed okay
        WORD    Msg2                    ; Already installed
        WORD    Msg3                    ; Can't install
        WORD    Msg4                    ; Can't find flag
        WORD    Msg5                    ; Can't deinstall
        WORD    Msg6                    ; Requires DOS 2+
        WORD    Msg7                    ; MCB damaged
        WORD    Msg8                    ; Invalid ID
        WORD    Msg9                    ; Invalid memory block address
        WORD    Msg10                   ; Successful access
        WORD    Msg11                   ; Can't access
        WORD    Msg12                   ; Unrecognized option

Msg0    BYTE    CR, LF, "TSR deinstalled", CR, LF, 0
Msg1    BYTE    CR, LF, "TSR installed", CR, LF, 0
Msg2    BYTE    CR, LF, "TSR already installed", CR, LF, 0
Msg3    BYTE    CR, LF, "Can't install TSR", CR, LF, 0
Msg4    BYTE    CR, LF, "Can't find MS-DOS Critical Error Flag", CR, LF, 0
Msg5    BYTE    CR, LF, "Can't deinstall TSR", CR, LF, 0
Msg6    BYTE    CR, LF, "Requires MS-DOS 2.0 or later", CR, LF, 0
Msg7    BYTE    CR, LF, "Memory Control Block damaged", CR, LF, 0
Msg8    BYTE    CR, LF, "No ID numbers available", CR, LF, 0
Msg9    BYTE    CR, LF, "Can't free memory block:  invalid address", CR, LF,0
Msg10   BYTE    CR, LF, "TSR successfully accessed", CR, LF, 0
Msg11   BYTE    CR, LF, "Can't access:  TSR not installed", CR, LF, 0
Msg12   BYTE    CR, LF, "Unrecognized option", CR, LF, 0

INSTALLDATA ENDS


INSTALLCODE SEGMENT PARA PUBLIC 'CODE2'

        ASSUME  ds:@data

;* GetOptions - Scans command line for argument of form /X or -X
;* where X = specified ASCII character. Presumes that argument is
;* preceded by either '/' or '-'. Comparisons are case insensitive.
;* Designed to be callable only from an assembly-language program.
;*
;* Params: ES = Segment address of Program Segment Prefix
;*         AL = Argument character for which to scan
;*
;* Return: AX    = One of the following codes:
;*                 NO_ARGUMENT  if empty command line
;*                 OK_ARGUMENT  if argument found
;*                 BAD_ARGUMENT if argument not as specified
;*         ES:DI = Pointer to found argument

GetOptions PROC NEAR

        and     al, 11011111y           ; Make character upper case
        mov     ah, NO_ARGUMENT         ; Assume no argument
        mov     di, 80h                 ; Point to command line
        sub     ch, ch
        mov     cl, BYTE PTR es:[di]    ; Command-line count
        jcxz    exit                    ; If none, quit
        sub     bx, bx                  ; Initialize flag

; Find start of argument

loop1:
        inc     di                      ; Point to next character
        mov     dl, es:[di]             ; Get character from argument list
        cmp     dl, '/'                 ; Find option prefix '/'
        je      analyze
        cmp     dl, '-'                 ;   or option prefix '-'
        je      analyze
        .IF     (dl != ' ') && (dl != TAB ) ; If not white space,
        inc     bx                      ; Set flag if command line not empty
        .ENDIF

        loop    loop1

        or      bx, bx                  ; Empty command line?
        jz      exit                    ; Yes?  Normal exit
        jmp     SHORT e_exit            ; Error if no argument is preceded
                                        ;   by '-' or '/' prefixes

; '/' or '-' prefix found. Compare command-line character
; with character specified in AL.
analyze:
        mov     ah, OK_ARGUMENT         ; Assume argument is okay
        inc     di
        mov     dl, es:[di]
        and     dl, 11011111y           ; Convert to upper-case
        cmp     dl, al                  ; Argument as specified?
        je      exit                    ; If so, normal exit
        mov     ah, BAD_ARGUMENT        ; Else signal bad argument,
        inc     bx                      ;   raise flag, and
        jmp     loop1                   ;   continue scan

e_exit:
        mov     ah, BAD_ARGUMENT
exit:
        mov     al, ah
        cbw                             ; AX = return code
        ret

GetOptions ENDP


;* FatalError - Displays an error message and exits to DOS.
;* Callable from a high-level language.
;*
;* Params: Err = Error number
;*
;* Return: AL = Error number returned to DOS (except DOS 1.x)

FatalError PROC FAR,
        Err:WORD

        mov     ax, Err
        push    ax
        mov     bx, @data
        mov     ds, bx                  ; DS points to DGROUP
        mov     bx, OFFSET _MsgTbl
        shl     ax, 1                   ; Double to get offset into _MsgTbl
        add     bx, ax                  ; BX = table index
        mov     si, [bx]                ; DS:SI points to message
        sub     bx, bx                  ; BH = page 0

        .WHILE  1
        lodsb                           ; Get character from ASCIIZ string
        .BREAK .IF al == 0              ; Break if null terminator
        mov     ah, 0Eh                 ; Request video Function 0Eh
        int     10h                     ; Display text, advance cursor
        .ENDW

        pop     ax                      ; Recover original error code

        .IF     ax == WRONG_DOS         ; If DOS error,
        int     20h                     ;   terminate Program (Version 1.x)
        .ELSE                           ; Else,
        mov     ah, 4Ch                 ;   request DOS Function 4Ch
        int     21h                     ;   terminate Program (2.x and later)
        .ENDIF

FatalError ENDP


;* GetResidentSize - Returns the number of paragraphs between Program
;* Segment Prefix (PSP) and beginning of INSTALLDATA. This is the size of
;* the program less the now-unneeded installation code and data -- in other
;* words, the size of the resident TSR block. The return value can serve as
;* the argument for the routine KeepTsr.
;*
;* Params: PspSeg - PSP segment address
;*
;* Return: AX = Number of paragraphs

GetResidentSize PROC FAR,
        PspSeg:WORD

        mov     ax, INSTALLDATA         ; Bottom of installation section
        inc     ax                      ;   plus one paragraph
        sub     ax, PspSeg              ; AX = number of paragraphs in
        ret                             ;   block to be made resident

GetResidentSize ENDP


;* KeepTsr -  Calls Terminate-and-Stay-Resident function to
;* make TSR resident. Callable from a high-level language.
;*
;* Params:  ParaNum - Number of paragraphs in resident block
;*
;* Return:  DOS return code = 0

KeepTsr PROC    FAR,
        ParaNum:WORD

        mov     ax, @data
        mov     ds, ax                  ; DS:SI points to "Program
        mov     si, OFFSET Msg1         ;   installed" message
        sub     bx, bx                  ; BH = page 0

        .WHILE  1
        lodsb                           ; Get character from ASCIIZ string
        .BREAK .IF al == 0              ; Break if null terminator
        mov     ah, 0Eh                 ; Request video Function 0Eh
        int     10h                     ; Display text, advance cursor
        .ENDW

        mov     dx, ParaNum             ; DX = number of paragraphs
        mov     ax, 3100h               ; Request Function 31h, err code = 0
        int     21h                     ; Terminate-and-Stay-Resident
        ret

KeepTsr ENDP


;* FreeTsr - Deinstalls TSR by freeing its two memory blocks: program
;* block (located at PSP) and environment block (located from address
;* at offset 2Ch of PSP). Callable from a high-level language.
;*
;* Params:  PspSeg - Segment address of TSR's Program Segment Prefix
;*
;* Return:  AX = 0 if successful, or one of the following error codes:
;*          MCB_DESTROYED       if Memory Control Block damaged
;*          INVALID_ADDR        if invalid block address

FreeTsr PROC    FAR,
        PspSeg:WORD

        mov     es, PspSeg              ; ES = address of resident PSP
        mov     ah, 49h                 ; Request DOS Function 49h
        int     21h                     ; Release memory in program block

        .IF     !carry?                 ; If no error:
        mov     es, es:[2Ch]            ; ES = address of environment block
        mov     ah, 49h                 ; Request DOS Function 49h
        int     21h                     ; Release Memory in environment block
        .IF     !carry?                 ; If no error:
        sub     ax, ax                  ; Return AX = 0
        .ENDIF                          ; Else exit with AX = error code
        .ENDIF

        ret

FreeTsr ENDP


;* CallMultiplexC - Interface for CallMultiplex procedure to make it
;* callable from a high-level language. Separating this ability from
;* the original CallMultiplex procedure keeps assembly-language calls
;* to CallMultiplex neater and more concise.
;*
;* Params: FuncNum - Function number for multiplex handler
;*         RecvPtr - Far address to recieve ES:DI pointer
;*
;* Return: One of the following return codes:
;*              NOT_INSTALLED      IS_INSTALLED       NO_IDNUM
;*         ES:DI pointer written to address in RecvPtr

CallMultiplexC PROC FAR USES ds si di,
        FuncNum:WORD, RecvPtr:FPVOID

        mov     al, BYTE PTR FuncNum    ; AL = function number
        call    CallMultiplex           ; Multiplex

        lds     si, RecvPtr             ; DS:SI = far address of pointer
        mov     [si], di                ; Return ES:DI pointer for the
        mov     [si+2], es              ;   benefit of high-level callers
        ret

CallMultiplexC ENDP


INSTALLCODE ENDS

        END
