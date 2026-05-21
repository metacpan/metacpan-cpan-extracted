#ifndef TSTR_PARAM_H
#define TSTR_PARAM_H

#include <stddef.h>
#include <string.h>

typedef enum {
  TSTR_PARAM_UNKNOWN = 0,
  TSTR_PARAM_FORMAT,
  TSTR_PARAM_PRECISION,
  TSTR_PARAM_NANOSECOND,
  TSTR_PARAM_OFFSET,
  TSTR_PARAM_PIVOT_YEAR,
} tstr_param_t;

static inline tstr_param_t tstr_param_from_string(const char* src, size_t len) {
  switch (len) {
    case 6:
      if (!memcmp(src, "format", 6))
        return TSTR_PARAM_FORMAT;
      if (!memcmp(src, "offset", 6))
        return TSTR_PARAM_OFFSET;
      break;
    case 9:
      if (!memcmp(src, "precision", 9))
        return TSTR_PARAM_PRECISION;
      break;
    case 10:
      if (!memcmp(src, "nanosecond", 10))
        return TSTR_PARAM_NANOSECOND;
      if (!memcmp(src, "pivot_year", 10))
        return TSTR_PARAM_PIVOT_YEAR;
      break;
  }
  return TSTR_PARAM_UNKNOWN;
}

#endif /* TSTR_PARAM_H */
