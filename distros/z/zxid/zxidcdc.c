/* zxidcdc.c  -  Handwritten functions for Common Domain Cookie handling at SP
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidcdc.c,v 1.5 2008-10-08 03:56:55 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 16.1.2007, split from zxidlib.c --Sampo
 * 7.10.2008, added documentation --Sampo
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"

/* ============== CDC ============== */

/*() Read Common Domain Cookie and formulate HTTP redirection to pass it back.
 *
 * The SAML CDC is a standards based method for SSO IdP discovery. */

/* Called by:  covimp_test, main x2, zxid_simple_no_ses_cf */
struct zx_str* zxid_cdc_read(zxid_conf* cf, zxid_cgi* cgi)
{
  char* p;
  char* cdc = 0;
  char* cookie = getenv("HTTP_COOKIE");
  char* host = getenv("HTTP_HOST");
  if (cookie) {
    D("CDC(%s) host(%s)", cookie, host);
    cdc = strstr(cookie, "_saml_idp");
    if (!cdc)
      cdc = strstr(cookie, "_liberty_idp");
    if (cdc) {
      cdc = strchr(cdc, '=');
      if (cdc) {
	D("cdc(%s)", cdc);
	if (cdc[1] == '"') {
	  cdc += 2;
	  p = strchr(cdc, '"');
	  if (p)
	    *p = 0;
	  else
	    cdc = 0;
	} else
	  ++cdc;
      }
    } else {
      ERR("Malformed CDC(%s)", cookie);
    }
  } else {
    D("No CDC _saml_idp in CGI environment host(%s)", STRNULLCHK(host));
  }
  D("Location: %s?o=E&c=%s\r\n\r\n", cf->burl, cdc?cdc:"(missing)");
  /* *** should prepare AuthnReq and redirect directly to the IdP (if any). */
  return zx_strf(cf->ctx, "Location: %s?o=E&c=%s\r\n\r\n", cf->burl, cdc?cdc:"");
}

/*() Process second part of Common Domain Cookie redirection.
 * See zxid_cdc_read() for first part.
 *
 * The SAML CDC is a standards based method for SSO IdP discovery. */

/* Called by:  covimp_test, main x2, zxid_simple_no_ses_cf */
int zxid_cdc_check(zxid_conf* cf, zxid_cgi* cgi)
{
  int len;
  zxid_entity* ent;
  char* p;
  char* q;
  char eid[ZXID_MAX_EID];
#if 0
  char* idp_eid;
  if (!cgi->cdc) return 0;
  for (idp_eid = strtok(cgi->cdc, " "); idp_eid; idp_eid = strtok(0, " ")) {
    if (!(ent = zxid_get_ent(cf, idp_eid)))
      continue;
    switch (cf->cdc_choice) {
    case ZXID_CDC_CHOICE_ALWAYS_FIRST:  /* Do not offer UI, always pick first on CDC list. */
      break;
    case ZXID_CDC_CHOICE_ALWAYS_LAST:   /* Do not offer UI, always pick last on CDC list. */
      /* *** How to detect "lastness" in strtok() list? */
      break;
    case ZXID_CDC_CHOICE_ALWAYS_ONLY:   /* If CDC has only one IdP, always pick it. */
      /* *** How to detect "onlyness" in strtok() list? */
      break;
    case ZXID_CDC_CHOICE_UI_PREF:       /* Offer UI with the CDC designated IdPs first. */
      /* *** */
      break;
    case ZXID_CDC_CHOICE_UI_NOPREF:     /* Offer UI. Do not give preference to CDC IdPs. */
      /* *** */
      break;
    default: NEVER("Bad CDC choice(%d)\n", cf->cdc_choice);
    }
  }
#else

  for (q = cgi->cdc; q; q = p ? p+1 : 0) {
    p = strchr(q, ' ');
    len = p ? p-q : strlen(q);
    
    if (SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(len) > sizeof(eid)-1) {
      ERR("EntityID len=%d larger than built in limit=%d. Base64 len=%d", SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(len), (int)sizeof(eid)-1, len);
      continue;
    }
    q = unbase64_raw(q, q + len, eid, zx_std_index_64);
    *q = 0;

    ent = zxid_get_ent(cf, eid);
    if (!ent) {
      ERR("eid(%s) not in CoT", eid);  /* *** Change this to offer login button anyway so new IdP can join CoT using WKL */
      continue;
    }
    D("Adding entity(%s) to cgi->idp_list", eid);
    ent->n_cdc = cgi->idp_list;
    cgi->idp_list = ent;
  }
#endif
  return 0;
}

/* EOF  --  zxidcdc.c */
