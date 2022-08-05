;       ********************************************************
;               BIOS PSET SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is moving VRAM data
;               right by 1 byte.
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
WBOOT           EQU     0EB03H          ; WBOOT entry address.
PSET            EQU     0EB33H          ; PSET entry address.
;
MAINSP          EQU     01000H          ; Stack pointer
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
START:
        LD      SP,MAINSP               ; Set stack pointer.
        LD      B,64                    ; Set vertical loop counter.
        LD      HL,1920                 ; Maximum VRAM byte number.
;
PLOOP1:
        PUSH    BC                      ; Save loop counter 1.
        LD      B,30-1                  ; Set horizontal loop counter.
        DEC     HL                      ; Get new destination address.
;
PLOOP2:
        PUSH    BC                      ; Save loop counter 2.
;
        LD      C,01H                   ; AND function code.
        LD      B,00H                   ; Clear destination data.
        CALL    PSET                    ; Write VRAM with 00H.
;
        DEC     HL                      ; Get source address.
        LD      C,02H                   ; OR function code.
        LD      B,00H                   ; Read VRAM data only.
        CALL    PSET                    ; Write VRAM.
;
        INC     HL                      ; Get destination address.
        LD      B,C                     ; Move reading data to setting register.
        LD      C,02H                   ; OR function code.
        CALL    PSET                    ; Write VRAM.
        
        DEC     HL                      ; Set next destination address.
        POP     BC                      ; Restore loop counter 2.
        DJNZ    PLOOP2                  ; Not 0, then loop.
;
        POP     BC                      ; Restore loop counter 1.
        DJNZ    PLOOP1                  ; Not 0, then loop.
;
        JP      WBOOT                   ; Program end.
;
        END

;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
