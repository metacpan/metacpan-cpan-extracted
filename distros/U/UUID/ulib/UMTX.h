#ifndef ULIB__UMTX_H
#define ULIB__UMTX_H
/*
  The entire need for locking in UUID springs from the fact that some
  are using it in forked or threaded environments, not to mention the
  "thread-safety" aspects.

  The first complaint was that UUIDv4 would repeat after creating new
  threads. This was solved by moving the RNG context into a thread-safe
  container and reseeding at clone time.

  The next complaint was that UUIDv4 would repeat after forking new
  processes. This was solved by saving the process id and comparing it
  to the live pid on every call. If they differed, reseed the RNG.

  The next complaint, which has not appeared yet but will in time as
  CPUs get faster, will be that UUIDv1 repeats due to timestamp overlap.
  This can already be seen in testing and has been partially mitigated
  by implementing a counter on top of the raw time value and spinning
  the clock_seq field as needed.

  However, in light of the first two complaints, this too shall fail.
  The real solution is to move both random number and time contexts into
  a shared memory space that can be seen by both threads and forks,
  which of course presents us with a serious need for a fast, reliable
  lock.

  There does not appear to be a portable solution, so we get this.
*/

#if defined(USE_WIN32_ALIEN) || defined(USE_WIN32_NATIVE)

#  ifdef HAVE_SRWLOCK
#    define UMTX_init   InitializeSRWLock(&SMEM->LOCK)
#    define UMTX_lock   AcquireSRWLockExclusive(&SMEM->LOCK)
#    define UMTX_unlock ReleaseSRWLockExclusive(&SMEM->LOCK)
#  else
#    define UMTX_init   InitializeCriticalSection(&SMEM->LOCK)
#    define UMTX_lock   EnterCriticalSection(&SMEM->LOCK)
#    define UMTX_unlock LeaveCriticalSection(&SMEM->LOCK)
#  endif

#elif defined(__OpenBSD__)

/* sem_init() broken when pshared != 0 */
#include "FUTX.h"
#include "atomic.h"
#define UMTX_init SMEM->LOCK = 0
#define UMTX_lock { \
    long c; \
    if ((c = cmpxchg(&SMEM->LOCK, 0, 1)) != 0) { \
        if (c != 2) \
            c = xchg(&SMEM->LOCK, 2); \
        while (c != 0) { \
            futex_wait(&SMEM->LOCK, 2, 0); \
            c = xchg(&SMEM->LOCK, 2); \
        } \
    } \
}
#define UMTX_unlock { \
    if (xdec(&SMEM->LOCK) != 1) { \
        SMEM->LOCK = 0; \
        futex_wake(&SMEM->LOCK, 1); \
    } \
}

#elif defined(__APPLE__) && defined(HAVE_DISPATCH_DISPATCH_H)

/* See this link for a nice discussion on options here.
https://www.codestudy.net/blog/why-are-sem-init-sem-getvalue-sem-destroy-deprecated-on-mac-os-x-and-what-replaces-them/
 * Note that one of the workarounds is with pthreads. Their call to
 * pthread_mutex_create() discards the pshared argument, which is really
 * where all our troubles began with pthreads in general. Notably that
 * once you start needing pshared=!0, various platforms display differing
 * states of brokenness. One platform (*cough* OpenBSD) going so far as to
 * say that removing process-shared mutex was POSIX-conformant. And while
 * that's probably true, our need is not diminished.
*/
/* For OSX and archlinux but arch seems to have a working sem_init/wait */
/* dispatch_semaphore_t is a pointer type */
#define UMTX_init SMEM->LOCK = dispatch_semaphore_create(0)
#define UMTX_lock dispatch_semaphore_wait(SMEM->LOCK, DISPATCH_TIME_FOREVER)
#define UMTX_unlock dispatch_semaphore_signal(SMEM->LOCK)

#else

#define UMTX_init \
    if (sem_init(&SMEM->LOCK, 1, 1)) \
        Perl_croak_nocontext("panic: sem_init (%d) [%s:%d]", errno, __FILE__, __LINE__)
#define UMTX_lock do { \
    if (sem_wait(&SMEM->LOCK) == 0) break; \
    if (errno == EINVAL) \
        Perl_croak_nocontext("panic: sem_wait (EINVAL) [%s:%d]", __FILE__, __LINE__); \
} while (1);
#define UMTX_unlock { \
    int r = sem_post(&SMEM->LOCK); \
    if (r != 0) \
        Perl_croak_nocontext("panic: sem_post (TRUE) [%s:%d]", __FILE__, __LINE__); \
}

#endif


/* This is try/catch from XSUB.h, copied here for reference. */
#ifdef NO_XSLOCKSxxx
#  define dXCPT             dJMPENV; int rEtV = 0
#  define XCPT_TRY_START    JMPENV_PUSH(rEtV); if (rEtV == 0)
#  define XCPT_TRY_END      JMPENV_POP;
#  define XCPT_CATCH        if (rEtV != 0)
#  define XCPT_RETHROW      JMPENV_JUMP(rEtV)
#endif

#define UMTX_INIT   UMTX_init
#define UMTX_LOCK   dJMPENV; int rEtV = 0; UMTX_lock; JMPENV_PUSH(rEtV); if (rEtV == 0)
#define UMTX_UNLOCK JMPENV_POP; UMTX_unlock; if (rEtV != 0) { JMPENV_JUMP(rEtV); }

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
