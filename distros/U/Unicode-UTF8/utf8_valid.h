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

#if defined(UTF8_DFA32_H) && defined(UTF8_DFA64_H)
#  error "utf8_dfa32.h and utf8_dfa64.h are mutually exclusive"
#elif !defined(UTF8_DFA32_H) && !defined(UTF8_DFA64_H)
#  error "include utf8_dfa32.h or utf8_dfa64.h before utf8_valid.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

static inline size_t utf8_maximal_subpart(const char* src, size_t len) {
  const uint8_t* bytes = (const uint8_t*)src;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, bytes[i]);
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
  const uint8_t* bytes = (const uint8_t*)src;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;
  size_t prefix = 0;

  for (size_t i = 0; i < len; i++) {
    state = utf8_dfa_step(state, bytes[i]);
    if (state == UTF8_DFA_ACCEPT)
      prefix = i + 1;
    else if (state == UTF8_DFA_REJECT)
      break;
  }
  return prefix;
}

static inline bool utf8_check(const char* src,
                              size_t len,
                              size_t* cursor) {
  const uint8_t* bytes = (const uint8_t*)src;
  utf8_dfa_state_t state = UTF8_DFA_ACCEPT;

  state = utf8_dfa_run_dual(state, bytes, len);
  if (state == UTF8_DFA_ACCEPT) {
    if (cursor)
      *cursor = len;
    return true;
  }

  if (cursor)
    *cursor = utf8_maximal_prefix(src, len);
  return false;
}

static inline bool utf8_valid(const char* src, size_t len) {
  return utf8_check(src, len, NULL);
}

static inline bool utf8_check_ascii(const char* src, size_t len, size_t* cursor) {
  utf8_dfa_state_t state;

  state = utf8_dfa_run_ascii(UTF8_DFA_ACCEPT, (const uint8_t *)src, len);
  if (state == UTF8_DFA_ACCEPT) {
    if (cursor)
      *cursor = len;
    return true;
  }

  if (cursor)
    *cursor = utf8_maximal_prefix(src, len);
  return false;
}

static inline bool utf8_valid_ascii(const char *src, size_t len) {
  return utf8_check_ascii(src, len, NULL);
}

#ifdef __cplusplus
}
#endif
#endif
