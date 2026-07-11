/*
 * Nanos.xs - XS implementation of Time::Nanos
 *
 * Provides a single XS function, hrtime(), that returns a high-resolution
 * timestamp in nanoseconds.  Two backends are supported:
 *
 *   HAS_CLOCK_GETTIME - POSIX clock_gettime(2) (Linux, macOS, BSD, ...)
 *   HAS_WINHR         - Windows high-resolution timers
 *
 * If neither is defined at compile time, hrtime() croaks at runtime.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdint.h>

#ifdef HAS_CLOCK_GETTIME
#include <time.h>
#include <errno.h>
#include <string.h>
#endif

#ifdef HAS_WINHR
#include <windows.h>
#endif

/*
 * Populate *sec_out / *nsec_out with the current time from the requested
 * clock source.
 * use_realtime=1 -> CLOCK_REALTIME  (wall-clock),
 * use_realtime=0 -> CLOCK_MONOTONIC (time since boot, immune to jumps).
 */
#if defined(HAS_CLOCK_GETTIME) || defined(HAS_WINHR)
static void
get_hrtime(int use_realtime, uint64_t *sec_out, uint64_t *nsec_out)
{
#ifdef HAS_CLOCK_GETTIME
    {
        struct timespec ts;
        clockid_t clock_id = use_realtime ? CLOCK_REALTIME : CLOCK_MONOTONIC;
        if (clock_gettime(clock_id, &ts) != 0) {
            croak("hrtime(): clock_gettime() failed: %s", strerror(errno));
        }
        *sec_out  = (uint64_t)ts.tv_sec;
        *nsec_out = (uint64_t)ts.tv_nsec;
    }
#else
    if (use_realtime) {
        /* Windows: GetSystemTimePreciseAsFileTime gives 100 ns intervals
         * since 1601-01-01.  Adjust epoch to 1970-01-01 and convert. */
        FILETIME ft;
        ULARGE_INTEGER ul;
        GetSystemTimePreciseAsFileTime(&ft);
        ul.LowPart  = ft.dwLowDateTime;
        ul.HighPart = ft.dwHighDateTime;
        ul.QuadPart -= 116444736000000000ULL;                /* 1601 -> 1970 offset */
        *sec_out    = ul.QuadPart / 10000000ULL;             /* 100 ns -> sec       */
        *nsec_out   = (ul.QuadPart % 10000000ULL) * 100ULL;  /* remainder -> ns     */
    } else {
        /* Windows: QueryPerformanceCounter for monotonic time */
        LARGE_INTEGER freq, counter;
        int64_t remainder;
        if (!QueryPerformanceFrequency(&freq)) {
            croak("hrtime(): QueryPerformanceFrequency() failed");
        }
        if (!QueryPerformanceCounter(&counter)) {
            croak("hrtime(): QueryPerformanceCounter() failed");
        }
        *sec_out  = (uint64_t)(counter.QuadPart / freq.QuadPart);
        remainder = counter.QuadPart % freq.QuadPart;
        *nsec_out = (uint64_t)((remainder * 1000000000LL) / freq.QuadPart);
    }
#endif
}
#endif

MODULE = Time::Nanos    PACKAGE = Time::Nanos

PROTOTYPES: DISABLE

void
hrtime(int clock_source)
    PPCODE:
        /*
         * Returns a nanosecond-precision timestamp as a single integer.
         *
         * clock_source:
         *   0 -> CLOCK_REALTIME  (wall-clock, default)
         *   1 -> CLOCK_MONOTONIC (time since boot, immune to jumps)
         *
         * Any other value croaks.
         */
#if !defined(HAS_CLOCK_GETTIME) && !defined(HAS_WINHR)
        croak("hrtime(): high-resolution clock is not available on this platform");
#else
        {
            uint64_t sec_part, nsec_part;
            int use_realtime = 0;

            if (clock_source == 0) {
                use_realtime = 1;
            } else if (clock_source == 1) {
                use_realtime = 0;
            } else {
                croak("hrtime(): invalid clock source %d (valid: 0 = realtime, 1 = monotonic)", clock_source);
            }

            get_hrtime(use_realtime, &sec_part, &nsec_part);

            {
                uint64_t total = sec_part * 1000000000ULL + nsec_part;

                EXTEND(SP, 1);
#if UVSIZE >= 8
                /* 64-bit UV (typical): exact integer nanoseconds. */
                PUSHs(sv_2mortal(newSVuv((UV)total)));
#else
                /* 32-bit UV perl: a 64-bit ns cannot fit in UV and a plain
                 * scalar cannot hold a 64-bit int, so return it as an NV
                 * (double). This avoids silently wrapping to garbage; the
                 * value loses precision (~256 ns at the current epoch) but
                 * stays "close" and keeps the array split sane. */
                PUSHs(sv_2mortal(newSVnv((NV)total)));
#endif
            }
        }
#endif
