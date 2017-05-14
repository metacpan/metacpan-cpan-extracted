/* zxididpx.c  -  Handwritten functions for IdP dispatch
 * Copyright (c) 2008-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxididpx.c,v 1.10 2010-01-08 02:10:09 sampo Exp $
 *
 * 14.11.2008,  created --Sampo
 * 12.2.2010,   added locking to lazy loading --Sampo
 * 11.12.2011,  added OAUTH2 and OpenID-Connect support --Sampo
 *
 * TODO: *** Review of all of IdP SLO and MNI code
 */

#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* ============== Dispatch incoming requests and responses ============== */

/*() Dispatch redirect and post binding requests.
 *
 * return:: a string (such as Location: header) and let the caller output it. */

/* Called by:  zxid_simple_ses_active_cf x2 */
struct zx_str* zxid_idp_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int chk_dup)
{
  struct zx_sp_LogoutRequest_s* req;
  zxid_entity* sp_meta;
  struct zx_str* loc;
  struct zx_str* ss;
  struct zx_str* ss2;
  struct zx_root_s* r;
  ses->sigres = ZXSIG_NO_SIG;

  if (cgi->response_type)  /* OAUTH2 / OpenID-Connect */
    return zxid_oauth2_az_server_sso(cf, cgi, ses);

  r = zxid_decode_redir_or_post(cf, cgi, ses, chk_dup);
  if (!r)
    return zx_dup_str(cf->ctx, "* ERR");

  if (r->AuthnRequest)
    return zxid_idp_sso(cf, cgi, ses, r->AuthnRequest);
  
  if (req = r->LogoutRequest) {
    D("IdP SLO %d", 0);
    if (cf->idp_ena) {  /* *** Kludgy check */
      if (!zxid_idp_slo_do(cf, cgi, ses, req))
	return zx_dup_str(cf->ctx, "* ERR");
    } else {
      if (!zxid_sp_slo_do(cf, cgi, ses, req))
	return zx_dup_str(cf->ctx, "* ERR");
    }
    /* *** Need to do much more to log out all other SPs of the session. */
    return zxid_slo_resp_redir(cf, cgi, req);
  }
  
  if (r->LogoutResponse) {
    if (!zxid_saml_ok(cf, cgi, r->LogoutResponse->Status, "SLO resp"))
      return zx_dup_str(cf->ctx, "* ERR");
    cgi->msg = "Logout Response OK. Logged out.";
    zxid_del_ses(cf, ses);
    return zx_dup_str(cf->ctx, "K"); /* Prevent mgmt screen from displaying, show login screen. */
  }

  if (r->ManageNameIDRequest) {
    sp_meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(r->ManageNameIDRequest->Issuer));
    loc = zxid_sp_loc_raw(cf, cgi, sp_meta, ZXID_MNI_SVC, SAML2_REDIR, 0);
    if (!loc)
      return 0;  /* *** consider sending error page */
    ss = zxid_mni_do_ss(cf, cgi, ses, r->ManageNameIDRequest, loc);
    ss2 = zxid_saml2_resp_redir(cf, loc, ss, cgi->rs);
    zx_str_free(cf->ctx, loc);
    zx_str_free(cf->ctx, ss);
    return ss2;
  }
  
  if (r->ManageNameIDResponse) {
    if (!zxid_saml_ok(cf, cgi, r->ManageNameIDResponse->Status, "MNI resp")) {
      ERR("MNI Response indicates failure. %d", 0);
      return zx_dup_str(cf->ctx, "* ERR");
    }
    cgi->msg = "Manage NameID Response OK.";
    return zx_dup_str(cf->ctx, "M"); /* Defederation doesn't have to mean SLO, show mgmt screen. */
  }

  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "IDPDISP", 0, "sid(%s) unknown req or resp (loc)", ses->sid);
  ERR("Unknown request or response %p", r);
  return zx_dup_str(cf->ctx, "* ERR");
}

#if 0
/*(-) SOAP dispatch can also handle requests and responses received via artifact
 * resolution. However only some combinations make sense.
 * Return 0 for failure, otherwise some success code such as ZXID_SSO_OK
 * *** NOT CALLED FROM ANYWHERE. See zxid_sp_soap_dispatch() for real action */

/* Called by: */
int zxid_idp_soap_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_root_s* r)
{
  X509* sign_cert;
  RSA*  sign_pkey;
  struct zxsig_ref refs;
  struct zx_e_Body_s* body;
  struct zx_sp_LogoutRequest_s* req;
  ses->sigres = ZXSIG_NO_SIG;
  
  if (!r) goto bad;
  if (!r->Envelope) goto bad;
  
  if (cf->log_level > 1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "W", "IDPDISP", 0, "sid(%s) soap", ses->sid);

  if (r->Envelope->Body->ArtifactResolve) {
    D("ArtifactResolve not implemented yet %d",0);
    //if (!zxid_saml_ok(cf, cgi, r->Envelope->Body->ArtifactResponse->Status, "ArtResp"))
    //  return 0;
    //return zxid_sp_dig_sso_a7n(cf, cgi, ses, r->Envelope->Body->ArtifactResponse->Response);
  }
  
  if (req = r->Envelope->Body->LogoutRequest) {
    if (!zxid_idp_slo_do(cf, cgi, ses, req))
      return 0;

    body = zx_NEW_e_Body(cf->ctx,0);
    body->LogoutResponse = zxid_mk_logout_resp(cf, zxid_OK(cf), req->ID);
    if (cf->sso_soap_resp_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = body->LogoutResponse->ID;
      refs.canon = zx_EASY_ENC_SO_sp_LogoutResponse(cf->ctx, body->LogoutResponse);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert idp slo")) {
	body->LogoutResponse->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&body->LogoutResponse->gg, &body->LogoutResponse->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
    return zxid_soap_cgi_resp_body(cf, ses, body);
  }

  if (r->Envelope->Body->ManageNameIDRequest) {
    struct zx_sp_ManageNameIDResponse_s* res = zxid_mni_do(cf, cgi, ses, r->Envelope->Body->ManageNameIDRequest);
    body = zx_NEW_e_Body(cf->ctx,0);
    body->ManageNameIDResponse = res;
    if (cf->sso_soap_resp_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = res->ID;
      refs.canon = zx_EASY_ENC_SO_sp_ManageNameIDResponse(cf->ctx, res);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert idp mni")) {
	res->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&res->gg, &res->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
    return zxid_soap_cgi_resp_body(cf, body, ZX_GET_CONTENT(r->Envelope->Body->ManageNameIDRequest->Issuer));
  }
  
 bad:
  ERR("Unknown soap request %p", r);
  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "IDPDISP", 0, "sid(%s) unknown soap req", ses->sid);
  return 0;
}

/*() Return 0 for failure, otherwise some success code such as ZXID_SSO_OK */

/* Called by: */
int zxid_idp_soap_parse(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int len, char* buf)
{
  struct zx_root_s* r;
  r = zx_dec_zx_root(cf->ctx, len, buf, "idp soap parse");
  if (!r || !r->Envelope || !r->Envelope->Body) {
    ERR("Failed to parse SOAP request buf(%.*s)", len, buf);
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "BADXML", 0, "sid(%s) bad soap req", ses->sid);
    return 0;
  }
  return zxid_sp_soap_dispatch(cf, cgi, ses, r);
}
#endif

/* EOF  --  zxididpx.c */
