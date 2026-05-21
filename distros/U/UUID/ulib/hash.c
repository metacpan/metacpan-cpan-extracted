#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/hash.h"
#include "ulib/pack.h"
#include "ulib/parse.h"

#ifdef __cplusplus
}
#endif

#ifdef MD5_DEBUG
#undef MD5_DEBUG
#endif

static const char *hexdigits = "0123456789abcdef";

/* borrowed from Digest::MD5 with gentle mangling                 */
/*----------------------------------------------------------------*/
/*
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 *  Copyright 1998-2000 Gisle Aas.
 *  Copyright 1995-1996 Neil Winton.
 *  Copyright 1991-1992 RSA Data Security, Inc.
 *
 * This code is derived from Neil Winton's MD5-1.7 Perl module, which in
 * turn is derived from the reference implementation in RFC 1321 which
 * comes with this message:
 *
 * Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
 * rights reserved.
 *
 * License to copy and use this software is granted provided that it
 * is identified as the "RSA Data Security, Inc. MD5 Message-Digest
 * Algorithm" in all material mentioning or referencing this software
 * or this function.
 *
 * License is also granted to make and use derivative works provided
 * that such works are identified as "derived from the RSA Data
 * Security, Inc. MD5 Message-Digest Algorithm" in all material
 * mentioning or referencing the derived work.
 *
 * RSA Data Security, Inc. makes no representations concerning either
 * the merchantability of this software or the suitability of this
 * software for any particular purpose. It is provided "as is"
 * without express or implied warranty of any kind.
 *
 * These notices must be retained in any copies of any part of this
 * documentation and/or software.
 */

#ifndef PERL_UNUSED_VAR
# define PERL_UNUSED_VAR(x) ((void)x)
#endif

#if PERL_VERSION < 8
# undef SvPVbyte
# define SvPVbyte(sv, lp) (sv_utf8_downgrade((sv), 0), SvPV((sv), (lp)))
#endif

/* Perl does not guarantee that U32 is exactly 32 bits.  Some system
 * has no integral type with exactly 32 bits.  For instance, A Cray has
 * short, int and long all at 64 bits so we need to apply this macro
 * to reduce U32 values to 32 bits at appropriate places. If U32
 * really does have 32 bits then this is a no-op.
 */
#if BYTEORDER > 0x4321 || defined(TRUNCATE_U32)
  #define TO32(x)    ((x) &  0xFFFFffff)
  #define TRUNC32(x) ((x) &= 0xFFFFffff)
#else
  #define TO32(x)    (x)
  #define TRUNC32(x) /*nothing*/
#endif

/* The MD5 algorithm is defined in terms of little endian 32-bit
 * values.  The following macros (and functions) allow us to convert
 * between native integers and such values.
 */
static void u2s(U32 u, U8* s)
{
    *s++ = (U8)(u         & 0xFF);
    *s++ = (U8)((u >>  8) & 0xFF);
    *s++ = (U8)((u >> 16) & 0xFF);
    *s   = (U8)((u >> 24) & 0xFF);
}

#define s2u(s,u) ((u) =  (U32)(*s)            |  \
                        ((U32)(*(s+1)) << 8)  |  \
                        ((U32)(*(s+2)) << 16) |  \
                        ((U32)(*(s+3)) << 24))

typedef struct {
  U32 A, B, C, D;  /* current digest */
  U32 bytes_low;   /* counts bytes in message */
  U32 bytes_high;  /* turn it into a 64-bit counter */
  U8 buffer[128];  /* collect complete 64 byte blocks */
} MD5_CTX;

/* Padding is added at the end of the message in order to fill a
 * complete 64 byte block (- 8 bytes for the message length).  The
 * padding is also the reason the buffer in MD5_CTX have to be
 * 128 bytes.
 */
static const unsigned char PADDING[64] = {
  0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

/* Constants for MD5Transform routine.
 */
#define S11 7
#define S12 12
#define S13 17
#define S14 22
#define S21 5
#define S22 9
#define S23 14
#define S24 20
#define S31 4
#define S32 11
#define S33 16
#define S34 23
#define S41 6
#define S42 10
#define S43 15
#define S44 21

/* F, G, H and I are basic MD5 functions.
 */
#define F(x, y, z) ((((x) & ((y) ^ (z))) ^ (z)))
#define G(x, y, z) F(z, x, y)
#define H(x, y, z) ((x) ^ (y) ^ (z))
#define I(x, y, z) ((y) ^ ((x) | (~z)))

/* ROTATE_LEFT rotates x left n bits.
 */
#define ROTATE_LEFT(x, n) (((x) << (n) | ((x) >> (32-(n)))))

/* FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
 * Rotation is separate from addition to prevent recomputation.
 */
#define FF(a, b, c, d, s, ac)                    \
 (a) += F ((b), (c), (d)) + (NEXTx) + (U32)(ac); \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

#define GG(a, b, c, d, x, s, ac)                 \
 (a) += G ((b), (c), (d)) + X[x] + (U32)(ac);    \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

#define HH(a, b, c, d, x, s, ac)                 \
 (a) += H ((b), (c), (d)) + X[x] + (U32)(ac);    \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

#define II(a, b, c, d, x, s, ac)                 \
 (a) += I ((b), (c), (d)) + X[x] + (U32)(ac);    \
 TRUNC32((a));                                   \
 (a) = ROTATE_LEFT ((a), (s));                   \
 (a) += (b);                                     \
 TRUNC32((a));

static void MD5Init(MD5_CTX *ctx) {
  /* Start state */
  ctx->A = 0x67452301;
  ctx->B = 0xefcdab89;
  ctx->C = 0x98badcfe;
  ctx->D = 0x10325476;

  /* message length */
  ctx->bytes_low = ctx->bytes_high = 0;
}

static void MD5Transform(MD5_CTX* ctx, const U8* buf, STRLEN blocks) {
#ifdef MD5_DEBUG
  static int tcount = 0;
#endif

  U32 A = ctx->A;
  U32 B = ctx->B;
  U32 C = ctx->C;
  U32 D = ctx->D;

  do {
    U32 a = A;
    U32 b = B;
    U32 c = C;
    U32 d = D;

    U32 X[16];      /* little-endian values, used in round 2-4 */
    U32 *uptr = X;
    U32 tmp;
        #define NEXTx  (s2u(buf,tmp), buf += 4, *uptr++ = tmp)

#ifdef MD5_DEBUG
    if (buf == ctx->buffer)
      fprintf(stderr,"%5d: Transform ctx->buffer", ++tcount);
    else
      fprintf(stderr,"%5d: Transform %p (%d)", ++tcount, buf, blocks);

    {
      int i;
      fprintf(stderr,"[");
      for (i = 0; i < 16; i++) {
        fprintf(stderr,"%x,", X[i]); /* FIXME */
      }
      fprintf(stderr,"]\n");
    }
#endif

    /* Round 1 */
    FF (a, b, c, d, S11, 0xd76aa478); /* 1 */
    FF (d, a, b, c, S12, 0xe8c7b756); /* 2 */
    FF (c, d, a, b, S13, 0x242070db); /* 3 */
    FF (b, c, d, a, S14, 0xc1bdceee); /* 4 */
    FF (a, b, c, d, S11, 0xf57c0faf); /* 5 */
    FF (d, a, b, c, S12, 0x4787c62a); /* 6 */
    FF (c, d, a, b, S13, 0xa8304613); /* 7 */
    FF (b, c, d, a, S14, 0xfd469501); /* 8 */
    FF (a, b, c, d, S11, 0x698098d8); /* 9 */
    FF (d, a, b, c, S12, 0x8b44f7af); /* 10 */
    FF (c, d, a, b, S13, 0xffff5bb1); /* 11 */
    FF (b, c, d, a, S14, 0x895cd7be); /* 12 */
    FF (a, b, c, d, S11, 0x6b901122); /* 13 */
    FF (d, a, b, c, S12, 0xfd987193); /* 14 */
    FF (c, d, a, b, S13, 0xa679438e); /* 15 */
    FF (b, c, d, a, S14, 0x49b40821); /* 16 */

    /* Round 2 */
    GG (a, b, c, d,  1, S21, 0xf61e2562); /* 17 */
    GG (d, a, b, c,  6, S22, 0xc040b340); /* 18 */
    GG (c, d, a, b, 11, S23, 0x265e5a51); /* 19 */
    GG (b, c, d, a,  0, S24, 0xe9b6c7aa); /* 20 */
    GG (a, b, c, d,  5, S21, 0xd62f105d); /* 21 */
    GG (d, a, b, c, 10, S22,  0x2441453); /* 22 */
    GG (c, d, a, b, 15, S23, 0xd8a1e681); /* 23 */
    GG (b, c, d, a,  4, S24, 0xe7d3fbc8); /* 24 */
    GG (a, b, c, d,  9, S21, 0x21e1cde6); /* 25 */
    GG (d, a, b, c, 14, S22, 0xc33707d6); /* 26 */
    GG (c, d, a, b,  3, S23, 0xf4d50d87); /* 27 */
    GG (b, c, d, a,  8, S24, 0x455a14ed); /* 28 */
    GG (a, b, c, d, 13, S21, 0xa9e3e905); /* 29 */
    GG (d, a, b, c,  2, S22, 0xfcefa3f8); /* 30 */
    GG (c, d, a, b,  7, S23, 0x676f02d9); /* 31 */
    GG (b, c, d, a, 12, S24, 0x8d2a4c8a); /* 32 */

    /* Round 3 */
    HH (a, b, c, d,  5, S31, 0xfffa3942); /* 33 */
    HH (d, a, b, c,  8, S32, 0x8771f681); /* 34 */
    HH (c, d, a, b, 11, S33, 0x6d9d6122); /* 35 */
    HH (b, c, d, a, 14, S34, 0xfde5380c); /* 36 */
    HH (a, b, c, d,  1, S31, 0xa4beea44); /* 37 */
    HH (d, a, b, c,  4, S32, 0x4bdecfa9); /* 38 */
    HH (c, d, a, b,  7, S33, 0xf6bb4b60); /* 39 */
    HH (b, c, d, a, 10, S34, 0xbebfbc70); /* 40 */
    HH (a, b, c, d, 13, S31, 0x289b7ec6); /* 41 */
    HH (d, a, b, c,  0, S32, 0xeaa127fa); /* 42 */
    HH (c, d, a, b,  3, S33, 0xd4ef3085); /* 43 */
    HH (b, c, d, a,  6, S34,  0x4881d05); /* 44 */
    HH (a, b, c, d,  9, S31, 0xd9d4d039); /* 45 */
    HH (d, a, b, c, 12, S32, 0xe6db99e5); /* 46 */
    HH (c, d, a, b, 15, S33, 0x1fa27cf8); /* 47 */
    HH (b, c, d, a,  2, S34, 0xc4ac5665); /* 48 */

    /* Round 4 */
    II (a, b, c, d,  0, S41, 0xf4292244); /* 49 */
    II (d, a, b, c,  7, S42, 0x432aff97); /* 50 */
    II (c, d, a, b, 14, S43, 0xab9423a7); /* 51 */
    II (b, c, d, a,  5, S44, 0xfc93a039); /* 52 */
    II (a, b, c, d, 12, S41, 0x655b59c3); /* 53 */
    II (d, a, b, c,  3, S42, 0x8f0ccc92); /* 54 */
    II (c, d, a, b, 10, S43, 0xffeff47d); /* 55 */
    II (b, c, d, a,  1, S44, 0x85845dd1); /* 56 */
    II (a, b, c, d,  8, S41, 0x6fa87e4f); /* 57 */
    II (d, a, b, c, 15, S42, 0xfe2ce6e0); /* 58 */
    II (c, d, a, b,  6, S43, 0xa3014314); /* 59 */
    II (b, c, d, a, 13, S44, 0x4e0811a1); /* 60 */
    II (a, b, c, d,  4, S41, 0xf7537e82); /* 61 */
    II (d, a, b, c, 11, S42, 0xbd3af235); /* 62 */
    II (c, d, a, b,  2, S43, 0x2ad7d2bb); /* 63 */
    II (b, c, d, a,  9, S44, 0xeb86d391); /* 64 */

    A += a;  TRUNC32(A);
    B += b;  TRUNC32(B);
    C += c;  TRUNC32(C);
    D += d;  TRUNC32(D);

  } while (--blocks);
  ctx->A = A;
  ctx->B = B;
  ctx->C = C;
  ctx->D = D;
}

#ifdef MD5_DEBUG
static char*
ctx_dump(MD5_CTX* ctx)
{
    static char buf[1024];
    sprintf(buf, "{A=%x,B=%x,C=%x,D=%x,%d,%d(%d)}",
	    ctx->A, ctx->B, ctx->C, ctx->D,
	    ctx->bytes_low, ctx->bytes_high, (ctx->bytes_low&0x3F));
    return buf;
}
#endif

static void MD5Update(MD5_CTX* ctx, const U8* buf, STRLEN len) {
  STRLEN blocks;
  STRLEN fill = ctx->bytes_low & 0x3F;

#ifdef MD5_DEBUG
  static int ucount = 0;
  fprintf(stderr,"%5i: Update(%s, %p, %d)\n", ++ucount, ctx_dump(ctx), buf, len);
#endif

  ctx->bytes_low += (U32)len;
  if (ctx->bytes_low < len) /* wrap around */
    ctx->bytes_high++;

  if (fill) {
    STRLEN missing = 64 - fill;
    if (len < missing) {
      Copy(buf, ctx->buffer + fill, len, U8);
      return;
    }
    Copy(buf, ctx->buffer + fill, missing, U8);
    MD5Transform(ctx, ctx->buffer, 1);
    buf += missing;
    len -= missing;
  }

  blocks = len >> 6;
  if (blocks)
    MD5Transform(ctx, buf, blocks);
  if ( (len &= 0x3F)) {
    Copy(buf + (blocks << 6), ctx->buffer, len, U8);
  }
}

static void MD5Final(U8* digest, MD5_CTX *ctx) {
  STRLEN fill = ctx->bytes_low & 0x3F;
  STRLEN padlen = (fill < 56 ? 56 : 120) - fill;
  U32 bits_low, bits_high;
#ifdef MD5_DEBUG
  fprintf(stderr,"       Final:  %s\n", ctx_dump(ctx));
#endif
  Copy(PADDING, ctx->buffer + fill, padlen, U8);
  fill += padlen;

  bits_low = ctx->bytes_low << 3;
  bits_high = (ctx->bytes_high << 3) | (ctx->bytes_low  >> 29);
  u2s(bits_low,  ctx->buffer + fill);   fill += 4;
  u2s(bits_high, ctx->buffer + fill);   fill += 4;

  MD5Transform(ctx, ctx->buffer, fill >> 6);
#ifdef MD5_DEBUG
  fprintf(stderr,"       Result: %s\n", ctx_dump(ctx));
#endif

  u2s(ctx->A, digest);
  u2s(ctx->B, digest+4);
  u2s(ctx->C, digest+8);
  u2s(ctx->D, digest+12);
}
/*----------------------------------------------------------------*/

/* declared above since also used in sha1
static const char *hexdigits = "0123456789abcdef";
*/

static void hex_16(const unsigned char* from, char* to) {
  const unsigned char *end = from + 16;
  char *d = to;

  while (from < end) {
    *d++ = hexdigits[(*from >> 4)];
    *d++ = hexdigits[(*from & 0x0F)];
    from++;
  }
  *d = '\0';
}

void uu_hash_md5(pUCXT, struct_uu_t *io, char *name) {
  /* io is assumed to be a v1 namespace uuid coming in. */
  /* name is... a name. */
  MD5_CTX       context;
  char          tmp[37];
  char          vardig;
  unsigned char digeststr[21];
  uu_t          packed;

  uu_pack_v1(io, (U8*)&packed);

  MD5Init(&context);

  MD5Update(&context, (U8*)&packed, sizeof(packed));
  if (name)
    MD5Update(&context, (U8*)name, strlen(name));

  MD5Final((U8*)digeststr, &context);
  digeststr[20] = '\0';

  hex_16(digeststr, tmp);
  tmp[32] = '\0';

  /* hyphenate */
  Move(&tmp[20], &tmp[21], 12, char); tmp[20] = '-';
  Move(&tmp[16], &tmp[17], 17, char); tmp[16] = '-';
  Move(&tmp[12], &tmp[13], 22, char); tmp[12] = '-';
  Move(&tmp[ 8], &tmp[ 9], 27, char); tmp[ 8] = '-';
  tmp[36] = '\0';

  /* version */
  tmp[14] = '3';

  /* variant */
  vardig = tmp[19] - 48;
  if (vardig > 9) vardig -= 7;
  if (vardig > 15) vardig -= 32;
  vardig = (vardig & 0x3) | 0x8;
  if (vardig > 9) vardig += 87;
  else vardig += 48;
  tmp[19] = vardig;

  uu_parse(tmp, io);
}


/******************************************************************/
/******************************************************************/
/******************************************************************/


/* borrowed from Digest::SHA1                                     */
/*----------------------------------------------------------------*/
/* NIST Secure Hash Algorithm */
/* heavily modified by Uwe Hollerbach <uh@alumni.caltech edu> */
/* from Peter C. Gutmann's implementation as found in */
/* Applied Cryptography by Bruce Schneier */
/* Further modifications to include the "UNRAVEL" stuff, below */

/* This code is in the public domain */

/* Useful defines & typedefs */

#if defined(U64TYPE) && (defined(USE_64_BIT_INT) || ((BYTEORDER != 0x1234) && (BYTEORDER != 0x4321)))
typedef U64TYPE ULONGx;
# if BYTEORDER == 0x1234
#   undef BYTEORDER
#   define BYTEORDER 0x12345678
# elif BYTEORDER == 0x4321
#   undef BYTEORDER
#   define BYTEORDER 0x87654321
# endif
#else
typedef unsigned long ULONGx;     /* 32-or-more-bit quantity */
#endif

#define SHA_BLOCKSIZE       64
#define SHA_DIGESTSIZE      20

typedef struct {
    ULONGx digest[5];       /* message digest */
    ULONGx count_lo, count_hi;  /* 64-bit bit count */
    U8 data[SHA_BLOCKSIZE]; /* SHA data buffer */
    int local;          /* unprocessed amount in data */
} SHA_INFO;


/* UNRAVEL should be fastest & biggest */
/* UNROLL_LOOPS should be just as big, but slightly slower */
/* both undefined should be smallest and slowest */

#define SHA_VERSION 1
#define UNRAVEL
/* #define UNROLL_LOOPS */
/* SHA f()-functions */
#define f1(x,y,z)   ((x & y) | (~x & z))
#define f2(x,y,z)   (x ^ y ^ z)
#define f3(x,y,z)   ((x & y) | (x & z) | (y & z))
#define f4(x,y,z)   (x ^ y ^ z)

/* SHA constants */
#define CONST1      0x5a827999L
#define CONST2      0x6ed9eba1L
#define CONST3      0x8f1bbcdcL
#define CONST4      0xca62c1d6L

/* truncate to 32 bits -- should be a null op on 32-bit machines */
#define T32(x)  ((x) & 0xffffffffL)

/* 32-bit rotate */
#define R32(x,n)    T32(((x << n) | (x >> (32 - n))))

/* the generic case, for when the overall rotation is not unraveled */
#define FG(n)   \
    T = T32(R32(A,5) + f##n(B,C,D) + E + *WP++ + CONST##n); \
    E = D; D = C; C = R32(B,30); B = A; A = T

/* specific cases, for when the overall rotation is unraveled */
#define FA(n)   \
    T = T32(R32(A,5) + f##n(B,C,D) + E + *WP++ + CONST##n); B = R32(B,30)

#define FB(n)   \
    E = T32(R32(T,5) + f##n(A,B,C) + D + *WP++ + CONST##n); A = R32(A,30)

#define FC(n)   \
    D = T32(R32(E,5) + f##n(T,A,B) + C + *WP++ + CONST##n); T = R32(T,30)

#define FD(n)   \
    C = T32(R32(D,5) + f##n(E,T,A) + B + *WP++ + CONST##n); E = R32(E,30)

#define FE(n)   \
    B = T32(R32(C,5) + f##n(D,E,T) + A + *WP++ + CONST##n); D = R32(D,30)

#define FT(n)   \
    A = T32(R32(B,5) + f##n(C,D,E) + T + *WP++ + CONST##n); C = R32(C,30)

static void sha_transform(SHA_INFO *sha_info)
{
    int i;
    U8 *dp;
    ULONGx T, A, B, C, D, E, W[80], *WP;

    dp = sha_info->data;

/*
the following makes sure that at least one code block below is
traversed or an error is reported, without the necessity for nested
preprocessor if/else/endif blocks, which are a great pain in the
nether regions of the anatomy...
*/
#undef SWAP_DONE

#if BYTEORDER == 0x1234
#define SWAP_DONE
    /* assert(sizeof(ULONGx) == 4); */
    for (i = 0; i < 16; ++i) {
    T = *((ULONGx *) dp);
    dp += 4;
    W[i] =  ((T << 24) & 0xff000000) | ((T <<  8) & 0x00ff0000) |
        ((T >>  8) & 0x0000ff00) | ((T >> 24) & 0x000000ff);
    }
#endif

#if BYTEORDER == 0x4321
#define SWAP_DONE
    /* assert(sizeof(ULONGx) == 4); */
    for (i = 0; i < 16; ++i) {
    T = *((ULONGx *) dp);
    dp += 4;
    W[i] = T32(T);
    }
#endif

#if BYTEORDER == 0x12345678
#define SWAP_DONE
    /* assert(sizeof(ULONGx) == 8); */
    for (i = 0; i < 16; i += 2) {
    T = *((ULONGx *) dp);
    dp += 8;
    W[i] =  ((T << 24) & 0xff000000) | ((T <<  8) & 0x00ff0000) |
        ((T >>  8) & 0x0000ff00) | ((T >> 24) & 0x000000ff);
    T >>= 32;
    W[i+1] = ((T << 24) & 0xff000000) | ((T <<  8) & 0x00ff0000) |
         ((T >>  8) & 0x0000ff00) | ((T >> 24) & 0x000000ff);
    }
#endif

#if BYTEORDER == 0x87654321
#define SWAP_DONE
    /* assert(sizeof(ULONGx) == 8); */
    for (i = 0; i < 16; i += 2) {
    T = *((ULONGx *) dp);
    dp += 8;
    W[i] = T32(T >> 32);
    W[i+1] = T32(T);
    }
#endif

#ifndef SWAP_DONE
#error Unknown byte order -- you need to add code here
#endif /* SWAP_DONE */

    for (i = 16; i < 80; ++i) {
    W[i] = W[i-3] ^ W[i-8] ^ W[i-14] ^ W[i-16];
#if (SHA_VERSION == 1)
    W[i] = R32(W[i], 1);
#endif /* SHA_VERSION */
    }
    A = sha_info->digest[0];
    B = sha_info->digest[1];
    C = sha_info->digest[2];
    D = sha_info->digest[3];
    E = sha_info->digest[4];
    WP = W;
#ifdef UNRAVEL
    FA(1); FB(1); FC(1); FD(1); FE(1); FT(1); FA(1); FB(1); FC(1); FD(1);
    FE(1); FT(1); FA(1); FB(1); FC(1); FD(1); FE(1); FT(1); FA(1); FB(1);
    FC(2); FD(2); FE(2); FT(2); FA(2); FB(2); FC(2); FD(2); FE(2); FT(2);
    FA(2); FB(2); FC(2); FD(2); FE(2); FT(2); FA(2); FB(2); FC(2); FD(2);
    FE(3); FT(3); FA(3); FB(3); FC(3); FD(3); FE(3); FT(3); FA(3); FB(3);
    FC(3); FD(3); FE(3); FT(3); FA(3); FB(3); FC(3); FD(3); FE(3); FT(3);
    FA(4); FB(4); FC(4); FD(4); FE(4); FT(4); FA(4); FB(4); FC(4); FD(4);
    FE(4); FT(4); FA(4); FB(4); FC(4); FD(4); FE(4); FT(4); FA(4); FB(4);
    sha_info->digest[0] = T32(sha_info->digest[0] + E);
    sha_info->digest[1] = T32(sha_info->digest[1] + T);
    sha_info->digest[2] = T32(sha_info->digest[2] + A);
    sha_info->digest[3] = T32(sha_info->digest[3] + B);
    sha_info->digest[4] = T32(sha_info->digest[4] + C);
#else /* !UNRAVEL */
#ifdef UNROLL_LOOPS
    FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1);
    FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1); FG(1);
    FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2);
    FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2); FG(2);
    FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3);
    FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3); FG(3);
    FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4);
    FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4); FG(4);
#else /* !UNROLL_LOOPS */
    for (i =  0; i < 20; ++i) { FG(1); }
    for (i = 20; i < 40; ++i) { FG(2); }
    for (i = 40; i < 60; ++i) { FG(3); }
    for (i = 60; i < 80; ++i) { FG(4); }
#endif /* !UNROLL_LOOPS */
    sha_info->digest[0] = T32(sha_info->digest[0] + A);
    sha_info->digest[1] = T32(sha_info->digest[1] + B);
    sha_info->digest[2] = T32(sha_info->digest[2] + C);
    sha_info->digest[3] = T32(sha_info->digest[3] + D);
    sha_info->digest[4] = T32(sha_info->digest[4] + E);
#endif /* !UNRAVEL */
}

/* initialize the SHA digest */

static void sha_init(SHA_INFO *sha_info)
{
    sha_info->digest[0] = 0x67452301L;
    sha_info->digest[1] = 0xefcdab89L;
    sha_info->digest[2] = 0x98badcfeL;
    sha_info->digest[3] = 0x10325476L;
    sha_info->digest[4] = 0xc3d2e1f0L;
    sha_info->count_lo = 0L;
    sha_info->count_hi = 0L;
    sha_info->local = 0;
}

/* update the SHA digest */

static void sha_update(SHA_INFO *sha_info, U8 *buffer, int count)
{
    int i;
    ULONGx clo;

    clo = T32(sha_info->count_lo + ((ULONGx) count << 3));
    if (clo < sha_info->count_lo) {
    ++sha_info->count_hi;
    }
    sha_info->count_lo = clo;
    sha_info->count_hi += (ULONGx) count >> 29;
    if (sha_info->local) {
    i = SHA_BLOCKSIZE - sha_info->local;
    if (i > count) {
        i = count;
    }
    memcpy(((U8 *) sha_info->data) + sha_info->local, buffer, i);
    count -= i;
    buffer += i;
    sha_info->local += i;
    if (sha_info->local == SHA_BLOCKSIZE) {
        sha_transform(sha_info);
    } else {
        return;
    }
    }
    while (count >= SHA_BLOCKSIZE) {
    memcpy(sha_info->data, buffer, SHA_BLOCKSIZE);
    buffer += SHA_BLOCKSIZE;
    count -= SHA_BLOCKSIZE;
    sha_transform(sha_info);
    }
    memcpy(sha_info->data, buffer, count);
    sha_info->local = count;
}


static void sha_transform_and_copy(unsigned char digest[20], SHA_INFO *sha_info)
{
    sha_transform(sha_info);
    digest[ 0] = (unsigned char) ((sha_info->digest[0] >> 24) & 0xff);
    digest[ 1] = (unsigned char) ((sha_info->digest[0] >> 16) & 0xff);
    digest[ 2] = (unsigned char) ((sha_info->digest[0] >>  8) & 0xff);
    digest[ 3] = (unsigned char) ((sha_info->digest[0]      ) & 0xff);
    digest[ 4] = (unsigned char) ((sha_info->digest[1] >> 24) & 0xff);
    digest[ 5] = (unsigned char) ((sha_info->digest[1] >> 16) & 0xff);
    digest[ 6] = (unsigned char) ((sha_info->digest[1] >>  8) & 0xff);
    digest[ 7] = (unsigned char) ((sha_info->digest[1]      ) & 0xff);
    digest[ 8] = (unsigned char) ((sha_info->digest[2] >> 24) & 0xff);
    digest[ 9] = (unsigned char) ((sha_info->digest[2] >> 16) & 0xff);
    digest[10] = (unsigned char) ((sha_info->digest[2] >>  8) & 0xff);
    digest[11] = (unsigned char) ((sha_info->digest[2]      ) & 0xff);
    digest[12] = (unsigned char) ((sha_info->digest[3] >> 24) & 0xff);
    digest[13] = (unsigned char) ((sha_info->digest[3] >> 16) & 0xff);
    digest[14] = (unsigned char) ((sha_info->digest[3] >>  8) & 0xff);
    digest[15] = (unsigned char) ((sha_info->digest[3]      ) & 0xff);
    digest[16] = (unsigned char) ((sha_info->digest[4] >> 24) & 0xff);
    digest[17] = (unsigned char) ((sha_info->digest[4] >> 16) & 0xff);
    digest[18] = (unsigned char) ((sha_info->digest[4] >>  8) & 0xff);
    digest[19] = (unsigned char) ((sha_info->digest[4]      ) & 0xff);
}

/* finish computing the SHA digest */
static void sha_final(unsigned char digest[20], SHA_INFO *sha_info)
{
    int count;
    ULONGx lo_bit_count, hi_bit_count;

    lo_bit_count = sha_info->count_lo;
    hi_bit_count = sha_info->count_hi;
    count = (int) ((lo_bit_count >> 3) & 0x3f);
    ((U8 *) sha_info->data)[count++] = 0x80;
    if (count > SHA_BLOCKSIZE - 8) {
    memset(((U8 *) sha_info->data) + count, 0, SHA_BLOCKSIZE - count);
    sha_transform(sha_info);
    memset((U8 *) sha_info->data, 0, SHA_BLOCKSIZE - 8);
    } else {
    memset(((U8 *) sha_info->data) + count, 0,
        SHA_BLOCKSIZE - 8 - count);
    }
    sha_info->data[56] = (U8)((hi_bit_count >> 24) & 0xff);
    sha_info->data[57] = (U8)((hi_bit_count >> 16) & 0xff);
    sha_info->data[58] = (U8)((hi_bit_count >>  8) & 0xff);
    sha_info->data[59] = (U8)((hi_bit_count >>  0) & 0xff);
    sha_info->data[60] = (U8)((lo_bit_count >> 24) & 0xff);
    sha_info->data[61] = (U8)((lo_bit_count >> 16) & 0xff);
    sha_info->data[62] = (U8)((lo_bit_count >>  8) & 0xff);
    sha_info->data[63] = (U8)((lo_bit_count >>  0) & 0xff);
    sha_transform_and_copy(digest, sha_info);
}
/*----------------------------------------------------------------*/

/* declared above since also used in md5
static const char *hexdigits = "0123456789abcdef";
*/

static void hex_20(const unsigned char* from, char* to) {
  const unsigned char *end = from + 20;
  char *d = to;

  while (from < end) {
    *d++ = hexdigits[(*from >> 4)];
    *d++ = hexdigits[(*from & 0x0F)];
    from++;
  }
  *d = '\0';
}

void uu_hash_sha1(pUCXT, struct_uu_t *io, char *name) {
  /* io is assumed to be a v1 namespace uuid coming in. */
  /* do hton*() here. */
  /* name is... a name. */
  SHA_INFO      context;
  char          tmp[41];
  char          vardig;
  unsigned char digeststr[21];
  uu_t          packed;

  uu_pack_v1(io, (U8*)&packed);

  sha_init(&context);

  sha_update(&context, (U8*)&packed, sizeof(packed));
  if (name)
    sha_update(&context, (U8*)name, (int)strlen(name));

  sha_final((U8*)&digeststr, &context);
  digeststr[20] = '\0';

  hex_20(digeststr, tmp);
  tmp[32] = '\0';

  /* hyphenate */
  Move(&tmp[20], &tmp[21], 12, char); tmp[20] = '-';
  Move(&tmp[16], &tmp[17], 17, char); tmp[16] = '-';
  Move(&tmp[12], &tmp[13], 22, char); tmp[12] = '-';
  Move(&tmp[ 8], &tmp[ 9], 27, char); tmp[ 8] = '-';
  tmp[36] = '\0';

  /* version */
  tmp[14] = '5';

  /* variant */
  vardig = tmp[19] - 48;
  if (vardig > 9) vardig -= 7;
  if (vardig > 15) vardig -= 32;
  vardig = (vardig & 0x3) | 0x8;
  if (vardig > 9) vardig += 87;
  else vardig += 48;
  tmp[19] = vardig;

  uu_parse(tmp, io);
}

/* ex:set ts=2 sw=2 itab=spaces: */
