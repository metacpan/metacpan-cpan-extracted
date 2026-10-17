#ifndef TK_NOW_H
#define TK_NOW_H

/* The current time, to the nanosecond where the system gives it.
 *
 * TK_HAVE_CLOCK_GETTIME is set by Makefile.PL when a program calling
 * clock_gettime(CLOCK_REALTIME) compiles and links with no extra library.
 * Where it does not (glibc before 2.17 wants -lrt), gettimeofday gives
 * microseconds. On Windows the system time is in 100ns steps from 1601. */

#ifdef WIN32
#  include <windows.h>
#else
#  include <sys/time.h>
#  include <time.h>
#endif

static void
tk_now(tk_instant *t)
{
#if defined(WIN32)
    FILETIME ft;
    uint64_t ticks;
    GetSystemTimeAsFileTime(&ft);
    ticks = ((uint64_t)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
    ticks -= (uint64_t)116444736000000000ULL;
    t->sec = (int64_t)(ticks / 10000000);
    t->nsec = (int32_t)(ticks % 10000000) * 100;
#elif defined(TK_HAVE_CLOCK_GETTIME)
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    t->sec = (int64_t)ts.tv_sec;
    t->nsec = (int32_t)ts.tv_nsec;
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    t->sec = (int64_t)tv.tv_sec;
    t->nsec = (int32_t)tv.tv_usec * 1000;
#endif
}

static int
tk_now_resolution_ns(void)
{
#if defined(WIN32)
    return 100;
#elif defined(TK_HAVE_CLOCK_GETTIME)
    return 1;
#else
    return 1000;
#endif
}

#endif
