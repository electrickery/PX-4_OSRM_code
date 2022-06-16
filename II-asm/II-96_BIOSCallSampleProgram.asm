;       ********************************************************
;               BIOS CALL SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is consists of only
;               BIOS calling routine.
;               So, this program doesn't run by itself.
;
;       <> assemble condition <>
;
        .Z80
;
;       <> loading address <>
;
        .PHASE  100h
;
;       <> constant value <>
;
;
RBIOS1          EQU     00000H
RBIOS2          EQu     0EB03H
;
;       ********************************************************
;               BIOS CALL ROUTINE
;       ********************************************************
;
;       NOTE :
;               This routine is used for calling BIOS.
;       <> entry parameter <>
;               A    : BIOS function number * 3
;               Depending on each BIOS function.
;       <> return parameter <>
;               Depending on each BIOS function.
;       <> preserved registers <>
;               IY is used by calling address.
;
;       CAUTION :
;               If you use resident BIOS, change
;               RBIOS1 to RBIOS2
;               If Your program is ROM execute program,
;               you must use RBIOS2.
;
BIOS:
        PUSH    HL              ; Save registers
        PUSH    DE              ;
        LD      HL,(RBIOS1+1)   ; Get WBOOT entry address.
        LD      E,A             ; Function code.
        LD      D,00H           ; Get target BIOS function entry addr.
        ADD     HL,DE           ;
        PUSH    HL              ; Set target address to IY register.
        POP     IY              ;
        POP     DE              ; Restore registers.
        POP     HL              ;
        JP      (IY)            ; Jump to target BIOS function.
;
;
        END
