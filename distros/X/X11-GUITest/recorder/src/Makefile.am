DEBUG = -DNOPERL
# WARN_CFLAGS is only set to GCC/Clang-flavored warning flags when the
# detected compiler is actually GCC-compatible (see configure.ac); X_CFLAGS
# comes from AC_PATH_XTRA rather than a hardcoded path list. popt and, if
# needed, libintl are picked up automatically via $(LIBS), which automake
# always appends to the link line -- see the AC_CHECK_LIB/AC_SEARCH_LIBS
# calls in configure.ac.
AM_CFLAGS = $(WARN_CFLAGS) $(DEBUG) -O2 -DLOCALEDIR='"$(localedir)"' $(X_CFLAGS) -I../ -I../../
AM_LDFLAGS = -s

bindir = $(prefix)/bin
bin_PROGRAMS = x11guirecord
x11guirecord_SOURCES = ../../KeyUtil.c record.c script_file.c main.c
x11guirecord_LDADD = $(X_PRE_LIBS) $(X_LIBS) -lXtst -lXext -lX11 $(X_EXTRA_LIBS)

