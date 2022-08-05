;       ********************************************************
;               SET AUTO START STRING
;       ********************************************************
;
;       NOTE :
;               This sample program sets auto start string.
;               If '^' + character are inputed, they are
;               translated into control characater.
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
;       BDOS entry
;
BDOS            EQU     00005H  ; BDOS entry address.
;
STRING_OUT      EQU     09H     ; BDOS function.
STRING_IN       EQU     0AH     ;
;
;       BIOS entry
;
WBOOT           EQU     0EB03H          ; Warm boot entry.
AUTOST          EQU     WBOOT +81H      ; Auto start entry
;
;       System area
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This program sets auto start string,
;               whitch is inputed from keyboard.
;
MAIN:
        LD      SP,1000H        ; Set stack pointer.
;
        LD      C,STRING_OUT    ; Console out string.
        LD      DE,MSG01        ;  Message address.
        CALL    BDOS            ;
;
        LD      C,STRING_IN     ; Input into console buffer.
        LD      DE,IN_BUFF      ; Buffer address.
        CALL    BDOS            ;
;
        CALL    CHK_CTRL        ; Check control code.
;
        LD      HL,IN_BUFF+1    ; Set auto sart string.
        LD      C,01H           ;  Set.
        CALL    AUTOST          ;
;
        JP      WBOOT           ; program end.
;
;       ********************************************************
;               CHANGE ^+CHARACTER TO CONTROL CODE
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
;       CAUTION:
;
CHK_CTRL:
        LD      HL,IN_BUFF+1    ; Inputed character no. check.
        LD      A,(HL)          ;  Get inputed character no.
        OR      A               ;  No. character inputed?
        RET     Z               ;  Yes.
;
        LD      C,A             ; Char. No. --> C
        INC     HL              ; Char. data top addr. --> HL.
        LD      D,H             ; Char. data top addr. --> DE.
        LD      E,L             ;
;
CHK10:
        LD      A,(DE)          ; Get character.
        CP      '^'             ; '^' code?
        JR      Z,CHK20         ; Yes.
;
        LD      (HL),A          ; Set data.
        INC     DE              ; Get pointer update.
        INC     HL              ; Put pointer update.
        DEC     C               ; Counter decrement.
        RET     Z               ; End of char.
        JR      CHK10           ; Loop.
;
        LD      A,(DE)          ; Get character.
        SUB     40H             ; 40H to 7FH?
        JR      C,CHK10         ;
        JR      NC,CHK10        ; No.
;
        AND     11011111B       ; 00H to 1FH.
        LD      (HL),A          ; Set new data.
        INC     DE              ; Get pointer update.
        INC     HL              ; Put pointer update.
        LD      A,(IN_BUFF+1)   ; Character No. decrement.
        DEC     A               ;
        LD      (IN_BUFF+1), A  ;
        DEC     C               ; Character remain?
        RET     Z               ; No.
        JR      CHK10           ; Loop until end of char.
;
CHK20:
        INC     DE              ; Get pointer increment.
        DEC     C               ; Counter check.
        RET     Z               ; No char. exists.
;
        LD      A,(DE)          ; Get character.
        SUB     40H             ; 40H to 7FH?
        JR      C,CHK10         ; No.
        CP      40H             ;
        JR      NC,CHK10        ; No.
;
        AND     11011111B       ; 00H to 1FH.
        LD      (HL),A          ; Set new data.
        INC     DE              ; Get pointer update.
        INC     HL              ; Put pointer update.
        LD      A,(IN_BUFF+1)   ; Character No. decrement.
        DEC     A               ;
        LD      (IN_BUFF+1),A   ;
        DEC     C               ; Character remain?
        RET     Z               ; No.
        JR      CHK10           ; Loop until end of char.
;
;       Message and work area
;
MSG01:
        DB      'INPUT AUTO START STRING (Max 32 char.)'
        DB      0DH,0AH,09H,'$'
;
;
IN_BUF:
        DB      32              ; Max input character No.
        DS      1               ;  Inputed char. No. area.
        DS      32              ;  Inputed data area.
;
        END
