#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Tie::Array::Pointer  PACKAGE = Tie::Array::Pointer

PROTOTYPES: DISABLE

void *
tsp_malloc(bytes)
    size_t bytes

  CODE:
    void *buffer;

    # // printf("tsp_malloc(%d)\n", bytes);
    buffer = safemalloc(bytes);
    RETVAL = buffer;

  OUTPUT:
    RETVAL

void
tsp_free(buffer)
    void *buffer

  CODE:
    if (buffer) safefree(buffer);

# /* write 1 byte */
void
tsp_w8(buffer, i8)
    void *buffer;
    I32 i8;

  CODE:
    char *b = (char *) buffer;
    *b      = i8;

# /* write 2 bytes */
void
tsp_w16(buffer, i16)
    void *buffer;
    I16 i16;

  CODE:
    I16 *b = (I16 *) buffer;
    *b     = i16;

# /* write 4 bytes */
void
tsp_w32(buffer, i32)
    void *buffer;
    I32 i32;

  CODE:
    I32 *b = (I32 *) buffer;
    *b     = i32;

# /* read 1 byte */
I32
tsp_r8(buffer)
    void *buffer;

  CODE:
    char *b = (char *) buffer;
    RETVAL  = (I32) *b;
    # // printf("read %d at %08x\n", RETVAL, b);

  OUTPUT:
    RETVAL

# /* read 2 bytes */
I16
tsp_r16(buffer)
    void *buffer;

  CODE:
    I16 *b = (I16 *) buffer;
    RETVAL = *b;

  OUTPUT:
    RETVAL

# /* read 4 bytes */
I32
tsp_r32(buffer)
    void *buffer;

  CODE:
    I32 *b = (I32 *) buffer;
    RETVAL = *b;

  OUTPUT:
    RETVAL

# /* a comment in .xs files needs to start w/ /^#\s+/ */
# /* $Id */
