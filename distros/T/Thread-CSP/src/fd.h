SV* S_io_fdopen(pTHX_ int fd, const char* packagename);
#define io_fdopen(fd, packagename) S_io_fdopen(aTHX_ fd, packagename)
