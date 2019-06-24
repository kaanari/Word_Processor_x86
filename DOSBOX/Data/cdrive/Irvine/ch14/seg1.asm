    title Multiple Segment Example         (seg1.asm)

    cseg  segment 'CODE'
          assume cs:cseg, ds:data1, ss:mystack

    main proc
        mov   ax,data1           ; point DS to data1 segment
        mov   ds,ax
        mov   ax,seg val2        ; point ES to data2 segment
        mov   es,ax

        mov   ax,val1            ; requires ASSUME for DS
        mov   bx,es:val2         ; ASSUME not required
        cmp   ax,bx
        jb    L1                 ; requires ASSUME for CS
        mov   ax,0
    L1:
        mov   ax,4C00h           ; return to DOS
        int   21h
    main endp

    cseg  ends


    data1 segment 'DATA'        ; specify class type
      val1  dw  1001h
    data1 ends

    data2 segment 'DATA'
      val2  dw  1002h
    data2 ends

    mystack segment para STACK 'STACK'  ; combine & class type
        db  100h dup('S')
    mystack ends
    
    end main
    