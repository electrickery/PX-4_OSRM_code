1 REM III-20 - 2.1.1 Application circuit example Test program
10 PRINT HEX$(INP(&H13))
20 OUT &H13,&H80
30 OUT &H10,&HFF
40 OUT &H10,&H00
50 GOTO 30
60 END
