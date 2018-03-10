#if !defined (P5UV_CONSTANTS_H)
#define P5UV_CONSTANTS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#include "ppport.h"
#include <uv.h>

#define DO_CONST_IV(c) \
    newCONSTSUB(stash, #c, newSViv(c)); \
    av_push(export, newSVpv(#c, 0));

/* all of these call Perl API functions and should have thread context */
extern void constants_export_uv_util(pTHX);

void constants_export_uv_util(pTHX)
{
    HV *stash = gv_stashpv("UV::Util", GV_ADD);
    AV *export = get_av("UV::Util::EXPORT_XS", TRUE);
    DO_CONST_IV(UV_ASYNC);
    DO_CONST_IV(UV_CHECK);
    DO_CONST_IV(UV_FS_EVENT);
    DO_CONST_IV(UV_FS_POLL);
    DO_CONST_IV(UV_IDLE);
    DO_CONST_IV(UV_NAMED_PIPE);
    DO_CONST_IV(UV_POLL);
    DO_CONST_IV(UV_PREPARE);
    DO_CONST_IV(UV_PROCESS);
    DO_CONST_IV(UV_STREAM);
    DO_CONST_IV(UV_TCP);
    DO_CONST_IV(UV_TIMER);
    DO_CONST_IV(UV_TTY);
    DO_CONST_IV(UV_UDP);
    DO_CONST_IV(UV_SIGNAL);
    DO_CONST_IV(UV_FILE);
    DO_CONST_IV(UV_UNKNOWN_HANDLE);
    DO_CONST_IV(UV_HANDLE);
    DO_CONST_IV(UV_HANDLE_TYPE_MAX);
}

#endif
