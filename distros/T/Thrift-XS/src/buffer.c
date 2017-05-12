// Derived from:

/* $OpenBSD: buffer.c,v 1.31 2006/08/03 03:34:41 deraadt Exp $ */
/*
 * Author: Tatu Ylonen <ylo@cs.hut.fi>
 * Copyright (c) 1995 Tatu Ylonen <ylo@cs.hut.fi>, Espoo, Finland
 *                    All rights reserved
 * Functions for manipulating fifo buffers (that can grow if needed).
 *
 * As far as I am concerned, the code I have written for this software
 * can be used freely for any purpose.  Any derived versions of this
 * software must be clearly marked as such, and if the derived work is
 * incompatible with the protocol description in the RFC file, it must be
 * called by a name other than "ssh" or "Secure Shell".
 */

#include "buffer.h"

#define  BUFFER_MAX_CHUNK       0x1400000
#define  BUFFER_MAX_LEN         0x1400000
#define  BUFFER_ALLOCSZ         0x002000
#define  BUFFER_COMPACT_PERCENT 0.8

/* Initializes the buffer structure. */

void
buffer_init(Buffer *buffer, uint32_t len)
{
  if (!len) len = BUFFER_ALLOCSZ;

  buffer->alloc = 0;
  New(0, buffer->buf, (int)len, u_char);
  buffer->alloc = len;
  buffer->offset = 0;
  buffer->end = 0;

#ifdef XS_DEBUG
  PerlIO_printf(PerlIO_stderr(), "Buffer allocated with %d bytes\n", len);
#endif
}

/* Frees any memory used for the buffer. */

void
buffer_free(Buffer *buffer)
{
  if (buffer->alloc > 0) {
#ifdef XS_DEBUG
    PerlIO_printf(PerlIO_stderr(), "Buffer high water mark: %d\n", buffer->alloc);
#endif
    memset(buffer->buf, 0, buffer->alloc);
    buffer->alloc = 0;
    Safefree(buffer->buf);
  }
}

/* Appends data to the buffer, expanding it if necessary. */

void
buffer_append(Buffer *buffer, const void *data, uint32_t len)
{
  void *p;
  p = buffer_append_space(buffer, len);
  Copy(data, p, (int)len, u_char);
}

static int
buffer_compact(Buffer *buffer)
{
  /*
   * If the buffer is at least BUFFER_COMPACT_PERCENT empty, move the
   * data to the beginning.
   */
  if (buffer->offset * 1.0 / buffer->alloc >= BUFFER_COMPACT_PERCENT ) {
#ifdef XS_DEBUG
    PerlIO_printf(PerlIO_stderr(), "Buffer compacting (%d -> %d)\n", buffer->offset + buffer_len(buffer), buffer_len(buffer));
#endif
    Move(buffer->buf + buffer->offset, buffer->buf, (int)(buffer->end - buffer->offset), u_char);
    buffer->end -= buffer->offset;
    buffer->offset = 0;
    return (1);
  }

  return (0);
}

/*
 * Appends space to the buffer, expanding the buffer if necessary. This does
 * not actually copy the data into the buffer, but instead returns a pointer
 * to the allocated region.
 */

void *
buffer_append_space(Buffer *buffer, uint32_t len)
{
  uint32_t newlen;
  void *p;

  if (len > BUFFER_MAX_CHUNK)
    croak("buffer_append_space: len %u too large (max %u)", len, BUFFER_MAX_CHUNK);

  /* If the buffer is empty, start using it from the beginning. */
  if (buffer->offset == buffer->end) {
    buffer->offset = 0;
    buffer->end = 0;
  }

restart:
  /* If there is enough space to store all data, store it now. */
  if (buffer->end + len <= buffer->alloc) {
    p = buffer->buf + buffer->end;
    buffer->end += len;
    return p;
  }

  /* Compact data back to the start of the buffer if necessary */
  if (buffer_compact(buffer))
    goto restart;

  /* Increase the size of the buffer and retry. */
  if (buffer->alloc + len < 4096)
    newlen = (buffer->alloc + len) * 2;
  else
    newlen = buffer->alloc + len + 4096;
  
  if (newlen > BUFFER_MAX_LEN)
    croak("buffer_append_space: alloc %u too large (max %u)",
        newlen, BUFFER_MAX_LEN);
#ifdef XS_DEBUG
  PerlIO_printf(PerlIO_stderr(), "Buffer extended to %d\n", newlen);
#endif
  Renew(buffer->buf, (int)newlen, u_char);
  buffer->alloc = newlen;
  goto restart;
  /* NOTREACHED */
}

/* Returns the number of bytes of data in the buffer. */

uint32_t
buffer_len(Buffer *buffer)
{
  return buffer->end - buffer->offset;
}

/* Gets data from the beginning of the buffer. */

int
buffer_get_ret(Buffer *buffer, void *buf, uint32_t len)
{
  if (len > buffer->end - buffer->offset) {
    warn("buffer_get_ret: trying to get more bytes %d than in buffer %d", len, buffer->end - buffer->offset);
    return (-1);
  }

  Copy(buffer->buf + buffer->offset, buf, (int)len, char);
  buffer->offset += len;
  return (0);
}

void
buffer_get(Buffer *buffer, void *buf, uint32_t len)
{
  if (buffer_get_ret(buffer, buf, len) == -1)
    croak("buffer_get: buffer error");
}

/* Consumes the given number of bytes from the beginning of the buffer. */

int
buffer_consume_ret(Buffer *buffer, uint32_t bytes)
{
  if (bytes > buffer->end - buffer->offset) {
    warn("buffer_consume_ret: trying to get more bytes %d than in buffer %d", bytes, buffer->end - buffer->offset);
    return (-1);
  }

  buffer->offset += bytes;
  return (0);
}

void
buffer_consume(Buffer *buffer, uint32_t bytes)
{
  if (buffer_consume_ret(buffer, bytes) == -1)
    croak("buffer_consume: buffer error");
}

/* Returns a pointer to the first used byte in the buffer. */

void *
buffer_ptr(Buffer *buffer)
{
  return buffer->buf + buffer->offset;
}

// Dumps the contents of the buffer to stderr.
// Based on: http://sws.dett.de/mini/hexdump-c/
#ifdef XS_DEBUG
void
buffer_dump(Buffer *buffer, uint32_t size)
{
  unsigned char *data = buffer->buf;
  unsigned char c;
  int i = 1;
  int n;
  char bytestr[4] = {0};
  char hexstr[ 16*3 + 5] = {0};
  char charstr[16*1 + 5] = {0};
  
  if (!size) {
    size = buffer->end - buffer->offset;
  }
  
  for (n = buffer->offset; n < buffer->offset + size; n++) {
    c = data[n];

    /* store hex str (for left side) */
    snprintf(bytestr, sizeof(bytestr), "%02x ", c);
    strncat(hexstr, bytestr, sizeof(hexstr)-strlen(hexstr)-1);

    /* store char str (for right side) */
    if (isalnum(c) == 0) {
      c = '.';
    }
    snprintf(bytestr, sizeof(bytestr), "%c", c);
    strncat(charstr, bytestr, sizeof(charstr)-strlen(charstr)-1);

    if (i % 16 == 0) { 
      /* line completed */
      PerlIO_printf(PerlIO_stderr(), "%-50.50s  %s\n", hexstr, charstr);
      hexstr[0] = 0;
      charstr[0] = 0;
    }
    i++;
  }

  if (strlen(hexstr) > 0) {
    /* print rest of buffer if not empty */
    PerlIO_printf(PerlIO_stderr(), "%-50.50s  %s\n", hexstr, charstr);
  }
}
#endif
