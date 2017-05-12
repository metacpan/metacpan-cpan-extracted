
#if !defined(TIGER_H)

#define TIGER_H

#include <stdio.h>
#include "endian.h"

typedef unsigned long long int u64;
typedef unsigned long u32;
typedef unsigned char byte;

#define TIGER_BLOCKSIZE 64
#define TIGER_HASHSIZE 24

typedef struct {
    u64  a, b, c;
    byte buf[64];
    int  count;
    u32  nblocks;
} TIGER_CONTEXT;

extern void tiger_init(TIGER_CONTEXT *hd);
extern void tiger_update(TIGER_CONTEXT *hd, byte *inbuf, size_t inlen);
extern void tiger_final(byte hash[24], TIGER_CONTEXT *hd);

#endif
