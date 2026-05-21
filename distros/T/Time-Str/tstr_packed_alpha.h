#ifndef TSTR_PACKED_ALPHA_H
#define TSTR_PACKED_ALPHA_H

#include <stdint.h>
#include <stddef.h>

/*
 * Pack up to 12 ASCII letters into a uint64_t using 5 bits per character.
 *
 * Case-insensitive: a-z => 1-26, packed MSB-first.
 * Returns the number of characters consumed, or 0 if none or >12.
 */
static inline size_t tstr_packed_alpha_encode(const char* str,
                                              size_t len,
                                              uint64_t* packed) {
  const unsigned char* src = (const unsigned char*)str;
  uint64_t enc;
  size_t i;

  for (enc = 0, i = 0; i < len; i++) {
    unsigned char lower = src[i] | 0x20;
    unsigned char c;

    if (lower - 'a' <= (unsigned)('z' - 'a'))
      c = lower - 'a' + 1;
    else
      break;

    enc = (enc << 5) | c;
  }

  if (i == 0 || i > 12)
    return 0;
  *packed = enc;
  return i;
}

/* clang-format off */
#define TSTR_PACKED_ALPHA_MAP_CHAR(c) \
  ( ((c) == 'A' || (c) == 'a') ?  1 : \
    ((c) == 'B' || (c) == 'b') ?  2 : \
    ((c) == 'C' || (c) == 'c') ?  3 : \
    ((c) == 'D' || (c) == 'd') ?  4 : \
    ((c) == 'E' || (c) == 'e') ?  5 : \
    ((c) == 'F' || (c) == 'f') ?  6 : \
    ((c) == 'G' || (c) == 'g') ?  7 : \
    ((c) == 'H' || (c) == 'h') ?  8 : \
    ((c) == 'I' || (c) == 'i') ?  9 : \
    ((c) == 'J' || (c) == 'j') ? 10 : \
    ((c) == 'K' || (c) == 'k') ? 11 : \
    ((c) == 'L' || (c) == 'l') ? 12 : \
    ((c) == 'M' || (c) == 'm') ? 13 : \
    ((c) == 'N' || (c) == 'n') ? 14 : \
    ((c) == 'O' || (c) == 'o') ? 15 : \
    ((c) == 'P' || (c) == 'p') ? 16 : \
    ((c) == 'Q' || (c) == 'q') ? 17 : \
    ((c) == 'R' || (c) == 'r') ? 18 : \
    ((c) == 'S' || (c) == 's') ? 19 : \
    ((c) == 'T' || (c) == 't') ? 20 : \
    ((c) == 'U' || (c) == 'u') ? 21 : \
    ((c) == 'V' || (c) == 'v') ? 22 : \
    ((c) == 'W' || (c) == 'w') ? 23 : \
    ((c) == 'X' || (c) == 'x') ? 24 : \
    ((c) == 'Y' || (c) == 'y') ? 25 : \
    ((c) == 'Z' || (c) == 'z') ? 26 : \
    0 )

#define TSTR_PACKED_ALPHA1(c1) \
  ((uint64_t)(TSTR_PACKED_ALPHA_MAP_CHAR(c1) & 0x1F))
#define TSTR_PACKED_ALPHA2(c1, c2) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*1)) | TSTR_PACKED_ALPHA1(c2))
#define TSTR_PACKED_ALPHA3(c1, c2, c3) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*2)) | TSTR_PACKED_ALPHA2(c2, c3))
#define TSTR_PACKED_ALPHA4(c1, c2, c3, c4) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*3)) | TSTR_PACKED_ALPHA3(c2, c3, c4))
#define TSTR_PACKED_ALPHA5(c1, c2, c3, c4, c5) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*4)) | TSTR_PACKED_ALPHA4(c2, c3, c4, c5))
#define TSTR_PACKED_ALPHA6(c1, c2, c3, c4, c5, c6) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*5)) | TSTR_PACKED_ALPHA5(c2, c3, c4, c5, c6))
#define TSTR_PACKED_ALPHA7(c1, c2, c3, c4, c5, c6, c7) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*6)) | TSTR_PACKED_ALPHA6(c2, c3, c4, c5, c6, c7))
#define TSTR_PACKED_ALPHA8(c1, c2, c3, c4, c5, c6, c7, c8) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*7)) | TSTR_PACKED_ALPHA7(c2, c3, c4, c5, c6, c7, c8))
#define TSTR_PACKED_ALPHA9(c1, c2, c3, c4, c5, c6, c7, c8, c9) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*8)) | TSTR_PACKED_ALPHA8(c2, c3, c4, c5, c6, c7, c8, c9))
#define TSTR_PACKED_ALPHA10(c1, c2, c3, c4, c5, c6, c7, c8, c9, c10) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*9)) | TSTR_PACKED_ALPHA9(c2, c3, c4, c5, c6, c7, c8, c9, c10))
#define TSTR_PACKED_ALPHA11(c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*10)) | TSTR_PACKED_ALPHA10(c2, c3, c4, c5, c6, c7, c8, c9, c10, c11))
#define TSTR_PACKED_ALPHA12(c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12) \
  ((TSTR_PACKED_ALPHA1(c1) << (5*11)) | TSTR_PACKED_ALPHA11(c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12))
/* clang-format on */

#endif /* TSTR_PACKED_ALPHA_H */
