/** enc-templ.c  -  XML encoder template, used in code generation
 ** Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 ** Copyright (c) 2006-2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 ** Author: Sampo Kellomaki (sampo@iki.fi)
 ** This is confidential unpublished proprietary source code of the author.
 ** NO WARRANTY, not even implied warranties. Contains trade secrets.
 ** Distribution prohibited unless authorized in writing.
 ** Licensed under Apache License 2.0, see file COPYING.
 ** $Id: enc-templ.c,v 1.27 2007-10-05 22:24:28 sampo Exp $
 **
 ** 30.5.2006, created, Sampo Kellomaki (sampo@iki.fi)
 ** 6.8.2006,  factored data structure walking to aux-templ.c --Sampo
 ** 8.8.2006,  reworked namespace handling --Sampo
 ** 26.8.2006, some CSE --Sampo
 ** 23.9.2006, added WO logic --Sampo
 ** 30.9.2007, improvements to WO encoding --Sampo
 ** 8.2.2010,  better handling of schema order encoding of unknown namespace prefixes --Sampo
 ** 27.10.2010, re-engineered namespace handling --Sampo
 ** 24.11.2010, this code is sceduled for removal as el_order processing in WO encoder accomplishes the same result. --Sampo
 **
 ** N.B: wo=wire order (needed for exc-c14n), so=schema order
 ** N.B2: This template is meant to be processed by pd/xsd2sg.pl. Beware
 ** of special markers that xsd2sg.pl expects to find and understand.
 **/

#if 0

#ifdef EL_NAME
#undef EL_NAME
#endif
#ifdef EL_STRUCT
#undef EL_STRUCT
#endif
#ifdef EL_NS
#undef EL_NS
#endif
#ifdef EL_TAG
#undef EL_TAG
#endif

#define EL_NAME   ELNAME
#define EL_STRUCT ELSTRUCT
#define EL_NS     ELNS
#define EL_TAG    ELTAG

#ifndef MAYBE_UNUSED
#define MAYBE_UNUSED   /* May appear as unused variable, but is needed by some generated code. */
#endif

#if 0
#define ENC_LEN_DEBUG(x,tag,len) D("x=%p tag(%s) len=%d",(x),(tag),(len))
#define ENC_LEN_DEBUG_BASE char* enc_base = p
#else
#define ENC_LEN_DEBUG(x,tag,len)
#define ENC_LEN_DEBUG_BASE
#endif

/* FUNC(TXLEN_SO_ELNAME) */

/* Compute length of an element (and its subelements). The XML attributes
 * and elements are processed in schema order. */

/* Called by: */
int TXLEN_SO_ELNAME(struct zx_ctx* c, struct ELSTRUCT* x SIMPLELENNS)
{
  struct zx_ns_s* pop_seen = 0;
  struct zx_elem_s* se MAYBE_UNUSED;
#if 1 /* NORMALMODE */
  /* *** in simple_elem case should output ns prefix from ns node. */
  int len = sizeof("<ELNSCELTAG")-1 + 1 + sizeof("</ELNSCELTAG>")-1;
  if (c->inc_ns_len)
    len += zx_len_inc_ns(c, &pop_seen);
XMLNS_SO_LEN;
ATTRS_SO_LEN;
#else
  /* root node has no begin tag */
  int len = 0;
#endif
  
ELEMS_SO_LEN;

  len += zx_len_so_common(c, &x->gg, &pop_seen);
  zx_pop_seen(pop_seen);
  ENC_LEN_DEBUG(x, "ELNSCELTAG", len);
  return len;
}

/* FUNC(TXENC_SO_ELNAME) */

/* Render element into string. The XML attributes and elements are
 * processed in schema order. This is what you generally want for
 * rendering new data structure to a string. The wo pointers are not used. */

/* Called by: */
char* TXENC_SO_ELNAME(struct zx_ctx* c, struct ELSTRUCT* x, char* p SIMPLETAGLENNS)
{
  struct zx_elem_s* se MAYBE_UNUSED;
  struct zx_attr_s* attr MAYBE_UNUSED;
  struct zx_ns_s* pop_seen = 0;
  ENC_LEN_DEBUG_BASE;
#if 1 /* NORMALMODE */
  /* *** in simple_elem case should output ns prefix from ns node. */
  ZX_OUT_TAG(p, "<ELNSCELTAG");
  if (c->inc_ns)
    zx_add_inc_ns(c, &pop_seen);
XMLNS_SO_SEE;
  zx_see_attr_ns(c, x->gg.attr, &pop_seen);
  p = zx_enc_seen(p, pop_seen); 
ATTRS_SO_ENC;
  for (attr = x->gg.attr; attr; attr = (struct zx_attr_s*)attr->g.n)
    if (attr->g.tok == ZX_TOK_ATTR_NOT_FOUND)
      p = zx_attr_wo_enc(p, attr);
  ZX_OUT_CH(p, '>');
#else
  /* root node has no begin tag */
#endif
  
ELEMS_SO_ENC;
  p = zx_enc_so_unknown_elems_and_content(c, p, &x->gg);
  
#if 1 /* NORMALMODE */
  ZX_OUT_CLOSE_TAG(p, "</ELNSCELTAG>");
  zx_pop_seen(pop_seen);
#else
  /* root node has no end tag either */
#endif
  ENC_LEN_DEBUG(x, "ELNSCELTAG", p-enc_base);
  return p;
}

/* FUNC(TXEASY_ENC_SO_ELNAME) */

/* Called by: */
struct zx_str* TXEASY_ENC_SO_ELNAME(struct zx_ctx* c, struct ELSTRUCT* x SIMPLETAGLENNS)
{
  int len;
  char* buf;
  c->ns_tab = ZX_ALLOC(c, sizeof(TXns_tab));      /* *** do we really need to make a copy? Do we still keep list of aliases? */
  memcpy(c->ns_tab, TXns_tab, sizeof(TXns_tab));
  len = TXLEN_SO_ELNAME(c, x SIMPLELENNSARG);
  buf = ZX_ALLOC(c, len+1);
  return zx_easy_enc_common(c, TXENC_SO_ELNAME(c, x, buf SIMPLETAGLENNSARG), buf, len);
}
#endif

/* EOF */
