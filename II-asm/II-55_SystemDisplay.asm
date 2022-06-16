;       TITLE   SYSTEM DISPLAY
;       PAGE    45
;       ****************************************************************
;               SYSTEM DISPLAY BY USER CALL
;       ****************************************************************
;
;       NOTE :
;               This program simulates CTRL-HELP in software. With the
;               item keyboard installed, the CTRL-key is different.
;
;       <> assemble conditions <>
        .Z80
;
;       <> loading address <>
        .PHASE  100H
;
;       <> constant values <>
;
CTRLHELP        EQU     0F0D1H          ; CTRL/HELP function.
DISBNK          EQU     0f52EH          ; Destination bank.
;
WBOOT           EQU     0EB03H          ; WBOOT entry address
CALLX           EQU     0EB69H          ; CALLX entry address
;
MAINSP          EQU     01000H          ; Stack pointer.
;
START:
        LD      SP,MAINSP       ; Set stack pointer.
;
        LD      IX,(CTRLHELP)
        LD      A,0FFH          ; Select system bank.
        LD      (DISBNK),A      ;
        CALL    CALLX           ; Call SETERR.
        JP      WBOOT
        
        END
