;       ********************************************************
;               BIOS BEEP SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is melody of 'White
;                    ' by using beep.
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
BPINTEBL        EQU     0F0F5H
;
WBOOT           EQU     0EB03H
BEEP            EQU     0EB39H
;
MAINSP          EQU     01000H
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :

START:
        LD      SP,MAINSP               ; Set stack pointer.
;
        LD      A,(BPINTEBL)            ; Get beep interrupt table.
        OR      10000000B               ; Disable 1 sec interrupt during beep.
        LD      (BPINTEBL), A           ; Set new beep interrupt table.
;
        LD      HL,SONG                 ; Set song data top address.
;
LOOP:
        LD      B,(HL)                  ; Sound type.
        INC     HL                      ; Next pointer.
        LD      C,(HL)                  ; Sound length.
        INC     HL                      ; Next pointer.
        LD      A,C                     ; If sound length is 0,
        OR      A                       ;  then end of data.
        JP      Z,WBOOT                 ; End of data, then WBOOT.
;
        PUSH    HL                      ; Save song table pointer.
        CALL    BEEP                    ; Sound.
        POP     HL                      ; Restore song table pointer.
        JR      LOOP                    ; Loop.
;
;       SONG DATA
;
SONG:
        DB      17,2, 17,2, 17,2, 17,2, 17,2, 17,2, 17,9
        DB      17,3, 20,8, 17,2, 15,2, 17,9, 17,3, 17,8
        DB      20,2, 20,2, 20,6, 20,2, 22,2, 20,2, 18,6
        DB      16,2, 18,2, 18,2, 18,6, 00,7
        DB      15,2, 15,2, 15,2, 15,2, 15,2, 15,2, 18,9
        DB      15,2, 15,2, 17,2, 17,6, 17,2, 17,2, 17,9
        DB      17,3, 17,8, 15,2, 17,2, 15,6, 13,2, 15,2
        DB      13,2, 13,18,00,6
        DB      25,2, 25,2, 25,2, 25,2, 25,2, 25,2, 25,8
        DB      24,2, 25,2, 24,3, 22,9, 22,9, 22,3, 24,2
        DB      24,2, 24,2, 24,2, 24,2, 24,2, 24,5, 22,2
        DB      24,2, 22,8, 20,2, 17,2, 20,12
        DB      25,2, 25,2, 25,2, 25,2, 25,2, 25,2, 25,6
        DB      24,2, 25,2, 24,3, 22,6, 24,3, 22,8, 22,2
        DB      22.2, 24,3, 24,8, 22,2, 20,2, 22,8, 20,2
        DB      22,2, 20,2, 20,16
        DB      00,0
        
        END


;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
