;       ********************************************************
;               BIOS GETPFK SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is displaying present
;               defined function key list.
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
WBOOT           EQU     0EB03H  ; WBOOT entry address.
CONIN           EQU     0EB09H  ; CONIN entry address.
CONOUT          EQU     0EB09H  ; CONOUT entry address.
GETPFK          EQU     0E6CH   ; GETPFK entry address.
;
MAINSP          EQU     1000H   ; Stack pointer.
;
CR              EQU     0DH     ; Carriage return code.
LF              EQU     0AH     ; Line feed code.
BREAK           EQU     03H     ; STOP code.
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE : 
;
START:
        LD      SP,MAINSP       ; Set stack pointer.
;
        LD      B,09H-00H+1     ; Loop counter.
        LD      C,00H           ; PF1 to PF10
;
LOOP1:
        PUSH    BC              ; Save counter and PFK code.
        LD      HL,PFKBUF       ; PFK data reading area.
        CALL    GETPFK          ; Get PFK data.
        CALL    PFKDSP          ; Display PFK data.
        POP     BC              ; Restore counter and PFK code.
        INC     C               ; Increase PFK code.
        DJNZ    LOOP1           ; Loop 10 times.
        LD      B,7EH-40H+1     ; Loop counter.
        LD      C,40H           ; ITEM FK code.
;
LOOP2:
        PUSH    BC              ; Save counter & ITEM FK code.
        LD      HL,PFKBUF       ; PFK data reading area.
        CALL    GETPFK          ; Get PFK data.
        CALL    PFKDSP          ; Display PFK data.
        POP     BC              ; Restore counter & ITEM FK code.
        INC     C               ; Increase ITEMFK code.
        DJNZ    LOOP2           ; Loop 63 times.
;
        JP      WBOOT           ; End of main program.
;
;       ********************************************************
;               DISPLAY FUNCTION KEY DATA
;       ********************************************************
;
;       NOTE : 
;               Display the function key data and
;                when input any key except STOP. return.
;               If STOP key is pressed, then WBOOT.

;       <> entry parameter <>
;               HL : PFK string top address.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       Caution :
;
PFKDSP:
        LD      A,(HL)          ; Get string length.
        OR      A               ; Length is 0?
        JR      Z,PFKEND        ; Yes.
;
        LD      B,A             ; String length --> counter.
        INC     HL              ; String pointer 1 increase.
;
PFKLOOP:
        PUSH    HL              ; Save pointer.
        PUSH    BC              ; Save counter.
        LD      C,(HL)          ; Get display data.
        CALL    CONOUT          ; Display the data.
        POP     BC              ; Restore counter.
        POP     HL              ; Restore pointer.
        INC     HL              ; Pointer update.
        DJNZ    PFKLOOP         ; Loop (by string length)
;
PFKEND:
        LD      C,CR            ; Display CR & LF.
        CALL    CONOUT          ;
        LD      C,LF            ;
        CALL    CONOUT          ;
;
        CALL    CONIN           ; Get any inputed key.
        CP      BREAK           ; STOP code?
        JP      Z,WBOOT         ; YES, then WBOOT.
        RET                     ; else return.
;
;       ********************************************************
;       WORK AREA
;       ********************************************************
;
PFKBUF:
        DS      16              ; PFK data reading area.
;
        END
