#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined _SOLARIS
#include <sys/types.h>
#include <sys/time.h>
#if defined USE_64_BIT_INT
typedef uint64_t func_return_t;
#else
typedef double   func_return_t;
#endif
#endif

#if defined _LINUX
#include <sys/types.h>
#include <time.h>
#if defined USE_64_BIT_INT
typedef u_int64_t func_return_t;
#else
typedef double    func_return_t;
#endif
#endif

#if defined _CYGWIN
#include <windows.h>
#if defined USE_64_BIT_INT
typedef ULARGE_INTEGER func_return_t;
#else
typedef double         func_return_t;
#endif
#endif

#if defined USE_64_BIT_INT
#   define  _T_FUNCRET_INPUT(arg,var)  	var = (func_return_t)SvUV(arg)
#   define  _T_FUNCRET_OUTPUT(arg,var)	sv_setuv(arg, (UV)var);
#else
#   define  _T_FUNCRET_INPUT(arg,var) 	var = (func_return_t)SvNV(arg)
#   define  _T_FUNCRET_OUTPUT(arg,var)	sv_setnv(arg, (func_return_t)var);
#endif

func_return_t _gethrtime() {
#if defined _SOLARIS
   return gethrtime();
#endif
#if defined _LINUX
#if defined  CLOCK_REALTIME
   struct timespec ts;
   clock_gettime(CLOCK_REALTIME, &ts);
   return ((func_return_t)ts.tv_sec)*1e9+ts.tv_nsec;
#else
   struct timeval tv;
   gettimeofday(&tv, NULL);
   return ((func_return_t)tv.tv_sec)*1e9+tv.tv_usec*1e3;
#endif
#endif
#if defined _CYGWIN
   LARGE_INTEGER ts;
   QueryPerformanceCounter(&ts);
   return (func_return_t)ts.QuadPart;
#endif
}

MODULE = Time::HR		PACKAGE = Time::HR		

func_return_t
gethrtime()
   CODE:
      RETVAL = _gethrtime();
   OUTPUT:
      RETVAL
