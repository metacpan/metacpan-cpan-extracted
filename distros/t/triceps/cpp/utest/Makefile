
# most of it is shared with the common subdirectories
include ../Makefile.sub

# however the object files here are collected into a separate shared library,
# which will be linked with the C++ unit test binaries

UT_LIBRARY := triceps_utest
UT_SHLIB := $(BUILDDIR)/lib$(UT_LIBRARY).so

all: $(UT_SHLIB)

$(UT_SHLIB): $(OBJECTS) 
	rm -f $@
	$(CXX) -shared -o $@ $^
