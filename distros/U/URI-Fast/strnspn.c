#include <stdlib.h>
#include <string.h>
#include "fast.h"

static
size_t strnspn(const char *s, size_t s_len, const char *c)
{
  size_t res = strspn(s, c);
  return s_len < res ? s_len : res;
}

static
size_t strncspn(const char *s, size_t s_len, const char *c)
{
  size_t res = strcspn(s, c);
  return s_len < res ? s_len : res;
}
