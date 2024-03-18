#ifndef UU_NODE_H
#define UU_NODE_H

#include "ulib/UUID.h"

#ifdef cBOOL
#undef cBOOL
#endif
#define cBOOL(cbool) ((bool) (cbool))

#ifdef EXPECT
#undef EXPECT
#ifdef HAS_BUILTIN_EXPECT
#  define EXPECT(expr,val)                  __builtin_expect(expr,val)
#else
#  define EXPECT(expr,val)                  (expr)
#endif
#endif

#ifdef LIKELY
#undef LIKELY
#define LIKELY(cond)                        EXPECT(cBOOL(cond),TRUE)
#endif

#ifdef UNLIKELY
#undef UNLIKELY
#define UNLIKELY(cond)                      EXPECT(cBOOL(cond),FALSE)
#endif

#ifdef PERL_MALLOC_WRAP

# ifdef _MEM_WRAP_NEEDS_RUNTIME_CHECK
# undef _MEM_WRAP_NEEDS_RUNTIME_CHECK
# endif
# define _MEM_WRAP_NEEDS_RUNTIME_CHECK(n,t) \
    (sizeof(MEM_SIZE) < sizeof(n) || sizeof(t) > ((MEM_SIZE)1 << 8*(sizeof(MEM_SIZE) - sizeof(n))))

# ifdef _MEM_WRAP_WILL_WRAP
# undef _MEM_WRAP_WILL_WRAP
# endif
# define _MEM_WRAP_WILL_WRAP(n,t) \
    ((_MEM_WRAP_NEEDS_RUNTIME_CHECK(n,t) ? (MEM_SIZE)(n) : MEM_SIZE_MAX/sizeof(t)) > MEM_SIZE_MAX/sizeof(t))

# ifdef MEM_WRAP_CHECK
# undef MEM_WRAP_CHECK
# endif
# define MEM_WRAP_CHECK(n,t) \
    (void)(UNLIKELY(_MEM_WRAP_WILL_WRAP(n,t)) && (Perl_croak_nocontext("panic: memory wrap"),0))

#endif /* PERL_MALLOC_WRAP */
int uu_get_node_id(pUCXT, U8 *node_id);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
