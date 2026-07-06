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

/*
 * utf8_swar.h -- SWAR primitives for UTF-8
 * =============================================================================
 *
 * Counts UTF-8 codepoint boundaries in 8-byte words without SIMD instruction 
 * set extension. Assumes well-formed UTF-8 input.
 *
 *
 * BACKGROUND
 * ----------
 *
 * A UTF-8 byte falls into one of three classes:
 *
 *   ASCII           0xxxxxxx  (0x00-0x7F)  -- starts a 1-byte sequence
 *   Lead            11xxxxxx  (0xC0-0xFF)  -- starts a 2/3/4-byte sequence
 *   Continuation    10xxxxxx  (0x80-0xBF)  -- interior byte, not a boundary
 *
 * Counting codepoints is equivalent to counting non-continuation bytes,
 * since every codepoint begins at exactly one ASCII or lead byte.
 *
 *
 * BYTE CLASS DETECTION
 * --------------------
 *
 * Each mark function operates on an 8-byte word loaded with memcpy and
 * returns a word with bit 0 of each byte set iff the corresponding byte
 * belongs to the class. Each byte of the result is therefore 0 or 1.
 *
 * ASCII (bit 7 clear):
 *   (~w & 0x8080...) >> 7
 *
 * Continuation (10xxxxxx):
 *   (w & ~(w << 1)) & 0x8080...
 *   Bit 7 of each result byte is w[7] & ~w[6]. The shift crosses byte
 *   boundaries, but the mask isolates bit 7, so each byte's result
 *   depends only on its own bits 7 and 6.
 *
 * Non-continuation (ASCII or lead):
 *   (~w | (w << 1)) & 0x8080...
 *   Bit 7 of each result byte is ~w[7] | w[6] — true for ASCII
 *   (bit 7 clear) and lead bytes (bit 6 set). Same masking as above.
 *
 *
 * HORIZONTAL SUMS
 * ----------------
 *
 * Two reduction functions fold 8 byte lanes into a scalar count:
 *
 *   utf8_swar_hsum_bits8(x)   -- each byte is 0 or 1 (mark word).
 *   utf8_swar_hsum_bytes8(x)  -- each byte is 0..255 (accumulated marks).
 *
 * hsum_bits8 uses hardware popcount when available (UTF8_SWAR_POPCNT),
 * otherwise a multiply-fold sum. With popcount, independent calls on
 * separate words can execute in parallel.
 *
 * hsum_bytes8 widens adjacent bytes into 16-bit lanes, then folds with
 * a multiply. Used after accumulating mark words without per-word
 * reduction.
 *
 *
 * HARDWARE POPCOUNT DETECTION
 * ---------------------------
 *
 * UTF8_SWAR_POPCNT is defined when a hardware popcount instruction is
 * available:
 *
 *   x86/x86-64  __POPCNT__   (-mpopcnt or -march=* implying it)
 *   AArch64     __aarch64__  (cnt always available)
 *   PowerPC     __POPCNTD__  (popcntd, POWER5+ and later)
 *   RISC-V      __riscv_zbb  (Zbb bit-manipulation extension)
 *   MSVC        __AVX__      (/arch:AVX or higher)
 *
 * __has_builtin(__builtin_popcountll) is intentionally NOT used: GCC
 * recognises the builtin on all targets but may emit a libgcc soft
 * call (__popcountdi2) when no hardware instruction is available.
 *
 */
#ifndef UTF8_SWAR_H
#define UTF8_SWAR_H
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__POPCNT__)    || \
    defined(__aarch64__)   || \
    defined(__POPCNTD__)   || \
    defined(__riscv_zbb)   || \
    (defined(_MSC_VER) && defined(__AVX__))
#  define UTF8_SWAR_POPCNT 1
#endif

#if defined(_MSC_VER) && defined(UTF8_SWAR_POPCNT)
#  include <intrin.h>
#endif

/*
 * utf8_swar_hsum_bits8 -- sum the 8 byte lanes of a mark word.
 * Each byte of x must be 0 or 1. Returns the total count of 1-bytes.
 */
#if defined(_MSC_VER) && defined(UTF8_SWAR_POPCNT)
static inline size_t utf8_swar_hsum_bits8(uint64_t x) {
  return (size_t)__popcnt64(x);
}
#elif defined(UTF8_SWAR_POPCNT)
static inline size_t utf8_swar_hsum_bits8(uint64_t x) {
  return (size_t)__builtin_popcountll(x);
}
#else
static inline size_t utf8_swar_hsum_bits8(uint64_t x) {
  return (size_t)((x * UINT64_C(0x0101010101010101)) >> 56);
}
#endif

/*
 * utf8_swar_hsum_bytes8 -- sum the 8 byte lanes of an accumulated word.
 * Each byte of x is in 0..255. Returns the total in [0, 2040].
 */
static inline size_t utf8_swar_hsum_bytes8(uint64_t x) {
  uint64_t pair_sum = (x & UINT64_C(0x00FF00FF00FF00FF))
                    + ((x >> 8) & UINT64_C(0x00FF00FF00FF00FF));
  return (size_t)((pair_sum * UINT64_C(0x0001000100010001)) >> 48);
}

/*
 * has_ predicates -- high-bit mask per lane (0x80 = match, 0x00 = no match).
 * mark_ functions -- normalized to bit 0 per lane (0x01 = match, 0x00 = no match).
 */

// utf8_swar_has_zero8 -- test for zero bytes.
static inline uint64_t utf8_swar_has_zero8(uint64_t w) {
  return (w - UINT64_C(0x0101010101010101)) & ~w & UINT64_C(0x8080808080808080);
}

// utf8_swar_has_byte8 -- test for bytes equal to byte.
static inline uint64_t utf8_swar_has_byte8(uint64_t w, uint8_t byte) {
  return utf8_swar_has_zero8(w ^ (UINT64_C(0x0101010101010101) * byte));
}

// utf8_swar_has_newline8 -- test for '\n' bytes (0x0A).
static inline uint64_t utf8_swar_has_newline8(uint64_t w) {
  return utf8_swar_has_zero8(w ^ UINT64_C(0x0A0A0A0A0A0A0A0A));
}

// utf8_swar_has_ascii8 -- test for ASCII bytes (0x00-0x7F).
static inline uint64_t utf8_swar_has_ascii8(uint64_t w) {
  return ~w & UINT64_C(0x8080808080808080);
}

// utf8_swar_has_continuations8 -- test for continuation bytes (0x80-0xBF).
static inline uint64_t utf8_swar_has_continuations8(uint64_t w) {
  return (w & ~(w << 1)) & UINT64_C(0x8080808080808080);
}

// utf8_swar_has_non_continuations8 -- test for non-continuation bytes (ASCII or lead).
static inline uint64_t utf8_swar_has_non_continuations8(uint64_t w) {
  return (~w | (w << 1)) & UINT64_C(0x8080808080808080);
}

// utf8_swar_mark_zero8 -- mark zero bytes (0x01 per lane).
static inline uint64_t utf8_swar_mark_zero8(uint64_t w) {
  return utf8_swar_has_zero8(w) >> 7;
}

// utf8_swar_mark_byte8 -- mark bytes equal to byte (0x01 per lane).
static inline uint64_t utf8_swar_mark_byte8(uint64_t w, uint8_t byte) {
  return utf8_swar_has_byte8(w, byte) >> 7;
}

// utf8_swar_mark_newline8 -- mark '\n' bytes (0x01 per lane).
static inline uint64_t utf8_swar_mark_newline8(uint64_t w) {
  return utf8_swar_has_newline8(w) >> 7;
}

// utf8_swar_mark_ascii8 -- mark ASCII bytes (0x01 per lane).
static inline uint64_t utf8_swar_mark_ascii8(uint64_t w) {
  return utf8_swar_has_ascii8(w) >> 7;
}

// utf8_swar_mark_continuations8 -- mark continuation bytes (0x01 per lane).
static inline uint64_t utf8_swar_mark_continuations8(uint64_t w) {
  return utf8_swar_has_continuations8(w) >> 7;
}

// utf8_swar_mark_non_continuations8 -- mark non-continuation bytes (0x01 per lane).
static inline uint64_t utf8_swar_mark_non_continuations8(uint64_t w) {
  return utf8_swar_has_non_continuations8(w) >> 7;
}

// utf8_swar_count_codepoints_1x8 -- count codepoints in one 8-byte block.
static inline size_t utf8_swar_count_codepoints_1x8(const void *src) {
  uint64_t w;
  memcpy(&w, src, sizeof w);
  return utf8_swar_hsum_bits8(utf8_swar_mark_non_continuations8(w));
}

/*
 * utf8_swar_count_codepoints_Nx32 -- count codepoints in n 32-byte blocks.
 * Each block is processed as four 8-byte words. Without hardware popcnt,
 * mark words are accumulated and folded every 63 blocks (63*4 = 252 < 255).
 */
static inline size_t utf8_swar_count_codepoints_Nx32(const void *src, size_t n) {
  const uint8_t *bytes = (const uint8_t *)src;
  size_t count = 0;

#if defined(UTF8_SWAR_POPCNT)
  for (size_t i = 0; i < n; i++, bytes += 32) {
    uint64_t w0, w1, w2, w3;
    memcpy(&w0, bytes +  0, 8);
    memcpy(&w1, bytes +  8, 8);
    memcpy(&w2, bytes + 16, 8);
    memcpy(&w3, bytes + 24, 8);
    count += utf8_swar_hsum_bits8(utf8_swar_mark_non_continuations8(w0))
           + utf8_swar_hsum_bits8(utf8_swar_mark_non_continuations8(w1))
           + utf8_swar_hsum_bits8(utf8_swar_mark_non_continuations8(w2))
           + utf8_swar_hsum_bits8(utf8_swar_mark_non_continuations8(w3));
  }
#else
  while (n > 0) {
    size_t batch = n < 63 ? n : 63;
    n -= batch;
    uint64_t acc = 0;
    for (size_t i = 0; i < batch; i++, bytes += 32) {
      uint64_t w0, w1, w2, w3;
      memcpy(&w0, bytes +  0, 8);
      memcpy(&w1, bytes +  8, 8);
      memcpy(&w2, bytes + 16, 8);
      memcpy(&w3, bytes + 24, 8);
      acc += utf8_swar_mark_non_continuations8(w0)
           + utf8_swar_mark_non_continuations8(w1)
           + utf8_swar_mark_non_continuations8(w2)
           + utf8_swar_mark_non_continuations8(w3);
    }
    count += utf8_swar_hsum_bytes8(acc);
  }
#endif
  return count;
}

#ifdef __cplusplus
}
#endif
#endif /* UTF8_SWAR_H */
