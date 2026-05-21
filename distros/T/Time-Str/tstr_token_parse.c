#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <limits.h>

#include "tstr_packed_alpha.h"
#include "tstr_packed_alnum.h"

const int kNotFound = INT_MAX;

static inline int lookup_day_from_packed_alnum(uint64_t packed) {
  switch (packed) {
    case TSTR_PACKED_ALNUM1('1'):
    case TSTR_PACKED_ALNUM2('0','1'):
    case TSTR_PACKED_ALNUM3('1','s','t'):
      return 1;
    case TSTR_PACKED_ALNUM1('2'):
    case TSTR_PACKED_ALNUM2('0','2'):
    case TSTR_PACKED_ALNUM3('2','n','d'):
      return 2;
    case TSTR_PACKED_ALNUM1('3'):
    case TSTR_PACKED_ALNUM2('0','3'):
    case TSTR_PACKED_ALNUM3('3','r','d'):
      return 3;
    case TSTR_PACKED_ALNUM1('4'):
    case TSTR_PACKED_ALNUM2('0','4'):
    case TSTR_PACKED_ALNUM3('4','t','h'):
      return 4;
    case TSTR_PACKED_ALNUM1('5'):
    case TSTR_PACKED_ALNUM2('0','5'):
    case TSTR_PACKED_ALNUM3('5','t','h'):
      return 5;
    case TSTR_PACKED_ALNUM1('6'):
    case TSTR_PACKED_ALNUM2('0','6'):
    case TSTR_PACKED_ALNUM3('6','t','h'):
      return 6;
    case TSTR_PACKED_ALNUM1('7'):
    case TSTR_PACKED_ALNUM2('0','7'):
    case TSTR_PACKED_ALNUM3('7','t','h'):
      return 7;
    case TSTR_PACKED_ALNUM1('8'):
    case TSTR_PACKED_ALNUM2('0','8'):
    case TSTR_PACKED_ALNUM3('8','t','h'):
      return 8;
    case TSTR_PACKED_ALNUM1('9'):
    case TSTR_PACKED_ALNUM2('0','9'):
    case TSTR_PACKED_ALNUM3('9','t','h'):
      return 9;
    case TSTR_PACKED_ALNUM2('1','0'):
    case TSTR_PACKED_ALNUM4('1','0','t','h'):
      return 10;
    case TSTR_PACKED_ALNUM2('1','1'):
    case TSTR_PACKED_ALNUM4('1','1','t','h'):
      return 11;
    case TSTR_PACKED_ALNUM2('1','2'):
    case TSTR_PACKED_ALNUM4('1','2','t','h'):
      return 12;
    case TSTR_PACKED_ALNUM2('1','3'):
    case TSTR_PACKED_ALNUM4('1','3','t','h'):
      return 13;
    case TSTR_PACKED_ALNUM2('1','4'):
    case TSTR_PACKED_ALNUM4('1','4','t','h'):
      return 14;
    case TSTR_PACKED_ALNUM2('1','5'):
    case TSTR_PACKED_ALNUM4('1','5','t','h'):
      return 15;
    case TSTR_PACKED_ALNUM2('1','6'):
    case TSTR_PACKED_ALNUM4('1','6','t','h'):
      return 16;
    case TSTR_PACKED_ALNUM2('1','7'):
    case TSTR_PACKED_ALNUM4('1','7','t','h'):
      return 17;
    case TSTR_PACKED_ALNUM2('1','8'):
    case TSTR_PACKED_ALNUM4('1','8','t','h'):
      return 18;
    case TSTR_PACKED_ALNUM2('1','9'):
    case TSTR_PACKED_ALNUM4('1','9','t','h'):
      return 19;
    case TSTR_PACKED_ALNUM2('2','0'):
    case TSTR_PACKED_ALNUM4('2','0','t','h'):
      return 20;
    case TSTR_PACKED_ALNUM2('2','1'):
    case TSTR_PACKED_ALNUM4('2','1','s','t'):
      return 21;
    case TSTR_PACKED_ALNUM2('2','2'):
    case TSTR_PACKED_ALNUM4('2','2','n','d'):
      return 22;
    case TSTR_PACKED_ALNUM2('2','3'):
    case TSTR_PACKED_ALNUM4('2','3','r','d'):
      return 23;
    case TSTR_PACKED_ALNUM2('2','4'):
    case TSTR_PACKED_ALNUM4('2','4','t','h'):
      return 24;
    case TSTR_PACKED_ALNUM2('2','5'):
    case TSTR_PACKED_ALNUM4('2','5','t','h'):
      return 25;
    case TSTR_PACKED_ALNUM2('2','6'):
    case TSTR_PACKED_ALNUM4('2','6','t','h'):
      return 26;
    case TSTR_PACKED_ALNUM2('2','7'):
    case TSTR_PACKED_ALNUM4('2','7','t','h'):
      return 27;
    case TSTR_PACKED_ALNUM2('2','8'):
    case TSTR_PACKED_ALNUM4('2','8','t','h'):
      return 28;
    case TSTR_PACKED_ALNUM2('2','9'):
    case TSTR_PACKED_ALNUM4('2','9','t','h'):
      return 29;
    case TSTR_PACKED_ALNUM2('3','0'):
    case TSTR_PACKED_ALNUM4('3','0','t','h'):
      return 30;
    case TSTR_PACKED_ALNUM2('3','1'):
    case TSTR_PACKED_ALNUM4('3','1','s','t'):
      return 31;
    default:
      return kNotFound;
  }
}

static inline int lookup_day_name_from_packed_alpha(uint64_t packed) {
  switch (packed) {
    case TSTR_PACKED_ALPHA3('M','o','n'):
    case TSTR_PACKED_ALPHA6('M','o','n','d','a','y'):
      return 1;
    case TSTR_PACKED_ALPHA3('T','u','e'):
    case TSTR_PACKED_ALPHA4('T','u','e','s'):
    case TSTR_PACKED_ALPHA7('T','u','e','s','d','a','y'):
      return 2;
    case TSTR_PACKED_ALPHA3('W','e','d'):
    case TSTR_PACKED_ALPHA9('W','e','d','n','e','s','d','a','y'):
      return 3;
    case TSTR_PACKED_ALPHA3('T','h','u'):
    case TSTR_PACKED_ALPHA5('T','h','u','r','s'):
    case TSTR_PACKED_ALPHA8('T','h','u','r','s','d','a','y'):
      return 4;
    case TSTR_PACKED_ALPHA3('F','r','i'):
    case TSTR_PACKED_ALPHA6('F','r','i','d','a','y'):
      return 5;
    case TSTR_PACKED_ALPHA3('S','a','t'):
    case TSTR_PACKED_ALPHA8('S','a','t','u','r','d','a','y'):
      return 6;
    case TSTR_PACKED_ALPHA3('S','u','n'):
    case TSTR_PACKED_ALPHA6('S','u','n','d','a','y'):
      return 7;
    default:
      return kNotFound;
  }
}

static inline int lookup_month_from_packed_alnum(uint64_t packed) {
  switch (packed) {
    case TSTR_PACKED_ALNUM1('1'):
    case TSTR_PACKED_ALNUM2('0','1'):
    case TSTR_PACKED_ALNUM1('I'):
    case TSTR_PACKED_ALNUM3('J','a','n'):
    case TSTR_PACKED_ALNUM7('J','a','n','u','a','r','y'):
      return 1;
    case TSTR_PACKED_ALNUM1('2'):
    case TSTR_PACKED_ALNUM2('0','2'):
    case TSTR_PACKED_ALNUM2('I','I'):
    case TSTR_PACKED_ALNUM3('F','e','b'):
    case TSTR_PACKED_ALNUM8('F','e','b','r','u','a','r','y'):
      return 2;
    case TSTR_PACKED_ALNUM1('3'):
    case TSTR_PACKED_ALNUM2('0','3'):
    case TSTR_PACKED_ALNUM3('I','I','I'):
    case TSTR_PACKED_ALNUM3('M','a','r'):
    case TSTR_PACKED_ALNUM5('M','a','r','c','h'):
      return 3;
    case TSTR_PACKED_ALNUM1('4'):
    case TSTR_PACKED_ALNUM2('0','4'):
    case TSTR_PACKED_ALNUM2('I','V'):
    case TSTR_PACKED_ALNUM3('A','p','r'):
    case TSTR_PACKED_ALNUM5('A','p','r','i','l'):
      return 4;
    case TSTR_PACKED_ALNUM1('5'):
    case TSTR_PACKED_ALNUM2('0','5'):
    case TSTR_PACKED_ALNUM1('V'):
    case TSTR_PACKED_ALNUM3('M','a','y'):
      return 5;
    case TSTR_PACKED_ALNUM1('6'):
    case TSTR_PACKED_ALNUM2('0','6'):
    case TSTR_PACKED_ALNUM2('V','I'):
    case TSTR_PACKED_ALNUM3('J','u','n'):
    case TSTR_PACKED_ALNUM4('J','u','n','e'):
      return 6;
    case TSTR_PACKED_ALNUM1('7'):
    case TSTR_PACKED_ALNUM2('0','7'):
    case TSTR_PACKED_ALNUM3('V','I','I'):
    case TSTR_PACKED_ALNUM3('J','u','l'):
    case TSTR_PACKED_ALNUM4('J','u','l','y'):
      return 7;
    case TSTR_PACKED_ALNUM1('8'):
    case TSTR_PACKED_ALNUM2('0','8'):
    case TSTR_PACKED_ALNUM4('V','I','I','I'):
    case TSTR_PACKED_ALNUM3('A','u','g'):
    case TSTR_PACKED_ALNUM6('A','u','g','u','s','t'):
      return 8;
    case TSTR_PACKED_ALNUM1('9'):
    case TSTR_PACKED_ALNUM2('0','9'):
    case TSTR_PACKED_ALNUM2('I','X'):
    case TSTR_PACKED_ALNUM3('S','e','p'):
    case TSTR_PACKED_ALNUM4('S','e','p','t'):
    case TSTR_PACKED_ALNUM9('S','e','p','t','e','m','b','e','r'):
      return 9;
    case TSTR_PACKED_ALNUM2('1','0'):
    case TSTR_PACKED_ALNUM1('X'):
    case TSTR_PACKED_ALNUM3('O','c','t'):
    case TSTR_PACKED_ALNUM7('O','c','t','o','b','e','r'):
      return 10;
    case TSTR_PACKED_ALNUM2('1','1'):
    case TSTR_PACKED_ALNUM2('X','I'):
    case TSTR_PACKED_ALNUM3('N','o','v'):
    case TSTR_PACKED_ALNUM8('N','o','v','e','m','b','e','r'):
      return 11;
    case TSTR_PACKED_ALNUM2('1','2'):
    case TSTR_PACKED_ALNUM3('X','I','I'):
    case TSTR_PACKED_ALNUM3('D','e','c'):
    case TSTR_PACKED_ALNUM8('D','e','c','e','m','b','e','r'):
      return 12;
    default:
      return kNotFound;
  }
}

bool tstr_token_parse_day(const char* src, size_t len, int* day) {
  uint64_t packed;
  int value;
  if (!len || tstr_packed_alnum_encode(src, len, &packed) != len)
    return false;
  value = lookup_day_from_packed_alnum(packed);
  if (value == kNotFound)
    return false;
  *day = value;
  return true;
}

bool tstr_token_parse_day_name(const char* src, size_t len, int* day) {
  uint64_t packed;
  int value;
  if (!len || tstr_packed_alpha_encode(src, len, &packed) != len)
    return false;
  value = lookup_day_name_from_packed_alpha(packed);
  if (value == kNotFound)
    return false;
  *day = value;
  return true;
}

bool tstr_token_parse_month(const char* src, size_t len, int* month) {
  uint64_t packed;
  int value;
  if (!len || tstr_packed_alnum_encode(src, len, &packed) != len)
    return false;
  value = lookup_month_from_packed_alnum(packed);
  if (value == kNotFound)
    return false;
  *month = value;
  return true;
}

bool tstr_token_parse_meridiem(const char* src, size_t len, int* merdiem) {
  unsigned char a, m;

  if (len == 2) {
    a = src[0];
    m = src[1];
  } else if (len == 4) {
    if (src[1] != '.' || src[3] != '.')
      return false;
    a = src[0];
    m = src[2];
  } else {
    return false;
  }

  if ((m | 0x20) != 'm')
    return false;

  if ((a | 0x20) == 'a') {
    *merdiem = 0;
    return true;
  }
  if ((a | 0x20) == 'p') {
    *merdiem = 12;
    return true;
  }
  return false;
}

static inline bool is_digit(char c) {
  return (unsigned)c - '0' < 10;
}

bool tstr_token_parse_tz_offset(const char* src, size_t len, int* offset) {
  if (!len)
    return false;

  const char *end = src + len;
  int sign;
  switch (*src++) {
  case '+':
    sign = 1;
    break;
  case '-':
    sign = -1;
    break;
  default:
    return false;
  }

  // Parse hour (1-2 digits)
  int h = 0;
  size_t nd = 0;
  while (nd < 2 && src < end && is_digit(*src)) {
    h = h * 10 + (*src++ - '0');
    nd++;
  }

  if (nd == 0)
    return false;

  // Parse optional minutes
  int m = 0;
  if (src < end) {
    if (*src == ':')
      src++;
    if (end - src != 2)
      return false;
    if (!is_digit(src[0]) || !is_digit(src[1]))
      return false;
    m = (src[0] - '0') * 10 + (src[1] - '0');
    src += 2;
  }

  if (src != end)
    return false;

  if (h > 23 || m > 59)
    return false;

  *offset = sign * (h * 60 + m);
  return true;
}

bool tstr_token_parse_year(const char* src, size_t len, int* year) {
  if (len != 2 && len != 4)
    return false;

  int v = 0;
  for (size_t i = 0; i < len; i++) {
    if (!is_digit(src[i]))
      return false;
    v = v * 10 + (src[i] - '0');
  }

  *year = v;
  return true;
}

bool tstr_token_parse_hour(const char* src, size_t len, int* hour) {
  if (len < 1 || len > 2)
    return false;

  int v = 0;
  for (size_t i = 0; i < len; i++) {
    if (!is_digit(src[i]))
      return false;
    v = v * 10 + (src[i] - '0');
  }

  *hour = v;
  return true;
}

bool tstr_token_parse_minute(const char* src, size_t len, int* minute) {
  if (len != 2)
    return false;
  if (!is_digit(src[0]) || !is_digit(src[1]))
    return false;

  *minute = (src[0] - '0') * 10 + (src[1] - '0');
  return true;
}

bool tstr_token_parse_second(const char* src, size_t len, int* second) {
  if (len != 2)
    return false;
  if (!is_digit(src[0]) || !is_digit(src[1]))
    return false;

  *second = (src[0] - '0') * 10 + (src[1] - '0');
  return true;
}

bool tstr_token_parse_fraction(const char* src, size_t len, int* nanosecond) {
  if (len < 1 || len > 9)
    return false;

  int v = 0;
  for (size_t i = 0; i < len; i++) {
    if (!is_digit(src[i]))
      return false;
    v = v * 10 + (src[i] - '0');
  }

  for (size_t i = len; i < 9; i++)
    v *= 10;

  *nanosecond = v;
  return true;
}
