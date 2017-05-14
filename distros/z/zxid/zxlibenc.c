/* zxlibenc.c  -  XML encoder
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxlib.c,v 1.41 2009-11-24 23:53:40 sampo Exp $
 *
 * 28.5.2006, created --Sampo
 * 8.8.2006,  moved lookup functions to generated code --Sampo
 * 12.8.2006, added special scanning of xmlns to avoid backtracking elem recognition --Sampo
 * 26.8.2006, significant Common Subexpression Elimination (CSE) --Sampo
 * 30.9.2007, more CSE --Sampo
 * 7.10.2008, added documentation --Sampo
 * 26.5.2010, added XML parse error reporting --Sampo
 * 27.10.2010, re-engineered namespace handling --Sampo
 */

#include "platform.h"  /* needed on Win32 for snprintf(), va_copy() et al. */

#include <memory.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "errmac.h"
#include "zx.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* Add inclusive namespaces. */

/* Called by:  TXLEN_SO_ELNAME, zx_LEN_WO_any_elem x2 */
static int zx_len_inc_ns(struct zx_ctx* c, struct zx_ns_s** pop_seenp) {
  int len = 0;
  struct zx_ns_s* ns;
  for (ns = c->inc_ns; ns; ns = ns->inc_n)
    len += zx_len_xmlns_if_not_seen(c, ns, pop_seenp);
  /*c->inc_ns_len = 0;  needs to be processed at every level */
  return len;
}

/* Called by:  TXENC_SO_ELNAME, zx_ENC_WO_any_elem x2 */
static void zx_add_inc_ns(struct zx_ctx* c, struct zx_ns_s** pop_seenp) {
  struct zx_ns_s* ns;
  for (ns = c->inc_ns; ns; ns = ns->inc_n)
    zx_add_xmlns_if_not_seen(c, ns, pop_seenp);
  /*c->inc_ns = 0;  needs to be processed at every level */
}

/* Called by:  TXENC_SO_ELNAME, zx_ENC_WO_any_elem */
static void zx_see_attr_ns(struct zx_ctx* c, struct zx_attr_s* aa, struct zx_ns_s** pop_seenp) {
  for (; aa; aa = (struct zx_attr_s*)aa->g.n)
    zx_add_xmlns_if_not_seen(c, aa->ns, pop_seenp);
}

/*() Check if a namespace is already in inclusive namespaces so we do not need to add it again. */

/* Called by:  zxsig_validate */
int zx_in_inc_ns(struct zx_ctx* c, struct zx_ns_s* new_ns) {
  struct zx_ns_s* ns;
  for (ns = c->inc_ns; ns; ns = ns->inc_n)
    if (new_ns == ns)
      return 1;
  return 0;
}

/*() Convert a tok integer to namespace and el_tok descriptor from zx_el_tab[] table. */

struct zx_el_tok* zx_get_el_tok(struct zx_elem_s* x)
{
  int ix;
  if (!x->ns) {
    ix = (x->g.tok >> ZX_TOK_NS_SHIFT)&(ZX_TOK_NS_MASK >> ZX_TOK_NS_SHIFT);
    if (ix >= zx__NS_MAX) {
      ERR("Namespace index of token(0x%06x) out of range(0x%02x)", x->g.tok, zx__NS_MAX);
      return 0;
    }
    x->ns = zx_ns_tab + ix;
  }
  ix = x->g.tok & ZX_TOK_TOK_MASK;
  if (ix >= zx__ELEM_MAX) {
    ERR("Element token(0x%06x) out of range(0x%04x)", x->g.tok, zx__ELEM_MAX);
    return 0;
  }
  return zx_el_tab + ix;
}

/*() Convert a tok integer to namespace and at_tok descriptor from zx_at_tab[] table. */

static struct zx_at_tok* zx_get_at_tok(struct zx_attr_s* attr)
{
  int ix;
  if (!attr->ns && IN_RANGE((attr->g.tok & ZX_TOK_NS_MASK) >> ZX_TOK_NS_SHIFT, 1, zx__NS_MAX))
    attr->ns = zx_ns_tab + ((attr->g.tok & ZX_TOK_NS_MASK) >> ZX_TOK_NS_SHIFT);
  ix = attr->g.tok & ZX_TOK_TOK_MASK;
  if (ix >= zx__ATTR_MAX) {
    ERR("Attribute token(0x%06x) out of range(0x%04x)", attr->g.tok, zx__ATTR_MAX);
    return 0;
  }
  return zx_at_tab + ix;
}

#define D_LEN_ENA 0
#if D_LEN_ENA
#define D_LEN(f,t,l) D(f,t,l)
#else
#define D_LEN(f,t,l)
#endif

/*() Compute length of an element (and its subelements). The XML attributes
 * and elements are processed in wire order and no assumptions
 * are made about namespace prefixes. */

/* Called by:  main x2, zx_EASY_ENC_elem, zx_LEN_WO_any_elem x2 */
int zx_LEN_WO_any_elem(struct zx_ctx* c, struct zx_elem_s* x)
{
  //const struct zx_el_desc* ed;
  struct zx_at_tok* at_tok;
  struct zx_el_tok* el_tok;
  struct zx_ns_s* pop_seen = 0;
  struct zx_attr_s* attr;
  struct zx_elem_s* kid;
  int len;
  //struct zx_elem_s* kid;
  switch (x->g.tok) {
  case zx_root_ELEM:
    len = 0;
    if (c->inc_ns_len)
      len += zx_len_inc_ns(c, &pop_seen);
    for (kid = x->kids; kid; kid = ((struct zx_elem_s*)(kid->g.n)))
      len += zx_LEN_WO_any_elem(c, kid);
    break;
  case ZX_TOK_DATA:
    return x->g.len;
  case zx_ds_Signature_ELEM:
    if (x == c->exclude_sig)
      return 0;
    /* fall thru */
  default:
    if (x->g.s) {
      /*    <   ns:elem    >                                    </  ns:elem    >    / */
      len = 1 + x->g.len + 1 + ((x->kids || !c->enc_tail_opt) ? (2 + x->g.len + 1) : 1);
    } else { /* Construct elem string from tok */
      if (!(el_tok = zx_get_el_tok(x)))
	return 0;
      len = strlen(el_tok->name);
      DD("ns prefix_len=%d el_len=%d", x->ns->prefix_len, len);
      /*    <   ns                  :   elem  >                                    </  ns                  :   elem  >    / */
      len = 1 + x->ns->prefix_len + 1 + len + 1 + ((x->kids || !c->enc_tail_opt) ? (2 + x->ns->prefix_len + 1 + len + 1) : 1);
    }
    D_LEN("%06x ** tag start: %d", x->g.tok, len);
    len += zx_len_xmlns_if_not_seen(c, x->ns, &pop_seen);
    D_LEN("%06x after xmlns: %d", x->g.tok, len);

    if (c->inc_ns_len)
      len += zx_len_inc_ns(c, &pop_seen);
    D_LEN("%06x after inc_ns: %d", x->g.tok, len);

    for (attr = x->attr; attr; attr = (struct zx_attr_s*)attr->g.n) {
      if (attr->name) {
	/*    sp   name             ="                "   */
	len += 1 + attr->name_len + 2 + attr->g.len + 1;
      } else { /* Construct elem string from tok */
	if (!(at_tok = zx_get_at_tok(attr)))
	  return 0;
	if (attr->ns)
	  len += attr->ns->prefix_len + 1;
	len += strlen(at_tok->name);
	/*     sp ="                "   */
	len += 1+ 2 + attr->g.len + 1;
      }
      len += zx_len_xmlns_if_not_seen(c, attr->ns, &pop_seen);
    }
    D_LEN("%06x after attrs: %d", x->g.tok, len);

    for (kid = x->kids; kid; kid = ((struct zx_elem_s*)(kid->g.n)))
      len += zx_LEN_WO_any_elem(c, kid);
    
    break;
  }
  zx_pop_seen(pop_seen);
  D_LEN("%06x final: %d", x->g.tok, len);
  return len;
}

/* Called by:  TXENC_SO_ELNAME, zx_ENC_WO_any_elem */
static char* zx_attr_wo_enc(char* p, struct zx_attr_s* attr)
{
  struct zx_at_tok* at_tok;
  ZX_OUT_CH(p, ' ');
  if (attr->name) {
    ZX_OUT_MEM(p, attr->name, attr->name_len);
  } else { /* Construct elem string from tok */
    if (!(at_tok = zx_get_at_tok(attr)))
      return p;
    if (attr->ns) {
      ZX_OUT_MEM(p, attr->ns->prefix, attr->ns->prefix_len);
      ZX_OUT_CH(p, ':');
    }
    ZX_OUT_MEM(p, at_tok->name, strlen(at_tok->name));
  }
  ZX_OUT_CH(p, '=');
  ZX_OUT_CH(p, '"');
  ZX_OUT_MEM(p, attr->g.s, attr->g.len);
  ZX_OUT_CH(p, '"');
  return p;
}

/*() Render element into string. The XML attributes and elements are
 * processed in wire order by starting with kids root and chasing g.n pointers.
 * This is what you want for validating signatures on other people's XML documents.
 * The lists are assumed to be in forward order, i.e. opposite
 * of what zx_dec_zx_root() and zx_DEC_elem() return. You should call
 * zx_reverse_elem_lists() if needed. */

/* Called by:  main x2, zx_EASY_ENC_elem, zx_ENC_WO_any_elem x2 */
char* zx_ENC_WO_any_elem(struct zx_ctx* c, struct zx_elem_s* x, char* p)
{
  struct zx_el_tok* el_tok;
  struct zx_ns_s* pop_seen = 0;
  struct zx_attr_s* attr;
  struct zx_elem_s* kid;
#if D_LEN_ENA
  char* b = p;
#endif
  switch (x->g.tok) {
  case zx_root_ELEM:
    if (c->inc_ns)
      zx_add_inc_ns(c, &pop_seen);
    p = zx_enc_seen(p, pop_seen);
    for (kid = x->kids; kid; kid = (struct zx_elem_s*)kid->g.n)
      p = zx_ENC_WO_any_elem(c, kid, p);
    break;
  case ZX_TOK_DATA:
    ZX_OUT_STR(p, x);
    break;
  case zx_ds_Signature_ELEM:
    if (x == c->exclude_sig)
      return p;
    /* fall thru */
  default:
    ZX_OUT_CH(p, '<');
    if (x->g.s) {
      ZX_OUT_MEM(p, x->g.s, x->g.len);
    } else { /* Construct elem string from tok */
      if (!(el_tok = zx_get_el_tok(x)))
	return p;
      ZX_OUT_MEM(p, x->ns->prefix, x->ns->prefix_len);
      ZX_OUT_CH(p, ':');
      ZX_OUT_MEM(p, el_tok->name, strlen(el_tok->name));
    }
    D_LEN("%06x   ** tag start: %d", x->g.tok, p-b);
    zx_add_xmlns_if_not_seen(c, x->ns, &pop_seen);
    if (c->inc_ns)
      zx_add_inc_ns(c, &pop_seen);
    D_LEN("%06x   after inc_ns: %d", x->g.tok, p-b);
    zx_see_attr_ns(c, x->attr, &pop_seen);
    p = zx_enc_seen(p, pop_seen);
    D_LEN("%06x   after seen ns: %d", x->g.tok, p-b);

    for (attr = x->attr; attr; attr = (struct zx_attr_s*)attr->g.n)
      p = zx_attr_wo_enc(p, attr);

    if (x->kids || !c->enc_tail_opt) {
      ZX_OUT_CH(p, '>');
      D_LEN("%06x   after attrs: %d", x->g.tok, p-b);
      
      for (kid = x->kids; kid; kid = (struct zx_elem_s*)kid->g.n)
	p = zx_ENC_WO_any_elem(c, kid, p);
      D_LEN("%06x   after kids: %d", x->g.tok, p-b);

      ZX_OUT_CH(p, '<');
      ZX_OUT_CH(p, '/');
      if (x->g.s) {
	ZX_OUT_MEM(p, x->g.s, x->g.len);
      } else { /* Construct elem string from tok */
	ZX_OUT_MEM(p, x->ns->prefix, x->ns->prefix_len);
	ZX_OUT_CH(p, ':');
	ZX_OUT_MEM(p, el_tok->name, strlen(el_tok->name));
      }
    } else {
      ZX_OUT_CH(p, '/');  /* Also an XML legal way to terminate an empty tag, e.g. <ns:foo/> */
    }
    ZX_OUT_CH(p, '>');
  }
  zx_pop_seen(pop_seen);
  D_LEN("%06x   final: %d", x->g.tok, p-b);
  return p;
}

/*(i) Render any element in wire order, as often needed in validating canonicalizations.
 * See also: zx_easy_enc_elem_opt() */

/* Called by:  zx_easy_enc_elem_opt, zx_easy_enc_elem_sig, zxsig_sign, zxsig_validate x2 */
struct zx_str* zx_EASY_ENC_elem(struct zx_ctx* c, struct zx_elem_s* x)
{
  int len;
  char* buf;
  char* p;
  if (!c || !x) {
    ERR("zx_easy_enc_elem called with NULL argument %p (programmer error)", x);
    return 0;
  }
  len = zx_LEN_WO_any_elem(c, x);
  buf = ZX_ALLOC(c, len+1);
  p = zx_ENC_WO_any_elem(c, x, buf);
  if (p != buf+len) {
    ERR("Encoded length(%d) does not match computed length(%d). ED(%.*s)", ((int)(p-buf)), len, ((int)(p-buf)), buf);
    len = p-buf;
  }
  buf[len] = 0;
  return zx_ref_len_str(c, len, buf);
}

/* EOF -- zxlibenc.c */
