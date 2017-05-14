/** getput-templ.c  -  Auxiliary functions template: cloning, freeing, walking data
 ** Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 ** Author: Sampo Kellomaki (sampo@iki.fi)
 ** This is confidential unpublished proprietary source code of the author.
 ** NO WARRANTY, not even implied warranties. Contains trade secrets.
 ** Distribution prohibited unless authorized in writing.
 ** Licensed under Apache License 2.0, see file COPYING.
 ** $Id: getput-templ.c,v 1.8 2009-08-30 15:09:26 sampo Exp $
 **
 ** 30.5.2006, created, Sampo Kellomaki (sampo@iki.fi)
 ** 6.8.2006, factored from enc-templ.c to separate file --Sampo
 **
 ** N.B: wo=wire order (needed for exc-c14n), so=schema order
 ** Edit with care! xsd2sg.pl applies various substitutions to this file.
 **/

#if 1 /* GETPUT_SUBTEMPL */

#ifdef ZX_ENA_GETPUT

/* FUNC(ELTYPE_NUM_FNAME) */

int ELTYPE_NUM_FNAME(struct ELTYPE_s* x)
{
  struct FTYPE_s* y;
  int n = 0;
  if (!x) return 0;
  for (y = x->FNAME; y && y->gg.g.tok == FTYPE_ELEM; ++n, y = (struct FTYPE_s*)y->gg.g.n) ;
  return n;
}

/* FUNC(ELTYPE_GET_FNAME) */

struct FTYPE_s* ELTYPE_GET_FNAME(struct ELTYPE_s* x, int n)
{
  struct FTYPE_s* y;
  if (!x) return 0;
  for (y = x->FNAME; n>=0 && y && y->gg.g.tok == FTYPE_ELEM; --n, y = (struct FTYPE_s*)y->gg.g.n) ;
  return y;
}

/* FUNC(ELTYPE_POP_FNAME) */

struct FTYPE_s* ELTYPE_POP_FNAME(struct ELTYPE_s* x)
{
  struct FTYPE_s* y;
  if (!x) return 0;
  y = x->FNAME;
  if (y)
    x->FNAME = (struct FTYPE_s*)y->gg.g.n;
  return y;
}

/* FUNC(ELTYPE_PUSH_FNAME) */

void ELTYPE_PUSH_FNAME(struct ELTYPE_s* x, struct FTYPE_s* z)
{
  if (!x || !z) return;
  z->gg.g.n = &x->FNAME->gg.g;
  x->FNAME = z;
}

/* FUNC(ELTYPE_REV_FNAME) */

void ELTYPE_REV_FNAME(struct ELTYPE_s* x)
{
  struct FTYPE_s* nxt;
  struct FTYPE_s* y;
  if (!x) return;
  y = x->FNAME;
  if (!y) return;
  x->FNAME = 0;
  while (y) {
    nxt = (struct FTYPE_s*)y->gg.g.n;
    y->gg.g.n = &x->FNAME->gg.g;
    x->FNAME = y;
    y = nxt;
  }
}

/* FUNC(ELTYPE_PUT_FNAME) */

void ELTYPE_PUT_FNAME(struct ELTYPE_s* x, int n, struct FTYPE_s* z)
{
  struct FTYPE_s* y;
  if (!x || !z) return;
  y = x->FNAME;
  if (!y) return;
  switch (n) {
  case 0:
    z->gg.g.n = y->gg.g.n;
    x->FNAME = z;
    return;
  default:
    for (; n > 1 && y->gg.g.n && y->gg.g.n->gg.g.tok == FTYPE_ELEM; --n, y = (struct FTYPE_s*)y->gg.g.n) ;
    if (!y->gg.g.n) return;
    z->gg.g.n = y->gg.g.n->n;
    y->gg.g.n = &z->gg.g;
  }
}

/* FUNC(ELTYPE_ADD_FNAME) */

void ELTYPE_ADD_FNAME(struct ELTYPE_s* x, int n, struct FTYPE_s* z)
{
  struct FTYPE_s* y;
  if (!x || !z) return;
  switch (n) {
  case 0:
  add_to_start:
    z->gg.g.n = &x->FNAME->gg.g;
    x->FNAME = z;
    return;
  case -1:
    y = x->FNAME;
    if (!y) goto add_to_start;
    for (; y->gg.g.n && y->gg.g.n->gg.g.tok == FTYPE_ELEM; y = (struct FTYPE_s*)y->gg.g.n) ;
    break;
  default:
    for (y = x->FNAME; n > 1 && y && y->gg.g.tok == FTYPE_ELEM; --n, y = (struct FTYPE_s*)y->gg.g.n) ;
    if (!y) return;
  }
  z->gg.g.n = y->gg.g.n;
  y->gg.g.n = &z->gg.g;
}

/* FUNC(ELTYPE_DEL_FNAME) */

void ELTYPE_DEL_FNAME(struct ELTYPE_s* x, int n)
{
  struct FTYPE_s* y;
  if (!x) return;
  switch (n) {
  case 0:
    x->FNAME = (struct FTYPE_s*)x->FNAME->gg.g.n;
    return;
  case -1:
    y = (struct FTYPE_s*)x->FNAME;
    if (!y) return;
    for (; y->gg.g.n && y->gg.g.n->gg.g.tok == FTYPE_ELEM; y = (struct FTYPE_s*)y->gg.g.n) ;
    break;
  default:
    for (y = x->FNAME; n > 1 && y->gg.g.n && y->gg.g.n->gg.g.tok == FTYPE_ELEM; --n, y = (struct FTYPE_s*)y->gg.g.n) ;
    if (!y->gg.g.n) return;
  }
  y->gg.g.n = y->gg.g.n->n;
}

#endif

#endif /* GETPUT_SUBTEMPL */

/* EOF */
