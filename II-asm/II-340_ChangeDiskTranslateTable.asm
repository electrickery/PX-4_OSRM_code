;       ********************************************************
;               CHANGE DISK TRANSLATE TABLE
;       ********************************************************
;
;       NOTE :
;               This sample program is changing disk
;               translate table.
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
CONOUT          EQU     WBOOT   +09H    ; Console out entry
;
;       System area
;
DISKTBL         EQU     0F0FFH          ; Top of User BIOS
DISKROV         EQU     0F10CH          ; RBIOS1 loading addr
ROMCPN01        EQU     0F10AH          ; RBDOS1 loading addr
;
INDATA          EQU     00080H
;
;       Constant
;
CR              EQU     0DH
LF              EQU     0AH
;
;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This program is changing disk translate table.
;                       First parameter is logical drive.
;                       Second parameter is Physical drive.
;
MAIN:
        LD      SP,1000H        ; Set stack pointer.
;
;
        CALL    GETDATA         ; Get user inputed data.
        JP      C,ERROR_END     ; If parameter end, then end.
;
        CALL    SETMSG          ; Set return message data.
        CALL    CHANGE          ; Change disk translate table.
;
        LD      HL,MSG01        ; Normal end message.
        JR      PEND            ;
;
;
ERROR_END:
        LD      HL,MSG02        ; Error end message.
PEND:
        CALL    DSPMSG          ; Display message.
        JP      WBOOT           ;
;
;       ********************************************************
;               CHANGE DISK DRIVE TABLE
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               B : Logical drive NO.
;               C : Physical drive NO.
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If parameter error, then WBOOT.
;
CHANGE:
        LD      E,B             ; Get target logical drive NO. address.
        LD      D,00H           ;  DISKTBL + BC --> HL
        LD      HL,DISKTBL      ;
        ADD     HL,DE           ;
        LD      (HL),C          ; Set new physical drive No.
;
        INC     E               ; Calculate read only bit position.
        LD      B,E             ; Drive No. (1 to 11)
        LD      E,D             ; DE is 0000H.
        SCF                     ; Carry on.
;
LOOP10:
        RL      E               ; Shift left by 1 bit.
        RL      D               ; 
        DJNZ    LOOP10          ; Loop by Drive No.
;
        LD      HL,DISKROV      ; Disk R/) table.
        LD      A,C             ; If R/O disk (1,2,9,10)
        CP      01H             ;  then set read only bit.
        JR      Z,RO_DISK       ;
        CP      02H             ;
        JR      Z,RO_DISK       ;
        CP      09H             ;
        JR      Z,RO_DISK       ;
        CP      0AH             ;
        JR      NZ,RW_DISK      ;
;
RO_DISK:
        LD      A,(HL)          ; Set R/O bit.
        OR      E               ;
        LD      (HL),A          ;
        INC     HL              ;
        LD      A,(HL)          ;
        OR      D               ;
        LD      (HL),A          ;
        JR      RON_CAPSEL      ;
;
RW_DISK:
        LD      A,0FFH          ; Reset read only bit.
        XOR     E               ;
        AND     (HL)            ;
        LD      (HL),A          ;
        INC     HL              ;
        LD      A,-FFH          ;
        XOR     D               ;
        AND     (HL)            ;
        LD      (HL),A          ;
;
ROM_CAPSEL:
        LD      A,C             ; Key code. (Disk code)
        OR      A               ; RAM disk.
        RET     Z               ; Yes.
        CP      03H             ; ROM capsel 1 or 2?
        RET     NC              ;No.
;
        LD      B,11            ; Table length.
        LD      HL,DISKTBL      ; Table address.
        CALL    SEARCH          ; Search data.
        RET     C               ; Not found.
;
        LD      B,00H           ; Set position No. in table.
        LD      HL,ROMCPNO1-1   ;
        ADD     HL,BC           ;
        LD      (HL),A          ;
;
        RET
;
;
;       ********************************************************
;               GET PARAMETER FROM BUFFER
;       ********************************************************
;
;       NOTE :
;               Get disk translate data from
;               CCP input buffer.
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               CY-flag : Return parameter.
;                  =0 -- Normal return
;                  =1 -- Error return
;                         (Parameter error)
;               Case of Normal return
;                 B : Logical drive NO.
;                       (00H to 0AH)
;                 C : Physical drive NO.
;                       (00H to 0AH)
;
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               Case of normal retyrn, this routine
;               sets finishing message.
;
GETDATA:
        LD      HL,INDATA       ; Parameter inputed address.
        LD      A,(HL)          ; Get inputed byte number.
        CP      05H             ; Parameter count check.
        RET     C               ; Error, then return with carry on.
;
        INC     HL              ; Pointer update.
        INC     HL              ;
        LD      A,(HL)          ; Get first data.
        AND     0DFH            ; Capital change.
        SUB     'A'             ; 'A' to 'K' check.
        RET     C               ; If error,
        CP      'L'-'A'         ;  then return with carry on.
        CCF                     ;
        RET     C               ;
;
        LD      B,A             ; First parameter --> B
;
        INC     HL              ; Pointer update.
        LD      A,(HL)          ; ':=' check.
        CP      ':'             ;
        SCF                     ;
        RET     NZ              ;
        INC     HL              ;
        LD      A,(HL)          ;
        CP      '+'             ;
        SCF                     ;
        RET     NZ              ;
;
        INC     HL      ; Pointer update.
        LD      A,(HL)  ; Get second parameter.
        AND     0DH     ;
        SUB     'A'     ; 'A' to 'K' check.
        RET     C       ;
        CP      'L'-'A' ;
        CCF             ;
        RET     C       ;
;
        LD      C,A     ; Second parameter --> C
        RET             ;
;
;       ********************************************************
;               SET DRIVE NAME
;       ********************************************************
;
;       NOTE :
;               Set drive name to message area.
;
;       <> entry parameter <>
;               B : Drive No.
;               C : Drive No.

;       <> return parameter <>
;               NON
;
;       <> preserved registers <>
;               BC
;
;       CAUTION :
SETMSG:
        PUSH    BC              ; Save register.
        LD      A,B             ;
        ADD     A,'A'           ; Get ASCII data.
        LD      (DRIVE),A       ; Set drive code.
;
        LD      HL,DEVICETBL    ; Data search table.
        LD      A,C             ;
        ADD     A,A             ;
        LD      E,A             ;
        LD      D,00H           ;
        ADD     HL,DE           ;
        LD      E,(HL)          ;
        INC     HL              ;
        LD      D,(HL)          ;
;
        EX      DE,HL           ; Message top address. (HL)
        LD      DE,DEVICE       ; Data setting address.
        LD      C,(HL)          ; Get data count.
        INC     HL              ;
        LD      B,00H           ;
        LDIR                    ;
        LD      HL,ENDMARK      ; Set end data.
        LD      C,04H           ;
        LDIR                    ;
;
        POP     BC              ; Restore register.
        RET
;
;       Message table & data
;
DEVICETBL:
        DW      DV_A            ; RAM disk
        DW      DV_B            ; ROM capsel 1
        DW      DV_C            ; ROM capsel 2
        DW      DV_D            ; FDD 1
        DW      DV_E            ; FDD 2
        DW      DV_F            ; FDD 3
        DW      DV_G            ; FDD 4
        DW      DV_H            ; MCT cartridge
        DW      DV_I            ; RAM cartridge
        DW      DV_J            ; ROM cartridge 1
        DW      DV_K            ; ROM cartdidge 2
;
DV_A:
        DB      8,'RAM disk'
DV_B:
        DB      12,'ROM capsel 1'
DV_C:
        DB      12,'ROM capsel 2'
DV_D:
        DB      5,'FDD 1'
DV_E:
        DB      5,'FDD 2'
DV_F:
        DB      5,'FDD 3'
DV_G:
        DB      5,'FDD 4'
DV_H:
        DB      13,'MCT cartridge'
DV_I:
        DB      13,'RAM cartridge'
DV_J:
        DB      15,'ROM cartridge 1'
DV_K:
        DB      15,'ROM cartridge 2'
;
ENDMARK:
        DB      '.',CR,LF,00H
;
;       ********************************************************
;               SEARCH TABLE
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               A  : Key code
;               B  : Length of table
;               C  : Top of table address
;       <> return parameter <>
;               CY  : Return information
;                       =0 : Found
;                       =1 : Not found
;               A  : KeyNo.
;               HL : Object item position in table
;       <> preserved registers <>
;               BC,DE
;
;       CAUTION :
;
SEARCH:
        PUSH    BC              ; Save register.
        LD      C,00H           ; Initialize key NO.
SEAR1:
        CP      (HL)            ; Compare key with item.
        JR      Z,SEAR2         ; If found, then exit.
        INC     HL              ;  else check next item.
        INC     C               ; Key NO. update
        DJNZ    SEAR1           ; If not end of table, then repeat,
        LD      C,0FFH          ;  else set not found sign.
        SCF                     ;
SEAR2:
        LD      A,C             ; Set key NO.
        POP     BC              ; Restore register.
        RET                     ;
;
;       ********************************************************
;               DISPLAY MESSAGE
;       ********************************************************
;
;       NOTE :
;               Display message until find 00H.
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
        LD      C,(HL)          ; Get display data.
        INC     C               ; Data is 00H?
        DEC     C               ;
        RET     Z               ; Yes.
;
        PUSH HL                 ;
        CALL    CONOUT          ; Display data.
        POP     HL              ;
        INC     HL              ; Pointer update.
        JR      DSPMSG          ;
;
;       Message and Work area
;
MSG01:
        'Change drive '
DRIVE:  DS      1
        DB      ': to '
DEVICE: DS      19
;
MSG02:
        DB      'Parameter error!',CR,LF,00H
;
        END
