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
 * utf8_simd.h -- SIMD primitives for UTF-8
 * =========================================
 *
 * Provides utf8_simd_count_codepoints_Nx32 when a supported SIMD
 * instruction set is available at compile time. The header may be
 * included unconditionally; callers check UTF8_SIMD_AVAILABLE before
 * calling any function.
 *
 * Counts non-continuation bytes (signed > -65) in SIMD lanes.
 * Comparison results (0xFF / 0x00) accumulate in a byte-wide vector;
 * a periodic flush widens to 64-bit before overflow.
 *
 * Batch limits per flush:
 *   AVX2 — 255 blocks (one 32-byte load, max 1 per byte per block)
 *   SSE2 — 127 blocks (two 16-byte loads added, max 2 per byte per block)
 *   NEON — 127 blocks (same)
 */
#ifndef UTF8_SIMD_H
#define UTF8_SIMD_H
#include <stddef.h>
#include <stdint.h>

#if defined(__AVX2__)
#  define UTF8_SIMD_HAS_AVX2 1
#  include <immintrin.h>
#elif defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && (_M_IX86_FP >= 2))
#  define UTF8_SIMD_HAS_SSE2 1
#  include <emmintrin.h>
#elif defined(__aarch64__)
#  define UTF8_SIMD_HAS_NEON 1
#  include <arm_neon.h>
#endif

#if defined(UTF8_SIMD_HAS_AVX2) || defined(UTF8_SIMD_HAS_SSE2) || defined(UTF8_SIMD_HAS_NEON)
#  define UTF8_SIMD_AVAILABLE 1
#endif

#ifdef UTF8_SIMD_AVAILABLE

#ifdef __cplusplus
extern "C" {
#endif

/*
 * utf8_simd_count_codepoints_Nx32 -- count codepoints in n 32-byte blocks.
 *
 * src MUST point to well-formed UTF-8. No validation is performed.
 * Returns the number of codepoints in src[0..n*32).
 */
static inline size_t utf8_simd_count_codepoints_Nx32(const void *src, size_t n) {
  const uint8_t *bytes = (const uint8_t *)src;

#if defined(UTF8_SIMD_HAS_AVX2)
  const __m256i threshold  = _mm256_set1_epi8(-65);
  const __m256i zero = _mm256_setzero_si256();
  __m256i acc64 = zero;

  while (n > 0) {
    size_t batch = n < 255 ? n : 255;
    n -= batch;
    __m256i acc8 = zero;
    for (; batch >= 4; batch -= 4) {
      __m256i v0 = _mm256_loadu_si256((const __m256i *)bytes);
      __m256i v1 = _mm256_loadu_si256((const __m256i *)(bytes + 32));
      __m256i v2 = _mm256_loadu_si256((const __m256i *)(bytes + 64));
      __m256i v3 = _mm256_loadu_si256((const __m256i *)(bytes + 96));
      acc8 = _mm256_sub_epi8(acc8, _mm256_cmpgt_epi8(v0, threshold));
      acc8 = _mm256_sub_epi8(acc8, _mm256_cmpgt_epi8(v1, threshold));
      acc8 = _mm256_sub_epi8(acc8, _mm256_cmpgt_epi8(v2, threshold));
      acc8 = _mm256_sub_epi8(acc8, _mm256_cmpgt_epi8(v3, threshold));
      bytes += 128;
    }
    for (; batch > 0; batch--) {
      __m256i v = _mm256_loadu_si256((const __m256i *)bytes);
      acc8 = _mm256_sub_epi8(acc8, _mm256_cmpgt_epi8(v, threshold));
      bytes += 32;
    }
    acc64 = _mm256_add_epi64(acc64, _mm256_sad_epu8(acc8, zero));
  }

  __m128i lo  = _mm256_castsi256_si128(acc64);
  __m128i hi  = _mm256_extracti128_si256(acc64, 1);
  __m128i sum = _mm_add_epi64(lo, hi);
  sum = _mm_add_epi64(sum, _mm_srli_si128(sum, 8));
  return (size_t)_mm_cvtsi128_si64(sum);

#elif defined(UTF8_SIMD_HAS_SSE2)
  const __m128i threshold  = _mm_set1_epi8(-65);
  const __m128i zero = _mm_setzero_si128();
  __m128i acc64 = zero;

  while (n > 0) {
    size_t batch = n < 127 ? n : 127;
    n -= batch;
    __m128i acc8 = zero;
    for (; batch >= 2; batch -= 2) {
      __m128i a0 = _mm_loadu_si128((const __m128i *)bytes);
      __m128i a1 = _mm_loadu_si128((const __m128i *)(bytes + 16));
      __m128i b0 = _mm_loadu_si128((const __m128i *)(bytes + 32));
      __m128i b1 = _mm_loadu_si128((const __m128i *)(bytes + 48));
      __m128i ca = _mm_add_epi8(_mm_cmpgt_epi8(a0, threshold),
                                _mm_cmpgt_epi8(a1, threshold));
      __m128i cb = _mm_add_epi8(_mm_cmpgt_epi8(b0, threshold),
                                _mm_cmpgt_epi8(b1, threshold));
      acc8 = _mm_sub_epi8(acc8, ca);
      acc8 = _mm_sub_epi8(acc8, cb);
      bytes += 64;
    }
    for (; batch > 0; batch--) {
      __m128i v0 = _mm_loadu_si128((const __m128i *)bytes);
      __m128i v1 = _mm_loadu_si128((const __m128i *)(bytes + 16));
      __m128i c  = _mm_add_epi8(_mm_cmpgt_epi8(v0, threshold),
                                _mm_cmpgt_epi8(v1, threshold));
      acc8 = _mm_sub_epi8(acc8, c);
      bytes += 32;
    }
    acc64 = _mm_add_epi64(acc64, _mm_sad_epu8(acc8, zero));
  }

  acc64 = _mm_add_epi64(acc64, _mm_srli_si128(acc64, 8));
  return (size_t)_mm_cvtsi128_si64(acc64);

#elif defined(UTF8_SIMD_HAS_NEON)
  const int8x16_t threshold = vdupq_n_s8(-65);
  uint64_t count = 0;

  while (n > 0) {
    size_t batch = n < 127 ? n : 127;
    n -= batch;
    uint8x16_t acc8 = vdupq_n_u8(0);
    for (; batch >= 4; batch -= 4) {
      int8x16_t a0 = vld1q_s8((const int8_t *)bytes);
      int8x16_t a1 = vld1q_s8((const int8_t *)(bytes + 16));
      int8x16_t b0 = vld1q_s8((const int8_t *)(bytes + 32));
      int8x16_t b1 = vld1q_s8((const int8_t *)(bytes + 48));
      int8x16_t c0 = vld1q_s8((const int8_t *)(bytes + 64));
      int8x16_t c1 = vld1q_s8((const int8_t *)(bytes + 80));
      int8x16_t d0 = vld1q_s8((const int8_t *)(bytes + 96));
      int8x16_t d1 = vld1q_s8((const int8_t *)(bytes + 112));
      acc8 = vsubq_u8(acc8, vcgtq_s8(a0, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(a1, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(b0, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(b1, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(c0, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(c1, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(d0, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(d1, threshold));
      bytes += 128;
    }
    for (; batch > 0; batch--) {
      int8x16_t v0 = vld1q_s8((const int8_t *)bytes);
      int8x16_t v1 = vld1q_s8((const int8_t *)(bytes + 16));
      acc8 = vsubq_u8(acc8, vcgtq_s8(v0, threshold));
      acc8 = vsubq_u8(acc8, vcgtq_s8(v1, threshold));
      bytes += 32;
    }
    count += vaddlvq_u8(acc8);
  }

  return (size_t)count;
#endif
}

#ifdef __cplusplus
}
#endif
#endif /* UTF8_SIMD_AVAILABLE */
#endif /* UTF8_SIMD_H */
