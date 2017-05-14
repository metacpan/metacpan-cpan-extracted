/* zxidslo.c  -  Handwritten functions for implementing Single LogOut logic for SP
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidslo.c,v 1.42 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 12.10.2007, tweaked for signing SLO and MNI --Sampo
 * 14.4.2008,  added SimpleSign --Sampo
 * 7.10.2008,  added documentation --Sampo
 * 12.2.2010,  added locking to lazy loading --Sampo
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* ============== Single Logout ============== */

/*(i) SOAP client for sending Single Logout to IdP. The SOAP call is made
 * using CURL HTTP Client and will block until response is received.
 *
 * return:: 1 if successful. 0 upon failure. */

/* Called by:  zxid_mgmt, zxid_simple_ses_active_cf */
int zxid_sp_slo_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;

  zxid_get_ses_sso_a7n(cf, ses);  
  if (ses->a7n) {
    struct zxsig_ref refs;
    struct zx_root_s* r;
    struct zx_e_Body_s* body;
    struct zx_str* ses_ix;
    zxid_entity* idp_meta;
    
    ses_ix = ses->a7n->AuthnStatement?&ses->a7n->AuthnStatement->SessionIndex->g:0;
    if (cf->log_level>0)
      zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "W", "SLOSOAP", ses->sid, "sesix(%.*s)", ses_ix?ses_ix->len:1, ses_ix?ses_ix->s:"?");
    
    idp_meta = zxid_get_ses_idp(cf, ses);
    if (!idp_meta)
      return 0;
    
    body = zx_NEW_e_Body(cf->ctx,0);
    body->LogoutRequest = zxid_mk_logout(cf, zxid_get_user_nameid(cf, ses->nameid), ses_ix, idp_meta);
    if (cf->sso_soap_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = &body->LogoutRequest->ID->g;
      refs.canon = zx_easy_enc_elem_sig(cf, &body->LogoutRequest->gg);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert slo")) {
	body->LogoutRequest->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&body->LogoutRequest->gg, &body->LogoutRequest->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
    r = zxid_idp_soap(cf, cgi, ses, idp_meta, ZXID_SLO_SVC, body);
    if (!zxid_saml_ok(cf, cgi, r->Envelope->Body->LogoutResponse->Status, "LogoutResp"))
      return 0;
    return 1;
  }
  if (ses->a7n11) {
    ERR("Not implemented, SAML 1.1 assetion %d", 0);
  }
  if (ses->a7n12) {
    ERR("Not implemented, ID-FF 1.2 type SAML 1.1 assetion %d", 0);
  }
  ERR("Session sid(%s) lacks SSO assertion.", ses->sid);
  return 0;
}

/*(i) Send Single Logout to IdP using redirect binding. This function
 * generates the URL encapsulating the request. You need to pass this
 * URL to the appropriate function in your environment to provoke
 * an HTTP 302 redirect.
 *
 * cf:: ZXID config object, also used for memory allocation
 * cgi:: Data parsed from POST or query string. Provides parameters to determine
 *     details of the SLO request
 * ses:: Session object. Used to determine session index (~ses_ix~) and name id, among others
 * return:: location string if successful. "* ERR" upon failure. */

/* Called by:  zxid_mgmt, zxid_simple_ses_active_cf */
struct zx_str* zxid_sp_slo_redir(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  zxid_get_ses_sso_a7n(cf, ses);
  if (ses->a7n) {
    struct zx_sp_LogoutRequest_s* r;
    struct zx_str* rs;
    struct zx_str* loc;
    zxid_entity* idp_meta;
    struct zx_str* ses_ix;

    ses_ix = ses->a7n->AuthnStatement?&ses->a7n->AuthnStatement->SessionIndex->g:0;
    if (cf->log_level>0)
      zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "W", "SLOREDIR", ses->sid, "sesix(%.*s)", ses_ix?ses_ix->len:1, ses_ix?ses_ix->s:"?");
    
    idp_meta = zxid_get_ses_idp(cf, ses);
    if (!idp_meta)
      return zx_dup_str(cf->ctx, "* ERR");

    loc = zxid_idp_loc(cf, cgi, ses, idp_meta, ZXID_SLO_SVC, SAML2_REDIR);
    if (!loc)
      return zx_dup_str(cf->ctx, "* ERR");
    r = zxid_mk_logout(cf, zxid_get_user_nameid(cf, ses->nameid), ses_ix, idp_meta);
    r->Destination = zx_ref_len_attr(cf->ctx, &r->gg, zx_Destination_ATTR, loc->len, loc->s);
    rs = zx_easy_enc_elem_opt(cf, &r->gg);
    D("SLO(%.*s)", rs->len, rs->s);
    return zxid_saml2_redir(cf, loc, rs, 0);
  }
  if (ses->a7n11) {
    ERR("Not implemented, SAML 1.1 assetion %d", 0);
  }
  if (ses->a7n12) {
    ERR("Not implemented, ID-FF 1.2 type SAML 1.1 assetion %d", 0);
  }
  ERR("Session sid(%s) lacks SSO assertion.", ses->sid);
  return zx_dup_str(cf->ctx, "* ERR");
}

/*() Generate SLO Response, SP or IdP variant. The actual session invalidation must be
 * done somewhere else, i.e. this is just the final protocol phase of the SLO. */

/* Called by:  zxid_idp_dispatch, zxid_sp_dispatch */
struct zx_str* zxid_slo_resp_redir(zxid_conf* cf, zxid_cgi* cgi, struct zx_sp_LogoutRequest_s* req)
{
  struct zx_sp_LogoutResponse_s* res;
  zxid_entity* meta;
  struct zx_str* loc;
  struct zx_str* ss;
  struct zx_str* ss2;

  meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(req->Issuer));
  loc = zxid_idp_loc_raw(cf, cgi, meta, ZXID_SLO_SVC, SAML2_REDIR, 0);
  if (!loc)
    loc = zxid_sp_loc_raw(cf, cgi, meta, ZXID_SLO_SVC, SAML2_REDIR, 0);
  if (!loc)
    return zx_dup_str(cf->ctx, "* ERR");  /* *** consider sending error page */

  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "SLORESREDIR", 0, "");

  res = zxid_mk_logout_resp(cf, zxid_OK(cf, 0), &req->ID->g);
  res->Destination = zx_ref_len_attr(cf->ctx, &res->gg, zx_Destination_ATTR, loc->len, loc->s);
  ss = zx_easy_enc_elem_opt(cf, &res->gg);
  ss2 = zxid_saml2_resp_redir(cf, loc, ss, cgi->rs);
  /*zx_str_free(cf->ctx, loc); Do NOT free loc as it is still referenced by the metadata. */
  zx_str_free(cf->ctx, ss);
  return ss2;
}

/*() Process SP SLO request. */

/* Called by:  zxid_idp_dispatch, zxid_sp_dispatch, zxid_sp_soap_dispatch */
int zxid_sp_slo_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_LogoutRequest_s* req)
{
  struct zx_str* sesix = ZX_GET_CONTENT(req->SessionIndex);

  if (!zxid_chk_sig(cf, cgi, ses, &req->gg, req->Signature, req->Issuer, 0, "LogoutRequest"))
    return 0;

  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), cgi->sigval, "K", "SLO", ses->sid, "sesix(%.*s)", sesix?sesix->len:1, sesix?sesix->s:"?");
  
  req->NameID = zxid_decrypt_nameid(cf, req->NameID, req->EncryptedID);
  if (!ZX_GET_CONTENT(req->NameID)) {
    ERR("SLO failed: request does not have NameID. %p", req->NameID);
    return 0;
  }
  zxid_find_ses(cf, ses, sesix, ZX_GET_CONTENT(req->NameID));
  zxid_del_ses(cf, ses);
  return 1;
}

/*() Process IdP SLO request. The IdP SLO Requests are complicated by the need
 * to log the user out of other SPs as well, if they belong to same session.
 * Part of the complication is figuring out what constitutes "same session".
 * Finally, the redirect profiles may be "hairy" to handle if some SP does
 * not collaborate in the SLO. For SOAP similar problem exists, but it should be
 * manageable. */

/* Called by:  zxid_idp_dispatch, zxid_idp_soap_dispatch, zxid_sp_dispatch */
int zxid_idp_slo_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_LogoutRequest_s* req)
{
  struct zx_str* sesix = ZX_GET_CONTENT(req->SessionIndex);
  if (sesix)
    sesix = zxid_psobj_dec(cf, ZX_GET_CONTENT(req->Issuer), "ZS", sesix);
  
  if (!zxid_chk_sig(cf, cgi, ses, &req->gg, req->Signature, req->Issuer, 0, "LogoutRequest"))
    return 0;
  
  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), cgi->sigval, "K", "ISLO", ses->sid, "sesix(%.*s)", sesix?sesix->len:1, sesix?sesix->s:"?");
  if (cf->loguser)
    zxlogusr(cf, ses->uid, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), cgi->sigval, "K", "ISLO", ses->sid, "sesix(%.*s)", sesix?sesix->len:1, sesix?sesix->s:"?");

  req->NameID = zxid_decrypt_nameid(cf, req->NameID, req->EncryptedID);
  if (!ZX_GET_CONTENT(req->NameID)) {
    INFO("SLO: request does not have NameID. %p sesix(%.*s)", req->NameID, sesix?sesix->len:0, sesix?sesix->s:"");
  }
  if (zxid_find_ses(cf, ses, sesix, 0 /*ZX_GET_CONTENT(req->NameID)*/))
    zxid_del_ses(cf, ses);
  return 1;
}

/* EOF  --  zxidslo.c */
