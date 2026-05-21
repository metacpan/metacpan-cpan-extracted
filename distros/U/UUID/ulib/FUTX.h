#ifndef ULIB__FUTX_H
#define ULIB__FUTX_H

#include "ulib/UUID.h"

/* OpenBSD added futex() to libc since syscall mostly blocked from luserland. */
#if defined(__OpenBSD__)
#define futex_wait(uaddr, val, timeout) futex(uaddr, FUTEX_WAIT, val, timeout, 0);
#define futex_wake(uaddr, val)          futex(uaddr, FUTEX_WAKE, val, 0, 0);
#endif

/* FreeBSD does not have futex() function or syscall. */

/*
 * Not needed with AcquireSRWLockExclusive().
 *
#if defined(_WIN32)
#include <Windows.h>
bool futex_wait(LONG *uaddr, LONG val, DWORD timeout);
void futex_wake(LONG *uaddr, LONG val);
#endif
*/

/*
 * Not needed with AcquireSRWLockExclusive().
 *
#if defined(__CYGWIN__)
#include <Windows.h>
#define futex_wait(uaddr, val, timeout) ({ typeof(*(uaddr)) _val = (val); WaitOnAddress(uaddr, &_val, sizeof(_val), timeout); })
#define futex_wake(uaddr, val)          WakeByAddressSingle(uaddr)
#endif
*/

/*
 * Not needed with switch to sem_wait().
 *
#if defined(__linux__)
#include <unistd.h>
#include <linux/futex.h>
#include <sys/syscall.h>
#define futex_wait(uaddr, val, timeout) syscall(SYS_futex, uaddr, FUTEX_WAIT, val, timeout, 0, 0);
#define futex_wake(uaddr, val)          syscall(SYS_futex, uaddr, FUTEX_WAKE, val, 0, 0, 0);
#endif
*/

#endif
