/* zxidpool.c  -  Attribute handling
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidpool.c,v 1.7 2009-11-24 23:53:40 sampo Exp $
 *
 * 4.9.2009, forked from zxidsimp.c --Sampo
 * 1.2.2010, added ses_to methods --Sampo
 * 21.5.2010, added local attribute authority and local EPRs feature --Sampo
 */

#include "platform.h"

#include <memory.h>
#include <string.h>
#include <errno.h>

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zx-sa-data.h"

/*(i) Convert attributes from (session) pool to LDIF entry, applying OUTMAP.
 * This is used by zxid_simple() SSO successful code to generate return
 * value, but can also be used later to regenerate the LDIF
 * given the pool. See zxid_ses_to_pool() for how to create the pool.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by: */
static struct zx_str* zxid_pool_to_ldif(zxid_conf* cf, struct zxid_attr* pool)
{
  char* p;
  char* name;
  char* idpnid = 0;
  char* affid = 0;
  int len = 0, name_len;
  struct zxid_map* map;
  struct zxid_attr* at;
  struct zxid_attr* av;
  struct zx_str* ss;
  
  /* Length computation pass */

  for (at = pool; at; at = at->n) {
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL) {
	D("attribute(%s) filtered out by del rule in OUTMAP", at->name);
	continue;
      }
      at->map_val = zxid_map_val(cf, 0, 0, map, at->name, at->val);
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name_len = strlen(map->dst);
      } else {
	name_len = strlen(at->name);
      }
      len += name_len + sizeof(": \n")-1 + at->map_val->len;
      DD("len1=%d", len);

      for (av = at->nv; av; av = av->n) {
	av->map_val = zxid_map_val(cf, 0, 0, map, at->name, av->val);
	len += name_len + sizeof(": \n")-1 + av->map_val->len;
	DD("len2=%d", len);
      }
    } else {
      name_len = strlen(at->name);
      len += name_len + sizeof(": \n")-1 + (at->val?strlen(at->val):0);
      DD("len3=%d name_len=%d name(%s)", len, name_len, at->name);
      for (av = at->nv; av; av = av->n) {
	len += name_len + sizeof(": \n")-1 + (av->val?strlen(av->val):0);
	DD("len4=%d", len);
      }
    }

    if (!strcmp(at->name, "idpnid")) idpnid = at->val;
    else if (!strcmp(at->name, "affid")) affid = at->val;
  }
  len += sizeof("dn: idpnid=,affid=\n")-1 + (idpnid?strlen(idpnid):0) + (affid?strlen(affid):0);
  DD("lenFin=%d", p-ss->s);
  
  /* Attribute rendering pass */

  ss = zx_new_len_str(cf->ctx, len);
  p = ss->s;

  memcpy(p, "dn: idpnid=", sizeof("dn: idpnid=")-1);
  p += sizeof("dn: idpnid=")-1;
  if (idpnid) {
    strcpy(p, idpnid);
    p += strlen(idpnid);
  }
  memcpy(p, ",affid=", sizeof(",affid=")-1);
  p += sizeof(",affid=")-1;
  if (affid) {
    strcpy(p, affid);
    p += strlen(affid);
  }
  *p++ = '\n';

  DD("len 0=%d", ((int)(p-ss->s)));

  for (at = pool; at; at = at->n) {
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL)
	continue;
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name = map->dst;
      } else {
	name = at->name;
      }
      
      name_len = strlen(name);
      strcpy(p, name);
      p += name_len;
      *p++ = ':';
      *p++ = ' ';
      memcpy(p, at->map_val->s, at->map_val->len);
      p += at->map_val->len;
      *p++ = '\n';

      DD("len 1=%d", ((int)(p-ss->s)));
      
      for (av = at->nv; av; av = av->n) {
	strcpy(p, name);
	p += name_len;
	*p++ = ':';
	*p++ = ' ';
	memcpy(p, av->map_val->s, av->map_val->len);
	p += av->map_val->len;
	*p++ = '\n';

	DD("len 2=%d", (int)(p-ss->s));
      }


    } else {
      name_len = strlen(at->name);
      strcpy(p, at->name);
      p += name_len;
      *p++ = ':';
      *p++ = ' ';
      if (at->val) {
	strcpy(p, at->val);
	p += strlen(at->val);
      }
      *p++ = '\n';

      DD("len 3=%d name_len=%d name(%s)", (int)(p-ss->s), name_len, at->name);
      
      for (av = at->nv; av; av = av->n) {
	strcpy(p, at->name);
	p += name_len;
	*p++ = ':';
	*p++ = ' ';
	if (at->val) {
	  strcpy(p, av->val);
	  p += strlen(av->val);
	}
	*p++ = '\n';

	D("len 4=%d", (int)(p-ss->s));
      }

    }
  }
  DD("len Fin=%d", (int)(p-ss->s));

  ASSERTOPP(p, ==, ss->s+len);
  return ss;
}

/*(-) Length computation of JSON string */

/* Called by:  zxid_pool_to_json x9 */
static int zxid_json_strlen(char* js)
{
  int res = 0;
  for (; *js; ++js, ++res) {
    int c = *(unsigned char*)js;
    if (c < ' ') {
      if ((c == '\n') || (c == '\r') || (c == '\t') ||
	  (c == '\b') || (c == '\f')) {
	/* \X */
	res++;
      } else {
	/* \uXXXX */
	res += 5;
      }
    } else if ((c == '\'') || (c == '\"') || (c == '\\')) {
      /* \X */
      res++;
    } else if ((c == 0xe2) && (((unsigned char*)js)[1] == 0x80) &&
	       ((((unsigned char*)js)[2] & 0xfe) == 0xa8)) {
      /* Some java-script based JSON decoders don't like
       * unescaped \u2028 and \u2029. */
      /* \uXXXX */
      res += 5;
      js += 2;
    }
  }
  return res;
}

/*(-) Copy JSON string */

/* Called by:  zxid_pool_to_json x8 */
static char* zxid_json_strcpy(char* dest, char* js)
{
  for (; *js; ++js) {
    int c = *(unsigned char*)js;
    if (c < ' ') {
      /* Control character. */
      *dest++ = '\\';
      if (c == '\n') c = 'n';
      else if (c == '\r') c = 'r';
      else if (c == '\t') c = 't';
      else if (c == '\b') c = 'b';
      else if (c == '\f') c = 'f';
      else {
	/* \uXXXX */
	sprintf(dest, "u%04x", c);
	dest += 5;
	continue;
      }
    } else if ((c == '\'') || (c == '\"') || (c == '\\')) {
      /* \X */
      *dest++ = '\\';
    } else if ((c == 0xe2) && (((unsigned char*)js)[1] == 0x80) &&
	       ((((unsigned char*)js)[2] & 0xfe) == 0xa8)) {
      /* Some java-script based JSON decoders don't like
       * unescaped \u2028 and \u2029. */
      /* \uXXXX */
      sprintf(dest, "\\u%04x", 0x2028 | (js[2] & 1));
      js += 2;
      dest += 6;
      continue;
    }
    *dest++ = c;
  }
  return dest;
}

/*() Convert attributes from (session) pool to JSON, applying OUTMAP. */

/* Called by:  zxid_ses_to_json */
static struct zx_str* zxid_pool_to_json(zxid_conf* cf, struct zxid_attr* pool)
{
  char* p;
  char* name;
  int len = sizeof("{")-1, name_len;
  struct zxid_map* map;
  struct zxid_attr* at;
  struct zxid_attr* av;
  struct zx_str* ss;
  
  /* Length computation pass */

  for (at = pool; at; at = at->n) {
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL) {
	D("attribute(%s) filtered out by del rule in OUTMAP", at->name);
	continue;
      }
      at->map_val = zxid_map_val(cf, 0, 0, map, at->name, at->val);
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name_len = zxid_json_strlen(map->dst);
      } else {
	name_len = zxid_json_strlen(at->name);
      }

      if (at->nv) {  /* Multivalue requires array */
	len += name_len + sizeof("\"\":[\"\"],")-1 +
	  zxid_json_strlen(at->map_val->s);
	for (av = at->nv; av; av = av->n) {
	  av->map_val = zxid_map_val(cf, 0, 0, map, at->name, av->val);
	  len += name_len + sizeof(",\"\"")-1 +
	    zxid_json_strlen(at->map_val->s);
	}
      } else {
	len += name_len + sizeof("\"\":\"\",")-1 +
	  zxid_json_strlen(at->map_val->s);
      }
    } else {
      name_len = zxid_json_strlen(at->name);
      if (at->nv) {  /* Multivalue requires array */
	len += name_len + sizeof("\"\":[\"\"],")-1 +
	  (at->val?zxid_json_strlen(at->val):0);
	for (av = at->nv; av; av = av->n)
	  len += name_len + sizeof(",\"\"")-1 +
	    (av->val?zxid_json_strlen(av->val):0);
      } else {
	len += name_len + sizeof("\"\":\"\",")-1 +
	  (at->val?zxid_json_strlen(at->val):0);
      }
    }
  }
  
  /* Attribute rendering pass */

  ss = zx_new_len_str(cf->ctx, len);
  p = ss->s;
  *p++ = '{';

  for (at = pool; at; at = at->n) {
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL)
	continue;
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name = map->dst;
      } else {
	name = at->name;
      }

      *p++ = '"';
      p = zxid_json_strcpy(p, name);
      p += strlen(name);
      *p++ = '"';
      *p++ = ':';
      if (at->nv) {
	*p++ = '[';
	*p++ = '"';
	p = zxid_json_strcpy(p, at->map_val->s);
	*p++ = '"';
	for (av = at->nv; av; av = av->n) {
	  *p++ = ',';
	  *p++ = '"';
	  p = zxid_json_strcpy(p, av->map_val->s);
	  *p++ = '"';
	}
	*p++ = ']';
      } else {
	*p++ = '"';
	p = zxid_json_strcpy(p, at->map_val->s);
	*p++ = '"';
      }

    } else {
      *p++ = '"';
      p = zxid_json_strcpy(p, at->name);
      *p++ = '"';
      *p++ = ':';
      if (at->nv) {
	*p++ = '[';
	*p++ = '"';
	if (at->val) {
	  p = zxid_json_strcpy(p, at->val);
	}
	*p++ = '"';
	for (av = at->nv; av; av = av->n) {
	  *p++ = ',';
	  *p++ = '"';
	  if (at->val) {
	    p = zxid_json_strcpy(p, av->val);
	  }
	  *p++ = '"';
	}
	*p++ = ']';
      } else {
	*p++ = '"';
	if (at->val) {
	  p = zxid_json_strcpy(p, at->val);
	}
	*p++ = '"';
      }
    }
    *p++ = ',';
  }
  p[-1] = '}';   /* Overwrites last comma */
  ASSERTOPP(p, ==, ss->s+len);
  return ss;
}

/*() Convert attributes from (session) pool to query string, applying OUTMAP.
 * *** Need to check multivalue handling. Now all values are simply blurted
 *     out as separate name=value pairs.
 * *** Need to figure out how to distinguish query string return from
 *     other returns, like redirect. Perhaps arrange dn field always first? */

/* Called by:  zxid_ses_to_qs */
static struct zx_str* zxid_pool_to_qs(zxid_conf* cf, struct zxid_attr* pool)
{
  char* p;
  char* name;
  int len = sizeof("dn=QS1&")-1, name_len;
  struct zxid_map* map;
  struct zxid_attr* at;
  struct zxid_attr* av;
  struct zx_str* ss;
  
  /* Length computation pass */

  for (at = pool; at; at = at->n) {
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL) {
	D("attribute(%s) filtered out by del rule in OUTMAP", at->name);
	continue;
      }
      at->map_val = zxid_map_val(cf, 0, 0, map, at->name, at->val);
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name_len = strlen(map->dst);
      } else {
	name_len = strlen(at->name);
      }
      len += name_len + sizeof("=&")-1 + zx_url_encode_len(at->map_val->len,at->map_val->s)-1;
      for (av = at->nv; av; av = av->n) {
	av->map_val = zxid_map_val(cf, 0, 0, map, at->name, av->val);
	len += name_len + sizeof("=&")-1 + zx_url_encode_len(av->map_val->len,av->map_val->s)-1;
      }
      D("len=%d name_len=%d %s", len, name_len, at->name);
    } else {
      name_len = strlen(at->name);
      len += name_len + sizeof("=&")-1 + (at->val?zx_url_encode_len(strlen(at->val),at->val)-1:0);
      D("len=%d name_len=%d %s (nomap) url_enc_len=%d", len, name_len, at->name, (at->val?zx_url_encode_len(strlen(at->val),at->val)-1:0));
      for (av = at->nv; av; av = av->n)
	len += name_len + sizeof("=&")-1 + (av->val?zx_url_encode_len(strlen(av->val),av->val)-1:0);
    }
  }
  
  /* Attribute rendering pass */

  DD("HERE %d", 0);

  ss = zx_new_len_str(cf->ctx, len);
  p = ss->s;
  memcpy(p, "dn=QS1&", sizeof("dn=QS1&")-1);
  p += sizeof("dn=QS1&")-1;
  
  for (at = pool; at; at = at->n) {
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL)
	continue;
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name = map->dst;
      } else {
	name = at->name;
      }
      
      name_len = strlen(name);
      strcpy(p, name);
      p += name_len;
      *p++ = '=';
      p = zx_url_encode_raw(at->map_val->len, at->map_val->s, p);
      *p++ = '&';
      
      for (av = at->nv; av; av = av->n) {
	strcpy(p, name);
	p += name_len;
	*p++ = '=';
	p = zx_url_encode_raw(av->map_val->len, av->map_val->s, p);
	*p++ = '&';
      }
    } else {
      name_len = strlen(at->name);
      strcpy(p, at->name);
      p += name_len;
      *p++ = '=';
      if (at->val)
	p = zx_url_encode_raw(strlen(at->val), at->val, p);
      *p++ = '&';
      
      for (av = at->nv; av; av = av->n) {
	strcpy(p, at->name);
	p += name_len;
	*p++ = '=';
	if (at->val)
	  p = zx_url_encode_raw(strlen(av->val), av->val, p);
	*p++ = '&';
      }
    }
  }
  D("p=%p == %p ss=%p len=%d", p, ss->s+len, ss->s, len);
  DD("p(%.*s)", len, ss->s);
  ASSERTOPP(p, ==, ss->s+len);
  *p = 0;  /* Zap last & */
  return ss;
}

/*() Convert attributes from session to LDIF, applying OUTMAP. */

/* Called by: */
struct zx_str* zxid_ses_to_ldif(zxid_conf* cf, zxid_ses* ses) {
  return zxid_pool_to_ldif(cf, ses?ses->at:0);
}

/*() Convert attributes from session to JSON, applying OUTMAP. */

/* Called by:  zxid_simple_ab_pep */
struct zx_str* zxid_ses_to_json(zxid_conf* cf, zxid_ses* ses) {
  return zxid_pool_to_json(cf, ses?ses->at:0);
}

/*() Convert attributes from session to query string, applying OUTMAP. */

/* Called by:  zxid_simple_ab_pep */
struct zx_str* zxid_ses_to_qs(zxid_conf* cf, zxid_ses* ses) {
  return zxid_pool_to_qs(cf, ses?ses->at:0);
}

/*() Add values to session attribute pool, applying NEED, WANT, and INMAP */

/* Called by:  zxid_add_a7n_at_to_pool x2 */
static int zxid_add_at_vals(zxid_conf* cf, zxid_ses* ses, struct zx_sa_Attribute_s* at, char* name, struct zx_str* issuer)
{
  struct zx_str* ss;
  struct zxid_map* map;
  struct zx_sa_AttributeValue_s* av;
  struct zxid_attr* ses_at;
  
  /* Attribute must be needed or wanted */

  if (!zxid_is_needed(cf->need, name) && !zxid_is_needed(cf->want, name)) {
    D("attribute(%s) neither needed nor wanted", name);
    return 0;
  }
  
  map = zxid_find_map(cf->inmap, name);
  if (map && map->rule == ZXID_MAP_RULE_DEL) {
    D("attribute(%s) filtered out by del rule in INMAP", name);
    return 0;
  }
  
  /* Locate existing session pool attribute by name or mapped name, or create
   * empty one if needed. N.B. The value is not assigned here yet. */
  
  if (map && map->dst && *map->dst && map->src && map->src[0] != '*') {
    ses_at = zxid_find_at(ses->at, map->dst);
    if (!ses_at)
      ses->at = ses_at = zxid_new_at(cf, ses->at, strlen(map->dst), map->dst, 0, 0, "mappd");
  } else {
    ses_at = zxid_find_at(ses->at, name);
    if (!ses_at)
      ses->at = ses_at = zxid_new_at(cf, ses->at, strlen(name), name, 0, 0, "as is");
  }
  ses_at->orig = at;
  ses_at->issuer = issuer;
  
  for (av = at->AttributeValue;
       av;
       av = (struct zx_sa_AttributeValue_s*)ZX_NEXT(av)) {
    if (av->gg.g.tok != zx_sa_AttributeValue_ELEM)
      continue;
    DD("  adding value: %p", ZX_GET_CONTENT(av));
    if (av->EndpointReference || av->ResourceOffering)
      continue;  /* Skip bootstraps. They are handled elsewhere, see zxid_snarf_eprs_from_ses(). */
    if (ZX_GET_CONTENT(av)) {
      ss = zxid_map_val_ss(cf, ses, 0, map, ses_at->name, ZX_GET_CONTENT(av));
      if (ses_at->val) {
	D("  multival(%.*s)", ss->len, ss->s);
	ses->at->nv = zxid_new_at(cf, ses_at->nv, 0, 0, ss->len, ss->s, "multival");
      } else {
	D("  1st val(%.*s)", ss->len, ss->s);
	COPYVAL(ses_at->val, ss->s, ss->s+ss->len);
      }
    }
  }
  // *** check that value is not null, add empty string
  return 1;
}

/*() Add Attribute Statements of an Assertion to session attribute pool, applying NEED, WANT, and INMAP */

/* Called by:  zxid_ses_to_pool */
static void zxid_add_a7n_at_to_pool(zxid_conf* cf, zxid_ses* ses, zxid_a7n* a7n)
{
  struct zx_sa_Attribute_s* at;
  struct zx_sa_AttributeStatement_s* as;
  if (!a7n)
    return;
  
  for (as = a7n->AttributeStatement;
       as;
       as = (struct zx_sa_AttributeStatement_s*)ZX_NEXT(as)) {
    if (as->gg.g.tok != zx_sa_AttributeStatement_ELEM)
      continue;
    for (at = as->Attribute;
	 at;
	 at = (struct zx_sa_Attribute_s*)ZX_NEXT(at)) {
      if (at->gg.g.tok != zx_sa_Attribute_ELEM)
	continue;
      if (at->Name)
	zxid_add_at_vals(cf, ses, at, zx_str_to_c(cf->ctx, &at->Name->g), ZX_GET_CONTENT(a7n->Issuer));
      if (at->FriendlyName)
	zxid_add_at_vals(cf, ses, at, zx_str_to_c(cf->ctx, &at->FriendlyName->g), ZX_GET_CONTENT(a7n->Issuer));
    }
  }
}

/*() Add simple attribute to session's attribute pool, applying NEED, WANT, and INMAP.
 * Replaces zxid_add_attr_to_pool() */

/* Called by:  chkuid, zxid_add_action_from_body_child, zxid_add_ldif_at2ses, zxid_add_qs2ses, zxid_mini_httpd_sso, zxid_ses_to_pool x26, zxid_simple_ab_pep x2 */
void zxid_add_attr_to_ses(zxid_conf* cf, zxid_ses* ses, char* at_name, struct zx_str* val)
{
  struct zxid_map* map;
  if (!val)
    val = zx_dup_str(cf->ctx, "-");

  if (zxid_is_needed(cf->need, at_name) || zxid_is_needed(cf->want, at_name)) {
    map = zxid_find_map(cf->inmap, at_name);
    if (map && map->rule == ZXID_MAP_RULE_DEL) {
      D("attribute(%s) filtered out by del rule in INMAP", at_name);
    } else {
      if (map && map->dst && *map->dst && map->src && map->src[0] != '*') {
	ses->at = zxid_new_at(cf, ses->at, strlen(map->dst), map->dst, val->len, val->s, "mappd2");
      } else {
	ses->at = zxid_new_at(cf, ses->at, strlen(at_name), at_name, val->len, val->s, "as is2");
      }
    }
  } else {
    D("attribute(%s) neither needed nor wanted", at_name);
  }
}

/*() Parse LDIF format and insert attributes to linked list. Return new head of the list.
 * *** illegal input causes corrupt pointer. For example query string input causes corruption. */

/* Called by:  zxid_ses_to_pool x3 */
static void zxid_add_ldif_at2ses(zxid_conf* cf, zxid_ses* ses, const char* prefix, char* p, char* lk)
{
  char* name;
  char* val;
  char* nbuf;
  char name_buf[ZXID_MAX_USER];
  int len;
  if (prefix) {
    strncpy(name_buf, prefix, sizeof(name_buf)-1);
    nbuf = name_buf + MIN(strlen(prefix), sizeof(name_buf)-1);
  } else
    nbuf = name_buf;  

  for (; p; ++p) {
    name = p;
    p = strstr(p, ": ");
    if (!p)
      break;
    len = MIN(p-name, sizeof(name_buf)-(nbuf-name_buf)-1);
    memcpy(nbuf, name, len);
    nbuf[len]=0;

    val = p+2;
    p = strchr(val, '\n');  /* *** parsing LDIF is fragile if values are multiline */
    len = p?(p-val):strlen(val);
    D("%s: ATTR(%s)=(%.*s)", lk, name_buf, len, val);
    zxid_add_attr_to_ses(cf, ses, name_buf,  zx_dup_len_str(cf->ctx, len, val));
  }
}

/*() Copy user's local EPRs to his current session.
 * This function implements a feature where user can have at
 * some site some long term EPRs (with long term credential). When SSO
 * is made, these EPRs are copied to user's session's EPR
 * cache and thus made available. The persistent user EPRs could
 * be used to implement stuff like subscriptions.
 *
 * The ".all" user's EPRs provide a mechanism to add to all users of
 * a given SP some EPR. Naturally such EPR can not have per user
 * or short time credential. This can have security implications.
 *
 * cf:: Config object for cf->cpath, and for memory allocation
 * ses:: Session object. ses->sid is used to determine desitmation directory.
 * path:: Path to the user directory (in /var/zxid/user/<sha1_safe_base64(idpnid)>/)
 */

/* Called by:  zxid_ses_to_pool x3 */
static void zxid_cp_usr_eprs2ses(zxid_conf* cf, zxid_ses* ses, struct zx_str* path)
{
  char bs_dir[ZXID_MAX_BUF];
  char ses_path[ZXID_MAX_BUF];
  DIR* dir;
  struct dirent * de;
  if (!ses->sid || !*ses->sid || !path)
    return;  /* No valid session. Nothing to do. */
  
  snprintf(bs_dir, sizeof(bs_dir), "%.*s/.bs", path->len, path->s);
  bs_dir[sizeof(bs_dir)-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  dir = opendir(bs_dir);
  if (!dir) {
    D("Local bootstrap dir(%s) does not exist", bs_dir);
    return;
  }
  while (de = readdir(dir)) {
    if (ONE_OF_2(de->d_name[0], '.', 0))   /* skip . and .. and .foo */
      continue;
    
    snprintf(bs_dir, sizeof(bs_dir), "%.*s/.bs/%s", path->len, path->s, de->d_name);
    bs_dir[sizeof(bs_dir)-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
    snprintf(ses_path, sizeof(ses_path), "%.*s" ZXID_SES_DIR "%s/%s", path->len, path->s, ses->sid, de->d_name);
    ses_path[sizeof(ses_path)-1] = 0; /* must term manually as on win32 nul is not guaranteed */
    copy_file(bs_dir, ses_path, "EPRS2ses", 1);
  }
  closedir(dir);
}

/*(i) Process attributes from the AttributeStatements of the session's
 * SSO Assertion and insert them to the session's attribute pool. NEED, WANT, and INMAP
 * are applied. The pool is suitable for use by PEP or eventually
 * rendering to LDIF (or JSON). This function also implements
 * local attribute authority. */

/* Called by:  zxid_as_call_ses, zxid_az_base_cf, zxid_az_cf, zxid_fetch_ses, zxid_simple_ab_pep, zxid_wsc_valid_re_env, zxid_wsp_validate_env */
void zxid_ses_to_pool(zxid_conf* cf, zxid_ses* ses)
{
  char* src;
  char* dst;
  char* lim;
  struct zx_str* issuer = 0;
  struct zx_str* affid;
  struct zx_str* nid;
  struct zx_str* tgtissuer = 0;
  struct zx_str* tgtaffid;
  struct zx_str* tgtnid;
  struct zx_str* accr;
  struct zx_str* path;
  struct zx_sa_AuthnStatement_s* as;
  struct zx_sa_Assertion_s* a7n;
  struct zx_sa_Assertion_s* tgta7n;
  char* buf;
  char sha1_name[28];

  D_INDENT("ses2pool: ");
  zxid_get_ses_sso_a7n(cf, ses);
  a7n = ses->a7n;
  D("adding a7n %p to pool", a7n);
  zxid_add_a7n_at_to_pool(cf, ses, a7n);
  
  /* Format some pseudo attributes that describe the SSO */

  if (a7n) {
    zxid_add_attr_to_ses(cf, ses, "ssoa7n", zx_easy_enc_elem_opt(cf, &a7n->gg));
    issuer = ZX_GET_CONTENT(a7n->Issuer);
  }
  zxid_add_attr_to_ses(cf, ses, "issuer", issuer);
  zxid_add_attr_to_ses(cf, ses, "ssoa7npath",zx_dup_str(cf->ctx, STRNULLCHK(ses->sso_a7n_path)));
  
  affid = ses->nameid&&ses->nameid->NameQualifier?&ses->nameid->NameQualifier->g:0;
  nid = ZX_GET_CONTENT(ses->nameid);
  zxid_add_attr_to_ses(cf, ses, "affid",  affid);
  zxid_add_attr_to_ses(cf, ses, "idpnid", nid);
  zxid_add_attr_to_ses(cf, ses, "nidfmt", zx_dup_str(cf->ctx, ses->nidfmt?"P":"T"));
  if (nid) {  
    zxid_user_sha1_name(cf, affid, nid, sha1_name);
    path = zx_strf(cf->ctx, "%s" ZXID_USER_DIR "%s", cf->cpath, sha1_name);
    zxid_add_attr_to_ses(cf, ses, "localpath",   path);
    buf = read_all_alloc(cf->ctx, "splocal_user_at", 0, 0, "%.*s/.bs/.at", path->len, path->s);
    if (buf) {
      zxid_add_ldif_at2ses(cf, ses, "local_", buf, "splocal_user_at");
      ZX_FREE(cf->ctx, buf);
    }
    zxid_cp_usr_eprs2ses(cf, ses, path);
  }

  /* Format pseudo attrs that describe the target, defaulting to the SSO identity. */
  
  if (ses->tgta7n)
    tgta7n = ses->tgta7n;
  else
    tgta7n = a7n;
  if (tgta7n) {
    zxid_add_attr_to_ses(cf, ses, "tgta7n", zx_easy_enc_elem_opt(cf, &a7n->gg));
    tgtissuer = ZX_GET_CONTENT(tgta7n->Issuer);
  }
  if (tgtissuer)
    zxid_add_attr_to_ses(cf, ses, "tgtissuer", tgtissuer);
  zxid_add_attr_to_ses(cf, ses, "tgta7npath",zx_dup_str(cf->ctx, STRNULLCHK(ses->tgt_a7n_path)));

  tgtaffid = ses->tgtnameid&&ses->tgtnameid->NameQualifier?&ses->tgtnameid->NameQualifier->g:0;
  tgtnid = ZX_GET_CONTENT(ses->tgtnameid);
  if (!tgtissuer) tgtissuer = issuer;  /* Default: requestor is the target */
  if (!tgtaffid)  tgtaffid = affid;
  if (!tgtnid)    tgtnid = nid;
  zxid_add_attr_to_ses(cf, ses, "tgtaffid",  tgtaffid);
  zxid_add_attr_to_ses(cf, ses, "tgtnid",    tgtnid);
  zxid_add_attr_to_ses(cf, ses, "tgtfmt",    zx_dup_str(cf->ctx, ses->tgtfmt?"P":"T"));
  if (tgtnid) {
    zxid_user_sha1_name(cf, tgtaffid, tgtnid, sha1_name);
    path = zx_strf(cf->ctx, "%s" ZXID_USER_DIR "%s", cf->cpath, sha1_name);
    zxid_add_attr_to_ses(cf, ses, "tgtpath",   path);
    buf = read_all_alloc(cf->ctx, "sptgt_user_at", 0, 0, "%.*s/.bs/.at", path->len, path->s);
    if (buf) {
      zxid_add_ldif_at2ses(cf, ses, "tgt_", buf, "sptgt_user_at");
      ZX_FREE(cf->ctx, buf);
    }
    zxid_cp_usr_eprs2ses(cf, ses, path);
  }
  
  accr = a7n&&(as = a7n->AuthnStatement)&&as->AuthnContext?ZX_GET_CONTENT(as->AuthnContext->AuthnContextClassRef):0;
  //accr = a7n&&a7n->AuthnStatement&&a7n->AuthnStatement->AuthnContext&&a7n->AuthnStatement->AuthnContext->AuthnContextClassRef&&a7n->AuthnStatement->AuthnContext->AuthnContextClassRef->content&&a7n->AuthnStatement->AuthnContext->AuthnContextClassRef->content?a7n->AuthnStatement->AuthnContext->AuthnContextClassRef->content:0;
  zxid_add_attr_to_ses(cf, ses, "authnctxlevel", accr);
  
  buf = read_all_alloc(cf->ctx, "splocal.all", 0,0, "%s" ZXID_USER_DIR ".all/.bs/.at" , cf->cpath);
  if (buf) {
    zxid_add_ldif_at2ses(cf, ses, 0, buf, "splocal.all");
    ZX_FREE(cf->ctx, buf);
  }
  path = zx_strf(cf->ctx, "%s" ZXID_USER_DIR ".all", cf->cpath);
  zxid_cp_usr_eprs2ses(cf, ses, path);
  
  zxid_add_attr_to_ses(cf, ses, "eid",        zxid_my_ent_id(cf));
  zxid_add_attr_to_ses(cf, ses, "sigres",     zx_strf(cf->ctx, "%x", ses->sigres));
  zxid_add_attr_to_ses(cf, ses, "ssores",     zx_strf(cf->ctx, "%x", ses->ssores));
  if (ses->sid && *ses->sid) {
    zxid_add_attr_to_ses(cf, ses, "sesid",    zx_dup_str(cf->ctx, STRNULLCHK(ses->sid)));
    zxid_add_attr_to_ses(cf, ses, "sespath",  zx_strf(cf->ctx, "%s" ZXID_SES_DIR "%s", cf->cpath, STRNULLCHK(ses->sid)));
  }
  zxid_add_attr_to_ses(cf, ses, "sesix",      zx_dup_str(cf->ctx, STRNULLCHK(ses->sesix)));
  zxid_add_attr_to_ses(cf, ses, "setcookie",  zx_dup_str(cf->ctx, STRNULLCHK(ses->setcookie)));
  zxid_add_attr_to_ses(cf, ses, "setptmcookie",zx_dup_str(cf->ctx,STRNULLCHK(ses->setptmcookie)));
  if (ses->cookie && ses->cookie[0])
    zxid_add_attr_to_ses(cf, ses, "cookie",   zx_dup_str(cf->ctx, ses->cookie));
  zxid_add_attr_to_ses(cf, ses, "msgid",      ses->wsp_msgid);

  zxid_add_attr_to_ses(cf, ses, "rs",         zx_dup_str(cf->ctx, STRNULLCHK(ses->rs)));
  src = dst = ses->at->val;
  lim = ses->at->val + strlen(ses->at->val);
  URL_DECODE(dst, src, lim);
  *dst = 0;
  D("RelayState(%s)", ses->at->val);
  D_DEDENT("ses2pool: ");
}

/*(i) Add Attributes from Querty String to Session attribute pool
 * The qs argument is parsed according to the CGI Query String rules (string
 * is modifed to insert nul terminations and URL decoded in place)
 * and the attributes are added to the session. If apply_map is 1, the
 * INMAP configuration is applied. While this may seem a hassle, it
 * allows for specification of the values as safe_base64, etc. If values
 * are to be added verbatim, just specify 0 (all other values reserved).
 * The input argument qs gets modified in-situ due to URL decoding and
 * nul termination. Make sure to duplicate any string constant before calling.
 * Returns 1 on success, 0 on failure (return value often not checked). */

/* Called by:  zxid_az_base_cf_ses, zxid_az_cf_ses, zxid_query_ctlpt_pdp x2 */
int zxid_add_qs2ses(zxid_conf* cf, zxid_ses* ses, char* qs, int apply_map)
{
  char* n;
  char* v;
  if (!qs || !ses)
    return 0;

  D("qs(%s) len=%d", qs, (int)strlen(qs));
  while (qs && *qs) {
    qs = zxid_qs_nv_scan(qs, &n, &v, 1);
    if (!n)
      n = "NULL_NAM_ERR";

    if (apply_map) {
      D("map %s=%s", n,v);
      zxid_add_attr_to_ses(cf, ses, n, zx_dup_str(cf->ctx, v));  
    } else {
      D("asis %s=%s", n,v);
      ses->at = zxid_new_at(cf, ses->at, strlen(n), n, strlen(v), v, "as is3");
    }
  }
  return 1;
}

/*(i) Given session object (see zxid_simple_cf_ses() or zxid_fetch_ses()),
 * return n'th value (ix=0 is first) of given attribute, if any, from the
 * session common attribute pool. If apply_map is 0, the value is returned
 * as is. If it is 1 then OUTMAP is applied (the
 * attribute name is in the internal namespace). Other apply_map values
 * are reserved. */

/* Called by: */
struct zx_str* zxid_get_at(zxid_conf* cf, zxid_ses* ses, char* atname, int ix, int apply_map)
{
  struct zxid_attr* at;
  struct zxid_attr* av;
  if (!cf || !ses || !atname) {
    ERR("Missing args cf=%p ses=%p atname=%p", cf, ses, atname);
    return 0;
  }
  for (at = ses->at; at; at = at->n) {
    if (!strcmp(at->name, atname)) {
      for (av = at; av && ix; --ix, av = av->nv) ;
      if (av) {
	if (apply_map) {
	  return zx_dup_str(cf->ctx, at->val); /* *** */
	} else
	  return zx_dup_str(cf->ctx, at->val);
      }
    }
  }
  return 0;
}

/* EOF  --  zxidpool.c */
