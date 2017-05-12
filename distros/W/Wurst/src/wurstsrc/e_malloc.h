/*
 * For a verbose, checking malloc
 * The functions should be called via the macros, E_MALLOC and E_REALLOC.
 * For fun, we add in the function attributes which tell gcc that there
 * will be no aliasing of returned pointers. These may or may not help.
 * They are written so they will do no harm with other compilers.
 * rcsid = $Id: e_malloc.h,v 1.1 2007/09/28 16:57:11 mmundry Exp $
 */
#ifndef __E_MALLOC_H
#define __E_MALLOC_H
#ifndef E_MALLOC
#   define E_MALLOC(x) e_malloc ((x), __FILE__, __LINE__)
#endif
#ifndef E_REALLOC
#   define E_REALLOC(p,s) e_realloc ((p), (s), __FILE__, __LINE__)
#endif
#ifndef E_CALLOC
#   define E_CALLOC(n,s) e_calloc ((n), (s), __FILE__, __LINE__)
#endif

/* For the gnu compiler, the attribute tells it a bit about
 * pointer aliasing (or lack thereof).
 */
void *e_malloc(size_t x, const char *f, const int l)
#if (__GNUC__) && (__GNUC__ > 2)
     __attribute__ ((malloc))
#endif /* __GNUC__ */
;

void *e_realloc(void *p, size_t x, const char *f, const int l)
#if (__GNUC__) && (__GNUC__ > 2)
     __attribute__ ((malloc))
#endif /* __GNUC__ */
;

void *e_calloc(size_t n, size_t s, const char *f, const int l)
#if (__GNUC__) && (__GNUC__ > 2)
     __attribute__ ((malloc))
#endif /* __GNUC__ */
;


void  free_if_not_null ( void *);
#endif /* __E_MALLOC_H */
