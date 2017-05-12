
# The base settings that are always needed.
TRICEPS_CONF =
TRICEPS_XLIB = -lpthread -lrt

# configuration settings

# The NSPR library is a pain. In some distributions it's using the name,
# including the include directory name "nspr4". In some it's just "nspr".
# Hopefully, the configuration will be auto-found.
# You can override it by setting the values explicitly instead.
# If TRICEPS_NSPR is not set, NSPR won't be used. Instead an alternative
# portable implementation of atomic integers that uses a mutex will be used.
#
# The code below tries to do its best to find the NSPR library in the
# places I know of, or otherwise makes the code do without it.
# If it doesn't work weel on your system, you can always comment out
# this code and override it manually.
NSPR_LIBS = $(shell pkg-config --libs nspr 2>/dev/null)
ifneq ($(NSPR_LIBS),)
	# use the NSPR4 library, auto-found
	TRICEPS_CONF += -DTRICEPS_NSPR $(shell pkg-config --cflags nspr)
	TRICEPS_XLIB += $(NSPR_LIBS)
else
	NSPR_INC = $(shell ls -d /usr/include/nspr4 2>/dev/null)
	ifneq ($(NSPR_INC),)
		TRICEPS_CONF += -DTRICEPS_NSPR -I/usr/include/nspr4
		TRICEPS_XLIB += -lnspr4
	endif
endif

# use a different namespace (instead of Triceps)
# TRICEPS_CONF += -DTRICEPS_NS=name

# do not use the glibc stack tracing library
# TRICEPS_CONF += -DTRICEPS_BACKTRACE=false

# base name of the Triceps library
LIBRARY := triceps

# For the build checked out from trunk, treat the warnings as errors except
# for the annoying few. For the release build, just build with the minimum of
# flags and don't fail on warnings, since the warnings and their names
# differ by the GCC versions.
ifeq ($(notdir $(realpath ../..)), trunk)
	# Option useful for the newer GCC: -Wno-int-to-pointer-cast
	CFLAGS_WARNINGS = -Wall -Wno-sign-conversion -Wno-sign-compare -Werror
else
	CFLAGS_WARNINGS =
endif

OBJEXT := .o
BINEXT := 
BUILDDIR := build
CPPFLAGS := -I.. $(TRICEPS_CONF)
CFLAGS := -g -fPIC -pthread -rdynamic $(CPPFLAGS) $(CFLAGS_WARNINGS) $(TRICEPS_CONF)
CXXFLAGS := $(CFLAGS)
LDFLAGS := -L../build -l$(LIBRARY) $(TRICEPS_XLIB)
TESTLDFLAGS := $(LDFLAGS) -L../utest/build -Wl,-rpath='$$ORIGIN/../../../build' \
	-ltriceps_utest -Wl,-rpath='$$ORIGIN/../../../utest/build'

RANLIB := ranlib
VALGRIND := valgrind --leak-check=full -v

SHLIB := lib$(LIBRARY).so
ARLIB := lib$(LIBRARY).a

# so that the targets defined here won't override "all"
.DEFAULT_GOAL := all

$(BUILDDIR):
	mkdir $(BUILDDIR)

getconf:
	@echo "$(TRICEPS_CONF)"

getxlib:
	@echo "$(TRICEPS_XLIB)"

getlib:
	@echo "$(LIBRARY)"
