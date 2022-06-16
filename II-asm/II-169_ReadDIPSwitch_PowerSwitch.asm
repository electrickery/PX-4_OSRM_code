;       ********************************************************
;               READ DIP SWITCH & POWER SWITCH
;       ********************************************************
;
;       NOTE :
;               This sample program is reading switch
;               status and displaying it.
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
WBOOT           EQU     0EB03H          ; Warm Boot entry.
CONOUT          EQU     WBOOT   +09H    ; Console out entry.
READSW          EQU     WBOOT   +6FH    ; Read switch entry.
;
;
TAB             EQU     009H    ; TAB code.
LF              EQU     00AH    ; Line feed.
CLS             EQU     00CH    ; Clear screen.
CR              EQU     00DH    ; Carriage return.
ESC             EQU     01BH    ; Escape.
ON              EQU     0E2H    ; On code.
OFF             EQU     0E3H    ; Off code.
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;
MAIN:
        LD      SP,1000H        ; Set stack pointer.
;
        CALL    SETCHAR         ; Set user-defined char.
;
        LD      C,02H           ; Read dip switch.
        CALL    READSW          ;
        CALL    DSET            ; Set dipswich data.
;
        LD      C,04H           ; Read power switch.
        CALL    READSW          ;
        CALL    PSET            ; Set power switch status.
;
        CALL    DSPMSG          ; Display switch status.
;
        CALL    WBOOT           ; End.
;
;
;       ********************************************************
;               SET USER DEFINE CHARACTERS
;       ********************************************************
;
;       NOTE :
;               Set user defined character.
;               E0H & E1H is used.

;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
SETCHAR:
        LD      HL,CHARDATA     ; Data top address.
        LD      B,(HL)          ; get data counter.
        INC     HL              ;
;
SET10:
        LD      C,(HL)          ; Get conout data.
        PUSH    HL              ; Save registers.
        PUSH    BC              ;
        CALL    CONOUT          ; Console out.
        POP     BC              ; Restore registers.
        POP     HL              ;
        INC     HL              ; Pointer update.
        DJNZ    SET10           ; Loop.
        RET
;
;
CHARDATA:
        DB      22              ; Data number.
        DB      ESC,0E0H,0E2H   ; 0E2H char data.
        DB      3FH,3FH,3FH,3FH
        DB      21H,21H,21H,3FH
;
        DB      ESC,0E0H,0E3H   ; 0E3H char data.
        DB      3FH,21H,21H,21H
        DB      3FH,3FH,3FH,3FH
;
;
;       ********************************************************
;               SET DIP SWITCH DATA
;       ********************************************************
;
;       NOTE :
;               Set dip switch data to message area.

;       <> entry parameter <>
;               A  : Dip switch data.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
DSET:   
        LD      HL,DIPSW        ; Data setting addr.
        LD      B,8             ; Loop counter.
;
DSET10:
        RLCA                    ; Set switch status to CY.
        CALL    SETONOFF        ; Set data.
        INC     HL              ; Next setting address.
        DJNZ    DSET10          ; Loop.
;
        RET                     ;
;       ********************************************************
;               SET POWER SWITCH DATA
;       ********************************************************
;
;       NOTE :
;               Set power switch data to message area.

;       <> entry parameter <>
;               A  : Power switch data.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
PSET:
        LD      HL,POWSK        ; Data setting address.
        RRCA                    ; Switch data --> CY.
        CALL    SETONOF         ; Set data.
                                ;
;
;       ********************************************************
;               SELECT BDOS ERROR RECOVERY
;       ********************************************************
;
;       NOTE :
;               Select BDOS error recovery type.
;                1. Using SETERR and RSTERR
;                2. Replacing BDOS error vector

;       <> entry parameter <>
;               CY : ON/OFF information.
;                  =1 -- ON
;                  =0 -- OFF
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               BC,DE,HL
;
;       CAUTION :
;
SETONOFF:
        PUSH    BC              ; Save register.
        LD      B,ON            ; ON code --> B.
        JR      C,WSET10        ; ON.
        LD      B,OFF           ; Set OFF code.
MSET10:
        LD      (HL),B          ; Set data.
        POP     BC              ; Restore register.
        RET                     ;
;
;
;       ********************************************************
;               DISPLAY SWITCH MESSAGE
;       ********************************************************
;
;       NOTE :
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
DSPMSG:
        LD      HL,MSG          ; Message data top addr.
DSP10:
        LD      A,(HL)          ; Get data.
        OR      A               ; End of data?
        RET     Z               ; Yes.
;
        LD      C,A             ; Set parameter.
        PUSH    HL              ; Save register.
        CALL    CONOUT          ; Console out.
        POP     HL              ; Restore register.
        INC     HL              ; Pointer update.
        JR      DSP10           ; Loop.
;
;       Messsage and work area
;
MSG:
        DB      CLS
        DB      TAB,TAB,'ON 87654321',CR,LF
        DB      'DIP SWITCH',TAB
        
DIPSW:  DS      8
        DB      CR,LF
        DB      TAB,TAB,'OFF',CR,LF
        DB      TAB,TAB,'ON',CR,LF
        DB      'POWER SWITCH', TAB
        
POWSW:
        DS      1
        DB      CR,LF
        DB      TAB,TAB,'OFF',CR,LF
        DB      00H
;
        END
