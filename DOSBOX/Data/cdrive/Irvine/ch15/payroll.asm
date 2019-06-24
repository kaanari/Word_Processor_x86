title Payroll Calculation Program1 (8087 demo)

.model small
.8087                        ; enable 8087 instructions
.stack 100h
.code
main proc
     mov     ax, @data       ; initialize DS
     mov     ds, ax
     finit                   ; initalize the 8087 coprocessor
     fld     regRate         ; push regRate into ST
     fld     regConst        ; push regConst into ST 
     fld     totalHours      ; push totalHours into ST 
     fsub    st,st(1)        ; subtract ST(1) from ST:
                             ;  overtime hours = regConst - regRate
     ftst                    ; compare ST to zero
     fstsw   status          ; store coprocessor status word in 
                             ;   the memory variable status
     fwait                   ; tell the system processor to wait until
                             ;   8087 has completed the FSTSW
     mov     ax, status      ; load status into AX
     sahf                    ; store AH into the 8088 flags
     jle     calcRegular     ; no overtime if hours <= zero

calcOvertime:                ; overtime hours > zero
     fst     otHours         ; store ST to otHours
     fld     otRate          ; push otRate into ST
     fmul    st,st(3)        ; ST = ST * ST(3)      (otRate * regRate)
     fmul                    ; multiply St by ST(1), pop result into ST
     fst     grossPay        ; store ST in grossPay
     fstp    otpay           ; pop ST into otPay
     fldz                    ; push zero into ST 

calcRegular:                 ; If this is reached following an overtime
                             ;   pay calculation, then ST = 0.
     fadd                    ; ST = ST + ST(1) 
     fst     reghours        ; store ST in regHours
     fmul                    ; ST =  ST * ST(1) 
     fadd    grossPay        ; add grossPay to ST
     fstp    grossPay        ; pop ST into grossPay, the final result
     mov     ax,4C00h        ; return to DOS
     int     21h
main endp

.data
status          dw  ?        ; holds the 8087 status word
otRate          dd  1.5      ; The four variables are data that could be
regRate         dd  5.0      ;   input from a data file. They hold the data
regConst        dd  40.0     ;   to be processed by the coprocessor.
totalHours      dd  46.0
regHours        dd  0.0      ; The next five variables hold the results 
otHours         dd  0.0      ;   of the calculations.
otPay           dd  0.0
grossPay        dd  0.0
netPay          dd  0.0
end main
