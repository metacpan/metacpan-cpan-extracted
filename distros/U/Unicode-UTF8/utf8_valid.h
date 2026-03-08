/*
 * Copyright (c) 2017-2026 Christian Hansen <chansen@cpan.org>
 * <https://github.com/chansen/c-utf8-valid>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Shift-based DFA for UTF-8 validation
 *
 * Same 9-state DFA as the 64-bit version, but state offsets are chosen
 * by an SMT solver so all transition rows fit in a plain uint32_t.
 *
 * S_ERROR = 0: error transitions contribute nothing to a row value
 * since (S_ERROR << offset) == 0 for any offset.
 *
 * State offsets (bit positions within each row):
 *
 *   S_ERROR  =  0  Invalid byte seen (absorbing)
 *   S_ACCEPT =  6  Start / Accept
 *   S_TAIL1  = 16  Expect 1 more tail byte  (80-BF -> S_ACCEPT)
 *   S_TAIL2  =  1  Expect 2 more tail bytes (80-BF -> S_TAIL1)
 *   S_E0     = 19  After E0:    next tail must be A0-BF -> S_TAIL1
 *   S_ED     = 25  After ED:    next tail must be 80-9F -> S_TAIL1
 *   S_F0     = 11  After F0:    next tail must be 90-BF -> S_TAIL2
 *   S_F1_F3  = 18  After F1-F3: next tail         80-BF -> S_TAIL2
 *   S_F4     = 24  After F4:    next tail must be 80-8F -> S_TAIL2
 *
 * Sequence flows:
 *   1-byte:  S_ACCEPT -> S_ACCEPT
 *   2-byte:  S_ACCEPT -> S_TAIL1 -> S_ACCEPT
 *   3-byte:  S_ACCEPT -> S_TAIL2 -> S_TAIL1 -> S_ACCEPT
 *            (via S_E0 or S_ED for restricted leads)
 *   4-byte:  S_ACCEPT -> S_TAIL2 -> S_TAIL1 -> S_ACCEPT
 *            (via S_F0, S_F1_F3, or S_F4 for lead)
 *
 *
 * UTF-8 Encoding Form:
 *
 *    U+0000..U+007F       0xxxxxxx
 *    U+0080..U+07FF       110xxxxx 10xxxxxx
 *    U+0800..U+FFFF       1110xxxx 10xxxxxx 10xxxxxx
 *   U+10000..U+10FFFF     11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 *
 *
 *    U+0000..U+007F       00..7F
 *                      N  C0..C1  80..BF                   1100000x 10xxxxxx
 *    U+0080..U+07FF       C2..DF  80..BF
 *                      N  E0      80..9F  80..BF           11100000 100xxxxx
 *    U+0800..U+0FFF       E0      A0..BF  80..BF
 *    U+1000..U+CFFF       E1..EC  80..BF  80..BF
 *    U+D000..U+D7FF       ED      80..9F  80..BF
 *                      S  ED      A0..BF  80..BF           11101101 101xxxxx
 *    U+E000..U+FFFF       EE..EF  80..BF  80..BF
 *                      N  F0      80..8F  80..BF  80..BF   11110000 1000xxxx
 *   U+10000..U+3FFFF      F0      90..BF  80..BF  80..BF
 *   U+40000..U+FFFFF      F1..F3  80..BF  80..BF  80..BF
 *  U+100000..U+10FFFF     F4      80..8F  80..BF  80..BF   11110100 1000xxxx
 *
 *  Legend:
 *    N = Non-shortest form
 *    S = Surrogates
 */

#ifndef UTF8_VALID_H
#define UTF8_VALID_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#if defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && (_M_IX86_FP >= 2))
#  define UTF8_VALID_HAS_SSE2 1
#  include <emmintrin.h>
#elif defined(__aarch64__)
#  define UTF8_VALID_HAS_NEON 1
#  include <arm_neon.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define S_ERROR   0
#define S_ACCEPT  6
#define S_TAIL1  16
#define S_TAIL2   1
#define S_E0     19
#define S_ED     25
#define S_F0     11
#define S_F1_F3  18
#define S_F4     24

/* clang-format off */

#define DFA_ROW(accept,error,tail1,tail2,e0,ed,f0,f1_f3,f4) \
  ( ((uint32_t)(accept) << S_ACCEPT) \
  | ((uint32_t)(error)  << S_ERROR) \
  | ((uint32_t)(tail1)  << S_TAIL1) \
  | ((uint32_t)(tail2)  << S_TAIL2) \
  | ((uint32_t)(e0)     << S_E0) \
  | ((uint32_t)(ed)     << S_ED) \
  | ((uint32_t)(f0)     << S_F0) \
  | ((uint32_t)(f1_f3)  << S_F1_F3) \
  | ((uint32_t)(f4)     << S_F4) )

#define ERR S_ERROR

#define ASCII_ROW DFA_ROW(S_ACCEPT,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define LEAD2_ROW DFA_ROW(S_TAIL1,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define LEAD3_ROW DFA_ROW(S_TAIL2,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define LEAD4_ROW DFA_ROW(S_F1_F3,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define ERROR_ROW DFA_ROW(ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)

/*
 * Continuation byte rows.
 * Columns: ACCEPT  ERROR  TAIL1      TAIL2      E0        ED        F0         F1_F3      F4
 *
 * 80-8F:   ERR     ERR    ->ACCEPT   ->TAIL1    ->ERR     ->TAIL1   ->ERR      ->TAIL2    ->TAIL2
 * 90-9F:   ERR     ERR    ->ACCEPT   ->TAIL1    ->ERR     ->TAIL1   ->TAIL2    ->TAIL2    ->ERR
 * A0-BF:   ERR     ERR    ->ACCEPT   ->TAIL1    ->TAIL1   ->ERR     ->TAIL2    ->TAIL2    ->ERR
 */
#define CONT_80_8F DFA_ROW(ERR,ERR,S_ACCEPT,S_TAIL1,ERR,    S_TAIL1,ERR,     S_TAIL2,S_TAIL2)
#define CONT_90_9F DFA_ROW(ERR,ERR,S_ACCEPT,S_TAIL1,ERR,    S_TAIL1,S_TAIL2, S_TAIL2,ERR)
#define CONT_A0_BF DFA_ROW(ERR,ERR,S_ACCEPT,S_TAIL1,S_TAIL1,ERR,    S_TAIL2, S_TAIL2,ERR)

static const uint32_t utf8_dfa[256] = {
  // 00-7F
  [0x00]=ASCII_ROW,[0x01]=ASCII_ROW,[0x02]=ASCII_ROW,[0x03]=ASCII_ROW,
  [0x04]=ASCII_ROW,[0x05]=ASCII_ROW,[0x06]=ASCII_ROW,[0x07]=ASCII_ROW,
  [0x08]=ASCII_ROW,[0x09]=ASCII_ROW,[0x0A]=ASCII_ROW,[0x0B]=ASCII_ROW,
  [0x0C]=ASCII_ROW,[0x0D]=ASCII_ROW,[0x0E]=ASCII_ROW,[0x0F]=ASCII_ROW,
  [0x10]=ASCII_ROW,[0x11]=ASCII_ROW,[0x12]=ASCII_ROW,[0x13]=ASCII_ROW,
  [0x14]=ASCII_ROW,[0x15]=ASCII_ROW,[0x16]=ASCII_ROW,[0x17]=ASCII_ROW,
  [0x18]=ASCII_ROW,[0x19]=ASCII_ROW,[0x1A]=ASCII_ROW,[0x1B]=ASCII_ROW,
  [0x1C]=ASCII_ROW,[0x1D]=ASCII_ROW,[0x1E]=ASCII_ROW,[0x1F]=ASCII_ROW,
  [0x20]=ASCII_ROW,[0x21]=ASCII_ROW,[0x22]=ASCII_ROW,[0x23]=ASCII_ROW,
  [0x24]=ASCII_ROW,[0x25]=ASCII_ROW,[0x26]=ASCII_ROW,[0x27]=ASCII_ROW,
  [0x28]=ASCII_ROW,[0x29]=ASCII_ROW,[0x2A]=ASCII_ROW,[0x2B]=ASCII_ROW,
  [0x2C]=ASCII_ROW,[0x2D]=ASCII_ROW,[0x2E]=ASCII_ROW,[0x2F]=ASCII_ROW,
  [0x30]=ASCII_ROW,[0x31]=ASCII_ROW,[0x32]=ASCII_ROW,[0x33]=ASCII_ROW,
  [0x34]=ASCII_ROW,[0x35]=ASCII_ROW,[0x36]=ASCII_ROW,[0x37]=ASCII_ROW,
  [0x38]=ASCII_ROW,[0x39]=ASCII_ROW,[0x3A]=ASCII_ROW,[0x3B]=ASCII_ROW,
  [0x3C]=ASCII_ROW,[0x3D]=ASCII_ROW,[0x3E]=ASCII_ROW,[0x3F]=ASCII_ROW,
  [0x40]=ASCII_ROW,[0x41]=ASCII_ROW,[0x42]=ASCII_ROW,[0x43]=ASCII_ROW,
  [0x44]=ASCII_ROW,[0x45]=ASCII_ROW,[0x46]=ASCII_ROW,[0x47]=ASCII_ROW,
  [0x48]=ASCII_ROW,[0x49]=ASCII_ROW,[0x4A]=ASCII_ROW,[0x4B]=ASCII_ROW,
  [0x4C]=ASCII_ROW,[0x4D]=ASCII_ROW,[0x4E]=ASCII_ROW,[0x4F]=ASCII_ROW,
  [0x50]=ASCII_ROW,[0x51]=ASCII_ROW,[0x52]=ASCII_ROW,[0x53]=ASCII_ROW,
  [0x54]=ASCII_ROW,[0x55]=ASCII_ROW,[0x56]=ASCII_ROW,[0x57]=ASCII_ROW,
  [0x58]=ASCII_ROW,[0x59]=ASCII_ROW,[0x5A]=ASCII_ROW,[0x5B]=ASCII_ROW,
  [0x5C]=ASCII_ROW,[0x5D]=ASCII_ROW,[0x5E]=ASCII_ROW,[0x5F]=ASCII_ROW,
  [0x60]=ASCII_ROW,[0x61]=ASCII_ROW,[0x62]=ASCII_ROW,[0x63]=ASCII_ROW,
  [0x64]=ASCII_ROW,[0x65]=ASCII_ROW,[0x66]=ASCII_ROW,[0x67]=ASCII_ROW,
  [0x68]=ASCII_ROW,[0x69]=ASCII_ROW,[0x6A]=ASCII_ROW,[0x6B]=ASCII_ROW,
  [0x6C]=ASCII_ROW,[0x6D]=ASCII_ROW,[0x6E]=ASCII_ROW,[0x6F]=ASCII_ROW,
  [0x70]=ASCII_ROW,[0x71]=ASCII_ROW,[0x72]=ASCII_ROW,[0x73]=ASCII_ROW,
  [0x74]=ASCII_ROW,[0x75]=ASCII_ROW,[0x76]=ASCII_ROW,[0x77]=ASCII_ROW,
  [0x78]=ASCII_ROW,[0x79]=ASCII_ROW,[0x7A]=ASCII_ROW,[0x7B]=ASCII_ROW,
  [0x7C]=ASCII_ROW,[0x7D]=ASCII_ROW,[0x7E]=ASCII_ROW,[0x7F]=ASCII_ROW,

  // 80-8F
  [0x80]=CONT_80_8F,[0x81]=CONT_80_8F,[0x82]=CONT_80_8F,[0x83]=CONT_80_8F,
  [0x84]=CONT_80_8F,[0x85]=CONT_80_8F,[0x86]=CONT_80_8F,[0x87]=CONT_80_8F,
  [0x88]=CONT_80_8F,[0x89]=CONT_80_8F,[0x8A]=CONT_80_8F,[0x8B]=CONT_80_8F,
  [0x8C]=CONT_80_8F,[0x8D]=CONT_80_8F,[0x8E]=CONT_80_8F,[0x8F]=CONT_80_8F,

  // 90-9F
  [0x90]=CONT_90_9F,[0x91]=CONT_90_9F,[0x92]=CONT_90_9F,[0x93]=CONT_90_9F,
  [0x94]=CONT_90_9F,[0x95]=CONT_90_9F,[0x96]=CONT_90_9F,[0x97]=CONT_90_9F,
  [0x98]=CONT_90_9F,[0x99]=CONT_90_9F,[0x9A]=CONT_90_9F,[0x9B]=CONT_90_9F,
  [0x9C]=CONT_90_9F,[0x9D]=CONT_90_9F,[0x9E]=CONT_90_9F,[0x9F]=CONT_90_9F,

  // A0-BF
  [0xA0]=CONT_A0_BF,[0xA1]=CONT_A0_BF,[0xA2]=CONT_A0_BF,[0xA3]=CONT_A0_BF,
  [0xA4]=CONT_A0_BF,[0xA5]=CONT_A0_BF,[0xA6]=CONT_A0_BF,[0xA7]=CONT_A0_BF,
  [0xA8]=CONT_A0_BF,[0xA9]=CONT_A0_BF,[0xAA]=CONT_A0_BF,[0xAB]=CONT_A0_BF,
  [0xAC]=CONT_A0_BF,[0xAD]=CONT_A0_BF,[0xAE]=CONT_A0_BF,[0xAF]=CONT_A0_BF,
  [0xB0]=CONT_A0_BF,[0xB1]=CONT_A0_BF,[0xB2]=CONT_A0_BF,[0xB3]=CONT_A0_BF,
  [0xB4]=CONT_A0_BF,[0xB5]=CONT_A0_BF,[0xB6]=CONT_A0_BF,[0xB7]=CONT_A0_BF,
  [0xB8]=CONT_A0_BF,[0xB9]=CONT_A0_BF,[0xBA]=CONT_A0_BF,[0xBB]=CONT_A0_BF,
  [0xBC]=CONT_A0_BF,[0xBD]=CONT_A0_BF,[0xBE]=CONT_A0_BF,[0xBF]=CONT_A0_BF,

  // C0-C1: invalid
  [0xC0]=ERROR_ROW,[0xC1]=ERROR_ROW,

  // C2-DF: 2-byte lead
  [0xC2]=LEAD2_ROW,[0xC3]=LEAD2_ROW,[0xC4]=LEAD2_ROW,[0xC5]=LEAD2_ROW,
  [0xC6]=LEAD2_ROW,[0xC7]=LEAD2_ROW,[0xC8]=LEAD2_ROW,[0xC9]=LEAD2_ROW,
  [0xCA]=LEAD2_ROW,[0xCB]=LEAD2_ROW,[0xCC]=LEAD2_ROW,[0xCD]=LEAD2_ROW,
  [0xCE]=LEAD2_ROW,[0xCF]=LEAD2_ROW,[0xD0]=LEAD2_ROW,[0xD1]=LEAD2_ROW,
  [0xD2]=LEAD2_ROW,[0xD3]=LEAD2_ROW,[0xD4]=LEAD2_ROW,[0xD5]=LEAD2_ROW,
  [0xD6]=LEAD2_ROW,[0xD7]=LEAD2_ROW,[0xD8]=LEAD2_ROW,[0xD9]=LEAD2_ROW,
  [0xDA]=LEAD2_ROW,[0xDB]=LEAD2_ROW,[0xDC]=LEAD2_ROW,[0xDD]=LEAD2_ROW,
  [0xDE]=LEAD2_ROW,[0xDF]=LEAD2_ROW,

  // E0: first cont A0-BF
  [0xE0]=DFA_ROW(S_E0,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR),

  // E1-EC: 3-byte lead
  [0xE1]=LEAD3_ROW,[0xE2]=LEAD3_ROW,[0xE3]=LEAD3_ROW,[0xE4]=LEAD3_ROW,
  [0xE5]=LEAD3_ROW,[0xE6]=LEAD3_ROW,[0xE7]=LEAD3_ROW,[0xE8]=LEAD3_ROW,
  [0xE9]=LEAD3_ROW,[0xEA]=LEAD3_ROW,[0xEB]=LEAD3_ROW,[0xEC]=LEAD3_ROW,

  // ED: first cont 80-9F
  [0xED]=DFA_ROW(S_ED,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR),

  // EE-EF: 3-byte lead
  [0xEE]=LEAD3_ROW,[0xEF]=LEAD3_ROW,

  // F0: first cont 90-BF
  [0xF0]=DFA_ROW(S_F0,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR),

  // F1-F3: 4-byte lead
  [0xF1]=LEAD4_ROW,[0xF2]=LEAD4_ROW,[0xF3]=LEAD4_ROW,

  // F4: first cont 80-8F
  [0xF4]=DFA_ROW(S_F4,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR),

  // F5-FF: invalid
  [0xF5]=ERROR_ROW,[0xF6]=ERROR_ROW,[0xF7]=ERROR_ROW,[0xF8]=ERROR_ROW,
  [0xF9]=ERROR_ROW,[0xFA]=ERROR_ROW,[0xFB]=ERROR_ROW,[0xFC]=ERROR_ROW,
  [0xFD]=ERROR_ROW,[0xFE]=ERROR_ROW,[0xFF]=ERROR_ROW,
};

/* clang-format on */

#undef S_TAIL1
#undef S_TAIL2
#undef S_E0
#undef S_ED
#undef S_F0
#undef S_F1_F3
#undef S_F4

#undef ERR
#undef DFA_ROW
#undef ASCII_ROW
#undef CONT_80_8F
#undef CONT_90_9F
#undef CONT_A0_BF
#undef LEAD2_ROW
#undef LEAD3_ROW
#undef LEAD4_ROW
#undef ERROR_ROW

static inline uint32_t utf8_dfa_step(uint32_t state, unsigned char c) {
  return (utf8_dfa[c] >> state) & 31;
}

static inline uint32_t utf8_dfa_run(uint32_t state,
                                    const unsigned char* src,
                                    size_t len) {
  for (size_t i = 0; i < len; i++)
    state = utf8_dfa_step(state, src[i]);
  return state;
}

static inline size_t utf8_maximal_subpart(const char* src, size_t len) {
  const unsigned char* s = (const unsigned char*)src;
  uint32_t state = S_ACCEPT;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, s[i]);
    switch (state) {
      case S_ACCEPT:
        return i + 1;
      case S_ERROR:
        return i > 0 ? i : 1;
    }
  }
  return len;
}

static inline size_t utf8_maximal_prefix(const char* src, size_t len) {
  const unsigned char* s = (const unsigned char*)src;
  uint32_t state = S_ACCEPT;
  size_t prefix = 0;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, s[i]);
    if (state == S_ACCEPT)
      prefix = i + 1;
    else if (state == S_ERROR)
      break;
  }
  return prefix;
}

static inline bool utf8_check_ascii_block16(const unsigned char *s) {
#if defined(UTF8_VALID_HAS_SSE2)
  __m128i v = _mm_loadu_si128((const __m128i *)s);
  return _mm_movemask_epi8(v) == 0;
#elif defined(UTF8_VALID_HAS_NEON)
  uint8x16_t v = vld1q_u8(s);
  uint8x16_t high = vshrq_n_u8(v, 7);
  return vmaxvq_u8(high) == 0;
#else
  uint64_t v1, v2;
  memcpy(&v1, s, sizeof(v1));
  memcpy(&v2, s + sizeof(v1), sizeof(v2));
  v1 |= v2;
  return (v1 & UINT64_C(0x8080808080808080)) == 0;
#endif
}

static inline bool utf8_check(const char* src, size_t slen, size_t* cursor) {
  const unsigned char* s = (const unsigned char*)src;
  size_t len = slen;
  uint32_t state = S_ACCEPT;

  // Process 16-byte chunks; skip DFA when state is clean and chunk is ASCII
  while (len >= 16) {
    if (state != S_ACCEPT || !utf8_check_ascii_block16(s))
      state = utf8_dfa_run(state, s, 16);
    s += 16;
    len -= 16;
  }

  state = utf8_dfa_run(state, s, len);
  if (state == S_ACCEPT) {
    if (cursor)
      *cursor = slen;
    return true;
  }

  if (cursor)
    *cursor = utf8_maximal_prefix(src, slen);
  return false;
}

static inline bool utf8_valid(const char *src, size_t len) {
  return utf8_check(src, len, NULL);
}

static inline bool utf8_check_constant(const char* src,
                                       size_t slen,
                                       size_t* cursor) {
  const unsigned char* s = (const unsigned char*)src;
  size_t len = slen;
  uint32_t state = S_ACCEPT;

  // Process 16-byte chunks
  while (len >= 16) {
    state = utf8_dfa_run(state, s, 16);
    s += 16;
    len -= 16;
  }

  state = utf8_dfa_run(state, s, len);
  if (state == S_ACCEPT) {
    if (cursor)
      *cursor = slen;
    return true;
  }

  if (cursor)
    *cursor = utf8_maximal_prefix(src, slen);
  return false;
}

static inline bool utf8_valid_constant(const char* src, size_t len) {
  return utf8_check_constant(src, len, NULL);
}

/*
 * Streaming API
 *
 * utf8_stream_t holds the DFA state between calls. Initialize with
 * utf8_stream_init() before the first call to utf8_stream_check().
 *
 * utf8_stream_check() validates the next chunk of a UTF-8 stream and
 * returns the number of bytes forming complete, valid sequences. Any
 * remaining bytes at the end of the chunk (an incomplete sequence
 * crossing a chunk boundary) must be prepended to the next chunk by
 * the caller.
 *
 * If eof is true and the stream does not end on a sequence boundary,
 * the input is treated as ill-formed.
 *
 * On error, (size_t)-1 is returned and *cursor, if non-NULL, is set
 * to the byte offset of the start of the invalid or truncated sequence
 * within src. The stream state is automatically reset to S_ACCEPT so
 * the caller can resume from the next byte without reinitializing.
 */
typedef struct {
  uint32_t state;
} utf8_stream_t;

static inline void
utf8_stream_init(utf8_stream_t *s) {
  s->state = S_ACCEPT;
}

static inline size_t utf8_stream_check(utf8_stream_t* s,
                                       const char* src,
                                       size_t len,
                                       bool eof,
                                       size_t* cursor) {
  const unsigned char* p = (const unsigned char*)src;
  uint32_t state = s->state;
  size_t last_accept = 0;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, p[i]);
    if (state == S_ACCEPT)
      last_accept = i + 1;
    else if (state == S_ERROR) {
      s->state = S_ACCEPT;
      if (cursor)
        *cursor = last_accept;
      return (size_t)-1;
    }
  }

  s->state = state;

  if (state != S_ACCEPT) {
    if (eof) {
      s->state = S_ACCEPT;
      if (cursor)
        *cursor = last_accept;
      return (size_t)-1;
    }
    return last_accept;
  }

  return len;
}

#undef S_ACCEPT
#undef S_ERROR

#ifdef __cplusplus
}
#endif
#endif
