;       ********************************************************
;               BIOS CALL SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
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
WBOOT           EQU     0EB03H          ; WBOOT BIOS entry address
CONST           EQU     WBOOT   +03H    ; CONST BIOS entry address
CONIN           EQU     WBOOT   +06H    ; CONIN BIOS entry address
CONOUT          EQU     WBOOT   +09H    ; CONOUT BIOS entry address
RSIOX           EQU     WBOOT   +51H    ; RSIOX BIOS entry address
CALLX           EQU     WBOOT   +66H    ; CALLX BIOS entry address
;
RSOPN           EQU     10H             ; RS232C OPEN function
RSCLS           EQU     20H             ; CLOSE function
RSIST           EQU     30H             ; INPUT STATUS function
RSOST           EQU     40H             ; OUTPUT STATUS function
RSGET           EQU     50H             ; GET function
RSPUT           EQU     60H             ; PUT function
RSERR           EQU     90H             ; ERROR STATUS function
;
SRSADR          EQU     0EF31H          ; System serial parameter.
DISBNK          EQU     0F52EH          ; Destination bank area
;
HELP            EQU     00H             ; HELP code
CR              EQU     0DH             ; Carriage return code
LF              EQU     0AH             ; Line feed code
ESC             EQU     1BH             ; Escape code
TAB             EQU     09H             ; Tab code
;
XUSRSCRN        EQU     003CH           ; Change to system screen.
XSYSSCRN        EQU     003FH           ; Change to user screen.


;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
START:
        LD      SP,1000H        ; Set stack pointer.
;
        LD      HL,SRSADR       ; Copy open parameter from system area.
        LD      DE,OPNPRM       ; Application parameter area.
        LD      BC,9            ; Parameter number.
        LDIR                    ; Copy.
;
        LD      HL,OPENPRM      ; Open parameter.
        LD      B,RSOPN         ; RS232C open function.
        CALL    RSIOX           ; OPEN.
        OR      A               ; Error return?
        JP      NZ,WBOOT        ; Yes, then WBOOT.
;
KEYCHK:
        CALL    CONST           ; Get key inputed status.
        INC     A               ; Input any key?
        CALL    Z,PUT           ; Yes, then put the data.
;
        LD      HL,OPNPRM       ; Get input status.
        LD      B,RSIST         ;  Input status function.
        CALL    RSIOX           ;  Get input status.
        INC     A               ; If there is receiving data,
        CALL    Z,GET           ;  then get the data.
        JR      KEYCHK          ; Loop.
;
PEND:
        LD      B,RSCLS         ; Close RSIOX.
        CALL    RSIOX           ;
        JP      WBOOT           ; Program end.
;
;       ********************************************************
;               PUT INPUTED DATA TO RS232C
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
;               If inputed data is BREAK key, this program
;                ends.
;               If inputed data is HELP key, put from '0'
;                to '9' to RS232C.
;
;

PUT:
        CALL    CONIN           ; Get inputed data.
        LD      C,A             ;
        CP      03H             ; If inputed key is BREAK,
        JP      Z,WBOOT         ;  then end of program.
;
        CP      HELP            ; If inputed key is HELP,
        JP      Z,SEND          ;  then send '0' to '9'.
        PUSH    BC              ; Save input key code.
;
        PUSH    BC              ; Save input key code.
        CP      CR              ; If inputed key is RETURN,
        LD      C,LF            ;  then LF console out.
        CALL    Z,CONOUT        ;
        POP     BC              ; Restore input key code.
        CALL    CONOUT          ; Console out inputing data.
;
        LD      B,RSERR         ; Get error statys.
        CALL    RSIOX           ;
        AND     01110100B       ; If error is happened,
        CALL    NZ,RGSDSP       ;  then display the error status.
;
        POP     BC              ; Restore the input key code.
        LD      HL,OPNPRM       ; Put inputing data to RS232C.
        LD      B,RSPUT         ;  Put function code.
        CALL    RSIOX           ;  Put data.
        CALL    NZ,RGSDSP       ; If error return, then display error.
        RET                     ;
;
;       ********************************************************
;               SEND '0' TO '9'
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
;               If HELP key is pressed, then return.
;
SEND:
        LD      C,'0'           ; Start character code.
SEND10:
        PUSH    BC              ; Save send data.
        LD      HL,OPNPRM       ; Put data to RS232C.
        LD      B,RSPUT         ;  Put function.
        CALL    RSIOX           ; Put.
        POP     BC              ; Restore send data.
        INC     C               ; Send data update.
        LD      A,'9'+1         ; Send '0' to '9'?
        CP      C               ;
        JR      NZ,SEND10       ; No.
;
        CALL    CONST           ; Check input status.
        OR      A               ; No key is pressed?
        JR      Z,SEND          ; Yes.
        CALL    CONIN           ; Get pressed key code.
        CP      HELP            ; HELP key is pressed?
        JR      NZ,SEND         ; No.
        RET                     ;
;                    ;
;
;       ********************************************************
;               GET RECEIVED DATA
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
GET:
        LD      B,RSERR         ; Check error status.
        CALL    RSIOX           ; Get error status.
        AND     01110100B       ; Error is happened?
        CALL    NZ,RGSDSP       ; Yes, then display error.
;
        LD      HL,OPNPRM       ; Get received data.
        LD      B,RSGET         ;  Get function code.
        CALL    RSIOX           ;  Get.
        CALL    NZ,RGSDSP       ; If error, then display error.
;
        LD      C,A             ; Console out received data.
        CALL    RVSON           ; Reverse on.
        CALL    CONOUT          ; Display received data.
        CALL    RVSOFF          ; Reverse off.
        RET
;
;       ********************************************************
;               REVERSE MODE ON
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               BC
;
;       CAUTION :
;
RVSON:
        PUSH    BC              ; Save BC register.
        LD      C,ESC           ; Reverse on command.
        CALL    CONOUT          ;  ESC + '0'
        LD      C,'0'           ;
        CALL    CONOUT          ;
        POP     BC              ; Restore BC register.
        RET                     ;
;
;       ********************************************************
;               REVERSE MODE OFF
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               BC
;
;       CAUTION :
;        
RVSOFF:
        PUSH    BC              ; Save BC register.
        LD      C,ESC           ; Reverse off command.
        CALL    CONOUT          ;  ESC + '1'
        LD      C,'1'           ;
        CALL    CONOUT          ;
        POP     BC              ; Restore BC register.
        RET   
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
;       CAUTION :
;        
MSGDSP:
        LD      A,(HL)          ; Get display data.
        OR      A               ; Data is end code?
        RET     Z               ; Yes.
;
        LD      C,A             ;
        PUSH    HL              ; Save data address.
        CALL    CONOUT          ; Console out the data.
        POP     HL              ; Restore data address.
        INC     HL              ; Data address update.
        JR      MSGDSP          ; Loop.
;
;       ********************************************************
;               DISPLAY REGISTERS
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               All registers
;
;       CAUTION :
;
RGSDSP:
        PUSH    AF              ; Save all registers.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        PUSH    AF              ; Save display resisters.
        PUSH    BC              ;
        PUSH    DE              ;
        PUSH    HL              ;
;
        LD      IX,XSYSSCRN     ; Change to system screen.
        LD      A,0FFH          ;  Set system bank.
        LD      (DISBNK),A      ;
        CALL    CALLX           ;  Call OS jump table.
;
        LD      C,0CH           ; Clear screen & home.
        CALL    CONOUT          ;
;
        LD      HL,HLDSP        ; HL register display.
        POP     BC              ;  HL register data.
        CALL    BINASC          ;  Convert binary to ASCII.
        LD      HL,DEDSP        ; DE register display.
        POP     BC              ;  DE register data.
        CALL    BINASC          ;  Convert binary to ASCII.
        LD      HL,BCDSP        ; BC register display.
        POP     BC              ;  BC register data.
        CALL    BINASC          ;  Convert binary to ASCII.
        LD      HL,AFDSP        ; AF register display.
        POP     BC              ;  AF register data.
        CALL    BINASC          ;  Convert binary to ASCII.
;
        LD      HL,DTDSP        ; Return information area display.
        LD      DE,(OPNPRM)     ;
        CALL    BINASC0         ;
        LD      DE,(OPNPRM+2)   ;
        CALL    BINASC0         ;
        LD      DE,(OPNPRM+4)   ;
        CALL    BINASC0         ;
        LD      DE,(OPNPRM+6)   ;
        CALL    BINASC0         ;
        LD      DE,(OPNPRM+8)   ;
        LD      D,0             ;
        CALL    BINASC0         ;
;
        LD      HL,RGSMSG       ; Message display.
        CALL    MSGDSP          ;
RETRY:
        CALL    CONIN           ; Key input.
        CP      HELP            ; HELP key?
        JR      NZ,RETRY        ; No.
;
DSPEND:
        LD      IX,XUSRSCRN     ; Change to user screen.
        LD      A,OFFH          ;  OS bank.
        LD      (DISBNK),A      ;
        CALL    CALLX           ;
;
        POP     HL              ; Restore registers.
        POP     DE              ;
        POP     BC              ;
        POP     AF              ;
;
;       ********************************************************
;               CHANGE BINARY TO ASCII
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               BC : Binary data.
;               HL : ASCII data setting address.
;       <> return parameter <>
;               HL : HL + 2
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
BINASC0:
        LD      B,E             ; E --> B
        LD      C,D             ; D --> C
;
BINASC:
        LD      A,B             ; Change B register.
        CALL    BIN10           ; Convert.
        LD      A,C             ; Change C register.
;
BIN10:
        PUSH    AF              ; Save binary data.
        RRA                     ; Shift 4 bit.
        RRA                     ;
        RRA                     ;
        RRA                     ;
        CALL    CONV00          ; Binary --> ASCII
        POP     AF              ; Restore binary data.
;
CONV00:
        AND     0FH             ; LSB 4 bit.
        CP      10              ; 0 -- 9 ?
        JR      C,CONV20        ; Yes.
        SUB     9               ; Change 'A' to 'F'.
        OR      01000000B       ; 
        JR      CONV25          ;
CONV20:
        OR      00110000B       ; Change '0' to '9'.
CONV25:
        LD      (HL),A          ; Set converted data to (hl).
        INC     HL              ; Pointer update.
        RET                     ;
;
;       ********************************************************
;               MESSAGE DATA
;       ********************************************************
;
RGSMSG:
        DB      CR,LF
        DB      'Parameter display',CR,LF
        DB      'HL -- '
HLDSP:
        DS      4
        DB      TAB
        DB      'DE -- '
DEDSP:
        DS      4
        DB      CR,LF
        DB      'BC -- '
BCDSP:
        DS      4
        DB      TAB
        DB      'AF -- '
AFDSP:
        DS      4
        DB      CR,LF
DTDSP:
        DS      20
        DB      CR,LF
        DB      'Press HELP to continue'
        DB      0
;
;       ********************************************************
;               WORK DATA
;       ********************************************************
;
OPNPRM:
        DS      9               ; RSIOX open parameter area.
;
        END
