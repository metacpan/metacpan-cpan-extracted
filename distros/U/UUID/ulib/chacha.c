#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/chacha.h"
#include "ulib/splitmix.h"
#include "ulib/xoshiro.h"

#ifdef __cplusplus
}
#endif

/* perl versions broken on some platforms */
#undef U8TO16_LE
#define U8TO16_LE(p) (   \
  ((U16)((p)[0])     ) | \
  ((U16)((p)[1]) << 8)   \
)
#undef U8TO32_LE
#define U8TO32_LE(p) (    \
  ((U32)((p)[0])      ) | \
  ((U32)((p)[1]) <<  8) | \
  ((U32)((p)[2]) << 16) | \
  ((U32)((p)[3]) << 24)   \
)
#undef U8TO64_LE
#define U8TO64_LE(p) (    \
  ((U64)((p)[0])      ) | \
  ((U64)((p)[1]) <<  8) | \
  ((U64)((p)[2]) << 16) | \
  ((U64)((p)[3]) << 24) | \
  ((U64)((p)[4]) << 32) | \
  ((U64)((p)[5]) << 40) | \
  ((U64)((p)[6]) << 48) | \
  ((U64)((p)[7]) << 56)   \
)
#undef U32TO8_LE
#define U32TO8_LE(p, v) do {       \
  U32 _v = v;                      \
  (p)[0] = (((_v)      ) & 0xFFU); \
  (p)[1] = (((_v) >>  8) & 0xFFU); \
  (p)[2] = (((_v) >> 16) & 0xFFU); \
  (p)[3] = (((_v) >> 24) & 0xFFU); \
} while (0)

/* perls ROTL32 broken too */
#define rotl32(x,r) ((((U32)(x)) << (r)) | (((U32)(x)) >> (32 - (r))))

#define QROUND(a,b,c,d) \
  a += b; d = rotl32(d ^ a, 16); \
  c += d; b = rotl32(b ^ c, 12); \
  a += b; d = rotl32(d ^ a,  8); \
  c += d; b = rotl32(b ^ c,  7);


static void chacha_init(pUCXT, const UCHAR *seed, IV init_buffer) {
  chacha_t *cc = &SMEM->cc;
  U32 *x = (U32*)&cc->state;

  x[ 0] = 0x61707865;
  x[ 1] = 0x3320646e;
  x[ 2] = 0x79622d32;
  x[ 3] = 0x6b206574;
  x[ 4] = U8TO32_LE(seed +  0);
  x[ 5] = U8TO32_LE(seed +  4);
  x[ 6] = U8TO32_LE(seed +  8);
  x[ 7] = U8TO32_LE(seed + 12);
  x[ 8] = U8TO32_LE(seed + 16);
  x[ 9] = U8TO32_LE(seed + 20);
  x[10] = U8TO32_LE(seed + 24);
  x[11] = U8TO32_LE(seed + 28);
  x[12] = 0;
  x[13] = 0;
  x[14] = U8TO32_LE(seed + 32);
  x[15] = U8TO32_LE(seed + 36);

  if (init_buffer) {
    memset(cc->buf, 0, CC_BUFSZ);
    cc->have = 0;
  }
}

static void chacha_core(pUCXT, UCHAR* buf) {
  chacha_t *cc = &SMEM->cc;
  U32 *s = cc->state;
  U32 i, x[16];

  memcpy(x, s, 16*sizeof(U32));

  for (i = 0; i<CC_ROUNDS; i+=2) {
    QROUND( x[ 0], x[ 4], x[ 8], x[12] );
    QROUND( x[ 1], x[ 5], x[ 9], x[13] );
    QROUND( x[ 2], x[ 6], x[10], x[14] );
    QROUND( x[ 3], x[ 7], x[11], x[15] );
    QROUND( x[ 0], x[ 5], x[10], x[15] );
    QROUND( x[ 1], x[ 6], x[11], x[12] );
    QROUND( x[ 2], x[ 7], x[ 8], x[13] );
    QROUND( x[ 3], x[ 4], x[ 9], x[14] );
  }

  for (i = 0; i < 16; i++)
    x[i] += s[i];

  for (i = 0; i < 16; i++)
    U32TO8_LE( buf+4*i, x[i] );

  /* inc counter */
  if (++s[12] == 0) s[13]++;
}

static U16 chacha_stream(pUCXT, UCHAR* buf, U16 n) {
  U16   r = n;
  UCHAR sbuf[CC_CORESZ];

  while (r >= CC_CORESZ) {
    chacha_core(aUCXT, buf);
    buf += CC_CORESZ;
    r -= CC_CORESZ;
  }
  if (r > 0) {
    chacha_core(aUCXT, sbuf);
    memcpy(buf, sbuf, r);
  }
  return n;
}

static U32 chacha_refill(pUCXT) {
  chacha_t *cc = &SMEM->cc;
  U64   *cp;

  /* refill buffer */
  cc->have = chacha_stream(aUCXT, (UCHAR*)&cc->buf, CC_BUFSZ);

  /* reseed with KEYSZ bytes from buffer, then zero */
  /*
  chacha_init(cc.buf, 0);
  memset(cc.buf, 0, KEYSZ);
  cc.have = BUFSZ - KEYSZ;
  return cc.have;
  */

  /* create new key */
  /*
  UCHAR seed[40];
  cp = (U64*)&seed;
  *cp++ = uu_xoshiro_rand();
  *cp++ = uu_xoshiro_rand();
  *cp++ = uu_xoshiro_rand();
  *cp++ = uu_xoshiro_rand();
  *cp++ = uu_xoshiro_rand();
  chacha_init((UCHAR*)&seed, 0);
  return cc.have;
  */

  /* salt the state */
  /*
  cp = (U64*)&cc.state;
  while (cp < (U64*)&cc.buf)
    *cp++ ^= (U32)uu_xoshiro_rand();
  return cc.have;
  */

  /* salt the buffer */
  cp = (U64*)&cc->buf;
  while (cp < (U64*)&cc->have)
    *cp++ ^= uu_xoshiro_rand(aUCXT);
  return cc->have;
}

void uu_chacha_srand(pUCXT) {
  U64     d, n, *cp;
  UCHAR   data[40];

  uu_splitmix_srand(aUCXT);
  uu_xoshiro_srand(aUCXT);

  cp = (U64*)&data;

  *cp++ = uu_xoshiro_rand(aUCXT);
  *cp++ = uu_xoshiro_rand(aUCXT);
  *cp++ = uu_xoshiro_rand(aUCXT);
  *cp++ = uu_xoshiro_rand(aUCXT);
  *cp++ = uu_xoshiro_rand(aUCXT);

  chacha_init(aUCXT, data, 1);

  /* stir 8 - 39 times */
  uu_chacha_rand64(aUCXT, &d);
  n = 8 + (d >> 59);

  while (n-- > 0)
    uu_chacha_rand64(aUCXT, &d);
}

/* API */

void uu_chacha_rand16(pUCXT, U16 *out) {
  chacha_t *cc = &SMEM->cc;
  UCHAR *ptr;

  if (cc->have < 2) chacha_refill(aUCXT);
  ptr = cc->buf + CC_BUFSZ - cc->have;
  cc->have -= 2;

  *out = U8TO16_LE(ptr);
}

void uu_chacha_rand32(pUCXT, U32 *out) {
  chacha_t *cc = &SMEM->cc;
  UCHAR *ptr;

  if (cc->have < 4) chacha_refill(aUCXT);
  ptr = cc->buf + CC_BUFSZ - cc->have;
  cc->have -= 4;

  *out = U8TO32_LE(ptr);
}

void uu_chacha_rand64(pUCXT, U64 *out) {
  chacha_t *cc = &SMEM->cc;
  UCHAR *ptr;

  if (cc->have < 8) chacha_refill(aUCXT);
  ptr = cc->buf + CC_BUFSZ - cc->have;
  cc->have -= 8;

  *out = U8TO64_LE(ptr);
}

void uu_chacha_rand128(pUCXT, void *out) {
  chacha_t *cc = &SMEM->cc;
  U64   a, b;
  UCHAR *ptr;

  if (cc->have < 16) chacha_refill(aUCXT);
  ptr = cc->buf + CC_BUFSZ - cc->have;
  cc->have -= 16;

  a = U8TO64_LE(ptr);
  b = U8TO64_LE(ptr);
  *((U64*)out)     = a;
  *(((U64*)out)+8) = b;
}

/* ex:set ts=2 sw=2 itab=spaces: */
