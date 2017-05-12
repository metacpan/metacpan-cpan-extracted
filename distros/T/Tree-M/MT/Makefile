######################################################################
#                                                                    #
# Copyright (c) 1997,1998, 1999                                      #
# Multimedia DB Group and DEIS - CSITE-CNR,                          #
# University of Bologna, Bologna, ITALY.                             #
#                                                                    #
# All Rights Reserved.                                               #
#                                                                    #
# Permission to use, copy, and distribute this software and its      #
# documentation for NON-COMMERCIAL purposes and without fee is       #
# hereby granted provided  that this copyright notice appears in     #
# all copies.                                                        #
#                                                                    #
# THE AUTHORS MAKE NO REPRESENTATIONS OR WARRANTIES ABOUT THE        #
# SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING  #
# BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,      #
# FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. THE AUTHOR  #
# SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A      #
# RESULT OF USING, MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS    #
# DERIVATIVES.                                                       #
#                                                                    #
######################################################################

#         Makefile for M-tree test program

PROGRAM = MTree

CPP = $(CXX) -fpic

CFLAGS = -DUNIX

INCS = -I../GiST

LINKER = $(CXX)

SRCS = MTfile.cpp MTentry.cpp MTnode.cpp MTpredicate.cpp MTobject.cpp MT.cpp MTcursor.cpp BulkLoad.cpp # Main.cpp
       
OBJS = MTfile.o MTentry.o MTnode.o MTpredicate.o MTobject.o MT.o MTcursor.o BulkLoad.o

LIBS = ../GiST/libGiST.a

DEST = .

all: libMT.a

libMT.a: $(OBJS)
	ar rc libMT.a $(OBJS)
	ranlib libMT.a

$(PROGRAM): $(OBJS) $(LIBS)
	$(LINKER) -o $(PROGRAM) $(LDFLAGS) $(OBJS) $(LIBS)

gen:
	$(CPP) -o generate $(CFLAGS) $(INCS) $(LDFLAGS) generate.cpp

depend:
	makedepend -Y $(DEFINES) $(INCS) $(SRCS)

.SUFFIXES: .cpp
   
.cpp.o:
	$(CPP) -c $(CFLAGS) $(OPTIMIZE) $(INCS) $<

clean:
	rm -f $(OBJS) $(PROGRAM) libMT.a

install: $(PROGRAM)
	echo Installing $(PROGRAM) in $(DEST)
	install -s $(PROGRAM) $(DEST)
# DO NOT DELETE

MTfile.o: MTfile.h ../GiST/GiSTstore.h GiSTdefs.h
MTentry.o: MTentry.h ../GiST/GiST.h GiSTdefs.h ../GiST/GiSTentry.h
MTentry.o: ../GiST/GiSTpredicate.h ../GiST/GiSTlist.h ../GiST/GiSTnode.h
MTentry.o: ../GiST/GiSTpath.h ../GiST/GiSTstore.h ../GiST/GiSTcursor.h
MTentry.o: MTobject.h ../object.h ../PMT.h MT.h MTfile.h MTnode.h MTcursor.h
MTentry.o: list.h
MTnode.o: MT.h ../GiST/GiST.h GiSTdefs.h ../GiST/GiSTentry.h
MTnode.o: ../GiST/GiSTpredicate.h ../GiST/GiSTlist.h ../GiST/GiSTnode.h
MTnode.o: ../GiST/GiSTpath.h ../GiST/GiSTstore.h ../GiST/GiSTcursor.h
MTnode.o: MTfile.h MTnode.h MTentry.h MTobject.h ../object.h ../PMT.h
MTnode.o: MTcursor.h list.h MTpredicate.h
MTpredicate.o: MT.h ../GiST/GiST.h GiSTdefs.h ../GiST/GiSTentry.h
MTpredicate.o: ../GiST/GiSTpredicate.h ../GiST/GiSTlist.h ../GiST/GiSTnode.h
MTpredicate.o: ../GiST/GiSTpath.h ../GiST/GiSTstore.h ../GiST/GiSTcursor.h
MTpredicate.o: MTfile.h MTnode.h MTentry.h MTobject.h ../object.h ../PMT.h
MTpredicate.o: MTcursor.h list.h MTpredicate.h
MTobject.o: MTobject.h ../object.h ../PMT.h ../GiST/GiSTlist.h
MT.o: list.h MT.h ../GiST/GiST.h GiSTdefs.h ../GiST/GiSTentry.h
MT.o: ../GiST/GiSTpredicate.h ../GiST/GiSTlist.h ../GiST/GiSTnode.h
MT.o: ../GiST/GiSTpath.h ../GiST/GiSTstore.h ../GiST/GiSTcursor.h MTfile.h
MT.o: MTnode.h MTentry.h MTobject.h ../object.h ../PMT.h MTcursor.h
MT.o: MTpredicate.h
MTcursor.o: MTcursor.h ../GiST/GiST.h GiSTdefs.h ../GiST/GiSTentry.h
MTcursor.o: ../GiST/GiSTpredicate.h ../GiST/GiSTlist.h ../GiST/GiSTnode.h
MTcursor.o: ../GiST/GiSTpath.h ../GiST/GiSTstore.h ../GiST/GiSTcursor.h
MTcursor.o: list.h MT.h MTfile.h MTnode.h MTentry.h MTobject.h ../object.h
MTcursor.o: ../PMT.h MTpredicate.h
BulkLoad.o: MT.h ../GiST/GiST.h GiSTdefs.h ../GiST/GiSTentry.h
BulkLoad.o: ../GiST/GiSTpredicate.h ../GiST/GiSTlist.h ../GiST/GiSTnode.h
BulkLoad.o: ../GiST/GiSTpath.h ../GiST/GiSTstore.h ../GiST/GiSTcursor.h
BulkLoad.o: MTfile.h MTnode.h MTentry.h MTobject.h ../object.h ../PMT.h
BulkLoad.o: MTcursor.h list.h
