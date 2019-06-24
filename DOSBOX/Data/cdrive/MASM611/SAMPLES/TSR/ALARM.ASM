;* ALARM.ASM - A simple memory-resident program that beeps the speaker
;* at a prearranged time.  Can be loaded more than once for multiple
;* alarm settings.  During installation, ALARM establishes a handler
;* for the timer interrupt (interrupt 08).  It then terminates through
;* the Terminate-and-Stay-Resident function (function 31h).  After the
;* alarm sounds, the resident portion of the program retires by setting
;* a flag that prevents further processing in the handler.

        .MODEL tiny                     ; Create ALARM.COM
        .STACK

        .CODE

        ORG     5Dh                     ; Location of time argument in PSP,
CountDown       LABEL   WORD            ;   converted to number of 5-second
                                        ;   intervals to elapse
        .STARTUP
        jmp     Install                 ; Jump over data and resident code

; Data must be in code segment so it won't be thrown away with Install code.

OldTimer        DWORD   ?               ; Address of original timer routine
tick_91         BYTE    91              ; Counts 91 clock ticks (5 seconds)
TimerActiveFlag BYTE    0               ; Active flag for timer handler
Error_msg	BYTE	0dh,0ah
		BYTE	'The time must be between 0000 and 2359 !'
		BYTE	0dh,0ah,'$'


;* NewTimer - Handler routine for timer interrupt (interrupt 08).
;* Decrements CountDown every 5 seconds.  No other action is taken
;* until CountDown reaches 0, at which time the speaker sounds.

NewTimer PROC   FAR

        .IF     cs:TimerActiveFlag != 0 ; If timer busy or retired,
        jmp     cs:OldTimer             ;   jump to original timer routine
        .ENDIF
        inc     cs:TimerActiveFlag      ; Set active flag
        pushf                           ; Simulate interrupt by pushing flags,
        call    cs:OldTimer             ;   then far-calling original routine
        sti                             ; Enable interrupts
        push    ds                      ; Preserve DS register
        push    cs                      ; Point DS to current segment for
        pop     ds                      ;   further memory access
        dec     tick_91                 ; Count down for 91 ticks
        .IF     zero?                   ; If 91 ticks have elapsed,
        mov     tick_91, 91             ;   reset secondary counter and
        dec     CountDown               ;   subtract one 5-second interval
        .IF     zero?                   ; If CountDown drained,
        call    Sound                   ;   sound speaker
        inc     TimerActiveFlag         ; Alarm has sounded, set flag
        .ENDIF
        .ENDIF

        dec     TimerActiveFlag         ; Decrement active flag
        pop     ds                      ; Recover DS
        iret                            ; Return from interrupt handler

NewTimer ENDP


;* Sound - Sounds speaker with the following tone and duration:

BEEP_TONE       EQU     440             ; Beep tone in hertz
BEEP_DURATION   EQU     6               ; Number of clocks during beep,
                                        ;   where 18 clocks = approx 1 second

Sound   PROC    USES ax bx cx dx es     ; Save registers used in this routine
        mov     al, 0B6h                ; Initialize channel 2 of
        out     43h, al                 ;   timer chip
        mov     dx, 12h                 ; Divide 1,193,180 hertz
        mov     ax, 34DCh               ;   (clock frequency) by
        mov     bx, BEEP_TONE           ;   desired frequency
        div     bx                      ; Result is timer clock count
        out     42h, al                 ; Low byte of count to timer
        mov     al, ah
        out     42h, al                 ; High byte of count to timer
        in      al, 61h                 ; Read value from port 61h
        or      al, 3                   ; Set first two bits
        out     61h, al                 ; Turn speaker on

; Pause for specified number of clock ticks

        mov     dx, BEEP_DURATION       ; Beep duration in clock ticks
        sub     cx, cx                  ; CX:DX = tick count for pause
        mov     es, cx                  ; Point ES to low memory data
        add     dx, es:[46Ch]           ; Add current tick count to CX:DX
        adc     cx, es:[46Eh]           ; Result is target count in CX:DX
        .REPEAT
        mov     bx, es:[46Ch]           ; Now repeatedly poll clock
        mov     ax, es:[46Eh]           ;   count until the target
        sub     bx, dx                  ;   time is reached
        sbb     ax, cx
        .UNTIL  !carry?

        in      al, 61h                 ; When time elapses, get port value
        xor     al, 3                   ; Kill bits 0-1 to turn
        out     61h, al                 ;   speaker off
        ret

Sound   ENDP



;* Install - Converts ASCII argument to valid binary number, replaces
;* NewTimer as the interrupt handler for the timer, then makes program
;* memory resident by exiting through function 31h.
;*
;* This procedure marks the end of the TSR's resident section and the
;* beginning of the installation section.  When ALARM terminates through
;* function 31h, the above code and data remain resident in memory.  The
;* memory occupied by the following code is returned to DOS.


Install PROC

; Time argument is in hhmm military format.  Convert ASCII digits to
; number of minutes since midnight, then convert current time to number
; of minutes since midnight.  Difference is number of minutes to elapse
; until alarm sounds.  Convert to seconds-to-elapse, divide by 5 seconds,
; and store result in word CountDown.

DEFAULT_TIME    EQU     3600            ; Default alarm setting = 1 hour
                                        ;   (in seconds) from present time
        mov     ax, DEFAULT_TIME
        cwd                             ; DX:AX = default time in seconds


	sub	bx,bx			; Check if there is only numbers
	.REPEAT
	cmp	BYTE PTR CountDown[bx],'0'
	jb	time_err
	cmp	BYTE PTR CountDown[bx],'9'
	ja	time_err
	inc	bx
	.UNTIL	(bx == 4)


        xor     CountDown[0], '00'      ;   convert 4 bytes of ASCII
        xor     CountDown[2], '00'      ;   argument to binary
                                        
        mov     al, 10                  ; Multiply 1st hour digit by 10
        mul     BYTE PTR CountDown[0]   ;   and add to 2nd hour digit
        add     al, BYTE PTR CountDown[1]
        mov     bh, al                  ; BH = hour for alarm to go off
        mov     al, 10                  ; Repeat procedure for minutes
        mul     BYTE PTR CountDown[2]   ; Multiply 1st minute digit by 10
        add     al, BYTE PTR CountDown[3] ;   and add to 2nd minute digit
        mov     bl, al                  ; BL = minute for alarm to go off


	cmp 	bh,23  			; Check if hour <=23
	jg	time_err
	cmp	bl,59  			; Check if minute <=59
	jnge	time_ok

time_err:
	mov	dx,offset Error_msg	; Print Error_msg
	mov	ah,9
	int	21h
	.exit				; exit and don't install


time_ok:
        mov     ah, 2Ch                 ; Request function 2Ch
        int     21h                     ; Get Time (CX = current hour/min)
        mov     dl, dh
        sub     dh, dh
        push    dx                      ; Save DX = current seconds

        mov     al, 60                  ; Multiply current hour by 60
        mul     ch                      ;   to convert to minutes
        sub     ch, ch
        add     cx, ax                  ; Add current minutes to result
                                        ; CX = minutes since midnight
        mov     al, 60                  ; Multiply alarm hour by 60
        mul     bh                      ;   to convert to minutes
        sub     bh, bh
        add     ax, bx                  ; AX = number of minutes since
                                        ;   midnight for alarm setting
        sub     ax, cx                  ; AX = time in minutes to elapse
                                        ;   before alarm sounds
        .IF     carry?                  ; If alarm time is tomorrow,
        add     ax, 24 * 60             ;   add minutes in a day
        .ENDIF

        mov     bx, 60
        mul     bx                      ; DX:AX = minutes-to-elapse-times-60
        pop     bx                      ; Recover current seconds
        sub     ax, bx                  ; DX:AX = seconds to elapse before
        sbb     dx, 0                   ;   alarm activates
        .IF     carry?                  ; If negative,
        mov     ax, 5                   ;   assume 5 seconds
        cwd
        .ENDIF

        mov     bx, 5                   ; Divide result by 5 seconds
        div     bx                      ; AX = number of 5-second intervals
        mov     CountDown, ax           ;   to elapse before alarm sounds

        mov     ax, 3508h               ; Request function 35h
        int     21h                     ; Get vector for timer (interrupt 08)
        mov     WORD PTR OldTimer[0], bx; Store address of original
        mov     WORD PTR OldTimer[2], es;   timer interrupt
        mov     ax, 2508h               ; Request function 25h
        mov     dx, OFFSET NewTimer     ; DS:DX points to new timer handler
        int     21h                     ; Set vector with address of NewTimer

        mov     dx, OFFSET Install      ; DX = bytes in resident section
        mov     cl, 4
        shr     dx, cl                  ; Convert to number of paragraphs
        inc     dx                      ;   plus one
        mov     ax, 3100h               ; Request function 31h, error code=0
        int     21h                     ; Terminate-and-Stay-Resident

Install ENDP

        END
