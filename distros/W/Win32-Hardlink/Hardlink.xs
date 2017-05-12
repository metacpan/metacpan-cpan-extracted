#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

extern int create_hard_link ( const char* oldpath, const char* newpath );

MODULE = Win32::Hardlink		PACKAGE = Win32::Hardlink		

int
link(oldpath, newpath)
    const char * oldpath
    const char * newpath
    CODE:
	RETVAL = ((create_hard_link( oldpath, newpath ) == 0) ? 1 : 0);
    OUTPUT:
        RETVAL
