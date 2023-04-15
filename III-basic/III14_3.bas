1 REM III-14 - 2.1.7 DB mode Sample program
10 OUT &H18, &H02
20 OUT &H13, &HFF
30 PRINT HEX$(INP (&H13))
40 GOTO 20
