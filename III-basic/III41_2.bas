1 REM III-41 - 3.2 1-Second Counter
10 A=PEEK(&HEF91)
20 B=PEEK(&HEF92)
30 PRINT B*256+A
40 GOTO 10
