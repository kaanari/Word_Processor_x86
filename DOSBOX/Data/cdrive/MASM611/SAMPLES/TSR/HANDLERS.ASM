        .MODEL  small, pascal
        INCLUDE tsr.inc

        .CODE

; Stack buffer used by TSR. Size is determined by constant STACK_SIZ,
; declared in TSR.INC file. NewStack points to top of stack.

         EVEN
         BYTE   STACK_SIZ DUP(?)        ; Stack buffer
NewStack LABEL BYTE                     ; Pointer to top of stack

; Structures for interrupt handlers or "interrupt service routines."
; The following handlers are replaced during installation. Such routines
; usually set a flag to indicate they are active, call the original
; interrupt handler, optionally do some processing (such as detecting a
; hot key), and when finished clear the active flag.

HandArray       LABEL   BYTE                    ; Array of handler structures
;                Num   Flag     OldHand  NewHand
intClock  INTR  < 8h,  FALSE,   NULL,    Clock>
intKeybrd INTR  < 9h,  FALSE,   NULL,    Keybrd>
intVideo  INTR  <10h,  FALSE,   NULL,    Video>
intDiskIO INTR  <13h,  FALSE,   NULL,    DiskIO>
intMisc   INTR  <15h,  FALSE,   NULL,    SkipMiscServ>
intIdle   INTR  <28h,  FALSE,   NULL,    Idle>
intMultex INTR  <2Fh,  FALSE,   NULL,    Multiplex>

CHAND   EQU     ($ - HandArray) / (SIZEOF INTR) ; Number of handlers in array

; Interrupt trap routines. These interrupt routines are set up
; temporarily to trap keyboard break errors and critical errors
; while the TSR is active. When the TSR finishes its tasks, it
; restores the old interrupts before returning.

TrapArray       LABEL   BYTE                    ; Array of trap structures
;                Num   Flag     OldHand  NewHand
intCtrlBk INTR  <1Bh,  FALSE,   NULL,    CtrlBreak>
intCtrlC  INTR  <23h,  FALSE,   NULL,    CtrlC>
intCritEr INTR  <24h,  FALSE,   NULL,    CritError>

CTRAP   EQU     ($ - TrapArray) / (SIZEOF INTR) ; Number of traps in array

; Address of application's stack. Before calling the main body of the TSR,
; the Activate procedure stores the application's stack address, then resets
; SS:SP to point to LABEL NewStack (see above). This gives the TSR its own
; stack space without making demands on the current stack. Activate restores
; the application's stack before returning.

OldStackAddr    FPVOID  ?               ; SS:SP pointer to application stack

; The TSR must set up its own disk transfer area if it calls DOS functions
; that use the DTA (see section "Preserving Existing Data" in Chapter 11 of
; the Programmer's Guide). DTA_SIZ is defined in the TSR.INC include file.

                IFDEF   DTA_SIZ
OldDtaAddr      FPVOID  ?               ; Address of application's DTA
DtaBuff         BYTE    DTA_SIZ DUP(?)  ; DTA buffer
                ENDIF

; Multiplex data. STR_LEN is defined in the TSR.INC include file

IDnumber        BYTE    0               ; TSR's identity number
IDstring        BYTE    STR_LEN DUP (0) ; Copy of identifier string
IDstrlen        WORD    ?               ; Length of identifier string
ShareAddr       FPVOID  ?               ; Address of shared memory

; Miscellaneous data

TsrRequestFlag  BYTE    FALSE           ; Flag set when hot key is pressed
TsrActiveFlag   BYTE    FALSE           ; Flag set when TSR executes
BreakCheckFlag  BYTE    ?               ; Break-checking status of application
TsrPspSeg       WORD    ?               ; Segment address of PSP
TsrAddr         FPVOID  ?               ; Pointer to main part of TSR
CritErrAddr     FPVOID  ?               ; Pointer to MS-DOS critical error flag
InDosAddr       FPVOID  ?               ; Pointer to MS-DOS InDos flag

; Scan and shift codes for hot key. Install procedure initializes
; HotScan, HotShift, and HotMask during installation.

HotScan         BYTE    ?               ; Scan code hot key
HotShift        BYTE    ?               ; Shift value of hot key
HotMask         BYTE    ?               ; Mask unwanted shift values

Version         LABEL   WORD            ; DOS version number
minor           BYTE    ?
major           BYTE    ?

; Timer data, used when the TSR is activated at a preset time instead
; of activated from the keyboard. The following variables serve the
; same purposes as the counter variables used in the ALARM.ASM program
; presented in Chapter 11 of the Programmer's Guide. Refer to the
; header comments in the Install procedure for an explanation of how
; to set up a time-activated TSR.

Tick91          BYTE    91              ; Measures 91 timer ticks (5 seconds)
CountDown       WORD    0               ; Counts 5-second intervals



;* Clock - Interrupt handler for Interrupt 08 (timer). Executes at each
;* timer interrupt; these occur an average of 18.2 times per second. Clock
;* first allows the original timer service routine to execute. It then
;* checks the flag TsrRequestFlag maintained either by the keyboard handler
;* (if keyboard activated) or by this procedure (if time activated). If
;* TsrRequestFlag = TRUE and system is okay, Clock invokes the TSR by
;* calling the Activate procedure. Uses an active flag to prevent the
;* Clock procedure from being reentered while executing.
;*
;* Uses:   intClock, TsrActiveFlag, CountDown
;*
;* Params: None
;*
;* Return: None

Clock   PROC    FAR

        pushf                           ; Simulate interrupt by pushing flags,
        call    cs:intClock.OldHand     ;   far calling orig Int 08 routine

        .IF     cs:intClock.Flag == FALSE ; If not already in this handler:
        mov     cs:intClock.Flag, TRUE  ; Set active flag

        sti                             ; Interrupts are okay
        push    ds                      ; Save application's DS
        push    cs
        pop     ds                      ; Set DS to resident code segment
        ASSUME  ds:@code

        call    CheckRequest            ; Check conditions
        .IF     !carry?                 ; If TSR requested and safe,
        mov     TsrActiveFlag, TRUE     ;   activate TSR
        call    Activate
        mov     TsrActiveFlag, FALSE
        .ENDIF                          ; End carry flag check

        cmp     CountDown, 0            ; If CountDown = 0, TSR is not time
        je      ticked                  ;   activated or has already executed
        dec     Tick91                  ; Else count down 91 timer ticks
        jnz     ticked                  ; If 91 ticks have not elapsed, exit
        mov     Tick91, 91              ; Else reset secondary counter and
        dec     CountDown               ;   subract one 5-second interval
        ja      ticked                  ; If counter not yet drained, exit
        mov     TsrRequestFlag, TRUE    ; Else raise request flag
ticked:
        mov     intClock.Flag, FALSE    ; Clear active flag
        pop     ds                      ; Recover application's DS
        ASSUME  ds:NOTHING

        .ENDIF                          ; End in-handler check
        iret

Clock   ENDP


;* Keybrd - Interrupt handler for Interrupt 09 (keyboard).
;*
;* IBM PC/AT and compatibles:
;*      Gets the scan code of the current keystroke from port 60h. Then
;*      compares the scan code and shift state to the hot key. If they
;*      match, sets TsrRequestFlag to signal the handlers Clock and Idle
;*      that the TSR is requested.
;* 
;* IBM PS/2 series:
;*      Only the instructions at KeybrdMonitor (see below) are installed
;*      as Interrupt 09 handler, since above method should not be used to
;*      determine current keystroke in IBM PS/2 series. In this case, the
;*      Interrupt 15h handler MiscServ takes care of checking the scan codes
;*      and setting the request flag when the hot key is pressed.
;*
;* Time-activated TSRs:
;*      If the TSR is activated by time instead of by a hotkey, KeybrdMonitor
;*      serves as the Interrupt 09 handler for both PC/AT and PS/2 systems.
;*
;* Uses:   intKeybrd, TsrRequestFlag
;* 
;* Params: None
;*
;* Return: None

Keybrd  PROC    FAR

        sti                             ; Interrupts are okay
        push    ax                      ; Save AX register
        in      al, 60h                 ; AL = scan code of current key
        call    CheckHotKey             ; Check for hot key
        .IF     !carry?                 ; If not hot key:

; Hot key pressed. Reset the keyboard to throw away keystroke.

        cli                             ; Disable interrupts while resetting
        in      al, 61h                 ; Get current port 61h state
        or      al, 10000000y           ; Turn on bit 7 to signal clear keybrd
        out     61h, al                 ; Send to port
        and     al, 01111111y           ; Turn off bit 7 to signal break
        out     61h, al                 ; Send to port
        mov     al, 20h                 ; Reset interrupt controller
        out     20h, al
        sti                             ; Reenable interrupts

        pop     ax                      ; Recover AX
        mov     cs:TsrRequestFlag, TRUE ; Raise request flag
        iret                            ; Exit interrupt handler
        .ENDIF                          ; End hot-key check

; No hot key was pressed, so let normal Int 09 service routine take over

        pop     ax                      ; Recover AX and fall through
        cli                             ; Interrupts cleared for service

KeybrdMonitor LABEL FAR                 ; Installed as Int 09 handler for
                                        ;   PS/2 or for time-activated TSR
        mov     cs:intKeybrd.Flag, TRUE ; Signal that interrupt is busy
        pushf                           ; Simulate interrupt by pushing flags,
        call    cs:intKeybrd.OldHand    ;   far calling old Int 09 routine
        mov     cs:intKeybrd.Flag, FALSE
        iret

Keybrd  ENDP


;* Video - Interrupt handler for Interrupt 10h (video). Allows the original
;* video service routine to execute. Maintains an active flag to prevent
;* the TSR from being called while Interrupt 10h is executing.
;*
;* Uses:   intVideo
;*
;* Params: Registers passed to Interrupt 10h
;*
;* Return: Registers returned by Interrupt 10h

Video   PROC    FAR

        mov     cs:intVideo.Flag, TRUE  ; Set active flag
        pushf                           ; Simulate interrupt by pushing flags,
        call    cs:intVideo.OldHand     ;   far calling old Int 10h routine
        mov     cs:intVideo.Flag, FALSE ; Clear active flag
        iret

Video   ENDP


;* DiskIO - Interrupt handler for Interrupt 13h (disk I/O). Allows the
;* original disk I/O service routine to execute. Maintains an active flag
;* to prevent the TSR from being called while Interrupt 13h is executing.
;*
;* Uses:   intDiskIO
;*
;* Params: Registers passed to Interrupt 13h
;*
;* Return: Registers and the carry flag returned by Interrupt 13h

DiskIO  PROC    FAR

        mov     cs:intDiskIO.Flag, TRUE ; Set active flag
        pushf                           ; Simulate interrupt by pushing flags,
        call    cs:intDiskIO.OldHand    ;   far calling old Int 13h routine
        mov     cs:intDiskIO.Flag, FALSE; Clear active flag without
                                        ;   disturbing flags register
        sti                             ; Enable interrupts
        ret     2                       ; Simulate IRET without popping flags
                                        ;   (since services use carry flag)
DiskIO  ENDP


;* MiscServ - Interrupt handler for Interrupt 15h (Miscellaneous System
;* Services).
;*
;* IBM PC/AT and compatibles:
;*     Stub at SkipMiscServ is used as handler, bypassing all calls to
;*     Interrupt 15h. Keypresses are checked by Keybrd (Int 09 handler).
;* 
;* IBM PS/2 series:
;*     This procedure handles calls to Interrupt 15h, searching for
;*     Function 4Fh (Keyboard Intercept Service). When AH = 4Fh, gets
;*     scan code of current keystroke in AL register. Then compares the
;*     scan code and shift state to the hot key. If they match, sets
;*     TsrRequestFlag to signal the handlers Clock and Idle that the
;*     TSR is requested.
;*
;* Uses:   intMisc, TsrRequestFlag
;*
;* Params: Registers passed to Interrupt 15h
;*
;* Return: Registers returned by Interrupt 15h

MiscServ PROC   FAR

        sti                             ; Interrupts okay
        .IF     ah == 4Fh               ; If Keyboard Intercept Service,
        push    ax                      ;   preserve AX,
        call    CheckHotKey             ;   check for hot key
        pop     ax
        .IF     !carry?                 ; If hot key,
        mov     cs:TsrRequestFlag, TRUE ;   raise request flag,
        clc                             ;   signal BIOS not to process the key,
        ret     2                       ;   simulate IRET without popping flags
        .ENDIF                          ; End carry flag check
        .ENDIF                          ; End Keyboard Intercept check

        cli                             ; Disable interrupts and fall through

SkipMiscServ LABEL FAR                  ; Interrupt 15h handler if PC/AT

        jmp     cs:intMisc.OldHand

MiscServ ENDP


;* CtrlBreak - Interrupt trap for Interrupt 1Bh (CTRL+BREAK Handler).
;* Disables CTRL+BREAK processing.
;*
;* Params: None
;*
;* Return: None

CtrlBreak PROC  FAR

        iret

CtrlBreak ENDP


;* CtrlC - Interrupt trap for Interrupt 23h (CTRL+C Handler).
;* Disables CTRL+C processing.
;*
;* Params: None
;*
;* Return: None

CtrlC   PROC    FAR

        iret

CtrlC   ENDP


;* CritError - Interrupt trap for Interrupt 24h (Critical Error Handler).
;* Disables critical error processing.
;*
;* Params: None
;*
;* Return: AL = Stop code 0 or 3

CritError PROC  FAR

        sti
        sub     al, al                  ; Assume DOS 2.x
                                        ; Set AL = 0 for ignore error
        .IF     cs:major != 2           ; If DOS 3.x, set AL = 3
        mov     al, 3                   ; DOS call fails
        .ENDIF

        iret

CritError ENDP


;* Idle - Interrupt handler for Interrupt 28h (DOS Idle). Allows the
;* original Interrupt 28h service routine to execute. Then checks the
;* request flag TsrRequestFlag maintained either by the keyboard handler
;* (keyboard-activated TSR) or by the timer handler (time-activated TSR).
;* See header comments above for Clock, Keybrd, and MiscServ procedures.
;*
;* If TsrRequestFlag = TRUE and system is in interruptable state, Idle
;* invokes the TSR by calling the Activate procedure. Uses an active flag
;* to prevent the Idle procedure from being reentered while executing.
;*
;* Uses:   intIdle and TsrActiveFlag
;*
;* Params: None
;*
;* Return: None

Idle    PROC    FAR

        pushf                           ; Simulate interrupt by pushing flags,
        call    cs:intIdle.OldHand      ;   far-calling old Int 28h routine

        .IF     cs:intIdle.Flag == FALSE; If not already in this handler,
        mov     cs:intIdle.Flag, TRUE   ;   set active flag

        sti                             ; Interrupts are okay
        push    ds                      ; Save application's DS
        push    cs
        pop     ds                      ; Set DS to resident code segment
        ASSUME  ds:@code

        call    CheckRequest            ; Check conditions
        .IF     !carry?                 ; If TSR requested and safe,
        mov     TsrActiveFlag, TRUE     ;   activate TSR
        call    Activate
        mov     TsrActiveFlag, FALSE
        .ENDIF                          ; End carry flag check

        mov     intIdle.Flag, FALSE     ; Clear active flag
        pop     ds                      ; Recover application's DS
        .ENDIF                          ; End in-handler check

        iret

Idle    ENDP


;* Multiplex - Handler for Interrupt 2Fh (Multiplex Interrupt). Checks
;* AH for this TSR's identity number. If no match (indicating call is
;* not intended for this TSR), Multiplex passes control to the previous
;* Interrupt 2Fh handler.
;*
;* Params: AH = Handler identity number
;*         AL = Function number 0-2
;*
;* Return: AL    = 0FFh (function 0)
;*         ES:DI = Pointer to identifier string (function 0)
;*         ES:DI = Pointer to resident PSP segment (function 1)
;*         ES:DI = Pointer to shared memory (function 2)

Multiplex PROC  FAR

        .IF     ah != cs:IDnumber       ; If this handler not requested,
        jmp     cs:intMultex.OldHand    ;   pass control to old Int 2Fh
        .ENDIF                          ;   handler

        .IF     al == 0                 ; If function 0 (verify presence),
        mov     al, 0FFh                ;   AL = 0FFh,
        push    cs                      ;   ES = resident code segment
        pop     es
        mov     di, OFFSET IDstring     ;   DI = offset of identifier string

        .ELSEIF al == 1                 ; If function 1 (get PSP address),
        mov     es, cs:TsrPspSeg        ;   ES:DI = far address of resident PSP
        sub     di, di

        .ELSE
        les     di, cs:ShareAddr        ; If function 2 (get shared memory),
        .ENDIF                          ;   set ES:DI = far address

NoMultiplex LABEL  FAR                  ; Secondary entry for null Multiplex

        iret

Multiplex ENDP


;* CheckHotKey - Checks current keystroke for hot key. Called from Keybrd
;* handler if IBM PC/AT or compatible, or from MiscServ handler if PS/2.
;*
;* Uses:   HotScan, HotShift, HotMask, and SHFT_STAT
;*
;* Params: AL = Scan code
;*
;* Return: Carry flag set = FALSE; carry flag clear = TRUE

CheckHotKey PROC NEAR

        cmp     al, cs:HotScan          ; If current scan code isn't code
        jne     e_exit                  ;   for hot key, exit with carry set

        push    es                      ; Else look into BIOS data area
        sub     ax, ax                  ;   (segment 0) to check shift state
        mov     es, ax
        mov     al, es:[SHFT_STAT]      ; Get SHIFT-key flags
        and     al, cs:HotMask          ; AND with "don't care" mask
        cmp     al, cs:HotShift         ; Compare result with hot SHIFT key
        pop     es
        je      exit                    ; If match, exit with carry clear

e_exit: stc                             ; Set carry if not hot key
exit:   ret

CheckHotKey ENDP


;* CheckRequest - Checks request flag and system status using the 
;* following logic:
;*
;*         IF (TsrRequestFlag AND (NOT TsrActiveFlag)
;*             AND DosStatus AND HardwareStatus)
;*             return TRUE
;*         ELSE
;*             return FALSE
;*
;* Uses:   TsrRequestFlag and TsrActiveFlag
;*
;* Params: DS = Resident code segment
;*
;* Return: Carry flag set = TRUE; carry flag clear = FALSE

CheckRequest PROC NEAR

        rol     TsrRequestFlag, 1       ; Rotate high bit into carry - set
                                        ;   if TRUE (-1), clear if FALSE (0)
        cmc                             ; NOT carry

        .IF     !carry?                 ; If TsrRequestFlag = TRUE:
        ror     TsrActiveFlag, 1        ; Rotate low bit into carry - set
                                        ;   if TRUE (-1), clear if FALSE (0)
        .IF     !carry?                 ; If TsrActiveFlag = FALSE:
        call    CheckDos                ; Is DOS in interruptable state?

        .IF     !carry?                 ; If so,
        call    CheckHardware           ;   if hardware or BIOS unstable,
        .ENDIF                          ;   set carry and exit
        .ENDIF
        .ENDIF
        ret

CheckRequest ENDP


;* CheckDos - Checks status of MS-DOS using the following logic:
;*
;*         IF (NOT CritErr) AND ((NOT InDos) OR (Idle AND InDos))
;*             return DosStatus = TRUE
;*         ELSE
;*             return DosStatus = FALSE
;*
;* Uses:   CritErrAddr, InDosAddr, and intIdle
;*
;* Params: DS = Resident code segment
;*
;* Return: Carry flag set if MS-DOS is busy

CheckDos PROC   NEAR USES es bx ax

        les     bx, CritErrAddr
        mov     ah, es:[bx]             ; AH = value of CritErr flag

        les     bx, InDosAddr
        mov     al, es:[bx]             ; AL = value of InDos flag

        sub     bx, bx                  ; BH = 0, BL = 0
        cmp     bl, intIdle.Flag        ; Carry flag set if call is from
                                        ;   Interrupt 28h handler
        rcl     bl, 1                   ; Rotate carry into BL: TRUE if Idle
        cmp     bx, ax                  ; Carry flag clear if CritErr = 0
                                        ;   and InDos <= BL
        ret

CheckDos ENDP


;* CheckHardware - Checks status of BIOS and hardware using the
;* following logic:
;*
;*         IF HardwareActive OR KeybrdActive OR VideoActive OR DiskIOActive
;*             return HardwareStatus = FALSE
;*         ELSE
;*             return HardwareStatus = TRUE
;*
;* Uses:   intKeybrd, intVideo, and intDiskIO
;*
;* Params: DS = Resident code segment
;*
;* Return: Carry flag set if hardware or BIOS is busy

CheckHardware PROC NEAR USES ax

; Verify hardware interrupt status by interrogating Intel 8259A
; Programmable Interrupt Controller

        mov     ax, 00001011y           ; AL = 0CW3 for Intel 8259A
                                        ;   (RR = 1, RIS = 1)
        out     20h, al                 ; Request 8259A in-service register
        jmp     delay                   ; Wait a few cycles
delay:
        in      al, 20h                 ; AL = hardware interrupts being
        cmp     ah, al                  ;   serviced (bit = 1 if in service)

        .IF     !carry?                 ; If no hard interrupts in service,
        sub     al, al                  ;   verify BIOS interrupts not active,
        cmp     al, intKeybrd.Flag      ;   check Interrupt 09 handler

        .IF     !carry?                 ; If Int 09 not active,
        cmp     al, intVideo.Flag       ;   check Interrupt 10h handler

        .IF     !carry?                 ; If Int 10h not active,
        cmp     al, intDiskIO.Flag      ;   check Interrupt 13h handler,
        .ENDIF                          ;   return with carry set if
        .ENDIF                          ;   Interrupt 09, 10h, or 13h
        .ENDIF                          ;   is active

        ret

CheckHardware ENDP


;* Activate - Sets up for far call to TSR with the following steps:
;*
;*   1.  Stores stack pointer SS:SP and switches to new stack
;*   2.  Pushes registers onto new stack
;*   3.  Stores vectors for Interrupts 1Bh, 23h, and 23h, and
;*       replaces them with addresses of error-trapping handlers
;*   4.  Stores DOS CTRL+C checking flag, then turns off checking
;*   5.  If required, stores DTA address and switches to new DTA
;*
;* When TSR returns, restores all the above.
;*
;* Uses:   Reads or writes the following globals:
;*         OldStackAddr, TrapArray, BreakCheckFlag, TsrRequestFlag
;*
;* Params: DS = Resident code segment
;*
;* Return: None

Activate PROC   NEAR

; Step 1.  Set up a new stack

        mov     WORD PTR OldStackAddr[0], sp    ; Save current 
        mov     WORD PTR OldStackAddr[2], ss    ;   stack pointer

        cli                                     ; Turn off interrupts while
        push    cs                              ;   changing stack
        pop     ss                              ; New stack begins
        mov     sp, OFFSET NewStack             ;   at LABEL NewStack
        sti

; Step 2.  Preserve registers (DS already saved in Clock or Idle)

        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        push    es

        cld                                     ; Clear direction flag

; Step 3.  Set up trapping handlers for keyboard breaks and DOS
; critical errors (Interrupts 1Bh, 23h, and 24h)

        mov     cx, CTRAP                       ; CX = number of handlers
        mov     si, OFFSET TrapArray            ; DS:SI points to trap array

        .REPEAT
        mov     al, [si]                        ; AL = interrupt number
        mov     ah, 35h                         ; Request DOS Function 35h
        int     21h                             ; Get interrupt vector (ES:BX)
        mov     WORD PTR [si].INTR.OldHand[0], bx ; Save far address of
        mov     WORD PTR [si].INTR.OldHand[2], es ;   application's handler
        mov     dx, WORD PTR [si].INTR.NewHand[0] ; DS:DX points to TSR's hand
        mov     ah, 25h                         ; Request DOS Function 25h
        int     21h                             ; Set interrupt vector
        add     si, SIZEOF INTR                 ; DS:SI points to next in list
        .UNTILCXZ

; Step 4.  Disable MS-DOS break checking during disk I/O

        mov     ax, 3300h               ; Request DOS Function 33h
        int     21h                     ; Get CTRL+BREAK flag in DL
        mov     BreakCheckFlag, dl      ; Preserve it

        sub     dl, dl                  ; DL = 0 to disable I/O break checking
        mov     ax, 3301h               ; Request DOS Function 33h
        int     21h                     ; Set CTRL+BREAK flag from DL

; Step 5.  If TSR requires a disk transfer area, store address of current
; DTA and switch buffer address to this segment. See Help and section 
; "Preserving Existing Data" in Chapter 11 of the Programmer's Guide for
; more information about the DTA. 

        IFDEF   DTA_SIZ
        mov     ah, 2Fh                         ; Request DOS Function 2Fh
        int     21h                             ; Get DTA Address into ES:BX
        mov     WORD PTR OldDtaAddr[0], bx      ; Store address
        mov     WORD PTR OldDtaAddr[2], es

        mov     dx, OFFSET DtaBuff              ; DS:DX points to new DTA
        mov     ah, 1Ah                         ; Request DOS Function 1Ah
        int     21h                             ; Set DTA Address
        ENDIF

; Call main body of TSR.

        mov     ax, @data
        mov     ds, ax                          ; Initialize DS and ES
        mov     es, ax                          ;   to data segment

        call    cs:TsrAddr                      ; Call main part of TSR

        push    cs
        pop     ds                              ; Reset DS to this segment

; Undo step 5.  Restore previous DTA (if required)

        IFDEF   DTA_SIZ
        push    ds                      ; Preserve DS
        lds     dx, OldDtaAddr          ; DS:DX points to application's DTA
        mov     ah, 1Ah                 ; Request DOS Function 1Ah
        int     21h                     ; Set DTA Address
        pop     ds
        ENDIF

; Undo step 4.  Restore previous MS-DOS break checking

        mov     dl, BreakCheckFlag      ; DL = previous break state
        mov     ax, 3301h               ; Request DOS Function 33h
        int     21h                     ; Set CTRL+BREAK flag from DL

; Undo step 3.  Restore previous vectors for error-trapping handlers

        mov     cx, CTRAP
        mov     di, OFFSET TrapArray
        push    ds                      ; Preserve DS
        push    ds                      ; ES = resident code segment
        pop     es

        .REPEAT
        mov     al, es:[di]             ; AL = interrupt number
        lds     dx, es:[di].INTR.OldHand; DS:DX points to application's handler
        mov     ah, 25h                 ; Request DOS Function 25h
        int     21h                     ; Set interrupt vector from DS:DX
        add     di, SIZEOF INTR         ; ES:DI points to next in list
        .UNTILCXZ
        pop     ds

; Undo step 2.  Restore registers from stack

        pop     es
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax

; Undo step 1.  Restore address of original stack to SS:SP

        cli
        mov     sp, WORD PTR OldStackAddr[0]
        mov     ss, WORD PTR OldStackAddr[2]
        sti

; Clear request flag and return to caller (Clock or Idle procedure)

        mov     TsrRequestFlag, FALSE
        ret

Activate ENDP



;* INSTALLATION SECTION - The following code is executed only during
;* the TSR's installation phase. When the program terminates through
;* Function 31h, the above code and data remain resident; memory
;* occupied by the following code segment is returned to the operating
;* system.

DGROUP  GROUP INSTALLCODE

INSTALLCODE SEGMENT PARA PUBLIC 'CODE2'
        ASSUME  ds:@code

;* Install - Prepares for installation of a TSR by chaining interrupt
;* handlers and initializing pointers to DOS flags. Install does not
;* call the Terminate-and-Stay-Resident function.
;*
;* This library of routines accommodates both keyboard-activated and
;* time-activated TSRs. The latter are TSRs that activate at a preset
;* time. If the first parameter (Param1) is a valid scan code, Install
;* assumes the TSR is activated from the keyboard and sets up a keyboard
;* handler to search for the hot key. If Param1 is null, Install assumes
;* the next two parameters (Param2 and Param3) are respectively the hour
;* and minute at which the TSR is to activate. In this case, Install 
;* calls GetTimeToElapse to initialize the variable CountDown and sets
;* up KeybrdMonitor as the keyboard handler. CountDown and the secondary
;* counter Tick91 serve here the same functions as they do for the
;* ALARM.ASM program presented in Chapter 11 of the Programmer's Guide.
;* Install is callable from a high-level language.
;*
;* Uses:   InDosAddr, CritErrAddr, CHAND,
;*         HandArray, CTRAP, TrapArray
;*
;*                  Keyboard-activated                 Time-activated
;*                  ------------------                 --------------
;* Params: Param1 - Scan code for hot key              0
;*         Param2 - Bit value for shift hot key        Hour to activate
;*         Param3 - Bit mask for shift hot key         Minute to activate
;*         Param4 - Far address of main TSR procedure  (same)
;*
;* Return: AX = 0 if successful, or one of the following codes:
;*         IS_INSTALLED           FLAGS_NOT_FOUND        NO_IDNUM
;*         ALREADY_INSTALLED      WRONG_DOS

Install PROC    FAR USES ds si di,
        Param1:WORD, Param2:WORD, Param3:WORD, Param4:FAR PTR FAR

        mov     ax, @code
        mov     ds, ax                          ; Point DS to code segment

; Get and store parameters passed from main program module

        mov     al, BYTE PTR Param1
        mov     HotScan, al                     ; Store hot-key scan code
        mov     al, BYTE PTR Param2             ;   or flag for time activate
        mov     HotShift, al                    ; Store hot-key shift value
        mov     al, BYTE PTR Param3             ;   or hour value
        mov     HotMask, al                     ; Store hot-key shift mask
                                                ;   or minute value
        mov     ax, WORD PTR Param4[0]
        mov     bx, WORD PTR Param4[2]
        mov     WORD PTR TsrAddr[0], ax         ; Store segment:offset of
        mov     WORD PTR TsrAddr[2], bx         ;   TSR's main code

; Get addresses of DOS flags, then check for prior installation

        call    GetDosFlags             ; Find DOS service flags
        or      ax, ax
        jnz     exit                    ; If flags not found, quit

        sub     al, al                  ; Request multiplex function 0
        call    CallMultiplex           ; Invoke Interrupt 2Fh
        cmp     ax, NOT_INSTALLED       ; Check for presence of resident TSR

        .IF     !zero?                  ; If TSR is installed,
        cmp     ax, IS_INSTALLED        ;   return with appropriate
        jne     exit                    ;   error code
        mov     ax, ALREADY_INSTALLED
        jmp     exit
        .ENDIF

; Check if TSR is to activate at the hour:minute specified by Param2:Param3.
; If so, determine the number of 5-second intervals that must elapse before
; activation, then set up the code at the far LABEL KeybrdMonitor to serve
; as the keyboard handler.

        .IF     HotScan == 0            ; If valid scan code given,
        mov     ah, HotShift            ;   AH = hour to activate
        mov     al, HotMask             ;   AL = minute to activate
        call    GetTimeToElapse         ; Get number of 5-second intervals
        mov     CountDown, ax           ;   to elapse before activation

        .ELSE                           ; Force use of KeybrdMonitor as
                                        ;   keyboard handler
        cmp     Version, 031Eh          ; DOS Version 3.3 or higher?
        jb      setup                   ; No?  Skip next step

; Test for IBM PS/2 series. If not PS/2, use Keybrd and SkipMiscServ as
; handlers for Interrupts 09 and 15h respectively. If PS/2 system, set up
; KeybrdMonitor as the Interrupt 09 handler. Audit keystrokes with MiscServ
; handler, which searches for the hot key by handling calls to Interrupt 15h
; (Miscellaneous System Services). For more information about keyboard
; handlers, refer to the section "Auditing Hardware Events for TSR Requests"
; in Chapter 11 of the Programmer's Guide

        mov     ax, 0C00h               ; Function 0Ch (Get System
        int     15h                     ;   Configuration Parameters)
        sti                             ; Compaq ROM may leave interrupts
                                        ;   disabled

        jc      setup                   ; If carry set,
        or      ah, ah                  ;   or if AH not 0,
        jnz     setup                   ;   services are not supported

        test    BYTE PTR es:[bx+5], 00010000y   ; Test bit 4 to see if
        jz      setup                           ;   intercept is implemented

        mov     ax, OFFSET MiscServ             ; If so, set up MiscServ as
        mov     WORD PTR intMisc.NewHand, ax    ;   Interrupt 15h handler
        .ENDIF

        mov     ax, OFFSET KeybrdMonitor        ; Set up KeybrdMonitor as
        mov     WORD PTR intKeybrd.NewHand, ax  ;   Interrupt 09 handler

; Interrupt structure is now initialized for either PC/AT or PS/2 system.
; Get existing handler addresses from interrupt vector table, store in
; OldHand member, and replace with addresses of new handlers.

setup:
        mov     cx, CHAND               ; CX = count of handlers
        mov     si, OFFSET HandArray    ; SI = offset of handler structures

        .REPEAT
        mov     ah, 35h                 ; Request DOS Function 35h
        mov     al, [si]                ; AL = interrupt number
        int     21h                     ; Get interrupt vector in ES:BX
        mov     WORD PTR [si].INTR.OldHand[0], bx ; Save far address
        mov     WORD PTR [si].INTR.OldHand[2], es ;  of current handler
        mov     dx, WORD PTR [si].INTR.NewHand[0] ; DS:DX points to TSR handler
        mov     ah, 25h                 ; Request DOS Function 25h
        int     21h                     ; Set interrupt vector from DS:DX
        add     si, SIZEOF INTR         ; DS:SI points to next in list
        .UNTILCXZ

        sub     ax, ax                  ; Clear return code
exit:
        ret                             ; Return to caller

Install ENDP


;* Deinstall - Prepares for deinstallation of a TSR. Deinstall is the
;* complement of the Install procedure. It restores to the vector table
;* the original addresses replaced during installation, thus unhooking
;* the TSR's handlers. Checks to see if another TSR has installed handlers
;* for the interrupts in array HandArray. If so, the procedure fails with
;* an appropriate error code. Callable from a high-level language.
;*
;* Params: None
;*
;* Return: AX = Segment address of resident portion's PSP or 
;*              one of the following error codes:
;*              CANT_DEINSTALL           WRONG_DOS
                
Deinstall PROC  FAR USES ds si di

        mov     ax, @code
        mov     ds, ax                  ; Point DS to code segment

        sub     al, al                  ; Request multiplex function 0
        call    CallMultiplex           ; Get resident code segment in ES

        cmp     ax, IS_INSTALLED        ; If not resident,
        jne     exit                    ;   exit with error
        push    es                      ; Else point DS to
        pop     ds                      ;   resident code segment
        mov     cx, CHAND               ; Count of handlers
        mov     si, OFFSET HandArray    ; SI points to handler structures

; Read current vectors for TSR's interrupt handlers and compare with far
; addresses. If mismatch, another TSR has installed new handlers and ours
; cannot be safely deinstalled.

        .REPEAT
        mov     al, [si]                ; AL = interrupt number
        mov     ah, 35h                 ; Request DOS Function 35h
        int     21h                     ; Get interrupt vector in ES:BX
        cmp     bx, WORD PTR [si].INTR.NewHand[0] ; If offset different,
        jne     e_exit                            ;   error
        mov     ax, es
        cmp     ax, WORD PTR [si].INTR.NewHand[2] ; If segment different,
        jne     e_exit                            ;   error
        add     si, SIZEOF INTR         ; DS:SI points to next in list
        .UNTILCXZ

; If no interrupts replaced, call TSR's multiplex handler to locate
; address of resident portion's PSP. Although the PSP is not required
; until memory is returned to DOS, the call must be done now before
; unhooking the multiplex handler.

        mov     al, 1                   ; Request multiplex function 1
        call    CallMultiplex           ; Get resident code's PSP in ES
        push    es                      ; Save it

; Unhook all handlers by restoring the original vectors to vector table.

        mov     cx, CHAND               ; Count of installed handlers
        mov     si, OFFSET HandArray    ; SI points to handler structures

        .REPEAT
        mov     al, [si]                ; AL = interrupt number
        push    ds                      ; Preserve DS segment
        lds     dx, [si].INTR.OldHand   ; Put vector in DS:DX
        mov     ah, 25h                 ; Request DOS Function 25h
        int     21h                     ; Set interrupt vector from DS:DX
        pop     ds
        add     si, SIZEOF INTR         ; DS:SI points to next in list
        .UNTILCXZ

        pop     ax                      ; Return address of resident PSP
        jmp     exit                    ;  to signal success
e_exit:
        mov     ax, CANT_DEINSTALL
exit:
        ret

Deinstall ENDP


;* GetVersion - Gets the DOS version and stores it in a global variable as
;* well as returning it in AX.
;*
;* Uses:   Version
;*
;* Params: DS = Resident code segment
;*
;* Return: AH = Major version
;*         AL = Minor version

GetVersion PROC NEAR

        mov     ax, 3000h               ; Request DOS Function 30h
        int     21h                     ; Get MS-DOS version number
        .IF     al < 2                  ; If Version 1.x:
        mov     ax, WRONG_DOS           ; Abort with WRONG_DOS as error code
        .ELSE
        xchg    ah, al                  ; AH = major, AL = minor version
        mov     Version, ax             ; Save in global
        .ENDIF
        ret

GetVersion ENDP


;* GetDosFlags - Gets pointers to the DOS InDos and Critical Error flags.
;*
;* Params: DS = Resident code segment
;*
;* Return: 0 if successful, or the following error code:
;*         FLAGS_NOT_FOUND

GetDosFlags PROC NEAR

; Get InDOS address from MS-DOS

        mov     ah, 34h                         ; Request DOS Function 34h
        int     21h                             ; Get Address of InDos flag
        mov     WORD PTR InDosAddr[0], bx       ; Store address (ES:BX)
        mov     WORD PTR InDosAddr[2], es       ;   for later access

; Determine address of Critical Error Flag

        mov     ax, Version             ; AX = DOS version number

; If DOS 3.1 or greater and not OS/2 compatibility mode, Critical Error
; flag is in byte preceding InDOS flag 
        .IF     (ah < 10) && ((ah > 3) || ((ah == 3) && (al >= 10)))
        dec     bx                      ; BX points to byte before InDos flag

        .ELSE
; For earlier versions, the only reliable method is to scan through
; DOS to find an INT 28h instruction in a specific context.

        mov     cx, 0FFFFh              ; Maximum bytes to scan
        sub     di, di                  ; ES:DI = start of DOS segment

INT_28  EQU     028CDh

        .REPEAT
        mov     ax, INT_28              ; Load opcode for INT 28h

        .REPEAT
        repne   scasb                   ; Scan for first byte of opcode

        .IF     !zero?
        mov     ax, FLAGS_NOT_FOUND     ; Return error if not found
        jmp     exit
        .ENDIF
        .UNTIL  ah == es:[di]           ; For each matching first byte,
                                        ;   check the second byte until match

; See if INT 28h is in this context:
;                                       ;     (-7)    (-5)
;       CMP     ss:[CritErrFlag], 0     ;  36, 80, 3E,  ?,  ?,  0
;       JNE     NearLabel               ;  75,  ?
        int     28h                     ;  CD, 28
;                                       ;  (0) (1)
CMP_SS    EQU   3E80h
P_CMP_SS  EQU   8
P_CMP_OP  EQU   6

        mov     ax, CMP_SS              ; Load and compare opcode to CMP
        .IF     ax == es:[di-P_CMP_SS]  ; If match:
        mov     bx, es:[di-P_CMP_OP]    ; BX = offset of
        jmp     exit                    ;   Critical Error flag
        .ENDIF

; See if INT 28h is in this context:
;                                       ;     (-12)   (-10)
;       TEST    ?s:[CritErr], 0FFh      ;  ?6  F6, 06,  ?,  ?, FF
;       JNE     NearLabel               ;  75, ?
;       PUSH    ss:[CritErrFlag]        ;  36, FF, 36,  ?,  ?
        int     28h                     ;  CD, 28
;                                       ;  (0) (1)
TEST_SS   EQU   06F6h
P_TEST_SS EQU   13
P_TEST_OP EQU   11

        mov     ax, TEST_SS             ; Load AX = opcode for TEST
        .UNTIL  ax == es:[di-P_TEST_SS] ; If not TEST, continue scan

        mov     bx, es:[di-P_TEST_OP]   ; Else load BX with offset of
        .ENDIF                          ;   Critical Error flag
exit:
        mov     WORD PTR CritErrAddr[0], bx     ; Store address of
        mov     WORD PTR CritErrAddr[2], es     ;   Critical Error flag
        sub     ax, ax                          ; Clear error code
        ret

GetDosFlags ENDP


;* GetTimeToElapse - Determines number of 5-second intervals that
;* must elapse between specified hour:minute and current time.
;*
;* Params: AH = Hour
;*         AL = Minute
;*
;* Return: AX = Number of 5-second intervals

GetTimeToElapse PROC NEAR 

        push    ax                      ; Save hour:minute
        mov     ah, 2Ch                 ; Request DOS Function 2Ch
        int     21h                     ; Get Time (CH:CL = hour:minute)
        pop     bx                      ; Recover hour:minute
        mov     dl, dh
        sub     dh, dh
        push    dx                      ; Save DX = current seconds

        mov     al, 60                  ; 60 minutes/hour
        mul     bh                      ; Multiply by specified hour
        sub     bh, bh
        add     bx, ax                  ; BX = minutes from midnight
                                        ;   to activation time
        mov     al, 60                  ; 60 minutes/hour
        mul     ch                      ; Multiply by current hour
        sub     ch, ch
        add     ax, cx                  ; AX = minutes from midnight
                                        ;   to current time
        sub     bx, ax                  ; BX = minutes to elapse before
        .IF     carry?                  ; If activation is tomorrow,
        add     bx, 24 * 60             ;   add number of minutes per day
        .ENDIF

        mov     ax, 60
        mul     bx                      ; DX:AX = minutes-to-elapse-times-60
        pop     bx                      ; Recover current seconds
        sub     ax, bx                  ; DX:AX = seconds to elapse before
        sbb     dx, 0                   ;   activation
        .IF     carry?                  ; If negative,
        mov     ax, 5                   ;   assume 5 seconds
        cwd
        .ENDIF

        mov     bx, 5                   ; Divide result by 5 seconds
        div     bx                      ; AX = number of 5-second intervals
        ret

GetTimeToElapse ENDP


;* CallMultiplex - Calls the Multiplex Interrupt (Interrupt 2Fh).
;*
;* Uses:   IDstring
;*
;* Params: AL = Function number for multiplex handler
;*
;* Return: AX    = One of the following return codes:
;*                 NOT_INSTALLED      IS_INSTALLED       NO_IDNUM
;*         ES:DI = Resident code segment:identifier string (function 0)
;*         ES:DI = Resident PSP segment address (function 1)
;*         ES:DI = Far address of shared memory (function 2)

CallMultiplex PROC FAR USES ds

        push    ax                      ; Save function number
        mov     ax, @code
        mov     ds, ax                  ; Point DS to code segment

; First, check 2Fh vector. DOS Version 2.x may leave the vector null
; if PRINT.COM is not installed. If vector is null, point it to IRET
; instruction at LABEL NoMultiplex. This allows the new multiplex
; handler to pass control, if necessary, to a proper existing routine.

        mov     ax, 352Fh               ; Request DOS Function 35h
        int     21h                     ; Get interrupt vector in ES:BX
        mov     ax, es
        or      ax, bx
        .IF     zero?                   ; If Null vector,
        mov     dx, OFFSET NoMultiplex  ;   set vector to IRET instruction
        mov     ax, 252Fh               ;   at LABEL NoMultiplex
        int     21h                     ; Set interrupt vector
        .ENDIF

; Second, call Interrupt 2Fh with function 0 (presence request). Cycle
; through allowable identity numbers (192 to 255) until TSR's multiplex
; handler returns ES:DI = IDstring to verify its presence or until call
; returns AL = 0, indicating the TSR is not installed.

        mov     dh, 192                 ; Start with identity number = 192

        .REPEAT
        mov     ah, dh                  ; Call Multiplex with AH = trial ID
        sub     al, al                  ;   and AL = function 0
        push    dx                      ; Save DH and DS in case call
        push    ds                      ;   destroys them
        int     2Fh                     ; Multiplex
        pop     ds                      ; Recover DS and
        pop     dx                      ;   current ID number in DH
        or      al, al                  ; Does a handler claim this ID number?
        jz      no                      ; If not, stop search

        .IF     al == 0FFh              ; If handler ready to process calls,
        mov     si, OFFSET IDstring     ;   point DS:SI to ID string, compare
        mov     cx, IDstrlen            ;   with string at ES:DI returned
        repe    cmpsb                   ;   by multiplex handler
        je      yes                     ; If equal, TSR's handler is found
        .ENDIF

        inc     dh                      ; This handler is not the one
        .UNTIL  zero?                   ; Try next identity number up to 255

        mov     ax, NO_IDNUM            ; In the unlikely event that numbers
        jmp     e_exit                  ;   192-255 are all taken, quit

; Third, assuming handler is found and verified, process the multiplex
; call with the requested function number.

yes:
        pop     ax                      ; AL = original function number
        mov     ah, dh                  ; AH = identity number
        int     2Fh                     ; Multiplex
        mov     ax, IS_INSTALLED        ; Signal that handler has been found
        jmp     exit                    ;   and quit

; Reaching this section means multiplex handler (and TSR) not installed.
; Since the value in DH is not claimed by any handler, it will be used as
; the resident TSR's identity number.  Save the number in resident code
; segment so multiplex handler can find it.

no:
        mov     IDnumber, dh            ; Save multiplex identity number
        mov     ax, NOT_INSTALLED       ; Signal handler is not installed
e_exit:
        pop     bx                      ; Remove function number from stack
exit:
        ret

CallMultiplex ENDP


;* InitTsr - Initializes DOS version variables and multiplex data with
;* following parameters. This procedure must execute before calling
;* either the Install, Deinstall, or CallMultiplex procedures. Callable
;* from a high-level language.
;*
;* Uses:   IDstring
;*
;* Params: PspParam - Segment address of PSP
;*         StrParam - Far address of TSR's identifier string
;*         ShrParam - Far address of shared memory
;*
;* Return: AX = WRONG_DOS if not DOS Version 2.0 or higher

InitTsr PROC    FAR USES ds es si di,
        PspParam:WORD, StrParam:FPVOID, ShrParam:FPVOID

        mov     ax, @code
        mov     ds, ax                          ; Point DS and ES
        mov     es, ax                          ;   to code segment

; Get and store parameters passed from main program module

        mov     ax, PspParam
        mov     TsrPspSeg, ax                   ; Store PSP segment address

        mov     ax, WORD PTR ShrParam[0]
        mov     bx, WORD PTR ShrParam[2]
        mov     WORD PTR ShareAddr[0], ax       ; Store far address of
        mov     WORD PTR ShareAddr[2], bx       ;   shared memory

        push    ds
        mov     si, WORD PTR StrParam[0]        ; DS:SI points to multiplex
        mov     ax, WORD PTR StrParam[2]        ;   identifier string
        mov     ds, ax
        mov     di, OFFSET IDstring             ; Copy string to IDstring
        mov     cx, STR_LEN                     ;   at ES:DI so multiplex
                                                ;   handler has a copy
        .REPEAT
        lodsb                                   ; Copy STR_LEN characters
        .BREAK .IF al == 0                      ;   or until null terminator
        stosb                                   ;   found
        .UNTILCXZ

        pop     ds                              ; Recover DS = code segment
        mov     ax, STR_LEN
        sub     ax, cx
        mov     IDstrlen, ax                    ; Store string length

        INVOKE  GetVersion                      ; Return AX = version number
        ret                                     ;   or WRONG_DOS

InitTsr ENDP


INSTALLCODE ENDS

        END
