;       ********************************************************
;               CHANGE SCREEN AREA PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is changing screen
;               area.
;               So, you can use screen more than only one.
;
;       <> assemble condition <>
;
        .Z80
;
;       <> loading address <>
;
        .PHASE  100h
;
;       <> constant values <>
;
;       BIOS entry address.
;
WBOOT           EQU     0EB03H
CONIN           EQU     WBOOT   +06H
CONOUT          EQU     WBOOT   +09H
CALLX           EQU     WBOOT   +66H
;
;       System area
;
LSCADDR         EQU     0F290H  ; Screen buffer top addr.
LSCRVRAM        EQU     0F294H  ; VRAM area top addr.
LVRAMYOF        EQU     0F2A0H  ; VRAM Y-offset value.
TOPRAM          EQU     0EF94H  ; User BIOS area top addr.
;
;       OS ROM jump table
;
XREDSP          EQU     00036H  ; Re-display window
;
;
;
ESC             EQU     1BH     ; ESC code
STOP            EQU     03H     ; STOP code
HELP            EQU     00H     ; HELP code
;
;
VADDR           EQU     0C000H  ; New VRAM address.
;
;       IO register address
;
ZYOFF           EQU     09H     ;
ZVADR           EQU     08H     ;
;
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This routine sets new screen data.
;
;       CAUTION :
;               This program uses User BIOS area for VRAM.
;               But this routine doesn't check that
;               other program already User BIOS area.
;
;               If you stop program, you must restore
;               old screen status.
;               If you forget this, other system area
;               will be destroyed.
;
START:
        LD      SP,1000H        ; Set stack pointer.
;
;       Set initial data
;
        LD      HL,(TOPRAM)     ; User BIOS area check.
        LD      DE,0C001H       ; User BIOS area top addr <= C000H?
        XOR     A               ;
        SBC     HL,DE           ;
        JP      NC,WBOOT        ; No, then WBOOT
;
        LD      BC,50*256+40    ; Set default screen size.
        CALL    SETSCR          ;
;
        LD      HL,LSCADDR      ; Save current screen data.
        LD      DE,SCRSAVE      ; 
        LD      BC,27H          ;
        LDIR                    ;
;
        LD      BC,34*256+40    ; Set new screen size.
        CALL    SETSCR          ;
;
        LD      HL,VADDR        ; Clear new VRAM area
        LD      (HL),0          ;
        LD      D,H             ;
        LD      E,L             ;
        INC     DE              ;
        LD      BC,2048-1       ;
        LDIR
;
;       Main loop
;
LOOP:
        CALL    CONIN           ; Get inputed key code.
        CP      STOP            ; If STOP,
        JP      Z,PEND          ;  then end
        CP      ESC             ; If ESC,
        JR      Z,CHNGSCR       ;  then change the screen.
        CP      HELP            ; If HELP,
        JR      Z,CHNGVRAM      ;  then change VRAM.
        LD      C,A             ; Console out inpued data.
        CALL    CONOUT          ;
        JR      LOOP            ; Loop.
CHNGSCR:
        LD      C,ESC           ; Erase cursor
        CALL    CONOUT          ;
        LD      C,'2'           ;
        CALL    CONOUT          ;
;
        LD      HL,WORKBF1      ; Source addr.
        CALL    WKCHNG          ; Change screen.
;
        LD      A,0FFH          ; Set destination bank
        LD      (0F52EH),A      ; 
        LD      IX,XREDSP       ; redisplay window
        CALL    CALLX           ;
;
        LD      C,ESC           ; Cursor on.
        CALL    CONOUT          ;
        LD      C,'3'           ;
        CALL    CONOUT          ;
        JR      LOOP            ;
;
;
CHNGVRAM:
        LD      C,ESC           ; Erase cursor
        CALL    CONOUT          ;
        LD      C,'2'           ;
        CALL    CONOUT          ;
;
        LD      HL,WORKBF2      ;Source addr.
        CALL    WKCHNG          ;Change screen.
;
        CALL    SETVRAM         ;VRAM data set.
;
        LD      C,ESC           ; Cursor on.
        CALL    CONOUT          ;
        LD      C,'3'           ;
        CALL    CONOUT          ;
;
;
WKCHNG:
        LD      DE,LSCADDR      ;Destination addr.
        LD      B,27H           ;Exchange byte no.
;
WKC10:
        LD      C,(HL)          ;Exchange data.
        LD      A,(DE)          ; (DE) <--> (HL)
        LD      (HL),A          
        LD      A,C
        LD      (DE),A
;
        INC     HL              ;Pointer update
        INC     DE      
        DJNZ    WKC10           ;Loop until b=0
;
        RET
;
;
SETVRAM:
        XOR     A               ;Display off
        OUT     (ZYOFF),A
        LD      A,(LSCRVRAM+1)  ;Set VRAM addr.
        OUT     (ZVADR),A
        LD      A,(LVRAMYOF)    ;Set Y-offset
        OR      10000000B
        OUT     (ZYOFF),A
        RET
;
;
;       ********************************************************
;               CHANGE SCREEN ROUTINE
;       ********************************************************
;
;       NOTE :
;               This routine is changing screen size.
;
;       <> entry parameter <>
;               C   : New screen size for vertical
;               B   : New screen size for horizontal
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
SETSCR:
        PUSH    BC              ; Change screen size.
        LD      C,ESC           ;
        CALL    CONOUT          ;
        LD      C,0D0H          ;
        CALL    CONOUT          ;
        POP     BC              ;
        PUSH    BC              ;
        LD      C,B             ; Size of Y
        CALL CONOUT             ;
        POP     BC              ; Size of X
        CALL    CONOUT          ;
        RET                     ;
;
;
PEND:
        LD      HL,SCRSAVE      ;Restore screen data
        CALL    WKCHNG
        ;
        LD      C,0CH           ;Clear screen
        CALL    CONOUT
;
        CALL    SETVRAM
        JP      0000H           ;WBOOT
;
;
WORKBF1:
        DW      0D000H+40*34    ;Screen addr.
        DW      40*8            ;Screen size
        DW      0E000H          ;VRAM top addr
        DB      0               ;Cursor status
        DB      0               ;Reverse status
        DW      0101H           ;Cursor position in screen
        DB      40              ;Screen size X
        DB      8               ;Screen size Y
        DW      0101H           ;Window left-upper position
        DW      0000H           ;Cursor position in window
        DB      0               ;VRAM Y-offset
        DB      0               ;WIndow type
        DB      0               ;Secret mode
        DB      0               ;Scroll mode
        DW      0               ;Scroll step
        DB      0               ;Carriage return waitflag
        DB      0               ;Function status
        DW      0               ;Function addr
        DB      0               ;ESC flag
        DB      0               ;ESC count
        DB      0,0,0,0         ;Parameter store area
        DB      0,0,0,0
        DB      0,0,0
;
WORKBF2:
        DW      0D000H+40*42    ;Screen addr.
        DW      40*8            ;Screen size
        DW      VADDR           ;VRAM top addr
        DB      0               ;Cursor status
        DB      0               ;Reverse status
        DW      0101H           ;Cursor position in screen
        DB      40              ;Screen size X
        DB      8               ;Screen size Y
        DW      0101H           ;Window left-upper position
        DW      0000H           ;Cursor position in window
        DB      0               ;VRAM Y-offset
        DB      0               ;WIndow type
        DB      0               ;Secret mode
        DB      0               ;Scroll mode
        DW      0               ;Scroll step
        DB      0               ;Carriage return waitflag
        DB      0               ;Function status
        DW      0               ;Function addr
        DB      0               ;ESC flag
        DB      0               ;ESC count
        DB      0,0,0,0         ;Parameter store area
        DB      0,0,0,0
        DB      0,0,0
;
SCRSAVE:
        DS      27H             ;Screen data save area
        END
