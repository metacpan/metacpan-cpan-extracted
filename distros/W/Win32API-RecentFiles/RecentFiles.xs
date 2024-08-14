#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "shlobj.h"

void SHAddToRecentDocsA(SV* _path) {
    STRLEN len;
    const char * path = SvPVbyte(_path, len);
    SHAddToRecentDocs(
        SHARD_PATHA,
        path
    );
}

void SHAddToRecentDocsU(SV* _path) {
    STRLEN len;
    char* s = SvPVutf8(_path, len);
    STRLEN length = MultiByteToWideChar(CP_UTF8, 0, s, len, 0, 0);
    wchar_t* path;
    Newx(path, len+1, wchar_t);

    if( path ) {
        MultiByteToWideChar(CP_UTF8, 0, s, len, path, length);
        path[length] = L'\0';
    }

    SHAddToRecentDocs(
        SHARD_PATHW,
        path
    );

    Safefree(path);
}

void SHAddToRecentDocsW(SV* _path) {
    STRLEN len;
    const char * bytes = SvPVbyte(_path, len);
    wchar_t * path;
    unsigned char *p;
    Newx(path, len+2, char);
    memcpy( path, bytes, len );
    // add a \0 to the end of path
    path[ len/2 ] = 0;

    SHAddToRecentDocs(
        SHARD_PATHW,
        path
    );
    Safefree( path );
}


MODULE = Win32API::RecentFiles  PACKAGE = Win32API::RecentFiles

PROTOTYPES: DISABLE


void
SHAddToRecentDocsA (path)
	SV *	path
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        SHAddToRecentDocsA(path);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
SHAddToRecentDocsW (path)
	SV * path
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        SHAddToRecentDocsW(path);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
SHAddToRecentDocsU (_path)
	SV *	_path
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        SHAddToRecentDocsU(_path);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

