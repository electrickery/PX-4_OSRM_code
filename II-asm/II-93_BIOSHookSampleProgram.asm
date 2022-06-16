;       ********************************************************
;               BIOS HOOK SAMPLE PROGRAM
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
BIOSHK          EQU     0FFE8H  ; BIOS hook address
;
LOADADDR        EQU     0CB00H  ; Extend BIOS load address
;
WBOOT           EQU     00000H  ; Warm boot address
;
;       ********************************************************
;               BIOS HOOK DATA WRITE
;       ********************************************************
START:
        LD      SP,MAINSP
;
        CALL    UBSZCHECK       ; Check User-BIOS size.
        JP      C,WBOOT         ; Size error, then WBOOT.
        ;
        LD      HL,LOADDATA     ; Extend BIOS routine load.
        LD      DE,LOADADDR     ;
        LD      BC,LOADSIZE     ;
        LDIR
;
        LD      HL,BIOSHK       ; Change BIOS hook data.
        LD      DE,LOADADDR     ;
        LD      (HL),E          ; Set low address.
        INC     HL              ;
        LD      (HL),D          ; Set high address.
;
        JP      WBOOT
;
;       ********************************************************
;               USER-BIOS SIZE CHECK
;       ********************************************************
;
;       NOTE :

;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               CY : return information
;                    = 0 : size O.K.
;                    = 1 : size N.G.
;       <> preserved registers <>
;               NON
;
;       <> constant values <>
USERBIOS        EQU     0EF2DH
UBSIZE          EQU     001H
;
UBSZCHECK:
;
        LD      A,(USERBIOS)    ; USER-BIOS size --> A
        CP      UBSIZE          ; Check USER-BIOS size.
        RET
;
;       ********************************************************
;               EXTEND BIOS ROUTINE
;       ********************************************************
;
;       NOTE : This routine must be loaded to 0CB00H
;
;       <> entry parameter <>
;               Depend on each BIOS parameters
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               ALL
;
;       <> constant values <>
EXBIOSSP        EQU     0CC00H          ; Extend BIOS stack area (20H)
SAVESP          EQU     EXBIOSSP-20H    ; BIOS stack save area (02H)
;
CONINF          EQU     03H             ; CONIN function number
TARGETBIOS      EQU     CONINF*3        ; Target BIOS function number
;
BIOSJPTB        EQU     00007H          ; BIOS jump table address
;
EXBIOSE         EQU     EXBIOSR-EXBIOS+LOADADDR
                                        ; EXBIOSR addr in USER-BIOS area
;
;
        LD      (SAVESP),SP             ; Save BIOS stack pointer.
        LD      SP,EXBIOSSP             ; Set new stack pointer.
        PUSH    HL                      ;Save registers to new stack.
        PUSH    DE                      ;
        PUSH    AF                      ;
;
        LD      HL,(SAVESP)             ; Get default BIOS JUMP address.
        INC     HL                      ;
        INC     HL                      ;
        LD      E,(HL)                  ;
        INC     HL                      ;
        LD      D,(HL)                  ;
;
        LD      HL,(BIOSJPTB)           ; Get BIOS jump table top addr.
        EX      DE,HL                   ;
        OR      A                       ; Carry clear.
        SBC     HL,DE                   ; Calculate offset value.
        LD      A,L
;
        CP      TARGETBIOS              ; Target BIOS call ?
        JP      NZ,EXBIOSE              ; No.
;
;
;       You can inseet your own extend-BIOS routine
;       in this part.
;
;
EXBIOSR:
        POP     AF                      ; Register restore.
        POP     DE                      ;
        POP     HL                      ;
        LD      SP,(SAVESP)             ; Recover stack pointer.
        RET
;
LOADSIZE:       EQU     $-LOADDATA      ; Extend-BIOS loading size.
;
                DS      20H             ; Stack area for main routone.
MAINSP          EQU     $
;
        END
