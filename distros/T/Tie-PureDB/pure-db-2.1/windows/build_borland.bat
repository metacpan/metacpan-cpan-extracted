
bcc32 -I. -O2 -D_RTLDLL -DWIN32  -D_MT -c puredb_read.c
bcc32 -I. -O2 -D_RTLDLL -DWIN32  -D_MT -c puredb_write.c

tlib libpuredb_read.lib  +puredb_read.obj
tlib libpuredb_write.lib +puredb_write.obj

bcc32 -I. -O2 -D_RTLDLL -DWIN32  -D_MT regression.c      libpuredb_write.lib     libpuredb_read.lib
bcc32 -I. -O2 -D_RTLDLL -DWIN32  -D_MT regression2.c     libpuredb_write.lib     libpuredb_read.lib
bcc32 -I. -O2 -D_RTLDLL -DWIN32  -D_MT example_write.c   libpuredb_write.lib     libpuredb_read.lib
bcc32 -I. -O2 -D_RTLDLL -DWIN32  -D_MT example_read.c    libpuredb_write.lib     libpuredb_read.lib
