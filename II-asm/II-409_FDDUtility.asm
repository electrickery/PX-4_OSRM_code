;       ********************************************************
;               FDD UTILITY (READ SECTOR)
;       ********************************************************
;
;       NOTE :
;               This sample program is using EPSP
;               utilities.

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
WBOOT           EQU     0EB03H          ; Warm Boot entry
CONST           EQU     WBOOT   +03H    ; Console status entry
CONIN           EQU     WBOOT   +06H    ; Console in entry
CONOUT          EQU     WBOOT   +06H    ; Console out entry
CALLX           EQU     WBOOT   +66H    ; Call extra entry
;
;       System area
;
DISBNK          EQU     0F52EH          ;
PKT_TOP         EQU     0F931H          ;
PKT_FMT         EQU     PKT_TOP
PKT_RDT         EQU     0F936H
SCRCH_BUF       EQU     0F93AH          ;
PKT_STS         EQU     0F9B6H
;
;       Bank value
;
SYSBANK         EQU     0FFH            ; System bank
BANK0           EQU     000H            ; Bank 0 (RAM)
BANK1           EQU     001H            ; Bank 1 (ROM capsel 1)
BANK2           EQU     002H            ; Bank 2 (ROM capsel  2)
;
;       OS ROM jump table
;
EPSPSND         EQU     0030H
EPSPRCV         EQU     0033H
;
;
DID             EQU     31H
SID             EQU     23H
FNC             EQU     77H
SIZ             EQU     02H
;
;
BREAKKEY        EQU     03H     ;BREAK key code
LF              EQU     0AH     ;Line Feed code
CR              EQU     0DH     ;Carriage return code
SPCCD           EQU     20H     ;Space code
PERIOD          EQU     2EH     ;Period code
QMARK           EQU     3FH     ;Question mark code (3FH)
;
;
TERMINATOR      EQU     00H     ;Terminator code
;
;       BDOS function code table.
;
SPWK            EQU     01000H          ;SP bottom address
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               Read FDD block & display the data.
MAIN:
        LD      SP,SPWK         ;Set Stack pointer
;
READ:
        CALL    BREAKCHK        ;Check BREAK key (CTRL/C) press or not
        JP      NZ,ABORT
;
        CALL    SENDCMD         ;Send command to FDD.
        JP      NZ,DISKERR      ; Disk access error.
;
        LD      A,(PRT_STS)     ; Return parameter.
        OR      A               ;
        JR      NZ,READERR      ; Read error.
;
        CALL    PRDATA          ; Display FDD data.
;
        CALL    SETNEXT
        JR      NC,READ         ;Repeat FDD read until reached end.
        JP      WBOOT
;
;       ********************************************************
;               SEND READ-COMMAND AND 1 SECTOR READ
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               Same as EPSPSND
;       <> preserved registers <>
;               NON
;
;       CAUTION :
SENDCMD:
        LD      HL,PKT_FMR      ; EPSP packet top address.
        XOR     A               ;  Set FMT code.
        LD      (HL),A          ;
        INC     HL              ;
        LD      (HL),DID        ;  Set DID code.
        INC     HL              ;
        LD      (HL),SID        ;  Set SID code.
        INC     HL              ;
        LD      (HL),FNC        ;  Set FNC code.
        INC     HL              ;
        LD      (HL),SIZ        ;  Set SIZ data.
        INC     HL              ;
        LD      A,(SEKDSK)      ;  Set drive code.
        LD      (HL),A          ;
        INC     HL              ;
        LD      A,(SECTRK)      ;  Set seek track number.
        LD      (HL),A          ;
        INC     HL              ;
        LD      A,(SEKSEC)      ;  Set seek sector number.
        LD      (HL),A          ;
;
        LD      A,SYSBANK       ; Select OS bank.
        LD      (DISBNK),A      ;
        LD      IX,EPSPSND      ; Call address (EPSP send)
        LD      A,01H           ; Receive after send.
        LD      HL,PKT_TOP      ; Packet top address.
        CALL    CALLX           ; Go !!
;
        RET
;
;       ********************************************************
;               COUNT UP TRACK/SECTOR
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               CY : Return information
;                  =0 -- Normal end.
;                  =1 -- End of floppy
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
SETNEXT:
        LD      A,(SECSEC)      ; Sector number increment.
        INC     A               ;
        LD      (SEKSEC),A      ;
        CP      65              ;  Larger than 64?
        CCF                     ;
        RET     NC              ;  No.
        LD      A,01H           ; Set initial value.
        LD      (SEKSEC),A      ;
;
        LD      A,(SECTRK)      ; Track number increment.
        INC     A               ;
        LD      (SECTRK),A      ;
        CP      10              ;  Larger than 9?
        CCF                     ;
        RET                     ;
;
;********************************
;*                              *
;*      ERROR ROUTINE           *
;*                              *
;********************************
;
DISKERR:
        LD      HL,DKERRMSG     ;FDD access error message.
        CALL    DSPMSG
        JP      WBOOT
READERR:
        LD      HL,RDERRMSG     ;FDD read error message.
        CALL    DSPMSG
        JP      WBOOT
ABORT:
        LD      HL,ABORTMSG     ;Display ABORT message.
        CALL    DSPMSG
        JP      WBOOT
;
;
;*****************
;*   PRDATA   *
;*****************
;
;       Display FDD data (128 byte) by HEX format.        
;
;       on entry :
;       on exit  : none
;
;       Registers are not preserved.
;
PRDATA:
        LD      HL,TRKMSG       ;Track number.
        CALL    DSPMSG
        LD      IX,SEKTRK
        LD      (READPTR),IX
        LD      B,1             ;Display data quantity
        CALL    DSPDATA         ;Display track number.
;
        LD     HL,SECMSG        ;Sector number
        CALL    DSPMSG
        LD      IX,SEKSEC
        LD      (READPTR),IX
        LD      B,1             ;Display data quantity
        CALL    DSPDATA         ; Display sector number.
        LD      HL,CRLF
        CALL    DSPMSG          ;Line feed
;
        LD      IX,PKT_RDT
        LD      (READPTR),IX    ;Read data top address
        LD      B,8             ;Display 16 byte data on each line
;                               ;therefore it takes 8 line to list out
;                               ;128 byte data
PRDT00:
        PUSH    BC
        LD      B,16
        CALL    DSPDATA         ;FDD data (16 byte)
;
        LD      C,SPCCD
        CALL    CONOUT
        LD      HL,CHRPKT       ;Character image of FDD data, then stored
        CALL    DSPMSG          ; behind CHRPKT
;
        LD      HL,CRLF
        CALL    DSPMSG          ;Line feed
;
        CALL    CHKWAIT         ;Wait next go.
        POP     BC
        DJNZ    PRDT00          ;Repeat PRMCTDT until B=0
;
        RET
;
;*************
;*   DSPMSG   *
;*************
;
;       Display string data to the console until find 00H.
;
;       on entry : HL = Top address of string data
;                       Data 00H is a terminator of string.
;
;       on exit  : none
;
;       Registers are not preserved.
;
DSPMSG:
        LD      A,(HL)          ;Display data
        OR      A               ;Check terminator
        RET     Z               ;If find terminator then Return
;
        PUSH    HL
        LD      C,A
        CALL    CONOUT          ;Display data to the console
        POP     HL
        INC     HL              ;Update pointer
        JR      DSPMSG          ;Repeat DSPMSG until find terminator
;
;
;***************
;*   DSPDATA   *
;***************
;
;       Convert 1 byte data, that addressed by IX, to HET format and
;       LIST out it to printer. And store character image of data to
;       CHRPKT.
;
;       on entry : B = Data quantity that to be LIST out
;                  (READPTR) = Indicate data address
;
;       on exit  : (READPTR) = Next data address
;                  Character image of datas are stored behind CHRPKT.
;
;       Registers are not preserved.
;
DSPDATA:
        LD      A,8
        OR      A
        RET     Z               ;If data quqntity = 0 then return
;
        LD      HL,CHRPKT       ;HL=Start address of character data
        LD      IX,)READPTR)    ;IX=MCT data top address
DSPDT00:
        PUSH    BC
        PUSH    HL
        PUSH    IX
;
        LD      A,(IX)          ;A=DATA
        LD      (HL),PERIOD     ;Store PERIOD mark (default data)
        BIT     7,A             ;If data is 80H through FFH or 00H through
        CP      SPCCD           ;1FH then change to PERIOD mark and store
        JR      C,DSPDT10       ;it in CHRPKT
        LD      (HL),A          ;Store read data to CHRPKT
DSPDT10:
        CALL    TOHEX           ;Convert to HEX
        PUSH    BC              ;Save lower 4 bit hex data
        LD      C,B
        CALL    CONOUT          ;LIST out upper 4bit hex data
        POP     BC
        CALL    CONOUT          ;LIST   out lower 4bit hex data
        LD      C,SPCCD
        CALL    CONOUT          ;List out space
;
        POP     IX
        POP     HL
        POP     BC
        INC     HL
        INC     IX
        DJNZ    DSPDT00         ;Repeat until B=0
;
        LD      (READPTR),IX    ;Store next data address
        LD      (HL),TERMINATOR ;Store terminator of character data
;
        RET
;
;*************
;*   TOHEX   *
;*************
;
;       Convert input data (A reg) to 2 byte HEX data (BC reg)
;
;       on entry :  A = input data
;
;       on exit  : BC = HEX data of input data
;                       (B = upper 4bit data)
;                       (C = lower 4bit data)
;
TOHEX:
        PUSH    AF
;
        RRA                     ;Shift upper4bit to lower 4 bit
        RRA
        RRA
        RRA
;
        CALL    TOHEX10         ;Convert upper 4bit
        LD      B,A
;
        POP     AF              ;Convert lower 4bit
        CALL    TOHEX10
        LD      C,A
        RET
;
;
;***************
;*   TOHEX10   *
;***************
;
;       Convert lower 4bit of input data to HED dat.
;
;          entry : A = input data
;       on exit  : A = HEX data of input data lower 4bit
;
TOHEX10:
        AND     0FH             ;Mask upper 4bit
        CP      0AH 
        JR      C,TOHEX20
;
        ADD     A,07H           ;If 0AH through 0FH then "A" to "F"
;
TOHEX20:
        ADD     A,30H
        RET
;
;****************
;*   BREAKCHK   *
;****************
;
;       Check BREAK key (CTRL/C) press or not
;
;       on entry : none
;
;       on exit  : Z flag = 1 --- Break key is pressed
;                         = 0 --- Break key is not pressed
;
BREAKCHK:
        CALL    CONST
        INC     A
        RET     NZ              ;If key buffer is empty the return
;
        CALL    CONIN           
        CP      BREAKKEY        ;Check bREAK key or not
        RET     Z               ;If BREAK key then return
        JR      BREAKCHK        ;Repeat BREAKCHK until buffer is empty
;
CHKWAIT:
        CALL    CONST
        INC     A
        RET     NZ
;
        CALL    CONIN
        CP      BREAKKEY
        JP      Z,WBOOT
        CP      SPCCD
        JR      NZ,CHKWAIT
;
        CALL    CONIN
        CP      BREAKKEY
        JP      Z,WBOOT
        RET
;
;
;************************
;*                      *
;*      WORK AREA       *
;*                      *
;************************
;
SEKDSK:
        DB      01H             ;
SEKTRK:
        DB      04H             ; Directory part.
SEKSEC:
        DB      01H
;
READPTR:
        DS      2               ;Pointer of READPKT
CHRPKT:
        DS      20              ;Character data packet of MCT read data
;
;************************
;*                      *
;*      MESSAGE AREA    *
;*                      *
;************************
;
CRLF:  
        DB      CR,LF
        DB      TERMINATOR
;
DKERRMSG:
        DB      CR,LF
        DB      'Floppy disk drive access error !!'
        DB      CR,LF
        DB      TERMINATOR
;
RDERRMSG:
        DB      CR,LF
        DB      'Floppy disk drive read error !!'
        DB      CR,LF
        DB      TERMINATOR
;
ABORTMSG:
        DB      CR,LF
        DB      'Aborted'
        DB      TERMINATOR
TRKMSG:
        DB      CR,LF
        DB      'Track no = '
        DB      TERMINATOR
SECMSG:
        DB      '     Sector No = '
        DB      TERMINATOR
;
;
        END
