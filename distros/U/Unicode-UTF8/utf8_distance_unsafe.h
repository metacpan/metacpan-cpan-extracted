/*
 * Copyright (c) 2026 Christian Hansen <chansen@cpan.org>
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
#ifndef UTF8_DISTANCE_UNSAFE_H
#define UTF8_DISTANCE_UNSAFE_H
#include <stddef.h>
#include <stdint.h>

#include "utf8_swar.h"
#include "utf8_simd.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * utf8_distance_unsafe -- count the number of codepoints in src[0..len).
 *
 * src MUST point to well-formed UTF-8. No validation is performed.
 *
 * Uses SIMD (when available) or SWAR to process 32-byte blocks in bulk,
 * then SWAR 8-byte blocks, then a scalar tail for the remaining 0-7 bytes.
 */
static inline size_t utf8_distance_unsafe(const char *src, size_t len) {
  const uint8_t *bytes = (const uint8_t *)src;
  size_t pos = 0, count = 0;

  size_t n32 = len / 32;
  if (n32) {
#ifdef UTF8_SIMD_AVAILABLE
    count += utf8_simd_count_codepoints_Nx32(bytes, n32);
#else
    count += utf8_swar_count_codepoints_Nx32(bytes, n32);
#endif
    pos += n32 * 32;
  }

  while (pos + 8 <= len) {
    count += utf8_swar_count_codepoints_1x8(bytes + pos);
    pos += 8;
  }

  for (; pos < len; pos++)
    count += ((int8_t)bytes[pos] > -65);

  return count;
}

#ifdef __cplusplus
}
#endif
#endif /* UTF8_DISTANCE_UNSAFE_H */
