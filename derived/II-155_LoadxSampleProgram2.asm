;       ********************************************************
;               LOADX SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is reading from
;               data in the target bank.

;       <> assemble condition <>
;
;        .Z80
;
;       <> loading address <>
;
        ORG     0100H;        .PHASE  100h
;
;       <> constant values <>
;
;       BIOS entry
;
WBOOT           EQU     0EB03H          ; Warm boot entry
CONST           EQU     WBOOT   +03H
CONIN           EQU     WBOOT   +06H
CONOUT          EQU     WBOOT   +09H    ; Console out entry
LOADX           EQU     WBOOT   +5AH
;
;       Bank value
;
SYSBANK         EQU     0FFH            ; System bank
BANK0           EQU     000H            ; Bank 0 (RAM)
BANK1           EQU     001H            ; Bank 1 (ROM capse 1)
BANK2           EQU     002H            ; Bank 2 (ROM capse 2)
;
;
ESC             EQU     1BH
EOL             EQU     05H
BS              EQU     08H
CR              EQU     0DH
LF              EQU     0AH
STOP            EQU     03H

LINEWTH         EQU     10H
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;
        LD      SP,1000H        ; Set stack pointer.
;
        LD      HL,MSG01       ; Display opening message.
        CALL    DSPMSG          ;
;
MAIN10:
        CALL    GETADDR         ; Get address.
        JP      C,WBOOT         ; End if STOP pressed.
        CALL    GETBNK          ; Select bank.
        JP      C,WBOOT         ; End if STOP pressed.
;
        CALL    DUMPF           ; Dump memory.
        JR      MAIN10          ; Loop.
;
;       ********************************************************
;               DUMP FUNCTION
;       ********************************************************
;
;       NOTE :
;               Dump memory function

;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If Space bar is pressed, then stop display.
;               If ESC key is pressed, then exit this routine.
;
DUMPF:
        LD      HL,MSG02         ; Display dump guide line.
        CALL    DSPMSG
;
DUMP01:
        LD      DE,ASCDATA      ; Getting memory save area.
        LD      HL,(ADDR)       ; Dump start address.
        CALL    ASCDSP4         ; Display by ASCII.
        LD      B,LINEWTH           ; Loop counter.
        LD      A,(BANK)        ; Dump target bank.
        LD      C,A             ;
;
DUMP10:
        CALL    SPACE           ; Display space.
        CALL    LOADX           ; Get memory.
        LD      (DE),A          ; Set getting data.
        CALL    ASCDSP2         ; Display by ASCII.
        INC     HL              ; Pointer update.
        INC     DE              ;
        DJNZ    DUMP10          ; Loop LINWTH times (8 or 16).
;
        LD      (ADDR),HL       ; New address.
        CALL    SPACE           ; Display 2 spaces.
        CALL    SPACE           ;
        CALL    ASCDSPX         ; Display memory by ASCII.
;
        CALL    CONST           ; Input any key?
        INC     A               ;
        JR      NZ,DUMP01       ; No.
;
        CALL    CONIN           ; Get inputed key.
        CP      ESC             ; ESC?
        RET     Z               ; Yes.
        CP      STOP             ; STOP?
        RET     Z               ; Yes.
        CP      20H             ; Space?
        JR      NZ,DUMP01       ; No.
;
        CALL    CONIN           ; Stop dump until any key inputed.
        JR      DUMP01          ;
;
;
;
ASCDSPX:
        PUSH    AF              ; Save registers.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        LD      HL,ASCDATA      ; Save data address.
        LD      B,LINEWTH           ; Loop counter.
ASCDX1:
        LD      A,(HL)          ; Get data address.
        CP      20H             ; Control code?
        JR      NC,ASCDX2       ; No.
;
        LD      A,'.'           ; Change data to '.'.
ASCDX2:
        CALL    CONOUTS         ; Display data.
        INC     HL              ;
        DJNZ    ASCDX1          ; Loop LINWTH times (8 or 16).
;
        LD      C,CR            ; Carriage return.
        CALL    CONOUT          ;
        LD      C,LF            ; Line feed.
        CALL    CONOUT          ;
;
        POP     HL              ; Restore registers.
        POP     DE              ;
        POP     BC              ;
        POP     AF              ;
        RET                     ;
;
;
;
ASCDSP2:
        PUSH    AF              ; Save registers.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        LD      HL,0000H        ; Set binary data to HL.
        LD      L,A             ; A --> HL
        JR      ASCD42          ;
;
;
;
ASCDSP4:
        PUSH    AF              ; Save registers.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        LD      DE,4096         ; 1000H.
        CALL    ASCD45          ; Get 16**3.
        CALL    CONOUTS         ; Display data.
;
        LD      DE,256          ; 100H.
        CALL    ASCD45          ; Get 16**2.
        CALL    CONOUTS         ; Display data.
;
ASCD42:
        LD      DE,16           ; 10H.
        CALL    ASCD45          ; Get 16**1.
        CALL    CONOUTS         ; Display data.
;
        LD      A,L             ; Get 16**0.
        ADD     A,30H           ; Change to ASCII.
        LD      C,A             ;
        CALL    ASCD48          ;
        CALL    CONOUTS         ; Display data.
;
        POP     HL              ; Restore registers.
        POP     DE              ;
        POP     BC              ;
        POP     AF              ;
        RET                     ;
;
;
;
ASCD45:
        LD      C,'0'           ;
;
ASCD46:
        OR      A               ; Reset carry bit.
        SBC     HL,DE           ;
        JR      C,ASCD47        ;
;
        INC     C               ; Counter increase.
        JR      ASCD46          ; Loop.
;
ASCD47:
        ADD     HL,DE           ; Restore data.
ASCD48:
        LD      A,C             ;
        CP      ':'             ; If larger than '9'.
        RET     C               ;  then convert to 'A' -- 'F'.
        ADD     A,'A'-':'       ;
;
        RET                     ;
;
;
;       ********************************************************
;               INPUT ADDRESS DATA
;       ********************************************************
;
;       NOTE :
;               Get address data routine

;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               CY : Return information
;                  =0 -- Normal end
;                  =1 -- ESC key inputed
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
GETADDR:
        LD      HL,MSG03        ; Displays inputing address message.
        CALL    DSPMSG          ;
;
        LD      HL,INCNT        ; Inputed data counter reset.
        LD      (HL),00H        ;
        LD      DE,INDATA       ; Inputed data storage area.
;
GETA10:
        CALL    CONINS          ; Get inputed key.
        CP      STOP            ; STOP?
        SCF                     ;  Set carry flag.
        RET     Z               ; Yes.
        CP      BS              ; Back space?
        JR      Z,GETA20        ; Yes.
        CP      CR              ; Carriage return?
        JR      Z,GETA30        ; Yes.
;
        CALL    CHKHEX          ; Check HEX data.
        JR      C,GETA10        ; Not hexa data.
;
        LD      C,A             ; 
        LD      A,(HL)          ; Inputed counter check.
        CP      04H             ; Max 4 character.
        JR      NC,GETA10       ; Character over.
;
        LD      A,C             ;
        CALL    CONOUTS         ; Display inputed char.
        LD      (DE),A          ; Store data.
        INC     (HL)            ; Counter udate.
        INC     DE              ; Pointer update.
        JR      GETA10          ; Loop.
;
GETA20:
        XOR     A               ; Back space process.
        CP      (HL)            ; No inputed character?
        JR      Z,GETA10        ; Yes.
        DEC     (HL)            ; Counter decrement.
        DEC     DE              ; Pointer decrement.
        LD      A,BS            ; Cursor left.
        CALL    CONOUTS         ;
        LD      A,EOL           ; Erase end of line.
        CALL    CONOUTS         ;
        JR      GETA10          ;
;
GETA30:
        LD      B,(HL)          ; Carriage return process.
        LD      HL,INDATA       ; Change ASCII to binary.
        CALL    ASCBIN          ;
        LD      (ADDR),DE       ; Store converted data.
        OR      A               ; Carry off.
        RET                     ;
;
;
CHKHEX:
        CP      '0'             ; 00H -- 2FH?
        RET     C               ; Yes.
        CP      ':'             ; 30H -- 39H?
        CCF                     ;
        RET     NC              ; Yes.
        CP      'A'             ; 3AH -- 40H?
        RET     C               ; Yes.
        CP      'G'             ; 'A' -- 'F'?
        CCF                     ;
        RET     NC              ; Yes.
        CP      'a'             ; 47H -- 60H?
        RET     C               ; Yes.
        CP      'g'             ; 'a' -- 'f'?
        CCF                     ; ;
        RET                     ;
;
;
;       ********************************************************
;               SELECT BANK
;       ********************************************************
;
;       NOTE :
;               Select bank routine

;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               CY : Return information
;                  =0 -- Normal end
;                  =1 -- ESC key inputed
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
GETBNK:
        LD      HL,MSG04        ; Display selecting bank message.
        CALL    DSPMSG          ;
GETB05:
        CALL    CONIN           ; Key in.
        CP      STOP            ; STOP?
        SCF                     ;
        RET     Z               ; Yes.
;
        CP      '1'             ; '1' is system bank.
        LD      C,SYSBANK       ; 
        JR      Z,GETB10        ;
        CP      '2'             ; '2' is bank 0.
        LD      C,BANK0         ; 
        JR      Z,GETB10        ;
        CP      '3'             ; '3' is bank 1.
        LD      C,BANK1         ;
        JR      Z,GETB10        ;
        CP      '4'             ; '4' is bank 2.
        LD      C,BANK2         ;
        JR      Z,GETB10        ;
        JR      GETB05          ; Other inputed character.
;
GETB10:
        CALL    CONOUTS         ; display inputed code.
;
        LD      A,C             ; Set data.
        LD      (BANK),A        ;
        OR      A               ; Carry off.
        RET                     ;
;
;
;       ********************************************************
;               CHANGE ASCII TO BINARY
;       ********************************************************
;
;       NOTE :
;               Change ASCII HEX data to binary data.

;       <> entry parameter <>
;               HL : ASCII data top address.
;               B  : Data count
;       <> return parameter <>
;               DE : binary data
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
ASCBIN:
        LD      DE,0000H
        LD      A,B
        OR      A
        RET     Z
;
ASC10:
        PUSH    BC
        LD      A,(HL)
        CALL    ASC20
        LD      C,A
        LD      B,00H
        EX      DE,HL
        ADD     HL,BC
        EX      DE,HL
        POP     BC
        DEC     B
        RET     Z
;
        PUSH    BC
        LD      B,04H
ASC15:
        OR      A
        RL      E
        RL      D
        DJNZ    ASC15
;
        INC     HL
        POP     BC
        JR      ASC10
;
;
ASC20:
        SUB     '0'
        CP      0AH
        RET     C
        AND     11011111B
        SUB     'A'-'0'+10
        RET
;
;
;       ********************************************************
;               MESSAGE DISPLAY
;       ********************************************************
;
;       NOTE :
;               Display message until found 00H.
;
;       <> entry parameter <>
;               HL : ASCII data top address.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
DSPMSG:
        LD      A,(HL)
        OR      A
        RET     Z
;
        LD      C,A
        PUSH    HL
        CALL    CONOUT
        POP     HL
        INC     HL
        JR      DSPMSG
;
;
;       ********************************************************
;               CONSOLE OUT
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               A : Console out data
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               All registers
;
;       CAUTION :
;        
CONOUTS:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      C,A
CON010:
        CALL    CONOUT
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET
;
;
SPACE:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      C,20H
        JR      CON010
;
;
;       ********************************************************
;               CONSOLE IN
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               A : Console in data
;       <> preserved registers <>
;               All registers without AF
;
;       CAUTION :
;        
CONINS:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        CALL    CONIN
        POP     HL
        POP     DE
        POP     BC
        RET
;
MSG01:
        DEFB      'Start dump program',CR,LF
        DEFB      00H
MSG02:
        DEFB      CR,LF
        DEFB      CR,LF
        DEFB      'Addr 00 01 02 03 04 05 06 07  ASCII',CR,LF
        DEFB      00H
MSG03:        
        DEFB      CR,LF
        DEFB      'Input dump start address (Hexa data)',CR,LF
        DEFB      '  (Exit by pressing STOP)',CR,LF
        DEFB      00H
MSG04:
        DEFB      CR,LF
        DEFB      'Select dump bank (Exit by pressing STOP)',CR,LF
        DEFB      '  1 -- System bank   3 -- Bank 1',CR,LF
        DEFB      '  2 -- Bank 0 (RAM)  4 -- Bank 2',CR,LF
        DEFB      00H
;
INCNT:
        DEFS      1
INDATA:
        DEFS      2
ASCDATA:        
        DEFS      8
ADDR:
        DEFS      2
BANK:
        DEFS      1
;
        END
