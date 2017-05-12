#
# Makefile for cscwsd-0.1.0 (manual make)
# -----------------------------------------------------

# util
CC	= gcc
ARLIB	= ar
RANLIB	= ranlib

# options
CFLAGS	= -O2 -s -pipe -fomit-frame-pointer -Wunused -Wall
LDFLAG	= -s

# list obj required by 'libscws.a'
OBJ	= scws.o charset.o darray.o pool.o xdb.o \
	  xdict.o rule.o xtree.o

# target list
EXE	= libscws.a

# suffix rule
.c.o:	;	$(CC) $(CFLAGS) -c $*.c

# targets
all:	$(EXE)

libscws.a: $(OBJ)
	$(ARLIB) rv $@ $?
	$(RANLIB) $@
	chmod +x $@

clean:
	rm -fr *.o $(EXE) *.bak *.BAK *.a *.lo *.so *~ *.core *.stackdump
