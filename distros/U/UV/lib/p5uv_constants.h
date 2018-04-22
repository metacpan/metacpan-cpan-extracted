#if !defined (P5UV_CONSTANTS_H)
#define P5UV_CONSTANTS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#include "ppport.h"
#include <uv.h>

/* pulled from sys/signal.h in case we don't have it in Windows */
#if !defined(SIGPROF)
#define SIGPROF 27 /* profiling time alarm */
#endif

#if !defined(UV_DISCONNECT)
#define UV_DISCONNECT 4
#endif
#if !defined(UV_PRIORITIZED)
#define UV_PRIORITIZED 8
#endif
#if !defined(UV_VERSION_HEX)
#define UV_VERSION_HEX  ((UV_VERSION_MAJOR << 16) | \
                         (UV_VERSION_MINOR <<  8) | \
                         (UV_VERSION_PATCH))
#endif

#define DO_CONST_IV(c) \
    newCONSTSUB(stash, #c, newSViv(c)); \
    av_push(export, newSVpv(#c, 0));
#define DO_CONST_PV(c) \
    newCONSTSUB(stash, #c, newSVpvf("%s", c)); \
    av_push(export, newSVpv(#c, 0));

/* all of these call Perl API functions and should have thread context */
extern void constants_export_uv(pTHX);
extern void constants_export_uv_handle(pTHX);
extern void constants_export_uv_loop(pTHX);
extern void constants_export_uv_poll(pTHX);

void constants_export_uv(pTHX)
{
    HV *stash = gv_stashpv("UV", GV_ADD);
    AV *export = get_av("UV::EXPORT_XS", TRUE);
    DO_CONST_IV(UV_VERSION_MAJOR);
    DO_CONST_IV(UV_VERSION_MINOR);
    DO_CONST_IV(UV_VERSION_PATCH);
    DO_CONST_IV(UV_VERSION_IS_RELEASE);
    DO_CONST_IV(UV_VERSION_HEX);
    DO_CONST_PV(UV_VERSION_SUFFIX);

    /* expose the different error constants */
    DO_CONST_IV(UV_E2BIG);
    DO_CONST_IV(UV_EACCES);
    DO_CONST_IV(UV_EADDRINUSE);
    DO_CONST_IV(UV_EADDRNOTAVAIL);
    DO_CONST_IV(UV_EAFNOSUPPORT);
    DO_CONST_IV(UV_EAGAIN);
    DO_CONST_IV(UV_EAI_ADDRFAMILY);
    DO_CONST_IV(UV_EAI_AGAIN);
    DO_CONST_IV(UV_EAI_BADFLAGS);
    DO_CONST_IV(UV_EAI_BADHINTS);
    DO_CONST_IV(UV_EAI_CANCELED);
    DO_CONST_IV(UV_EAI_FAIL);
    DO_CONST_IV(UV_EAI_FAMILY);
    DO_CONST_IV(UV_EAI_MEMORY);
    DO_CONST_IV(UV_EAI_NODATA);
    DO_CONST_IV(UV_EAI_NONAME);
    DO_CONST_IV(UV_EAI_OVERFLOW);
    DO_CONST_IV(UV_EAI_PROTOCOL);
    DO_CONST_IV(UV_EAI_SERVICE);
    DO_CONST_IV(UV_EAI_SOCKTYPE);
    DO_CONST_IV(UV_EALREADY);
    DO_CONST_IV(UV_EBADF);
    DO_CONST_IV(UV_EBUSY);
    DO_CONST_IV(UV_ECANCELED);
    DO_CONST_IV(UV_ECHARSET);
    DO_CONST_IV(UV_ECONNABORTED);
    DO_CONST_IV(UV_ECONNREFUSED);
    DO_CONST_IV(UV_ECONNRESET);
    DO_CONST_IV(UV_EDESTADDRREQ);
    DO_CONST_IV(UV_EEXIST);
    DO_CONST_IV(UV_EFAULT);
    DO_CONST_IV(UV_EFBIG);
    DO_CONST_IV(UV_EHOSTUNREACH);
    DO_CONST_IV(UV_EINTR);
    DO_CONST_IV(UV_EINVAL);
    DO_CONST_IV(UV_EIO);
    DO_CONST_IV(UV_EISCONN);
    DO_CONST_IV(UV_EISDIR);
    DO_CONST_IV(UV_ELOOP);
    DO_CONST_IV(UV_EMFILE);
    DO_CONST_IV(UV_EMSGSIZE);
    DO_CONST_IV(UV_ENAMETOOLONG);
    DO_CONST_IV(UV_ENETDOWN);
    DO_CONST_IV(UV_ENETUNREACH);
    DO_CONST_IV(UV_ENFILE);
    DO_CONST_IV(UV_ENOBUFS);
    DO_CONST_IV(UV_ENODEV);
    DO_CONST_IV(UV_ENOENT);
    DO_CONST_IV(UV_ENOMEM);
    DO_CONST_IV(UV_ENONET);
    DO_CONST_IV(UV_ENOPROTOOPT);
    DO_CONST_IV(UV_ENOSPC);
    DO_CONST_IV(UV_ENOSYS);
    DO_CONST_IV(UV_ENOTCONN);
    DO_CONST_IV(UV_ENOTDIR);
    DO_CONST_IV(UV_ENOTEMPTY);
    DO_CONST_IV(UV_ENOTSOCK);
    DO_CONST_IV(UV_ENOTSUP);
    DO_CONST_IV(UV_EPERM);
    DO_CONST_IV(UV_EPIPE);
    DO_CONST_IV(UV_EPROTO);
    DO_CONST_IV(UV_EPROTONOSUPPORT);
    DO_CONST_IV(UV_EPROTOTYPE);
    DO_CONST_IV(UV_ERANGE);
    DO_CONST_IV(UV_EROFS);
    DO_CONST_IV(UV_ESHUTDOWN);
    DO_CONST_IV(UV_ESPIPE);
    DO_CONST_IV(UV_ESRCH);
    DO_CONST_IV(UV_ETIMEDOUT);
    DO_CONST_IV(UV_ETXTBSY);
    DO_CONST_IV(UV_EXDEV);
    DO_CONST_IV(UV_UNKNOWN);
    DO_CONST_IV(UV_EOF);
    DO_CONST_IV(UV_ENXIO);
    DO_CONST_IV(UV_EMLINK);
}

void constants_export_uv_handle(pTHX)
{
    HV *stash = gv_stashpv("UV::Handle", GV_ADD);
    AV *export = get_av("UV::Handle::EXPORT_XS", TRUE);

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
}

void constants_export_uv_loop(pTHX)
{
    HV *stash = gv_stashpv("UV::Loop", GV_ADD);
    AV *export = get_av("UV::Loop::EXPORT_XS", TRUE);

    /* Loop run constants */
    DO_CONST_IV(UV_RUN_DEFAULT);
    DO_CONST_IV(UV_RUN_ONCE);
    DO_CONST_IV(UV_RUN_NOWAIT);
    /* expose the Loop configure constants */
    DO_CONST_IV(UV_LOOP_BLOCK_SIGNAL);
    DO_CONST_IV(SIGPROF);
}

void constants_export_uv_poll(pTHX)
{
    HV *stash = gv_stashpv("UV::Poll", GV_ADD);
    AV *export = get_av("UV::Poll::EXPORT_XS", TRUE);

    /* Poll Event Types */
    DO_CONST_IV(UV_READABLE);
    DO_CONST_IV(UV_WRITABLE);
    DO_CONST_IV(UV_DISCONNECT);
    DO_CONST_IV(UV_PRIORITIZED);
}

#endif
