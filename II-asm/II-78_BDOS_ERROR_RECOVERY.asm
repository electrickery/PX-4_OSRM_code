;       ****************************************************************
;               BDOS ERROR RECOVERY SAMPLE PROGRAM
;       ****************************************************************
;
;       NOTE:
;       <> assemble condition <>
;
;        .Z80
;
;       <> loading address <>
;
			ORG		0100h	;	.PHASE  100H
;
;       <> constant values <>
;
SETERR          EQU     00012H          ; SETERR routine address
RSTERR          EQU     00015H          ; RSTERR routine address
;
WBOOT           EQU     0EB03H          ; WBOOT entry address
CONIN           EQU     0EB09H          ; CONIN entry address
CONOUT          EQU     0EB0CH          ; CONOUT entry address
LDIRX           EQU     0EB63H          ; LDIRX entry address
CALLX           EQU     0EB69H          ; CALLX entry address
;
RBDOS1          EQU     00005H          ; RBDOS1 entry address
RBDOS2          EQU     0FF90H          ; RBDOS2 entry address
;
BIOSERROR       EQU     0F52BH          ; BIOS error information
DISBNK          EQU     0F52EH          ; Distination bank
;
MAINSP          EQU     1000H           ; Stack pointer
BDOSSP          EQU     1000H           ; Stack pointer
;
;       ********************************************************
;               SELECT BDOS ERROR RECOVER
;       ********************************************************
START:
        LD      SP,MAINSP       ; Set stack pointer.
        ;
        CALL    SELERR          ; Select error recovery type.
LOOP:
;
;       ********************************************************
;               USER PROGRAM
;       ********************************************************
;
;       NOTE :
;               This part is user program.
;
        JP      LOOP            ; Loop permanent.
;
;       ********************************************************
;               SELECT BDOS ERROR RECOVERY
;       ********************************************************
;
;       NOTE :
;               Select BDOS error recovery type.
;                1. Using SETERR and RSTERR
;                2. Replacing BDOS error vector
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If BREAK key is pressed, then WBOOT
;
SELERR:
        LD      HL,MSG01        ; Select error recover message.
        CALL    DSPMSG          ; Display message.
;
        CALL    KEYIN           ; Get input key code.
        SUB     31H             ; Use SETERR?
        JR      Z,ERR010        ; Yes.
        DEC     A               ; Using error vector?
        JR      Z,ERR100        ; Yes.
        JR      SELERR          ; Others, then retry.
;
;       CALL SETERR ROUTINE.
;
ERR010:
        LD      IX,SETERR       ; Set calling address.
        LD      A,0FFH          ; Select system bank.
        LD      (DISBNK),A      
        CALL    CALLX           ; Call SETERR.
        RET
;
;       CHANGE ERROR VECTOR.
;
ERR100:
        LD      HL,VECTOR       ; New vector address.
        LD      DE,(RBDOS1+1)   ; Get vector address.
        INC     DE              ;  RBDOS top addr. + 3
        INC     DE              ;
        INC     DE              ;
        LD      BC,0008H        ; Transmite byte no.
        LD      A,00H           ; Select bank 0 (RAM bank).
        CALL    LDIRX           ; Change error vector.
        RET
;       ********************************************************
;               DISPLAY MESSAGE
;       ********************************************************
;
;       NOTE :
;               Display message until fine  00H.
;
;       <> entry parameter <>
;               HL : Message data top address
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
DSPMSG:
        LD      A,(HL)          ; get data 1 byte.
        OR      A               ; End of data?
        RET     Z               ; Yes.
;
        LD      C,A             ; Set display data.
        PUSH    HL              ; Save pointer.
        CALL    CONOUT          ; Display message 1 byte.
        POP     HL              ; Restore pointer.
        INC     HL              ; Update pointer.
        JR      DSPMSG          ; Loop until find 0.
;
;       ********************************************************
;               INPUT A KEY DATA
;       ********************************************************
;
;       NOTE :
;               Get inputed key data.
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If BREAK key is pressed, then WBOOT
;
KEYIN:
        CALL    CONIN           ; Get inputed key code.
        CP      03H             ; Break code?
        JP      Z,WBOOT         ; Yes, then WBOOT.
;
;       ********************************************************
;               BDOS ERROR RECOVERY
;       ********************************************************
;
;       NOTE :
;               BDOS  error recovery
;
;       <> entry parameter <>
;               H   : Error type 1
;               A   : Error type 2
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If BREAK key is pressed, then WBOOT
;
ERRCHK:
        LD      C,A             ; Save return code.
        LD      A,H             ; Error type.
        OR      A               ; Normal end?
        JR      Z,BDOSER        ; Yes.
;
        DEC     A               ; Bad sector?
        JR      Z,BADSEC        ; Yes.
        DEC     A               ; Bad select?
        JR      Z,BADSEL        ; Yes.
        DEC     A               ; Read only disk?
        JR      Z,RODISK        ; Yes.
        DEC     A               ; Read only file?
        JR      Z,ROFILE        ; Yes.
        DEC     A               ; Micro cassette error?
        JR      Z,MCTERR        ; Yes.
        RET                     ; opcode missing, buy binary value present (II-79)
;
;       BDOS ERROR INFORMATION.
;
BDOSER:
        PUSH    BC              ; Save return code.
        LD      HL,MSG04        ; BDOS error code message.
        CALL    DSPMSG          ; Display message.
        POP     BC              ; Restore return code.
;
        LD      A,30H           ; Change error code to ASCII.
        ADD     A,C             ;  Return code + 30H
        LD      C,A             ; 
        CALL    CONOUT          ; Display return code.
        CALL    KEYIN           ; Input any key.
        RET
;
;       BAD SECTOR
;
BADSEC:
        LD      A,(BIOSERROR)   ; BIOS error type.
        ADD     A,A             ; Get message address.
        LD      HL,MSG05        ; Message table top address.
        LD      B,00H           ; Get target pointer.
        LD      C,A             ; 
        ADD     HL,BC           ;
        LD      E,(HL)          ; Get target message address.
        INC     HL              ;
        LD      D,(HL)          ; 
        EX      DE,HL           ; Set message address to HL.
        CALL    DSPMSG          ; Display message.
        CALL    KEYIN           ; Input any key.
        RET
;
;       BAD SELECT.
;
BADSEL:
        LD      HL,MSG06        ; Bad select message.
        CALL    DSPMSG          ; Display message.
        CALL    KEYIN           ; Input any key.
        RET
;
;       READ ONLY DISK.
;
RODISK:
        LD      HL,MSG07        ; Read only disk message.
        CALL    DSPMSG          ; Display message.
        CALL    KEYIN           ; Input any key.
        RET
;
;       READ ONLY FILE.
;
ROFILE:
        LD      HL,MSG08        ; Read only file message.
        CALL    DSPMSG          ; Display message.
        CALL    KEYIN           ; Input any key.
        RET
;
;       MICRO CASSETTE ERROR.
;
MCTERR:
        LD      HL,MSG09        ; Micro cassette error message.
        CALL    DSPMSG          ; Display message.
        CALL    KEYIN           ; Input any key.
        RET
;
;       
;
XBADSEC:
        LD      SP,BDOSSP       ; Set stack pointer.
        CALL    BADSEC          ; Bad sector error.
        JP      LOOP            ; Return to user program.
XBADSEL:
        LD      SP,BDOSSP       ; Set stack pointer.
        CALL    BADSEL          ; Bad select error.
        JP      LOOP            ; Return to user program.
XRODISK:
        LD      SP,BDOSSP       ; Set stack pointer.
        CALL    RODISK          ; Read only disk error.
        JP      LOOP            ; Return to user program.
XROFILE:
        LD      SP,BDOSSP       ; Set stack pointer.
        CALL    ROFILE          ; Read only file error.
        JP      LOOP            ; Return to user program.
;
;       NEW ERROR VECTOR
;
VECTOR:
        DEFW    XBADSEC         ; Bad sector
        DEFW    XBADSEL         ; Bad select
        DEFW    XRODISK         ; Read only disk
        DEFW    XROFILE         ; Read only file
;
;       MESSAGE
;
MSG01:
        DEFB    0CH
        DEFB    'Select BDOS error recover type.', 0DH,0AH
        DEFB    '  1 -- Using SETERR',0DH,0AH
        DEFB    '  2 -- Replacing error vector',0DH,0AH
        DEFB    00H
MSG04:
        DEFB    0DH,0AH
        DEFB    'BDOS return code is '
        DEFB    00H
MSG05:
        DEFW    MSG050
        DEFW    MSG051
        DEFW    MSG052
        DEFW    MSG053
        DEFW    MSG054
        DEFW    MSG055
        DEFW    MSG056
        DEFW    MSG057
MSG050:
        DEFB    0DH,0AH
        DEFB    'Normal return.',0DH,0AH
        DEFB    00H
MSG051:
        DEFB    0DH,0AH
        DEFB    'Read error.',0DH,0AH
        DEFB    00H
       
MSG052:
        DEFB    0DH,0AH
        DEFB    'Write error.',0DH,0AH
        DEFB    00H
MSG053:
        DEFB    0DH,0AH
        DEFB    'Write protect error.',0DH,0AH
        DEFB    00H
MSG054:
        DEFB    0DH,0AH
        DEFB    'Time over error.',0DH,0AH
        DEFB    00H
MSG055:
        DEFB    0DH,0AH
        DEFB    'Seek error.',0DH,0AH
        DEFB    00H
MSG056:
        DEFB    0DH,0AH
        DEFB    'Break error.',0DH,0AH
        DEFB    00H
MSG057:
        DEFB    0DH,0AH
        DEFB    'Power off error.',0DH,0AH
        DEFB    00H
        
MSG06:
        DEFB    0DH,0AH
        DEFB    'Bad select.',0DH,0AH
        DEFB    00H

MSG07:
        DEFB    0DH,0AH
        DEFB    'Read only disk.',0DH,0AH
        DEFB    00H

MSG08:
        DEFB    0DH,0AH
        DEFB    'Read only file.',0DH,0AH
        DEFB    00H

MSG09:
        DEFB    0DH,0AH
        DEFB    'Micro cassette error.',0DH,0AH
        DEFB    00H

        END
