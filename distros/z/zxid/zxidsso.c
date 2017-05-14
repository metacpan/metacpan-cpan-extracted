/* zxidsso.c  -  Handwritten functions for implementing Single Sign-On logic for SP
 * Copyright (c) 2013-2014 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidsso.c,v 1.64 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 30.9.2006, added signature verification --Sampo
 * 9.10.2007, added signing SOAP requests, Destination for redirects --Sampo
 * 22.3.2008, permitted passing RelayState for SSO --Sampo
 * 7.10.2008, added documentation --Sampo
 * 1.2.2010,  added authentication service client --Sampo
 * 9.3.2011,  added Proxy IdP processing --Sampo
 * 26.10.2013, improved error reporting on credential expired case --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 */

#include "platform.h"  /* needed on Win32 for snprintf() et al. */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "wsf.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* ============== Generating and sending AuthnReq ============== */

/*() This function makes the policy decision about which profile to
 * use. It is only used if there was no explicit specification in the
 * CGI form (e.g. "Login (P)" button). Currently it is a stub that
 * always picks the SAML artifact profile. Eventually configuration options
 * or cgi input can be used to determine the profile in a more
 * sophisticated way. Often zxid_mk_authn_req() will override the
 * return value of this function by its own inspection of the CGI
 * variables. */

/* Called by:  zxid_start_sso_url */
int zxid_pick_sso_profile(zxid_conf* cf, zxid_cgi* cgi, zxid_entity* idp_meta)
{
  switch (cgi->pr_ix) {
  case ZXID_OIDC1_CODE:       return ZXID_OIDC1_CODE;
  case ZXID_OIDC1_ID_TOK_TOK: return ZXID_OIDC1_ID_TOK_TOK;
  }
  /* More sophisticated policy may eventually go here. */
  return ZXID_SAML2_ART;
}

/*() Map name id format form field to SAML specified URN string. */
/* Called by:  covimp_test x10, zxid_map_identity_token, zxid_mk_authn_req, zxid_nidmap_identity_token */
const char* zxid_saml2_map_nid_fmt(const char* f)
{
  if (!f || !f[0]) {
    ERR("NULL argument %p", f);
    return "trnsnt";
  }
#if 0
  switch (f[0]) {
  case 'n' /*'none'*/:   return "";
  case 'p' /*'prstnt'*/: return SAML2_PERSISTENT_NID_FMT;
  case 't' /*'trnsnt'*/: return SAML2_TRANSIENT_NID_FMT;
  case 'u' /*'unspfd'*/: return SAML2_UNSPECIFIED_NID_FMT;
  case 'e' /*'emladr'*/: return SAML2_EMAILADDR_NID_FMT;
  case 'x' /*'x509sn'*/: return SAML2_X509_NID_FMT;
  case 'w' /*'windmn'*/: return SAML2_WINDOMAINQN_NID_FMT;
  case 'k' /*'kerbrs'*/: return SAML2_KERBEROS_NID_FMT;
  case 's' /*'saml'*/:   return SAML2_ENTITY_NID_FMT;
  }
#else
  if (!strcmp("prstnt", f)) return SAML2_PERSISTENT_NID_FMT;
  if (!strcmp("trnsnt", f)) return SAML2_TRANSIENT_NID_FMT;
  if (!strcmp("none",   f)) return "";
  if (!strcmp("unspfd", f)) return SAML2_UNSPECIFIED_NID_FMT;
  if (!strcmp("emladr", f)) return SAML2_EMAILADDR_NID_FMT;
  if (!strcmp("x509sn", f)) return SAML2_X509_NID_FMT;
  if (!strcmp("windmn", f)) return SAML2_WINDOMAINQN_NID_FMT;
  if (!strcmp("kerbrs", f)) return SAML2_KERBEROS_NID_FMT;
  if (!strcmp("saml",   f)) return SAML2_ENTITY_NID_FMT;
#endif
  return f;
}

/*() Map protocol binding form field to SAML specified URN string. */
/* Called by:  covimp_test x7 */
const char* zxid_saml2_map_protocol_binding(const char* b)
{
  switch (b[0]) {
  case 'r' /*'redir'*/: return SAML2_REDIR;
  case 'a' /*'art'*/:   return SAML2_ART;
  case 'p' /*'post'*/:  return SAML2_POST;
  case 'q' /*'qsimplesig'*/:  return SAML2_POST_SIMPLE_SIGN;
  case 's' /*'soap'*/:  return SAML2_SOAP;
  case 'e' /*'ecp'*/:
    /*case 'paos':*/  return SAML2_PAOS;
  default:      return b;
  }
}

/*() Map SAML protocol binding URN to form field. */
/* Called by:  covimp_test x8, zxid_idp_sso x3, zxid_sp_loc_by_index_raw */
int zxid_protocol_binding_map_saml2(struct zx_str* b)
{
  if (!b || !b->len || !b->s) {
    D("No binding supplied, assume redir %d", 0);
    return 'r';
  }
  if (b->len == sizeof(SAML2_REDIR)-1 && !memcmp(b->s, SAML2_REDIR, b->len)) return 'r';
  if (b->len == sizeof(SAML2_ART)-1   && !memcmp(b->s, SAML2_ART, b->len))   return 'a';
  if (b->len == sizeof(SAML2_POST)-1  && !memcmp(b->s, SAML2_POST, b->len))  return 'p';
  if (b->len == sizeof(SAML2_POST_SIMPLE_SIGN)-1  && !memcmp(b->s, SAML2_POST_SIMPLE_SIGN, b->len)) return 'q';
  if (b->len == sizeof(SAML2_SOAP)-1  && !memcmp(b->s, SAML2_SOAP, b->len))  return 's';
  if (b->len == sizeof(SAML2_PAOS)-1  && !memcmp(b->s, SAML2_PAOS, b->len))  return 'e';
  D("Unknown binding(%.*s) supplied, assume redir.", b->len, b->s);
  return 'r';
}

/*() Map authentication contest class ref form field to SAML specified URN string. */
/* Called by:  covimp_test x8, zxid_mk_authn_req */
char* zxid_saml2_map_authn_ctx(char* c)
{
  switch (c[0]) {
  case 'n' /*'none'*/:      return "";
  case 'p':
    switch (c[2]) {
    case 'p' /*'pwp'*/:     return SAML_AUTHCTX_PASSWORDPROTECTED;
    case 0   /*'pw'*/:      return SAML_AUTHCTX_PASSWORD;
    case 'v' /*'prvses'*/:  return SAML_AUTHCTX_PREVSESS;
    }
    break;
  case 'c' /*'clicert'*/:   return SAML_AUTHCTX_SSL_TLS_CERT;
  case 'u' /*'unspcf'*/:    return SAML_AUTHCTX_UNSPCFD;
  case 'i' /*'ip'*/:        return SAML_AUTHCTX_INPROT;
  }
  return c;
}

/*() cgi->rs will be copied to ses->rs and from there in ab_pep to resource-id.
 * We compress and safe_base64 encode it to protect any URL special characters. */
/* Called by:  zxid_start_sso_url, zxid_simple_show_idp_sel */
void zxid_sso_set_relay_state_to_return_to_this_url(zxid_conf* cf, zxid_cgi* cgi)
{
  struct zx_str* ss;
  D("Previous rs(%s)", STRNULLCHKD(cgi->rs));
  // *** absolute URI consideration
  if (!cgi->rs || !cgi->rs[0]) {
    if (!cgi->uri_path) {
      ERR("null or empty cgi->uri_path=%p qs(%s) programming error", cgi->uri_path, STRNULLCHK(cgi->qs));
      if (!cgi->uri_path)
	cgi->uri_path = "";
    }
    ss = zx_strf(cf->ctx, "%s%c%s", cgi->uri_path, cgi->qs&&cgi->qs[0]?'?':0, STRNULLCHK(cgi->qs));
    cgi->rs = zxid_deflate_safe_b64_raw(cf->ctx, -2, ss->s);
    D("rs(%s) from(%s) uri_path(%s) qs(%s)",cgi->rs,ss->s,cgi->uri_path,STRNULLCHKD(cgi->qs));
    zx_str_free(cf->ctx, ss);
  }
}

/*(i) Generate an authentication request and make a URL out of it.
 *
 * cf::     Used for many configuration options and memory allocation
 * cgi::    Used to pick the desired SSO profile based on hidden fields or user
 *     input. The cgi->rs field specifies the URL to redirect to after the SSO.
 *     The cgi->eid specifies the IdP entity ID.
 * return:: Redirect URL as zx_str. Caller should eventually free this memory.
 */
/* Called by:  zxid_start_sso_location */
struct zx_str* zxid_start_sso_url(zxid_conf* cf, zxid_cgi* cgi)
{
  struct zx_md_SingleSignOnService_s* sso_svc;
  struct zx_sp_AuthnRequest_s* ar;
  struct zx_attr_s* dest;
  struct zx_str* ars;
  int sso_profile_ix;
  zxid_entity* idp_meta;
  D_INDENT("start_sso: ");
  D("cgi=%p cgi->eid=%p eid(%s) pr_ix=%d", cgi, cgi->eid, STRNULLCHKD(cgi->eid), cgi->pr_ix);
  zxid_sso_set_relay_state_to_return_to_this_url(cf, cgi);
  if (!cgi->eid || !cgi->eid[0]) {
    D("Entity ID missing %p", cgi->eid);
    cgi->err = "IdP URL Missing or incorrect";
    D_DEDENT("start_sso: ");
    return 0;
  }
  idp_meta = zxid_get_ent(cf, cgi->eid);
  if (!idp_meta) {
    cgi->err = "IdP URL incorrect or IdP does not support fetching metadata from that URL.";
    D_DEDENT("start_sso: ");
    return 0;
  }
  switch (sso_profile_ix = zxid_pick_sso_profile(cf, cgi, idp_meta)) {
  case ZXID_SAML2_ART:
  case ZXID_SAML2_POST:
  case ZXID_SAML2_POST_SIMPLE_SIGN:
    /* All of the above use redir binding for sending AnReq */
    if (!idp_meta->ed->IDPSSODescriptor) {
      ERR("Entity(%s) does not have IdP SSO Descriptor (metadata problem)", cgi->eid);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "ERR", cgi->eid, "No IDPSSODescriptor");
      cgi->err = "Bad IdP metadata. Try different IdP.";
      D_DEDENT("start_sso: ");
      return 0;
    }
    for (sso_svc = idp_meta->ed->IDPSSODescriptor->SingleSignOnService;
	 sso_svc;
	 sso_svc = (struct zx_md_SingleSignOnService_s*)sso_svc->gg.g.n) {
      if (sso_svc->gg.g.tok != zx_md_SingleSignOnService_ELEM)
	continue;
      if (sso_svc->Binding && !memcmp(SAML2_REDIR, sso_svc->Binding->g.s, sso_svc->Binding->g.len))
	break;
    }
    if (!sso_svc) {
      ERR("IdP Entity(%s) does not have any IdP SSO Service with " SAML2_REDIR " binding (metadata problem)", cgi->eid);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "ERR", cgi->eid, "No redir binding");
      cgi->err = "Bad IdP metadata. Try different IdP.";
      D_DEDENT("start_sso: ");
      return 0;
    }
    DD("HERE3 len=%d (%.*s)", sso_svc?sso_svc->Location->g.len:0, sso_svc->Location->g.len, sso_svc->Location->g.s);
    ar = zxid_mk_authn_req(cf, cgi);
    dest = zx_dup_len_attr(cf->ctx, 0, zx_Destination_ATTR, sso_svc->Location->g.len, sso_svc->Location->g.s);
    ZX_ORD_INS_ATTR(ar, Destination, dest);
    ars = zx_easy_enc_elem_opt(cf, &ar->gg);
    D("AuthnReq(%.*s) %p", ars->len, ars->s, dest);
    break;
  case ZXID_OIDC1_CODE:
  case ZXID_OIDC1_ID_TOK_TOK:
    if (!idp_meta->ed->IDPSSODescriptor) {
      ERR("Entity(%s) does not have IdP SSO Descriptor (OAUTH2) (metadata problem)", cgi->eid);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "ERR", cgi->eid, "No IDPSSODescriptor (OAUTH2)");
      cgi->err = "Bad IdP metadata (OAUTH). Try different IdP.";
      D_DEDENT("start_sso: ");
      return 0;
    }
    for (sso_svc = idp_meta->ed->IDPSSODescriptor->SingleSignOnService;
	 sso_svc;
	 sso_svc = (struct zx_md_SingleSignOnService_s*)sso_svc->gg.g.n) {
      if (sso_svc->gg.g.tok != zx_md_SingleSignOnService_ELEM)
	continue;
      if (sso_svc->Binding && !memcmp(OAUTH2_REDIR,sso_svc->Binding->g.s,sso_svc->Binding->g.len))
	break;
    }
    if (!sso_svc) {
      ERR("IdP Entity(%s) does not have any IdP SSO Service with " OAUTH2_REDIR " binding (metadata problem)", cgi->eid);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "ERR", cgi->eid, "No OAUTH2 redir binding");
      cgi->err = "Bad IdP metadata. Try different IdP.";
      D_DEDENT("start_sso: ");
      return 0;
    }
    DD("HERE3 len=%d (%.*s)", sso_svc?sso_svc->Location->g.len:0, sso_svc->Location->g.len, sso_svc->Location->g.s);
    if (cf->log_level>0)
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "OANREDIR", cgi->eid, 0);
    ars = zxid_mk_oauth_az_req(cf, cgi, &sso_svc->Location->g, cgi->rs);

    D_DEDENT("start_sso: ");
    return ars;
  default:
    NEVER("Inappropriate SSO profile: %d", sso_profile_ix);
    cgi->err = "Inappropriate SSO profile. Bad metadata?";
    D_DEDENT("start_sso: ");
    return 0;
  }
  
  if (cf->idp_ena) {  /* (PXY) Middle IdP of Proxy IdP scenario */
    if (cgi->rs) {
      ERR("Attempt to supply RelayState(%s) in middle IdP of Proxy IdP flow. Ignored.", cgi->rs);
    }
    cgi->rs = cgi->ssoreq; /* Carry the original authn req in RelayState */
    D("Middle IdP of Proxy IdP flow RelayState(%s)", STRNULLCHK(cgi->rs));
  }
  
  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "ANREDIR", cgi->eid, 0);
  ars = zxid_saml2_redir_url(cf, &sso_svc->Location->g, ars, cgi->rs);
  D_DEDENT("start_sso: ");
  return ars;
}

/*() Wrapper for zxid_start_sso_url(), used when Location header needs to be passed outside.
 * return:: Location header as zx_str. Caller should eventually free this memory. */

/* Called by:  main x2, zxid_simple_no_ses_cf */
struct zx_str* zxid_start_sso_location(zxid_conf* cf, zxid_cgi* cgi)
{
  struct zx_str* ss;
  struct zx_str* url = zxid_start_sso_url(cf, cgi);
  if (!url)
    return 0;
  ss = zx_strf(cf->ctx, "Location: %.*s" CRLF2, url->len, url->s);
  zx_str_free(cf->ctx, url);
  return ss;
}

/* ============== Process Response and SSO Assertion ============== */

/*(i) Dereference an artifact to obtain an assertion. This is the last
 * step in artifact SSO profile and involved making a SOAP call to the
 * IdP. The artifact is received in saml_art CGI field, <<see:
 * zxid_parse_cgi()>> where SAMLart query string argument is parsed. */

/* Called by:  main x2, zxid_simple_no_ses_cf */
int zxid_sp_deref_art(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  struct zx_md_ArtifactResolutionService_s* ar_svc;
  struct zx_e_Body_s* body;
  struct zx_root_s* r;
  zxid_entity* idp_meta;
  int len;
  char end_pt_ix[16];
  char* raw_succinct_id;
  /*char* msg_handle;*/
  char* p;
  char buf[64];
  D_INDENT("deref: ");

  if (!cgi || !cgi->saml_art || !*cgi->saml_art) {
    ERR("SAMLart missing or empty string. %p %p", cgi, cgi?cgi->saml_art:0);
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "ERR", cgi?cgi->saml_art:0, "Artifact missing");
    D_DEDENT("deref: ");
    return 0;
  }
  
  len = strlen(cgi->saml_art);
  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "W", "ART", cgi->saml_art, 0);
  if (len-7 >= sizeof(buf)*4/3) {
    ERR("SAMLart(%s), %d chars, too long. Max(%d) chars.", cgi->saml_art, len, (int)sizeof(buf)*4/3+6);
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "ERR", cgi->saml_art, "Artifact too long");
    D_DEDENT("deref: ");
    return 0;
  }
  p = unbase64_raw(cgi->saml_art, cgi->saml_art + len, buf, zx_std_index_64);
  *p = 0;
  if (buf[0])
    goto badart;
  switch (buf[1]) {
  case 0x03: /* SAML 1.1 */
    end_pt_ix[0] = 0;
    raw_succinct_id = buf + 2;
    /*msg_handle = buf + 22;*/
    break;
  case 0x04: /* SAML 2.0 */
    sprintf(end_pt_ix, "%d", (unsigned)buf[2] << 8 | (unsigned)buf[3]);
    raw_succinct_id = buf + 4;
    /*msg_handle = buf + 24;*/
    break;
  default: goto badart;
  }
  
  idp_meta = zxid_get_ent_by_succinct_id(cf, raw_succinct_id);
  if (!idp_meta || !idp_meta->eid) {
    ERR("Unable to dereference SAMLart(%s). Can not find metadata for IdP. %p", cgi->saml_art, idp_meta);
    D_DEDENT("deref: ");
    return 0;
  }
  
  switch (buf[1]) {
  case 0x03: /* SAML 1.1 */
    /* *** ff12_resolve_art() */
    break;
  case 0x04: /* SAML 2.0 */
    if (!idp_meta->ed->IDPSSODescriptor) {
      ERR("Entity(%s) does not have IdP SSO Descriptor (metadata problem)", idp_meta->eid);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "ERR", 0, "No IDPSSODescriptor eid(%s)", idp_meta->eid);
      D_DEDENT("deref: ");
      return 0;
    }
    for (ar_svc = idp_meta->ed->IDPSSODescriptor->ArtifactResolutionService;
	 ar_svc;
	 ar_svc = (struct zx_md_ArtifactResolutionService_s*)ar_svc->gg.g.n) {
      if (ar_svc->gg.g.tok != zx_md_ArtifactResolutionService_ELEM)
	continue;
      if (ar_svc->Binding  && !memcmp(SAML2_SOAP, ar_svc->Binding->g.s, ar_svc->Binding->g.len)
	  && ar_svc->index && !memcmp(end_pt_ix, ar_svc->index->g.s, ar_svc->index->g.len)
	  && ar_svc->Location)
	break;
    }
    if (!ar_svc) {
      ERR("Entity(%s) does not have any IdP Artifact Resolution Service with " SAML2_SOAP " binding and index(%s) (metadata problem)", idp_meta->eid, end_pt_ix);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "ERR", 0, "No Artifact Resolution Svc eid(%s) ep_ix(%s)", idp_meta->eid, end_pt_ix);
      D_DEDENT("deref: ");
      return 0;
    }
    
    body = zx_NEW_e_Body(cf->ctx,0);
    body->ArtifactResolve = zxid_mk_art_deref(cf, &body->gg, idp_meta, cgi->saml_art);
    r = zxid_soap_call_hdr_body(cf, &ar_svc->Location->g, 0, body);
    len =  zxid_sp_soap_dispatch(cf, cgi, ses, r);
    D_DEDENT("deref: ");
    return len;
  default: goto badart;
  }
  
 badart:
  ERR("Bad SAMLart type code 0x%02x 0x%02x", buf[0], buf[1]);
  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "ERR", 0, "Bad SAMLart type code 0x%02x 0x%02x", buf[0], buf[1]);
  D_DEDENT("deref: ");
  return 0;
}

/*() Map ZXSIG constant to letter for log and string message. */

/* Called by:  covimp_test x11, zxid_chk_sig, zxid_decode_redir_or_post, zxid_sp_sso_finalize, zxid_wsc_valid_re_env, zxid_wsf_validate_a7n, zxid_wsp_validate_env */
void zxid_sigres_map(int sigres, char** sigval, char** sigmsg)
{
  switch (sigres) {
  case ZXSIG_OK:
    D("Signature validated. %d", 1);
    *sigval = "O";
    *sigmsg = "Signature validated.";
    break;
  case ZXSIG_BAD_DALGO:  /* 1 Unsupported digest algorithm. */
    ERR("Bad digest algo. %d", sigres);
    *sigval = "A";
    *sigmsg = "Unsupported digest algorithm. Signature can not be validated.";
    break;
  case ZXSIG_DIGEST_LEN: /* 2 Wrong digest length. */
    ERR("Bad digest length. %d", sigres);
    *sigval = "G";
    *sigmsg = "Wrong digest length. Signature can not be validated.";
    break;
  case ZXSIG_BAD_DIGEST: /* 3 Digest value does not match. */
    ERR("Bad digest. Canon problem? %d", sigres);
    *sigval = "G";
    *sigmsg = "Message digest does not match signed content. Canonicalization problem? Or falsified or altered or substituted content. Signature can not be validated.";
    break;
  case ZXSIG_BAD_SALGO:  /* 4 Unsupported signature algorithm. */
    ERR("Bad sig algo. %d", sigres);
    *sigval = "A";
    *sigmsg = "Unsupported signature algorithm. Signature can not be validated.";
    break;
  case ZXSIG_BAD_CERT:   /* 5 Extraction of public key from certificate failed. */
    ERR("Bad cert. %d", sigres);
    *sigval = "I";
    *sigmsg = "Bad IdP certificate or bad IdP metadata or unknown IdP. Signature can not be validated.";
    break;
  case ZXSIG_VFY_FAIL:   /* 6 Verification of signature failed. */
    ERR("Bad sig. %d", sigres);
    *sigval = "R";
    *sigmsg = "Signature does not match signed content (but content checksum matches). Content may have been falsified, altered, or substituted; or IdP metadata does not match the keys actually used by the IdP.";
    break;
  case ZXSIG_NO_SIG:
    ERR("Not signed. %d", sigres);
    *sigval = "N";
    *sigmsg = "No signature found.";
    break;
  case ZXSIG_TIMEOUT:
    ERR("Out of validity period. %d", sigres);
    *sigval = "V";
    *sigmsg = "Assertion is not in its validity period.";
    break;
  case ZXSIG_AUDIENCE:
    ERR("Wrong audience. %d", sigres);
    *sigval = "V";
    *sigmsg = "Assertion has wrong audience.";
    break;
  default:
    ERR("Other sig err(%d)", sigres);
    *sigval = "E";
    *sigmsg = "Broken or unvalidatable signature.";
  }
}

/*(i) Validates conditions required by Liberty Alliance SAML2 conformance testing.
 *
 * May eventually validate additional conditions as well (this is the right place
 * to add them). N.B. It is not an error if a condition is missing, or there
 * is no Conditions element at all.
 *
 * cf::      Configuration object, used to determine time slops. Potentially
 *     used for memory allocation via cf->ctx.
 * cgi::     Optional CGI object. If non-NULL, sigval and sigmsg will be set.
 * ses::     Optional session object. If non-NULL, then sigres code will be set.
 * a7n::     Assertion whose conditions are checked.
 * myentid:: Entity ID used for checking audience restriction. Typically from zxid_my_ent_id(cf)
 * ourts::   Timestamp for validating NotOnOrAfter and NotBefore.
 * err::     Result argument: Error letter (as may appear in audit log entry). The returned
 *     string will be a constant and MUST NOT be freed by the caller.
 * return::  0 (ZXSIG_OK) if validation was successful, otherwise a ZXSIG error code. */

/* Called by:  zxid_sp_sso_finalize, zxid_wsf_validate_a7n */
int zxid_validate_cond(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_a7n* a7n, struct zx_str* myentid, struct timeval* ourts, char** err)
{
  struct timeval tsbuf;
  struct zx_sa_AudienceRestriction_s* audr;
  struct zx_elem_s* aud;
  struct zx_str* ss;
  int secs;

  if (!a7n || !a7n->Conditions) {
    INFO("Assertion does not have Conditions. %p", a7n);
    return ZXSIG_OK;
  }
  if (!myentid || !myentid->len) {
    ERR("My entity ID missing %p", myentid);
    return ZXSIG_OK;
  }

  if (!ourts) {
    GETTIMEOFDAY(&tsbuf, 0);
    ourts = &tsbuf;
  }

  if (a7n->Conditions->AudienceRestriction) {
    for (audr = a7n->Conditions->AudienceRestriction;
	 audr;
	 audr = (struct zx_sa_AudienceRestriction_s*)audr->gg.g.n) {
      if (audr->gg.g.tok != zx_sa_AudienceRestriction_ELEM)
	continue;
      for (aud = audr->Audience;
	   aud;
	   aud = (struct zx_elem_s*)aud->g.n) {
	if (aud->g.tok != zx_sa_Audience_ELEM)
	  continue;
	ss = ZX_GET_CONTENT(aud);
	if (ss?ss->len:0 == myentid->len && !memcmp(ss->s, myentid->s, ss->len)) {
	  D("Found audience. %d", 1);
	  goto found_audience;
	}
      }
    }
    if (cgi) {
      cgi->sigval = "V";
      cgi->sigmsg = "This SP not included in the Assertion Audience.";
    }
    if (ses)
      ses->sigres = ZXSIG_AUDIENCE;
    if (cf->audience_fatal) {
      ERR("SSO error: AudienceRestriction wrong. My entityID(%.*s)", myentid->len, myentid->s);
      if (err)
	*err = "P";
      if (ses) {
	zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Audience Restriction is wrong. Configuration or implementation error.", TAS3_STATUS_BADCOND, 0, "a7n", 0));
      }
      return ZXSIG_AUDIENCE;
    } else {
      INFO("SSO warn: AudienceRestriction wrong. My entityID(%.*s). Configured to ignore this (AUDIENCE_FATAL=0).", myentid->len, myentid->s);
    }
  } else {
    INFO("Assertion does not have AudienceRestriction. %d", 0);
  }
 found_audience:
  
  if (a7n->Conditions->NotOnOrAfter && a7n->Conditions->NotOnOrAfter->g.len > 18) {
    secs = zx_date_time_to_secs(a7n->Conditions->NotOnOrAfter->g.s);
    if (secs <= ourts->tv_sec) {
      if (secs + cf->after_slop <= ourts->tv_sec) {
	ERR("NotOnOrAfter rejected with slop of %d. Time to expiry %ld secs. Our gettimeofday: %ld secs, remote: %d secs. Relogin to refresh the session?", cf->after_slop, secs - ourts->tv_sec, ourts->tv_sec, secs);
	if (cgi) {
	  cgi->sigval = "V";
	  cgi->sigmsg = "Assertion has expired. Relogin to refresh the session?";
	}
	if (ses)
	  ses->sigres = ZXSIG_TIMEOUT;
	if (cf->timeout_fatal) {
	  if (err)
	    *err = "P";
	  if (ses) {
	    /* This is the only problem fixable by the user so emit a special
	     * informative message with distinctive error code. It may even be
	     * possible for the client end to automatically refresh the credential. */
	    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Assertion has expired (or clock synchrony problem between servers). Perhaps relogin to refresh the session will fix the problem?", TAS3_STATUS_EXPIRED, 0, "a7n", 0));
	  }
	  return ZXSIG_TIMEOUT;
	}
      } else {
	D("NotOnOrAfter accepted with slop of %d. Time to expiry %ld secs. Our gettimeofday: %ld secs, remote: %d secs", cf->after_slop, secs - ourts->tv_sec, ourts->tv_sec, secs);
      }
    } else {
      D("NotOnOrAfter ok. Time to expiry %ld secs. Our gettimeofday: %ld secs, remote: %d secs", secs - ourts->tv_sec, ourts->tv_sec, secs);
    }
  } else {
    INFO("Assertion does not have NotOnOrAfter. %d", 0);
  }
  
  if (a7n->Conditions->NotBefore && a7n->Conditions->NotBefore->g.len > 18) {
    secs = zx_date_time_to_secs(a7n->Conditions->NotBefore->g.s);
    if (secs > ourts->tv_sec) {
      if (secs - cf->before_slop > ourts->tv_sec) {
	ERR("NotBefore rejected with slop of %d. Time to validity %ld secs. Our gettimeofday: %ld secs, remote: %d secs", cf->before_slop, secs - ourts->tv_sec, ourts->tv_sec, secs);
	if (cgi) {
	  cgi->sigval = "V";
	  cgi->sigmsg = "Assertion is not valid yet (too soon). Clock synchrony problem between servers?";
	}
	if (ses)
	  ses->sigres = ZXSIG_TIMEOUT;
	if (cf->timeout_fatal) {
	  if (err)
	    *err = "P";
	  if (ses) {
	    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Assertion is not valid yet (too soon). Clock synchrony problem between servers?", TAS3_STATUS_BADCOND, 0, "a7n", 0));
	  }
	  return ZXSIG_TIMEOUT;
	}
      } else {
	D("NotBefore accepted with slop of %d. Time to validity %ld secs. Our gettimeofday: %ld secs, remote: %d secs", cf->before_slop, secs - ourts->tv_sec, ourts->tv_sec, secs);
      }
    } else {
      D("NotBefore ok. Time from validity %ld secs. Our gettimeofday: %ld secs, remote: %d secs", ourts->tv_sec - secs, ourts->tv_sec, secs);
    }
  } else {
    INFO("Assertion does not have NotBefore. %d", 0);
  }
  return ZXSIG_OK;
}

struct zx_str unknown_str = {0,0,1,"??"};  /* Static string used as dummy value. */

/*(i) zxid_sp_sso_finalize() gets called irrespective of binding (POST, Artifact)
 * and validates the SSO a7n, including the authentication statement.
 * Then, it creates session and optionally user entry.
 *
 * cf::  Configuration object, used to determine time slops, potentially memalloc via cf->ctx
 * cgi:: CGI object. sigval and sigmsg may be set.
 * ses:: Session object. Will be modified according to new session created from the SSO assertion.
 * a7n:: Single Sign-On assertion
 * return:: 0 for failure, otherwise some success code such as ZXID_SSO_OK
 *
 * See also: zxid_sp_sso_finalize_jwt() in zxidoauth.c
 */

/* Called by:  main, sig_validate, zxid_sp_dig_oauth_sso_a7n, zxid_sp_dig_sso_a7n */
int zxid_sp_sso_finalize(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_a7n* a7n, struct zx_ns_s* pop_seen)
{
  char* err = "S"; /* See: RES in zxid-log.pd, section "ZXID Log Format" */
  struct timeval ourts;
  struct timeval srcts = {0,501000};
  struct zx_str* logpath;
  struct zx_str* issuer = &unknown_str;
  struct zx_str* subj = &unknown_str;
  struct zx_str* ss;
  struct zxsig_ref refs;
  zxid_entity* idp_meta;
  /*ses->sigres = ZXSIG_NO_SIG; set earlier, do not overwrite */
  ses->a7n = a7n;
  ses->rs = cgi->rs;
  ses->ssores = 1;
  GETTIMEOFDAY(&ourts, 0);
  
  D_INDENT("ssof: ");

  if (!a7n || !a7n->AuthnStatement) {
    ERR("SSO failed: no assertion supplied, or assertion didn't contain AuthnStatement. %p", a7n);
    goto erro;
  }
  if (!a7n->IssueInstant || !a7n->IssueInstant->g.len || !a7n->IssueInstant->g.s || !a7n->IssueInstant->g.s[0]) {
    ERR("SSO failed: assertion does not have IssueInstant or it is empty. %p", a7n->IssueInstant);
    goto erro;
  }
  srcts.tv_sec = zx_date_time_to_secs(a7n->IssueInstant->g.s);
  if (!(issuer = ZX_GET_CONTENT(a7n->Issuer))) {
    ERR("SSO failed: assertion does not have Issuer. %p", a7n->Issuer);
    goto erro;
  }
  
  /* See zxid_wsp_validate() for similar code. *** consider factoring out commonality */
  
  if (!a7n->Subject) {
    ERR("SSO failed: assertion does not have Subject. %p", a7n);
    goto erro;
  }

  ses->nameid = zxid_decrypt_nameid(cf, a7n->Subject->NameID, a7n->Subject->EncryptedID);
  if (!(subj = ZX_GET_CONTENT(ses->nameid))) {
    ERR("SSO failed: assertion does not have Subject->NameID. %p", ses->nameid);
    goto erro;
  }
  
  ses->nid = zx_str_to_c(cf->ctx, subj);
  if (ses->nameid->Format && !memcmp(ses->nameid->Format->g.s, SAML2_TRANSIENT_NID_FMT, ses->nameid->Format->g.len)) {
    ses->nidfmt = 0;
  } else {
    ses->nidfmt = 1;  /* anything nontransient may be a federation */
  }

  /* In SSO the acting identity and the target identity are the same */
  ses->tgta7n = ses->a7n;
  ses->tgtnameid = ses->nameid;
  ses->tgt = ses->nid;
  ses->tgtfmt = ses->nidfmt;

  if (a7n->AuthnStatement->SessionIndex)
    ses->sesix = zx_str_to_c(cf->ctx, &a7n->AuthnStatement->SessionIndex->g);
  
  D("SSOA7N received. NID(%s) FMT(%d) SESIX(%s)", ses->nid, ses->nidfmt, STRNULLCHK(ses->sesix));
  
  /* Validate signature (*** add Issuer trusted check, CA validation, etc.) */
  
  idp_meta = zxid_get_ent_ss(cf, issuer);
  if (!idp_meta) {
    ERR("Unable to find metadata for Issuer(%.*s).", issuer->len, issuer->s);
    cgi->sigval = "I";
    cgi->sigmsg = "Issuer of Assertion unknown.";
    ses->sigres = ZXSIG_NO_SIG;
    if (cf->nosig_fatal) {
      err = "P";
      goto erro;
    }
  } else {
    if (a7n->Signature && a7n->Signature->SignedInfo && a7n->Signature->SignedInfo->Reference) {
      zx_reset_ns_ctx(cf->ctx);      
      ZERO(&refs, sizeof(refs));
      refs.sref = a7n->Signature->SignedInfo->Reference;
      refs.blob = &a7n->gg;
      refs.pop_seen = pop_seen;
      zx_see_elem_ns(cf->ctx, &refs.pop_seen, &a7n->gg);
      ses->sigres = zxsig_validate(cf->ctx, idp_meta->sign_cert, a7n->Signature, 1, &refs);
      zxid_sigres_map(ses->sigres, &cgi->sigval, &cgi->sigmsg);
    } else {
      if (cf->msg_sig_ok && !ses->sigres) {
	INFO("Assertion without signature accepted due to message level signature (SimpleSign) %d", 0);
      } else {
	ERR("SSO warn: assertion not signed. Sigval(%s) %p", STRNULLCHKNULL(cgi->sigval), a7n->Signature);
	cgi->sigval = "N";
	cgi->sigmsg = "Assertion was not signed.";
	ses->sigres = ZXSIG_NO_SIG;
	if (cf->nosig_fatal) {
	  err = "P";
	  goto erro;
	}
      }
    }
  }
  if (cf->sig_fatal && ses->sigres) {
    ERR("Fail SSO due to failed signature sigres=%d", ses->sigres);
    err = "P";
    goto erro;
  }
  
  if (zxid_validate_cond(cf, cgi, ses, a7n, zxid_my_ent_id(cf), &ourts, &err))
    goto erro;
  
  if (cf->log_rely_a7n) {
    DD("Logging... %d", 0);
    logpath = zxlog_path(cf, issuer, &a7n->ID->g, ZXLOG_RELY_DIR, ZXLOG_A7N_KIND, 1);
    if (logpath) {
      ses->sso_a7n_path = ses->tgt_a7n_path = zx_str_to_c(cf->ctx, logpath);
      ss = zx_easy_enc_elem_sig(cf, &a7n->gg);
      if (zxlog_dup_check(cf, logpath, "SSO assertion")) {
	if (cf->dup_a7n_fatal) {
	  err = "C";
	  zxlog_blob(cf, cf->log_rely_a7n, logpath, ss, "sp_sso_finalize dup err");
	  goto erro;
	}
      }
      zxlog_blob(cf, cf->log_rely_a7n, logpath, ss, "sp_sso_finalize");
      zx_str_free(cf->ctx, ss);
    }
  }
  DD("Creating session... %d", 0);
  ses->ssores = 0;
  zxid_put_ses(cf, ses);
  zxid_snarf_eprs_from_ses(cf, ses);  /* Harvest bootstrap(s) from attribute statements */
  cgi->msg = "SSO completed and session created.";
  cgi->op = '-';  /* Make sure management screen does not try to redispatch. */
  zxid_put_user(cf, &ses->nameid->Format->g, &ses->nameid->NameQualifier->g, &ses->nameid->SPNameQualifier->g, ZX_GET_CONTENT(ses->nameid), 0);
  DD("Logging... %d", 0);
  zxlog(cf, &ourts, &srcts, 0, issuer, 0, &a7n->ID->g, subj,
	cgi->sigval, "K", "NEWSES", ses->sid, "sesix(%s)", STRNULLCHKD(ses->sesix));
  zxlog(cf, &ourts, &srcts, 0, issuer, 0, &a7n->ID->g, subj,
	cgi->sigval, "K", ses->nidfmt?"FEDSSO":"TMPSSO", STRNULLCHKD(ses->sesix), 0);

  if (cf->idp_ena) {  /* (PXY) Middle IdP of Proxy IdP flow */
    if (cgi->rs && cgi->rs[0]) {
      D("ProxyIdP got RelayState(%s) ar(%s)", cgi->rs, STRNULLCHK(cgi->ssoreq));
      cgi->saml_resp = 0;  /* Clear Response to prevent re-interpretation. We want Request. */
      cgi->ssoreq = cgi->rs;
      zxid_decode_ssoreq(cf, cgi);
      cgi->op = 'V';
      D_DEDENT("ssof: ");
      return ZXID_IDP_REQ; /* Cause zxid_simple_idp_an_ok_do_rest() to be called from zxid_sp_dispatch(); */
    } else {
      INFO("Middle IdP of Proxy IdP flow did not receive RelayState from upstream IdP %p", cgi->rs);
    }
  }
  D_DEDENT("ssof: ");
  return ZXID_SSO_OK;

erro:
  ERR("SSO fail (%s)", err);
  cgi->msg = "SSO failed. This could be due to signature, timeout, etc., technical failures, or by policy.";
  zxlog(cf, &ourts, &srcts, 0, issuer, 0, a7n?&a7n->ID->g:0, subj,
	cgi->sigval, err, ses->nidfmt?"FEDSSO":"TMPSSO", STRNULLCHKD(ses->sesix), "Error.");
  D_DEDENT("ssof: ");
  return 0;
}

/*() Fake a login and generate a session. Used if SSO failure is configured to result
 * anonymous session.
 *
 * cf::  Configuration object, used to determine time slops, potentially memalloc via cf->ctx
 * cgi:: CGI object. sigval and sigmsg may be set.
 * ses:: Session object. Will be modified according to new session created from the SSO assertion.
 * return:: 0 for failure, otherwise some success code such as ZXID_SSO_OK */

/* Called by:  covimp_test, zxid_sp_dig_oauth_sso_a7n, zxid_sp_dig_sso_a7n */
int zxid_sp_anon_finalize(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  D_INDENT("anon_ssof: ");
  cgi->sigval = "N";
  cgi->sigmsg = "Anonymous login. No signature.";
  ses->sigres = ZXSIG_NO_SIG;
  ses->a7n = 0;
  ses->rs = cgi->rs;
  ses->nameid = 0;
  ses->nid = "-";
  ses->nidfmt = 0;
  ses->sesix = 0;
  
  D("SSO FAIL: ANON_OK. Creating session... %p", ses);
  
  zxid_put_ses(cf, ses);
  zxid_snarf_eprs_from_ses(cf, ses);  /* Harvest attributes and bootstrap(s) */
  cgi->msg = "SSO Failure treated as anonymous login and session created.";
  cgi->op = '-';  /* Make sure management screen does not try to redispatch. */
  /*zxid_put_user(cf, ses->nameid->Format, ses->nameid->NameQualifier, ses->nameid->SPNameQualifier, ZX_GET_CONTENT(ses->nameid), 0);*/
  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, cgi->sigval, "K", "TMPSSO", "-", 0);
  D_DEDENT("anon_ssof: ");
  return ZXID_SSO_OK;
}

/*() Authentication Service Client
 * cgi->uid and cgi->pw contain the credentials
 * See also: zxid_idp_as_do()
 */

/* Called by:  zxid_as_call */
int zxid_as_call_ses(zxid_conf* cf, zxid_entity* idp_meta, zxid_cgi* cgi, zxid_ses* ses)
{
  int len;
  struct zx_root_s* r;
  struct zx_e_Body_s* body;
#if 0
  struct zx_md_ArtifactResolutionService_s* ar_svc;
#else
  struct zx_md_SingleLogoutService_s* ar_svc;
#endif
  struct zx_as_SASLResponse_s* res;
  char* buf;
  char* b64;
  char* p;
  D_INDENT("as_call: ");

  if (!cf || !cgi || !ses || !cgi->uid || !cgi->pw) {
    ERR("Missing user, password, or mandatory argument cgi=%p (caller programming error)", cgi);
    D_DEDENT("as_call: ");
    return 0;
  }
  
  if (!idp_meta || !idp_meta->eid || !idp_meta->ed->IDPSSODescriptor) {
    ERR("Entity(%s) does not have IdP SSO Descriptor (metadata problem)", idp_meta?STRNULLCHKQ(idp_meta->eid):"-");
    zxlog(cf, 0,0,0,0,0,0,0, "N", "B", "ERR", 0, "No IDPSSODescriptor eid(%*s)", idp_meta?STRNULLCHKQ(idp_meta->eid):"-");
    D_DEDENT("as_call: ");
    return 0;
  }

#if 0
  for (ar_svc = idp_meta->ed->IDPSSODescriptor->ArtifactResolutionService;
       ar_svc;
       ar_svc = (struct zx_md_ArtifactResolutionService_s*)ar_svc->gg.g.n) {
    if (ar_svc->gg.g.tok != zx_md_ArtifactResolutionService_ELEM)
      continue;
    if (ar_svc->Binding  && !memcmp(SAML2_SOAP, ar_svc->Binding->s, ar_svc->Binding->len)
	/*&& ar_svc->index && !memcmp(end_pt_ix, ar_svc->index->s, ar_svc->index->len)*/
	&& ar_svc->Location)
      break;
  }
#else
  /* *** Kludge: We use the SLO SOAP endpoint for AS. ArtifactResolution might be more natural. */
  for (ar_svc = idp_meta->ed->IDPSSODescriptor->SingleLogoutService;
       ar_svc;
       ar_svc = (struct zx_md_SingleLogoutService_s*)ar_svc->gg.g.n) {
    if (ar_svc->gg.g.tok != zx_md_SingleLogoutService_ELEM)
      continue;
    if (ar_svc->Binding  && !memcmp(SAML2_SOAP, ar_svc->Binding->g.s, ar_svc->Binding->g.len)
	/*&& ar_svc->index && !memcmp(end_pt_ix, ar_svc->index->s, ar_svc->index->len)*/
	&& ar_svc->Location)
      break;
  }
#endif
  if (!ar_svc) {
    ERR("Entity(%s) does not have any IdP Artifact Resolution Service with " SAML2_SOAP " binding (metadata problem)", idp_meta->eid);
    zxlog(cf, 0,0,0,0,0,0,0,"N","B","ERR",0,"No Artifact Resolution Svc eid(%s)", idp_meta->eid);
    D_DEDENT("as_call: ");
    return 0;
  }

  len = 1+strlen(cgi->uid)+1+strlen(cgi->pw)+1;
  p = buf = ZX_ALLOC(cf->ctx, len);
  *p++ = 0;
  strcpy(p, cgi->uid);
  p += strlen(cgi->uid) + 1;
  strcpy(p, cgi->pw);
  
  b64 = ZX_ALLOC(cf->ctx, SIMPLE_BASE64_LEN(len)+1);
  p = base64_fancy_raw(buf, len, b64, std_basis_64, 1<<31, 0, 0, '=');
  *p = 0;
  ZX_FREE(cf->ctx, buf);
  
  body = zx_NEW_e_Body(cf->ctx,0);
  body->SASLRequest = zx_NEW_as_SASLRequest(cf->ctx, &body->gg);
  body->SASLRequest->mechanism = zx_dup_attr(cf->ctx, &body->SASLRequest->gg, zx_mechanism_ATTR, "PLAIN");
  body->SASLRequest->Data = zx_ref_len_elem(cf->ctx, &body->SASLRequest->gg, zx_as_Data_ELEM, p-b64, b64);
  r = zxid_soap_call_hdr_body(cf, &ar_svc->Location->g, 0, body);
  /* *** free the body */
  
  if (!r || !r->Envelope || !r->Envelope->Body || !(res = r->Envelope->Body->SASLResponse)) {
    ERR("Autentication Service call failed idp(%s). Missing response.", idp_meta->eid);
    zxlog(cf, 0,0,0,0,0,0,0, "N", "B", "ERR", 0, "Missing response eid(%s)", idp_meta->eid);
    D_DEDENT("as_call: ");
    return 0;
  }
  
  if (!res->Status || !res->Status->code || !res->Status->code->g.len || !res->Status->code->g.s) {
    ERR("Autentication Service call failed idp(%s). Missing Status code.", idp_meta->eid);
    zxlog(cf, 0,0,0,0,0,0,0, "N", "B", "ERR", 0, "Missing Status code eid(%s)", idp_meta->eid);
    D_DEDENT("as_call: ");
    return 0;
  }

  if (res->Status->code->g.len != 2
      || res->Status->code->g.s[0]!='O' || res->Status->code->g.s[1]!='K') {  /* "OK" */
    ERR("Autentication Service call failed idp(%s). Status code(%.*s).", idp_meta->eid, res->Status->code->g.len, res->Status->code->g.s);
    zxlog(cf, 0,0,0,0,0,0,0, "N", "B", "ERR", 0, "Missing Status code(%.*s) eid(%s)", res->Status->code->g.len, res->Status->code->g.s, idp_meta->eid);
    D_DEDENT("as_call: ");
    return 0;
  }
  
  ses->sigres = ZXSIG_NO_SIG;
  ses->a7n = 0;
  ses->nameid = 0;
  ses->nid = "-";
  ses->nidfmt = 0;
  ses->sesix = 0;
  
  D("AuthenSvc OK. Creating session... %p", ses);
  
  zxid_put_ses(cf, ses);
  zxid_ses_to_pool(cf, ses);  /* Process SSO a7n, applying NEED, WANT, and INMAP */
  zxid_snarf_eprs(cf, ses, res->EndpointReference);
  
  /* *** free r */
  D_DEDENT("as_call: ");
  return ZXID_SSO_OK;
}

/* Called by:  zxcall_main */
zxid_ses* zxid_as_call(zxid_conf* cf, zxid_entity* idp_meta, const char* user, const char* pw)
{
  zxid_ses* ses = zxid_alloc_ses(cf);
  zxid_cgi cgi;
  ZERO(&cgi, sizeof(cgi));
  cgi.uid = (char*)user;
  cgi.pw = (char*)pw;
  
  if (!zxid_as_call_ses(cf, idp_meta, &cgi, ses)) {
    ZX_FREE(cf->ctx, ses);
    return 0;
  }
  return ses;
}

/* EOF  --  zxidsso.c */
