#ifndef XSH_DEBUG_H
#define XSH_DEBUG_H 1

#include "util.h" /* XSH_PACKAGE, STMT_* */

#ifndef XSH_DEBUG
# define XSH_DEBUG 0
#endif

#if XSH_DEBUG
# define XSH_D(X) STMT_START X STMT_END
static void xsh_debug_log(const char *fmt, ...) {
 va_list va;
 SV *sv;
 dTHX;
 va_start(va, fmt);
 sv = get_sv(XSH_PACKAGE "::DEBUG", 0);
 if (sv && SvTRUE(sv))
  PerlIO_vprintf(Perl_debug_log, fmt, va);
 va_end(va);
 return;
}
#else
# define XSH_D(X)
#endif

#endif /* XSH_DEBUG_H */
