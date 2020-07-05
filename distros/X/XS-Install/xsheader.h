#pragma once
#define NO_XSLOCKS          /* dont hook libc calls */
#define PERLIO_NOT_STDIO 0  /* dont hook IO */
#define PERL_NO_GET_CONTEXT /* we want efficiency for threaded perls */

#ifdef _WIN32
    // perl breaks <cmath> with its fucking "isnan" macro on windows, including math.h fixes the issue
    #include <math.h>
#endif

#ifdef __cplusplus
    // perl breaks <algorithm> because of its fucking "seed" macro, so include it earlier to help XS code forget about this issue
    // we can't just undef this macro as we do for "do_open", because "seed" is used by other macros
    #include <algorithm>

    extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifdef __cplusplus
    }
#endif

#ifndef hv_storehek
  #define hv_storehek(hv,hek,val)    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), HV_FETCH_ISSTORE|HV_FETCH_JUST_SV, (val), HEK_HASH(hek))
  #define hv_fetchhek(hv,hek,lval)   ((SV**)hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (lval) ? (HV_FETCH_JUST_SV|HV_FETCH_LVALUE) : HV_FETCH_JUST_SV, NULL, HEK_HASH(hek)))
  #define hv_deletehek(hv,hek,flags) hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (flags)|HV_DELETE, NULL, HEK_HASH(hek))
#endif

#ifdef __cplusplus
    #undef do_open  // perl's macros do_open, do_close breaks <iostream>, undef it as they are not used in general
    #undef do_close
#endif
