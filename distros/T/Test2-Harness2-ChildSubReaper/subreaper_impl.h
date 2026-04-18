#ifndef H2_SUBREAPER_IMPL_H
#define H2_SUBREAPER_IMPL_H

#include <errno.h>
#include <unistd.h>

#if defined(__linux__)
#  include <sys/prctl.h>
#  ifdef PR_SET_CHILD_SUBREAPER
#    define H2_SUBREAPER_HAVE 1
#    define H2_SUBREAPER_MECHANISM "prctl"
     static int h2_subreaper_set(int on) {
         return prctl(PR_SET_CHILD_SUBREAPER, on ? 1 : 0, 0, 0, 0) == 0 ? 1 : 0;
     }
#  endif

#elif defined(__FreeBSD__) || defined(__DragonFly__)
#  include <sys/types.h>
#  include <sys/procctl.h>
#  if defined(PROC_REAP_ACQUIRE) && defined(PROC_REAP_RELEASE)
#    define H2_SUBREAPER_HAVE 1
#    define H2_SUBREAPER_MECHANISM "procctl"
     static int h2_subreaper_set(int on) {
         int cmd = on ? PROC_REAP_ACQUIRE : PROC_REAP_RELEASE;
         return procctl(P_PID, getpid(), cmd, NULL) == 0 ? 1 : 0;
     }
#  endif
#endif

#ifndef H2_SUBREAPER_HAVE
#  define H2_SUBREAPER_HAVE 0
#  define H2_SUBREAPER_MECHANISM NULL
   static int h2_subreaper_set(int on) {
       (void)on;
       errno = ENOSYS;
       return 0;
   }
#endif

#endif /* H2_SUBREAPER_IMPL_H */
