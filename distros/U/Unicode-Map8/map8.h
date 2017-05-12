/*
 * Copyright 1998, Gisle Aas.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */


#ifdef PERL
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#else
typedef unsigned long   U32;
typedef unsigned short  U16;
typedef unsigned char   U8;
#endif

#ifndef pTHX_
   #define pTHX_
#endif

#ifndef dTHX
   #define dTHX extern int errno
#endif

struct map8;

typedef U8*  (*map8_cb8)  (U16, struct map8*, STRLEN*);
typedef U16* (*map8_cb16) (U8,  struct map8*, STRLEN*);

typedef struct map8
{
  U16     to_16[256];
  U16*    to_8 [256]; /* two level table, first level is (char>>8) */

  /* default mapping values (to use if mapping is NOCHAR) */
  U16     def_to8;
  U16     def_to16;

  /* callback functions (to use if mapping and default is NOCHAR */
  map8_cb8  cb_to8;
  map8_cb16 cb_to16;

  void*   obj;  /* extra info of some kind */
} Map8;

/* A binary mapping file is a sequence of one or more of these records.
 * The numbers are stored in network byte order (big endian)
 */
struct map8_filerec
{
  U16  u8;
  U16 u16;
};

/* The first record of a binary file is a magic record with these
 * values.  The second value also serves as a file format version
 * number.
 */
#define MAP8_BINFILE_MAGIC_HI 0xFFFE
#define MAP8_BINFILE_MAGIC_LO 0x0001

#define NOCHAR  0xFFFF         /* U+FFFF is guaranteed not to be used */
#define map8_to_char16(m,c)    (m)->to_16[c]
#define map8_to_char8(m,c)     (m)->to_8[(c)>>8][(c)&0xFF]

#define map8_set_def_to8(m,c)  (m)->def_to8 = c
#define map8_get_def_to8(m)    (m)->def_to8
#define map8_set_def_to16(m,c) (m)->def_to16 = htons(c)
#define map8_get_def_to16(m)   ntohs((m)->def_to16)

/* Prototypes */
Map8* map8_new(void);
Map8* map8_new_txtfile(const char*);
Map8* map8_new_binfile(const char*);
void  map8_addpair(Map8*, U8, U16);
void  map8_nostrict(Map8*);
void  map8_free(Map8*);

U16*  map8_to_str16(Map8*, U8*, U16*, int, int*);
U8*   map8_to_str8 (Map8*, U16*, U8*, int, int*);
U8*   map8_recode_8(Map8*, Map8*, U8*, U8*, int, int*);

int   map8_empty_block(Map8*, U8);

#ifdef MAP8_DEBUGGING
#include <stdio.h>

void map8_print(Map8*);
void map8_fprint(Map8*,FILE*);
#endif
