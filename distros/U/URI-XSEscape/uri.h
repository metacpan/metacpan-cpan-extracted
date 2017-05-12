#ifndef URI_H_
#define URI_H_

/*
 * Routines to URI encode and decode a string efficiently.
 */

#include "buffer.h"

Buffer* uri_decode(Buffer* src, int length,
                   Buffer* tgt);

Buffer* uri_encode(Buffer* src, int length,
                   Buffer* tgt);
Buffer* uri_encode_matrix(Buffer* src, int length,
                          Buffer* escape,
                          Buffer* tgt);

#endif
