.MODEL LARGE

.STACK
 
.DATA

    OWNER DB "KAAN ARI","$"
    SCHL_NUM DB "21628042","$"

    BUTTON1 DB "LOAD FILE","$"
    BUTTON2 DB "NEW  FILE","$"
    BUTTON3 DB "SAVE FILE","$"
    BUTTON4 DB "RESUME","$"
    BUTTON5 DB "EXIT","$"

    LOAD_MSG DB "Please enter the Filename to Load:","$"
    NEWFILE_MSG DB "Please enter the Filename to Create:","$"

    CLEAR_MSG DB "CLEAR",'$'
    OK_MSG DB "OK","$"

    FILE_MSG DB "File : ","$"
    FILE_EXIST_MSG DB "FILE EXIST!","$"
    LINE_MSG DB "Line : ","$"
    COL_MSG DB "Column : ","$"
   
    HACETTEPE_LOGO DB 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,'$'

  
    ;---------EDITOR FOOTER TEXTS-------------
    F1_MSG DB "F1 Menu","$"
    F2_MSG DB "F2 Load","$"
    F3_MSG DB "F3 New","$"
    F4_MSG DB "F4 Save","$"
    F5_MSG DB "F5 Find","$"
    F6_MSG DB "F6 Find-Replace","$"
    F7_MSG DB "F7 Capitalize Sentences",'$'
    F8_MSG DB "F8 Capitalize Words","$"
    ESC_MSG DB "ESC Exit","$"

    BLANK_FILE_MSG DB "THIS FIELD CAN NOT BE EMPTY","$"
    FILE_NEXIST_MSG DB "FILE DOES NOT EXIST!","$"

    FILENAME DB 12 DUP(?)
    FILE_HANDLE DW ?
    FILE_BUFFER DB   ?
    TEMP_PAGE DW ?
    EOF_FLAG DW ?
    CURSOR_X DW 0000h
    CURSOR_Y DW 0000h

    FILE_POINTER DW 0000h

    FILE_POINTER_TEMP DW 0000h

    NEWLINE_POINTERS DW 30 DUP(?)

    NEXTLINE_TEMP DW 0000h
    BACKLINE_TEMP DW 0000h
    FILE_LEN DW 0000h

    BACKSPACE_LINE DW 0000h
    
    CAP_WORDS_FLAG DW 0000h
    
    CAP_SENT_FLAG DW 0000h
    
    FILE_CHANGED_FLAG DW 0000h
    
    MENU_SELECTED_BUTTON DW 0000h
    
    WANNA_QUIT_BUT DW 0000h
    DISABLED_EDITOR DW 0000h
    
    
    FILE_SAVED_MSG DB "File Saved.","$"
    WANNA_QUIT_MSG DB "Do you want to QUIT without SAVE ?","$"
    WANNA_LOAD_MSG DB "Do you want to LOAD without SAVE ?","$"
    WANNA_SAVE_MSG DB "Choose one option to SAVE FILE:","$"
    WANNA_NEW_MSG DB "Do you want to SAVE first ?","$" 
    SAVE_AS_MEN_MSG DB "Save as :","$"
    FIND_MSG DB "Please enter the string to Search:","$"
    FIND2_MSG DB "First enter the string to Search:","$"
    FIND_REP_MSG DB "Replace ","$" 
    FIND_REP_MSG2 DB " with:","$"
    ZERO_FOUND_MSG DB "NOT FOUND !","$"
    
    SAVE_QUIT_MSG DB "SAVE/QUIT","$"
    QUIT_MSG DB "QUIT","$"
    
    SAVE_LOAD_MSG DB "SAVE/LOAD","$"
    LOAD_MEN_MSG  DB "LOAD","$"
    SAVE_MEN_MSG  DB "SAVE","$"
    SAVE_AS_MSG DB "SAVE AS","$"
    
    SAVE_NEW_MSG DB "SAVE/NEW","$"
    NEW_MEN_MSG  DB "NEW","$"
    FIND_BTN DB "SEARCH","$"
    REPLACE_MSG DB "REPLACE","$"
    FOUND_MSG DB "TOT. FOUND : ","$" 
    FOUND2_MSG DB "IN THIS PAGE : ","$"
    FOUND_TEMP DW 0000h
    
    LAST_FILE_POINTER DW 0000h  
    
    FILENAME_OLD DB 12 DUP(?)
    
    FIND_WORD DB 21 DUP(?)
    FIND_WORD_LEN DW 0000h
    
    REPLACE_WORD DB 21 DUP(?)
    REPLACE_WORD_LEN DW 0000h

    NEXTLINE_PAGES DW 50 DUP(0) 
    
    FOUND_NUM DW 0000h 
    FOUND_NUM_PAGE DW 0000h
    FOUND_INDEX DW 50 DUP(?)
    FOUND_PAGE DW 50 DUP(?)
    FOUND_CURSOR DW 50 DUP(?)
    
    FILE_RESTORE DB 5000 DUP(?) 
    
    FILE_DUMMY DB 5000 DUP(?)
   
  
.CODE

MAIN PROC FAR
 
    CALL INITIALIZE_VGA ;INITIALIZE VGA

BACK_HOMEPAGE:
    
    CALL HOMEPAGE ; DRAW HOMEPAGE
    CALL CLEAR_SCREEN
    CALL EDITOR
    ;CALL MENU

EXIT:

    MOV BX,offset FILE_CHANGED_FLAG
    MOV AX,[BX]
    CMP AX,0
    JZ EXIT_CHECK
    
    CALL WANNA_QUIT

    EXIT_CHECK:
    
    CALL CLOSE_FILE  
    CALL CLEAR_SCREEN
    
    MOV AH,4Ch ;go back
    INT 21h ; to DOS.
 
MAIN ENDP

;-------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------GUI PROCEDURES----------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------
;----------------------------MAIN TEMPLATE-----------------------
;----------------------------------------------------------------

INITIALIZE_VGA PROC

    MOV AX,@DATA
    MOV DS,AX

    MOV AX,012h ;VGA mode
    INT 10h ;640 x 480 16 colors.
    INT 10h
    MOV AX,0A000h
    MOV ES,AX ;ES points to the video memory.

    RET

INITIALIZE_VGA ENDP


CLEAR_SCREEN PROC


    MOV ax,18h
    INT 10h

    CALL INITIALIZE_VGA


    RET
CLEAR_SCREEN ENDP

CURSOR_SET PROC ; PROC WILL SET CURSOR AT POSITION DL = COL,DH = ROW

    ;----ADJUST CURSOR----
    MOV AH,02h   ;settin cursor position
    MOV BH,00h   ;page number
    INT 10h
    
    RET

CURSOR_SET ENDP
    
;----------------HOMEPAGE AND MENU GUI PROC----------------------

HEADER PROC

    CALL HCTTP_LOGO ; DRAWING HACETTEPE LOGO TOP ON THE SCREEN

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0402h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV DI,0 ; DI pointer in the video memory.
    MOV CX,1200 ; Counter for Header
    MOV AX,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

;---DRAWING LOGO CURVE---

    MOV BX,0FFFFh
    MOV BP,15
L_HEADER:        
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    MOV CX,0
    MOV SI,16
L1_ROR_HEADER:        
    SHR BX,1
    RCL CX,1
    DEC SI
    JNZ L1_ROR_HEADER
    MOV BX,CX

    NOT BX

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    DEC BP
    JNZ L_HEADER

    RET

HEADER ENDP

FOOTER_TEXT PROC
    JNC COLORED_2
    MOV CX,3
    JMP SET_SI
COLORED_2:
    MOV CX,2
SET_SI:
    MOV SI,BX

L_FOOTER_TEXT_1:
    MOV AL,[SI]
    MOV BL,0F3h;White Foreground,Red Background 0F3 good
    CALL PRINT_COLORED_TEXT
    INC SI
    LOOP L_FOOTER_TEXT_1


L_FOOTER_TEXT:

    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_FOOTER_TEXT

    RET

FOOTER_TEXT ENDP

FOOTER PROC ; DRAWING FOOTER

    CALL OWNERs_SIGNATURE

    MOV BP,16
    MOV BX,0000h

L1_FOOTER_SHAPE_MAIN:

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0702h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,34 ; Counter for Header
    MOV AX,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    MOV CX,0
    MOV SI,16
L1_ROR_FOOTER_MAIN:        
    SHR BX,1
    RCL CX,1
    DEC SI
    JNZ L1_ROR_FOOTER_MAIN
    MOV BX,CX

    NOT BX

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0702h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header

    MOV AL,BH ; write to every pixel.
    MOV AH,BL
    REP STOSW ; fill the screen

    NOT BX

    DEC DI
    DEC DI

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX



    MOV DX,03C4h ; dx = indexregister
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1440 ; Counter for Footer
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen


    RET

FOOTER ENDP

CLEAR_FRAME PROC ; CLEAR BUTTON AREA AND POPUP AREA , CLEARING SELECTED AREA WILL SAVE THE TIME !

    MOV SI,DI
    MOV DI,8340
    MOV BP,DI

    MOV BH,5

    L_CLR_MAIN:
    MOV DI,BP
    MOV BL,30
    L_CLR:
    MOV dx,03C4h ; dx = indexregister
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    ADD DI,40

    DEC BL
    JNZ L_CLR

    MOV DI,BP
    MOV BL,30
    L2_CLR:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    ADD DI,40
    DEC BL
    JNZ L3_CLR

    ADD DI,5120-2400
    MOV BP,DI
    DEC BH
    JNZ L_CLR_MAIN
    MOV DI,SI

    RET

CLEAR_FRAME ENDP

DRAW_BUTTONS PROC ; DRAW BUTTON, NUMBER OF STORED IN BL

    L_ALL:

    MOV BL,30
    LB:
    CALL CLEAR_BUTTONAREA
    CALL DRAW_BUTTONCOLOR

    DEC BL
    CMP BL,0
    JNZ LB

    ADD DI,2720 ;PER LINE NUM x LINE NUM = 80 x 30 = 2400

    DEC BH
    CMP BH,0
    JNZ L_ALL

    MOV DI,SI

    RET

DRAW_BUTTONS ENDP

CLEAR_BUTTONAREA PROC

    MOV dx,03C4h ; dx = indexregister
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40

    RET

CLEAR_BUTTONAREA ENDP

DRAW_BUTTONCOLOR PROC

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,7 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen


    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,33 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40
    ADD DI,80

    RET

DRAW_BUTTONCOLOR ENDP

BUTTON_BACKGROUND PROC

    MOV SI,DI

    MOV DI,0
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0002h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,36000 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    MOV DI,0
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,36000 ; Counter for RED BACKGROUND
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    MOV DI,SI

    RET

BUTTON_BACKGROUND ENDP

BUTTON_TEXT PROC ; Printing BUTTON TEXTs

    MOV AX,@data ;ES -> DATA Segment
    MOV es,ax

    JNC HMPG  ; IF carry is set before CALL this PROC it will display MENU

    MOV DH,7 ; row to put string
    MOV dl,66         ; column to put string
    
    MOV BX,OFFSET BUTTON1 ;LOAD BUTTON
    CALL PRINT_BUTTON_TEXT_MENU

    MOV BX,OFFSET BUTTON2 ;NEW FILE BUTTON
    add dh,4         ; row to put string
    CALL PRINT_BUTTON_TEXT_MENU

    MOV BX,OFFSET BUTTON3 ;SAVE FILE BUTTON
    add dh,4         ; row to put string
    CALL PRINT_BUTTON_TEXT_MENU

    MOV BX,OFFSET BUTTON4 ;RESUME BUTTON
    add dh,4         ; row to put string
    add dl,1         ; column to put string
    CALL PRINT_BUTTON_TEXT_MENU

    MOV BX,OFFSET BUTTON5 ;EXIT BUTTON
    add dh,4         ; row to put string
    add dl,1         ; column to put string
    CALL PRINT_BUTTON_TEXT_MENU

    JMP PASS3

    HMPG:
    MOV DH,11 ; row to put string
    MOV dl,39         ; column to put string

    MOV BX,OFFSET BUTTON1 ;LOAD BUTTON
    CALL PRINT_BUTTON_TEXT

    MOV BX,OFFSET BUTTON2 ;NEW FILE BUTTON
    add dh,4         ; row to put string
    CALL PRINT_BUTTON_TEXT

    MOV BX,OFFSET BUTTON5 ;EXIT BUTTON
    add dh,4         ; row to put string
    add dl,2         ; column to put string
    CALL PRINT_BUTTON_TEXT

    PASS3:

    MOV AX,0A000H ;ES -> Video Memory
    MOV ES,AX

    RET

BUTTON_TEXT ENDP

PRINT_BUTTON_TEXT_MENU PROC
    
    MOV SI,BX
    
    CALL CURSOR_SET
    
    L_TEXT_M:

    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_TEXT_M
    
    RET
    
PRINT_BUTTON_TEXT_MENU ENDP



PRINT_BUTTON_TEXT PROC

    MOV CX,0
    DEC BX
    countCHR:
    INC BX
    INC CX
    MOV AL,[BX]
    CMP AL,'$'
    JNZ countCHR
    DEC CX  ;length of string
    SUB BX,CX

    MOV BP,BX
    MOV ah,13h         ; function 13 - write string
    MOV al,01h         ; attrib in bl,move cursor
    MOV bh,00h         ; video page 0
    MOV bl,0Fh         ; attribute - white

    INT 10h         ; call BIOS service

    RET

PRINT_BUTTON_TEXT ENDP

;-----------------------------------------------------------------
;-----------------------TEXT EDITOR GUI PROC----------------------
;-----------------------------------------------------------------

HEADER_TEXT PROC

    ;-------------WRITING FILENAME-------------
    MOV DH,0    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET FILE_MSG
    MOV SI,BX ;EXIT BUTTON



    L_HEADER_TEXT:
    MOV AL,[SI]
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_HEADER_TEXT

    MOV BX,OFFSET FILENAME
    MOV SI,BX ;EXIT BUTTON

    L_HEADER_TEXT2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"."
    JNZ L_HEADER_TEXT2

    MOV CX,4
    L_HEADER_TEXT2_2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    LOOP L_HEADER_TEXT2_2

    ;--WRITING LINE--
    MOV DH,0    ;row
    MOV DL,54   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET LINE_MSG
    MOV SI,BX ;EXIT BUTTON

    L_HEADER_TEXT3:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_HEADER_TEXT3

    ;--WRITING COLUMN--

    MOV BX,OFFSET COL_MSG
    MOV SI,BX ;EXIT BUTTON

    MOV DH,0    ;row
    MOV DL,67   ;column
    CALL CURSOR_SET



    L_HEADER_TEXT4:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_HEADER_TEXT4



    ;--DRAWING NUMBER BOX FOR LINE AND COLUMN--

    MOV SI,DI

    MOV DI,75+80
    MOV BX,12

    L_HEADER_TEXT5:
    MOV DX,03C4h ; dx = indexregister
    MOV AX,0302h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header
    MOV AX,00Fh ; write to every pixel.
    REP STOSB ; fill the screen

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,4
    ADD DI,80
    DEC BX
    JNZ L_HEADER_TEXT5

    MOV DI,60+80
    MOV BX,12

    L_HEADER_TEXT6:
    MOV DX,03C4h ; dx = indexregister
    MOV AX,0302h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header
    MOV AX,00Fh ; write to every pixel.
    REP STOSB ; fill the screen

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,5
    ADD DI,80
    DEC BX
    JNZ L_HEADER_TEXT6

    MOV DI,SI

    RET

HEADER_TEXT ENDP

BACKGROUND_GRAY PROC ; DRAWING BACKGROUND COLOR

    MOV dx,03C4h ; dx = indexregister
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,33440 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    RET

BACKGROUND_GRAY ENDP

BACKGROUND_GRAY_EDITOR PROC ; DRAWING BACKGROUND COLOR
    

    MOV dx,03C4h ; dx = indexregister
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,16640 ; Counter for Gray
    MOV ax,0FFFFh ; write to every pixel.
    REP STOSW ; fill the screen

    RET

BACKGROUND_GRAY_EDITOR ENDP

BACKGROUND_EDITOR_MENU_CLEAR PROC
    
    MOV DI,2400
    
    MOV dx,03C4h ; dx = indexregister
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,16640 ; Counter for Gray
    MOV ax,0h ; write to every pixel.
    REP STOSW ; fill the screen 
    
    
    RET
    
BACKGROUND_EDITOR_MENU_CLEAR ENDP

FOOTER_EDITOR PROC ; DRAWING FOOTER


    MOV BP,16
    MOV BX,0000h
    L1_FOOTER_SHAPE:

    NOT BX

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0702h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header

    MOV AL,BH ; write to every pixel.
    MOV AH,BL
    REP STOSW ; fill the screen

    NOT BX

    DEC DI
    DEC DI

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0402h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header

    MOV AL,0FFh ; write to every pixel.
    MOV AH,0FFh
    REP STOSW ; fill the screen


    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    MOV CX,0
    MOV SI,16
    L1_ROR_FOOTER:
    SHR BX,1
    RCL CX,1
    DEC SI
    JNZ L1_ROR_FOOTER
    MOV BX,CX

    NOT BX

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0702h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header

    MOV AL,BH ; write to every pixel.
    MOV AH,BL
    REP STOSW ; fill the screen

    NOT BX

    DEC DI
    DEC DI

    MOV DX,03C4h ; dx = indexregister
    MOV AX,0402h ; INDEX = MASK MAP,[COLOR][X]
    OUT DX,AX ; write all the bitplanes.
    MOV CX,1 ; Counter for Header

    MOV AL,0FFh ; write to every pixel.
    MOV AH,0FFh
    REP STOSW ; fill the screen



    MOV CX,0
    MOV SI,16
    L1_ROR_FOOTER2:
    SHR BX,1
    RCL CX,1
    DEC SI
    JNZ L1_ROR_FOOTER2
    MOV BX,CX

    STC
    RCL BX,1

    DEC BP
    JNZ L1_FOOTER_SHAPE

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    ;-----F1------

    MOV DH,28    ;row
    MOV DL,3   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F1_MSG
    CALL FOOTER_TEXT

    ;-----F2------
    MOV DH,28    ;row
    MOV DL,16   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F2_MSG
    CALL FOOTER_TEXT

    ;-----F3------

    MOV DH,28    ;row
    MOV DL,28   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F3_MSG
    CALL FOOTER_TEXT

    ;-----F4------

    MOV DH,28    ;row
    MOV DL,38   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F4_MSG
    CALL FOOTER_TEXT

    ;-----F5------

    MOV DH,28    ;row
    MOV DL,50   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F5_MSG
    CALL FOOTER_TEXT

    ;-----F6------

    MOV DH,28    ;row
    MOV DL,62   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F6_MSG
    CALL FOOTER_TEXT

    ;----F7-----

    MOV DH,29    ;row
    MOV DL,6   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F7_MSG
    CALL FOOTER_TEXT

    ;-----F8------

    MOV DH,29    ;row
    MOV DL,38   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET F8_MSG
    CALL FOOTER_TEXT

    ;----ESC------

    MOV DH,29    ;row
    MOV DL,65   ;column
    STC
    CALL CURSOR_SET

    MOV BX,OFFSET ESC_MSG
    CALL FOOTER_TEXT

    RET

FOOTER_EDITOR ENDP

WRITE_FILE_TO_EDITOR PROC

    MOV AL,DL
    MOV BL,0F7h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    RET

WRITE_FILE_TO_EDITOR ENDP

WRITE_FILE_TO_EDITOR2 PROC

    MOV AL,DL
    MOV BL,0F8h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    RET

WRITE_FILE_TO_EDITOR2 ENDP

OVERFLOW_EDITOR PROC

    MOV DH,27    ;row
    MOV DL,74   ;column
    CALL CURSOR_SET

    MOV CX,2

    OF_EDITOR_L:

    MOV AL,'>'
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    LOOP OF_EDITOR_L

    RET

OVERFLOW_EDITOR ENDP

UNDERFLOW_EDITOR PROC

    MOV DH,1    ;row
    MOV DL,4   ;column
    CALL CURSOR_SET

    MOV CX,2

    UF_EDITOR_L:

    MOV AL,'<'
    MOV BL,0F3h ;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    LOOP UF_EDITOR_L

    RET

UNDERFLOW_EDITOR ENDP

CLEAR_UF PROC

    MOV DI,1200
    MOV BX,16
    CLEAR_UF_L:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    ADD DI,80
    SUB DI,20
    DEC BX
    JNZ CLEAR_UF_L

    RET

CLEAR_UF ENDP

EDITOR_CURSOR_DRAW PROC

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    MOV BX,16
    CLEAR_UF_L2:

    MOV dx,03C4h ; dx = indexregister
    MOV ax,0802h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,002h ; write to every pixel.
    REP STOSB ; fill the screen

    ADD DI,80
    SUB DI,1
    DEC BX
    JNZ CLEAR_UF_L2

    RET

EDITOR_CURSOR_DRAW ENDP

EDITOR_CURSOR_CLEAR PROC

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    CMP DX,2560
    JZ PASS_CLC

    CMP DI,3840
    JB PASS_CLEAR_SUB

    SUB DI,1280

    PASS_CLEAR_SUB:

    PASS_CLC:

    MOV BX,48
    CLEAR_CUR_L:

    MOV dx,03C4h ; dx = indexregister
    MOV ax,0802h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,4 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    ADD DI,80
    SUB DI,4
    DEC BX
    JNZ CLEAR_CUR_L

    RET

EDITOR_CURSOR_CLEAR ENDP

PRINT_CURSOR_POS PROC
    

    ;--CLEAR CURSOR POS--

    MOV DI,75+80
    MOV BX,12

    L_CURSOR_CLR:
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,4
    ADD DI,80
    DEC BX
    JNZ L_CURSOR_CLR

    MOV DI,60+80
    MOV BX,12

    L_CURSOR_CLR2:
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,5
    ADD DI,80
    DEC BX
    JNZ L_CURSOR_CLR2

    ;--PRINT CURSOR POS--

    MOV DH,0    ;row
    MOV DL,61   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET CURSOR_Y
    MOV SI,BX ;EXIT BUTTON

    MOV AX,[SI]
    INC AX
    MOV BL,100

    DIV BL

    MOV CX,AX

    XOR AL,30h
    MOV BL,0F7h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AX,CX
    MOV AL,AH
    MOV AH,0
    MOV BL,10
    DIV BL
    MOV CX,AX

    XOR AL,30h
    MOV BL,0F7h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AX,CX
    XCHG AH,AL

    XOR AL,30h
    MOV BL,0F7h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    ;--WRITING COLUMN--

    MOV BX,OFFSET CURSOR_X
    MOV SI,BX ;EXIT BUTTON

    MOV DH,0    ;row
    MOV DL,76   ;column
    CALL CURSOR_SET

    MOV AX,[SI]
    INC AX
    MOV BL,10

    DIV BL

    MOV CX,AX

    XOR AL,30h
    MOV BL,0F7h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT 
    
    MOV AX,CX
    XCHG AL,AH

    XOR AL,30h
    MOV BL,0F7h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    RET

PRINT_CURSOR_POS ENDP

;----------------------------------------------------------------
;-----------------------POPUP GUI PROCS--------------------------
;----------------------------------------------------------------

DRAW_POPUP PROC

    MOV SI,DI
    MOV DI,8340+2400

    MOV BX,192
    LB2:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40
    ADD DI,80

    DEC BX
    JNZ LB2

    CALL DRAW_POPUP_QUIT_BUTTON

    CALL DRAW_POPUP_INPUT
    CALL DRAW_POPUP_BUTTON

    MOV DI,SI

    RET

DRAW_POPUP ENDP

CLEAR_POPUP PROC

    MOV SI,DI

    MOV DI,8340+2400

    MOV BX,192
    LB2_CLR:

    MOV dx,03C4h ; dx = indexregister
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40

    ADD DI,80

    DEC BX
    JNZ LB2_CLR

    MOV DI,SI

    RET

CLEAR_POPUP ENDP

DRAW_POPUP_BUTTON PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+2400+5120+4+1440+5120

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,10
    ADD DI,80

    MOV BX,28
    L_OK_BUT:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,10000000b ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,1

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    DEC BX
    JNZ L_OK_BUT

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    ;--CLEAR BUTTON--
    MOV DI,8340+2400+5120+26+1440+5120

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,10
    ADD DI,80

    MOV BX,28
    L_CLEAR_BUT:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_CLEAR_BUT

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,18    ;row
    MOV DL,28   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET OK_MSG
    MOV SI,BX ;EXIT BUTTON

    L_OK_TEXT:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_OK_TEXT

    ;---------CANCEL TEXT---------

    MOV DH,18    ;row
    MOV DL,49   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET CLEAR_MSG
    MOV SI,BX ;EXIT BUTTON

    L_CLEAR_TEXT:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_CLEAR_TEXT

    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

    DRAW_POPUP_BUTTON ENDP

    DRAW_POPUP_QUIT_BUTTON PROC

    ;--DRAWING QUIT BUTTON--

    MOV DI,8340+2400+38
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,2 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,2
    ADD DI,80

    MOV BP,15
    MOV BH,10000000b
    MOV BL,00000001b
    XCHG BH,BL
    LB33:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray

    MOV ax,BX ; write to every pixel.
    REP STOSW ; fill the screen

    SUB DI,2
    ADD DI,80

    DEC BP
    JNZ LB33

    ; DRAWING BOTTOM EDGE

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,0FFFFh ; write to every pixel.
    REP STOSW ; fill the screen

    ;DRAWING CROSS

    MOV DI,8340+2400+38+320

    MOV BP,5
    MOV BH,00011000b
    MOV BL,00011000b
    LB34:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    ;DRAWING CROSS OUTSIDE RED
    MOV DI,8340+2400+38

    MOV BP,16

    LB36:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,0FFFFh ; write to every pixel.
    REP STOSW ; fill the screen

    SUB DI,2
    ADD DI,80

    DEC BP
    JNZ LB36

    RET

DRAW_POPUP_QUIT_BUTTON ENDP

DRAW_POPUP_INPUT PROC

    MOV DI,8340+2400+5120+4+1440

    MOV BX,30
    LB22:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,32 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,32

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,32 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,32
    ADD DI,80

    DEC BX
    JNZ LB22

    MOV DI,SI

    RET

DRAW_POPUP_INPUT ENDP

CLEAR_POPUP_INPUT PROC

    MOV DI,8340+2400+5120+4+1440

    MOV BX,30

    LB223:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0302h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,32 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,32
    ADD DI,80

    DEC BX
    JNZ LB223

    RET

CLEAR_POPUP_INPUT ENDP 

DRAW_POPUP_SEARCH PROC
    MOV SI,DI
    MOV DI,8340+2400

    MOV BX,192
    LB2_FIND:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,40 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,40
    ADD DI,80

    DEC BX
    JNZ LB2_FIND

    CALL DRAW_POPUP_QUIT_BUTTON

    CALL DRAW_POPUP_INPUT
    CALL DRAW_POPUP_BUTTON_SEARCH

    MOV DI,SI

    RET

DRAW_POPUP_SEARCH ENDP 

DRAW_POPUP_BUTTON_SEARCH PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+5120+15+1440+5120+2400
    
    MOV BX,30
    L_OK_BUT3_SEL_FIND:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
       
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL_FIND

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,18    ;row
    MOV DL,37   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET FIND_BTN
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT2_FIND:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2_FIND
    
    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

DRAW_POPUP_BUTTON_SEARCH ENDP

PRINT_FOUND_NUM PROC
        
    MOV DI,8340+5120+15+1440+5120+2400
       
    MOV BX,30
    L_OK_BUT3_SEL_FIND2:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
 
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL_FIND2    
    
    ;--PRINTING BUTTON TEXT--

    MOV DH,18    ;row
    MOV DL,39   ;column
    CALL CURSOR_SET
       
    MOV BX,OFFSET OK_MSG
    MOV SI,BX ;EXIT BUTTON
    
    L_SAVE_TEXT2_FIND3:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2_FIND3
   
    MOV DH,16    ;row
    MOV DL,22   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET FOUND_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT2_FIND2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2_FIND2
    
    
    MOV BX,offset FOUND_NUM
    MOV CX,[BX]
    
    MOV DH,0
    MOV AX,CX
    MOV DL,100
    DIV DL
    
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AX,CX
    MOV DL,10
    DIV DL
    MOV DH,AH
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT

    MOV AL,DH
    
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    CALL PRINT_FOUND_NUM2
    
    RET
PRINT_FOUND_NUM ENDP

PRINT_FOUND_NUM_REP PROC
       
    MOV DI,8340+5120+15+1440+5120+2400
    
    MOV BX,30
    L_OK_BUT3_SEL_FIND2A:
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0B02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,000h ; write to every pixel.
    REP STOSB ; fill the screen
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,9 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
  
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL_FIND2A 
  
    ;--PRINTING BUTTON TEXT--

    MOV DH,18    ;row
    MOV DL,37   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET REPLACE_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT2_FIND3A:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2_FIND3A
    
 
    MOV DH,16    ;row
    MOV DL,22   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET FOUND_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT2_FIND2A:

    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2_FIND2A
    
    
    MOV BX,offset FOUND_NUM
    MOV CX,[BX]
    
    MOV DH,0
    MOV AX,CX
    MOV DL,100
    DIV DL
    
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AX,CX
    MOV DL,10
    DIV DL
    MOV DH,AH

    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,DH
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
     
    CALL PRINT_FOUND_NUM2
    
    RET
PRINT_FOUND_NUM_REP ENDP

PRINT_FOUND_NUM2 PROC
      
    MOV DH,16    ;row
    MOV DL,40   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET FOUND2_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT2_FIND23:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2_FIND23
    
    
    MOV BX,offset FOUND_NUM_PAGE
    MOV CX,[BX]
    
    MOV DH,0
    MOV AX,CX
    MOV DL,100
    DIV DL 

    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT 
    
    MOV AX,CX
    MOV DL,10
    DIV DL
    MOV DH,AH
    
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
      
    MOV AL,DH
             
    XOR AL,30h
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
       
    RET
    
PRINT_FOUND_NUM2 ENDP 

PRINT_COLORED_TEXT PROC ; Print Char in AL and Colored for value in BL with Teletype Mode
    
    MOV AH, 0Eh
    MOV BH,0
    INT 10h           ;Gives character in AL (keep it!), and attribute in AH  
    
    RET
    
PRINT_COLORED_TEXT ENDP

FIND_ASK_PROC PROC
     
    MOV BX,offset DISABLED_EDITOR
    MOV DX,[BX]
    CMP DX,0
    JNZ START_WANNA_BEFORE_FIND
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
    START_WANNA_BEFORE_FIND:
      
    CALL CLEAR_POPUP    
    CALL DRAW_POPUP_SEARCH
    
    ;PRINTING POPUP MESSAGE FOR LOAD POPUP
    
    MOV DH,11    ;row
    MOV DL,23   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET FIND_MSG
    MOV SI,BX ;EXIT BUTTON
    
    L_PIR_MEN_FIND: 
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX  
        
CONTINUE_LOADFILE_MEN_FIND: 
         
    MOV DH,14    ;row
    MOV DL,30   ;column
    CALL CURSOR_SET  
    
    MOV BX,offset FIND_WORD
    MOV SI, BX
    MOV CX,0
    
L_LOAD_FILE_MEN_FIND: 
    MOV ah,00h
    INT 16h
    
    CMP AL,09h
    JZ L_LOAD_FILE_MEN_FIND
    
    CMP CX,0
    JNZ PASS_FIRST_CHAR_CHECK
    
    CMP AL,' '
    JZ L_LOAD_FILE_MEN_FIND
    
    
    PASS_FIRST_CHAR_CHECK:

    CMP AX,1C0Dh
    JZ LOAD_NEW_MEN_FIND
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JNZ GO_BACK2_FIND
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    CALL STAY_CURRENT_PAGE
    
    CALL READ_FILE2
    
    CALL EDITOR_CURSOR_DRAW
    
    RET

    GO_BACK2_FIND: 
    CMP AX,0E08h
    JZ BACKSPACE_LOAD_MEN_FIND
    CMP CX,20
    JZ L_LOAD_FILE_MEN_FIND
         
    MOV [SI],AL
    INC SI
    INC CX
        

    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_LOAD_FILE_MEN_FIND
    
    BACKSPACE_LOAD_MEN_FIND:
    
    CMP CX,0
    JZ L_LOAD_FILE_MEN_FIND
    
    DEC SI
    DEC CX
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_LOAD_FILE_MEN_FIND 
    
    LOAD_NEW_MEN_FIND:
    
    CMP CX,0
    JZ NONAME_LOADFILE_MEN_FIND
    
    MOV BX,offset FIND_WORD_LEN
    MOV [BX],CX
    MOV [SI],0FFH
    
    ;--CONTROL IF FILE IS EXIST--
    CALL CLEAR_USELESS_STR
    CALL LOWER_CASE_FIND
    
    MOV BX,offset FOUND_TEMP
    MOV [BX],0
    CALL FIND_ALGORITHM
    
    MOV BX,offset FOUND_NUM
    MOV DX,[BX]
    CMP DX,0
    JNZ PASS_ZERO_FOUND_S
    
    MOV BX,offset FIND_WORD_LEN
    MOV [BX],0
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET ZERO_FOUND_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
    
    JMP CONTINUE_LOADFILE_MEN_FIND
    
    PASS_ZERO_FOUND_S:
    
    CALL COUNT_CUR_PAGE_FOUND
    CALL PRINT_FOUND_NUM
   
    MOV BX,offset FOUND_NUM_PAGE
    MOV DX,[BX]
    CMP DX,0
    JZ PASS_CURSOR_SET2
   
    CALL STAY_CURRENT_PAGE
    CALL CURSOR_POS_FINDER
    
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    MOV BP,AX 
    
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FOUND_CURSOR
    MOV DX,[BX]
    CALL CURSOR_SET
    
    MOV BX,offset FOUND_PAGE
    MOV DI,[BX]
    MOV BX,offset FILE_RESTORE
    SUB DI,BX
    MOV BX,offset FILE_POINTER
    DEC DI
    MOV [BX],DI

    PASS_CURSOR_SET2:
 
    MOV AH,00
    INT 16h 
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    CALL STAY_CURRENT_PAGE
    
    CALL READ_FILE2
    
    CALL EDITOR_CURSOR_DRAW

    RET
  
    NONAME_LOADFILE_MEN_FIND: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_LOADFILE_MEN_FIND
    
    
    RET
    
FIND_ASK_PROC ENDP

FIND_REPLACE_ASK PROC
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],0
    
    MOV BX,offset DISABLED_EDITOR
    MOV DX,[BX]
    CMP DX,0
    JNZ START_WANNA_BEFORE_FIND2
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
 START_WANNA_BEFORE_FIND2:
     
    CALL CLEAR_POPUP    
    CALL DRAW_POPUP_SEARCH
    
    ;PRINTING POPUP MESSAGE FOR LOAD POPUP
    
    MOV DH,11    ;row
    MOV DL,24   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET FIND2_MSG
    MOV SI,BX ;EXIT BUTTON
    
    L_PIR_MEN_FIND2: 
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_MEN_FIND2 
    
        
CONTINUE_LOADFILE_MEN_FIND2: 
         

    MOV DH,14    ;row
    MOV DL,30   ;column
    CALL CURSOR_SET  
    
    MOV BX,offset FIND_WORD
    MOV SI, BX
    MOV CX,0
    
L_LOAD_FILE_MEN_FIND2: 
    MOV ah,00h
    INT 16h
    
    CMP AL,09h
    JZ L_LOAD_FILE_MEN_FIND2
    
    CMP CX,0
    JNZ PASS_FIRST_CHAR_CHECK2
    
    CMP AL,' '
    JZ L_LOAD_FILE_MEN_FIND2
    
    
    PASS_FIRST_CHAR_CHECK2:

    CMP AX,1C0Dh
    JZ LOAD_NEW_MEN_FIND2
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JNZ GO_BACK2_FIND2
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    CALL STAY_CURRENT_PAGE
    
    CALL READ_FILE2
    
    CALL EDITOR_CURSOR_DRAW
    
    RET

    GO_BACK2_FIND2: 
    CMP AX,0E08h
    JZ BACKSPACE_LOAD_MEN_FIND2
    CMP CX,20
    JZ L_LOAD_FILE_MEN_FIND2
    
        
    MOV [SI],AL
    INC SI
    INC CX
    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_LOAD_FILE_MEN_FIND2
    
    BACKSPACE_LOAD_MEN_FIND2:
    
    CMP CX,0
    JZ L_LOAD_FILE_MEN_FIND2
    
    DEC SI
    DEC CX

    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
      
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_LOAD_FILE_MEN_FIND2 
    
    LOAD_NEW_MEN_FIND2:
    
    CMP CX,0
    JZ NONAME_LOADFILE_MEN_FIND2
    
    MOV BX,offset FIND_WORD_LEN
    MOV [BX],CX
    MOV [SI],0FFH
    
    ;--CONTROL IF FILE IS EXIST--
    CALL CLEAR_USELESS_STR
    CALL LOWER_CASE_FIND
    
    MOV BX,offset FOUND_TEMP
    MOV [BX],0
    CALL FIND_ALGORITHM
    CALL COUNT_CUR_PAGE_FOUND
    
    MOV BX,offset FOUND_NUM
    MOV DX,[BX]
    CMP DX,0
    JNZ PASS_ZERO_FOUND
    
    MOV BX,offset FIND_WORD_LEN
    MOV [BX],0
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET ZERO_FOUND_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
 
    
    JMP CONTINUE_LOADFILE_MEN_FIND2
  
    PASS_ZERO_FOUND:
      
    MOV BX,offset FOUND_NUM_PAGE
    MOV DX,[BX]
    CMP DX,0
    JZ PASS_CURSOR_SET22
   
    CALL STAY_CURRENT_PAGE
    CALL CURSOR_POS_FINDER
    ;CALL EDITOR_CURSOR_CLEAR
    
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    MOV BP,AX 
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FOUND_CURSOR
    MOV DX,[BX]
    CALL CURSOR_SET
    
    MOV BX,offset FOUND_PAGE
    MOV DI,[BX]
    MOV BX,offset FILE_RESTORE
    SUB DI,BX
    MOV BX,offset FILE_POINTER
    DEC DI
    MOV [BX],DI
    
   ;CALL EDITOR_CURSOR_DRAW
    
   ;REPLACE INPUT
    
    PASS_CURSOR_SET22:
    
    CALL CLEAR_POPUP    
    CALL DRAW_POPUP_SEARCH
    
    ;PRINTING POPUP MESSAGE FOR LOAD POPUP
    
    MOV DH,11    ;row
    MOV DL,24   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET FIND_REP_MSG
    MOV SI,BX ;EXIT BUTTON
    
    L_PIR_MEN_FIND2A:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_MEN_FIND2A
    
    
    MOV BX,OFFSET FIND_WORD
    MOV SI,BX ;EXIT BUTTON
    
    L_PIR_MEN_FIND2W:
    MOV AL,[SI]
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,0FFh
    JNZ L_PIR_MEN_FIND2W
     
    MOV BX,OFFSET FIND_REP_MSG2
    MOV SI,BX ;EXIT BUTTON
    
    L_PIR_MEN_FIND2B: 
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_MEN_FIND2B
    
    CALL PRINT_FOUND_NUM_REP     
        
CONTINUE_LOADFILE_MEN_FIND2_REP: 
         
    MOV DH,14    ;row
    MOV DL,30   ;column
    CALL CURSOR_SET  
    
    MOV BX,offset REPLACE_WORD
    MOV SI, BX
    MOV CX,0
    
L_LOAD_FILE_MEN_FIND2_REP: 
  
    MOV AH,00
    INT 16h 
      
    CMP AL,09h
    JZ L_LOAD_FILE_MEN_FIND2_REP
    
    CMP CX,0
    JNZ PASS_FIRST_CHAR_CHECK2_REP
    
    CMP AL,' '
    JZ L_LOAD_FILE_MEN_FIND2_REP
    
    
    PASS_FIRST_CHAR_CHECK2_REP:

    CMP AX,1C0Dh
    JZ LOAD_NEW_MEN_FIND2_REP
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JNZ GO_BACK2_FIND2_REP
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    CALL STAY_CURRENT_PAGE    
    CALL READ_FILE2
    
    CALL EDITOR_CURSOR_DRAW
    
    RET

    GO_BACK2_FIND2_REP: 
    CMP AX,0E08h
    JZ BACKSPACE_LOAD_MEN_FIND2_REP
    CMP CX,19
    JZ L_LOAD_FILE_MEN_FIND2_REP
            
    MOV [SI],AL
    INC SI
    INC CX

    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_LOAD_FILE_MEN_FIND2_REP
    
    BACKSPACE_LOAD_MEN_FIND2_REP:
    
    CMP CX,0
    JZ L_LOAD_FILE_MEN_FIND2_REP
    
    DEC SI
    DEC CX
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
      
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_LOAD_FILE_MEN_FIND2_REP 
    
    LOAD_NEW_MEN_FIND2_REP:
    
    CMP CX,0
    JZ NONAME_LOADFILE_MEN_FIND2_REP
    
    MOV BX,offset REPLACE_WORD_LEN
    MOV [BX],CX
    MOV [SI],0FFH
    
    ;--CONTROL IF FILE IS EXIST--
    CALL CLEAR_USELESS_STR

    CALL REPLACE_ALGORITHM
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],1
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    CALL STAY_CURRENT_PAGE
    CALL READ_FILE2
    
    CALL EDITOR_CURSOR_DRAW
    
    RET
    
    NONAME_LOADFILE_MEN_FIND2_REP: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_LOADFILE_MEN_FIND2_REP  
    
    NONAME_LOADFILE_MEN_FIND2: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_LOADFILE_MEN_FIND2
    
    
    RET

FIND_REPLACE_ASK ENDP

;----------------------------------------------------------------
;---------------------ADDITIONAL GUI TOOLS-----------------------
;----------------------------------------------------------------

HCTTP_LOGO PROC ; PRINT HACETTEPE LOGO TO SCREEN (COL,ROW)=(CX,DX)

    MOV BX,offset HACETTEPE_LOGO
    MOV SI,BX

    MOV CX,312
    MOV DX,1

    L1:
    MOV AH,0Ch
    MOV AL,[SI]
    INT 10h
    INC SI
    INC CX
    CMP [SI],'$'
    JNZ L1

    INC SI
    MOV CX,312
    INC DX
    CMP DX,28
    JNZ L1

    RET

HCTTP_LOGO ENDP

OWNERs_SIGNATURE PROC ; PRINTING CODER's INFO

    MOV DH,1Ch    ;row
    MOV DL,24h   ;column
    CALL CURSOR_SET

    MOV DX,OFFSET OWNER ; set the string to print

    MOV AX,0920h  ;AH=Function number AL=Space character
    MOV CX,200  ; number of chars that will be painted
    INT 10h     ;BIOS function 09h
    INT 21H     ;DOS function 09h

    MOV DH,1Dh    ;row
    MOV DL,24h   ;column
    CALL CURSOR_SET

    MOV DX,OFFSET SCHL_NUM ; set the string to print

    MOV AX,0920h  ;AH=Function number AL=Space character
    MOV CX,200  ; number of chars that will be painted
    INT 10h     ;BIOS function 09h
    INT 21H     ;DOS function 09h

    CALL BUTTON_BACKGROUND

    RET

OWNERs_SIGNATURE ENDP

ARROW_DRAW PROC ; PRINT HACETTEPE LOGO TO SCREEN (COL,ROW)=(CX,DX)

    ;--UPPER TRIANGLE--

    MOV SI,DI ;Store Current Value of DI to SI
    ADD DI,320+5 ; 8340 + SELECTED BUTTON POSITION + ADJUSMENT FOR DRAWN

    MOV BX,0111111111111111b
    MOV BP,11
    UP_TRI:
    CALL ARROW_TRIANGLE

    XCHG BH,BL

    SHR BX,1

    SUB DI,2
    ADD DI,80

    DEC BP
    JNZ UP_TRI

    SHL BX,1
    INC BX
    ;--LOWER TRIANGLE--

    MOV BP,11
    LO_TRI:
    CALL ARROW_TRIANGLE

    XCHG BH,BL

    SHL BX,1
    INC BX

    SUB DI,2
    ADD DI,80

    DEC BP
    JNZ LO_TRI

    ;--ARROW TAIL--

    MOV DI,SI
    ADD DI,800+2 ;Adjusment DI for ARROW TAIL

    MOV BH,10

    RECT:
    MOV CX,3
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV AX,0
    REP STOSB

    SUB DI,3
    ADD DI,80

    DEC BH
    JNZ RECT

    MOV DI,SI

    RET

ARROW_DRAW ENDP

ARROW_TRIANGLE PROC

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV CX,1
    XCHG BH,BL
    MOV AX,BX
    REP STOSW ; fill the screen

    RET

ARROW_TRIANGLE ENDP

CLEAR_ARROW PROC

    MOV SI,DI

    MOV BH,30

    CLR_ARR:
    MOV CX,7
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV AX,0FFh
    REP STOSB

    SUB DI,7
    ADD DI,80

    DEC BH
    JNZ CLR_ARR

    MOV DI,SI

    RET

CLEAR_ARROW ENDP

;-----------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------HOME PAGE AND MENU AND EDITOR MASTER PROC------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------

MENU PROC

    CALL HEADER

    CALL BACKGROUND_GRAY

    MOV BH,5 ; Number of Buttons to Display = 5 for Menu

    MOV SI,DI ;Store Current Value of DI to SI
    MOV DI,8340 ; 8340 for 5 Button -> Button Position Adjustment

    CALL DRAW_BUTTONS

    STC ; Set Carry for showing Menu in Button Text

    CALL BUTTON_TEXT

    CALL FOOTER

    CALL MENU_BACKEND

    RET

MENU ENDP

HOMEPAGE PROC

    CALL HEADER

    CALL BACKGROUND_GRAY

    MOV BH,3 ; Number of Buttons to Display = 3 for Homepage

    MOV SI,DI ;Store Current Value of DI to SI
    MOV DI,8340+5120 ; 8340 for 5 Button -> Button Position Adjustment

    CALL DRAW_BUTTONS ;5120 Difference between next  button Addres

    CLC ; Clear Carry for showing Homepage in Button Text

    CALL BUTTON_TEXT

    CALL FOOTER

    CALL HOMEPAGE_BACKEND

    RET

HOMEPAGE ENDP


EDITOR PROC

    CALL HEADER

    CALL BACKGROUND_GRAY_EDITOR

    CALL FOOTER_EDITOR

    CALL HEADER_TEXT

    CALL EDITOR_BACKEND


    RET

EDITOR ENDP

;-----------------------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------BACKEND PROCS------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------

;----------------------------------------------------------------
;------------------------GUI CONTROLLERS-------------------------
;----------------------------------------------------------------

HOMEPAGE_BACKEND PROC
    
    MOV DI,8340+5120 ;First Button Video Address for HOMEPAGE
    
    CALL ARROW_DRAW ; IT WILL DISPLAY WHICH BUTTON CURRENTLY SELECTED

LOOPMAIN:

    MOV ah,00h

    INT 16h
    ; UP ARROW BUTTON AX=4800h DOWN ARROW BUTTON AX=5000h, ESC-> AX=011Bh
    ;ENTER AX = 1C0Dh

    CMP AX,5000h
    JZ DOWN_ARROW
    
    CMP AX,4800h
    JZ UP_ARROW
    
    CMP AX,011Bh
    JZ EXIT
    
    CMP AX,1C0Dh
    JZ ENTER_BUT
    
    JMP PASSZ
    
    
DOWN_ARROW:
    CALL CLEAR_ARROW
    CMP DI,23700
    JZ RETURN_UP
    ADD DI,5120
    JMP PASSZ
     
    RETURN_UP:
    SUB DI,10240
    

    JMP PASSZ
    
UP_ARROW:
    CALL CLEAR_ARROW
    CMP DI,13460
    JZ RETURN_DOWN
    SUB DI,5120
    JMP PASSZ
    
    RETURN_DOWN:
    ADD DI,10240
    
    JMP PASSZ
    
ENTER_BUT:
    
    CMP DI,23700
    JZ EXIT
    
    CMP DI,18580
    JZ NEWFILE_M
    
    CMP DI,13460
    JZ LOAD_M
    
    JMP NOTDRAW
    
LOAD_M:

    CALL CLEAR_ARROW
    CALL CLEAR_FRAME
    CALL DRAW_POPUP
    
    ;PRINTING POPUP MESSAGE FOR LOAD POPUP
    
    MOV DH,11    ;row
    MOV DL,23   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET LOAD_MSG
    MOV SI,BX ;EXIT BUTTON
    
L_PIR: 
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR 
    
        
CONTINUE_LOADFILE: 
    
    MOV DH,14    ;row
    MOV DL,41   ;column
    CALL CURSOR_SET
    
    MOV BL,0F3h;White Foreground,Red Background
    MOV AL,'.'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT
    MOV AL,'x'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT         

    MOV DH,14    ;row
    MOV DL,33   ;column
    CALL CURSOR_SET  
    
    MOV BX,offset FILENAME
    MOV SI, BX
    MOV CX,0
    
L_LOAD_FILE: 
    MOV ah,00h
    INT 16h

    CMP AX,1C0Dh
    JZ LOAD_NEW
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JZ GO_BACK
    CMP AX,0E08h
    JZ BACKSPACE_LOAD
    CMP CX,8
    JZ L_LOAD_FILE
    
        
    MOV [SI],AL
    INC SI
    INC CX
    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_LOAD_FILE
    
    BACKSPACE_LOAD:
    
    CMP CX,0
    JZ L_LOAD_FILE
    
    DEC SI
    DEC CX
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
                
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_LOAD_FILE 
    
    LOAD_NEW:
    
    CMP CX,0
    JZ NONAME_LOADFILE
    
    MOV [SI],'.'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],'x'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],0
    
    ;--CONTROL IF FILE IS EXIST--
    
    CALL OPEN_FILE
    
	JC FILE_NOT_EXIST2 ;File not exist Error
	
	JMP FILE_EXIST2  ;FILE EXIST
    
    
    ;--LOADING FILE ERROR--
    FILE_NOT_EXIST2: ;IF FILE IS NOT EXIST ERROR MSG WILL SHOW UP
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,30   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET FILE_NEXIST_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
    
    JMP CONTINUE_LOADFILE
	
	
	;--LOADING FILE--
	
    FILE_EXIST2:
    MOV [SI], AX ; AX->File Handle 
    
    
    JMP END2 ; ITS DONE
      
    
    NONAME_LOADFILE: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_LOADFILE     


NEWFILE_M:
    
    CALL CLEAR_ARROW
    CALL CLEAR_FRAME
    CALL DRAW_POPUP
    
    ;PRINTING POPUP MESSAGE FOR NEWFILE POPUP
    
    MOV DH,11    ;row
    MOV DL,22   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET NEWFILE_MSG
    MOV SI,BX ;EXIT BUTTON
    

L_PIR2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR2

CONTINUE_NEWFILE: 
    
    MOV DH,14    ;row
    MOV DL,41   ;column
    CALL CURSOR_SET
    
    MOV BL,0F3h;White Foreground,Red Background
    MOV AL,'.'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT
    MOV AL,'x'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT         
    

    MOV DH,14    ;row
    MOV DL,33   ;column
    CALL CURSOR_SET   


    MOV BX,offset FILENAME
    MOV SI, BX
    MOV CX,0
    

L_SAVE_FILE: 
    MOV ah,00h
    INT 16h

    CMP AX,1C0Dh
    JZ SAVE_NEW
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JZ GO_BACK
    CMP AX,0E08h
    JZ BACKSPACE
    CMP CX,8
    JZ L_SAVE_FILE
    
        
    MOV [SI],AL
    INC SI
    INC CX
    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_SAVE_FILE
    
    BACKSPACE:
    
    CMP CX,0
    JZ L_SAVE_FILE
    
    DEC SI
    DEC CX
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
      
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT

    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_SAVE_FILE 
    
    SAVE_NEW:
    
    CMP CX,0
    JZ NONAME_NEWFILE
    
    MOV [SI],'.'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],'x'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],0
    
    ;--CONTROL IF FILE IS EXIST--
    
    CALL OPEN_FILE
    
	JC FILE_NOT_EXIST
	
	JMP FILE_EXIST  ;FILE EXIST ERROR
    
    
    ;--CREATING FILE--
    FILE_NOT_EXIST:
    
    CALL CREATE_FILE
	
	JC GO_BACK ;IF there is an ERRR
	
	MOV [SI], AX
	JMP END2  ; ITS DONE
	
	
	FILE_EXIST:;IF FILE IS EXIST ERROR MSG WILL SHOW UP
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET FILE_EXIST_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
    
    JMP CONTINUE_NEWFILE
    
    NONAME_NEWFILE: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_NEWFILE

    PASSZ:
    
    CALL ARROW_DRAW
    
    NOTDRAW:
    
    JMP LOOPMAIN 
    
    GO_BACK:
    CALL CLEAR_POPUP
    
    JMP BACK_HOMEPAGE
         
END2:
        
    RET
    
HOMEPAGE_BACKEND ENDP

MENU_BACKEND PROC
    
    MOV DI,8340 ;First Button Video Address for HOMEPAGE
    
    CALL ARROW_DRAW ; IT WILL DISPLAY WHICH BUTTON CURRENTLY SELECTED
LOOPMAIN_M:

    MOV ah,00h
    INT 16h

    ; UP ARROW BUTTON AX=4800h DOWN ARROW BUTTON AX=5000h, ESC-> AX=011Bh
    ;ENTER AX = 1C0Dh
    
      
    CMP AX,5000h
    JZ DOWN_ARROW_M
    
    CMP AX,4800h
    JZ UP_ARROW_M
    
    CMP AX,011Bh
    JZ MENU_END
    
    CMP AX,1C0Dh
    JZ ENTER_BUT_M
    
    JMP PASSZ_M
    
    
DOWN_ARROW_M:
    XXXX
    XXXX
    XXXX
    XXXX
    MP PASSZ
     
    RETURN_UP_M:
    XXXX
    
    JMP PASSZ
    
UP_ARROW_M:
    XXXX
    XXXX
    XXXX
    XXXX
    JMP PASSZ_M
    
    RETURN_DOWN_M:
    XXXX
    
    JMP PASSZ_M
    
ENTER_BUT_M:

    XXXX
    XXXX
    XXXX

    JMP NOTDRAW_M   
    
    PASSZ_M:
    
    XXXX
    
    NOTDRAW_M:
    
    JMP LOOPMAIN_M

MENU_END:    

    RET
    
MENU_BACKEND ENDP

EDITOR_BACKEND PROC
    
    CALL RESTORE_FILE

START_EDITOR:    
    XXXX
    XXXX
    XXXX
    XXXX
    
EDITOR_INPUT:
    
    CALL PRINT_CURSOR_POS
    
    MOV AH,00h
    INT 16h
    
    CMP AX,1C0Dh
    JZ NEWLINE_ENTER
    
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JZ EXIT
    
    CMP AX,4800h ; UP ARROW
    JZ CURSOR_UP
    
    CMP AX,5000h ; DOWN ARROW
    JZ CURSOR_DOWN
    
    CMP AX,4D00h ; RIGHT ARROW
    JZ CURSOR_RIGHT
    
    CMP AX,4B00h  ; LEFT ARROW
    JZ CURSOR_LEFT
    
    CMP AX,0E08h
    JZ BACKSPACE_PRESSED
    
    
    CMP AX,3B00h ;F1 - MENU
    JZ F1_MENU 
    
    CMP AX,3C00h ;F2 - LOAD
    JZ F2_LOAD
    
    CMP AX,3D00h   ; F3 - NEW
    JZ F3_NEW 
    
    CMP AX,3E00h ;F4 - SAVE
    JZ F4_SAVE         
    
    CMP AX,3F00h ;F5 - FIND
    JZ F5_FIND
    
    CMP AX,4000h ;F6 - FIND AND REPLACE
    JZ F6_FIND_REPLACE    
    
    CMP AX,4100h ; F7 - CAP SENT
    JZ F7_CS
    
    CMP AX,4200h ;F8 - CAP WORDS
    JZ F8_CW
    
    CMP AX,0F09h
    JZ TAB     
    
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],1
    XXXX ; ELSE (WRITE TO EDITOR PRESSED CHAR)

    JMP EDITOR_INPUT

    TAB:
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],1
    

    MOV AL,' '
    XXXX
    
    MOV AL,' '
    XXXX 

    
    JMP EDITOR_INPUT
    
    
    
    F1_MENU:
    
    XXXX
    
    F1_MENU_CONT:
    
    XXXX
    
    XXXX
    XXXX
   
    
    
    JMP START_EDITOR
    
   
    F2_LOAD:
    
    XXXX
    XXXX

    XXXX

    XXXX

    XXXX

    XXXX
    XXXX
    XXXX
    
    JMP START_EDITOR
    


    F3_NEW:
    
    XXXX

    XXXX
    XXXX

    XXXX

    XXXX

    XXXX

    XXXX
    
   
   
    F4_SAVE: 
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX

    XXXX

    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    
    JMP START_EDITOR
    
    
    F5_FIND:
    
    XXXX
    XXXX

    XXXX
    
    
    JMP EDITOR_INPUT
    
    
    
    F6_FIND_REPLACE:

    
    CALL FIND_REPLACE_ASK
    
    JMP EDITOR_INPUT
    
    
    F7_CS:
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    JMP START_EDITOR
    
    F8_CW:
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    
    CALL CAPITALIZE_WORDS
    
    
    JMP START_EDITOR
  
        
    BACKSPACE_PRESSED:


    CALL BACKSPACE_PROC
    
    JMP EDITOR_INPUT
    
    NEWLINE_ENTER:
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],1
     
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV BX,offset CURSOR_Y
    MOV CX,[BX]
    MOV DX,0
    MOV DL,78
    DIV DL
    SUB CX,AX   

    CMP CX,24
    JZ END_NL
    

    
    CMP CX,0
    JZ NL_1
    
    
    INC CX
    
    MOV BX,offset CURSOR_X
    MOV AX,[BX] ;X
    INC AX
    
    CMP AX,1
    JNZ NL_1
    
    MOV BX,offset NEWLINE_POINTERS
    
    L_NEWLINE_COUNTER_NL2:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL ; DH = ROW, DL=COL
    JE NL_1
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER_NL2
    
    CALL NEWLINE_PROC
    
    CALL NEWLINE_PROC
    
    
    MOV BX,offset CURSOR_Y
    MOV CX,[BX]
    DEC CX
    MOV [BX],CX
    
    
    JMP START_EDITOR 
    
    
NL_1:

 
    CALL NEWLINE_PROC
    JMP START_EDITOR  
        
    
END_NL:

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX 



    XXXX
    XXXX
    XXXX
    
    XXXX
    
    L_NEWLINE_COUNTER_NL:
        
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER_NL
     
    
    CALL EDITOR_CURSOR_CLEAR
    
    MOV BX,offset EOF_FLAG
    MOV DX,0
    MOV [BX],DX

    
    CALL SHIFT_DOWN_PROC
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    MOV [BX],DX
    
         
     
    JMP START_EDITOR 
    
    ND1_EXIST_NL: 
    CALL EDITOR_CURSOR_CLEAR
    
    MOV BX,offset EOF_FLAG
    MOV DX,0
    MOV [BX],DX
    
    CALL SHIFT_DOWN_PROC
    
    MOV BX,offset EOF_FLAG
    MOV DX,1
    MOV [BX],DX
    
    CALL EDITOR_CURSOR_CLEAR
    CALL READ_FILE2
    
    CALL NEWLINE_PROC
    
    JMP START_EDITOR

    
    CURSOR_RIGHT:

    CALL CURSOR_RIGHT_PROC
    CMP BP,0
    JZ EDITOR_INPUT

    JMP SHIFT_DOWN

    CURSOR_LEFT:
    
    XXXX
    XXXX
    XXXX

    CALL SHIFT_UP_PROC
    
    XXXX

    XXXX
    XXXX
    
    
    JMP EDITOR_INPUT

    
    CURSOR_DOWN:

    CALL CURSOR_DOWN_PROC

    CMP BP,0
    JZ EDITOR_INPUT
    
    SHIFT_DOWN:

    XXXX

    XXXX
    XXXX
    XXXX
     
    CURSOR_UP:
    
    XXXX

    XXXX
    XXXX
    
    SHIFT_UP:

    XXXX

    XXXX
    XXXX
    XXXX

    RET

EDITOR_BACKEND ENDP

;----------------------------------------------------------------------------
;---------------EDITOR ADDITIONAL BACKEND PROCS------------------------------
;----------------------------------------------------------------------------

NEWLINE_PROC PROC
    
    MOV BP,AX
    
    CALL EXTEND_MEM_NL
    
    MOV DI,2400
     
    CALL BACKGROUND_GRAY_EDITOR
                     
    MOV BX,offset CURSOR_Y ;LINE
    MOV CX,[BX]

    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV BL,78
    DIV BL
    SUB CX,AX
    INC CX  ;CURRENT ROW POSITION
    INC CX

    MOV BX,offset CURSOR_X ;COLUMN
    MOV BX,[BX]
    INC BX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    CALL EDITOR_CURSOR_CLEAR

    MOV BX,offset CURSOR_Y ;LINE
    MOV CX,[BX]
    INC CX
    MOV [BX],CX

    MOV BX,offset CURSOR_X ;COLUMN 
    MOV DX,[BX]
    MOV [BX],0

    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    INC DX
    INC DX

    MOV [BX],DX
    
    CALL STAY_CURRENT_PAGE

    RET
    
NEWLINE_PROC ENDP

BACKSPACE_PROC PROC
    MOV BX,0
    MOV SI,0
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    CMP DX,0
    JNZ CORRECT_BACKSPACE
    
    MOV BP,1; DO NOTHING
    
    RET
    
CORRECT_BACKSPACE:
    
    MOV BX,offset BACKSPACE_LINE
    MOV DX,0
    MOV [BX],DX
    
    CALL CURSOR_LEFT_PROC
    CMP BP,0
    JNZ BACKSPACE_NL
    
    CMP SI,1
    JZ NON_NL
     
    MOV BX,offset BACKSPACE_LINE
    MOV DX,[BX]
    CMP DX,0
    JZ NON_NL
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    INC DX
    INC DX

    MOV [BX],DX
    CALL REDUCE_MEM_NL

    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    DEC DX
    DEC DX
 
    MOV [BX],DX
           
    MOV DI,2400
     
    CALL BACKGROUND_GRAY_EDITOR
                     
    CALL STAY_CURRENT_PAGE
      
    CALL READ_FILE2
    
    MOV BP,0 ; ITS DONE GO TO NEXT INPUT
    
    RET
        
    NON_NL: 
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    
    CALL READ_FILE2
    
    MOV BP,0 ; ITS DONE GO TO NEXT INPUT
    
    RET
    
    BACKSPACE_NL: 

    XXXX

    XXXX

    XXXX

    JMP BACKSPACE_PROC
    
    MOV BP,0
    
    RET

FIN_BACK:

    XXXX
    
    MOV BP,0 ; ITS DONE GO TO NEXT INPUT
    
    RET

BACKSPACE_PROC ENDP

CURSOR_LEFT_PROC PROC
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    CMP DX,0
    
    JNZ CORRECT_CURSOR_LEFT
    
    MOV BP,0
    RET
    
    CORRECT_CURSOR_LEFT:

    MOV BX,offset CURSOR_X
    MOV DX,[BX]

    CMP DX,0
    JZ PASS_CUR_X_DEC
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    JMP DEC_CUR

    PASS_CUR_X_DEC:

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
v   XXXX

    CMP CX,0
    JNZ CONFIRM_LEFT

    MOV BP,1 ; YOU SHOULD PAGE UP.
    RET

CONFIRM_LEFT:

    CALL NEWLINE_CHECK_LEFT
    CMP BP,1
    JZ DEC_CUR

    CALL EDITOR_CURSOR_CLEAR

    MOV BX,offset CURSOR_X
    MOV DX,77
    MOV [BX],DX

    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    DEC DX
    MOV [BX],DX

    XXXX
    XXXX
    XXXX
    XXXX

    DEC_CUR:
    CALL EDITOR_CURSOR_CLEAR
    CALL EDITOR_CURSOR_DRAW

    MOV BP,0 ; ITS DONE, GO TO NEXT INPUT
    RET

CURSOR_LEFT_PROC ENDP

CURSOR_RIGHT_PROC PROC

    CALL NEWLINE_CHECK
    CMP BP,1
    JZ PASS_CUR_X_INC

    MOV BX,offset CURSOR_X
    MOV DX,[BX]

    CMP DX,77
    JZ PASS_CUR_X_INC
    INC DX
    MOV [BX],DX
    JMP INC_CUR

    PASS_CUR_X_INC:

    XXXX
    XXXX
    XXXX    
    XXXX
    XXXX
    XXXX
    XXXX
    CMP CX,24
    JZ PASS_R2

    CALL EDITOR_CURSOR_CLEAR
    MOV BX,offset CURSOR_X
    MOV [BX],0
    JMP CURSOR_DOWN_CHECK_PASS

    PASS_R2:

    MOV BX,offset EOF_FLAG
    MOV DX,[BX]
    CMP DX,1
    JNZ CONFIRM_RIGHT

    MOV BP,0 ; END OF FILE DO NOTHING
    RET

    CONFIRM_RIGHT:

    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX

    MOV BP,1 ; YOU SHOULD SHIFT PAGE DOWN
    RET

    INC_CUR:
    CALL EDITOR_CURSOR_CLEAR
    CALL EDITOR_CURSOR_DRAW

    MOV BP,0 ; ITS DONE GO TO GET NEXT INPUT
    RET

CURSOR_RIGHT_PROC ENDP

CURSOR_DOWN_PROC PROC

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    CMP CX,24
    JZ CURSOR_DOWN_CHECK_PASS
    
    MOV BX,offset FILE_POINTER
    MOV AX,[BX]
    MOV BX,offset FILE_POINTER_TEMP
    MOV [BX],AX
    
    CALL NEWLINE_CHECK_DOWN
    CMP BP,1
    JZ CUR_Y_INC

    CURSOR_DOWN_CHECK_PASS:

    MOV BX,offset EOF_FLAG
    MOV DX,[BX]
    CMP DX,1
    JZ PASS_R3

    CONT_DOWN:

    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV BX,offset CURSOR_Y
    MOV CX,[BX]
    MOV DX,0
    MOV DL,78
    DIV DL
    SUB CX,AX

    CMP CX,24
    JZ PASS_CUR_INC

    CALL EDITOR_CURSOR_CLEAR
    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    INC DX
    MOV [BX],DX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    CMP DX,CX
    JA DONT_DOWN

    JMP CUR_Y_INC

    PASS_CUR_INC:
    CALL EDITOR_CURSOR_CLEAR

    MOV BX,offset CURSOR_X
    MOV DX,[BX]
    MOV [BX],0
    MOV BX,offset FILE_POINTER
    MOV AX,[BX]
    SUB AX,DX
    MOV [BX],AX

    CALL NEWLINE_CHECK_DOWN

    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    INC DX
    MOV [BX],DX

    MOV BP,1
    RET ; GO TO SHIFT_DOWN

    PASS_R3:
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV BX,offset CURSOR_Y
    MOV CX,[BX]
    MOV DX,0
    MOV DL,78
    DIV DL
    SUB CX,AX
    CMP CX,24
    JNZ CONT_DOWN

    MOV BP,0
    RET ; CURSOR DOWN ITS DOWM GO TO NEXT INPUT
    
    DONT_DOWN:
    
    CALL EDITOR_CURSOR_CLEAR
    
    MOV BX,offset FILE_POINTER_TEMP
    MOV AX,[BX]

    
    MOV BX,offset FILE_POINTER
    MOV [BX],AX
    MOV BX,offset CURSOR_Y 
    MOV DX,[BX]
    DEC DX
    MOV [BX],DX
 
    CUR_Y_INC:
    CALL EDITOR_CURSOR_CLEAR
    CALL EDITOR_CURSOR_DRAW

    MOV BP,0
    
    RET ; CURSOR DOWN ITS DOWM GO TO NEXT INPUT

CURSOR_DOWN_PROC ENDP

SHIFT_DOWN_PROC PROC

    MOV BX,offset EOF_FLAG
    MOV DX,[BX]
    CMP DX,1
    JNZ PASS_GO_BACK

    MOV BP,0 ; GO EDITOR_INPUT BECAUSE YOU ARE AT THE END OF FILE
    
    RET

PASS_GO_BACK:

    MOV DI,2400

    CALL BACKGROUND_GRAY_EDITOR

    MOV BX,OFFSET TEMP_PAGE
    MOV DX,[BX] ;CX:DX, EXAMPLE, TO JUMP TO POSITION
    ADD DX,78
    MOV [BX],DX

    MOV BP,1 ;GO TO START_EDITOR TO DRAW NEW PAGE

    RET

SHIFT_DOWN_PROC ENDP

CURSOR_UP_PROC PROC

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    CMP CX,0
    JZ PASS_CUR_DEC

    CALL NEWLINE_CHECK_UP
    CMP BP,1
    JZ CUR_Y_DEC

    CALL EDITOR_CURSOR_CLEAR
    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    DEC DX
    MOV [BX],DX
    JMP CUR_Y_DEC

    PASS_CUR_DEC:
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    PASS_DEC_Y2:

    MOV BP,1 ; CURSOR UP NOT DONE, GO TO SHIFT PAGE UP
    RET

    CUR_Y_DEC:
    CALL EDITOR_CURSOR_CLEAR
    CALL EDITOR_CURSOR_DRAW

    MOV BP,0 ; CURSOR UP DONE GO GET ANOTHER INPUT
    RET

CURSOR_UP_PROC ENDP

SHIFT_UP_PROC PROC

    MOV BX,OFFSET TEMP_PAGE
    MOV DX,[BX]
    CMP DX,0
    JNZ SHIFT_CORRECT

    MOV BP,0 ;CANT SHIFT UP, WE ARE ALREADY IN FIRST PAGE
    RET

SHIFT_CORRECT:

    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    DEC AX
    SHL AX,1

    MOV BX,offset NEXTLINE_PAGES
    ADD BX,AX

    MOV DX,[BX]
    MOV BX,offset NEXTLINE_TEMP
    MOV [BX],DX

    MOV BX,offset FILE_POINTER
    MOV [BX],DX

    SHIFT_UP_PASS:
    CALL EDITOR_CURSOR_CLEAR

    MOV BX,offset CURSOR_X
    MOV [BX],0

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BX,offset CURSOR_Y
    MOV [BX],CX

    MOV DH,2    ;row
    MOV DL,1   ;column
    MOV CX,DX
    CALL CURSOR_SET

    PASS_L_SHIFT2:

    MOV DI,2400

    CALL BACKGROUND_GRAY_EDITOR

    MOV BX,OFFSET TEMP_PAGE
    MOV DX,[BX] ;CX:DX, EXAMPLE, TO JUMP TO POSITION
    SUB DX,78
    MOV [BX],DX

    MOV BP,1 ;SHIFT UP DONE. SUCCES SHIFT PAGE UP
    RET

SHIFT_UP_PROC ENDP

KEYBOARD_CONTROLLER PROC
    
    MOV BX,offset CAP_SENT_FLAG
    MOV [BX],0
    MOV BX,offset CAP_WORDS_FLAG ; CAPITALIAZED BEFORE
    MOV [BX],0
    
    MOV BP,AX
    
    CALL EXTEND_MEM
    
    MOV DI,2400
     
    CALL BACKGROUND_GRAY_EDITOR
                     
    CALL STAY_CURRENT_PAGE                 
    
    MOV AX,BP

    MOV BX,offset CURSOR_Y ;LINE
    MOV CX,[BX]

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BX,offset CURSOR_X ;COLUMN
    MOV BX,[BX]
    INC BX

    MOV DH,CL    ;row
    MOV DL,BL   ;column
    MOV CX,DX
    CALL CURSOR_SET

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV DX,CX
    INC DX
    CALL CURSOR_SET
    
    XXXX
    
    CALL CURSOR_RIGHT_PROC
    
    CMP BP,0
    JZ NOT_SHIFT_KEYBOARD
    
    CALL SHIFT_DOWN_PROC

NOT_SHIFT_KEYBOARD:

    RET

KEYBOARD_CONTROLLER ENDP

NEWLINE_COUNTER PROC

    MOV CX,2
    MOV AX,1 ;X
    
    MOV BX,offset NEWLINE_POINTERS
    
    L_NEWLINE_COUNTER_DOWN5:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL ; DH = ROW, DL=COL
    JE ND1_EXIST5
    
    CMP DX,0FFFFh
    JZ FIN_COUNTER_NEXT
    
    JMP L_NEWLINE_COUNTER_DOWN5    

    JMP FIN_COUNTER_NEXT

    ND1_EXIST5:
    
    MOV AX,DX
    MOV AH,0

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    JMP FIN_COUNTER_NEXT2

FIN_COUNTER_NEXT:
 
    MOV BX,offset NEXTLINE_TEMP
    MOV DX,[BX]
    ADD DX,78
    MOV [BX],DX

FIN_COUNTER_NEXT2:

    RET
    
NEWLINE_COUNTER ENDP

NEWLINE_CHECK PROC
    
    MOV BX, offset FILE_LEN
    MOV AX,[BX]

    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]  
    
    CMP AX,DX
    JZ EDITOR_INPUT
    INC DX
    MOV [BX],DX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset CURSOR_X
    MOV AX,[BX] ;X
    INC AX
    
    MOV BX,offset NEWLINE_POINTERS
    
L_NEWLINE_COUNTER2:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL
    JE CHECK22
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER2    
    
    JMP FIN_NEWLINE_COUNTER2

CHECK22:

    CMP DL,AL   
    JZ CHECK32
    JMP L_NEWLINE_COUNTER2

CHECK32:

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
       
FIN_NEWLINE_COUNTER2:    
    
    RET
    
NEWLINE_CHECK ENDP

NEWLINE_CHECK_UP PROC
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BP,1
    CMP CX,0
    JZ FIN_NEWLINE_COUNTER2_UP
    INC CX

    MOV BP,0
    
    
    MOV BX,offset CURSOR_X
    MOV AX,[BX]
    INC AX
    
    MOV BX,offset NEWLINE_POINTERS
    
L_NEWLINE_COUNTER2_UP:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL
    JE CHECK32_UP
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER2_UP    
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    SUB DX,78
    MOV [BX],DX

    JMP FIN_NEWLINE_COUNTER2_UP

CHECK32_UP:

    CMP DL,AL   
    JB CHECK33_UP 
    
    MOV BP,DX
    MOV AX,DX
    MOV AH,0
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]   
    SUB DX,AX
    SUB DX,1
    MOV [BX],DX

    MOV BP,0
    
    JMP FIN_NEWLINE_COUNTER2_UP 

CHECK33_UP:

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    CALL EDITOR_CURSOR_CLEAR
    MOV DX,BP
    
    MOV AX,DX
    MOV AH,0
    
    DEC AL
         
    MOV BX,offset CURSOR_X
    MOV [BX],AX
    MOV CX,0
    MOV CL,DH
    DEC CL
    DEC CL
    
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    ADD CX,AX
    
    MOV BX,offset CURSOR_Y
    MOV [BX],CX 

    MOV BP,1
       
FIN_NEWLINE_COUNTER2_UP:    
    
    RET
    
NEWLINE_CHECK_UP ENDP

NEWLINE_CHECK_LEFT PROC

    MOV BP,0
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV BX,offset CURSOR_Y
    MOV CX,[BX]
    MOV DX,0
    MOV DL,78
    DIV DL
    SUB CX,AX ;Y

    MOV BP,0

    INC CX

    MOV AX,1
    
    MOV BX,offset NEWLINE_POINTERS
    
L_NEWLINE_COUNTER2_LEFT:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL
    JE CHECK32_LEFT
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER2_LEFT    
    
    JMP FIN_NEWLINE_COUNTER2_LEFT

CHECK32_LEFT:
    
    MOV BP,DX
    
    MOV BX,offset BACKSPACE_LINE
    MOV DX,1
    MOV [BX],DX
    
    MOV DX,BP 
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV DX,BP
    CALL EDITOR_CURSOR_CLEAR
    MOV DX,BP 
    MOV BX,offset CURSOR_X
    MOV DH,0 
    DEC DX
    MOV [BX],DX

    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    DEC DX
    MOV [BX],DX
    MOV BP,1

FIN_NEWLINE_COUNTER2_LEFT:    
    
    RET
    
NEWLINE_CHECK_LEFT ENDP

NEWLINE_CHECK_BACKSPACE PROC

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BP,0

    INC CX

    MOV AX,1
    
    MOV BX,offset NEWLINE_POINTERS
    
L_NEWLINE_COUNTER2_BACKSPACE:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL
    JE CHECK32_BACKSPACE
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER2_BACKSPACE    
    
    JMP FIN_NEWLINE_COUNTER2_BACKSPACE

CHECK32_BACKSPACE:
    
    MOV BP,DX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    DEC DX
    DEC DX 
    MOV [BX],DX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BX,offset CURSOR_Y
    MOV DX,[BX]
    DEC DX
    MOV [BX],DX
    MOV BP,1

FIN_NEWLINE_COUNTER2_BACKSPACE:    
    
    RET
    
NEWLINE_CHECK_BACKSPACE ENDP

NEWLINE_CHECK_DOWN PROC
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    ADD DX,78
    MOV [BX],DX
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset CURSOR_X
    MOV AX,[BX] ;X
    INC AX
    
    MOV SI,AX
    
    MOV BX,offset NEWLINE_POINTERS
    
    L_NEWLINE_COUNTER_DOWN:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL ; DH = ROW, DL=COL
    JE ND1_EXIST
    
    CMP DX,0FFFFh
    JNZ L_NEWLINE_COUNTER_DOWN    
    
    INC CX; SEARCH NEXT LINE
    
    MOV BX,offset NEWLINE_POINTERS
    
    L2_NEWLINE_COUNTER_DOWN:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL ; DH = ROW, DL=COL
    JE ND2_EXIST
    
    CMP DX,0FFFFh
    JNZ L2_NEWLINE_COUNTER_DOWN
     
     
    JMP FIN_DOWN_CHECK 

    ND2_EXIST:
    
    CMP DL,AL
    JB ND2_YES
    
    JMP FIN_DOWN_CHECK
    
    ND2_YES:
    
    MOV BP,DX
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    JMP DONE_DOWN_CURSOR

    ND1_EXIST:
    
    MOV AX,DX
    MOV AH,0
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    SUB DX,78
    ADD DX,2
    ADD DX,AX
    MOV [BX],DX
    
    INC CX; SEARCH NEXT LINE
    
    MOV BX,offset CURSOR_X
    MOV AX,[BX] ;X
    INC AX
    
    MOV BX,offset NEWLINE_POINTERS
    
    L3_NEWLINE_COUNTER_DOWN:
        
    MOV DX,[BX]
    INC BX
    INC BX

    CMP DH,CL ; DH = ROW, DL=COL
    JE ND2_EXIST2
    
    CMP DX,0FFFFh
    JNZ L3_NEWLINE_COUNTER_DOWN
    
    JMP FIN_DOWN_CHECK_L

    ND2_EXIST2:
    CMP DL,AL
    JAE FIN_DOWN_CHECK_L
    
    MOV BP,DX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    MOV AH,0
    SUB DX,AX
    ;sub DX,1 ; NEW ADD
    
    MOV AX,BP
    MOV AH,0
    ADD DX,AX
    
    MOV [BX],DX

    DONE_DOWN_CURSOR:
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX 
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BX,offset TEMP_PAGE ;NEW ADD
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    ADD CX,AX
    
    MOV BX,offset CURSOR_Y
    MOV [BX],CX
    
    MOV BP,1
    
FIN_DOWN_CHECK_L:
 
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
    SUB DX,1 ; NEW ADD
    MOV [BX],DX
    
FIN_DOWN_CHECK:

    MOV BP,0      
    
    RET
    
NEWLINE_CHECK_DOWN ENDP

;----------------------------------------------------------------------------
;-----------------------------FILE OPERATIONS--------------------------------
;----------------------------------------------------------------------------

CLEAR_FILENAME_INPUT PROC
    
    CALL CLEAR_POPUP_INPUT
    
    MOV BX,offset FILENAME
    
    MOV CX,12
    
CLEAR_FILENAME:

    MOV [BX],0
    INC BX
    LOOP CLEAR_FILENAME
        
    
    RET
    
CLEAR_FILENAME_INPUT ENDP

CLEAR_EDITOR_AREA PROC

    
    RET
    
CLEAR_EDITOR_AREA ENDP

INPUT_ERROR_PRINT PROC 
    

    
ERR_PRT:

    MOV AL,[SI]
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ ERR_PRT
     
    MOV AH,00
    INT 16h
        
    CALL CLEAR_POPUP_INPUT
    MOV SI,offset FILENAME 
     
    RET

INPUT_ERROR_PRINT ENDP 



CREATE_FILE PROC
    
    MOV SI,offset FILE_HANDLE
    MOV AH, 3Ch
	MOV CX, 0
	MOV DX, offset FILENAME
	INT 21h         
    
    RET
    
CREATE_FILE ENDP

OPEN_FILE PROC
    
    MOV SI,offset FILE_HANDLE
    MOV AL, 2   ;Read/Write Mode
	MOV DX, offset FILENAME
	MOV AH, 3Dh  ;Open File
	INT 21h
    
    RET
    
OPEN_FILE ENDP

COUNT_FILE_LEN PROC
    
    MOV BX,offset FILE_RESTORE
    MOV BP,0
    
    FILE_LEN_L:
    MOV AL,[BX]
    INC BX
    INC BP
    CMP AL,1Ah
    JNZ FILE_LEN_L

    RET

COUNT_FILE_LEN ENDP


RESTORE_FILE PROC
    
    MOV BX,offset FILE_RESTORE
    MOV SI,BX

    MOV BP,0
  RESTORE_L:  
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    CMP  AX,0           ;were 0 bytes read?
    JZ   EOFF2           ;yes, end of file found

    MOV  DL,FILE_BUFFER       ;no, load file characters

    MOV [SI],DL 
    INC SI
    INC BP
    
    JMP  RESTORE_L       ;and repeat

EOFF2:
    
    MOV BX,offset FILE_LEN
    MOV [BX],BP

    MOV [SI],1Ah
    INC SI
    MOV [SI],0

    RET


RESTORE_FILE ENDP


READ_FILE2 PROC
        
    MOV DH,2    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET
    
    MOV BX,offset NEWLINE_POINTERS
    MOV DI,BX
    
    MOV BP,0
    MOV BX,offset FILE_RESTORE
    MOV SI,BX

    MOV BX,offset NEXTLINE_TEMP
    MOV DX,[BX]
    MOV BP,DX
    ADD SI,DX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BX,offset NEXTLINE_PAGES
    ADD BX,AX
    MOV AX,BP    
    MOV [BX],AX

    MOV BP,0 
L_READ_FILE2:
    MOV DL,[SI]
    INC SI
    CMP  DL,1AH         ;is it Control-Z <EOF>?
    JZ   EOFF23           ;jump if yes
    
    CMP DL,0Dh
    JZ L_READ_FILE2
    CMP DL,0Ah
    JZ NEW_LINE_EDITOR23
    CMP BP,78
    JZ NEW_LINE_EDITOR3
    
    JMP PASS_CONT
    CONTINUE_WRITE2:
    DEC SI
    MOV DL,[SI]
    INC SI
    
    PASS_CONT:
    
    CALL WRITE_FILE_TO_EDITOR
    INC BP
    JMP  L_READ_FILE2       ;and repeat

NEW_LINE_EDITOR3:
    
    MOV AH,03h
    MOV BH,0
    INT 10h
    
    CMP DH,26
    JZ EOFF_ERR2
    
    INC DH    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET   
    MOV BP,0

    JMP CONTINUE_WRITE2
    
NEW_LINE_EDITOR23:
    
    MOV AH,03h
    MOV BH,0
    INT 10h
    
    MOV [DI],DX
    INC DI
    INC DI
    
    CMP DH,26
    JZ EOFF_ERR2
    
    INC DH    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET   
    MOV BP,0

    JMP L_READ_FILE2      

EOFF_ERR2:
    MOV BX,offset LAST_FILE_POINTER 
    MOV [BX],SI
    
    CALL OVERFLOW_EDITOR
    MOV BX,offset EOF_FLAG
    MOV [BX],0
    JMP FIN_READ2

EOFF23:
    MOV BX,offset LAST_FILE_POINTER 
    MOV [BX],SI
    
    MOV BX,offset EOF_FLAG
    MOV [BX],1

FIN_READ2:
    MOV [DI],0FFFFh 
    CALL CLEAR_UF
    MOV BX,OFFSET TEMP_PAGE
    MOV DX,[BX] ;CX:DX, EXAMPLE, TO JUMP TO POSITION
    CMP DX,0
    JZ PASS_LEA2    
    CALL UNDERFLOW_EDITOR
    
PASS_LEA2:


    CALL NEWLINE_COUNTER
    
    RET
    
READ_FILE2 ENDP 

READ_FILE PROC
        
    MOV DH,2    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET
    
    MOV BX,offset NEWLINE_POINTERS
    MOV DI,BX
    
    MOV BP,0
    MOV BX,offset FILE_RESTORE
    MOV SI,BX

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    MOV BX,offset NEXTLINE_PAGES
    ADD BX,AX
    MOV AX,BP    
    MOV [BX],AX

    MOV BP,0 
L_READ_FILE:
    MOV DL,[SI]
    INC SI
    CMP  DL,1AH         ;is it Control-Z <EOF>?
    JZ   EOFF23           ;jump if yes
    
    CMP DL,0Dh
    JZ L_READ_FILE
    CMP DL,0Ah
    JZ NEW_LINE_EDITOR2
    CMP BP,78
    JZ NEW_LINE_EDITOR
    
    JMP PASS_CONT2
    CONTINUE_WRITE:
    DEC SI
    MOV DL,[SI]
    INC SI
    
    PASS_CONT2:
    
    CALL WRITE_FILE_TO_EDITOR2
    INC BP
    JMP  L_READ_FILE       ;and repeat

NEW_LINE_EDITOR:
    
    MOV AH,03h
    MOV BH,0
    INT 10h
    
    CMP DH,26
    JZ EOFF_ERR
    
    INC DH    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET   
    MOV BP,0

    JMP CONTINUE_WRITE
    
NEW_LINE_EDITOR2:
    
    MOV AH,03h
    MOV BH,0
    INT 10h
    
    MOV [DI],DX
    INC DI
    INC DI
    
    CMP DH,26
    JZ EOFF_ERR
    
    INC DH    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET   
    MOV BP,0

    JMP L_READ_FILE      

EOFF_ERR:
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    JMP FIN_READ

EOFF:
    XXXX
    XXXX
    XXXX
    XXXX

FIN_READ:
    XXXX
    XXXX
    XXXX
    XXXX
    CMP DX,0
    JZ PASS_LEA    
    CALL UNDERFLOW_EDITOR
    
PASS_LEA:

    CALL NEWLINE_COUNTER

    RET
    
READ_FILE ENDP

WRITE_FILE PROC

    ;CHANGE CURSOR IN FILE
    MOV AH, 42h          ;SERVICE FOR SEEK.
    MOV AL, 0            ;START FROM THE BEGINNING OF FILE.
    MOV BX, FILE_HANDLE  ;FILE.
    MOV CX, 0            ;THE FILE POSITION MUST BE PLACED IN
    MOV DX, 0          ;CX:DX,
    INT 21h              ;14000000 SET CX:DX = D5:9F80.

    ;CALL COUNT_FILE_LEN

    MOV BX,offset FILE_LEN
    MOV CX,[BX]

    ;WRITE STRING.
    MOV AH, 40h
    MOV BX, FILE_HANDLE
    MOV DX, offset FILE_RESTORE
    INT 21h


    RET
    
WRITE_FILE ENDP

CLOSE_FILE PROC
    
    ;CLOSE FILE (OR DATA WILL BE LOST).
    MOV  ah, 3eh
    MOV  bx, FILE_HANDLE
    INT  21h

    RET
    
CLOSE_FILE ENDP

EXTEND_MEM PROC

    MOV AX,@DATA
    MOV ES,AX

    MOV BX,offset FILE_POINTER
    MOV DX,[BX]

    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]

    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    INC CX
    MOV [BX],CX

    MOV AX,0A000h
    MOV ES,AX

    RET
    
EXTEND_MEM ENDP

EXTEND_MEM_NL PROC

    MOV AX,@DATA
    MOV ES,AX

    MOV BX,offset FILE_POINTER
    MOV DX,[BX]

    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]

    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    INC CX
    INC CX
    MOV [BX],CX

    MOV AX,0A000h
    MOV ES,AX

    RET
    
EXTEND_MEM_NL ENDP

REDUCE_MEM PROC
    
    MOV AX,@DATA
    MOV ES,AX

    MOV BX,offset FILE_POINTER
    MOV DX,[BX]

    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]

    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    DEC CX
    MOV [BX],CX

    MOV AX,0A000h
    MOV ES,AX
    
    
    RET
    
REDUCE_MEM ENDP

REDUCE_MEM_NL PROC
    
    MOV AX,@DATA
    MOV ES,AX

    MOV BX,offset FILE_POINTER
    MOV DX,[BX]


    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_POINTER
    MOV DX,[BX]
  
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    SUB CX,DX ; LOOP NUMBER
    INC CX
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    DEC CX
    DEC CX
    MOV [BX],CX

    MOV AX,0A000h
    MOV ES,AX
    
    
    RET
    
REDUCE_MEM_NL ENDP


;----------------------------------------------------------------------------
;-----------------------------FILE OPERATIONS--------------------------------
;----------------------------------------------------------------------------

FIND_ALGORITHM PROC
    
    MOV BX,offset FOUND_NUM
    MOV [BX],0
    
    CALL TEMP_STORE
    CALL TEMP_LOWER_CASE

    MOV BX,offset FILE_LEN
    MOV BP,[BX]
    MOV BX,DS
    MOV ES,BX
    
    
    MOV BX,offset FIND_WORD_LEN
    MOV CX,[BX]
    LEA SI, FIND_WORD
    LEA DI, FILE_DUMMY   
    SEARCH_L:

    CLD; Clear the direction flag
    
    XXXX
    XXXX
    XXXX
    XXXX
    
    LEA SI, FIND_WORD
    
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    
    MOV BX,offset FOUND_NUM
    MOV DX,[BX] 
    INC DX
    MOV [BX],DX
    
    CMP BP,0
    JNZ SEARCH_L
    
    
    MOV BX,0A000h
    MOV ES,BX
    
    JMP EXIT
    
    MISMATCH:
    MOV DX,CX
    
    MOV BX,offset FIND_WORD_LEN
    MOV CX,[BX] 
    
    LEA SI, FIND_WORD
    
    
    
    DEC BP
    JNZ SEARCH_L
    
    MOV BX,0A000h
    MOV ES,BX
    
    RET

FIND_ALGORITHM ENDP 

REPLACE_ALGORITHM PROC
    
    MOV AX,DS
    MOV ES,AX
       
    MOV BX,offset FOUND_NUM
    MOV BP,[BX]
  
    MOV BX,offset REPLACE_WORD_LEN
    MOV CX,[BX]
    MOV AX,CX
    
    MOV BX,offset FOUND_INDEX
    
    MOV DX,BP
    SHL DX,1
    ADD BX,DX
    DEC BX
    DEC BX
    
    REP_LOOP:
    
    MOV DI,[BX]
    SUB DI,5000
    
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH BP
    PUSH DI
    
    CALL MEM_ADJUST_REPLACE
   
    POP DI
    POP BP
    POP DX
    POP CX
    POP BX
    POP AX
    
    MOV DI,[BX]
    SUB DI,5000
    
    XXXX
    XXXX
    XXXX
    XXXX
       
    DEC BX
    DEC BX
    
    DEC BP
    JNZ REP_LOOP
    
    FIN_REP_LOOP:
    
    MOV AX,0A000h
    MOV ES,AX
        
    RET
    
REPLACE_ALGORITHM ENDP

CAPITALIZE_SENTENCES PROC
  
    MOV BX, offset FILE_LEN
    
    MOV CX,[BX]
    MOV DX,CX
    
    MOV BX,offset FILE_RESTORE
    
    L_CAP_SENT:  
    MOV AL,[BX]

    CMP AL,0Ah  ;NEW LINE
    JZ SPACE_COUNT_SENT
    
    CMP AL,02Eh   ;DOT
    JZ SPACE_COUNT_SENT
       
    CMP CX,DX
    JZ FIRST_CHAR_SENT
    
    INC BX
       
    CMP AL,1Ah
    JZ FIN_CS_LOOP 
    
    CONT_CAP_SENT_LOOP:
    
    

    LOOP L_CAP_SENT 
    
FIN_CS_LOOP:

    MOV DI,2400
     
    CALL BACKGROUND_GRAY_EDITOR
    
    CALL STAY_CURRENT_PAGE
    
    MOV BX,offset CAP_SENT_FLAG
    MOV DX,1
    MOV [BX],DX
    
    RET
    
    
    
    FIRST_CHAR_SENT:
    
    CALL CHAR_CHECK
    CMP BP,2
    JNZ PASS_FIRST_CHAR_SENT
    
    XOR AL,20h
    MOV [BX],AL 
    
    PASS_FIRST_CHAR_SENT:

    INC BX
    
    JMP CONT_CAP_SENT_LOOP
    
    
    SPACE_COUNT_SENT:

    
    FIND_REAL_CHAR_L:
    INC BX
    MOV AL,[BX]
    
    CMP AL,01Ah
    JZ FIN_CS_LOOP
       
    CALL CHAR_CHECK    
    CMP BP,0
    
    JZ FIND_REAL_CHAR_L
    
    CALL CHAR_CHECK    
    CMP BP,2
    JNZ PASS_SPACE_CHAR_SENT
    XOR AL,20h
    MOV [BX],AL 
    
    PASS_SPACE_CHAR_SENT:
    
    JMP CONT_CAP_SENT_LOOP
  
    RET

CAPITALIZE_SENTENCES ENDP

CAPITALIZE_WORDS PROC
    
    MOV BX, offset FILE_LEN
    
    MOV CX,[BX]
    MOV DX,CX
    
    MOV BX,offset FILE_RESTORE
    
    L_CAP_WORD:  
    MOV AL,[BX]
    
    CMP AL,20h  ; SPACE
    JZ SPACE_COUNT
    
    CMP AL,0Ah  ;NEW LINE
    JZ SPACE_COUNT
    
    CMP AL,02Eh   ;DOT
    JZ SPACE_COUNT
    
    CMP AL,02Ch  ; COMMA
    JZ SPACE_COUNT
    
    CMP CX,DX
    JZ FIRST_CHAR
    
    CMP AL,1Ah
    JZ FIN_CW_LOOP
    
    INC BX
         
    CONT_CAP_LOOP:

    LOOP L_CAP_WORD 
    
FIN_CW_LOOP:

    MOV DI,2400
     
    CALL BACKGROUND_GRAY_EDITOR

    CALL STAY_CURRENT_PAGE
    
    MOV BX,offset CAP_WORDS_FLAG
    MOV DX,1
    MOV [BX],DX
    
    RET
   
    FIRST_CHAR:
    
    CALL CHAR_CHECK
    CMP BP,2
    JNZ PASS_FIRST_CHAR
    
    XOR AL,20h
    MOV [BX],AL 
    
    PASS_FIRST_CHAR:

    INC BX
    
    JMP CONT_CAP_LOOP
    
    
    SPACE_COUNT:
    INC BX
    MOV AL,[BX]
    CALL CHAR_CHECK
    CMP BP,2
    JNZ PASS_SPACE_CHAR
    
    XOR AL,20h
    MOV [BX],AL 
    
    PASS_SPACE_CHAR:
    
    JMP CONT_CAP_LOOP

    RET
    
CAPITALIZE_WORDS ENDP

CHAR_CHECK PROC
    
    CMP AL,41h
    JB NOT_LETTER
    
    CMP AL,07Ah
    JA NOT_LETTER
    
    ;NOW WE HAVE A LETTER
    
    CMP AL,05Ah
    JBE UPPER_CASE
    
    CMP AL,61h
    JAE LOWER_CASE
    
    
    NOT_LETTER:
    MOV BP,0  ; ITs NOT LETTER PASS IT   
    RET 
    
    
    UPPER_CASE:
    MOV BP,1 ; Its a letter and upper case
    RET
    
    LOWER_CASE:
    MOV BP,2 ; Its a letter and lower case
    
    RET
 
CHAR_CHECK ENDP

EDITOR_MENU PROC
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
    MOV SI,DI
 
    MENU_BUTTON_LOOP: 
        
    MOV DI,8340+40 ;5120
    
    MOV SI,5
    LB_MENU_ALL:    

    MOV BX,0000h

    MOV DX,0000000000011b
    MOV DS,DX
    
    
    MOV BP,30
    LB_MENU_EDITOR:
   
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    DEC DI
    DEC DI

    NOT BX

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    NOT BX
    
    DEC DI
    DEC DI

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    STC
    RCL BX,1

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,18

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,20
    ADD DI,80

    DEC BP
    JNZ LB_MENU_EDITOR
    
    ADD DI,2720 
     
    DEC SI
    JNZ LB_MENU_ALL
    
    MOV AX,@DATA
    MOV DS,AX 
    
    CALL STAY_CURRENT_PAGE
    
    STC
    CALL BUTTON_TEXT    
    
    
    MOV DX,104
    MOV CX,495 ;494
    MOV BP,5
    MOV SI,CX
    MOV DI,DX
    CURVE_L:
    

    CALL EDITOR_MENU_WHITE_CURVE
    DEC BP
    JNZ CURVE_L
    
    
    MOV DX,104
    MOV CX,501 ;494
    MOV BP,5
    MOV SI,CX
    MOV DI,DX
    CURVE_L2:
    

    CALL EDITOR_MENU_WHITE_CURVE
    DEC BP
    JNZ CURVE_L2
    
    CALL EDITOR_MENU_SELECTED_POPUP
    
    CALL EDITOR_MENU_SELECTED_TEXT

    MOV AH,00
    INT 16h
    
    CMP AX,011Bh
    JZ RESUME_EDITOR 
    
    CMP AX,3B00h
    JZ RESUME_EDITOR
    
    CMP AX,5000h
    JNZ PASS_DOWNL
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    
    CMP AX,4
    JNZ INC_MENU
    
    MOV AX,0FFFFh
    
    INC_MENU:
    
    INC AX
    MOV [BX],AX
    
    PASS_DOWNL:
    
    CMP AX,4800h ; UP ARROW
    JNZ PASS_UPL
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    CMP AX,0
    JNZ DEC_MENU
    
    MOV AX,5
    
    
    DEC_MENU:
        
    DEC AX
    MOV [BX],AX
    
    PASS_UPL:

    CMP AX,1C0Dh
    JNZ PASS_ENTER
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    
    
    CMP AX,0
    JZ LOAD_MENU
    
    CMP AX,1
    JZ NEW_MENU
    
    CMP AX,2
    JZ SAVE_MENU
    
    CMP AX,3
    JZ RESUME_EDITOR
    
    MOV BX,offset DISABLED_EDITOR
    MOV [BX],1
    CMP AX,4
    JZ EXIT_MENU
    
    EXIT_MENU:
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
   
        MOV BX,offset DISABLED_EDITOR
    MOV [BX],0
    CALL READ_FILE2
    
    JMP EXIT
    
    LOAD_MENU:

    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
   
    MOV BX,offset DISABLED_EDITOR
    MOV [BX],0
    CALL READ_FILE2 
    
    CALL WANNA_SAVE_BEFORE_LOAD
    
    CALL STAY_CURRENT_PAGE
    JMP RESUME_EDITOR
    
    
    NEW_MENU:
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
   
    MOV BX,offset DISABLED_EDITOR
    MOV [BX],0
    CALL READ_FILE2
    
    CALL WANNA_SAVE_BEFORE_NEW
    
    CALL STAY_CURRENT_PAGE
    JMP RESUME_EDITOR
    
    
    
    SAVE_MENU:
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
   
    MOV BX,offset DISABLED_EDITOR
    MOV [BX],0
    CALL READ_FILE2
    
    CALL WANNA_SAVE_BEFORE_SAVE
    
    CALL STAY_CURRENT_PAGE
    JMP RESUME_EDITOR
    
    
    PASS_ENTER:
       

    JMP MENU_BUTTON_LOOP 
    
    RESUME_EDITOR:

    RET
    
EDITOR_MENU ENDP

EDITOR_MENU_WHITE_CURVE PROC

    MOV BX,16
    L1_MEN:
    MOV AH,0Ch
    MOV AL,0Fh
    INT 10h

    DEC CX


    INC DX
    DEC BX
    JNZ L1_MEN
    
    MOV CX,SI
    MOV DX,DI
    DEC CX

    MOV BX,16
    L2_MEN:
    MOV AH,0Ch
    MOV AL,0Fh
    INT 10h

    DEC CX


    INC DX
    DEC BX
    JNZ L2_MEN
    
    MOV CX,SI
    MOV DX,DI
    DEC CX
    DEC CX

    MOV BX,16
    L3_MEN:
    MOV AH,0Ch
    MOV AL,0Fh
    INT 10h

    DEC CX


    INC DX
    DEC BX
    JNZ L3_MEN

    MOV CX,SI
    MOV DX,DI
    ADD DX,16
    SUB CX,16
    
    
    MOV BX,14
    L4_MEN:
    MOV AH,0Ch
    MOV AL,0Fh
    INT 10h
    INC DX
    DEC BX
    JNZ L4_MEN
    

    MOV CX,SI
    MOV DX,DI
    ADD DX,16
    SUB CX,16
    DEC CX
    
    
    MOV BX,14
    L5_MEN:
    MOV AH,0Ch
    MOV AL,0Fh
    INT 10h
    INC DX
    DEC BX
    JNZ L5_MEN 
    
    MOV CX,SI
    MOV DX,DI
    ADD DX,16
    SUB CX,16
    DEC CX
    DEC CX
    
    MOV BX,14
    L6_MEN:
    MOV AH,0Ch
    MOV AL,0Fh
    INT 10h
    INC DX
    DEC BX
    JNZ L6_MEN
    
    
    MOV CX,SI
    ADD DI,64
    MOV DX,DI
    
    RET
    
    
EDITOR_MENU_WHITE_CURVE ENDP

EDITOR_MENU_SELECTED PROC
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    ;INC AX
    
    MOV DX,2720+2400
    MUL DX
    
    MOV DI,8340+40 ;5120
    ADD DI,AX

    MOV BX,0000h
    
    
    MOV DX,0000000000011b
    MOV DS,DX
    
    
    MOV BP,30
    LB_MENU_EDITOR_WHITE:
    

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    DEC DI
    DEC DI



    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    STC
    RCL BX,1

    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,18

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,20
    ADD DI,80

    DEC BP
    JNZ LB_MENU_EDITOR_WHITE


    
    MOV AX,@DATA
    MOV DS,AX 
    
    CALL STAY_CURRENT_PAGE
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    CALL EDITOR_MENU_RED_CURVE
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    MOV DX,64
    MUL DX

    MOV DX,104
    ADD DX,AX
    MOV CX,501 ;494

   
    MOV SI,CX
    MOV DI,DX
    
    CALL EDITOR_MENU_RED_CURVE
    
    RET
    
EDITOR_MENU_SELECTED ENDP

EDITOR_MENU_SELECTED_POPUP PROC
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    ;INC AX
    
    MOV DX,2720+2400
    MUL DX
    
    MOV DI,8340+40 ;5120
    ADD DI,AX

    MOV BX,0000h
    
    
    MOV DX,0000000000011b
    MOV DS,DX
    
    
    MOV BP,30
    LB_MENU_EDITOR_WHITE2:
    

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    DEC DI
    DEC DI
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
                        
    STC
    RCL BX,1

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,18

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    SUB DI,20
    ADD DI,80

    DEC BP
    JNZ LB_MENU_EDITOR_WHITE2
   
    MOV AX,@DATA
    MOV DS,AX 
    
    CALL STAY_CURRENT_PAGE
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    CALL EDITOR_MENU_RED_CURVE
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV AX,[BX]
    MOV DX,64
    MUL DX

    MOV DX,104
    ADD DX,AX
    MOV CX,501 ;494

   
    MOV SI,CX
    MOV DI,DX
    
    CALL EDITOR_MENU_RED_CURVE
    
    RET
    
EDITOR_MENU_SELECTED_POPUP ENDP

EDITOR_MENU_RED_CURVE PROC
        
    MOV BX,16
    L1_MEN_R:
    MOV AH,0Ch
    MOV AL,04h
    INT 10h

    DEC CX

    INC DX
    DEC BX
    JNZ L1_MEN_R
    
    MOV CX,SI
    MOV DX,DI
    DEC CX    
    
    MOV BX,16
    L2_MEN_R:
    MOV AH,0Ch
    MOV AL,04h
    INT 10h

    DEC CX

    INC DX
    DEC BX
    JNZ L2_MEN_R
    
    MOV CX,SI
    MOV DX,DI
    DEC CX
    DEC CX   
    
    MOV BX,16
    L3_MEN_R:
    MOV AH,0Ch
    MOV AL,04h
    INT 10h

    DEC CX

    INC DX
    DEC BX
    JNZ L3_MEN_R

    MOV CX,SI
    MOV DX,DI
    ADD DX,16
    SUB CX,16
    
    
    MOV BX,14
    L4_MEN_R:
    MOV AH,0Ch
    MOV AL,04h
    INT 10h
    INC DX
    DEC BX
    JNZ L4_MEN_R
    
    MOV CX,SI
    MOV DX,DI
    ADD DX,16
    SUB CX,16
    DEC CX
    
    MOV BX,14
    L5_MEN_R:
    MOV AH,0Ch
    MOV AL,04h
    INT 10h
    INC DX
    DEC BX
    JNZ L5_MEN_R 
    
    MOV CX,SI
    MOV DX,DI
    ADD DX,16
    SUB CX,16
    DEC CX
    DEC CX
    
    MOV BX,14
    L6_MEN_R:
    MOV AH,0Ch
    MOV AL,04h
    INT 10h
    INC DX
    DEC BX
    JNZ L6_MEN_R
    
    MOV CX,SI
    ADD DI,64
    MOV DX,DI
    
    RET
        
EDITOR_MENU_RED_CURVE ENDP 

EDITOR_BACKGROUND_TRANS PROC
   
    MOV DI,2400
    
    MOV dx,03C4h ; dx = indexregister
    MOV ax,0802h ; INDEX = MASK MAP,[COLOR][X]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,16640 ; Counter for Gray
    MOV ax,0FFFFh ; write to every pixel.
    REP STOSW ; fill the screen
    
    RET
    
EDITOR_BACKGROUND_TRANS ENDP

EDITOR_MENU_SELECTED_TEXT PROC
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV DI,[BX]   
    
    MOV DH,7 ; row to put string
    MOV dl,66         ; column to put string
    
    CMP DI,0
    JNZ PASS_B1
    
    MOV BX,OFFSET BUTTON1 ;LOAD BUTTON
    CALL PRINT_BUTTON_TEXT_MENU_RED
    
    JMP END_R_B  
    
    PASS_B1:

    MOV BX,OFFSET BUTTON2 ;NEW FILE BUTTON
    add dh,4         ; row to put string
    
    CMP DI,1
    JNZ PASS_B2
    
    CALL PRINT_BUTTON_TEXT_MENU_RED
    
    JMP END_R_B  
    
    PASS_B2:

    MOV BX,OFFSET BUTTON3 ;SAVE FILE BUTTON
    add dh,4         ; row to put string
    
    CMP DI,2
    JNZ PASS_B3
    
    CALL PRINT_BUTTON_TEXT_MENU_RED
    
    JMP END_R_B
    
    PASS_B3:
    
    MOV BX,OFFSET BUTTON4 ;RESUME BUTTON
    add dh,4         ; row to put string
    add dl,1         ; column to put string
    
    CMP DI,3
    JNZ PASS_B4
    
    CALL PRINT_BUTTON_TEXT_MENU_RED
    
    JMP END_R_B
    
    PASS_B4:
    
    MOV BX,OFFSET BUTTON5 ;EXIT BUTTON
    add dh,4         ; row to put string
    add dl,1         ; column to put string 
    
    CMP DI,4
    JNZ END_R_B
    
    CALL PRINT_BUTTON_TEXT_MENU_RED
    
    
    END_R_B:
    
    RET
    
EDITOR_MENU_SELECTED_TEXT ENDP 

PRINT_BUTTON_TEXT_MENU_RED PROC
    
    MOV SI,BX
    
    CALL CURSOR_SET
    
    L_TEXT_M_R:

    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_TEXT_M_R
    
    RET
    
PRINT_BUTTON_TEXT_MENU_RED ENDP

WANNA_QUIT PROC
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV [BX],0 
    
    MOV BX,offset DISABLED_EDITOR
    MOV DX,[BX]
    CMP DX,0
    JNZ START_WANNA
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
    START_WANNA:
    
    CALL CLEAR_POPUP_MSG    
    CALL DRAW_POPUP_MSG
    CALL DRAW_POPUP_BUTTON_MSG2
    
    
    MOV DH,12    ;row
    MOV DL,23   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET WANNA_QUIT_MSG
    MOV SI,BX ;EXIT BUTTON
    
L_PIR_FILE_SAVED: 
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_FILE_SAVED 
    
    INPUT_WANNA:
    
    MOV AH,00
    INT 16h
    
    
    CMP AX,4D00h
    JZ RIGHT_SELECT
    
    CMP AX,4B00h
    JZ LEFT_SELECT
    
    CMP AX,1C0Dh
    JZ FIN_SELECT_SAVE
    
    CMP AX,011Bh
    JNZ PASS_ESC
    
    CALL STAY_CURRENT_PAGE
    
    PUSH AX 
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    JMP START_EDITOR
    
    PASS_ESC: 
    
    
    JMP INPUT_WANNA
    
    LEFT_SELECT:
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,0
    JZ RIGHT_SELECT
    MOV [BX],0
    
    JMP START_WANNA    
    
    RIGHT_SELECT:
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    JMP START_WANNA
    
    FIN_SELECT_SAVE:
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,1
    JZ EXIT_CHECK
    
    CALL WRITE_FILE
    JMP EXIT_CHECK
  
    RET

WANNA_QUIT ENDP

FILE_SAVED PROC
    CALL CLEAR_POPUP_MSG
    CALL DRAW_POPUP_MSG
    CALL DRAW_POPUP_BUTTON_MSG
    
    MOV DH,12    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET FILE_SAVED_MSG
    MOV SI,BX ;EXIT BUTTON
    
L_PIR_WANNA_SAVED:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_WANNA_SAVED 
    
    MOV AH,00
    INT 16h
    
    CALL STAY_CURRENT_PAGE
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    
    RET
FILE_SAVED ENDP

DRAW_POPUP_MSG PROC


    MOV SI,DI
    MOV DI,8340+2400+2400+1

    MOV BX,130
    LB2_MSG:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0702h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,38 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,38

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,38 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,38
    ADD DI,80

    DEC BX
    JNZ LB2_MSG


    MOV DI,SI

    RET

DRAW_POPUP_MSG ENDP 

CLEAR_POPUP_MSG PROC

    MOV SI,DI
    MOV DI,8340+2400+2400+1

    MOV BX,130
    LB2_MSG_CLR:


    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,38 ; Counter for Gray
    MOV ax,00h ; write to every pixel.
    REP STOSB ; fill the screen

    SUB DI,38
    ADD DI,80

    DEC BX
    JNZ LB2_MSG_CLR


    MOV DI,SI

    RET

CLEAR_POPUP_MSG ENDP


DRAW_POPUP_BUTTON_MSG PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+5120+15+1440+5120-160



    MOV BX,30
    L_OK_BUT2:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT2



    

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,16    ;row
    MOV DL,39   ;column
    CALL CURSOR_SET

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

 

    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

 DRAW_POPUP_BUTTON_MSG ENDP

DRAW_POPUP_BUTTON_MSG2 PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+5120+3+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,0
    JNZ DRAW_NOT_SELECTED
    


    
    MOV BX,30
    L_OK_BUT3_SEL:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,11 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    

    
    SUB DI,11
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL
    

    
    
    JMP BTN2_WANNA
    
    DRAW_NOT_SELECTED:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,11 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    ADD DI,80
    SUB DI,11
    
    MOV BX,28
    L_OK_BUT3:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,080h ; write to every pixel.
    REP STOSB ; fill the screen
    
    SUB DI,1 
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    
    ADD DI,9
    

    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,01h ; write to every pixel.
    REP STOSB ; fill the screen 
        
    SUB DI,1
    
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    DEC BX
    JNZ L_OK_BUT3
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    
    
    BTN2_WANNA:
    
    MOV DI,8340+5120+27+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,1
    JNZ DRAW_NOT_SELECTED2
    
    MOV BX,30
    L_OK_BUT4_SEL:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    

    
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT4_SEL 
    
    
    JMP FIN_BUT_DRAW
    
    DRAW_NOT_SELECTED2:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    ADD DI,80
    SUB DI,10
    
    MOV BX,28
    L_QUIT_BUT3:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,080h ; write to every pixel.
    REP STOSB ; fill the screen
    
    SUB DI,1 
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    
    ADD DI,8
    

    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,01h ; write to every pixel.
    REP STOSB ; fill the screen 
        
    SUB DI,1
    
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    

    
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_QUIT_BUT3
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen


    FIN_BUT_DRAW:
    

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,16    ;row
    MOV DL,24   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET SAVE_QUIT_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT2
    
    
    
    MOV DH,16    ;row
    MOV DL,50   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET QUIT_MSG
    MOV SI,BX ;EXIT BUTTON

    L_EXIT_TEXT2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_EXIT_TEXT2

 

    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

 DRAW_POPUP_BUTTON_MSG2 ENDP
 
DRAW_POPUP_BUTTON_MSG2_LOAD PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+5120+3+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,0
    JNZ DRAW_NOT_SELECTED_LOAD
    


    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    
    SUB DI,11
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL2
    

    
    
    JMP BTN2_WANNA_LOAD
    
    DRAW_NOT_SELECTED_LOAD:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,11 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    ADD DI,80
    SUB DI,11
    
    MOV BX,28
    L_OK_BUT32:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0402h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    

    
    SUB DI,11
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT32
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,11 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen 
    
    
    
    BTN2_WANNA_LOAD:
    
    MOV DI,8340+5120+27+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,1
    JNZ DRAW_NOT_SELECTED2_LOAD
    
    MOV BX,30
    L_OK_BUT4_SEL2:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    

    
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT4_SEL2 
    
    
    JMP FIN_BUT_DRAW_LOAD
    
    DRAW_NOT_SELECTED2_LOAD:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    ADD DI,80
    SUB DI,10
    
    MOV BX,28
    L_QUIT_BUT3_LOAD:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    

    
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_QUIT_BUT3_LOAD
    
    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen


    FIN_BUT_DRAW_LOAD:
    

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,16    ;row
    MOV DL,24   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET SAVE_LOAD_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT22:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT22
    
    
    
    MOV DH,16    ;row
    MOV DL,50   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET LOAD_MEN_MSG
    MOV SI,BX ;EXIT BUTTON

    L_EXIT_TEXT22:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_EXIT_TEXT22

 

    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

 DRAW_POPUP_BUTTON_MSG2_LOAD ENDP 
 
 WANNA_SAVE_BEFORE_LOAD PROC
    
         
    MOV BX,offset WANNA_QUIT_BUT
    MOV [BX],0    

    
    MOV BX,offset DISABLED_EDITOR
    MOV DX,[BX]
    CMP DX,0
    JNZ START_WANNA_BEFORE
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
    START_WANNA_BEFORE:  
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV DX,[BX]
    CMP DX,0
    JNZ LOAD_MENU_PROC_PASS
    
    CALL LOAD_MENU_PROC
    
    RET
    
    LOAD_MENU_PROC_PASS: 
    
    

    
    CALL CLEAR_POPUP_MSG    
    CALL DRAW_POPUP_MSG
    CALL DRAW_POPUP_BUTTON_MSG2_LOAD
    
    
    MOV DH,12    ;row
    MOV DL,23   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET WANNA_LOAD_MSG
    MOV SI,BX ;EXIT BUTTON
    
L_PIR_FILE_SAVED2:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_FILE_SAVED2
    
    MOV DH,13    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET FILENAME
    MOV SI,BX ;EXIT BUTTON

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    

    
    INPUT_WANNA_BEFORE:
    
    MOV AH,00
    INT 16h
    
    
    CMP AX,4D00h
    JZ RIGHT_SELECT2
    
    CMP AX,4B00h
    JZ LEFT_SELECT2
    
    CMP AX,1C0Dh
    JZ FIN_SELECT_SAVE2
    
    CMP AX,011Bh
    JNZ PASS_ESC2
    
    CALL STAY_CURRENT_PAGE
    
    POP AX 
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    JMP START_EDITOR
    
    PASS_ESC2: 
    
    
    JMP INPUT_WANNA_BEFORE
    
    LEFT_SELECT2:
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,0
    JZ RIGHT_SELECT2
    MOV [BX],0
    
    JMP START_WANNA_BEFORE    
    
    RIGHT_SELECT2:
    
    
    MOV BX,offset WANNA_QUIT_BUT 
    MOV DX,[BX]
    CMP DX,1
    JZ LEFT_SELECT2
    MOV [BX],1
    
    JMP START_WANNA_BEFORE
    
    FIN_SELECT_SAVE2:
     
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,1
    JZ LOAD_MENU_PROC_PASS2

    
    
    
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],0
    CALL WRITE_FILE
    
    LOAD_MENU_PROC_PASS2:
   
    CALL LOAD_MENU_PROC
  
    RET

WANNA_SAVE_BEFORE_LOAD ENDP


LOAD_MENU_PROC PROC
    
    MOV BX,offset FILENAME
    MOV SI,BX
    MOV BX,offset FILENAME_OLD
    
    MOV CX,12
    STORE_L5:
    MOV DL,[SI] 
    MOV [BX],DL
    INC BX
    INC SI
    LOOP STORE_L5 

    
    CALL CLEAR_POPUP
    
    CALL DRAW_POPUP
    
    ;PRINTING POPUP MESSAGE FOR LOAD POPUP
    
    MOV DH,11    ;row
    MOV DL,23   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET LOAD_MSG
    MOV SI,BX ;EXIT BUTTON
    
    L_PIR_MEN:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_MEN 
    
        
CONTINUE_LOADFILE_MEN: 
    
    MOV DH,14    ;row
    MOV DL,41   ;column
    CALL CURSOR_SET 

    MOV BL,0F3h;White Foreground,Red Background
    MOV AL,'.'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT
    MOV AL,'x'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT         

    MOV DH,14    ;row
    MOV DL,33   ;column
    CALL CURSOR_SET  
    
    MOV BX,offset FILENAME
    MOV SI, BX
    MOV CX,0
    
L_LOAD_FILE_MEN: 
    MOV ah,00h
    INT 16h

    CMP AX,1C0Dh
    JZ LOAD_NEW_MEN
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JNZ GO_BACK2
    
    MOV BX,offset FILENAME_OLD
    MOV SI,BX
    MOV BX,offset FILENAME
    
    MOV CX,12
    STORE_L52:
    MOV DL,[SI] 
    MOV [BX],DL
    INC BX
    INC SI
    LOOP STORE_L52 
    
    RET

    GO_BACK2: 
    CMP AX,0E08h
    JZ BACKSPACE_LOAD_MEN
    CMP CX,8
    JZ L_LOAD_FILE_MEN
    
        
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    MOV [SI],0
    
    JMP L_LOAD_FILE_MEN 
    
    LOAD_NEW_MEN:
    
    CMP CX,0
    JZ NONAME_LOADFILE_MEN
    
    MOV [SI],'.'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],'x'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],0
    
    ;--CONTROL IF FILE IS EXIST--
    
    CALL OPEN_FILE
    
	JC FILE_NOT_EXIST2_MEN ;File not exist Error
	
	JMP FILE_EXIST2_MEN  ;FILE EXIST
    
    
    ;--LOADING FILE ERROR--
    FILE_NOT_EXIST2_MEN: ;IF FILE IS NOT EXIST ERROR MSG WILL SHOW UP
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,30   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET FILE_NEXIST_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
    
    JMP CONTINUE_LOADFILE_MEN
	
	
	;--LOADING FILE--
	
	
	
    FILE_EXIST2_MEN:
    
    MOV BP,AX
    
    CALL CLOSE_FILE
    
    MOV AX,BP
     
    MOV [SI], AX ; AX->File Handle
    

    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR 
    
    CALL EDITOR_CURSOR_CLEAR

    
    CALL CLEAR_CACHE
    
     
    
    CALL EDITOR_CURSOR_DRAW
    
    CALL CLEAR_SCREEN
    
    JMP EDITOR ; ITS DONE DIKKAT BURAYA
      
    
    NONAME_LOADFILE_MEN: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_LOADFILE_MEN
    
    
    RET
    
LOAD_MENU_PROC ENDP


DRAW_POPUP_BUTTON_MSG2_NEW PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+5120+3+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,0
    JNZ DRAW_NOT_SELECTED_NEW
    


    
    MOV BX,30
    L_OK_BUT3_SEL2_NEW:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    

    
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL2_NEW
    

    
    
    JMP BTN2_WANNA_NEW
    
    DRAW_NOT_SELECTED_NEW:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,10 ; Counter for Gray
    MOV ax,0FFh ; write to every pixel.
    REP STOSB ; fill the screen
    
    ADD DI,80
    SUB DI,10
    
    MOV BX,28
    L_OK_BUT32_NEW:

    MOV dx,03C4h ; dx = indexregister (try 03C6. its nicee)
    MOV ax,0F02h ; INDEX = MASK MAP,[COLOR][MEMORY MODE]
    OUT dx,ax ; write all the bitplanes.
    MOV cx,1 ; Counter for Gray
    MOV ax,080h ; write to every pixel.
    REP STOSB ; fill the screen
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    
    BTN2_WANNA_NEW:
    
    MOV DI,8340+5120+28+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,1
    JNZ DRAW_NOT_SELECTED2_NEW
    
    MOV BX,30
    L_OK_BUT4_SEL2_NEW:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    

    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX


    FIN_BUT_DRAW_NEW:

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,16    ;row
    MOV DL,24   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET SAVE_NEW_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT22_NEW:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
     INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT22_NEW
    
    
    
    MOV DH,16    ;row
    MOV DL,51   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET NEW_MEN_MSG
    MOV SI,BX ;EXIT BUTTON

    L_EXIT_TEXT22_NEW:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_EXIT_TEXT22_NEW

 

    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

DRAW_POPUP_BUTTON_MSG2_NEW ENDP 


WANNA_SAVE_BEFORE_NEW PROC
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV [BX],0
    
    MOV BX,offset DISABLED_EDITOR
    MOV DX,[BX]
    CMP DX,0
    JNZ START_WANNA_BEFORE_NEW
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
    START_WANNA_BEFORE_NEW: 
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV DX,[BX]
    CMP DX,0
    JZ NEW_MENU_PROC  
    
    

    
    CALL CLEAR_POPUP_MSG    
    CALL DRAW_POPUP_MSG
    CALL DRAW_POPUP_BUTTON_MSG2_NEW
    
    
    MOV DH,12    ;row
    MOV DL,26   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET WANNA_NEW_MSG
    MOV SI,BX ;EXIT BUTTON
    
L_PIR_FILE_SAVED2_NEW:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_FILE_SAVED2_NEW
    
    MOV DH,13    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET FILENAME
    MOV SI,BX ;EXIT BUTTON

    L_HEADER_TEXT2_MEN_NEW:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"."
    JNZ L_HEADER_TEXT2_MEN_NEW
    
    MOV CX,4
    L_HEADER_TEXT2_2MEN_NEW:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    LOOP L_HEADER_TEXT2_2MEN_NEW
    
     
    

    INPUT_WANNA_BEFORE_NEW:
    
    MOV AH,00
    INT 16h
    
    
    CMP AX,4D00h
    JZ RIGHT_SELECT2_NEW
    
    CMP AX,4B00h
    JZ LEFT_SELECT2_NEW
    
    CMP AX,1C0Dh
    JZ FIN_SELECT_SAVE2_NEW
    
    CMP AX,011Bh
    JNZ PASS_ESC2_NEW
    
    CALL STAY_CURRENT_PAGE
    
    POP AX 
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    JMP START_EDITOR
    
    PASS_ESC2_NEW: 
    
    
    JMP INPUT_WANNA_BEFORE_NEW
    
    LEFT_SELECT2_NEW:
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,0
    JZ RIGHT_SELECT2_NEW
    MOV [BX],0
    
    JMP START_WANNA_BEFORE_NEW    
    
    RIGHT_SELECT2_NEW:
    
    
    MOV BX,offset WANNA_QUIT_BUT 
    MOV DX,[BX]
    CMP DX,1
    JZ LEFT_SELECT2_NEW
    MOV [BX],1
    
    JMP START_WANNA_BEFORE_NEW
    
    FIN_SELECT_SAVE2_NEW:
     
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,1
    JZ J_NEW_MEN
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],0
    CALL WRITE_FILE
    
    J_NEW_MEN:
   
    CALL NEW_MENU_PROC
  
    RET

WANNA_SAVE_BEFORE_NEW ENDP



NEW_MENU_PROC PROC 
    
    MOV BX,offset FILENAME
    MOV SI,BX
    MOV BX,offset FILENAME_OLD
    
    MOV CX,12
    STORE_L51:
    MOV DL,[SI] 
    MOV [BX],DL
    INC BX
    INC SI
    LOOP STORE_L51 
    
    CALL CLEAR_POPUP
    CALL DRAW_POPUP
    
    ;PRINTING POPUP MESSAGE FOR NEWFILE POPUP
    
    MOV DH,11    ;row
    MOV DL,22   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET NEWFILE_MSG
    MOV SI,BX ;EXIT BUTTON
    

L_PIR2_MEN:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR2_MEN

CONTINUE_NEWFILE_MEN: 
    
    MOV DH,14    ;row
    MOV DL,41   ;column
    CALL CURSOR_SET

    MOV BL,0F3h;White Foreground,Red Background
    MOV AL,'.'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT
    MOV AL,'x'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT        
    

    MOV DH,14    ;row
    MOV DL,33   ;column
    CALL CURSOR_SET   


    MOV BX,offset FILENAME
    MOV SI, BX
    MOV CX,0
    

L_SAVE_FILE_MEN: 
    MOV ah,00h
    INT 16h

    CMP AX,1C0Dh
    JZ SAVE_NEW_MEN
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JZ END2_MEN  
    CMP AX,0E08h
    JZ BACKSPACE_MEN
    CMP CX,8
    JZ L_SAVE_FILE_MEN
    
        
    MOV [SI],AL
    INC SI
    INC CX
    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_SAVE_FILE_MEN
    
    BACKSPACE_MEN:
    
    CMP CX,0
    JZ L_SAVE_FILE_MEN
    
    DEC SI
    DEC CX
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
      
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_SAVE_FILE_MEN 
    
    SAVE_NEW_MEN:
    
    CMP CX,0
    JZ NONAME_NEWFILE_MEN
    
    MOV [SI],'.'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],'x'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],0
    
    ;--CONTROL IF FILE IS EXIST--
    
    CALL OPEN_FILE
    
	JC FILE_NOT_EXIST_MEN
	
	JMP FILE_EXIST_MEN  ;FILE EXIST ERROR
    
    
    ;--CREATING FILE--
    FILE_NOT_EXIST_MEN:
    
    CALL CLOSE_FILE
    
    CALL CREATE_FILE
	
	JC EXIT ;IF there is an ERRR
	
	MOV [SI], AX
	
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR 
    
    CALL EDITOR_CURSOR_CLEAR

    
    CALL CLEAR_CACHE
    
     
    
    CALL EDITOR_CURSOR_DRAW
    
    CALL CLEAR_SCREEN
    
    JMP EDITOR ; ITS DONE DIKKAT BURAYA
	
	
	FILE_EXIST_MEN:;IF FILE IS EXIST ERROR MSG WILL SHOW UP
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET FILE_EXIST_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
    
    JMP CONTINUE_NEWFILE_MEN
    
    NONAME_NEWFILE_MEN: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_NEWFILE_MEN
  
         
END2_MEN:
    
    MOV BX,offset FILENAME_OLD
    MOV SI,BX
    MOV BX,offset FILENAME
    
    MOV CX,12
    STORE_L522:
    MOV DL,[SI] 
    MOV [BX],DL
    INC BX
    INC SI
    LOOP STORE_L522
    RET
    
NEW_MENU_PROC ENDP 

DRAW_POPUP_BUTTON_MSG2_SAVE PROC

    ;--PRINTING BUTTON FRAME--
    ;--OK BUTTON--
    MOV DI,8340+5120+3+1440+5120-160
    
    MOV BX,offset WANNA_QUIT_BUT
    
    MOV DX,[BX]
    CMP DX,0
    JNZ DRAW_NOT_SELECTED_SAVE
    


    
    MOV BX,30
    L_OK_BUT3_SEL2_SAVE:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    

    
    SUB DI,11
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT3_SEL2_SAVE
    

    
    
    JMP BTN2_WANNA_SAVE
    
    DRAW_NOT_SELECTED_SAVE:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    ADD DI,80
    SUB DI,11
    
    MOV BX,28
    
    L_OK_BUT32_SAVE:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    
    ADD DI,9
    

    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    
    SUB DI,10
    ADD DI,80

    DEC BX
    JNZ L_OK_BUT4_SEL2_SAVE 
    
    
    JMP FIN_BUT_DRAW_SAVE
    
    DRAW_NOT_SELECTED2_SAVE:

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    

    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX


    FIN_BUT_DRAW_SAVE:
    

    ;------------------------
    ;--PRINTING BUTTON TEXT--

    ;--OK TEXT--
    MOV AX,@data ;ES -> DATA Segment
    MOV ES,AX

    MOV DH,16    ;row
    MOV DL,25   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET SAVE_AS_MSG
    MOV SI,BX ;EXIT BUTTON

    L_SAVE_TEXT22_SAVE:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_SAVE_TEXT22_SAVE
    
    
    
    MOV DH,16    ;row
    MOV DL,50   ;column
    CALL CURSOR_SET

    MOV BX,OFFSET SAVE_MEN_MSG
    MOV SI,BX ;EXIT BUTTON

    L_EXIT_TEXT22_SAVE:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_EXIT_TEXT22_SAVE

 

    ;Change ES to Video Memory
    MOV AX,0A000h
    MOV ES,AX

    MOV DI,SI

    RET

DRAW_POPUP_BUTTON_MSG2_SAVE ENDP


WANNA_SAVE_BEFORE_SAVE PROC
    
   MOV BX,offset WANNA_QUIT_BUT
    MOV [BX],0
        

    
    MOV BX,offset DISABLED_EDITOR
    MOV DX,[BX]
    CMP DX,0
    JNZ START_WANNA_BEFORE_SAVE
    
    CALL STAY_CURRENT_PAGE
     
    CALL READ_FILE
    
    START_WANNA_BEFORE_SAVE:  
    
    CALL CLEAR_POPUP_MSG    
    CALL DRAW_POPUP_MSG
    CALL DRAW_POPUP_BUTTON_MSG2_SAVE
    
    
    MOV DH,12    ;row
    MOV DL,25   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET WANNA_SAVE_MSG
    MOV SI,BX ;EXIT BUTTON
    
L_PIR_FILE_SAVED2_SAVE:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR_FILE_SAVED2_SAVE
    
    MOV DH,13    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
    
    
    MOV BX,OFFSET FILENAME
    MOV SI,BX ;EXIT BUTTON

    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    MOV CX,4
    L_HEADER_TEXT2_2MEN_SAVE:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    LOOP L_HEADER_TEXT2_2MEN_SAVE
    
     

    INPUT_WANNA_BEFORE_SAVE:
    
    MOV AH,00
    INT 16h
    
    
    CMP AX,4D00h
    JZ RIGHT_SELECT2_SAVE
    
    CMP AX,4B00h
    JZ LEFT_SELECT2_SAVE
    
    CMP AX,1C0Dh
    JZ FIN_SELECT_SAVE2_SAVE
    
    CMP AX,011Bh
    JNZ PASS_ESC2_SAVE
    
    CALL STAY_CURRENT_PAGE
    
    POP AX 
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    JMP START_EDITOR
    
    PASS_ESC2_SAVE: 
    
    
    JMP INPUT_WANNA_BEFORE_SAVE
    
    LEFT_SELECT2_SAVE:
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,0
    JZ RIGHT_SELECT2_SAVE
    MOV [BX],0
    
    JMP START_WANNA_BEFORE_SAVE    
    
    RIGHT_SELECT2_SAVE:
    
    
    MOV BX,offset WANNA_QUIT_BUT 
    MOV DX,[BX]
    CMP DX,1
    JZ LEFT_SELECT2_SAVE
    MOV [BX],1
    
    JMP START_WANNA_BEFORE_SAVE
    
    FIN_SELECT_SAVE2_SAVE:
     
    MOV BX,offset WANNA_QUIT_BUT
    MOV DX,[BX]
    CMP DX,1
    JZ LOAD_MENU_PROC_PASS2_SAVE

    CALL SAVE_MENU_PROC
    
    CMP BP,0
    JZ FIN_MEN_SAVE
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],0
    
    CALL CLEAR_SCREEN
    
    JMP EDITOR
    
    
    
    
    
    LOAD_MENU_PROC_PASS2_SAVE:
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],0
    CALL WRITE_FILE
    
    CALL FILE_SAVED
    
    CALL BACKGROUND_EDITOR_MENU_CLEAR
    MOV DI,2400
    CALL BACKGROUND_GRAY_EDITOR
    
    
    FIN_MEN_SAVE:
    
    RET

WANNA_SAVE_BEFORE_SAVE ENDP


SAVE_MENU_PROC PROC
    
    MOV BX,offset FILENAME
    MOV SI,BX
    MOV BX,offset FILENAME_OLD
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    CALL CLEAR_POPUP
    CALL DRAW_POPUP
    
    ;PRINTING POPUP MESSAGE FOR NEWFILE POPUP
    
    MOV DH,11    ;row
    MOV DL,36   ;column
    CALL CURSOR_SET
    
    MOV BX,OFFSET SAVE_AS_MEN_MSG
    MOV SI,BX ;EXIT BUTTON
    

L_PIR2_MEN_SAVE:
    MOV AL,[SI]
    MOV BL,0FBh;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    INC SI
    MOV BL,[SI]
    CMP BL,"$"
    JNZ L_PIR2_MEN_SAVE

CONTINUE_NEWFILE_MEN_SAVE: 
    
    MOV DH,14    ;row
    MOV DL,41   ;column
    CALL CURSOR_SET

    MOV BL,0F3h;White Foreground,Red Background
    MOV AL,'.'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT
    MOV AL,'x'
    CALL PRINT_COLORED_TEXT
    MOV AL,'t'
    CALL PRINT_COLORED_TEXT         
    

    MOV DH,14    ;row
    MOV DL,33   ;column
    CALL CURSOR_SET   


    MOV BX,offset FILENAME
    MOV SI, BX
    MOV CX,0
    

L_SAVE_FILE_MEN_SAVE: 
    MOV ah,00h
    INT 16h

    CMP AX,1C0Dh   
    JZ SAVE_NEW_MEN_SAVE
    CMP AX,011Bh ;ESC, Return HOMEPAGE
    JZ END2_MEN_SAVE  
    CMP AX,0E08h
    JZ BACKSPACE_MEN_SAVE
    CMP CX,8
    JZ L_SAVE_FILE_MEN_SAVE
    
        
    MOV [SI],AL
    INC SI
    INC CX

    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    JMP L_SAVE_FILE_MEN_SAVE
    
    BACKSPACE_MEN_SAVE:
    
    CMP CX,0
    JZ L_SAVE_FILE_MEN_SAVE
    
    DEC SI
    DEC CX
    
    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
      
    MOV AL,[SI]    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT

    MOV AL,08h    
    MOV BL,0F3h;White Foreground,Red Background
    CALL PRINT_COLORED_TEXT
    
    MOV [SI],0
    
    JMP L_SAVE_FILE_MEN_SAVE 
    
    SAVE_NEW_MEN_SAVE:
    
    CMP CX,0
    JZ NONAME_NEWFILE_MEN_SAVE
    
    MOV [SI],'.'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],'x'
    INC SI
    MOV [SI],'t'
    INC SI
    MOV [SI],0
    
    ;--CONTROL IF FILE IS EXIST--
    
    CALL OPEN_FILE
    
	JC FILE_NOT_EXIST_MEN_SAVE
	
	JMP FILE_EXIST_MEN_SAVE  ;FILE EXIST ERROR
    
    
    ;--CREATING FILE--
    FILE_NOT_EXIST_MEN_SAVE:
    
    CALL CLOSE_FILE
    
    CALL CREATE_FILE
	
	JC EXIT ;IF there is an ERRR
	
	MOV [SI], AX
	
	CALL WRITE_FILE
	
	CALL CLOSE_FILE
	
	CALL OPEN_FILE
	
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
	
	
	FILE_EXIST_MEN_SAVE:;IF FILE IS EXIST ERROR MSG WILL SHOW UP
    
    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,35   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET FILE_EXIST_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT
    
    JMP CONTINUE_NEWFILE_MEN_SAVE
    
    NONAME_NEWFILE_MEN_SAVE: ; IF INPUT IS BLANK SHOW ERROR

    CALL CLEAR_FILENAME_INPUT
    
    MOV DH,14    ;row
    MOV DL,27   ;column
    CALL CURSOR_SET
     
    MOV BX,OFFSET BLANK_FILE_MSG
    MOV SI,BX ;EXIT BUTTON
    CALL INPUT_ERROR_PRINT 
    
    JMP CONTINUE_NEWFILE_MEN_SAVE
  
         
END2_MEN_SAVE:
    
    MOV BX,offset FILENAME_OLD
    MOV SI,BX
    MOV BX,offset FILENAME
    
    MOV CX,12
    STORE_L522_SAVE:
    MOV DL,[SI] 
    MOV [BX],DL
    INC BX
    INC SI
    LOOP STORE_L522_SAVE
    
    MOV BP,0 ;ISLEM IPTAL
    
    RET
    
SAVE_MENU_PROC ENDP


CLEAR_CACHE PROC
    
    MOV BX,offset CURSOR_X
    MOV [BX],0
    MOV BX,offset CURSOR_Y
    MOV [BX],0 
    
    MOV BX,offset TEMP_PAGE
    MOV [BX],0
    
    MOV BX,offset EOF_FLAG
    MOV [BX],0   
    
    MOV BX,offset FILE_POINTER
    MOV [BX],0 
    
    MOV BX,offset FILE_POINTER_TEMP
    MOV [BX],0 

    MOV BX,offset NEXTLINE_TEMP
    MOV [BX],0 

    MOV BX,offset BACKSPACE_LINE
    MOV [BX],0 
     
    MOV BX,offset CAP_WORDS_FLAG
    MOV [BX],0  
    
    MOV BX,offset CAP_SENT_FLAG
    MOV [BX],0 
    
    MOV BX,offset FILE_CHANGED_FLAG
    MOV [BX],0
    
    MOV BX,offset MENU_SELECTED_BUTTON
    MOV [BX],0
    
    MOV BX,offset WANNA_QUIT_BUT
    MOV [BX],0
    
    MOV BX,offset DISABLED_EDITOR
    MOV [BX],0
  
    RET
    
CLEAR_CACHE ENDP 

CLEAR_USELESS_STR PROC
    
   MOV BX,offset FIND_WORD 
   MOV SI,BX
   
   MOV BX,offset FIND_WORD_LEN
   MOV CX,[BX]
   ADD SI,CX
   DEC SI   
   
   DEL_LOOP:
   MOV AL,[SI]
   
   CALL CHAR_CHECK
   CMP BP,0
   JNZ FIN_DEL_LOOP
   
   CMP AL,' '
   JNZ FIN_DEL_LOOP
   
   MOV [SI],0
   
   MOV BX,offset FIND_WORD_LEN
   MOV DX,[BX]
   DEC DX
   MOV [BX],DX
   
   DEC SI   
      
   LOOP DEL_LOOP
   
   FIN_DEL_LOOP:
      
   RET               
    
CLEAR_USELESS_STR ENDP

STAY_CURRENT_PAGE PROC
    
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    SHL AX,1

    MOV BX,offset NEXTLINE_PAGES
    ADD BX,AX

    MOV DX,[BX]
    MOV BX,offset NEXTLINE_TEMP
    MOV [BX],DX
    
    RET
    
STAY_CURRENT_PAGE ENDP

MEM_ADJUST_REPLACE PROC
       
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    MOV [BX],DI
    
    LOOP_RED:   
    
    PUSH DI
    
    CALL REDUCE_MEM
    
    MOV BX,@DATA
    MOV ES,BX
    
    POP DI
    
    LEA BX,FILE_POINTER
    MOV DX,[BX]
    DEC DX
    MOV [BX],DX    
    
    DEC BP
    JNZ LOOP_RED
    
    LEA BX,FILE_POINTER_TEMP
    MOV DX,[BX]
    
    LEA BX,FILE_POINTER
    MOV [BX],DX
    
    RET
        
    EXTENDED_REPLACE:
    
    XCHG CX,DX
    
    SUB DX,CX

    MOV BP,DX
    MOV AX,BP
        
    LEA BX,FILE_POINTER
    MOV DX,[BX]
    
    LEA BX,FILE_POINTER_TEMP
    MOV [BX],DX
  
    LEA BX,FIND_WORD_LEN
    MOV DX,[BX]
    
    LEA BX,FILE_RESTORE
    MOV CX,BX
    
    LEA BX,FILE_POINTER
    ADD DI,DX
    SUB DI,CX
    
    MOV [BX],DI
    
    LOOP_EXT:    
    
    PUSH DI
       
    CALL EXTEND_MEM    
    MOV BX,@DATA
    MOV ES,BX
        
    POP DI
    
    LEA BX,FILE_POINTER
    MOV DX,[BX]
    INC DX
    MOV [BX],DX
       
    DEC BP
    JNZ LOOP_EXT
    
    LEA BX,FILE_POINTER_TEMP
    MOV DX,[BX]
    
    LEA BX,FILE_POINTER
    MOV [BX],DX
    
    RET
    
MEM_ADJUST_REPLACE ENDP 

TEMP_STORE PROC

    MOV AX,@DATA
    MOV ES,AX

    MOV BX,offset FILE_LEN
    MOV CX,[BX]
    INC CX

    MOV BX, offset FILE_RESTORE
    MOV SI,BX
    MOV BX, offset FILE_DUMMY 
    XXXX
    XXXX

    MOV AX,0A000h
    MOV ES,AX

    RET
    
TEMP_STORE ENDP

TEMP_LOWER_CASE PROC

    MOV BX, offset FILE_LEN    
    MOV CX,[BX]
    
    MOV BX,offset FILE_DUMMY
    
    L_LOW_WORD:  
    MOV AL,[BX]
    
    CALL CHAR_CHECK
    CMP BP,1
    JNZ PASS_CASE
    
    XOR AL,20h
    MOV [BX],AL
    
    PASS_CASE:
    
    INC BX

    LOOP L_LOW_WORD 

    RET
    
TEMP_LOWER_CASE ENDP

LOWER_CASE_FIND PROC
    
    MOV BX, offset FIND_WORD_LEN    
    MOV CX,[BX] 
    
    CMP CX,0
    JZ FIN_LCF
    
    MOV BX,offset FIND_WORD
    
    L_LOW_WORD2:  
    MOV AL,[BX]

    CALL CHAR_CHECK
    CMP BP,1
    JNZ PASS_CASE2
    
    XOR AL,20h
    MOV [BX],AL
    
    PASS_CASE2:
    
    INC BX

    LOOP L_LOW_WORD2
    
    FIN_LCF:
    
    RET
    
LOWER_CASE_FIND ENDP

COUNT_CUR_PAGE_FOUND PROC
    
    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    SHL AX,1

    MOV BX,offset NEXTLINE_PAGES
    ADD BX,AX

    MOV DX,[BX]
    
    MOV BX,offset FILE_RESTORE
    ADD DX,BX
    
    MOV BX,offset FOUND_NUM
    MOV CX,[BX]
    
    CMP CX,0
    JZ FIN_COUNT_CUR2
    
  
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX
    
    MOV BP,0
    
    L_COUNT_PF:
    
    MOV BX,[SI]
    SUB BX,5000
    INC BX
    CMP BX,AX
    JA PASS_T
    
    CMP BX,DX
    JB PASS_T
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX 
    
    LOOP L_COUNT_PF
    
    FIN_COUNT_CUR2:
    
    MOV BX,offset FOUND_NUM_PAGE
    MOV [BX],BP
    
    RET
COUNT_CUR_PAGE_FOUND ENDP 

CURSOR_POS_FINDER PROC
    
    MOV DH,2    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET
    
    MOV BX,offset NEWLINE_POINTERS
    MOV DI,BX
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX

    MOV BX,offset TEMP_PAGE
    MOV AX,[BX]
    MOV DX,78
    DIV DL
    MOV DX,2
    MUL DL

    MOV BX,offset NEXTLINE_PAGES
    ADD BX,AX
    MOV AX,BP    
    MOV [BX],AX
    
    MOV BX,offset FOUND_PAGE
    MOV DI,[BX]
    
    MOV BP,0
L_READ_FILE2_FOUND:
    
    CMP SI,DI
    JZ FOUND_CUR_D
    MOV DL,[SI]
    CONT_D:
    
    INC SI
    
    CMP  DL,1AH         ;is it Control-Z <EOF>?
    JZ   EOFF_ERR2_FOUND           ;jump if yes
    
    CMP DL,0Dh
    JZ L_READ_FILE2_FOUND
    CMP DL,0Ah
    JZ NEW_LINE_EDITOR23_FOUND
    CMP BP,78
    JZ NEW_LINE_EDITOR3_FOUND 
    
    CONTINUE_WRITE2_FOUND:
    INC BP
    
    MOV AH,03h
    MOV BH,0
    INT 10h
    
    INC DL   ;column
    CALL CURSOR_SET 

    JMP  L_READ_FILE2_FOUND       ;and repeat

NEW_LINE_EDITOR3_FOUND:

    MOV AH,03h
    MOV BH,0
    INT 10h
    
    CMP DH,26
    JZ EOFF_ERR2_FOUND
    
    INC DH    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET   
    MOV BP,0

    JMP CONTINUE_WRITE2_FOUND 
    
    FOUND_CUR_D:
    
    MOV AH,03h
    MOV BH,0
    INT 10h
    
    DEC DL
    
    MOV BX,offset FOUND_TEMP
    MOV CX,[BX]
    SHL CX,1
    
    XXXX
    XXXX
    XXXX
    XXXX

    XXXX
    XXXX
    XXXX   
    
    MOV BX,offset FOUND_PAGE 
    INC BX
    INC BX
    MOV DI,[BX]
        
    JMP CONT_D
    
NEW_LINE_EDITOR23_FOUND:
    
    MOV AH,03h
    MOV BH,0
    INT 10h
       
    CMP DH,26
    JZ EOFF_ERR2_FOUND
    
    INC DH    ;row
    MOV DL,1   ;column
    CALL CURSOR_SET   
    MOV BP,0

    JMP L_READ_FILE2_FOUND      

EOFF_ERR2_FOUND:
    
    
    RET
    
CURSOR_POS_FINDER ENDP



END MAIN
