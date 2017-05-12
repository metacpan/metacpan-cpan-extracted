#define WIN32_MEAN_AND_LEAN

/* XS code for Win32::GUI::DropFiles
 * $Id: DropFiles.xs,v 1.1 2006/04/25 21:38:18 robertemay Exp $
 * (c) Robert May, 2006
 * Released under the same terms as Perl
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "windows.h"
#include "shellapi.h"

/* void newSVpvnW(SV* s, WCHAR* w, UINT c)
 *  - s [OUT] pointer to SV. Will be set to point to a newly created SV,
 *    with ref count 1.
 *  - w [IN]  pointer to WCHAR buffer.
 *  - c [IN]  number of characters (NOT bytes) to be copied from WCHAR.  Do
 *    not include any NULL termination. If c = -1, then length will be
 *    calculated, assuming w is NULL terminated.
 */
/* TODO: This macro probably better written as a function that returns the
 * pointer to the SV, and it is more 'perl like' if c==0 indicates the length
 * should be calculated. It would be good to get rid of the duplicated SvPVX() calls.
 */
#define newSVpvnW(s, w, c) \
    { UINT b = WideCharToMultiByte(CP_UTF8, 0, w, c, NULL, 0, NULL, NULL); \
      s = newSV(b); SvPOK_on(s); SvUTF8_on(s); SvCUR_set(s,b); \
      WideCharToMultiByte(CP_UTF8, 0, w, c, SvPVX(s), b, NULL, NULL); \
      *(SvPVX(s) + b) = 0; sv_utf8_downgrade(s, 1); }

/* BOOL INVALID_HANDLE(HDROP h)
 * Attempt to determine if a HDROP handle is valid
 * Returns TRUE  if handle is invalid
 * Returns FALSE if handle is valid
 * TODO: can we do better than this?
 */
BOOL INVALID_HANDLE(HDROP h) {
    if(GlobalLock((HGLOBAL)h)) {
        GlobalUnlock((HGLOBAL)h);
        return 0;
    }
    return 1;
}

#ifndef W32G_NO_WIN9X
/* BOOL IsWin9X()
 * Returns TRUE  if OS Version is Win95/98/ME
 * Returns FLASE if OS Version is NT/2K/XP/2003 or higher
 */
/* TODO: Better to cache the value to prevent the overhead of
 * GetVersion() on each call.  Eventually this needs extracting
 * somewhere central, so that we don't have repeat implementations
 * all over the place.  ??Can we efficiently access the Win32::IsWin95
 * function??
 */
BOOL IsWin9X() {
    return (GetVersion() & 0x80000000);
}
#endif

MODULE = Win32::GUI::DropFiles        PACKAGE = Win32::GUI::DropFiles

PROTOTYPES: ENABLE

     ##########################################################################
     # (@)WIN32API:DragQueryFile(HDROP, [ITEM])
     # See Dropfiles.pm for documentation
void DragQueryFile(handle, ...)
    HDROP handle
PREINIT:
    UINT count, item, cch;
    SV* sv;
PPCODE:
    /* Shell32.dll crashes if we pass an invalid handle
     * to DragQueryFile, so ensure we have one
     */
    if(INVALID_HANDLE(handle)) {
        SetLastError(ERROR_INVALID_HANDLE); /* set $^E */
        errno = EINVAL;                     /* set $! */
        XSRETURN_UNDEF;                     /* and return undef */
    }
#ifndef W32G_NO_WIN9X
    if(IsWin9X())
        count = DragQueryFileA(handle, 0xFFFFFFFF, NULL, 0);
    else
#endif
        count = DragQueryFileW(handle, 0xFFFFFFFF, NULL, 0);

    if(items == 1) {
        mXPUSHu(count);
        XSRETURN(1);
    } else if (items == 2) {
        item = (UINT)SvIV(ST(1));
        if(item < count) {  /* item is in range */
#ifndef W32G_NO_WIN9X
            if(IsWin9X()) {
                CHAR buffer[MAX_PATH];

                cch = DragQueryFileA(handle, item, buffer, MAX_PATH);
                sv = newSVpvn(buffer,cch);
            } else {
#endif
                WCHAR wbuffer[MAX_PATH];

                cch = DragQueryFileW(handle, item, wbuffer, MAX_PATH);
                newSVpvnW(sv, wbuffer, cch);
#ifndef W32G_NO_WIN9X
            }
#endif
            XPUSHs(sv_2mortal(sv));
            XSRETURN(1);
        } else {                               /* item is out of range */
            SetLastError(ERROR_INVALID_INDEX); /* set $^E */
            errno = EINVAL;                    /* set $! */
            XSRETURN_UNDEF;                    /* and return undef */
        }
    } else {
        croak("Usage: DragQueryHandle(handle);\n   or: DragQueryHandle(handle, index);");
    }

     ##########################################################################
     # (@)WIN32API:DragQueryPoint(HDROP)
     # See Dropfiles.pm for documentation
void DragQueryPoint(handle)
    HDROP handle
PREINIT:
    POINT pt;
    UV client;
PPCODE:
    /* DragQueryPoint returns garbage if passed
     * an invalid handle, so ensure we have one
     */
    if(INVALID_HANDLE(handle)) {
        SetLastError(ERROR_INVALID_HANDLE); /* set $^E */
        errno = EINVAL;                     /* set $! */
        XSRETURN_UNDEF;                     /* and return undef */
    }
    client = (UV)DragQueryPoint(handle, &pt);
    mXPUSHi(pt.x);
    mXPUSHi(pt.y);
    mXPUSHu(client);
    XSRETURN(3);

     ##########################################################################
     # (@)WIN32API:DragFinish(HDROP)
     # See Dropfiles.pm for documentation
void
DragFinish(handle)
    HDROP handle
