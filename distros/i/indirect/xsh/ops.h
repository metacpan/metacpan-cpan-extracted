#ifndef XSH_OPS_H
#define XSH_OPS_H 1

#include "caps.h" /* XSH_HAS_PERL() */
#include "util.h" /* NOOP */

#ifdef XSH_THREADS_H
# error threads.h must be loaded at the very end
#endif

#ifndef XSH_THREADS_GLOBAL_SETUP
# define XSH_THREADS_GLOBAL_SETUP 1
#endif

#ifndef XSH_THREADS_GLOBAL_TEARDOWN
# define XSH_THREADS_GLOBAL_TEARDOWN 1
#endif

#ifndef OpSIBLING
# ifdef OP_SIBLING
#  define OpSIBLING(O) OP_SIBLING(O)
# else
#  define OpSIBLING(O) ((O)->op_sibling)
# endif
#endif

#ifndef OpMAYBESIB_set
# define OpMAYBESIB_set(O, S, P) ((O)->op_sibling = (S))
#endif

#ifndef OP_NAME
# define OP_NAME(O) (PL_op_name[(O)->op_type])
#endif

#ifndef OP_CLASS
# define OP_CLASS(O) (PL_opargs[(O)->op_type] & OA_CLASS_MASK)
#endif

#if defined(OP_CHECK_MUTEX_LOCK) && defined(OP_CHECK_MUTEX_UNLOCK)
# define XSH_CHECK_LOCK   OP_CHECK_MUTEX_LOCK
# define XSH_CHECK_UNLOCK OP_CHECK_MUTEX_UNLOCK
#elif XSH_HAS_PERL(5, 9, 3)
# define XSH_CHECK_LOCK   OP_REFCNT_LOCK
# define XSH_CHECK_UNLOCK OP_REFCNT_UNLOCK
#else
/* Before perl 5.9.3, da_ck_*() calls are already protected by the XSH_LOADED
 * mutex, which falls back to the OP_REFCNT mutex. Make sure we don't lock it
 * twice. */
# define XSH_CHECK_LOCK   NOOP
# define XSH_CHECK_UNLOCK NOOP
#endif

typedef OP *(*xsh_check_t)(pTHX_ OP *);

#ifdef wrap_op_checker

# define xsh_ck_replace(T, NC, OCP) wrap_op_checker((T), (NC), (OCP))

#else

static void xsh_ck_replace(pTHX_ OPCODE type, xsh_check_t new_ck, xsh_check_t *old_ck_p) {
#define xsh_ck_replace(T, NC, OCP) xsh_ck_replace(aTHX_ (T), (NC), (OCP))
 XSH_CHECK_LOCK;
 if (!*old_ck_p) {
  *old_ck_p      = PL_check[type];
  PL_check[type] = new_ck;
 }
 XSH_CHECK_UNLOCK;
}

#endif

static void xsh_ck_restore(pTHX_ OPCODE type, xsh_check_t *old_ck_p) {
#define xsh_ck_restore(T, OCP) xsh_ck_restore(aTHX_ (T), (OCP))
 XSH_CHECK_LOCK;
 if (*old_ck_p) {
  PL_check[type] = *old_ck_p;
  *old_ck_p      = 0;
 }
 XSH_CHECK_UNLOCK;
}

#endif /* XSH_OPS_H */
