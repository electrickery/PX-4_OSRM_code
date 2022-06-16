;       ********************************************************
;               DISPLAY KEY STATUS
;       ********************************************************
;
;       NOTE :
;               This sample program is displaying the
;               current key status.
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
;       BIOS entry
;
WBOOT           EQU     0EB03H          ; Warn Boot entry
CONST           EQU     WBOOT   +03H    ; Console status entry
CONIN           EQU     WBOOT   +6H     ; Console input entry
CONOUT          EQU     WBOOT   +9H     ; Console output entry
;
;       System area
;
YSHFDT          EQU     0F00FH          ; Normal keyboard key status
IMSHFT          EQU     0F01FH          ; ITEM keyboard key status
YKCOUNTRY       EQU     0F775H          ; Keyboard country
;
;
STOP            EQU     03H             ; Stop code
EOL             EQU     05H             ; Erase end of line
CR              EQU     0DH             ; Carriage return
LF              EQU     0AH             ; Line feed
HOME            EQU     0BH             ; Home code
CLS             EQU     12H             ; Clear screen
ESC             EQU     0BH             ; ESC code
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This program is displaying the current shift key status.
;
MAIN:
        LD      SP,1000H        ; Set stack pointer.
;
        LD      C,CLS           ; Clear screen & home.
        CALL    CONOUT          ;
        CALL    CURSOFF         ; Cursor off.
;
MAIN10:
        HALT                    ; Halt (sleep mode).
;
        CALL    KEYST           ; Display key status.
;
        CALL    CONST           ; Input any key?
        INC     A               ; 
        JR      NZ,MAIN10       ; No.
;
        CALL    CONIN           ; Get inputed key.
        CP      STOP            ; STOP?
        JR      NZ,MAIN10       ; No.
;
        CALL    CURSON          ; Cursor on.
        JP      WBOOT           ; End.
;
;
;
;       ********************************************************
;               DISPLAY KEY STATUS
;       ********************************************************
;
;       NOTE :
;               Display current key status.
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
KEYST:
        LD      HL,SVSHFT       ; Old key status.
        LD      DE,YSHFDT       ; Current key status (Normal keyboard).
;
        LD      A,(YKCOUNTRY)   ; ITEM keyboard?
        AND     80H             ;
        JR      Z,KEY10         ; No.
        LD      DE,IMSHIFT      ; Current key status (ITEM)
KEY10:
        LD      A,(DE)          ; Get current status.
        CP      (HL)            ; Same as old one?
        RET     Z               ; Yes.
;
        LD      (HL),A          ; Save current key status.
;
        LD      C,HOME          ; Move cursor to home position.
        CALL    SVCONOUT        ;
        LD      HL,SHFTTBL      ; Shift data table.
        LD      B,08H           ; Loop counter.
KEY20:
        LD      C,EOL           ; Erase end of line.
        CALL    SVCONOUT        ;
;
        RRA                     ; LSB --> CY.
        CALL    C,DSPMSG        ; If OK, then dsp message.
        INC     HL              ; Pointer update.
        INC     HL              ;
        DEC     B               ; Counter decrement.
        RET     Z               ; End.
;
        LD      C,CR            ; Move cursor to next line.
        CALL    SVCONOUT        ; 
        LD      C,LF            ;
        CALL    SVCONOUT        ;
        JR      KEY20           ; Loop.
;
;       ********************************************************
;               DISPLAY MESSAGE
;       ********************************************************
;
;       NOTE :
;               Display message
;
;       <> entry parameter <>
;               HL : Data table top address.
;                 (HL+0) -- Byte number
;                 (HL+1) -- Display data
;                    '          '
;                    '          '
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               All registers
;
;       CAUTION :
;
DSPMSG:
        PUSH    AF              ; Save registers.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        LD      E,(HL)          ; Get data top address.
        INC     HL              ;
        LD      D,(HL)          ;
        EX      DE,HL           ; 
        LD      B,(HL)          ; Get displaying data number.
        INC     HL              ; HL is displaying data top address.
;
DSP10:
        LD      C,(HL)          ; Get display data.
        CALL    SYSCONOUT       ; Display.
        INC     HL              ; Pointer update.
        DJNZ    DSP10           ; Loop.
;
        POP     HL              ; Restore registers.
        POP     DE              ;
        POP     BC              ;
        POP     AF              ;
        RET                     ;
;
;       Conout data with unchanging all registers
;
SVCONOUT:
        PUSH    AF 
        PUSH    BC
        PUSH    DE
        PUSH    HL
        CALL    CONOUT
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET
;
;       Cursor on
;
CURSON:
        LD      C,ESC
        CALL    CONOUT
        LD      C,'3'
        CALL    CONOUT
        RET
;
;       Cursor off
;
CURSOFF:
        LD      C,ESC
        CALL    CONOUT
        LD      C,'2'
        CALL    CONOUT
        RET
;
;
;
SHFTTBL:
        DW      SHFTR
        DW      SHFTL
        DW      CAPS
        DW      NON
        DW      NUM
        DW      NON
        DW      GRPH
        DW      CTRL
;
SHFTR:
        DB      12
        DB      'SHIFT(right)'
SHFTL:
        DB      11
        DB      'SHIFT(left)'
CAPS:
        DB      9
        DB      'CAPS LOCK'
NON:
        DB      1
        DB      00H
NUM:
        DB      7
        DB      'NUMERIC'
GRPH:
        DB      7
        DB      'GRAPHIC'
CTRL:
        DB      7
        DB      'CONTROL'
;
;
SVSHFT:
        DB      0FFH
;
        END
