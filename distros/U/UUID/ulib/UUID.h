#ifndef UU_UUID_H
#define UU_UUID_H

/* Enable extensions on AIX 3, Interix.  */
#ifndef _ALL_SOURCE
# undef _ALL_SOURCE
#endif
/* Enable general extensions on macOS.  */
#ifndef _DARWIN_C_SOURCE
# undef _DARWIN_C_SOURCE
#endif
/* Enable general extensions on Solaris.  */
#ifndef __EXTENSIONS__
# undef __EXTENSIONS__
#endif
/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# undef _GNU_SOURCE
#endif
/* Enable X/Open compliant socket functions that do not require linking
   with -lxnet on HP-UX 11.11.  */
#ifndef _HPUX_ALT_XOPEN_SOCKET_API
# undef _HPUX_ALT_XOPEN_SOCKET_API
#endif
/* Identify the host operating system as Minix.
   This macro does not affect the system headers' behavior.
   A future release of Autoconf may stop defining this macro.  */
#ifndef _MINIX
# undef _MINIX
#endif
/* Enable general extensions on NetBSD.
   Enable NetBSD compatibility extensions on Minix.  */
#ifndef _NETBSD_SOURCE
# undef _NETBSD_SOURCE
#endif
/* Enable OpenBSD compatibility extensions on NetBSD.
   Oddly enough, this does nothing on OpenBSD.  */
#ifndef _OPENBSD_SOURCE
# undef _OPENBSD_SOURCE
#endif
/* Define to 1 if needed for POSIX-compatible behavior.  */
#ifndef _POSIX_SOURCE
# undef _POSIX_SOURCE
#endif
/* Define to 2 if needed for POSIX-compatible behavior.  */
#ifndef _POSIX_1_SOURCE
# undef _POSIX_1_SOURCE
#endif
/* Enable POSIX-compatible threading on Solaris.  */
#ifndef _POSIX_PTHREAD_SEMANTICS
# undef _POSIX_PTHREAD_SEMANTICS
#endif
/* Enable extensions specified by ISO/IEC TS 18661-5:2014.  */
#ifndef __STDC_WANT_IEC_60559_ATTRIBS_EXT__
# undef __STDC_WANT_IEC_60559_ATTRIBS_EXT__
#endif
/* Enable extensions specified by ISO/IEC TS 18661-1:2014.  */
#ifndef __STDC_WANT_IEC_60559_BFP_EXT__
# undef __STDC_WANT_IEC_60559_BFP_EXT__
#endif
/* Enable extensions specified by ISO/IEC TS 18661-2:2015.  */
#ifndef __STDC_WANT_IEC_60559_DFP_EXT__
# undef __STDC_WANT_IEC_60559_DFP_EXT__
#endif
/* Enable extensions specified by ISO/IEC TS 18661-4:2015.  */
#ifndef __STDC_WANT_IEC_60559_FUNCS_EXT__
# undef __STDC_WANT_IEC_60559_FUNCS_EXT__
#endif
/* Enable extensions specified by ISO/IEC TS 18661-3:2015.  */
#ifndef __STDC_WANT_IEC_60559_TYPES_EXT__
# undef __STDC_WANT_IEC_60559_TYPES_EXT__
#endif
/* Enable extensions specified by ISO/IEC TR 24731-2:2010.  */
#ifndef __STDC_WANT_LIB_EXT2__
# undef __STDC_WANT_LIB_EXT2__
#endif
/* Enable extensions specified by ISO/IEC 24747:2009.  */
#ifndef __STDC_WANT_MATH_SPEC_FUNCS__
# undef __STDC_WANT_MATH_SPEC_FUNCS__
#endif
/* Enable extensions on HP NonStop.  */
#ifndef _TANDEM_SOURCE
# undef _TANDEM_SOURCE
#endif
/* Enable X/Open extensions.  Define to 500 only if necessary
   to make mbstate_t available.  */
#ifndef _XOPEN_SOURCE
# undef _XOPEN_SOURCE
#endif

#define PERL_NO_GET_CONTEXT
#include "ulib/EUMM.h"
#include "EXTERN.h"
#include "perl.h"
#include "ulib/TYPE.h"
#include "ulib/PORT.h"

#ifdef SvPVbyte
# if PERL_VERSION_EQ(5,6,1)
    /* SvPVbyte does not work in perl-5.6.1, borrowed version for 5.7.3 */
#   undef SvPVbyte
#   define SvPVbyte(sv, lp) \
      ((SvFLAGS(sv) & (SVf_POK|SVf_UTF8)) == (SVf_POK) \
      ? ((lp = SvCUR(sv)), SvPVX(sv)) : my_sv_2pvbyte(aTHX_ sv, &lp))

      static char *
      my_sv_2pvbyte(pTHX_ register SV *sv, STRLEN *lp) {
        sv_utf8_downgrade(sv,0);
        return SvPV(sv,*lp);
      }
# endif
#else
# define SvPVbyte SvPV
#endif

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
