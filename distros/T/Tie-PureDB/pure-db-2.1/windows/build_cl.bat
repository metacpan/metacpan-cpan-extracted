call vcvars32

cl  /I. /MD /c /Tc puredb_read.c
cl  /I. /MD /c /Tc puredb_write.c

lib -nologo -nodefaultlib  puredb_read.obj /OUT:libpuredb_read.lib  WSOCK32.LIB
lib -nologo -nodefaultlib  puredb_write.obj /OUT:libpuredb_write.lib  WSOCK32.LIB

cl /I.  /MD  /Tc regression.c      libpuredb_write.lib     libpuredb_read.lib
cl /I.  /MD  /Tc regression2.c     libpuredb_write.lib     libpuredb_read.lib
cl /I.  /MD  /Tc example_write.c   libpuredb_write.lib     libpuredb_read.lib
cl /I.  /MD  /Tc example_read.c    libpuredb_write.lib     libpuredb_read.lib
