/*
 * Copyright (c) 2017-2026 Christian Hansen <chansen@cpan.org>
 * <https://github.com/chansen/c-utf8>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#ifndef UTF8_VALID_H
#define UTF8_VALID_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#if defined(UTF8_DFA32_H) && defined(UTF8_DFA64_H)
#  error "utf8_dfa32.h and utf8_dfa64.h are mutually exclusive"
#elif !defined(UTF8_DFA32_H) && !defined(UTF8_DFA64_H)
#  error "include utf8_dfa32.h or utf8_dfa64.h before utf8_valid.h"
#endif

#ifdef UTF8_VALID_USE_SIMD
#  if defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && (_M_IX86_FP >= 2))
#    define UTF8_VALID_HAS_SSE2 1
#    include <emmintrin.h>
#  elif defined(__aarch64__)
#    define UTF8_VALID_HAS_NEON 1
#    include <arm_neon.h>
#  endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

static inline size_t utf8_maximal_subpart(const char* src, size_t len) {
  const unsigned char* s = (const unsigned char*)src;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, s[i]);
    switch (state) {
      case UTF8_DFA_ACCEPT:
        return i + 1;
      case UTF8_DFA_REJECT:
        return i > 0 ? i : 1;
    }
  }
  return len;
}

static inline size_t utf8_maximal_prefix(const char* src, size_t len) {
  const unsigned char* s = (const unsigned char*)src;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;
  size_t prefix = 0;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, s[i]);
    if (state == UTF8_DFA_ACCEPT)
      prefix = i + 1;
    else if (state == UTF8_DFA_REJECT)
      break;
  }
  return prefix;
}

static inline bool utf8_check(const char* src,
                              size_t slen,
                              size_t* cursor) {
  const unsigned char* s = (const unsigned char*)src;
  size_t len = slen;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;

  // Process 16-byte chunks
  while (len >= 16) {
    state = utf8_dfa_run16(state, s);
    s += 16;
    len -= 16;
  }

  state = utf8_dfa_run(state, s, len);
  if (state == UTF8_DFA_ACCEPT) {
    if (cursor)
      *cursor = slen;
    return true;
  }

  if (cursor)
    *cursor = utf8_maximal_prefix(src, slen);
  return false;
}

static inline bool utf8_valid(const char* src, size_t len) {
  return utf8_check(src, len, NULL);
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

static inline bool utf8_check_ascii(const char* src, size_t slen, size_t* cursor) {
  const unsigned char* s = (const unsigned char*)src;
  size_t len = slen;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;

  // Process 16-byte chunks; skip DFA when state is clean and chunk is ASCII
  while (len >= 16) {
    if (state != UTF8_DFA_ACCEPT || !utf8_check_ascii_block16(s))
      state = utf8_dfa_run16(state, s);
    s += 16;
    len -= 16;
  }

  state = utf8_dfa_run(state, s, len);
  if (state == UTF8_DFA_ACCEPT) {
    if (cursor)
      *cursor = slen;
    return true;
  }

  if (cursor)
    *cursor = utf8_maximal_prefix(src, slen);
  return false;
}

static inline bool utf8_valid_ascii(const char *src, size_t len) {
  return utf8_check_ascii(src, len, NULL);
}

#ifdef __cplusplus
}
#endif
#endif
