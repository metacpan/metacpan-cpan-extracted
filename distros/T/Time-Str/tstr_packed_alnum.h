#ifndef TSTR_PACKED_ALNUM_H
#define TSTR_PACKED_ALNUM_H

#include <stdint.h>
#include <stddef.h>

/*
 * Pack up to 10 alphanumeric characters into a uint64_t using 6 bits each.
 *
 * Case-insensitive: a-z => 1-26, 0-9 => 27-36, packed MSB-first.
 * Returns the number of characters consumed, or 0 if none or >10.
 */
static inline size_t tstr_packed_alnum_encode(const char* str,
                                              size_t len,
                                              uint64_t* packed) {
  const unsigned char* src = (const unsigned char*)str;
  uint64_t enc;
  size_t i;

  for (enc = 0, i = 0; i < len; i++) {
    unsigned char ch = src[i];
    unsigned char c;
    unsigned char lower = ch | 0x20;

    if (lower - 'a' <= (unsigned)('z' - 'a'))
      c = lower - 'a' + 1;
    else if (ch - '0' <= (unsigned)('9' - '0'))
      c = ch - '0' + 27;
    else
      break;

    enc = (enc << 6) | c;
  }

  if (i == 0 || i > 10)
    return 0;
  *packed = enc;
  return i;
}

/* clang-format off */
#define TSTR_PACKED_ALNUM_MAP_CHAR(c) \
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
    ((c) == '0') ? 27 : \
    ((c) == '1') ? 28 : \
    ((c) == '2') ? 29 : \
    ((c) == '3') ? 30 : \
    ((c) == '4') ? 31 : \
    ((c) == '5') ? 32 : \
    ((c) == '6') ? 33 : \
    ((c) == '7') ? 34 : \
    ((c) == '8') ? 35 : \
    ((c) == '9') ? 36 : \
    0 )

#define TSTR_PACKED_ALNUM1(c1) \
  ((uint64_t)(TSTR_PACKED_ALNUM_MAP_CHAR(c1) & 0x3F))
#define TSTR_PACKED_ALNUM2(c1, c2) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*1)) | TSTR_PACKED_ALNUM1(c2))
#define TSTR_PACKED_ALNUM3(c1, c2, c3) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*2)) | TSTR_PACKED_ALNUM2(c2, c3))
#define TSTR_PACKED_ALNUM4(c1, c2, c3, c4) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*3)) | TSTR_PACKED_ALNUM3(c2, c3, c4))
#define TSTR_PACKED_ALNUM5(c1, c2, c3, c4, c5) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*4)) | TSTR_PACKED_ALNUM4(c2, c3, c4, c5))
#define TSTR_PACKED_ALNUM6(c1, c2, c3, c4, c5, c6) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*5)) | TSTR_PACKED_ALNUM5(c2, c3, c4, c5, c6))
#define TSTR_PACKED_ALNUM7(c1, c2, c3, c4, c5, c6, c7) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*6)) | TSTR_PACKED_ALNUM6(c2, c3, c4, c5, c6, c7))
#define TSTR_PACKED_ALNUM8(c1, c2, c3, c4, c5, c6, c7, c8) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*7)) | TSTR_PACKED_ALNUM7(c2, c3, c4, c5, c6, c7, c8))
#define TSTR_PACKED_ALNUM9(c1, c2, c3, c4, c5, c6, c7, c8, c9) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*8)) | TSTR_PACKED_ALNUM8(c2, c3, c4, c5, c6, c7, c8, c9))
#define TSTR_PACKED_ALNUM10(c1, c2, c3, c4, c5, c6, c7, c8, c9, c10) \
  ((TSTR_PACKED_ALNUM1(c1) << (6*9)) | TSTR_PACKED_ALNUM9(c2, c3, c4, c5, c6, c7, c8, c9, c10))
/* clang-format on */

#endif /* TSTR_PACKED_ALNUM_H */
