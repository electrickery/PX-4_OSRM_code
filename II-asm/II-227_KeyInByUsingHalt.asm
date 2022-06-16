;       ********************************************************
;               KEY IN BY USING HALT
;       ********************************************************
;
;       NOTE :
;               This sample program is how to input key
;               by using halt.
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
WBOOT           EQU     0EB033H         ; Warm boot entry
CONST           EQU     WBOOT   +03H    ; Console status entry
CONIN           EQU     WBOOT   +06H    ; Console input entry
CONOUT          EQU     WBOOT   +09H    ; Console output entry
POWEROFF        EQU     WBOOT   +7BH    ; Power off entry
;
;       System area
;
ATSHUTOFF       EQU     0EF40H          ; Auto power off time (minute)
ATSOTIME        EQU     0EF41H          ; Auto power off time (second)
TIMER0          EQU     0EF8FH          ; 1 sec counter
TIMEEND         EQU     0F77CH          ; Auto powrr off time setting area
;
;
STOP            EQU     03H             ; Stop code.
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This program is using CONST routine.
;               And at the time of power off,
;               power off by user.
;
MAIN:
        LD      SP,1000H        ; Set stack pointer.
;
MAIN10:
        LD      HL,(ATSOTIME)   ; Set auto power off time.
        LD      DE,(TIMER0)     ; (ATSOTIME)+(TIMER0) --> (TIMEEND)
        ADD     HL,DE           ;
        LD      (TIMEEND),HL    ;
;
MAIN20:
        LD      A,(ATSHUTOFF)   ; Check auto power off.
        OR      A               ; Disable?
        JR      Z,MAIN30        ; Yes.
;
        LD      HL,(TIMEEND)    ; Check power off time.
        LD      DE,(TIMER0)     ; (TIMEEND)-(TIMER0) < 0 ?
        OR      A               ;
        SBC     HL,DE           ;
        LD      C,00H           ; Yes, then continue mode power off.
        CALL    M,POWEROFF      ;
;
MAIN30:
        HALT                    ; Halt (Sleep mode)
;
        CALL    CONST           ; Input any key?
        INC     A               ;
        JR      NZ,MAIN20       ; No.
;
        CALL    CONIN           ; Get inputed key.
        CP      STOP            ; Stop code?
        JP      Z,WBOOT         ; Yes, then end.
        LD      C,A             ; Display inputed key.
        CALL    CONOUT          ;
        JR      MAIN10          ; Loop.
;
        END
