;       ********************************************************
;               POWER OFF & ALARM CONTROL PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program shows how to control
;               power off & alarm interrupt.
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
;       BIOS entry
;
WBOOT           EQU     0EB03H          ; Warm Boot entry
CONST           EQU     WBOOT   +03H    ; Console status entry
CONIN           EQU     WBOOT   +06H    ; Console in entry
CONOUT          EQU     WBOOT   +09H    ; Console out entry
POWEROFF        EQU     WBOOT   +7BH    ; Power off entry
;
;       System area
;
YPOFDS          EQU     0EFEFH          ; Power of disable flag.
YPOFST          EQU     0EFF0H          ; Power off status.
YALMDS          EQU     0EFF1H          ; Alarm disable flag.
YALMST          EQU     0EFF2H          ; Alarm status.
BTRYFG          EQU     0EFEEH          ; Power fail status.
PWSWOFFG        EQU     0EFF0H          ; Power sw. off status.
;
;       RAM jump table
;
RSPSTBIOS       EQU     0FF96H          ; Post BIOS execute.
;
STOP            EQU     03H             ; STOP code
LF              EQU     0AH             ; Line feed
CR              EQU     0DH             ; Carriage return

;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This program is setting power off & alarm
;               alarm disable, and if key inputed, do power
;               off or alarm.
;
MAIN:
        LD      SP,1000H        ; Set stack pointer.
;
        CALL    DISABLE         ; Interrupt disable
;
MAIN10:
        LD      A,(PEND)        ; Stop key check.
        OR      A               ; Stop key pressed?
        JP      NZ,MAIN20       ; Yes.
;
        HALT                    ; Wait until interrupt happened.
        CALL    CHKINT          ; Check interrupt status.
        JR      Z,MAIN10        ; Neither power off nor alarm.
;
        PUSH    AF              ; Save interrupt information.
        CALL    KEYIN           ; Message display and key in.
        POP     AF              ; Restore interrupt information.
;
        CALL    OKINT           ; Interrupt execute.
;
MAIN20:
        CALL    ENABLE          ; Interrupt enable.
        JP      WBOOT           ; End.
;
;       ********************************************************
;               DISABLE POWER OFF & ALARM
;       ********************************************************
;
;       NOTE :
;               Disable the following system function.
;                1. Power off execute.
;                2. Alarm screen display.
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
DISABLE:
        LD      A,(YPOFDS)      ; Set power off disable.
        OR      01H             ; Bit 0 is application bit.
        LD      (YPOFDS),A      ;
;
        LD      A,(YALMDS)      ; Set alarm disable.
        OR      01H             ; Bit 0 is application bit.
        LD      (YALMDS),A      ;
        RET                     ;
;
;
;       ********************************************************
;               ENABLE POWER OFF & ALARM
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
ENABLE:
        LD      HL,YPOFDS       ; Reset my disable bit.
        RES     0,(HL)          ;
;
        LD      HL,YALMDS       ; Reset my disable bit.
        RES     0,(HL)          ;
;
        CALL    CHKINT          ; Check interrupt happened.
        RET     Z               ; No interrupt.
        CALL    OKINT           ; Interrupt execute.
;
        RET                     ;
;
;       ********************************************************
;               CHECK POWER OFF & ALARM INTERRUPT
;       ********************************************************
;
;       NOTE :
;               Check power off & alarm interrupt occurred.
;               If occurred, set the information to return
;               code.
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               Z-flag  : Return information.
;                       =0 -- Both interrupt not occurred.
;                       =1 -- Interupr occurred
;               A       : Interrupt type
;                 bit 0 : Alarm interrupt.
;                 bit 1 : Power off interrupt.
;                       ( 1=occurr, 0=not occurr)
;
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If STOP key is pressed, then sets
;               PEND flag.
;
CHKINT:
        CALL    CONST           ; Key in check.
        INC     A               ; No inputed key?
        JR      NZ,CHK10        ; No.
;
        LD      (PEND),A        ; Set program end flag.
;
CHK10:
        LD      C,00H           ; Clear return information.
;
        LD      A,(YPOFST)      ; Check power off status.
        OR      A               ; Power off occurred?
        JR      Z,CHK20         ; No.
;
        LD      HL,YPOFDS       ; Reset my disable bit.
        RES     0,(HL)          ;
;
        AND     11111110B       ; Reset my status bit.
        LD      (YFOFST),A      ;
        JR      NZ,CHK20        ; Disable by other.
;
        LD      A,C             ; Set Power-off- go bit.
        OR      02H             ;
        LD      C,A             ;
;
CHK20:
        LD      A,(YALMST)      ; Check alarm status.
        OR      A               ; Alarm occurred?
        JR      Z,CHK40         ; No.
;
        LD      HL,YALMDS       ; Reset my disable bit.
        RES     0,(HL)          ;
;
        AND     11111110B       ; Reset my status bit.
        LD      (YALMST),A      ; 
        JR      NZ,CHK40        ; Disable by other.
;
        LD      A,C             ; Set alarm-go bit.
        OR      01H             ;
        LD      C,A             ;
;
CHK40:
        LD      A,C             ; Set return information.
        OR      A               ;
        RET                     ;
;
;
;       ********************************************************
;               STATUS DISPLAY & KEY IN
;       ********************************************************
;
;       NOTE :
;               If power off or alarm occurred, then
;               display message & wait until key inputed.
;
;       <> entry parameter <>
;               A  : Interrupt type.
;                  bit 0 : alarm
;                  bit 1 : power off
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
KEYIN:
        RRCA                    ; Alarm bit --> CY
        PUSH    AF              ; Save interrupt status.
        LD      HL,MSG01        ; Alarm happen message.
        CALL    C,DSPMSG        ; Display if alarm occurred.
        POP     AF              ; Restore interrupt status.
        RRCA                    ; Power off bit --> CY
        LD      HL,MSG02        ; Power off happen message.
        CALL    C,DSPMSG        ; Display if power off occurred.
;
        LD      HL,MSG03        ; Kei in message
        CALL    DSPMSG          ;
;
        CALL    CONIN           ; Input any key.
        RET
;
;
;       ********************************************************
;               POWER OFF OR ALARM EXECUTE
;       ********************************************************
;
;       NOTE :
;               Power off or alarm execute in
;               this routine.
;
;       <> entry parameter <>
;               A  : Interrupt type.
;                  bit 0 : alarm
;                  bit 1 : power off
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
OKINT:
        PUSH    AF              ; Save interrupt information.
        BIT     1,A             ; Power off?
        JR      Z,OK20          ; No.
;
        LD      C,00H           ; Set continue power off mode.
        LD      A,(BTRYFG)      ; Power fail check.
        OR      A               ; Power fail?
        JR      NZ,OK10         ; Yes.
;
        LD      A,(PWSWOFFG)    ; Power off check.
        CP      02H             ; Continue power off?
        JR      Z,OK10          ; Yes.
;
        INC     C               ; Set restart power off.
;
OK10:
        CALL    POWEROFF        ; Go power off.
;
OK20:
        POP     AF              ; Restore interrupt information.
        BIT     0,A             ; Alarm?
        RET     Z               ; No.
;
        LD      A,(YALMST)      ; Set BIOS bit
        OR      10000000B       ;
        LD      (YALMST),A      ;
        CALL    RSPSTBIOS       ; Go alarm.
;
        RET
;
;
;       ********************************************************
;               DISPLAY MESSAGE UNTIL FIND 00H
;       ********************************************************
;
;       NOTE :
;               Power off or alarm execute in
;               this routine.
;
;       <> entry parameter <>
;               HL : Message top address.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
DSPMSG:
DSPMSG:
        LD      C,(HL)          ; Get message data.
        LD      A,C
        OR      A               ; End of message?
        RET     Z               ; Yes.
;
        PUSH    HL              ; Save pointer.
        CALL    CONOUT          ; Message display.
        POP     HL              ; Restore pointer.
        INC     HL              ; Pointer update.
        JR      DSPMSG          ; Loop
;
;       Message and work area
;
MSG01:
        DB      'Alarm interrupt occurred.'
        DB      CR,LF,00H
;
MSG02:
        DB      'Power switch off or Power fail occurred.'
        DB      CR,LF,00H
;
MSG03:
        DB      'Press any key to continue.'
        DB      CR,LF,00H
;
;
PEND:
        DB      00H
;
        END
