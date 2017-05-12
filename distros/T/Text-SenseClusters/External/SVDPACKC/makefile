#######################################################################
#                     SVDPACKC (Ver 1.0) Makefile                     #
#                                                                     #
# this is a version modifed by Ted Pedersen to only include las2.c    #
# otherwise it is the same as distributed with SVDPACKC at netlib.org #
# modifications made March 24, 2008                                   #
#######################################################################
#                                                                     #
#      las2: Single-Vector Lanczos SVD via   A'A    Eigensystems      #
#                                                                     #
#######################################################################
 
CC    =	gcc -ansi
CFLAGS= -O -c 
LIB=	-lm
TIMER=	timersun.o

all:	las2 

las2.o:	las2.h

.c.o:   $*.c 
	${CC} ${CFLAGS} $*.c

las2:	las2.o ${TIMER}
	${CC} -o $@ las2.o ${TIMER} ${LIB}

clean:
	rm -fr las2.o timersun.o las2 lav2 matrix
