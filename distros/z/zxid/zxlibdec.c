/* zxlibdec.c  -  Utility functions for generated decoders
 * Copyright (c) 2013 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
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
 * 27.10.2010, forked from zxlib.c, re-engineered namespace handling --Sampo
 * 20.11.2010, reengineered for unified simplifed decoder --Sampo
 * 30.11.2013, fixed bondary condition of loop looking one past end (found by valgrind) --Sampo
 */

#include "platform.h"  /* needed on Win32 for snprintf(), va_copy() et al. */

//#include <pthread.h>
#include <memory.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "errmac.h"
#include "zx.h"
#include "c/zx-data.h"
#include "c/zx-ns.h"

/*() Format error message describing an XML parse error. The buf argument
 * should be at leaset 256 bytes for satisfactory results. */

/* Called by:  covimp_test, zxid_wsp_validate */
int zx_format_parse_error(struct zx_ctx* ctx, char* buf, int siz, char* logkey)
{
  int at, end, start, len;
  end = ctx->lim - ctx->bas;
  at = MIN(ctx->p - ctx->bas, end);
  start = MAX(0,at-30);
  len = MIN(at+30, end) - start;    
  len = snprintf(buf, siz, "%s: Parse error at char %d/%d (prev char, char, next char: 0x%02x 0x%02x 0x%02x)\n%.*s\n%.*s^\n", logkey, at, end, at > 0 ? ctx->p[-1]:0, ctx->p[0], at < end ? ctx->p[1]:0, len, ctx->bas + start, at-start, "-----------------------------------------------");
  buf[siz-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  return len;
}

/* Called by:  covimp_test, zx_dec_attr_val x2, zx_scan_elem_end, zx_scan_pi_or_comment, zx_scan_xmlns x2 */
void zx_xml_parse_err(struct zx_ctx* c, char quote, const char* func, const char* msg)
{
  const char* errloc = MAX(c->p - 20, c->bas);
  ERR("%s: %s: char(%c) pos=%d (%.*s)", func, msg, quote,
      ((int)(c->p - c->bas)), (int)MIN(c->lim - errloc, 40), errloc);
}

/* Called by:  zx_xmlns_decl */
void zx_xml_parse_dbg(struct zx_ctx* c, char quote, const char* func, const char* msg)
{
  const char* errloc = MAX(c->p - 20, c->bas);
  D("%s: %s: char(%c) pos=%d (%.*s)", func, msg, quote,
    ((int)(c->p - c->bas)), (int)MIN(c->lim - errloc, 40), errloc);
}

/* --------------------- D e c o d e r ---------------------- */

/* Called by:  zx_DEC_elem */
static int zx_scan_data(struct zx_ctx* c, struct zx_elem_s* el)
{
  struct zx_str* ss;
  const char* d = c->p;
  if (*c->p)
    ZX_LOOK_FOR(c,'<');
  ss = ZX_ZALLOC(c, struct zx_str);
  ss->len = c->p - d;
  ss->s = (char*)d;
  ss->tok = ZX_TOK_DATA;
  ss->n = &el->kids->g;
  el->kids = (struct zx_elem_s*)ss;
  return 1;

 look_for_not_found:
  /*zx_xml_parse_err(c, '<', (const char*)__FUNCTION__, "look for not found");  -- Causes bogus warning in end of buffer. */
  return 0;
}

/* Called by:  zx_DEC_elem */
static int zx_scan_pi_or_comment(struct zx_ctx* c)
{
  const char* name;
  char quote;

  switch (*c->p) {
  case '?':  /* processing instruction <?xml ... ?> */
    name = c->p-1;
    DD("Processing Instruction detected (%.*s)", 5, name);
    while (1) {
      quote = '>';
      ZX_LOOK_FOR(c,'>');
      if (c->p[-1] == '?')
	break;
    }
    ++c->p;
    DD("Processing Instruction scanned (%.*s)", c->p-name, name);
    /*ZX_PI_DEC_EXT(pi);*/
    return 0;
  case '!':  /* comment <!-- ... --> or <!DOCTYPE...> */
    name = c->p-1;
    if (!memcmp(c->p+1, "DOCTYPE", sizeof("DOCTYPE")-1)) {
      D("DOCTYPE detected (%.*s)", 60, c->p-1);
      ZX_LOOK_FOR(c,'>');
      ++c->p;
      D("DOCTYPE scanned (%.*s)", ((int)(c->p-name)), name);
      return 0;
    }
    c->p += 2;
    if (c->p[-1] != '-' || c->p[0] != '-') {
      c->p -= 3;
      return 1;
    }
    D("Comment detected (%.*s)", 8, name);
    c->p += 2;
    while (1) {
      quote = '>';
      ZX_LOOK_FOR(c,'>');
      if (c->p[-2] == '-' && c->p[-1] == '-') {
	break;
      }
    }
    ++c->p;
    D("Comment scanned (%.*s)", ((int)(c->p-name)), name);
    /*ZX_COMMENT_DEC_EXT(comment);*/
    return 0;
  }
  return 1;
 look_for_not_found:
  zx_xml_parse_err(c, quote, (const char*)__FUNCTION__, "look for not found");
  return 1;
}

/*() Assuming current c->p points to a name, scan until end of the name.
 * Called from innards for dec-templ.c for CSE. Leaves c->p pointing to char after name. */

/* Called by:  zx_el_lookup */
static const char* zx_scan_elem_start(struct zx_ctx* c, const char* func)
{
  const char* name = c->p;
  int len = strcspn(c->p, " >/\n\r\t");
  c->p += len;
  /*for (++c->p; c->p<c->lim && !ONE_OF_6(*c->p, ' ', '>', '/', '\n', '\r', '\t'); ++c->p) ;*/
  if (c->p < c->lim)
    return name;
  ERR("%s: Incomplete %.*s", func, ((int)(c->lim-name)), name);
  return 0;
}

/*() End of tag detection called from innards for dec-templ.c for CSE. */

/* Called by:  zx_DEC_elem */
static int zx_scan_elem_end(struct zx_ctx* c, const char* start, const char* func)
{
  const char* name;
  const char* errloc;
  ++c->p;
  if (c->p >= c->lim)
    goto look_for_not_found;
  name = c->p;
  ZX_LOOK_FOR(c,'>');
  if (memcmp(start?start:"", name, c->p-name))	{
    errloc = MAX(c->p - 20, c->bas);
    ERR("%s: Mismatching close tag(%.*s) pos=%d (%.*s)", func, ((int)(c->p-name)), name, ((int)(c->p - c->bas)), (int)MIN(c->lim - errloc, 40), errloc);
    ++c->p;
    return 0;
  }
  return 1;

look_for_not_found:
  zx_xml_parse_err(c, '>', func, "char not found");
  return 0;
}

/*() Check the child element ordering of a token against schema.
 * Returns 0 if ordering is good. If ordering is bad, returns index to
 * the offending child element. This check does not verify whether all
 * mandatory child elements are present - it merely checks that the
 * order is right.
 *
 * N.B. Check c/zx-elems.c for the tables that show the ordering (tables
 * were generated from schema so hand editing them is not recommended). */

/* Called by:  zx_reverse_elem_lists */
static int zx_chk_el_ord(struct zx_elem_s* x)
{
  int i,j,n;
  struct zx_el_tok* et;
  struct zx_el_tok* ef;
  struct zx_el_desc* ed = zx_el_desc_lookup(x->g.tok);
  if (!ed)
    return 0;
  x = x->kids;
  for (n = i = j = 0; x; i = j, x = (struct zx_elem_s*)x->g.n) {
    ++n;
    if (x->g.tok == ZX_TOK_DATA)
      continue;
    for (j = i; ed->el_order[j] != ZX_TOK_NOT_FOUND; ++j)
      if (x->g.tok == ed->el_order[j]) {
	if ((errmac_debug & ERRMAC_DEBUG_MASK)>2) {
	  et = zx_el_tab + (x->g.tok & ZX_TOK_TOK_MASK);
	  ef = zx_el_tab + MINMAX(ed->tok & ZX_TOK_TOK_MASK, 0, zx__ELEM_MAX);
	  D("Right: Known <%s> tok(0x%06x) as %d. child of <%s> tok(0x%06x) (%d,%d)", et->name, x->g.tok, n, ef->name, ed->tok, i, j);
	}
	break;
      }
    if (ed->el_order[j] == ZX_TOK_NOT_FOUND) {
      if (x->g.tok == ZX_TOK_NOT_FOUND || !IN_RANGE(x->g.tok & ZX_TOK_TOK_MASK, 0, zx__ELEM_MAX)) {
	ef = zx_el_tab + MINMAX(ed->tok & ZX_TOK_TOK_MASK, 0, zx__ELEM_MAX);
	/* *** ideally this should be flagged as error, but problem is that we
	 *     permit freeform bodies so there are a lot of unknown tokens like this. */
	D("Unknown <%.*s> token(0x%06x) as %d. child of <%s> 0x%06x (%d,%d)", x->g.len, x->g.s, x->g.tok, n, ef->name, ed->tok, i, j);
      } else {
	et = zx_el_tab + (x->g.tok & ZX_TOK_TOK_MASK);
	ef = zx_el_tab + MINMAX(ed->tok & ZX_TOK_TOK_MASK, 0, zx__ELEM_MAX);
	ERR("WRONG: Known <%s> tok(0x%06x) in wrong place as %d. child of <%s> tok(0x%06x) (%d,%d)", et->name, x->g.tok, n, ef->name, ed->tok, i, j);
	// *** we should really dump the whole message into log
      }
      return n;
    }
  }
  return 0;
}

/*() Insert an attribute to element's attribute list in canoncically sorted
 * place, i.e. no namespace sorts first, namespaced attribute sort by
 * namespace URI (not namespace prefix). Assumes the attribute
 * list has so far been sorted. Used as part of insertion sort. */

/* Called by:  zx_reverse_elem_lists */
struct zx_attr_s* zx_ord_ins_at(struct zx_elem_s* x, struct zx_attr_s* in_at)
{
  struct zx_attr_s* at;
  struct zx_attr_s** atp;
  const char* at_name;
  const char* in_at_name;
  const char* p;
  int res, at_name_len, in_at_name_len;

  atp = &x->attr;
  for (at = x->attr; at; atp = (struct zx_attr_s**)&at->g.n, at = (struct zx_attr_s*)at->g.n) {
    if (!in_at->ns && IN_RANGE((in_at->g.tok & ZX_TOK_NS_MASK)>>ZX_TOK_NS_SHIFT, 1, zx__NS_MAX))
      in_at->ns = zx_ns_tab + ((in_at->g.tok & ZX_TOK_NS_MASK)>>ZX_TOK_NS_SHIFT);
    if (in_at->ns) {
      if (!at->ns && IN_RANGE((at->g.tok & ZX_TOK_NS_MASK)>>ZX_TOK_NS_SHIFT, 1, zx__NS_MAX))
	at->ns = zx_ns_tab + ((at->g.tok & ZX_TOK_NS_MASK)>>ZX_TOK_NS_SHIFT);
      if (at->ns) {
	if (at->ns != in_at->ns) {
	  res = memcmp(at->ns->url, in_at->ns->url, MIN(at->ns->url_len, in_at->ns->url_len));
	  if (res > 0)
	    break;
	  if (res < 0)
	    continue;
	  if (at->ns->url_len > in_at->ns->url_len)
	    break;
	  if (at->ns->url_len < in_at->ns->url_len)
	    continue;
	}
      } else
	continue;  /* at has no namespace, sorts earlier than in_at that has namespace. */
    } else {
      if (at->ns)
	break;  /* No namespace sorts before namespace */
    }
    /* Neither has namespace, or namespaces were equal: sort by attribute name */

    if (at->name) {
      at_name = at->name;
      at_name_len = at->name_len;
      p = memchr(at_name, ':', at_name_len);
      if (p) {
	at_name_len -= 1 + p - at_name;
	at_name = p+1;
      }
    } else {
      if (IN_RANGE((at->g.tok & ZX_TOK_TOK_MASK), 0, zx__ATTR_MAX)) {
	at_name = (char*)zx_at_tab[at->g.tok & ZX_TOK_TOK_MASK].name;
	at_name_len = strlen(at_name);
      } else {
	ERR("Attribute supplied without name and tok 0x%06x is out of range", at->g.tok);
	break;
      }
    }
    if (in_at->name) {
      in_at_name = in_at->name;
      in_at_name_len = in_at->name_len;
      p = memchr(in_at_name, ':', in_at_name_len);
      if (p) {
	in_at_name_len -= 1 + p - in_at_name;
	in_at_name = p+1;
      }
    } else {
      if (IN_RANGE((in_at->g.tok & ZX_TOK_TOK_MASK), 0, zx__ATTR_MAX)) {
	in_at_name = (char*)zx_at_tab[in_at->g.tok & ZX_TOK_TOK_MASK].name;
	in_at_name_len = strlen(in_at_name);
      } else {
	ERR("Attribute supplied without name and tok 0x%06x is out of range", in_at->g.tok);
	break;
      }
    }
    res = memcmp(at_name, in_at_name, MIN(at_name_len, in_at_name_len));
    if (res > 0 || !res && at_name_len >= in_at_name_len)
      break;
  }
  in_at->g.n = &at->g;
  *atp = in_at;
  return in_at;
}

/*() Since kids lists of elements are usually built by adding
 * nodes at the root of the list, they end up being in reverse order.
 * Thus we need to reverse them to get them to right order. We
 * take this opportunity to also check that the ordering is correct
 * and also to sort the XML attributes.
 * Called from dec-templ.c for CSE elimination.
 * N.B. This function is not recursive: only one level is reversed.
 * N.B2. Although decoder returns lists in reverse order, we try
 * to maintain as common representation the forward ordered list. */

/* Called by:  zx_DEC_elem, zxenc_pubkey_enc, zxenc_symkey_enc, zxid_ac_desc, zxid_add_env_if_needed, zxid_add_fed_tok2epr, zxid_ar_desc, zxid_az_soap, zxid_contact_desc, zxid_idp_sso_desc, zxid_key_desc, zxid_key_info, zxid_mk_a7n, zxid_mk_authn_req, zxid_mk_az, zxid_mk_az_cd1, zxid_mk_di_req_svc, zxid_mk_mni, zxid_mk_saml_resp, zxid_mk_xac_az, zxid_mk_xacml_resp, zxid_mk_xacml_simple_at, zxid_mni_desc, zxid_nimap_desc, zxid_org_desc, zxid_slo_desc, zxid_sp_meta, zxid_sp_sso_desc, zxid_sso_desc, zxid_wsc_prep, zxid_wsf_decor x2, zxid_wsp_decorate, zxsig_sign x3 */
void zx_reverse_elem_lists(struct zx_elem_s* x)
{
  struct zx_elem_s* iternode;
  struct zx_attr_s* in_at;
  struct zx_attr_s* at_next;

  iternode = x->kids;
  REVERSE_LIST_NEXT(x->kids, iternode, g.n);

  zx_chk_el_ord(x);
  
  /* Insertion sort attribute list in alphabetical order 1st by NS URI, then by attribute name */

  in_at = x->attr;
  if (!in_at || !in_at->g.n)
    return;  /* Nothing to sort (no attributes or just one attribute) */

  at_next = in_at;    /* Start insertion sort by considering first to already be in place. */
  in_at = (struct zx_attr_s*)in_at->g.n;
  at_next->g.n = 0;

  for (; in_at; in_at = at_next) {
    at_next = (struct zx_attr_s*)in_at->g.n;
    zx_ord_ins_at(x, in_at);
  }
}

/*() Called from dec-templ.c for CSE elimination. */

/* Called by:  zx_attr_lookup */
static const char* zx_dec_attr_val(struct zx_ctx* c, const char* func)
{
  const char* data;
  char quote = '=';
  ZX_LOOK_FOR(c,'=');
  
  ++c->p;
  if (c->p >= c->lim)
    goto look_for_not_found;
  if (!ONE_OF_2(*c->p, '"', '\'')) {
    zx_xml_parse_err(c, *c->p, func, "zx_dec_attr_val: Did not find expected quote char (single or double), saw");
    return 0;
  }
  quote = *c->p;
  ++c->p;
  if (c->p >= c->lim)
    goto look_for_not_found;
  data = c->p;	
  ZX_LOOK_FOR(c, quote);
  return data;
 look_for_not_found:
  zx_xml_parse_err(c, quote, func, "zx_dec_attr_val: char not found");
  return 0;
}

/*() Tokenize an attribute.
 * Lookup functions to convert a namespace qualified string to an integer token.
 * The att2tok() functions come from xsd2sg.pl code generation via gperf.
 * Internal function CSE.
 * Starts with c->p pointing to beginning of attribute (with ns prefix, if any) */

/* Called by:  zx_DEC_elem */
static int zx_attr_lookup(struct zx_ctx* c, struct zx_elem_s* x)
{
  const char* prefix;
  const char* name;
  const char* lim;
  const char* data;
  const char* p;
  struct zx_ns_s* ns;
  const struct zx_at_tok* zt;
  struct zx_attr_s* attr;

  ZX_SKIP_WS(c, ZX_TOK_ATTR_ERR);
  if (ONE_OF_2(*c->p, '>', '/'))
    return ZX_TOK_NO_ATTR;

  attr = ZX_ZALLOC(c, struct zx_attr_s);
  attr->name = (char*)(name = c->p);
  if (!(data = zx_dec_attr_val(c, "attr_lookup"))) {
    ZX_FREE(c, attr);
    return ZX_TOK_ATTR_ERR;
  }
  attr->name_len = data - 2 - attr->name;
  attr->g.s = (char*)data;
  attr->g.len = c->p - attr->g.s;
  lim = attr->g.s - 2;
  /*attr->g.tok = ZX_TOK_NS_NOT_FOUND;  / * Start with unknown namespace. */

  p = memchr(name, ':', lim-name);  /* look for namespace prefix */
  if (p) {
    prefix = name;
    name = p+1;
  } else
    prefix = 0;

  /* Look for namespace declaration. Skip as these were prescanned (see above in this file). */
  if (prefix) {
    if ((name-1)-prefix == sizeof("xmlns")-1 && !memcmp("xmlns", prefix, sizeof("xmlns")-1)) {
      ZX_FREE(c, attr);
      zx_xmlns_detected(c, x, data);
      return ZX_TOK_XMLNS;
    }
    ns = zx_prefix_seen_whine(c, (name-1)-prefix, prefix, "attr_lookup", 0);
    if (ns) {
      attr->ns = ns;
      if (ns->master)
	ns = ns->master;
      if (ns > c->ns_tab && ns - c->ns_tab < c->n_ns) {
	attr->g.tok = (ns - c->ns_tab) << ZX_TOK_NS_SHIFT;
      } else {
	INFO("Non-native prefix(%.*s) attr(%.*s) in elem(%.*s)", ((int)((name-1)-prefix)), prefix, attr->name_len, attr->name, x->g.len, x->g.s);
      }
    } else {
      INFO("Undeclared (and unknown) prefix(%.*s) attr(%.*s) in elem(%.*s)", ((int)((name-1)-prefix)), prefix, attr->name_len, attr->name, x->g.len, x->g.s);
    }
  } else {
    if (lim-name == sizeof("xmlns")-1 && !memcmp("xmlns", name, sizeof("xmlns")-1)) {
      ZX_FREE(c, attr);
      zx_xmlns_detected(c, x, data);
      return ZX_TOK_XMLNS;
    }
    /* Most attributes are namespaceless (or have containing element's namespace). */
  }
  
  attr->g.n = &x->attr->g;
  x->attr = attr;
  zt = zx_attr2tok(name, lim-name);
  if (zt)
    return attr->g.tok |= (zt - zx_at_tab);
  return attr->g.tok |= ZX_TOK_ATTR_NOT_FOUND;
}

/*() Given token, find element descriptor. */

/* Called by:  zx_DEC_elem, zx_ENC_WO_any_elem, zx_LEN_WO_any_elem, zx_chk_el_ord, zx_el_lookup, zx_new_elem */
struct zx_el_desc* zx_el_desc_lookup(int tok)
{
  struct zx_el_desc* ed;
  if (tok == ZX_TOK_NOT_FOUND)
    return 0;
  if (!IN_RANGE(tok & ZX_TOK_TOK_MASK, 0, zx__ELEM_MAX)) {
    ERR("out of range token 0x%06x", tok);
    return 0;
  }
  for (ed = zx_el_tab[tok & ZX_TOK_TOK_MASK].n; ed; ed = ed->n)
    if (ed->tok == tok)
      return ed;
  ERR("unknown token 0x%06x", tok);
  return 0;
}

/*() Lookup function to convert a namespace qualified string to an integer token.
 * First namespace is looked up and then the element in namespace specific hash.
 * The hash functions come from xsd2sg.pl code generation via gperf. */

/* Called by:  zx_DEC_elem */
static struct zx_elem_s* zx_el_lookup(struct zx_ctx* c, struct zx_elem_s* x, struct zx_ns_s** pop_seenp)
{
  struct zx_elem_s* el;
  struct zx_ns_s* ns;
  struct zx_ns_s* master_ns;
  const struct zx_el_tok* zt;
  const struct zx_el_desc* ed;
  const char* full_name;
  const char* name;
  const char* prefix;
  const char* p;
  int tok;

  if (!(name = zx_scan_elem_start(c, (const char*)__FUNCTION__)))
    return 0;
  
  *pop_seenp = zx_scan_xmlns(c);    /* Prescan namespaces so token can be correctly recognized. */

  full_name = name;
  p = memchr(name, ':', c->p-name); /* look for namespace prefix */
  if (p) {
    prefix = name;
    name = p+1;
  } else
    prefix = 0;

  ns = zx_prefix_seen_whine(c, prefix ? (name-1)-prefix : 0, prefix, (const char*)__FUNCTION__,1);
  master_ns = ns->master?ns->master:ns;
  zt = zx_elem2tok(name, c->p - name);
  if (zt) {
    tok = ((master_ns - c->ns_tab) << ZX_TOK_NS_SHIFT) | (zt - zx_el_tab);
    ed = zx_el_desc_lookup(tok);
    if (ed) {
      el = ZX_ALLOC(c, ed->siz);
      ZERO(el, ed->siz);
    } else
      goto unknown_el;
  } else {
unknown_el:
    // Unknown element warnings are quite frequent and just clutter the logs. Downgrade.
    //INFO("Unknown element <%.*s>, child of <%.*s>", ((int)(c->p - full_name)), full_name, x->g.len, x->g.s);
    D("Unknown element <%.*s>, child of <%.*s>", ((int)(c->p - full_name)), full_name, x->g.len, x->g.s);
    el = ZX_ZALLOC(c, struct zx_elem_s);
    tok = ZX_TOK_NOT_FOUND;
  }

  el->g.tok = tok;
  el->ns = ns;
  el->g.s = (char*)full_name;
  el->g.len = c->p - full_name;
  el->g.n = &x->kids->g;
  x->kids = el;
  return el;
}

/*() Element Decoder. When per element decoder is called, the c->p
 * will point to just past the element name. The element has already
 * been allocated to the correct size and the namespace prescan has
 * already been done (except when called from zx_dec_zx_root()). */

/* Called by:  zx_DEC_elem, zx_dec_zx_root */
void zx_DEC_elem(struct zx_ctx* c, struct zx_elem_s* x)
{
  int tok MAYBE_UNUSED;  /* Unused in zx_DEC_root() */
  struct zx_el_desc* ed = zx_el_desc_lookup(x->g.tok);
  struct zx_elem_s* el;
  struct zx_ns_s* pop_seen;

  if (x->g.tok != zx_root_ELEM) {
    /* The tag name has already been detected. Process attributes until '>' */
    
    for (; c->p < c->lim; ++c->p) {
      tok = zx_attr_lookup(c, x);
      switch (tok) {
      case ZX_TOK_XMLNS: break;
      case ZX_TOK_ATTR_NOT_FOUND: break;
      case ZX_TOK_ATTR_ERR: return; 
      case ZX_TOK_NO_ATTR: goto no_attr;
      default:
	if (!ed || !ed->at_dec(c, x)) { /* element specific attribute processing */
	  D("Known attribute(%.*s) tok=0x%x in wrong context(%.*s)", x->attr->name_len, x->attr->name, x->attr->g.tok, x->g.len, x->g.s);
	}
      }
    }
no_attr:
    if (c->p < c->lim) {
      ++c->p;
      if (c->p < c->lim && c->p[-1] == '/' && c->p[0] == '>') {  /* <Tag/> without content */
	++c->p;
	goto out;
      }
    }
  }

  /* Process contents until '</' or end of string nul */
  
  while (1) {
  next_elem:
    if (c->p >= c->lim)
      goto out;
    /*ZX_SKIP_WS(c,x);    DO NOT SQUASH WHITESPACE! EXC-CANON NEEDS IT. */
    if (*c->p == '<') {
    potential_tag:
      ++c->p;
      if (c->p >= c->lim)
	goto out;
      switch (*c->p) {
      case '?':  /* processing instruction <?xml ... ?> */
      case '!':  /* comment <!-- ... --> */
	if (zx_scan_pi_or_comment(c))
	  break;
	goto next_elem;
      case '/':  /* close tag */
	if (!zx_scan_elem_end(c, ((struct zx_elem_s*)x)->g.s, (const char*)__FUNCTION__))
	  return;
	/* Legitimate close tag. Normal exit from this function. */
	++c->p;
	goto out;
      default:
	if (AZaz_(*c->p)) {
	  el = zx_el_lookup(c, (struct zx_elem_s*)x, &pop_seen);
	  if (!el)
	    return;
	  zx_DEC_elem(c, el);  /* read the kid on syntactic level */
	  /* element specific subelement processing: assign the kid to correct struct field */
	  if (!ed || !ed->el_dec(c, x)) {
	    if (el->g.tok != ZX_TOK_NOT_FOUND) {
	      D("Known element(%.*s) tok=0x%x in wrong context(%.*s)", el->g.len, el->g.s, el->g.tok, x->g.len, x->g.s);
	      el->g.tok = ZX_TOK_NOT_FOUND;
	    }
	  }
	  zx_pop_seen(pop_seen);
	  if (c->top1 && x->g.tok == zx_root_ELEM)  /* to stop parse after single <e:Envelope> */
	    goto out;
	  goto next_elem;
	}
      }
      /* false alarm <, fall thru */
    }
    if (!zx_scan_data(c, (struct zx_elem_s*)x))
      return;
    goto potential_tag;
  }
 out:
  zx_reverse_elem_lists((struct zx_elem_s*)x);
}

/*() Prepare a context for decoding XML. The decoding operation will not
 * alter the underlying data (e.g. no nuls are inserted, not even temporarily).
 * N.B. Often you would wrap this in locks, like
 *   LOCK(cf->ctx->mx, "valid");
 *   zx_prepare_dec_ctx(cf->ctx, zx_ns_tab, n_ns, ss->s, ss->s + ss->len);
 *   r = zx_DEC_elem(cf->ctx, &r->gg);
 *   UNLOCK(cf->ctx->mx, "valid");
 * or just see zx_dec_zx_root()
 */

/* Called by:  covimp_test, zx_dec_zx_root */
void zx_prepare_dec_ctx(struct zx_ctx* c, struct zx_ns_s* ns_tab, int n_ns, const char* start, const char* lim)
{
  zx_reset_ns_ctx(c);
  c->ns_tab = ns_tab;
  c->n_ns = n_ns;
  c->bas = c->p = start;
  c->lim = lim;
}

/*(i) Decode arbitary xml with zx_ns_tab set of namespaces and parsers.
 * The resulting data structure has linked lists in *inverted* order,
 * i.e. last tag is first element of the list. */

/* Called by:  main x6, sig_validate, test_ibm_cert_problem, zxid_add_env_if_needed x2, zxid_dec_a7n, zxid_decode_redir_or_post, zxid_decrypt_nameid, zxid_decrypt_newnym, zxid_di_query, zxid_find_epr, zxid_gen_boots, zxid_get_ses_sso_a7n x2, zxid_idp_soap_parse, zxid_mk_sa_attribute_ss, zxid_mk_xacml_simple_at, zxid_parse_meta, zxid_print_session, zxid_reg_svc, zxid_soap_call_raw, zxid_sp_soap_parse, zxid_str2a7n, zxid_str2nid, zxid_str2token, zxid_wsp_validate */
struct zx_root_s* zx_dec_zx_root(struct zx_ctx* c, int len, const char* start, const char* func)
{
  struct zx_root_s* r = zx_NEW_root(c, 0);
  LOCK(c->mx, func);
  zx_prepare_dec_ctx(c, zx_ns_tab, sizeof(zx_ns_tab)/sizeof(struct zx_ns_s), start, start + len);
  zx_DEC_elem(c, &r->gg);
  UNLOCK(c->mx, func);
  return r;
}

/* EOF -- zxlibdec.c */
