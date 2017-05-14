/* zxida7n.c  -  Handwritten functions for Assertion handling
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxida7n.c,v 1.3 2008-10-08 03:56:55 sampo Exp $
 *
 * 3.2.2007, created --Sampo
 * 7.10.2008, added documentation --Sampo
 * 17.2.2011, XML whitespace handling fix --Sampo
 *
 * See also: zxidsimp.c (attributes to LDIF), and zxidepr.c
 */

#include <string.h>
#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-ns.h"
#include "c/zx-sa-data.h"

/*() Look into attribute statement(s) of an assertion and scan
 * for nth occurance of named attribute. Ordering of attributes
 * is accoring to their occurance in attribute statement, or
 * more broadly according to ordering of the attribute statements
 * themselves.
 *
 * - NULL or zero length nfmt (name format) will match any
 * - NULL or zero length name will match any
 * - NULL or zero length friendly (name) will match any
 * - minus one (-1) as either length field will cause strlen() to be done
 * - the index n is one based
 *
 * *Arguments*
 *
 * a7n:: Assertion data structure, obtained from XML parsing
 * nfmt_len:: Length of the name format, or 0 if no matching by name format is desired
 * nfmt:: name format to match (or 0)
 * name_len:: Length of the attribute name, or 0 if no matching by attribute name is desired
 * name:: attribute name to match (or 0)
 * friendly_len:: Length of the friendly name, or 0 if no matching by friendly name is desired
 * friendly:: friendly name to match (or 0)
 * n:: Howmanieth instance of the matching attribute is desired. 1 means first.
 * return:: Data structure representing the matching attribute.
 */

struct zx_sa_Attribute_s* zxid_find_attribute(zxid_a7n* a7n, int nfmt_len, char* nfmt, int name_len, char* name, int friendly_len, char* friendly, int n)
{
  struct zx_sa_Attribute_s* at;
  struct zx_sa_AttributeStatement_s* as;
  if (!nfmt) { nfmt_len = 0; nfmt = ""; }
  if (nfmt_len == -1 && nfmt) nfmt_len = strlen(nfmt);
  if (!name) { name_len = 0; name = ""; }
  if (name_len == -1 && name) name_len = strlen(name);
  if (!friendly) { friendly_len = 0; friendly = ""; }
  if (friendly_len == -1 && friendly) friendly_len = strlen(friendly);
  if (!a7n) {
    ERR("No assertion supplied (null assertion pointer) when looking for attribute nfmt(%.*s) name(%.*s) friendly(%.*s) n=%d", nfmt_len, nfmt, name_len, name, friendly_len, friendly, n);
    return 0;
  }
  for (as = a7n->AttributeStatement;
       as;
       as = (struct zx_sa_AttributeStatement_s*)as->gg.g.n) {
    if (as->gg.g.tok != zx_sa_AttributeStatement_ELEM)
      continue;
    for (at = as->Attribute;
	 at;
	 at = (struct zx_sa_Attribute_s*)at->gg.g.n) {
      if (at->gg.g.tok != zx_sa_Attribute_ELEM)
	continue;
      if ((nfmt_len ? (at->NameFormat
		       && at->NameFormat->g.len == nfmt_len
		       && !memcmp(at->NameFormat->g.s, nfmt, nfmt_len)) : 1)
	  && (name_len ? (at->Name
			  && at->Name->g.len == name_len
			  && !memcmp(at->Name->g.s, name, name_len)) : 1)
	  && (friendly_len ? (at->FriendlyName
			      && at->FriendlyName->g.len == friendly_len
			      && !memcmp(at->FriendlyName->g.s, friendly, friendly_len)) : 1)) {
	--n;
	if (!n)
	  return at;
      }
    }
  }
  return 0;
}

/* EOF  --  zxida7n.c */
