/*
 * Copyright (c) 2017 Christian Hansen <chansen@cpan.org>
 * <https://github.com/chansen/c-utf8-valid>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef UTF8_VALID_H
#define UTF8_VALID_H
#include <stddef.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

size_t
utf8_maximal_subpart(const char *src, size_t len) {
  const unsigned char *cur = (const unsigned char *)src;
  U32 v;

  if (len < 2)
    return len;

  v = (cur[0] << 8) | cur[1];
  if ((v & 0xC0C0) != 0xC080)
    return 1;

  if ((v & 0x2000) == 0) {
    if ((v & 0x1E00) == 0)
      return 1;
    return 2;
  }
  else if ((v & 0x1000) == 0) {
    if ((v & 0x0F20) == 0 ||
        (v & 0x0F20) == 0x0D20)
      return 1;
    if (len < 3 || (cur[2] & 0xC0) != 0x80)
      return 2;
    return 3;
  }
  else {
    if ((v & 0x0730) == 0 ||
        (v > 0xF48F))
      return 1;
    if (len < 3 || (cur[2] & 0xC0) != 0x80)
      return 2;
    if (len < 4 || (cur[3] & 0xC0) != 0x80)
      return 3;
    return 4;
  }
}

bool
utf8_check(const char *src, size_t len, size_t *cursor) {
  const unsigned char *cur = (const unsigned char *)src;
  const unsigned char *end = cur + len;
  const unsigned char *p;
  unsigned char buf[4];
  U32 v;

  for (p = cur;;) {
    if (cur >= end - 3) {
      if (cur == end)
        break;
      memset(buf, 0, 4);
      memcpy(buf, cur, end - cur);
      p = (const unsigned char *)buf;
    }

    v = *p++;
    if ((v & 0x80) == 0) {
      cur += 1;
      continue;
    }

    v = (v << 8) | *p++;
    if ((v & 0xE0C0) == 0xC080 &&
        (v & 0x1E00) != 0) {
      cur += 2;
      continue;
    }

    v = (v << 8) | *p++;
    if ((v & 0xF0C0C0) == 0xE08080 &&
        (v & 0x0F2000) != 0 &&
        (v & 0x0F2000) != 0x0D2000) {
      cur += 3;
      continue;
    }

    v = (v << 8) | *p++;
    if ((v & 0xF8C0C0C0) == 0xF0808080 &&
        (v & 0x07300000) != 0 &&
        (v < 0xF4908080)) {
      cur += 4;
      continue;
    }

    break;
  }

  if (cursor)
    *cursor = (const char *)cur - src;

  return cur == end;
}

bool
utf8_valid(const char *src, size_t len) {
  return utf8_check(src, len, NULL);
}

#ifdef __cplusplus
}
#endif
#endif

