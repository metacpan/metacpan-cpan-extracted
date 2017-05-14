/* zxidoidc.c  -  Handwritten nitty-gritty functions for OpenID Connect 1.0 (openid-connect oidc)
 * Copyright (c) 2011-2014 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id$
 *
 * While this file contains some protocol encoders and decoders for OAUTH2,
 * the main logic of the flows is integrated to other parts, such as zxidsimp.c
 * 
 * http://openid.net/specs/openid-connect-basic-1_0.html
 * http://openid.net/specs/openid-connect-session-1_0.html
 * http://openid.net/specs/openid-connect-messages-1_0.html
 * http://tools.ietf.org/html/draft-ietf-oauth-v2-22
 * http://tools.ietf.org/html/draft-jones-json-web-encryption-01
 *
 * 11.12.2011, created --Sampo
 * 9.10.2014, adapted from zxidoauth.c --Sampo
 */

#include "platform.h"
#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"   /* for bindings like OAUTH2_REDIR */
#include "c/zx-data.h"

/*() Interpret ZXID standard form fields to construct a XML structure for AuthnRequest */

/* Called by:  zxid_start_sso_url */
struct zx_str* zxid_mk_oauth_az_req(zxid_conf* cf, zxid_cgi* cgi, struct zx_str* loc, char* relay_state)
{
  struct zx_str* ss;
  struct zx_str* nonce;
  struct zx_str* eid;
  char* eid_url_enc;
  char* redir_url_enc;
  char* state_b64;
  char* prompt;
  char* display;

  if (!loc) {
    ERR("Redirection location URL missing. %d", 0);
    return 0;
  }
  
  redir_url_enc = zx_url_encode(cf->ctx, strlen(cf->burl), cf->burl, 0);
  eid = zxid_my_ent_id(cf);
  eid_url_enc = zx_url_encode(cf->ctx, eid->len, eid->s, 0);
  zx_str_free(cf->ctx, eid);
  
  if (relay_state)
    state_b64 = zxid_deflate_safe_b64_raw(cf->ctx, strlen(relay_state), relay_state);
  else
    state_b64 = 0;
  nonce = zxid_mk_id(cf, "OA", ZXID_ID_BITS);
  prompt = BOOL_STR_TEST(cgi->force_authn) ? "login" : 0;
  prompt = BOOL_STR_TEST(cgi->consent && cgi->consent[0]) ? (prompt?"login+consent":"consent") : prompt;
  display = BOOL_STR_TEST(cgi->ispassive) ? "none" : 0;
  
  ss = zx_strf(cf->ctx,
	       "%.*s%cresponse_type=token+id_token"
	       "&client_id=%s"
	       "&scope=openid+profile+email+address"
	       "&redirect_uri=%s%%3fo=O"
	       "&nonce=%.*s"
	       "%s%s"           /* &state= */
	       "%s%s"           /* &display= */
	       "%s%s"           /* &prompt= */
	       CRLF2,
	       loc->len, loc->s, (memchr(loc->s, '?', loc->len)?'&':'?'),
	       eid_url_enc,
	       redir_url_enc,
	       nonce->len, nonce->s,
	       state_b64?"&state=":"", STRNULLCHK(state_b64),
	       display?"&display=":"", STRNULLCHK(display),
	       prompt?"&prompt=":"", STRNULLCHK(prompt)
	       );
  D("OAUTH2 AZ REQ(%.*s)", ss->len, ss->s);
  if (errmac_debug & ERRMAC_INOUT) INFO("%.*s", ss->len, ss->s);
  zx_str_free(cf->ctx, nonce);
  ZX_FREE(cf->ctx, state_b64);
  ZX_FREE(cf->ctx, eid_url_enc);
  ZX_FREE(cf->ctx, redir_url_enc);
  return ss;
}

/*() Construct OAUTH2 / OpenID-Connect1 id_token. */

/* Called by:  zxid_sso_issue_jwt */
char* zxid_mk_jwt(zxid_conf* cf, int claims_len, char* claims)
{
  char hash[64 /*EVP_MAX_MD_SIZE*/];
  char* jwt_hdr;
  int hdr_len;
  char* b64;
  char* p;
  int len = SIMPLE_BASE64_LEN(claims_len);
  
  switch (cf->oaz_jwt_sigenc_alg) {
  case 'n':
    jwt_hdr = "{\"typ\":\"JWT\",\"alg\":\"none\"}";
    hdr_len = strlen(jwt_hdr);
    len += SIMPLE_BASE64_LEN(hdr_len) + 1 + 1;    
    break;
  case 'h':
    jwt_hdr = "{\"typ\":\"JWT\",\"alg\":\"HS256\"}";
    hdr_len = strlen(jwt_hdr);
    len += SIMPLE_BASE64_LEN(hdr_len) + 1 + 1 + 86 /* siglen conservative estimate */;    
    break;
  case 'r':
    jwt_hdr = "{\"typ\":\"JWT\",\"alg\":\"RS256\"}";
    hdr_len = strlen(jwt_hdr);
    len += SIMPLE_BASE64_LEN(hdr_len) + 1 + 1 + 500 /* siglen conservative estimate */;    
    break;
  default:
    ERR("Unrecognized OAZ_JWT_SIGENC_ALG spec(%c). See zxid-conf.pd or zxidconf.h for documentation.", cf->oaz_jwt_sigenc_alg);
    return 0;
  }
  
  b64 = ZX_ALLOC(cf->ctx, len+1);
  p = base64_fancy_raw(jwt_hdr, hdr_len, b64, safe_basis_64, 1<<31, 0, 0, 0);
  *p++ = '.';
  p = base64_fancy_raw(claims, claims_len, p, safe_basis_64, 1<<31, 0, 0, 0);
  *p = 0;
  
  switch (cf->oaz_jwt_sigenc_alg) {
  case 'n':
    *p++ = '.';
    *p = 0;
    break;
  case 'h':
    if (!cf->hmac_key[0])
      zx_get_symkey(cf, "hmac.key", cf->hmac_key);
    zx_hmac_sha256(cf->ctx, ZX_SYMKEY_LEN, cf->hmac_key, p-b64, b64, hash, &len);
    *p++ = '.';
    p = base64_fancy_raw(hash, len, p, safe_basis_64, 1<<31, 0, 0, 0);
    *p = 0;
    break;
  case 'r':
    ERR("RSA not implemented yet %d",0);
    zx_hmac_sha256(cf->ctx, ZX_SYMKEY_LEN, cf->hmac_key, p-b64, b64, hash, &len);
    *p++ = '.';
    p = base64_fancy_raw(hash, len, p, safe_basis_64, 1<<31, 0, 0, 0);
    *p = 0;
    break;
  }
  D("JWT(%s)", b64);
  return b64;
}

/*() Issue OAUTH2 / OpenID-Connect1 id_token. */

/* Called by:  zxid_oauth2_az_server_sso */
char* zxid_sso_issue_jwt(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct timeval* srcts, zxid_entity* sp_meta, struct zx_str* acsurl, zxid_nid** nameid, char* logop)
{
  int rawlen;
  char* buf;
  char* jwt;
  char* jwt_id; /* sha1 hash of the jwt, taken from log_path */
  struct zx_str issuer;
  struct zx_str* affil;
  char* eid;
  struct zx_str* logpath;
  struct zx_str ss;
  struct zx_str nn;
  struct zx_str id;
  zxid_nid* tmpnameid;
  char sp_name_buf[ZXID_MAX_SP_NAME_BUF];
  D("sp_eid(%s)", sp_meta->eid);
  if (!nameid)
    nameid = &tmpnameid;

  //if (ar && ar->IssueInstant && ar->IssueInstant->g.len && ar->IssueInstant->g.s)
  //  srcts->tv_sec = zx_date_time_to_secs(ar->IssueInstant->g.s);
  
  if (!cgi->allow_create)
    cgi->allow_create = '1';
  if (!cgi->nid_fmt || !cgi->nid_fmt[0])
    cgi->nid_fmt = "prstnt";  /* Persistent is the default implied by the specs. */

  /* Check for federation. */
  
  issuer.s = cgi->client_id; issuer.len = strlen(cgi->client_id);
  affil = &issuer;
  zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), affil, affil, 7);
  D("sp_name_buf(%s)  allow_create=%d", sp_name_buf, cgi->allow_create);

  *nameid = zxid_get_fed_nameid(cf, &issuer, affil, ses->uid, sp_name_buf, cgi->allow_create,
				(cgi->nid_fmt && !strcmp(cgi->nid_fmt, "trnsnt")),
				srcts, 0, logop);
  if (logop) { logop[3]='S';  logop[4]='S';  logop[5]='O';  logop[6]=0;  /* Patch in SSO */ }
  if (!*nameid) {
    ERR("get_fed_nameid() client_id(%s) returned NULL", cgi->client_id);
    return 0;
  }

  eid = zxid_my_ent_id_cstr(cf);
  // ,\"\":\"\"
  buf = zx_alloc_sprintf(cf->ctx, &rawlen,
		       "{\"iss\":\"%s\""
		       ",\"user_id\":\"%.*s\""
		       ",\"aud\":\"%s\""
		       ",\"exp\":%d"
		       ",\"nonce\":\"%s\"}",
		       eid,
		       ZX_GET_CONTENT_LEN(*nameid), ZX_GET_CONTENT_S(*nameid),
		       cgi->client_id,
		       time(0) + cf->timeskew + cf->a7nttl,
		       cgi->nonce);
  ZX_FREE(cf->ctx, eid);
  jwt = zxid_mk_jwt(cf, rawlen, buf);
  ZX_FREE(cf->ctx, buf);

  /* Log the issued JWT */

  ss.s = jwt; ss.len = strlen(jwt);
  logpath = zxlog_path(cf, &issuer, &ss, ZXLOG_ISSUE_DIR, ZXLOG_JWT_KIND, 1);
  if (!logpath) {
    ERR("Could not generate logpath for aud(%s) JWT(%s)", cgi->client_id, jwt);
    ZX_FREE(cf->ctx, jwt);
    return 0;
  }
  
  /* Since JWT does not have explicit ID attribute, we use the sha1 hash of the
   * contents of JWT as an ID. Since this is what logpath also does, we just
   * use the last component of the logpath. */
  for (jwt_id = logpath->s + logpath->len; jwt_id > logpath->s && jwt_id[-1] != '/'; --jwt_id) ;

  if (cf->log_issue_a7n) {
    if (zxlog_dup_check(cf, logpath, "sso_issue_jwt")) {
      ERR("Duplicate JWT ID(%s)", jwt_id);
      if (cf->dup_a7n_fatal) {
	ERR("FATAL (by configuration): Duplicate JWT ID(%s)", jwt_id);
	zxlog_blob(cf, 1, logpath, &ss, "sso_issue_JWT dup");
	zx_str_free(cf->ctx, logpath);
	ZX_FREE(cf->ctx, jwt);
	return 0;
      }
    }
    zxlog_blob(cf, 1, logpath, &ss, "sso_issue_JWT");
  }

  nn.s = cgi->nonce; nn.len = strlen(cgi->nonce);
  id.s = jwt_id; id.len = strlen(jwt_id);

  if (cf->loguser)
    zxlogusr(cf, ses->uid, 0, 0, 0, &issuer, &nn, &id,
	     ZX_GET_CONTENT(*nameid),
	     (cf->oaz_jwt_sigenc_alg!='n'?"U":"N"), "K", logop, 0, 0);
  
  zxlog(cf, 0, 0, 0, &issuer, &nn, &id,
	ZX_GET_CONTENT(*nameid),
	(cf->oaz_jwt_sigenc_alg!='n'?"U":"N"), "K", logop, 0, 0);

  zx_str_free(cf->ctx, logpath);
  return jwt;
}

/*(i) Generate SSO assertion and ship it to SP by OAUTH2 Az redir binding. User has already
 * logged in by the time this is called. See also zxid_ssos_anreq() and zxid_idp_sso(). */

/* Called by:  zxid_idp_dispatch */
struct zx_str* zxid_oauth2_az_server_sso(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  zxid_entity* sp_meta;
  struct zx_str* acsurl = 0;
  struct timeval srcts = {0,501000};
  zxid_nid* nameid;
  char* idtok;
  char logop[8];
  strcpy(logop, "OAZxxxx");

  if (!cgi->client_id || !cgi->redirect_uri || !cgi->nonce) {
    ERR("Missing mandatory OAUTH2 field client_id=%p redirect_uri=%p nonce=%p", cgi->client_id, cgi->redirect_uri, cgi->nonce);
    return zx_dup_str(cf->ctx, "* ERR");
  }

  if (!cgi->response_type || !strstr(cgi->response_type, "token") || !strstr(cgi->response_type, "id_token")) {
    ERR("Missing mandatory OAUTH2 field response_type(%s) missing or does not contain `token id_token'", STRNULLCHKD(cgi->response_type));
    return zx_dup_str(cf->ctx, "* ERR");
  }

  if (!cgi->scope || !strstr(cgi->scope, "openid")) {
    ERR("Missing mandatory OAUTH2 field scope=%p or the scope does not contain `openid'", STRNULLCHKD(cgi->scope));
    return zx_dup_str(cf->ctx, "* ERR");
  }

  sp_meta = zxid_get_ent(cf, cgi->client_id);
  if (!sp_meta) {
    ERR("The metadata for client_id(%s) of the Az Req could not be found or fetched", cgi->client_id);
    return zx_dup_str(cf->ctx, "* ERR");
  }
  D("sp_eid(%s)", sp_meta->eid);

  /* Figure out the binding and url */

  acsurl = zxid_sp_loc_raw(cf, cgi, sp_meta, ZXID_ACS_SVC, OAUTH2_REDIR, 0);
  if (!acsurl) {
    ERR("sp(%s) metadata does not have SPSSODescriptor/AssertionConsumerService with Binding=\"" OAUTH2_REDIR "\". Pre-registering the SP at IdP is mandatory. redirect_uri(%s) will be ignored. (remote SP metadata problem)", sp_meta->eid, cgi->redirect_uri);
    return zx_dup_str(cf->ctx, "* ERR");
  }
  if (strlen(cgi->redirect_uri) != acsurl->len || memcmp(cgi->redirect_uri, acsurl->s, acsurl->len)) {
    ERR("sp(%s) metadata has SPSSODescriptor/AssertionConsumerService with Binding=\"" OAUTH2_REDIR "\" has value(%.*s), which is different from redirect_uri(%s). (remote SP problem)", sp_meta->eid, acsurl->len, acsurl->s, cgi->redirect_uri);
    return zx_dup_str(cf->ctx, "* ERR");
  }

  if (!cf->log_issue_a7n) {
    INFO("LOG_ISSUE_A7N must be turned on in IdP configuration for artifact profile to work. Turning on now automatically. %d", 0);
    cf->log_issue_a7n = 1;
  }

  /* User ses->uid is already logged in, now check for federation with sp */

  idtok = zxid_sso_issue_jwt(cf, cgi, ses, &srcts, sp_meta, acsurl, &nameid, logop);
  if (!idtok) {
    ERR("Issuing JWT Failed %s", logop);
    return zx_dup_str(cf->ctx, "* ERR");
  }
  
  D("OAUTH2-ART ep(%.*s)", acsurl->len, acsurl->s);
  zxlog(cf, 0, &srcts, 0, sp_meta->ed?&sp_meta->ed->entityID->g:0, 0, 0, ZX_GET_CONTENT(nameid), "N", "K", logop, ses->uid, "OAUTH2-ART");

  /* Formulate OAUTH2 / OpenID-Connect1 Az Redir Response */
  
  return zx_strf(cf->ctx, "Location: %s%c"
		 "access_token=%s"
		 "&token_type=bearer"
		 "&id_token=%s"
		 "&expires_in=%d" CRLF
		 "%s%s%s",   /* Set-Cookie */
		 cgi->redirect_uri, (strchr(cgi->redirect_uri, '?') ? '&' : '?'),
		 idtok,
		 idtok,
		 cf->a7nttl,
		 ses->setcookie?"Set-Cookie: ":"", ses->setcookie?ses->setcookie:"", ses->setcookie?CRLF:"");
}

/*() Extract an assertion from OAUTH Az response, and perform SSO */

/* Called by:  zxid_sp_oauth2_dispatch */
static int zxid_sp_dig_oauth_sso_a7n(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  //if (!zxid_chk_sig(cf, cgi, ses, &resp->gg, resp->Signature, resp->Issuer, 0, "Response")) return 0;
  
  //p = zxid_http_get(cf, url, &lim);

  ERR("*** process JWT %d", 0);

  //a7n = zxid_dec_a7n(cf, resp->Assertion, resp->EncryptedAssertion);
  //if (a7n) {
  //  zx_see_elem_ns(cf->ctx, &pop_seen, &resp->gg);
  //  return zxid_sp_sso_finalize(cf, cgi, ses, a7n, pop_seen);
  //}
  if (cf->anon_ok && cgi->rs && !strcmp(cf->anon_ok, cgi->rs))  /* Prefix match */
    return zxid_sp_anon_finalize(cf, cgi, ses);
  ERR("No Assertion found and not anon_ok in OAUTH Response %d", 0);
  zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "ERR", 0, "sid(%s) No assertion", ses->sid?ses->sid:"");
  return 0;
}

/*() Dispatch, on RP/SP side, OAUTH redir or artifact binding requests.
 *
 * return:: a string (such as Location: header) and let the caller output it.
 *     Sometimes a dummy string is just output to indicate status, e.g.
 *     "O" for SSO OK, "K" for normal OK no further action needed,
 *     "M" show management screen, "I" forward to IdP dispatch, or
 *     "* ERR" for error situations. These special strings
 *     are allocated from static storage and MUST NOT be freed. Other
 *     strings such as "Location: ..." should be freed by caller. */

/* Called by:  zxid_simple_no_ses_cf */
struct zx_str* zxid_sp_oauth2_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  int ret;

  if (cgi->id_token) {  /* OAUTH2 artifact / redir biding, aka OpenID-Connect1 */    
    ret = zxid_sp_dig_oauth_sso_a7n(cf, cgi, ses);
    D("ret=%d ses=%p", ret, ses);
    switch (ret) {
    case ZXID_OK:      return zx_dup_str(cf->ctx, "K");
    case ZXID_SSO_OK:  return zx_dup_str(cf->ctx, "O");
    case ZXID_IDP_REQ: /* (PXY) Middle IdP of IdP Proxy flow */
      return zx_dup_str(cf->ctx, zxid_simple_ses_active_cf(cf, cgi, ses, 0, 0x1fff));
    case ZXID_FAIL:
      D("*** FAIL, should send back to IdP select %d", 0);
      return zx_dup_str(cf->ctx, "* ERR");
    }
    return zx_dup_str(cf->ctx, "M");  /* Management screen, please. */
  }
    
  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "SPOADISP", 0, "sid(%s) unknown req or resp", STRNULLCHK(ses->sid));
  ERR("Unknown request or response %d", 0);
  return zx_dup_str(cf->ctx, "* ERR");
}

/*() Handle, on IdP side, OAUTH2 / OpenID-Connect1 check_id requests.
 *
 * return:: a string (such as Location: header) and let the caller output it.
 *     Sometimes a dummy string is just output to indicate status, e.g.
 *     "O" for SSO OK, "K" for normal OK no further action needed,
 *     "M" show management screen, "I" forward to IdP dispatch, or
 *     "* ERR" for error situations. These special strings
 *     are allocated from static storage and MUST NOT be freed. Other
 *     strings such as "Location: ..." should be freed by caller. */

/* Called by:  zxid_simple_no_ses_cf */
char* zxid_idp_oauth2_check_id(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int auto_flags)
{
  int ret = 0;

  if (cgi->id_token) {  /* OAUTH2 artifact / redir biding, aka OpenID-Connect1 */
    /* The id_token is directly the local filename of the corresponsing assertion. */
    
    D("ret=%d ses=%p", ret, ses);

    //return zxid_simple_show_page(cf, ss, ZXID_AUTO_METAC, ZXID_AUTO_METAH, "b", "text/xml", res_len, auto_flags, 0);
  }
  
  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "IDPOACI", 0, "sid(%s) unknown req or resp", STRNULLCHK(ses->sid));
  ERR("Unknown request or response %d", 0);
  return 0;
}

/* EOF  --  zxiduma.c */
