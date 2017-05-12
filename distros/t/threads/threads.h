#ifndef _THREADS_H_
#define _THREADS_H_

/* Needed for 5.8.0 */
#ifndef CLONEf_JOIN_IN
#  define CLONEf_JOIN_IN        8
#endif
#ifndef SAVEBOOL
#  define SAVEBOOL(a)
#endif

/* Added in 5.11.x */
#ifndef G_WANT
#  define G_WANT                (128|1)
#endif

/* Added in 5.24.x */
#ifndef PERL_TSA_RELEASE
#  define PERL_TSA_RELEASE(x)
#endif
#ifndef PERL_TSA_EXCLUDES
#  define PERL_TSA_EXCLUDES(x)
#endif
#ifndef CLANG_DIAG_IGNORE
#  define CLANG_DIAG_IGNORE(x)
#endif
#ifndef CLANG_DIAG_RESTORE
#  define CLANG_DIAG_RESTORE
#endif

#endif
