
# the common Makefile for all the subdirs

include ../Makefile.inc

SRC_C := $(wildcard *.c)
SRC_CPP := $(wildcard *.cpp)
SOURCES := $(SRC_C) $(SRC_CPP)
OBJECTS := $(addprefix $(BUILDDIR)/, $(SRC_C:.c=$(OBJEXT)) $(SRC_CPP:.cpp=$(OBJEXT)))
DEPENDS := $(addprefix $(BUILDDIR)/, $(SRC_C:.c=.d) $(SRC_CPP:.cpp=.d))

# for tests
T_SRC_CPP := $(wildcard test/t_*.cpp)
T_BINS := $(patsubst test/%, test/$(BUILDDIR)/%, $(T_SRC_C:.c=$(BINEXT)) $(T_SRC_CPP:.cpp=$(BINOBJEXT)))
T_DEPENDS := $(patsubst test/%, test/$(BUILDDIR)/%, $(T_SRC_C:.c=.d) $(T_SRC_CPP:.cpp=.d))
T_MAINS := $(patsubst test/%, test/$(BUILDDIR)/%, $(T_SRC_CPP:.cpp=.main.cpp))

.PHONY: all depend clean clobber mktest test qtest vtest

ifeq (,$(strip $(NODEP) $(filter help% clean% %clean clobber%, $(MAKECMDGOALS))))
-include $(DEPENDS)
-include $(T_DEPENDS)
endif

all: $(OBJECTS)

$(OBJECTS): | $(BUILDDIR)

$(DEPENDS): | $(BUILDDIR)

$(BUILDDIR)/%$(OBJEXT): Makefile 

$(BUILDDIR)/%$(OBJEXT): %.cpp Makefile ../Makefile.inc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILDDIR)/%$(OBJEXT): %.c Makefile ../Makefile.inc
	$(CC) $(CFLAGS) -c -o $@ $<

depend: $(DEPENDS) $(T_DEPENDS)

$(BUILDDIR)/%.d: %.cpp Makefile ../Makefile.inc
	@echo "depending $< to $@ ..."
	@rm -f $@; \
	$(CXX) -M $(CPPFLAGS) $< > $@.$$$$ && \
	sed 's,\($*\)\.o[ :]*,$(BUILDDIR)/\1.o $@ : ,g' < $@.$$$$ > $@ && \
	rm -f $@.$$$$

$(BUILDDIR)/%.d: %.c Makefile ../Makefile.inc
	@echo "depending $< to $@ ..."
	@rm -f $@; \
	$(CC) -M $(CPPFLAGS) $< > $@.$$$$ && \
	sed 's,\($*\)\.o[ :]*,$(BUILDDIR)/\1.o $@ : ,g' < $@.$$$$ > $@ && \
	rm -f $@.$$$$

cleancore:
	rm -f core.* *.core core vgcore.*

cleantest:
	rm -rf test/$(BUILDDIR) 

clean: cleancore cleantest
	rm -rf $(BUILDDIR) test/$(BUILDDIR) 

clobber:
	rm -f $(OBJECTS) $(DEPENDS)

cleandep:
	rm -f $(DEPENDS)

### the test stuff ###

mktest: $(T_DEPENDS) $(T_MAINS) $(T_BINS)

test: vtest

# quick test, without valgrind
qtest: cleancore mktest
	@echo "Unit tests:"; for i in  $(T_BINS); do \
		basename $$i; $$i || { echo "  FAIL" >&2; exit 1; } \
	done

# detailed test, with valgrind
vtest: cleancore mktest
	@echo "Unit tests valgrind:"; for i in  $(T_BINS); do \
		basename $$i; $(VALGRIND) $$i 2>$$i.vg || { echo "  FAIL" >&2; exit 1; }; \
		grep "ERROR SUMMARY: .*[^0].* errors from" $$i.vg && { echo "  FAIL MEMCHK" >&2; exit 1; }; \
		grep "are definitely lost" $$i.vg && { echo "  FAIL LEAK" >&2; exit 1; }; \
	done; true

$(T_DEPENDS): | test/$(BUILDDIR)

$(T_BINS): | test/$(BUILDDIR)

test/$(BUILDDIR):
	mkdir test/$(BUILDDIR)
	@#echo "$(T_SRC_CPP)"
	@#echo "$(T_DEPENDS)"
	@#echo "$(T_BINS)"

test/$(BUILDDIR)/%.d: test/%.cpp Makefile ../Makefile.inc
	@echo "depending $< to $@ ..."
	@rm -f $@; \
	$(CXX) -M $(CPPFLAGS) $< > $@.$$$$ && \
	sed 's,\($*\)\.o[ :]*,test/$(BUILDDIR)/\1 $@ : test/build/\1.main.cpp ,g' < $@.$$$$ > $@ && \
	rm -f $@.$$$$

test/$(BUILDDIR)/%.d: test/%.c Makefile ../Makefile.inc
	@echo "depending $< to $@ ..."
	@rm -f $@; \
	$(CC) -M $(CPPFLAGS) $< > $@.$$$$ && \
	sed 's,\($*\)\.o[ :]*,$(BUILDDIR)/\1.o $@ : ,g' < $@.$$$$ > $@ && \
	rm -f $@.$$$$

# automatically build main() for the test driver
test/$(BUILDDIR)/%.main.cpp: test/%.cpp ../utest/genmain.pl
	perl ../utest/genmain.pl < $< > $@

test/$(BUILDDIR)/%$(BINEXT): Makefile ../Makefile.inc

test/$(BUILDDIR)/%$(BINEXT): test/%.cpp test/$(BUILDDIR)/%.main.cpp
	$(CXX) $(CXXFLAGS) $(TESTLDFLAGS) -o $@ $< test/$(BUILDDIR)/$*.main.cpp

# the C code, if any appears, doesn't use the common unit test driver
test/$(BUILDDIR)/%$(BINEXT): test/%.c Makefile ../Makefile.inc
	$(CC) $(CFLAGS) $(TESTLDFLAGS) -o $@ $<

