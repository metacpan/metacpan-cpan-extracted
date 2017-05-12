// Derived from:

/* $OpenBSD: buffer.h,v 1.17 2008/05/08 06:59:01 markus Exp $ */

/*
 * Author: Tatu Ylonen <ylo@cs.hut.fi>
 * Copyright (c) 1995 Tatu Ylonen <ylo@cs.hut.fi>, Espoo, Finland
 *                    All rights reserved
 * Code for manipulating FIFO buffers.
 *
 * As far as I am concerned, the code I have written for this software
 * can be used freely for any purpose.  Any derived versions of this
 * software must be clearly marked as such, and if the derived work is
 * incompatible with the protocol description in the RFC file, it must be
 * called by a name other than "ssh" or "Secure Shell".
 */

#ifndef BUFFER_H
#define BUFFER_H

typedef struct {
  u_char  *buf;   /* Buffer for data. */
  u_int  alloc;   /* Number of bytes allocated for data. */
  u_int  offset;  /* Offset of first byte containing data. */
  u_int  end;     /* Offset of last byte containing data. */
} Buffer;

void buffer_init(Buffer *buffer, uint32_t len);
void buffer_free(Buffer *buffer);
void buffer_append(Buffer *buffer, const void *data, uint32_t len);
static int buffer_compact(Buffer *buffer);
void * buffer_append_space(Buffer *buffer, uint32_t len);
uint32_t buffer_len(Buffer *buffer);
int buffer_get_ret(Buffer *buffer, void *buf, uint32_t len);
void buffer_get(Buffer *buffer, void *buf, uint32_t len);
int buffer_consume_ret(Buffer *buffer, uint32_t bytes);
void buffer_consume(Buffer *buffer, uint32_t bytes);
void * buffer_ptr(Buffer *buffer);
#ifdef XS_DEBUG
void buffer_dump(Buffer *buffer, uint32_t len);
#endif

#endif
