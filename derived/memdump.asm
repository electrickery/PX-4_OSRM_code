;       ********************************************************
;               MEMORY DUMP SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is reading from
;               data in the target bank or ram disk
;               parts.
;               It is derived from the OSRM II-155 LOADX SAMPLE PROGRAM 
;               and II-580 1 M BIT ROM READ PROGRAM. It also has access 
;               to the External RAM Disk.

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
RAMDSK0         EQU     010H            ; RAM Disk lower half 00000-0FFFH
RAMDSK1         EQU     011H            ; RAM Disk upper half 1000H-1FFFH
RAMDSK2         EQU     012H            ; Capsule ROM lower half 20000H-2FFFFH
RAMDSK3         EQU     013H            ; Capsule ROM upper half 30000H-3FFFFH
;
P90		EQU	90H		; I/O port 90H AD0-AD7: EXTAR 0-7
P91		EQU	91H		; I/O port 91H AD8-AD15: EXTAR 8-15
P92		EQU	92H		; I/O port 92H AD16-AD18: EXTAR 16-18
P93		EQU	93H		; I/O port 93H: EXTIR, EXTOR
P94		EQU	94H		; I/O port 94H: EXTSR, EXTCR

;
ESC             EQU     1BH
EOL             EQU     05H
BS              EQU     08H
CR              EQU     0DH
LF              EQU     0AH
STOP            EQU     03H

LINEWTH         EQU     08H
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
        CALL    GETADDR         ; Get address.  Stored in (ADDR)
        JP      C,WBOOT         ; End if STOP pressed.
        
        CALL    GETBNK          ; Select bank.  Stored in (BANK)
        JP      C,WBOOT         ; End if STOP pressed.
        LD      HL,(ADDR)
        CALL    ASCDSP4
        CALL    SPACE
        LD      A,'-'
        CALL    CONOUTS
        CALL    SPACE

        LD      A,(BANK)
        CALL    ASCDSP2         ; display inputed code.
        CALL    CRLF

;
        LD      A, (BANK)       ; Banks: 0FFh, 000h-002h. RAMdsk: 010h-013h
        AND     011100000B      ; catches the 0FFh
        JR      NZ, BANKDMP     ;  when not zero
        LD      A, (BANK)
        AND     000010000B      ; catches the 000h-002h
        JR      Z, BANKDMP      ;  when zero
        JR      RAMDDMP         ; the RAM disk

BANKDMP:
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
        LD      HL,MSGBD
        CALL    DSPMSG
        LD      HL,MSG02         ; Display dump guide line.
        CALL    DSPMSG
;
DUMP01:
        LD      DE,ASCDATA      ; Getting memory save area for text.
        LD      HL,(ADDR)       ; Dump start address.
        CALL    ASCDSP4         ; Display address as HEX.
        LD      B,LINEWTH           ; Loop counter.
        LD      A,(BANK)        ; Select target bank.
        LD      C,A             ;
;
DUMP10:
        CALL    SPACE           ; Display space.
        CALL    LOADX           ; Get memory, using ADDR and BANK.
        LD      (DE),A          ; Set getting data.
        CALL    ASCDSP2         ; Display data as HEX.
        INC     HL              ; Pointer update.
        INC     DE              ;
        DJNZ    DUMP10          ; Loop LINWTH times (8 or 16).
;
        LD      (ADDR),HL       ; New address.
        CALL    SPACE           ; Display 2 spaces.
        CALL    SPACE           ;
        CALL    ASCDSPX         ; Display data as TEXT.
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
RAMDDMP:
        CALL    CHKROM          ; External RAM disk present?
        JR      NC,RAMDSKOK
        LD      HL, MSGABRT     ; No RAM disk detected at 094h.
        CALL    DSPMSG 
        CALL    CONIN           ; Wait for user key to acknowledge
        JP      MAIN10
;
RAMDSKOK:
        CALL    RDMPF
        JP      MAIN10
;
RDMPF:
        LD      HL,MSGRD
        CALL    DSPMSG
        CALL    SPACE           ; prefix a space for the 5-digit address
        LD      HL,MSG02        ; Display dump guide line.
        CALL    DSPMSG
        LD      HL,(ADDR)       ; Initialize port values from ADDR
        LD      A,L
        LD      (P90DT), A
        LD      A,H
        LD      (P91DT), A
        LD      A,(BANK)        ; Only values 10h-13h are used.
        AND     00FH
        LD      (P92DT),A       ; Set the proper 64k bank 
;
RDMP01:
        LD      A,(BANK)        ; Prefix the extra nibble for the 64k range
        CALL    NIB2HEX         ;  0, 1 for RAM; 2, 3 for 1M ROM capsule
        CALL    CONOUTS
        LD      DE,ASCDATA   
        LD      HL,(ADDR)       ; Dump start address.
        CALL    ASCDSP4         ; Display by ASCII.
        LD      B,LINEWTH       ; Loop counter.
        LD      A,(BANK)        ; Dump target bank.
        LD      C,A             ;
;        
RDMP10:
        CALL    SPACE           ; Display space.
        CALL    READROM
        LD      (DE),A          ; Set getting data.
        CALL    ASCDSP2         ; Display data as HEX.
        INC     HL              ; Pointer update.
        INC     DE              ;
        DJNZ    RDMP10          ; Loop LINEWTH times
;
        LD      (ADDR),HL
        LD      A,L
        LD      (P90DT), A
        LD      A,H
        LD      (P91DT), A
        CALL    SPACE           ; Display 2 spaces.
        CALL    SPACE           ;
        CALL    ASCDSPX         ; Display as TEXT. Using ASCDATA & LINWIDTH
;
        CALL    CONST           ; Input any key?
        INC     A               ;
        JR      NZ,RDMP01       ; No.
;
        CALL    CONIN           ; Get inputed key.
        CP      ESC             ; ESC?
        RET     Z               ; Yes.
        CP      STOP             ; STOP?
        RET     Z               ; Yes.
        CP      20H             ; Space?
        JR      NZ,RDMP01       ; No.
;
        CALL    CONIN           ; Pause dump until any key inputed.
        JR      RDMP01          ;
;
ASCDSPX:
        PUSH    AF              ; Save registers.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        LD      HL,ASCDATA      ; Save data address.
        LD      B,LINEWTH       ; Loop counter.
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
        CALL    CRLF          ;
;
        POP     HL              ; Restore registers.
        POP     DE              ;
        POP     BC              ;
        POP     AF              ;
        RET                     ;
;
;
; Convert byte in A to hex in HL and CONOUT
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
; Convert 16 bit value in HL? to HEX and CONOUT. DE 'selects' the proper nibble.
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
        SBC     HL,DE           ; Select the proper nibble
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
        RET     C               ;
        ADD     A,'A'-':'       ;  then convert to 'A' -- 'F'.
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
        CP      '5'             ; '5' will be RAM disk lower half
        LD      C,RAMDSK0
        JR      Z,GETB10  
        CP      '6'             ; '6' will be RAM disk upper half
        LD      C,RAMDSK1
        JR      Z,GETB10  
        CP      '7'             ; '7' will be RAM disk capsule ROM lower half
        LD      C,RAMDSK2
        JR      Z,GETB10  
        CP      '8'             ; '8' will be RAM disk capsule ROM upper half
        LD      C,RAMDSK3
        JR      Z,GETB10  
        JR      GETB05          ; Other inputed character.
;
GETB10:
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
        OR      A               ; set flags
        RET     Z
;
ASC10:
        PUSH    BC
        LD      A,(HL)          ; load hex char
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
        AND     11011111B       ; reset 'lower-case' bit
        SUB     7               ; 'A'-'0'+10  << this didn't work for z80asm
        RET
;        
NIB2HEX:
        AND     0FH
        ADD     A, '0'
        CP      '9'+1
        RET     C
        ADD     A, 7
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
CRLF:
        PUSH    BC
        LD      C,CR            ; Carriage return.
        CALL    CONOUT          ;
        LD      C,LF            ; Line feed.
        CALL    CONOUT          ;
        POP     BC
        RET
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
        
; Update address parts at roll-over
READROM:
        CALL    OPNRAMD
	LD	A,(P90DT)	; Last 8 bits data.
	INC	A		; 256 bytes read?
	LD	(P90DT),A	;  Set the new address.
	JR	NZ,READ50	; No.
;
	LD	A,(P91DT)	; Middle 8 bits.
	INC	A		; 256*256 bytes read?
	LD	(P91DT),A	;  Set the new address.
	JR	NZ,READ40	; No.
;
	LD	A,(P92DT)	; Top 8 bits data.
	INC	A		; Count up.
	LD	(P92DT),A	; Set the new address.
;
READ40:
	LD	A,(P90DT)	; I/O port output for setting next address.
	OUT	(P90),A		;  Last 8 bits.
	LD	A,(P91DT)	; 
	OUT	(P91),A		; Middle 8 bits.
	LD	A,(P92DT)	; 
	OUT	(P92),A		; Top 8 bits.
;
READ50:
	IN	A,(P93)		; Read ROM data.
        CALL    CLSRAMD
	RET			; 
;
CHKROM:
	IN	A,(P94)		; Get external status.
	RLA			; MSB --> CY
	RET			; 

OPNRAMD:
        PUSH    AF
        LD      A, 00000011b    ; EXTSR, (OPN + WP)
        OUT     (P94), A
        POP     AF
        RET

CLSRAMD:
        PUSH    AF
        LD      A, 00000001b    ;EXTSR, (WP)
        OUT     (P94), A
        POP     AF
        RET
;
MSG01:
        DEFB      CR,LF
        DEFB      'RAM/ROM bank & RAM disk dump program 3', CR,LF
        DEFB      00H
MSG02:
;        DEFB      'Addr 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  ASCII',CR,LF
        DEFB      'Addr 00 01 02 03 04 05 06 07  ASCII', CR,LF
        DEFB      00H
MSG03:        
        DEFB      CR,LF
        DEFB      'Input dump start address (Hex data)', CR,LF
        DEFB      '  (Exit by pressing STOP)', CR,LF
        DEFB      00H
MSG04:
        DEFB      CR,LF
        DEFB      'Select dump bank (Exit by pressing STOP)', CR,LF
        DEFB      ' 1 - System bank     2 - Bank 0 (RAM)', CR,LF
        DEFB      ' 3 - Bank 1 (RAM/B:) 4 - Bank 2 (RAM/C:)', CR,LF
        DEFB      ' 5 - RAMdisk(A:)low  6 - RAMdisk(A:)high', CR,LF
        DEFB      ' 7 - ROM low         8 - ROM high', CR,LF
        DEFB      00H
MSGBD:
        DEFB      CR,LF
        DEFB      'Memory bank dump: SYS-ROM, RAM banks', CR,LF
        DEFB      00H
        
MSGRD:
        DEFB      CR,LF
        DEFB      'RAM disk dump: Ext. RAM disk, 1MB ROM', CR,LF
        DEFB      00H
;
MSGABRT:
        DEFB      CR,LF
        DEFB      'No RAM disk at 90h-93h', CR,LF
        DEFB      00H
;        
INCNT:
        DEFS      1
INDATA:
        DEFS      2
ASCDATA:        
        DEFS      LINEWTH
ADDR:
        DEFS      2
BANK:
        DEFS      1
        
;
P90DT:
	DEFB	0FFH
P91DT:
	DEFB	0FFH
P92DT:
	DEFB	001H

        END
