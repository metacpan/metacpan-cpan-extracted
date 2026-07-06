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
#ifndef UTF8_ADVANCE_FORWARD_UNSAFE_H
#define UTF8_ADVANCE_FORWARD_UNSAFE_H
#include <stddef.h>
#include <stdint.h>

#include "utf8_swar.h"
#include "utf8_simd.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * utf8_advance_forward_unsafe -- advance forward by distance codepoints.
 *
 * src MUST point to well-formed UTF-8. No validation is performed.
 *
 * Returns the byte offset of the start of the codepoint distance positions
 * ahead in src[0..len), or len if distance exceeds the number of codepoints
 * in the buffer. If advanced is non-NULL, writes the number of codepoints
 * actually advanced before stopping.
 *
 * Uses SIMD (when available) or SWAR to process 32-byte blocks in bulk.
 * A 32-byte block contains at most 32 codepoints, so processing
 * (distance - count) / 32 blocks at a time can never overshoot.
 * Remaining 8-byte blocks use SWAR, then a scalar walk handles the
 * final bytes.
 */
static inline size_t utf8_advance_forward_unsafe(const char *src,
                                                 size_t len,
                                                 size_t distance,
                                                 size_t *advanced) {
  const uint8_t *bytes = (const uint8_t *)src;
  size_t pos = 0, count = 0;

  while (distance - count >= 32 && len - pos >= 32) {
    size_t remain = (distance - count) / 32;
    size_t avail  = (len - pos) / 32;
    size_t blocks = remain < avail ? remain : avail;
#ifdef UTF8_SIMD_AVAILABLE
    count += utf8_simd_count_codepoints_Nx32(src + pos, blocks);
#else
    count += utf8_swar_count_codepoints_Nx32(src + pos, blocks);
#endif
    pos += blocks * 32;
  }

  while (distance - count >= 8 && len - pos >= 8) {
    count += utf8_swar_count_codepoints_1x8(bytes + pos);
    pos += 8;
  }

  while (pos < len && count < distance) {
    count += ((int8_t)bytes[pos] > -65);
    pos++;
  }

  while (pos < len && (int8_t)bytes[pos] <= -65)
    pos++;

  if (advanced)
    *advanced = count;
  return pos;
}

#ifdef __cplusplus
}
#endif
#endif /* UTF8_ADVANCE_FORWARD_UNSAFE_H */
