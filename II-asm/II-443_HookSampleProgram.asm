;       ********************************************************
;               HOOK SAMPLE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is testing hook.

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
WBOOT           EQU     0EB03H          ; Warm Boot entry
CONIN           EQU     WBOOT   +06H    ; Console in entry
CONOUT          EQU     WBOOT   +09H    ; Console out entry
CALLX           EQU     WBOOT   +66H    ; Call extra entry
RESIDENT        EQU     WBOOT   +84H    ; Resudent entry
;
;       System area
;
TOPRAM          EQU     0EF94H          ; Top of User BIOS
USERBIOS        EQU     0EF2DH          ; Size of User BIOS area
DISBNK          EQU     0F52EH          ; Destination bank for CALLX
RZIER           EQU     0F53EH          ; Interrupt enable register
;
HOOKTBL         EQU     0FFC0H          ; Hook table top address
;
;       Bank value
;
SYSBANK         EQU     0FFH            ; System bank
BANK0           EQU     000H            ; Bank 0 (RAM)
BANK1           EQU     001H            ; Bank 1 (ROM capsel 1)
BANK2           EQU     002H            ; Bank 2 (ROM capsel 2)
;
;
;
UB_HEAD         EQU     0CBF0H          ; Top addr of User BIOS area's header
UB_OVWRITE      EQU     UB_HEAD +11     ;  Over write flag
UB_RELEASE      EQU     UB_HEAD +12     ;  Release address
;
;
;       OS ROM jump table
;
BIOSJT          EQU     00006H
XUSRSCRN        EQU     0003CH
;
;       Resident jump table
;
SELBNK          EQU     0FF9CH
;
CR              EQU     0DH
LF              EQU     0AH
CLS             EQU     12H

;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               Using system hook jump program.
;
;       CAUTION:
;               This program uses User BIOS area.
;               Usually, you must check that another
;               already used this area. But this program
;               doesn't check it.
;
;               This program doesn't do resetting hook.
;               So, you wish to stop test hook, you must
;               push reset bottom.
;
MAIN:   
        JP      START           ; Program start
;
;       *****   Output message data
;
MSGX:
        DB      '*** User BIOS size error ***',CR,LF
        DB      '  Set User BIOS size to 2k bytes!!'
        DB      CR,LF
        DB      00H
;
MSG0:
        DB      CLS,00H
;
MSG1:
        DB      CR,LF
        DB      '*** Hook test program ***'
        DB      CR,LF
        DB      '   1   -- ALMHKX  test',CR,LF
        DB      '   2,3 -- Reserve     ',CR,LF
        DB      '   3   -- HK8251 test',CR,LF
        DB      '   4   -- ICFHOOK test',CR,LF
        DB      '   5   -- OVFHOOK test',CR,LF
        DB      '   6   -- EXTHOOK test',CR,LF
        DB      '   7   -- TIMDAT test',CR,LF
        DB      ' Select one of 1 to 7 -- '
        DB      00H
;
MSG3:
        DB      CR,LF
        DB      CR,LF
        DB      '***  Alarm hook test  ***'
        DB      CR,LF        
        DB      '   1 -- ALMHK1',CR,LF
        DB      '   2 -- ALMHK2',CR,LF
        DB      '   3 -- ALMHK3',CR,LF
        DB      '   4 -- ALMHK4',CR,LF
        DB      '   5 -- ALMHK5',CR,LF
        DB      ' Select one of 1 to 5 -- '
        DB      00H
;
MSG4:
        DB      CR,LF
        DB      CR,LF
        DB      '***  Interrupt hook test  ***'
        DB      CR,LF
        DB      ' When interrupt occur,',CR,LF
        DB      '  print message "interrupt".',CR,LF
        DB      00H
;
MSG5:
        DB      CR,LF
        DB      CR,LF
        DB      '***  TIMDAT test  ***'
        DB      CR,LF
        DB      ' When timedat routine call,',CR,LF
        DB      ' print message "TIMDAT".',CR,LF
        DB      '  1 -- TIMDAT83',CR,LF
        DB      '  2 -- TIMDAT85',CR,LF
        DB      '  3 -- TIMDAT86',CR,LF
        DB      ' Select one of 1 to 3 -- '
        DB      00H
;
START:
        LD      A,(USERBIOS)
        CP      08H             ; If User BIOS is smaller than 8 k.
        JP      C,SZERROR       ;  then error
;
        LD      HL,HOOK         ; Copy program data for hook
        LD      DE,(TOPRAM)     ;  from hook to topram (userbios)
        LD      BC,HOOKBTM-HOOK
        DI                      ; Interrupt disable
        LDIR
        EI
;
        LD      HL,MSG0         ; Clear screen
        CALL    DSPMSG
;
PTOP:
        LD      SP,2000H        ; Set stack pointer
;
        LD      C,01H           ; Set resident flag
        CALL    RESIDENT        ;
;
        LD      HL,MSG1         ; Message (alarm, interrupt, timdat)
        CALL    DSPMSG
;
SELECT2:
        CALL    CONINF
        JP      Z,STOPEND       ; If stop, then end
        CP      '1'
        JR      C,SELECT2       ; If select error, then retry
        JR      Z,ALARM         ; Alarm select
        CP      '6'
        JR      Z,TIMDAT        ; TIMDAT select
        JR      NC,SELECT2      ; If select error, then retry
        JR      INTERRUPT       ; else interrupt
;
;       *****   Alarm hook test *****
;
ALARM:
        LD      HL,MSG3         ; Message (alarm hook 1 -- 5)
        CALL    DSPMSG
;
SELECT3:
        CALL    CONINF
        JP      Z,STOPEND       ; If stop, then end
        CP      '1'
        JR      C,SELECT3       ; If select error, then retry
        CP      '6'
        JR      NC,SELECT3      ; If select error, then retry
;
        SUB     '1'             ; A reg. is 0..4
        JR      SETHOOK         ; Goto hook setting process
;
;       *****   Interrupt hook test     *****
;
INTERRUPT:
        PUSH    AF              ; Save selecting number
        LD      HL,MSG4
        CALL    DSPMSG          ; Interrupt hook select message
        POP     AF
        SUB     '2'
        ADD     A,05H           ; A reg. is 0..4
        JR      SETHOOK         ; Goto hook setting process
;
;       ***** TIMDAT hook test  *****
;
TIMDAT:
        LD      HL,MSG5
        CALL    DSPMSG          ; Select TIMDAT message
;
SELECT4:
        CALL    CONINF
        JP      Z,STOPEND       ; If stop, then end
        CP      '1'
        JR      C,SELECT4       ; If select error, then retry
        CP      '4'
        JR      NC,SELECT4      ; If select error, then retry
;
        SUB     '1'             ; A reg. is 0..4
        JR      SETHOOK         ; Goto hook setting process
;
;       *****   Set hook data for each select  ****
;               A -- Hook logical number (0 -- 12)
SETHOOK:
        LD      C,A             ; Get hook data addr
        ADD     A<A
        LD      D,A
        ADD     A,C
        LD      C,A
        LD      B,00H
        LD      HL,HOOKTBL
        ADD     HL,BC           ; HOOKTBL * A*3 --> HL
        PUSH    HL              ; Push target hook table
;
        LD      HL,(TOPRAM)
        ADD     A,A
        LD      C,A
        ADD     HL,BC           ; (TOPRAM) + A*6 --> HL
        EX      DE,HL
;
        POP     HL              ; Set hook jump addr
        DI                      ; Interrupt disable
        INC     HL
        LD      (HL),E
        INC     HL
        LD      (HL),D
        EI
;
        JP      PTOP1
;
;       *****   User BIOS data  *****
;               This part is copyed into user bios area
HOOK:
        PUSH    HL
        LD      HL,0C400h+PDATA1-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA2-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA3-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA4-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA5-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA6-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA7-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA8-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA9-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA10-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA11-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA12-HOOK
        JR      HOOKSTART
;
        PUSH    HL
        LD      HL,0C400h+PDATA13-HOOK
        JR      HOOKSTART
;
;
HOOKSTART:
        LD      (0C400H+SAVESP-HOOK),SP
;                               ; Set stack pointer
        LD      SP,0CAEFH
;
        PUSH    HL              ; Save all registers
        PUSH    DE
        PUSH    BC
        PUSH    AF
;
        LD      A,(RZIER)       ; Interrupt disable
        PUSH    AF
        XOR     A        
        OUT     (4),A
;
        LD      C,0FFH  
        CALL    SELBNK          ; Select OS bank
        PUSH    BC              ; Save old bank information
;
;                               ; Print message
        PUSH    HL
        CALL    XUSRSCRN        ; Change to user screen
        POP     HL
;
        CALL    0C400H+SAVESP-HOOK
;
        POP     BC
        CALL    SELBANK         ; Recover old bank
;
        POP     AF              ; Recover interrupt register
        LD      (RZIER),A
        OUT     (4),A
;
        POP     AF
        POP     BC
        POP     DE
        POP     HL
;
        LD      SP,(0C400H+SAVESP-HOOK)
;                               ; Restore stack pointer
        POP     HL
        RET
;
XCONOUT:
        LD      E,0CH           ; Conout function
        JR      XPRINT0
;
XPRINT:
        LD      E,0FH           ; List function
;
XPRINT0:
        LD      C,(HL)          ; DATA --> C
        LD      A,C
        OR      A
        RET     Z               ; Data end?
;
        CALL    0C400H+ROMBIOS-HOOK
;                               ; Call ROM BIOS
        INC     HL              ; Pointer update
        JR      XPRINT0
;
;       *****   Select target rom bios  *****
;               E -- Function number
ROMBIOS:
        PUSH    HL               ; Save all registers
        PUSH    DE              
        PUSH    BC
;
        LD      HL,(BIOSJT)+1)  ; Get ROM BIOS jump addr
        LD      D,00H
        ADD     HL,DE
        LD      DE,0C400H+RETADDR-HOOK
        PUSH    DE              ; Push return addr
        JP      (HL)            ; Go!!
;
RETADDR:
        POP     BC              ; Restore all r4egisters
        POP     DE
        POP     HL
        RET
;
;
PDATA1:
        DB      'ALARM1',CR,LF,0
PDATA2:
        DB      'ALARM2',CR,LF,0
PDATA3:
        DB      'ALARM3',CR,LF,0
PDATA4:
        DB      'ALARM4',CR,LF,0
PDATA5:
        DB      'ALARM5',CR,LF,0
PDATA6:
        DB      'TMHOOK',CR,LF,0
PDATA7:
        DB      'HK8251',CR,LF,0
PDATA8:
        DB      'ICFHOOK',CR,LF,0
PDATA9:
        DB      'OVFHOOK',CR,LF,0
PDATA10:
        DB      'EXTHOOK',CR,LF,0
PDATA11:
        DB      'TIMDAT83',CR,LF,0
PDATA12:
        DB      'TIMDAT85',CR,LF,0
PDATA13:
        DB      'TIMDAT86',CR,LF,0
;
SAVESP:
        DW      0000H
;
HOOKBTM:
;
;
;
;
SZERROR:
        LD      HL,MSGX         ; Error message display
        CALL    DSPMSG
        JP      STOPEND
;
;       *****   Console input routine   *****
;
CONINF:
        CALL    CONIN           ; Console in
        CP      03H
        PUSH    AF              ; If stop, then z-flag on
        LD      C,A
        CALL    CONOUT          ; Display inputing char
        POP     AF
        RET
;
;       *****   Console output routine   *****
;               IN :    HL -- Conout message top addr.
DSPMSG:
        LD      C,(HL)
        LD      A,C
        OR      A               ; If data is 0,
        RET     Z               ;  then end of data.
;
        PUSH    HL
        CALL    CONOUT          ; Console output
        POP     HL
        INC     HL
        JR      DSPMSG
;
;       *****   Ending process  *****
;
STOPEND:
        LD      C,00H           ; Reset resident flag
        CALL    RESIDENT
        JP      WBOOT           ;
;
        END
        POP
