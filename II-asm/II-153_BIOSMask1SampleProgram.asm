;       ********************************************************
;               BIOS MASK1 SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is that all interrupt
;               makes disable except for STOP key inputing.
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
MASKI           EQU     0EB5AH  ; MASK1 entry address.
WBOOT           EQU     0EB03H  ; WBOOT entry address.
CONIN           EQU     0EB09H  ; CONIN entry address.
;
MAINSP          EQU     1000H   ; Stack pointer.
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;
START:
        LD      SP,MAINSP       ; Set stack pointer.
;
        LD      B,80H           ; Get current interrupt status.
        CALL    MASKI           ; 
        PUSH    BC              ; Save current interrupt status.
;
        LD      A,C             ; Disable all key interrupt except
        AND     11111100B       ;  STOP key. 
        OR      00000001B       ;
        LD      C,A             ;
        CALL    MASKI           ; Set new interrupt status.
;
;       Application inserts the process in the part
;        which needs to disable interrupt.
;       In case of this sample program, STOP key onle can input.
;
        CALL    CONIN           ; Key in. (Only STOP key)
;
        POP     BC              ; Restore interrupt status.
        CALL    MASKI           ; Restore old interrupt.
;
        JP      WBOOT           ; Jump WBOOT.
;
        END
