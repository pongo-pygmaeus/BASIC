5 REM     Taken from Usborne's 1982 book
6 REM     "Computer Battlegames"
10 PRINT "TRAITOR'S CASTLE"
20 LET S=0
30 FOR G=1 TO 10
40 LET R$=""
50 LET T=INT(RND(1)*9+1)
60 FOR L=1 TO 9
70 IF L=T THEN LET R$=R$+"O"
80 IF L<>T THEN LET R$=R$+"."
90 NEXT L
100 PRINT R$,
110 LET I$=INKEY$(600)
130 IF VAL("0"+I$)=T THEN GOTO 170
150 PRINT "MISSED"
160 GOTO 190
170 PRINT "GOOD SHOT"
180 LET S=S+1
190 NEXT G
200 PRINT "YOU HIT ";S;" OUT OF 10"
210 STOP