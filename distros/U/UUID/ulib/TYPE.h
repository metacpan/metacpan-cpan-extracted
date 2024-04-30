#ifndef UU_TYPE_H
#define UU_TYPE_H

#ifndef PERL_VERSION
# undef SUBVERSION /* OS/390 */
# include <patchlevel.h>
# ifndef SUBVERSION
#   define SUBVERSION 0
# endif
# if !defined(PATCHLEVEL)))
#   include <could_not_find_Perl_patchlevel.h>
# endif
# define PERL_REVISION    5
# define PERL_VERSION     PATCHLEVEL
# define PERL_SUBVERSION  SUBVERSION
#endif

#ifndef PERL_VERSION_DECIMAL
# define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#endif
#ifndef PERL_DECIMAL_VERSION
# define PERL_DECIMAL_VERSION \
    PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#endif

#ifndef PERL_VERSION_LT
# define PERL_VERSION_LT(r,v,s) \
    (PERL_DECIMAL_VERSION < PERL_VERSION_DECIMAL(r,v,s))
#endif
#ifndef PERL_VERSION_EQ
# define PERL_VERSION_EQ(r,v,s) \
    (PERL_DECIMAL_VERSION == PERL_VERSION_DECIMAL(r,v,s))
#endif


/* related from SO for gcc:
* https://stackoverflow.com/questions/1188939/representing-128-bit-numbers-in-c
*******************************************************************************
  typedef unsigned int uint128_t __attribute__((mode(TI)));

   uint64_t x = 0xABCDEF01234568;
   uint64_t y = ~x;

   uint128_t result = ((uint128_t) x * y);

   printf("%016llX * %016llX -> ", x, y);

   uint64_t r1 = (result >> 64);
   uint64_t r2 = result;

   printf("%016llX %016llX\n", r1, r2);
*/


/* Quad_t/U64 first appear in 5.00563 (8175356b44).
    #ifdef Quad_t
      typedef I64TYPE I64;
      typedef U64TYPE U64;
    #endif
 * U64TYPE also first appears in 8175356b44.
 * HAS_QUAD also appears in 5.00563 (de1c261475),
 * but did not take over the typedefs until 6b8eaf9322,
 * (also 5.00563) where U64 type was restricted to core.
 * QUADKIND also first appears in 6b8eaf9322.
 *
 * U64 made available outside core in 5.27.7.
*/
#if PERL_VERSION_LT(5, 27, 7)
#  ifdef U64TYPE
     typedef U64TYPE U64;
#  else
     typedef uint64_t U64;
#  endif
#endif

typedef union {
  struct {
    /* keep this struct first for namespace init */
    U32 time_low;
    U16 time_mid;
    U16 time_high_and_version;
    U16 clock_seq_and_variant;
    U8  node[6];
  } v1;
  struct {
    U64 low;
    U64 high;
  } v0;
  struct {
    U32 md5_high32;
    U16 md5_high16;
    U16 md5_mid_and_version;
    U32 md5_low_and_variant;
    U32 md5_low;
  } v3;
  struct {
    U32 rand_a;
    U32 rand_b_and_version;
    U32 rand_c_and_variant;
    U32 rand_d;
  } v4;
  struct {
    U32 sha1_high32;
    U16 sha1_high16;
    U16 sha1_mid_and_version;
    U32 sha1_low_and_variant;
    U32 sha1_low;
  } v5;
  struct {
    U32 time_high;
    U16 time_mid;
    U16 time_low_and_version;
    U16 clock_seq_and_variant;
    U8  node[6];
  } v6;
  struct {
    U32 time_high;
    U16 time_low;
    U16 rand_a_and_version;
    U64 rand_b_and_variant;
  } v7;
  U64 __align;
} struct_uu_t;

typedef unsigned char UCHAR;

#define CC_STATESZ  16           /* words: 4 constant, 8 key, 2 counter, 2 nonce */
#define CC_KEYSZ    40           /* bytes of user supplied key+nonce */
#define CC_CORESZ   64           /* bytes output by core */
#define CC_BUFSZ    16*CC_CORESZ /* bytes we get at a time (1024) */
#define CC_ROUNDS   20

typedef struct {
  U32           state[CC_STATESZ];
  UCHAR         buf[CC_BUFSZ];
  U16           have;
  unsigned int  pid;
  U64           __align;
} cc_st;

typedef struct {
  char    *path;
  STRLEN  len;
} struct_pathlen_t;

/* this should be aligned at least 4 bytes, better yet 16 */
typedef U8 uu_t[16];

typedef struct {
  U64               xo_s[4];
  U64               sm_x;
  U64               gen_epoch;
  U8                gen_node[6];  /* need 64bit align */
  U16               __align;
  U8                gen_real_node[6];  /* need 64bit align */
  NV                (*myNVtime)();
  void              (*myU2time)(pTHX_ UV ret[2]);
  int               gen_has_real_node;
  int               gen_use_unique;
  cc_st             cc;  /* aligned 64bit */
  int               clock_state_fd;
  FILE              *clock_state_f;
  struct_pathlen_t  clock_pathlen;
  int               clock_adj;
  struct timeval    clock_last;
  U16               clock_seq;
  UV                thread_id;
  U64               clock_defer_100ns;
  U64               clock_prev_reg;
} my_cxt_t;

#define pUCXT pTHX_ my_cxt_t *my_cxtp
#define aUCXT aTHX_ my_cxtp
#define UCXT  (*my_cxtp)

#endif
/* ex:set ts=2 sw=2 itab=spaces */
