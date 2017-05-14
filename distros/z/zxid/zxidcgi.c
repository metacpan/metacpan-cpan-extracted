/* zxidcgi.c  -  Handwritten functions for parsing SP specific CGI options
 * Copyright (c) 2012-2013 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidcgi.c,v 1.33 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 16.1.2007,  split from zxidlib.c --Sampo
 * 12.10.2007, added cookie scanning --Sampo
 * 7.10.2008,  added documentation --Sampo
 * 10.12.2011, added OAuth2, OpenID Connect, and UMA support --Sampo
 * 20.10.2012, made the fr to rs copy cause deflate safe base64 encode --Sampo
 * 14.3.2013   added language/skin dependent templates --Sampo
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 */

#include <memory.h>
#include <string.h>
#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidconf.h"
#include "zxidutil.h"

/* ============== CGI Parsing ============== */

/*(i) Parse query string or form POST and detect parameters relevant for ZXID.
 * N.B. This CGI parsing is very specific for needs of ZXID. It is not generic.
 *
 * cf:: ZXID configuration object, for occasional memory allocation.
 * cgi:: Already allocated CGI structure where results of this function
 *     are deposited. Note that this structure is not cleared. Thus it is
 *     possible to call zxid_parse_cgi() multiple times to accumulate
 *     results from multiple sources, e.g. foirst for query string, and then
 *     for form POST.
 * qs:: CGI formatted input. Usually query string or form POST content.
 *     qs is modified in-place  e.g. to perform url decoding and nul termination.
 *     References to the qs will be taken, e.g. pointers in cgi struct point
 *     to it, thus qs MUST NOT be freed before cgi struct is freed, which
 *     may be long after the call to zxid_parse_cgi().
 * return:: 0 on success. Other values reserved. Usually return value is
 *     ignored as there really is no way for this function to fail. Unrecognized
 *     CGI arguments are simply ignored with assumption that some other processing
 *     layer will pick them up - hence no need to flag error. */

/* Called by:  chkuid x2, main x4, zxid_decode_ssoreq, zxid_mini_httpd_sso x2, zxid_new_cgi, zxid_simple_cf_ses x3, zxid_simple_no_ses_cf */
int zxid_parse_cgi(zxid_conf* cf, zxid_cgi* cgi, char* qs)
{
  char *p, *n, *v;
  DD("qs(%s)=%p len=%d", STRNULLCHK(qs), qs, qs?strlen(qs):-1);
  if (!qs)
    return 0;
#if 1
  p = getenv("HTTP_USER_AGENT");
  if (p && !memcmp(p, "Synmobile", sizeof("Synmobile")-1)) {
    D("Mobile detected UA(%s)", p);
    cgi->mob = 1;
  }
#endif
  
  while (qs && *qs) {
    qs = zxid_qs_nv_scan(qs, &n, &v, 2);
    if (!n)
      n = "NULL_NAME_ERROR";
    DD("n(%s)=v(%s) qs(%s)=%p len=%d", n,v, STRNULLCHKNULL(qs), qs, qs?strlen(qs):-1);
    switch (n[0]) {
    case 'n':
      if (!strcmp(n, "nonce")) { cgi->nonce = v; break; }
      goto unknown;
    case 'o':
      if (!n[1]) { cgi->op = v[0];    break; }
      if (n[1] = 'k' && !n[2]) { cgi->ok = v;  break; }  /* ok button */
      goto unknown;
    case 'p':
      if (!strcmp(n, "prompt")) { cgi->prompt = v; break; }  /* OAUTH2 */
      if (!strcmp(n, "pcode"))  { cgi->pcode = v; break; }   /* Mobile pairing code */
      goto unknown;
    case 'r':
      if (!strcmp(n, "response_type")) { cgi->response_type = v; break; }  /* OAUTH2/OIDC1 */
      if (!strcmp(n, "redirect_uri"))  { cgi->redirect_uri = v;	 break; }  /* OAUTH2 */
      if (!strcmp(n, "redirafter"))    { cgi->redirafter = v;	 break; }
      if (!strcmp(n, "rs"))            { cgi->rs = v; break; }
      if (!strcmp(n, "rest"))          { cgi->rest = v; break; }
      if (!strcmp(n, "refresh_token")) { cgi->refresh_token = v; break; }  /* OAUTH2 */
      goto unknown;
    case 's':
      if (!n[1]) { cgi->sid = v; break; }
      if (!strcmp(n, "scope"))  { cgi->scope = v; break; }   /* OAUTH2 */
      if (!strcmp(n, "state"))  { cgi->state = v; break; }   /* OAUTH2 */
      if (!strcmp(n, "schema")) { cgi->schema = v; break; }  /* OAUTH2 */
      goto unknown;
    case 't':
      if (!strcmp(n, "token_type")) { cgi->token_type = v; break; }  /* OAUTH2 */
      if (!strcmp(n, "templ"))   { DD("Detect templ(%s) cgi=%p",v,cgi); cgi->templ = v; break; }
      goto unknown;
    case 'u':
      if (!strcmp(n, "user_id")) { cgi->user_id = v; break; }   /* OAUTH2 */
      goto unknown;
    case 'c':
      if (!n[1]) { cgi->cdc = v; break; }
      if (!strcmp(n, "client_id")) { cgi->client_id = v; break; }    /* OAUTH2 */
      if (!strcmp(n, "code"))      { cgi->code = v;      break; }    /* OAUTH2 */
      goto unknown;
      /* The following two entity IDs, combined with various login buttons
       * aim at supporting may different user interface layouts. You need to
       * understand how they interact to avoid undesired conflicts. */
    case 'e':  /* EntityID field (manual entry). Overrides 'd'. */
      if (!strcmp(n, "expires_in")) { cgi->expires_in = atoi(v); break; }  /* OAUTH2 */
      if (!strcmp(n, "exp"))        { cgi->exp = v; break; }    /* OAUTH2 */
      if (!n[1]) {
set_eid:
	if (v[0]) cgi->eid = v;
	DD("v(%s) v0=0x%02x v=%p cgi->eid=%p cgi=%p", v, v[0], v, cgi->eid, cgi);
	break;
      }
      goto unknown;
    case 'd':  /* EntityID popup or radio box */
      if (!n[1]) {
	if (cgi->eid && cgi->eid[0]) {
	  D("EID already set v(%s) v0=0x%02x v=%p cgi->eid=%p cgi=%p", v, v[0], v, cgi->eid, cgi);
	  break;
	}
	goto set_eid;
      }
      if (!strcmp(n, "display")) { cgi->display = v; break; }
      goto unknown;
    case 'l':
      /* Login button names are like lP<eid>, where "l" is literal ell, P is
       * protocol profile designator, and <eid> is Entity ID of the IdP.
       * N.B. If eid is omitted from button name, it may be provided using
       * d or e fields (see above). */
      cgi->pr_ix = n[1]-'0';
      if (n[2]) {
	cgi->eid = n+2;
	/*if (cf->idp_list_meth == ZXID_IDP_LIST_BRAND)*/
	/* We need to remove the .x and/or .y from the end (image map coordinates) */
	p = strchr(cgi->eid, 0);  /* Pointer to end of string */
	DD("p[-2]=%x (%c%c) n=%p p=%p name(%s) val(%s)", p[-2], p[-2], p[-1], n, p, n, v);
	if (p[-2] == '.' && ONE_OF_2(p[-1], 'x', 'y')) {
	  p[-2] = 0;
	  DD("eid=%p eid(%s) p[-2]=%x n=%p p=%p v=%p (%s)=(%s)", cgi->eid, cgi->eid, p[-2], n, p, v, n, v);
	}
      }
      cgi->op = 'L';
      D("cgi: login eid=%p eid(%s)", cgi->eid, cgi->eid);
      break;
    case 'k':
      DD("k CGI field(%s) val(%s) cgi=%p", n, v, cgi);
      if (!n[1]) { cgi->skin = v;    break; }  /* often used for lang as well */
      goto unknown;
    case 'i':
      if (!strcmp(n, "id_token")) { cgi->id_token = v; break; }  /* OAUTH2 */
      if (!strcmp(n, "iss")) { cgi->iss = v; break; }            /* OAUTH2 */
      if (!strcmp(n, "iso29115")) { cgi->iso29115 = v; break; }  /* OAUTH2 */
      if (!strcmp(n, "id"))  { cgi->id = v; break; }             /* OAUTH2 */
      if (!strcmp(n, "inv")) { cgi->inv = v; break; }            /* OAUTH2 */
      /* IdP and protocol index selection popup values are like P<eid>
       * N.B. If eid is omitted from button name, it may be provided using
       * d or e fields (see above). This effectively allows i to be just
       * a protocol selection popup. */
      cgi->pr_ix = v[0]-'0';
      if (v[1])
	cgi->eid = v+1;
      break;
    case 'f':  /* flags and (hidden) fields found in typical SP login form */
      if (!n[1] || n[2]) goto unknown;
      switch (n[1]) {  /* Typical fields of SP side idp selection form (or query string) */
      case 'a': cgi->authn_ctx = v;       D("authn_ctx=%s", cgi->authn_ctx); break; /* fa */
      case 'c': cgi->allow_create = v[0]; D("allow_create=%c", cgi->allow_create); break; /* fc */
      case 'f': cgi->force_authn = v[0];  D("force_authn=%c", cgi->force_authn); break; /* ff */
      case 'g': cgi->get_complete = v;    break;   /* fg */
      case 'h': cgi->pxy_count = v;       break;   /* fh */
	/*case 'i': cgi->idp_list = v;    break;*/ /* fi */
      case 'm': cgi->matching_rule = v;   break;   /* fm */
      case 'n': cgi->nid_fmt = v;         D("nid_fmt=%s", cgi->nid_fmt); break;     /* fn */
      case 'p': cgi->ispassive = v[0];    D("ispassive=%c", cgi->ispassive); break; /* fp */
      case 'q': cgi->affil = v;           break;   /* fq */
      case 'r': cgi->rs = zxid_deflate_safe_b64_raw(cf->ctx, -2, v); break;         /* fr */
      case 'y': cgi->consent = v;         break;   /* fy */
      }
      break;
    case 'g':  /* management (gestion) form fields or query string arguments */
      switch (n[1]) {
      case 'r': /* gr - single logout redirect */
	if (!strcmp(n, "grant_type")) {    /* OAUTH2 */
	  cgi->grant_type = v;
	  break;
	}
      case 'l': /* gl - local logout */
      case 's': /* gs - single logout SOAP */
      case 't': /* gt - defederate redir */
      case 'u': cgi->op = n[1];           break; /* gu - defederate SOAP */
      case 'n': cgi->newnym = v;          break; /* gn */
      case 'e': cgi->enc_hint = v[0];     break; /* ge */
      case 0: goto unknown; /* N.B. single letter g=GrantToken in zxidgrant.pl */
      }
      break;
    case 'a':
      if (!n[1]) goto unknown;
      if (!strcmp(n, "access_token")) { cgi->access_token = v; break; }    /* OAUTH2 */
      if (!strcmp(n, "aud"))          { cgi->aud = v; break; }             /* OAUTH2 */
      switch (n[1]) {
      case 'l': if (n[3]) goto unknown;  cgi->op = n[2];           break;  /* al = login */
      case 'u': if (n[2]) goto unknown;  if (v[0] || !cgi->uid) cgi->uid = v; break; /* au =user */
      case 'p': if (n[2]) goto unknown;  cgi->pw = v;              break;  /* ap = password */
      case 'q': if (n[2]) goto unknown;  cgi->pin = v;             break;  /* aq = pin */
      case 'r': if (n[2]) goto unknown;  cgi->ssoreq = v;          break;  /* ar = AnRq */
      case 'n': if (n[2]) goto unknown;  cgi->op = 'N';            break;  /* an = new user */
      case 'w': if (n[2]) goto unknown;  cgi->op = 'W';            break;  /* aw = recover pw */
      case 't': if (n[2]) goto unknown;  cgi->atselafter = 1;      break;  /* at */
      }
      break;
    case 'z':
      switch (n[1]) {
      case 'x':
	switch (n[2]) {
	case 'a': cgi->zxapp = v;         break;
	case 'r': cgi->zxrfr = v;         break;
	}
	break;
      }
      break;
    case 'R':
      if (!strcmp(n, "RelayState")) { cgi->rs = v; break; }
      goto unknown;
    case 'S':
      if (!strcmp(n, "SAMLart")) {
	cgi->saml_art = v;
	cgi->op = 'A';
	break;
      }
      if (!strcmp(n, "SAMLResponse")) {
	cgi->saml_resp = v;
	cgi->op = 'P';
	break;
      }
      if (!strcmp(n, "SAMLRequest")) {
	cgi->saml_req = v;
	if (!ONE_OF_3(cgi->op, 'p', 'F', 'R'))  /* Avoid redundant sigvfy and processing for IdP */
	  cgi->op = 'Q';
	break;
      }
      if (!strcmp(n, "SigAlg")) {
	cgi->sigalg = v;
	break;
      }
      if (!strcmp(n, "Signature")) {
	cgi->sig = v;
	break;
      }
      goto unknown;
    case '_':
      if (!strcmp(n, "_uma_authn")) {
	/* Decode in place: it should always fit */
	p = unbase64_raw(v, v+strlen(v), v, zx_std_index_64);
	*p = 0;
	cgi->uid = v;
	p = strchr(v, ':');
	if (p) {
	  *p = 0;
	  cgi->pw = p+1;
	} else {
	  ERR("Malformed _uma_authn token(%s): no colon found", v);
	}
	break;
      }      
      /* fall thru */
    unknown:
    default:  D("Unknown CGI field(%s) val(%s) cgi=%p", n, v, cgi);
    }
  }
  DD("END cgi=%p cgi->eid=%p (%s) op(%c) magic=%x", cgi, cgi->eid, cgi->eid, cgi->op, cgi->magic);
  return 0;
}

/* Called by:  covimp_test */
zxid_cgi* zxid_new_cgi(zxid_conf* cf, char* qs)
{
  zxid_cgi* cgi = ZX_ZALLOC(cf->ctx, zxid_cgi);
  cgi->magic = ZXID_CGI_MAGIC;
  if (qs) {
    char* qqs;
    int len = strlen(qs);
    qqs = ZX_ALLOC(cf->ctx, len+1);
    memcpy(qqs, qs, len);
    qqs[len] = 0;
    zxid_parse_cgi(cf, cgi, qqs);
  }
  return cgi;
}

/*() Try to extract session ID from a cookie. The extracted value, if any,
 * will be deposited in cgi->sid. If no session ID is found, then cgi->sid
 * is not modified. The name of the cookie is determined by configuration
 * option ~SES_COOKIE_NAME~ (see zxidconf.h).
 * N.B. The session itself is not loaded, just the cgi->sid is populated.
 *
 * return:: none, but cgi->sid is modified
 *
 * For original Netscape cookie spec see: http://curl.haxx.se/rfc/cookie_spec.html (Oct2007)
 *
 * *Example*
 *
 *    ONE_COOKIE=aaa; ZXIDSES=S12cvd324; SOME_OTHER_COOKIE=...
 */

/* Called by:  chkuid, zxid_mini_httpd_sso, zxid_simple_cf_ses */
void zxid_get_sid_from_cookie(zxid_conf* cf, zxid_cgi* cgi, const char* cookie)
{
  char* q;
  int len;
  if (!cookie)
    return;
  len = strlen(cf->ses_cookie_name);
  for (cookie = strstr(cookie, cf->ses_cookie_name);
       cookie;
       cookie = strstr(cookie + 1, cf->ses_cookie_name))
    if (cookie[len] == '=') {
      cookie += len + 1;
      if (*cookie == '"')
	++cookie;
      q = strchr(cookie, ';');
      len = q ? (q-cookie) : strlen(cookie);
      if (cookie[len-1] == '"')
	--len;
      cgi->sid = ZX_ALLOC(cf->ctx, len + 1);
      memcpy(cgi->sid, cookie, len);
      cgi->sid[len] = 0;
      return;
    }
}

/* EOF  --  zxidcgi.c */
