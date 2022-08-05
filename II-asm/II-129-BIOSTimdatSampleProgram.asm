;       ********************************************************
;               BIOS TIMDAT SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is reading clock
;                and displainig time.
;               
;       <> assemble condition <>
;
;        .Z80
;
;       <> loading address <>
;
			ORG		0100h	;	.PHASE  100h
;
;       <> constant values <>
;
WBOOT           EQU     0EB03H  ; WBOOT entry address.
CONST           EQU     0EB06H  ; CONST entry address.
CONIN           EQU     0EB09H  ; CONIN entry address.
CONOUT          EQU     0EB0CH  ; CONOUT entry address.
TIMDAT          EQU     0EB4EH  ; TIMDAT entry address.
;
MAINSP          EQU     01000H  ; Stack pointer.
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               Display time until press BREAK key.
;
START:
        LD      SP,MAINSP       ; Set stack pointer
;
        LD      HL,CURSOFF      ; Cursor off data.
        CALL    DSPMSG
;
        LD      HL,MSG01        ; Date & time message.
        CALl    DSPMSG          ; Dispay message.
;
LOOP:
        CALL    CONST           ; Key in check.
        INC     A               ; Input any key?
        JR      NZ,SKIP         ; No.
        CALL    CONIN           ; Get imputed key.
        CP      03H             ; BREAK key?
        JR      Z,TIMEEND       ; Yes.
SKIP:
        LD      DE,NTIME        ; Time discrepter.
        LD      C,00H           ; Read time function.
        CALL    TIMDAT          ; Read time.
;
        CALL    TIMECHK         ; New & old time compare.
        JR      Z,LOOP          ; If same, then loop.
;
        CALL    TIMESET         ; Set new time data.
        LD      HL,MSG02        ; Display time data.
        CALL    DSPMSG          ;
        JR      LOOP            ; Loop.
;
TIMEEND:
        LD      HL,CURSON       ; Cursor on data.
        CALL    DSPMSG          ; Cursor on.
        JP      WBOOT           ; WBOOT
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
        RET     Z               ; Yes. then return.
;
        LD      C,A             ; Set display data to C reg.
        PUSH    HL              ; Save message pointer.
        CALL    CONOUT          ; Display message.
        POP     HL              ; Restore message pointer.
        INC     HL              ; Pointer update.
        JR      DSPMSG          ; Loop until find 0.
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
        LD      B, 06H          ; Data counter.
TLOOP:
        LD      A,(DE)          ; Get old time data.
        CP      (HL)            ; Compare it with new one.
        RET     NZ              ; If disagree, then return.
        INC     DE              ; Poniters update.
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
        LD      BC,6            ; B is counter.
        LDIR                    ; Move new data to old area.
;
        LD      HL,NTIME        ; Set BCD data to message area with ASCII.
        LD      DE,DATE         ; HL is source, DE is destination.
        LD      B,03H           ; B is counter
SET10:
        CALL    SETASCII        ; Convert BCD to ASCII.
        INC     HL              ; Pointer update.
        INC     DE              ;
        DJNZ    SET10           ; Loop 3 times. (Year/month/date)
;
        LD      DE,TIME         ; Time date setting area.
        LD      B,03H
SET20:
        CALL    SETASCII        ; Convert BCD to ASCII.
        INC     HL              ; Pointer update.
        INC     DE              ;
        DJNZ    SET20           ; Loop 3 times. (Houir/minute/second)
;
;       ********************************************************
;               SET ASCII DATA FROM BCD DATA
;       ********************************************************
;
;       NOTE :
;               
;       <> entry parameter <>
;               HL : BCD data address.
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
        POP     AF              ; Restore BCD data.
NEXT:
        AND     0FH             ; Check LSB 4 bit.
        ADD     A,30H           ; Change to ASCII data.
        LD      (DE),A          ; Set ASCII data.
        INC     DE              ; Setting pointer update.
        RET                     ;
;
;
;
CURSOFF:
        DEFB      1BH,'2',00H             ; Cursor off data.
CURSON:
        DEFB      1BH,'3'00H              ; Cursor on data.
;
MSG01:
        DEFB      0CH
        DEFB      'Present date is         .',0DH,0AH
        DEFB      'Present time is         .'
        DEFB      00H
MSG02:
        DEFB      1BH,'=',20H,30H         ; Direct cursor.
DATE:
        DEFB      '00/00/00'
        DEFB      1BH,'=',21H,30H         ; Direct cursor.
TIME:
        DEFB      '00:00:00'
        DEFB      00H
;
;
NTIME:
        DEFS      7
OTIME:
        DEFS      7
;
        END
