LIBRARY = libGiST.a

SRCS = GiSTnode.cpp GiST.cpp GiSTfile.cpp GiSTpredicate.cpp GiSTcursor.cpp

OBJS = GiSTnode.o GiST.o GiSTfile.o GiSTpredicate.o GiSTcursor.o

DEST = .

CPP = $(CXX) -fpic

DEFINES = -DUNIX

INCS = 

LINKER = $(LD)

LDFLAGS = #-L/home/users/patella/pub/libg++-2.7.1/

.SUFFIXES: .cpp

.cpp.o:
	$(CPP) -c $(CFLAGS) $(OPTIMIZE) $(DEFINES) $(INCS) $<

$(LIBRARY): $(OBJS)
	rm -f $(LIBRARY)
	ar r $(LIBRARY) $(OBJS)
	ranlib $(LIBRARY)

clean:
	rm -f $(OBJS) $(LIBRARY) *~ #*# *pure*

depend:
	makedepend -Y $(DEFINES) $(INCS) $(SRCS)

install: $(PROGRAM)
	echo Installing $(PROGRAM) in $(DEST)
	install -s $(PROGRAM) $(DEST)

# DO NOT DELETE

GiSTnode.o: GiST.h GiSTdefs.h GiSTentry.h GiSTpredicate.h GiSTlist.h
GiSTnode.o: GiSTnode.h GiSTpath.h GiSTstore.h GiSTcursor.h
GiST.o: GiST.h GiSTdefs.h GiSTentry.h GiSTpredicate.h GiSTlist.h GiSTnode.h
GiST.o: GiSTpath.h GiSTstore.h GiSTcursor.h
GiSTfile.o: GiSTfile.h GiSTstore.h GiSTdefs.h
GiSTpredicate.o: GiST.h GiSTdefs.h GiSTentry.h GiSTpredicate.h GiSTlist.h
GiSTpredicate.o: GiSTnode.h GiSTpath.h GiSTstore.h GiSTcursor.h
GiSTcursor.o: GiST.h GiSTdefs.h GiSTentry.h GiSTpredicate.h GiSTlist.h
GiSTcursor.o: GiSTnode.h GiSTpath.h GiSTstore.h GiSTcursor.h
