#AUTOSTART=1
#VARS A=2.5
#VARS AB=1.25
#VARS ABC=6.25
#VARS A$="HELLO"
#VARS M(2,3)=11,12,13,21,22,23
#VARS M$(2,3,2)="AA","AB","AC","BA","BB","BC"

    PRINT A;" ";AB;" ";ABC
    PRINT A$
    FOR I=1 TO 2
        FOR J=1 TO 3
            PRINT M(I,J);" ";
        NEXT J
        PRINT
    NEXT I
    FOR I=1 TO 2
        FOR J=1 TO 3
            PRINT M$(I,J);" ";
        NEXT J
        PRINT
    NEXT I
