;       ********************************************************
;               CONSOLE DIRECT DISPLAY SAMPLE
;       ********************************************************
;
;       NOTE :
;               This sample program is using console
;               out direct display.
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
WBOOT           EQU     0EB03H  ; WBOOT entry address.
CONST           EQU     0EB06H  ; CONST entry address.
CONIN           EQU     0EB09H  ; CONIN entry address.
CONOUT          EQU     0EB0CH  ; CONOUT entry address.
TIMDAT          EQU     0EB4EH  ; TIMDAT entry address.
CALLX           EQU     0EB69H  ; CALLX entry address.
;
;       Bank value
;
SYSBANK         EQU     0FFH
BANK0           EQU     000H
BANK1           EQU     001H
BANK2           EQU     002H
;
;
MAINSP          EQU     01000H  ; Stack pointer.
;
;       System area
;
LESCPRM         EQU     0F2ACH  ; ESC sequence parameter area.
LFKADDR         EQU     0F2A8H  ; CONOUT execute addr.
DISBNK          EQU     0F52EH  ; Bank data.
;
;
CR              EQU     0DH
LF              EQU     0AH
CLS             EQU     12H
ESC             EQU     1BH
;
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               Display time until press BREAK key.
;               And key input any key.
;
START:
        LD      SP,MAINSP       ; Set stack pointer.
;
        CALL    GETFKAD         ; Get direct display function addr.
;
        LD      HL,MSG01        ; Date & time message.
        CALL    DSPMSG          ; Dispay message.
;
LOOP:
        HALT
;
        CALL    CONST           ; Key in check.
        INC     A               ; Input any key?
        JR      NZ,SKIP         ; No.
        CALL    CONIN           ; Get inputed key.
        CP      03H             ; BREAK key?
        JR      Z,TIMEEND       ; Yes.
;
        LD      C,A             ; Display inputed character.
        CALL    CONOUT          ;
;
SKIP:
        LD      DE,NTIME        ; Time discrepter.
        LD      C,00H           ; Read time function.
        CALL    TIMDAT          ; Read time.
;
        CALL    TIMECHK         ; New & old time compare.
        JR      Z,LOOP          ; If same, then loop.
;
        CALL    TIMESET         ; Set new time.
        CALL    DSPTIME         ; Display time data
        JR      LOOP            ; Loop
;
TIMEEND:
;
;       ********************************************************
;               GET DIRECT DISPLAY FUNCTION ADDRESS.
;       ********************************************************
;
;       NOTE :
;               This routine sends dummy console out function.
;               And get the function execute address in
;               OS ROM.
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
GETFKAD:
        LD      HL,DIRECT       ; Dummy console out data.
        CALL    DSPMSG          ;
;
        LD      HL,(LFKADDR)    ; Get the function execute addr.
        LD      (FKDIRECT),HL   ; Save the address.
        RET                     ;
;
;       ********************************************************
;               DISPLAY MESSAGE UNTIL FIND 0
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               HL : Message data top address.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
DSPMSG:
        LD      A,(HL)          ; Get message data.
        OR      A               ; End mark?
        RET     Z               ; Yes, then return.
;
        LD      C,A             ; Set display data to c reg.
        PUSH    HL              ; Save message pointer.
        CALL    CONOUT          ; Display message.
        POP     HL              ; Restore pointer.
        INC     HL              ; Pointer update.
        JR      DSPMSG          ; Loop until find 0.
;
;       ********************************************************
;               DISPLAY TIME DATA
;       ********************************************************
;
;       NOTE :
;               Display time data by calling OS ROM directly.
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
DSPTIME:
        LD      HL,MSG02        ; Date message.
        CALL    DSP10           ; Display the message.
;
        LD      HL,MSG03        ; Time message.
DSPT10:
        LD      DE,LESCRPRM     ; CONOUT parameter area.
        LD      A,(HL)          ; Set Y-coordinate.
        LD      (DE),A          ;
        INC     HL              ;
        INC     DE              ;
;
        LD      A,(HL)          ; Set X-coordinate.
        LD      (DE),A          ;
        INC     HL              ;
;
        LD      B,08H           ; Loop counter.
DSPT20:
        LD      C,(HL)          ; Display character.
        LD      A,SYSBANK       ; Set system bank value.
        LD      (DISBNK),A      ;
        LD      IX,(FKDIRECT)   ; OS ROM call address.
        PUSH    BC              ; Save registers.
        PUSH    DE              ;
        PUSH    HL              ;
        CALL    CALLX           ; Go !!
        POP     HL              ; Restore registers.
        POP     DE              ;
        POP     BC              ;
;
        LD      A,(DE)          ; Increment X-coordinate.
        INC     A               ;
        LD      (DE),A          ;
        INC     HL              ; Message pointer update.
        DJNZ    DSPT20          ; Loop.
;
        RET                     ;
;
;       ********************************************************
;               CHECK OLD & NEW TIME
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               ZF : Return iformation
;                    =1 : New time is same as old one.
;                    =0 : New time is different from old one.
;       <> preserved registers <>
;               NON
;
TIMECHK:
        LD      HL,NTIME        ; New time data.
        LD      DE,OTIME        ; Old time data.
        LD      B,06H           ; Data counter.
;
TLOOP:
        LD      A,(DE)          ; Get old time data.
        CP      (HL)            ; Compare it with the new one.
        RET     NZ              ; If disagree, then return.
        INC     DE              ; Poninters update.
        INC     HL              ;
        DJNZ    TLOOP           ; Loop 6 times.
        RET                     ;
;
;       ********************************************************
;               SET TIME DATA
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
TIMESET:
        LD      HL,NTIME        ; Set time data to old time area.
        LD      DE,OTIME        ; 
        LD      BC,6            ; Year/month/date/hour/minute/second
        LDIR                    ; Move new data to old area.
;
        LD      HL,NTIME        ; Set BCD data to message area with ASCII.
        LD      DE,DATE         ; HL is source, DE is destination.
        LD      B,03H           ; B is counter.
SET10:
        CALL    SETASCII        ; Convert BCD to ASCII.
        INC     HL              ; Pointer update.
        INC     DE              ; 
        DJNZ    SET10           ; Loop 3 times. (Year/month/date)
;
        LD      DE,TIME         ; Time date setting area.
        LD      B,03H           ;
SET20:
        CALL    SETASCII        ; Convert BCD to ASCII.
        INC     HL              ; Pointer update.
        INC     DE              ;
        DJNZ    SET20           ; Loop 3 times. (Hour/minute/second)
        RET
;
;       ********************************************************
;               SET ASCII DATA FROM BCD DATA
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               HL : BCD data address,
;               DE : ASCII data setting address.
;       <> return parameter <>
;               DE : Entry DE + 2
;       <> preserved registers <>
;               HL
;
SETASCII:
        LD      A,(HL)          ; Get BCD data.
        PUSH    AF              ; Save BCD data.
        RRCA                    ; Move MSB 4 bit to LSB 4bit.
        RRCA                    ;
        RRCA                    ;
        RRCA                    ;
        CALL    NEXT            ; Set ASCII data by 1 byte.
        POP     AF              ;
NEXT:
        AND     0FH             ; Check LSB 4 bit.
        ADD     A,30H           ; Change to ASCII data.
        LD      (DE),A          ; Set ASCII data.
        INC     DE              ; Setting pointer update.
        RET                     ;
;
;
;
MSG01:
        DB      0CH
        DB      'Present date is         .',CR,LF
        DB      'Input line = '
        DB      00H
MSG02:
        DB      01H,11H                 ; Direct display
DATE:
        DB      '00/00/00'
MSG03:
        DB      02H,11H                 ; Direct display
TIME:
        DB      '00:00:00'
;
DIRECT:
        DB      ESC,0D2H,1,1,20H        ; Direct display dummy
        DB      00H
;
;
;
NTIME:
        DS      7
OTIME:
        DS      7
;
FKDIRECT
        DS      2
        END
