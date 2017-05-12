#ifndef _COMMON_H
#define _COMMON_H

// Define for debug output
//#define XS_DEBUG

// Define for memory new/free debug
//#define MEM_DEBUG

#ifdef XS_DEBUG
# define DEBUG_TRACE(...) fprintf(stderr, __VA_ARGS__)
#else
# define DEBUG_TRACE(...)
# define buffer_dump(...)
#endif

#ifdef MEM_DEBUG
# define MEM_TRACE(...) frintf(stderr, __VA_ARGS__)
#else
# define MEM_TRACE(...)
#endif

#if __GNUC__ >= 4
# define likely(x)   __builtin_expect(!!(x), 1)
# define unlikely(x) __builtin_expect(!!(x), 0)
#else
# define likely(x)   (x)
# define unlikely(x) (x)
#endif

#define my_hv_store(a,b,c)     hv_store(a,b,strlen(b),c,0)
#define my_hv_store_ent(a,b,c) hv_store_ent(a,b,c,0)
#define my_hv_fetch(a,b)       hv_fetch(a,b,strlen(b),0)
#define my_hv_exists(a,b)      hv_exists(a,b,strlen(b))
#define my_hv_exists_ent(a,b)  hv_exists_ent(a,b,0)
#define my_hv_delete(a,b)      hv_delete(a,b,strlen(b),0)

#define THROW(class, message)                                                        \
  HV *exception = newHV();                                                           \
  my_hv_store(exception, "message", newSVpv(message, 0));                            \
  my_hv_store(exception, "code", newSViv(0));                                        \
  SV *errsv = get_sv("@", GV_ADD);                                                   \
  sv_setsv(errsv, sv_bless(newRV_noinc((SV *)exception), gv_stashpv(class, TRUE)));  \
  croak(NULL)

#define THROW_SV(class, message)                                                     \
  HV *exception = newHV();                                                           \
  my_hv_store(exception, "message", message);                                        \
  my_hv_store(exception, "code", newSViv(0));                                        \
  SV *errsv = get_sv("@", GV_ADD);                                                   \
  sv_setsv(errsv, sv_bless(newRV_noinc((SV *)exception), gv_stashpv(class, TRUE)));  \
  croak(NULL)

#endif
