/* errmac.h  -  Utility, debugging, and error checking macros
 *
 * Copyright (c) 1998,2001,2006,2010-2014 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * Copyright (c) 2001-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * This is free software and comes with NO WARRANTY. Licensed under Apache2 license.
 * $Id$
 *
 * 10.1.2003, added option to make ASSERT nonfatal --Sampo
 * 4.6.2003,  added STRERROR() macro --Sampo
 * 11.7.2003, added MUTEX_DEBUG, ASSERT_THR(), ASSERT_NOT_IN_LOCK() --Sampo
 * 6.10.2003, added ALIGN128 (16 byte alignment) --Sampo
 * 12.12.2003, added AK support to asserts --Sampo
 * 15.1.2004, added STRNULLCHK() --Sampo
 * 24.2.2006, made some definitions conditional --Sampo
 * 15.4.2006, new adaptation over Easter holiday --Sampo
 * 3.10.2007, added FLOCK() and FUNLOCK() --Sampo
 * 22.3.2008, renamed debug to zx_debug to avoid conflicts in any .so module usage --Sampo
 * 4.12.2010, fixed bug in locking where range was zero length --Sampo
 * 4.12.2011, fixed bug in TOUPPER() macro --Sampo
 * 30.10.2012, added AKBOX_FN() to logging --Sampo
 */

#ifndef _errmac_h
#define _errmac_h

#ifndef MAYBE_UNUSED
#define MAYBE_UNUSED __attribute__ ((unused))
#endif

#ifdef MINGW
#include <windows.h>
#else
#include <pthread.h>
#endif
#include <stdio.h>    /* For stderr */
#include <stdint.h>

#ifdef USE_AKBOX_FN
#include "akbox.h"
#endif

/* CONFIG */

#if 0
#define trace 1
#define assert_nonfatal 0
#else
extern int assert_nonfatal;
extern int trace;   /* this gets manipulated by -v or similar flag */
#endif

#define TCP_PROTO 6 /* never seen getprotobyname("tcp") return anything else */

/* END CONFIG */

/* For bracketing macros so that they appear as single statement. */
/* Note: MB = MACRO_BEGIN, ME = MACRO_END */
 
#define MB do {
#define ME } while(0)

#define unless(x) if(!(x))

#define STRERROR(en) (strerror(en)?strerror(en):"???")

/* Since Solaris printf does not grog NULL pointers eve if field with is zero, we need to
 * liberally apply an explicit NULL check whenever we call printf family (glibc printf
 * is much more reasonable and does not require such silly checks). */
#define STRNULLCHK(s)  ((s)?(char*)(s):"")
#define STRNULLCHKQ(s) ((s)?(char*)(s):"?")
#define STRNULLCHKD(s) ((s)?(char*)(s):"-")
#define STRNULLCHKZ(s) ((s)?(char*)(s):"0")
#define STRNULLCHKNULL(s) ((s)?(char*)(s):"(null)")

/* Common datatypes */

#ifndef U8
#define U8 unsigned char
#endif
#ifndef CU8
#define CU8 const unsigned char
#endif

#ifndef U16_MAX
#define U16_MAX 65535
#endif
#ifndef I16_MAX
#define I16_MAX 32767
#endif
#ifndef I32_MAX
#define I32_MAX 0x7fffffff
#endif

/* Pessimistic maximum string conversion lengths.
 *   2^n == 10^x
 *   x = n * l(2)/l(10)   ; l == ln or log
 * 9         --> 3 chars + sign + NUL
 * 13 = 3.9  --> 4 chars + sign + NUL
 * 32 = 9.6  --> 10 chars + sign + NUL
 * 64 = 19.2 --> 20 chars + sign + NUL = 22
 *
 * A double is 64 bits total, thus mantissa can never exceed 64 bit int.
 * The exponent takes `E', sign, and length of the exponent of 16 bits.
 */

#define INTSTRLEN 22
#define DBLSTRLEN 30

/* WARNING: Many of these macros evaluate arguments more than once (and
 * not all arguments get necessarily evaluated at all). Beware of
 * passing return values of functions as arguments, because then the
 * function may get called twice. */

#define ABS(x)                    ( ((x) <  0) ? -(x) : (x) )
#define IN_RANGE(x,a,b)           ( ((x) >= (a)) ? ((x) <= (b)) : 0 )
#define IN_RANGE_EXCLUSIVE(x,a,b) ( ((x) >  (a)) ? ((x) <  (b)) : 0 )
 
/*#define WHITESPACE(c)             ((c) == ' ' || (c) == '\t' || (c) == '\n')*/
#define WHITESPACE(c) ((c) == ' ' || (c) == '\t' || (c) == '\n' || (c) =='\r' || (c) == '\f')

#ifndef MIN
#define MIN(a,b) ( ((a) < (b)) ? (a) : (b) )
#endif
#ifndef MAX
#define MAX(a,b) ( ((a) > (b)) ? (a) : (b) )
#endif
 
#define MIN3(a,b,c)   MIN((a), MIN((b),(c)))
#define MIN4(a,b,c,d) MIN(MIN((a),(b)), MIN((c),(d)))

#define MAX3(a,b,c)   MAX((a), MAX((b),(c)))
#define MAX4(a,b,c,d) MAX(MAX((a),(b)), MAX((c),(d)))

#define MINMAX(x,min,max) (MIN(MAX((x),(min)),(max)))
#define CLAMP(x,min,max) ((x) = MINMAX((x),(min),(max)))
 
#define ONE_OF_2(x,a,b)     (((x) == (a)) || ((x) == (b)))
#define ONE_OF_3(x,a,b,c)   (ONE_OF_2((x),(a),(b)) || ((x) == (c)))
#define ONE_OF_4(x,a,b,c,d) (ONE_OF_2((x),(a),(b)) || ONE_OF_2((x),(c),(d)))
#define ONE_OF_5(x,a,b,c,d,e) (ONE_OF_3((x),(a),(b),(c)) || ONE_OF_2((x),(d),(e)))
#define ONE_OF_6(x,a,b,c,d,e,f) (ONE_OF_3((x),(a),(b),(c)) || ONE_OF_3((x),(d),(e),(f)))
#define ONE_OF_7(x,a,b,c,d,e,f,g)   (ONE_OF_4((x),(a),(b),(c),(g)) || ONE_OF_3((x),(d),(e),(f)))
#define ONE_OF_8(x,a,b,c,d,e,f,g,h) (ONE_OF_4((x),(a),(b),(c),(g)) || ONE_OF_4((x),(d),(e),(f),(h)))

#define THREE_IN_ROW(p,a,b,c) ((p)[0] == (a) && (p)[1] == (b) && (p)[2] == (c))

#define STR_TERM '\0'
 
#define TOUPPER(x) (IN_RANGE(x, 'a', 'z') ? ((x) - ('a' - 'A')) : (x))
#define TOLOWER(x) (IN_RANGE(x, 'A', 'Z') ? ((x) - ('A' - 'a')) : (x))

#define BOOL_STR_TEST(x) ((x) && (x) != '0')
 
/* Copy memory and null terminate string. strncpy strings and
   guarantee null termination (strncpy does not). */
 
#define MEMCPYZ(to,fro,l) MB memcpy((to),(fro),(l)); (to)[(l)]   = 0x00; ME
#define strnzcpy(to,f,l)  MB strncpy((to),(f),(l));  (to)[(l)-1] = '\0'; ME
 

#define AZaz_09_(x) ( IN_RANGE((x), '0', '9') || ((x) == '_') || \
                    IN_RANGE((x), 'A', 'Z') || IN_RANGE((x), 'a', 'z') )
#define AZaz_09_dash(x) ( IN_RANGE((x), '0', '9') || ((x) == '_') || \
                    ((x) == '-') || \
                    IN_RANGE((x), 'A', 'Z') || IN_RANGE((x), 'a', 'z') )
#define AZaz_09_dot(x) ( IN_RANGE((x), '0', '9') || ((x) == '_') || \
                    ((x)=='.') || ((x) == '-') || \
                    IN_RANGE((x), 'A', 'Z') || IN_RANGE((x), 'a', 'z') )
#define AZaz_09_dot_plus(x) ( IN_RANGE((x), '0', '9') || ((x) == '_') || \
                    ((x)=='.') || ((x) == '-') || ((x) == '+') || \
                    IN_RANGE((x), 'A', 'Z') || IN_RANGE((x), 'a', 'z') )
#define AZaz_(x) ( ((x) == '_') || \
                    IN_RANGE((x), 'A', 'Z') || IN_RANGE((x), 'a', 'z') )
#define IS_ALPHA(x) (IN_RANGE((x), 'A', 'Z') || IN_RANGE((x), 'a', 'z'))
#define IS_ALNUM(x) (IS_ALPHA(x) || IS_DIGIT(x) || (x) == '_')

/* Find the next newline starting from p and bound by e, set a to addr or 0 if not found */
#define FIND_NL(a,p,e) MB for((a)=(p);((a)<(e))&&(*(a)!=0x0a);++(a));if((a)==(e)) (a)=0; ME

#define IS_DIGIT(x) IN_RANGE((x), '0', '9')
#define IS_HEX(x) ( IN_RANGE((x), '0', '9') || \
                    IN_RANGE((x), 'A', 'F') || IN_RANGE((x), 'a', 'f') )

#define HEX(x) (IN_RANGE((x), '0', '9') ? ((x) - '0') : (((x) & 0x07) + 9))
#define HEX_DIGIT(x) (((x)<10) ? ((x) + '0') : ((x) - 10 + 'A'))
 
#define CONV_DIGIT(x) ((x) - '0')

#define LEAP(a) (!((a)%4) && (((a)%100) || !((a)%400))) /* Input full year, like 1984 or 2011 */

#define ROUND_UP(x,n) if ((n) && (x) % (n)) x += (n) - (x) % (n);

/* Original Base64  Len  (x+2) / 3
 * ""       ""        0  2     0(2)     Suitable original(packed) sizes = bits
 * 1        WX==      4  3     1(0)     to avoid padding are
 * 12       WXY=      4  4     1(1)      3(4) = 24,   6(8)= 48,  9(12)= 72, 12(16)= 96,
 * 123      WXYZ      4  5     1(2)     15(20)=120, 18(24)=144, 21(28)=168, 24(32)=192,
 * 1234     WXYZwx==  8  6     2(0)     27(36)=216, 30(40)=240, 33(44)=264, 36(48)=288
 * 12345    WXYZwxy=  8  7     2(1)
 * 123456   WXYZwxyz  8  8     2(2)
 */
#define SIMPLE_BASE64_LEN(x) (((x)+2) / 3 * 4)  /* exact encoded length given binary length */
#define SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(x) (((x)+3)/4*3)
#define DEFLATE_PESSIMISTIC_LEN(x) ((x)+((x)>>8)+12)  /* zlib worst case: orig_size * 1.001 + 12, see also compressBound() */
#define OAEP_LEN 41 /* Overhead of PKCS#1 v2.0 OAEP padding */

/* Perform URL conversion in place
 *   src = dst = buffer_where_data_is;
 *   URL_DECODE(src,dst,buf+sizeof(buf));
 *   *dst = 0;   // nul terminate
 *   len = dst - buf;
 * The dst pointer need not point to same buffer as src, though it can (to effectuate an
 * in-place conversion). The converted length is the difference with original dst and final dst.
 * src and dst MUST be different variables (even if they point to same place).
 * lim is one beyond end of the src data. Resulting conversion is always shorter
 * or equal to original. Both src and dst will be altered. Conversion is not nul terminated. */
#define URL_DECODE(dst,src,lim) MB while ((src) < (lim)) \
  if ((*(src) == '%') && ((src) < ((lim)-2)) && IS_HEX((src)[1]) && IS_HEX((src)[2])) \
    { *((dst)++) = (HEX((src)[1]) << 4) | HEX((src)[2]); (src) += 3; } \
  else if (*(src) == '+') { *((dst)++) = ' '; ++(src); } \
  else *((dst)++) = *((src)++); ME

/* Usage: you must set nodes to root prior to calling this macro, for example
 * v = s->first; REVERSE_LIST_NEXT(s->first, v, vnext);
 * The nodes argument is "iterator". The reveresed list is left in root. */
#define REVERSE_LIST_NEXT(root,nodes,nxt) MB (root) = 0; \
  while (nodes) { void* n = (nodes)->nxt; (nodes)->nxt = (void*)(root); \
    (root) = (void*)(nodes); (nodes) = n;  } ME

#define REVERSE_LIST(root,nodes) REVERSE_LIST_NEXT((root),(nodes),next)

#if 0
# define DLIST_ADD(head,x) MB (x)->next = (head).next;  /* add to head of doubly linked list */ \
                             ((x)->prev) = (void*)&(head); \
 	                     (head).next->prev = (x); \
	                     (head).next = (x);  ME
# define DLIST_DEL(prv,nxt) MB (nxt)->prev = (prv); (prv)->next = (nxt); (prv)=(nxt)=0; ME
#endif

#define DPDU_ADD(head,x) MB (x)->g.pdunext = (head).pdunext;  /* add to head of doubly linked list */ \
                            ((x)->g.pduprev) = (void*)&(head); \
 	                    (head).pdunext->g.pduprev = (x); \
	                    (head).pdunext = (x); ME

#define PDU_DLIST_DEL(p) MB (p)->g.pdunext->g.pduprev = (p)->g.pduprev; \
                            (p)->g.pduprev->g.pdunext = (p)->g.pdunext; \
                            (p)->g.pduprev = (p)->g.pdunext = 0; ME

#define PREPEND_LIST(root,list,typ) MB while (list) { \
  (typ)* x = (list); (list) = (list)->next; /* remove from list */ \
  x->next = (root); (root) = x; /* append at root */ \
} ME

#define FREE_LIST_NEXT(root,type,nxt) MB type pp; type dead; for (pp = (root); pp; dead = pp, pp = pp->nxt, FREE_EXPR(dead)) ; (root) = 0; ME
#define FREE_LIST(root,type) FREE_LIST_NEXT((root),type,next)

     /* Memory management */

#define MALLOC(p) CHK_NULL((p)=malloc(sizeof(*(p))))
#define DUP(d,s) MB CHK_NULL((d)=malloc(sizeof(*(s)))); if (d) memcpy((d),(s),sizeof(*(s))); ME
#define REALLOC(p) MB if (p) CHK_NULL((p)=realloc((p), sizeof(*p))); \
                      else   CHK_NULL((p)=malloc(sizeof(*(p)))); ME

#if 0
# define MALLOCN(p,n) CHK_NULL((void*)(p)=malloc(n))
# define REALLOCN(p,n) MB if (p) CHK_NULL((void*)(p)=realloc((p),(n))); \
		         else   CHK_NULL((void*)(p)=malloc(n)); ME
# define STRDUP(d,s) MB (d) = strdup(s); ME
#else
/* Catch mallocs of zero size */
# define MALLOCN(p,n) MB ASSERT(n); CHK_NULL((p)=malloc(n)); ME
# define REALLOCN(p,n) MB ASSERT(n); if (p) CHK_NULL((p)=realloc((p),(n))); \
		                    else   CHK_NULL((p)=malloc(n)); ME
# define STRDUP(d,s) MB (d) = strdup(s); ME
#endif

#define DUPN(d,s,n) MB MALLOCN(d,n); if (d) memcpy((d),(s),(n)); ME

#if 1
# define FREE(p) (p) = 0; free(p)
# define FREE_EXPR(p) free(p)
#else
# define FREE(p) 0
# define FREE_EXPR(p) (0)
#endif

#define ZERO(p,n) memset((p), 0, (n))
#define ZMALLOC(p) MB MALLOC(p); ZERO((p), sizeof(*(p))); ME
#define ZMALLOCN(p,n) MB MALLOCN((p),(n)); ZERO((p), (n)); ME

     /* Common type declarations */
#define const_str const char FAR*
#define var_str char FAR*

/* Hash algorithm cannibalized from perl-5.6.1 hv.h, line 50
 *   register unsigned int h, hh;
 *   SHASH(key,h);
 *   hh = h%hash_size;  // convert open ended hash to bounded hash
 * 
 * SHASH() simply computes openended hash over C string (as opposed to blob)
 * FIND_SHASH() actually scans into hash table and finds the slot containting
 * the value
 */

#define SHASH(key,h) MB register CU8* s = (CU8*)(key); (h)=0; \
  while (*s) (h) = (h)*33 + *s++; (h) += (h)>>5; ME

#define FIND_SHASH(key,hh,hash_size,tab) MB register unsigned int h; \
  SHASH(key,h); (hh) = h%(hash_size); \
  while ((tab)[(hh)] && strcmp((tab)[(hh)], (key))) (hh)++; ME

/* Same perl hash algorithm for the case where string is fully binary */

#define BHASH(key,len,h) MB \
  register CU8* s = (CU8*)(key); register int l = (len); (h)=0; \
  while (l--) (h) = (h)*33 + *s++; (h) += (h)>>5; ME

/* Simple pool allocator (only allows you to allocate more).
 *   p = pointer that will receive the memory
 *   k = allocation arena header
 *   n = amount to allocate (negative deallocates, but careful here)
 *   e = function call that will extend the arena, if needed
 *
 * PALIGN()    effects rounding up so 64 bit alignment is preserved
 * PALLOCN()   allocates memory without regard to possibility of arena ending,
 *             i.e. it assumes the arena was already prextended to the right
 *             size. The arena is assumed to contain field ap (alloc pointer)
 *             which is used to remember the next free location. E.g:
 *
 *               struct arena {
 *                 struct arena* next;   // not required, but usually used by extension function
 *                 int len;              // required by ALLOCMORE()
 *                 U8* ap;               // next free location (required)
 *                 U8  dat[0];           // actual data (as much as len indicates), required by ALLOCMORE()
 *               }
 * PALLOC()    same as PALLOCN(), but takes the amount to alloc from sizeof of the pointed type
 *
 * PALLOCEXTN() allocates memory and foresees the possibility that arena has to be
 *             extended. Presumably this is done using linked list of arenas
 *             where newest arena is linked to the head of the list. Typical
 *             call and extension function would be
 *
 *               PALLOCEXT(p, k, k = more_arena(k, psiz));       // psiz represents byte size of the allocation
 *               PALLOCEXTN(p, k, 100, k = more_arena(k, psiz)); // here size is 100
 *               
 *               struct arena*
 *               more_arena(struct arena* k, int n) {
 *                 struct arena* kk;
 *                 MALLOCN(kk, sizeof(struct arena) + ALIGN(n));  // or allocate more at once
 *                 kk->next = k;
 *                 kk->len = ALIGN(n);  // or more
 *                 kk->ap = kk->dat;
 *                 return kk;
 *               }
 * PALLOCEXT() same as PALLOCEXTN() but determines the size of the arena from sizeof of the pointed type
 */

/*#define ALIGN32(n) ((((unsigned)(n)-1)&0xfffffffc)+4)*/
/*#define ALIGN64(n) ((((unsigned)(n)-1)&0xfffffff8)+8)*/
#define ALIGN16(n)  (((n) + 0x1) & ~0x1)
#define ALIGN32(n)  (((n) + 0x3) & ~0x3)
#define ALIGN64(n)  (((n) + 0x7) & ~0x7)
#define ALIGN128(n) (((n) + 0xf) & ~0xf)

#define PALIGN(n) ALIGN32(n)
#define PALLOC(p,k)         PALLOCN((p),(k),sizeof(*(p)))
#define PALLOCN(p,k,n)      MB ((U8*)(p))=(k)->ap; (k)->ap += PALIGN(n); ME
#define PALLOCEXT(p,k,e)    PALLOCEXTN((p),(k),sizeof(*(p)),(e))

/* N.B. PALLOCEXTN() produces compile error about "non-lvalue in assignment"
 * if p is of type char* (used to happen with U8*). This is either a
 * compiler bug or me not understanding how C is supposed to work. The
 * culprit is the assignment `(char*)(p)=(char*)((k)->ap);'
 * Following C fragment should illustrate the problem
 *   struct kk { char* ap; }; void main() { struct kk* k; char* p; (char*)p = k->ap; }
 * but fails to reproduce it :-( --Sampo */
#define PALLOCEXTN(p,k,n,e) MB if ((int) ((((char*)((k)->ap))-((char*)((k)->dat))) + (n)) \
                                   > (int) (k)->len) \
                               { int psiz = (n); if(!(e)) { (p)=0; break; } } \
                               (char*)(p)=(char*)((k)->ap); (k)->ap += PALIGN(n); ME

#define ZPALLOC(p,k)         MB PALLOC((p),(k)); ZERO((p), sizeof(*(p))); ME
#define ZPALLOCN(p,k,n)      MB PALLOCN((p),(k),(n)); ZERO((p), (n)); ME
#define ZPALLOCEXT(p,k,e)    MB PALLOCEXT((p),(k),(e)); ZERO((p), sizeof(*(p))); ME
#define ZPALLOCEXTN(p,k,n,e) MB PALLOCEXTN((p),(k),(n),(e)); ZERO((p), (n)); ME

/* =============== Console color =============== */
/* vt100 terminal color escapes to liven up debug prints :-)
 * See https://wiki.archlinux.org/index.php/Color_Bash_Prompt */

#ifdef NOCOLOR
#define CC_RED(x)     x
#define CC_REDB(x)    x
#define CC_YELB(x)    x 
#define CC_GRNB(x)    x 
#define CC_BLUB(x)    x 
#define CC_PURB(x)    x 
#define CC_CYNB(x)    x 
#define CC_REDY(x)    x
#define CC_YELY(x)    x 
#define CC_GREENY(x)  x 
#define CC_BLUY(x)    x 
#define CC_PURY(x)    x 
#define CC_CYNY(x)    x 
#else
#define CC_RED(x)    "\e[0;31m" x "\e[0m" /* regular red */
#define CC_REDB(x)   "\e[1;31m" x "\e[0m" /* bold red */
#define CC_YELB(x)   "\e[1;33m" x "\e[0m"
#define CC_GRNB(x)   "\e[1;32m" x "\e[0m"
#define CC_BLUB(x)   "\e[1;34m" x "\e[0m"
#define CC_PURB(x)   "\e[1;35m" x "\e[0m"
#define CC_CYNB(x)   "\e[1;36m" x "\e[0m"
#define CC_REDY(x)   "\e[41m" x "\e[0m"  /* red background, black text (no bold) */
#define CC_YELY(x)   "\e[43m" x "\e[0m"
#define CC_GREENY(x) "\e[42m" x "\e[0m"
#define CC_BLUY(x)   "\e[44m" x "\e[0m"
#define CC_PURY(x)   "\e[45m" x "\e[0m"
#define CC_CYNY(x)   "\e[46m" x "\e[0m"
#endif

/* =============== Debugging macro system =============== */

#ifndef ERRMAC_INSTANCE
/*#define ERRMAC_INSTANCE "\tzx"*/
#define ERRMAC_INSTANCE errmac_instance
extern char errmac_instance[64];
#endif

#define ERRMAC_DEBUG_MASK   0x03  /* 0 = no debug, 1=minimal info debug, 2=bit more, 3=lot more */
#define ERRMAC_XMLDBG       0x04
#define ERRMAC_RESERVED     0x08
#define ERRMAC_INOUT        0x10
#define MOD_AUTH_SAML_INOUT 0x20
#define CURL_INOUT          0x40  /* Back Channel */

extern int errmac_debug;          /* Defined in zxidlib.c */
extern char errmac_indent[256];   /* Defined in zxidlib.c *** Locking issues? */
extern FILE* errmac_debug_log;    /* Defined in zxidlib.c as 0 alias to stderr */
#define ERRMAC_DEBUG_LOG (errmac_debug_log?errmac_debug_log:(stderr))
#if 1
/* In some scenarios multithreaded access can cause errmac_indent to be scrambled.
 * However, it should not under- or overflow. Thus no lock. */
#define D_INDENT(s) strncat(errmac_indent, (s), sizeof(errmac_indent)-1)
#define D_DEDENT(s) (errmac_indent[MAX(0, strlen(errmac_indent)-sizeof(s)+1)] = 0)
#else
#define D_INDENT(s) /* no locking issues */
#define D_DEDENT(s)
#endif

#ifdef VERBOSE
# define D(format,...) (void)((fprintf(ERRMAC_DEBUG_LOG, "%d %10s:%-3d %-16s %s d %s" format "\n", getpid(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, ## __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
# define DD D
#else
# ifdef USE_PTHREAD
#  ifdef USE_AKBOX_FN
#   define D(format,...) (void)((errmac_debug&ERRMAC_DEBUG_MASK)>1 && (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %04x:%-4d %s d %s" format "\n", getpid(), (long)pthread_self(), AKBOX_FN(__FUNCTION__), __LINE__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
#  else
#   define D(format,...) (void)((errmac_debug&ERRMAC_DEBUG_MASK)>1 && (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %10s:%-3d %-16s %s d %s" format "\n", getpid(), (long)pthread_self(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
#  endif
# else
#  define D(format,...) (void)((errmac_debug&ERRMAC_DEBUG_MASK)>1 && (fprintf(ERRMAC_DEBUG_LOG, "%d %10s:%-3d %-16s %s d %s" format "\n", getpid(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, ## __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
# endif
# define DD(format,...)  /* Documentative */
#endif

#ifdef USE_PTHREAD
# ifdef USE_AKBOX_FN
#  define ERR(format,...) (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %04x:%-4d %s E %s" format "\n", getpid(), (long)pthread_self(), AKBOX_FN(__FUNCTION__), __LINE__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG))
#  define WARN(format,...) (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %04x:%-4d %s W %s" format "\n", getpid(), (long)pthread_self(), AKBOX_FN(__FUNCTION__), __LINE__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG))
#  define INFO(format,...) (void)(errmac_debug&ERRMAC_DEBUG_MASK && (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %04x:%-4d %s I %s" format "\n", getpid(), (long)pthread_self(), AKBOX_FN(__FUNCTION__), __LINE__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
# else
#  define ERR(format,...) (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %10s:%-3d %-16s %s E %s" format "\n", getpid(), (long)pthread_self(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG))
#  define WARN(format,...) (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %10s:%-3d %-16s %s W %s" format "\n", getpid(), (long)pthread_self(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG))
#  define INFO(format,...) (void)(errmac_debug&ERRMAC_DEBUG_MASK && (fprintf(ERRMAC_DEBUG_LOG, "%d.%lx %10s:%-3d %-16s %s I %s" format "\n", getpid(), (long)pthread_self(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
# endif
#else
# define ERR(format,...) (fprintf(ERRMAC_DEBUG_LOG, "%d %10s:%-3d %-16s %s E %s" format "\n", getpid(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG))
# define WARN(format,...) (fprintf(ERRMAC_DEBUG_LOG, "%d %10s:%-3d %-16s %s W %s" format "\n", getpid(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG))
# define INFO(format,...) (void)(errmac_debug&ERRMAC_DEBUG_MASK && (fprintf(ERRMAC_DEBUG_LOG, "%d %10s:%-3d %-16s %s I %s" format "\n", getpid(), __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, errmac_indent, __VA_ARGS__), fflush(ERRMAC_DEBUG_LOG)))
#endif

#define D_XML_BLOB(cf, lk, len, xml) errmac_debug_xml_blob((cf), __FILE__, __LINE__, __FUNCTION__, (lk), (len), (xml))
#define DD_XML_BLOB(cf, lk, len, xml) /* Documentative */

int hexdmp(const char* msg, const void* p, int len, int max);
int hexdump(const char* msg, const void* p, const void* lim, int max);

#define HEXDUMP(msg, p, lim, max) if ((errmac_debug&ERRMAC_DEBUG_MASK) > 1) hexdump((msg), (p), (lim), (max))
#define DHEXDUMP(msg, p, lim, max) /* Disabled hex dump */

#define DUMP_CORE() ASSERT(0)
#define NEVER(explanation,val) D(explanation,(val))
#define NEVERNEVER(explanation,val) MB ERR(explanation,(val)); fflush(stdout); fflush(ERRMAC_DEBUG_LOG); DUMP_CORE(); ME

#define CMDLINE(x)

#ifdef DEBUG
#define DEFINE_MUTEX_INFO(name)
/*#define DEFINE_MUTEX_INFO(name) char* name ## info; int name ## line; pthread_t name ## thr;*/
#define SET_MUTEX_INFO(name, msg)
/*#define SET_MUTEX_INFO(name, msg) name ## info = __FILE__ " " msg; name ## line = __LINE__; name ## thr = pthread_self();*/
# ifdef STDOUT_DEBUG
#  define LOG ERRMAC_DEBUG_LOG,
#  define OPEN_LOG()
#  define CLOSE_LOG()
#  define FLUSH() fflush(stdout)
# else
#  define LOG ERRMAC_DEBUG_LOG,
#  define LOG_FILE HOME "foo.log"
#  define OPEN_LOG() MB TR { if ((errmac_debug_log = fopen(LOG_FILE, "a")) == NULL) trace = 0; } ME
#  define CLOSE_LOG() MB TR if (errmac_debug_log) { fclose(errmac_debug_log); debug_log=0; trace = 0; } ME
#  define FLUSH() MB if (errmac_debug_log) fflush(errmac_debug_log); ME
# endif
 
#define TR  if (trace)
#define TR2 if (trace > 1)
#define TR3 if (trace > 2)
#define PR fprintf
#define DUMP(x) dump(LOG (char*)&(x), sizeof(x))
#define PRMEM(f,buf,len) MB char b[256]; memcpy(b, (buf), MIN(256, (len))); \
                          PR(LOG (f), b, (len)); ME

#else
/* -------------------------------------------------------- */
/* Nondebugging macros */

#define DEFINE_MUTEX_INFO(name)
#define SET_MUTEX_INFO(name, msg)
#define OPEN_LOG()
#define CLOSE_LOG()
# ifdef STDOUT_DEBUG
#  define LOG ERRMAC_DEBUG_LOG,
#  define FLUSH() fflush(errmac_debug_log)
# else

   /* N.B. these macros assume existence of global variable debug_log, unless STDOUT_DEBUG
    *      is defined. */
#  define LOG ERRMAC_DEBUG_LOG,
#  define FLUSH() fflush(errmac_debug_log)
# endif
#define PR fprintf
#define PRMEM(f,buf,len) MB char b[256]; memcpy(b, (buf), MIN(254, (len))); \
                          b[MIN(255, (len))] = '\0'; PR(LOG (f), b, (len)); ME
#ifndef FLUSH
# define FLUSH()
#endif
#define TR  if (0)
#define TR2 if (0)
#define TR3 if (0)
#define DUMP(x)

#endif

#ifdef DEBUG

/* Try to produce some exception, unless global setting says asserting is NOT ok. */

extern char* assert_msg;
//#define DIE_ACTION(b) MB fprintf(ERRMAC_DEBUG_LOG, assert_msg, ERRMAC_INSTANCE); if (assert_nonfatal == 0) { *((int*)0xffffffff) = 1; } ME
#define DIE_ACTION(b) MB fprintf(ERRMAC_DEBUG_LOG, assert_msg, ERRMAC_INSTANCE); if (assert_nonfatal == 0) { *((int*)-1) = 1; } ME

/* Many development time sanity checks use these macros so that they
 * can be compiled away from the final version. ASSERT macros are more
 * convenient than their library counter parts, such as assert(3), in
 * that core is dumped in the function where the ASSERT fired, rather
 * than somewhere deep inside a library. N.B. Since these are macros,
 * any arguments may get evaluated zero or more times, producing no,
 * one, or multiple side effects, depending on
 * circumstances. Therefore arguments, should NOT have any side
 * effects. Otherwise "Heisenbugs" will result that manifest depending
 * on whether ASSERTs are enabled or not. */

#if 1  /* More verbose versions */
# define CHK(cond,err) MB if ((cond)) { \
      /*ak_ts(AK_NFN(__FUNCTION__), __LINE__, AK_ASSERT_RAZ, "CHK FAIL: " #cond, "");*/ \
      ERR("CHK FAIL: " #cond " %x", err); \
      DIE_ACTION(err); } ME

# define ASSERT(c) MB if (!(c)) { \
      /*ak_ts(AK_NFN(__FUNCTION__), __LINE__,AK_ASSERT_RAZ,(char*)(int)(a),"ASSERT FAIL: " #c);*/ \
      ERR("ASSERT FAIL: " #c " %d", 0); \
      DIE_ACTION(1); } ME

# define ASSERTOP(a,op,b,err) MB if (!((a) op (b))) { \
      /*ak_ts(AK_NFN(__FUNCTION__), __LINE__, AK_ASSERTOP_RAZ, (char*)(int)(a), "ASSERTOP FAIL: " #a #op #b);*/ \
      ERR("ASSERTOP FAIL: " #a #op #b " %x", (int)(err)); \
      DIE_ACTION(1); } ME

# define ASSERTOPI(a,op,b) MB if (!((a) op (b))) { \
      /*ak_ts(AK_NFN(__FUNCTION__), __LINE__, AK_ASSERTOP_RAZ, (char*)(int)(a), "ASSERTOP FAIL: " #a #op #b);*/ \
      ERR("ASSERTOP FAIL: " #a #op #b " %x", (int)(a)); \
      DIE_ACTION(1); } ME

# define ASSERTOPL(a,op,b) MB if (!((a) op (b))) { \
      /*ak_ts(AK_NFN(__FUNCTION__), __LINE__, AK_ASSERTOP_RAZ, (char*)(int)(a), "ASSERTOP FAIL: " #a #op #b);*/ \
      ERR("ASSERTOP FAIL: " #a #op #b " %lx", (long)(a)); \
      DIE_ACTION(1); } ME

# define ASSERTOPP(a,op,b) MB if (!((a) op (b))) { \
      /*ak_ts(AK_NFN(__FUNCTION__), __LINE__, AK_ASSERTOP_RAZ, (char*)(int)(a), "ASSERTOP FAIL: " #a #op #b);*/ \
      ERR("ASSERTOPP FAIL: " #a #op #b " %p", (a)); \
      DIE_ACTION(1); } ME

# define FAIL(x,why) MB /*ak_ts(AK_NFN(__FUNCTION__), __LINE__, AK_FAIL_RAZ, (char*)(x), why);*/ DIE_ACTION(1); ME

/* SANITY_CHK is a smaller assert which checks a condition but will not force an abort */
# define SANITY_CHK(cond,...) MB if (!(cond)) \
  /*ak_tsf(AK_NFN(__FUNCTION__), __LINE__, AK_SANITY_RAZ, #cond, __VA_ARGS__);*/ 1; ME
#else  /* More sterile versions */
# define CHK(cond,err) MB if (cond) { DIE_ACTION(err); } ME
# define ASSERT(c) MB if (!(c)) { DIE_ACTION(1); } ME
# define ASSERTOP(a,op,b,err) MB if (!((a) op (b))) { DIE_ACTION(err); } ME
# define ASSERTOPI(a,op,b) MB if (!((a) op (b))) { DIE_ACTION(1); } ME
# define ASSERTOPL(a,op,b) MB if (!((a) op (b))) { DIE_ACTION(1); } ME
# define ASSERTOPP(a,op,b) MB if (!((a) op (b))) { DIE_ACTION(1); } ME
# define FAIL(x,why) MB DIE_ACTION(1); ME
# define SANITY_CHK(cond,...) MB if (!(cond)) NEVER("insanity %d",0); ME
#endif

/* Sometimes compiler issues bogus "variable might be uninitialized"
 * warnings. To silence them, use this macro thusly
 *    char* yourvar BOGUS_UNINITIALIZED_WARNING_0; */
#define BOGUS_UNINITIALIZED_WARNING_0 =0

#else /* ---------------- no debug --------------- */
# define CHK(cond,err)
# define ASSERT(c)
# define ASSERTOP(a,op,b,err)
# define ASSERTOPI(a,op,b)
# define ASSERTOPL(a,op,b)
# define ASSERTOPP(a,op,b)
# define FAIL(format)
# define BOGUS_UNINITIALIZED_WARNING_0
#endif /* DEBUG */

/* -------------------------------------------------------- */
/* Asserting and sanity checks */
 
#define CHK_NULL(n)    ASSERT((intptr_t)(n))
#define CHK_ERRNO(n)   CHK(((n)<0), errno)
#define CHK_MAGIC(p,m) MB ASSERT(p); ASSERTOP((p)->magic, ==, (m), (p)->magic); ME

#define ASSERT_THR(t)  ASSERTOP(pthread_self(), ==, (t), (t))
/* Following macro assumes that each lock is accompanied by a variable
 * describing who holds it. This macro takes that variable as an
 * argument (e.g. shuff_locked). */
#define ASSERT_NOT_IN_LOCK(t) ASSERT((unsigned)(t) != (unsigned)pthread_self())
#define ASSERT_IN_LOCK(t) ASSERTOP((unsigned)(t), ==, (unsigned)pthread_self(),(t))

/* DASSERT family is "documentative" assert, i.e. not compiled in even in debug mode */
#define DASSERT(c)
#define DASSERTOP(a,op,b,err)
#define DASSERTOPI(a,op,b)
#define DASSERTOPL(a,op,b)
#define DASSERTOPP(a,op,b)
#define DASSERT_THR(t)
#define DASSERT_NOT_IN_LOCK(t)
#define DASSERT_IN_LOCK(t)

#ifdef MUTEX_DEBUG
# define MUTEX_INITIALIZER PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP
# define MUTEXATTR &debug_mutexattr
#else
# define MUTEX_INITIALIZER PTHREAD_MUTEX_INITIALIZER
# define MUTEXATTR 0
#endif
#define MUTEXATTR_DECL debug_mutexattr

/* =============== pthread locking =============== */

#ifdef USE_PTHREAD
# if 1
/*#define LOCK_STATIC(l) pthread_mutex_t l.ptmut = PTHREAD_MUTEX_INITIALIZER  do not use */
#  define LOCK_INIT(l) pthread_mutex_init(&(l).ptmut, 0)
#  define LOCK(l,lk)   MB if (pthread_mutex_lock(&(l).ptmut))   NEVERNEVER("DEADLOCK(%s)", (lk)); (l).func = __FUNCTION__; (l).line = __LINE__; (l).thr = pthread_self(); ME
#  define UNLOCK(l,lk) MB ASSERTOPL((long)((l).thr), ==, (long)pthread_self()); /*(l).func = __FUNCTION__; (l).line = __LINE__;*/ (l).thr = 0; if (pthread_mutex_unlock(&(l).ptmut)) NEVERNEVER("UNLOCK-ERR(%s)", (lk)); ME
  /* pthread_cond_wait(3) does some important magic: it unlocks the mutex (l)
   * so that other threads may move. But it will reacquire the lock before
   * returning. Due to this, other threads may have set lock debugging variables,
   * so we need to reset them back here. */
#  define ERRMAC_COND_WAIT(c,l,lk) MB pthread_cond_wait((c), &(l).ptmut); (l).func = __FUNCTION__; (l).line = __LINE__; (l).thr = pthread_self(); ME
#  define ERRMAC_COND_SIG(c,lk) pthread_cond_signal(c)
# else
/*#define LOCK_STATIC(l) pthread_mutex_t l = PTHREAD_MUTEX_INITIALIZER  do not use */
#  define LOCK_INIT(l) pthread_mutex_init(&(l), 0)
#  define LOCK(l,lk)   if (pthread_mutex_lock(&(l)))   NEVERNEVER("DEADLOCK(%s)", (lk))
#  define UNLOCK(l,lk) if (pthread_mutex_unlock(&(l))) NEVERNEVER("UNLOCK-TWICE(%s)", (lk))
#  define ERRMAC_COND_WAIT(c,l,lk) pthread_cond_wait((c), &(l).ptmut)
#  define ERRMAC_COND_SIG(c,lk) pthread_cond_signal(c)
# endif
#else
# define LOCK_STATIC(l) 
# define LOCK_INIT(l)
# define LOCK(l,lk)
# define UNLOCK(l,lk)
# define ERRMAC_COND_WAIT(c,l,lk) NEVERNEVER("Program written to use pthread_cond_wait() can not work when compiled to not use it (%s).",(lk));
#  define ERRMAC_COND_SIG(c,lk)  NEVERNEVER("Program written to use pthread_cond_sig() can not work when compiled to not use it (%s).",(lk));
#endif

/* =============== file system flocking =============== */

#ifndef USE_LOCK
#if 0
#define FLOCKEX(fd) lockf((fd), F_LOCK, 1)
#define FUNLOCK(fd) lockf((fd), F_ULOCK, 1)
#else
#define FLOCKEX(fd) fcntl((fd), F_SETLKW, &errmac_rdlk)
#define FUNLOCK(fd) fcntl((fd), F_SETLKW, &errmac_unlk)
#endif
#else
/* If you have neither flock() nor lockf(), then -DUSE-LOCK=dummy_no_flock
 * but beware that this means NO file locking will be done, possibly
 * leading to corrupt audit logs, or other files. You need to judge
 * the probability of this happening as well as the cost of clean-up. */
#define dummy_no_flock(x,y) (0)  /* no file locking where locking should be */
#define FLOCKEX(fd) USE_LOCK((fd), LOCK_EX)
#define FUNLOCK(fd) USE_LOCK((fd), LOCK_UN)
#endif

/* Nibble and bit arrays */

#define GET_NIBBLE(b, i)    ((i) & 0x01 ? (b)[(i)>>1] & 0x0f : ((b)[(i)>>1] >> 4) & 0x0f )
#define SET_NIBBLE(b, i, v) ((i) & 0x01 ? ((b)[(i)>>1] = (b)[(i)>>1] & 0xf0 | (v) & 0x0f) \
                                        : ((b)[(i)>>1] = (b)[(i)>>1] & 0x0f | ((v) << 4) & 0xf) )

#define GET_BIT(a,i)    ((a)[(i) >> 3] & (1 << ((i) & 0x3)))
#define SET_BIT(a,i,v)  ((a)[(i) >> 3] = (v) ? ((a)[(i) >> 3] | (1 << ((i) & 0x3))) : ((a)[(i) >> 3] & ~(1 << ((i) & 0x3))))

/* -------------------------------------------------------- */
/* BER and ASN.1 Macros */

/* Decode the BER extensible integer format (i.e. that which represents
 * numbers in base128 with high bit indicating continuation.
 */

/*  #define BER_INT(p,x) MB (x) = *((p)++); if ((x)&0x80) { (x)&=0x7f;\ */
/*    do { (x) = ((x)<<7) | ((CU8)(*(p)) & 0x7f); \ */
/*    } while (*((p)++)&0x80) } ME */

/*  #define BER_INT_N(p,x,n) MB if (n) { (x) = *((p)++); \ */
/*    if ((x)&0x80 && --(n)) { \ */
/*      (x)&=0x7f; \ */
/*      do { (x) = ((x)<<7) | (((CU8)(*(p))) & 0x7f); \ */
/*      } while (*((p)++)&0x80 && --(n)); \ */
/*    }} else { (x) = 0; } ME */

#if 0
/* *** This code is wrong. Please see pdu/bermacros.h for macro that works. */
#define BER_INT_N(p,x,n) MB   { (x) = *((p)++); \
  { switch((n)) {\
  case 0: (x) = 0; break \
  case 1: (x) = *((p)++) & 0x7f; break; \
  case 2: (x) = ((*(p)<<8) | *((p)+1)) | 0x7fff); (p)+=2; break; \
  case 3: (x) = ((*(p)<<16) | (*((p)+1)<<8) | *((p)+2)) | 0x7fffff; (p)+=3; break; \
  case 4: (x) = ((*(p)<<24) | (*((p)+1)<<16) | (*((p)+2)<<8) | *((p)+3)) | 0x7fffffff; (p)+=4; break; \
  default: NEVER("BER_LEN: long length > 4 not supported (%d)",(x)); \
  }} ME
#endif

#define BER_LEN(p,x) MB (x) = *((p)++); if ((x)&0x80) { switch((x)&0x7f) {\
  case 0: NEVER((LOG "BER_LEN: long length is zero?!?")); break; \
  case 1: (x) = *((p)++); break; \
  case 2: (x) = (*(p)<<8) | *((p)+1); (p)+=2; break; \
  case 3: (x) = (*(p)<<16) | (*((p)+1)<<8) | *((p)+2); (p)+=3; break; \
  case 4: (x) = (*(p)<<24) | (*((p)+1)<<16) | (*((p)+2)<<8) | *((p)+3); (p)+=4; break; \
  default: NEVER("BER_LEN: long length > 4 not supported (%d)",(x)); \
  }} ME

/* Encode a TAG in BER  (only checked for unsigned ints) 
 * (This was formerly called BER_UINT_WRITE, but BER integers are encoded
 * differently than BER Tags)
 */

#define BER_TAG_WRITE(p,x) MB if ((x) < (1<<7)) { *((p)++) = (U8)(x); } \
  else if ((x) < (1<<14)) { *((p)++) = 0x80 | (((x)>>7)  & 0x7f); \
                            *((p)++) =          (x)      & 0x7f;} \
  else if ((x) < (1<<21)) { *((p)++) = 0x80 | (((x)>>14) & 0x7f); \
                            *((p)++) = 0x80 | (((x)>>7)  & 0x7f); \
                            *((p)++) =          (x)      & 0x7f;} \
  else if ((x) < (1<<28)) { *((p)++) = 0x80 | (((x)>>21) & 0x7f); \
                            *((p)++) = 0x80 | (((x)>>14) & 0x7f); \
                            *((p)++) = 0x80 | (((x)>>7)  & 0x7f); \
                            *((p)++) =          (x)      & 0x7f;} \
  else { NEVER("int %d too big to encode in BER\n",(x)); }; ME

/* Encode an int in BER (only checked for unsigned ints) */

#define BER_UINT_WRITE(p,x) MB if ((x) <= 0x7f) { *((p)++) = (U8)(x); } \
  else if ((x) <= 0x7fff) { *((p)++) = ((x) >> 8) & 0xff;  \
                            *((p)++) =  (x); }      \
  else if ((x) <= 0x7fffff) { *((p)++) = ((x) >> 16) & 0xff; \
                              *((p)++) = ((x) >> 8) & 0xff;  \
                              *((p)++) =  (x) & 0xff; }      \
  else if ((x) <= 0x7fffffff) {  *((p)++) = ((x) >> 24) & 0xff; \
                                 *((p)++) = ((x) >> 16) & 0xff; \
                                 *((p)++) = ((x) >> 8) & 0xff;  \
                                 *((p)++) =  (x) & 0xff; }      \
  else { NEVER("length %lx too big to encode in BERLEN\n",(unsigned long)(x)); }; ME

/* Encode length in BER */

#define BER_LEN_WRITE(p,x) MB if ((x) <= 0x7f) { *((p)++) = (U8)(x); } \
  else if ((x) <= 255U)   { *((p)++) = 0x81; *((p)++) = (U8)(x); } \
  else if ((x) <= 65535U) { *((p)++) = 0x82; \
                            *((p)++) = ((x) >> 8) & 0xff;  \
                            *((p)++) =  (x) & 0xff; }      \
  else if ((x) <= 16777215U) { *((p)++) = 0x83; \
                               *((p)++) = ((x) >> 16) & 0xff; \
                               *((p)++) = ((x) >> 8) & 0xff;  \
                               *((p)++) =  (x) & 0xff; }      \
  else if ((x) <= 4294967295U) { *((p)++) = 0x84; \
                                 *((p)++) = ((x) >> 24) & 0xff; \
                                 *((p)++) = ((x) >> 16) & 0xff; \
                                 *((p)++) = ((x) >> 8) & 0xff;  \
                                 *((p)++) =  (x) & 0xff; }      \
  else { NEVER("length %d too big to encode in BERLEN\n",(x)); }; ME

#define PEM_CERT_START          "-----BEGIN CERTIFICATE-----"
#define PEM_CERT_END              "-----END CERTIFICATE-----"
#define PEM_RSA_PRIV_KEY_START  "-----BEGIN RSA PRIVATE KEY-----"
#define PEM_RSA_PRIV_KEY_END      "-----END RSA PRIVATE KEY-----"
#define PEM_DSA_PRIV_KEY_START  "-----BEGIN DSA PRIVATE KEY-----"
#define PEM_DSA_PRIV_KEY_END      "-----END DSA PRIVATE KEY-----"
#define PEM_PRIV_KEY_START      "-----BEGIN PRIVATE KEY-----"
#define PEM_PRIV_KEY_END          "-----END PRIVATE KEY-----"

/* Define this so it results CR (0xd) and LF (0xa) on your platform. N.B. \n is not always 0xa! */
#define CRLF "\015\012"
#define CRLF2 CRLF CRLF

/* Both methods are valid for booleans, but the default "1" and "0" approach is more compact.
 * If you have to interop with buggy software that insists on the "true" and "false",
 * tweak this conditional. */

#ifdef XML_BOOL_WASTE_SPACE
#define XML_TRUE  "true"
#define XML_FALSE "false"
#else
#define XML_TRUE  "1"
#define XML_FALSE "0"
#endif

/* Test XML boolean field (zx_str) for XML valid "true" values */
#define XML_TRUE_TEST(x) ((x) && (x)->s && (((x)->len == 1 && (x)->s[0] == '1') || ((x)->len == 4 && !memcmp((x)->s, "true", 4))))

void platform_broken_snprintf(int n, const char* where, int maxlen, const char* fmt);

#if 0
/* Following come handy when printf(3) is broken or otherwise
 * the libc support is minimal. */

static char* errhexll(const char* prefix, long long x) {
  static char buf[64];
  char const digit[] = "0123456789abcdef";
  char* p;
  int i;
  for (p = buf; prefix && *prefix; ++prefix, ++p) *p = *prefix;
#if 0
  *p++ = digit[(x >> 60) & 0x0f];
  *p++ = digit[(x >> 56) & 0x0f];
  *p++ = digit[(x >> 52) & 0x0f];
  *p++ = digit[(x >> 48) & 0x0f];
  *p++ = digit[(x >> 44) & 0x0f];
  *p++ = digit[(x >> 40) & 0x0f];
  *p++ = digit[(x >> 36) & 0x0f];
  *p++ = digit[(x >> 32) & 0x0f];

  *p++ = digit[(x >> 28) & 0x0f];
  *p++ = digit[(x >> 24) & 0x0f];
  *p++ = digit[(x >> 20) & 0x0f];
  *p++ = digit[(x >> 16) & 0x0f];
  *p++ = digit[(x >> 12) & 0x0f];
  *p++ = digit[(x >> 8) & 0x0f];
  *p++ = digit[(x >> 4) & 0x0f];
  *p++ = digit[x & 0x0f];
  *p++ = '\n';
  write(1, buf, p-buf);
#else
  p+=8;
  *p-- = '\n';
  for (i=8; i; --i, x >>= 4) *p-- = digit[x & 0x0f];
  write(1, buf, p+9-buf);
#endif
  return buf;
}

static char* errstr(const char* prefix, const char* str, int len) {
  static char buf[64];
  char* p;
  int i;
  for (p = buf; prefix && *prefix; ++prefix, ++p) *p = *prefix;
  if (len == -2)
    len = strlen(str);
  for (; str && *str && len && p < buf+sizeof(buf)-1; --len) *p++ = *str++;
  *p++ = '\n';
  write(1, buf, p-buf);
  return buf;
}
#endif

#endif /* errmac.h */
