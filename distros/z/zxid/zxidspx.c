/* zxidspx.c  -  Handwritten functions for SP dispatch
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidspx.c,v 1.14 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 12.10.2007, tweaked for signing SLO and MNI --Sampo
 * 14.4.2008,  added SimpleSign --Sampo
 * 7.10.2008,  added documentation --Sampo
 * 22.8.2009,  added XACML dummy PDP support --Sampo
 * 15.11.2009, added discovery service Query --Sampo
 * 12.2.2010,  added locking to lazy loading --Sampo
 *
 * See also zxid/sg/wsf-soap11.sg and zxid/c/zx-e-data.h, which is generated.
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include "errmac.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidpriv.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*() Extract an assertion, decrypting EncryptedAssertion if needed. */

/* Called by:  sig_validate x2, zxid_imreq, zxid_sp_dig_oauth_sso_a7n, zxid_sp_dig_sso_a7n, zxid_wsp_validate_env x2 */
zxid_a7n* zxid_dec_a7n(zxid_conf* cf, zxid_a7n* a7n, struct zx_sa_EncryptedAssertion_s* enca7n)
{
  struct zx_str* ss;
  struct zx_root_s* r;
  
  if (!a7n && enca7n) {
    ss = zxenc_privkey_dec(cf, enca7n->EncryptedData, enca7n->EncryptedKey);
    if (!ss || !ss->s || !ss->len) {
      return 0;
    }
    r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "dec a7n");
    if (!r) {
      ERR("Failed to parse EncryptedAssertion buf(%.*s)", ss->len, ss->s);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "BADXML", 0, "bad EncryptedAssertion");
      return 0;
    }
    a7n = r->Assertion;
  }
  return a7n;
}

/*() Extract an assertion from Request, decrypting EncryptedAssertion if needed, and perform SSO */

/* Called by:  zxid_idp_soap_dispatch, zxid_sp_dispatch, zxid_sp_soap_dispatch x3 */
static int zxid_sp_dig_sso_a7n(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_Response_s* resp)
{
  zxid_a7n* a7n;
  struct zx_ns_s* pop_seen = 0;

  if (!zxid_chk_sig(cf, cgi, ses, &resp->gg, resp->Signature, resp->Issuer, 0, "Response"))
    return 0;
  
  a7n = zxid_dec_a7n(cf, resp->Assertion, resp->EncryptedAssertion);
  if (a7n) {
    zx_see_elem_ns(cf->ctx, &pop_seen, &resp->gg);
    return zxid_sp_sso_finalize(cf, cgi, ses, a7n, pop_seen);
  }
  if (cf->anon_ok && cgi->rs && zx_match(cf->anon_ok, cgi->rs))
    return zxid_sp_anon_finalize(cf, cgi, ses);
  ERR("No Assertion found in SAML Response and anon_ok does not match %p", cf->anon_ok);
  zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "ERR", 0, "sid(%s) No assertion", ses->sid?ses->sid:"");
  return 0;
}

/*() Dispatch redirct or post binding requests (and sometimes responses).
 *
 * return:: a string (such as Location: header) and let the caller output it.
 *     Sometimes a dummy string is just output to indicate status, e.g.
 *     "O" for SSO OK, "K" for normal OK no further action needed,
 *     "M" show management screen, "I" forward to IdP dispatch, or
 *     "* ERR" for error situations. These special strings
 *     are allocated from static storage and MUST NOT be freed. Other
 *     strings such as "Location: ..." should be freed by caller. */

/* Called by:  main x3, zxid_mgmt, zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
struct zx_str* zxid_sp_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses)
{
  struct zx_sp_LogoutRequest_s* req;
  zxid_entity* idp_meta;
  struct zx_str* loc;
  struct zx_str* ss;
  struct zx_str* ss2;
  struct zx_root_s* r;
  int ret;

  ses->sigres = ZXSIG_NO_SIG;
  r = zxid_decode_redir_or_post(cf, cgi, ses, 1);
  if (!r)
    return zx_dup_str(cf->ctx, "* ERR");

  if (r->Response) {
    if (!zxid_saml_ok(cf, cgi, r->Response->Status, "SAMLresp"))
      return zx_dup_str(cf->ctx, "* ERR");
    ret = zxid_sp_dig_sso_a7n(cf, cgi, ses, r->Response);
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
  
  if (req = r->LogoutRequest) {
    if (cf->idp_ena) {  /* *** Kludgy check */
      D("IdP SLO %d", 0);
      if (!zxid_idp_slo_do(cf, cgi, ses, req))
	return zx_dup_str(cf->ctx, "* ERR");
    } else {
      if (!zxid_sp_slo_do(cf, cgi, ses, req))
	return zx_dup_str(cf->ctx, "* ERR");
    }
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
    idp_meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(r->ManageNameIDRequest->Issuer));
    loc = zxid_idp_loc_raw(cf, cgi, idp_meta, ZXID_MNI_SVC, SAML2_REDIR, 0);
    if (!loc)
      return zx_dup_str(cf->ctx, "* ERR");  /* *** consider sending error page */
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
  
  if (r->AuthnRequest) {
    D("AuthnRequest %d", 0);
    return zx_dup_str(cf->ctx, "I");
  }
  
  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "SPDISP", 0, "sid(%s) unknown req or resp", STRNULLCHK(ses->sid));
  ERR("Unknown request or response %p", r);
  return zx_dup_str(cf->ctx, "* ERR");
}

/*() Create Authorization Decision */

/* Called by:  zxid_xacml_az_do x2 */
static void zxid_ins_xacml_az_stmt(zxid_conf* cf, zxid_a7n* a7n, char* deci)
{
  /* Two ways of doing assertion with XACMLAuthzDecisionStatement:
   * 1. Explicitly include such statement in assertion
   * 2. Use sa:Statement, but brandit with xsi:type
   * The former is more logical, but the latter is what Jericho does
   * and in effect the XACML interop events have done (de-facto standard?). */

#if 1
  a7n->XACMLAuthzDecisionStatement = zx_NEW_xasa_XACMLAuthzDecisionStatement(cf->ctx,0);
  ZX_ADD_KID(a7n->XACMLAuthzDecisionStatement, Response, zxid_mk_xacml_resp(cf, deci));
  /* *** Add xaspcd1 and xasacd1 variants */
  zx_add_kid_before(&a7n->gg, zx_xasa_XACMLPolicyStatement_ELEM, &a7n->XACMLAuthzDecisionStatement->gg);
#else
  a7n->Statement = zx_NEW_sa_Statement(cf->ctx,0);
  a7n->Statement->type = zx_ref_str(cf->ctx, "xasa:XACMLAuthzDecisionStatementType");
  a7n->Statement->Response = zxid_mk_xacml_resp(cf, deci);
  zx_add_kid_before(&a7n->gg, zx_sa_AuthnStatement_ELEM, a7n->Statement);
#endif
}

/* Called by:  zxid_xacml_az_cd1_do x2 */
static void zxid_ins_xacml_az_cd1_stmt(zxid_conf* cf, zxid_a7n* a7n, char* deci)
{
  /* Two ways of doing assertion with XACMLAuthzDecisionStatement:
   * 1. Explicitly include such statement in assertion
   * 2. Use sa:Statement, but brandit with xsi:type
   * The former is more logical, but the latter is what Jericho does
   * and in effect the XACML interop events have done (de-facto standard?). */

#if 1
  a7n->xasacd1_XACMLAuthzDecisionStatement = zx_NEW_xasacd1_XACMLAuthzDecisionStatement(cf->ctx,0);
  ZX_ADD_KID(a7n->xasacd1_XACMLAuthzDecisionStatement, Response, zxid_mk_xacml_resp(cf, deci));
  /* *** Add xaspcd1 and xasacd1 variants */
  zx_add_kid_before(&a7n->gg, zx_xasacd1_XACMLPolicyStatement_ELEM, &a7n->xasacd1_XACMLAuthzDecisionStatement->gg);
#else
  a7n->Statement = zx_NEW_sa_Statement(cf->ctx,0);
  a7n->Statement->type = zx_ref_str(cf->ctx, "xasacd1:XACMLAuthzDecisionStatementType");
  a7n->Statement->Response = zxid_mk_xacml_resp(cf, deci);
  zx_add_kid_before(&a7n->gg, zx_sa_AuthnStatement_ELEM, a7n->Statement);
#endif
}

/*() Process <XACMLAuthzDecisionQuery>. The response will have
 * SAML assertion containing Authorization Decision Statement. */

/* Called by:  zxid_sp_soap_dispatch */
static struct zx_sp_Response_s* zxid_xacml_az_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_xasp_XACMLAuthzDecisionQuery_s* azq)
{
  zxid_a7n* a7n;
  struct zx_str* affil;
  struct zx_str* subj;
  struct zx_str* ss;
  struct zx_xac_Attribute_s* xac_at;
  
  if (!zxid_chk_sig(cf, cgi, ses, &azq->gg, azq->Signature, azq->Issuer, 0, "XACMLAuthzDecisionQuery"))
    return 0;

  affil = subj = 0;
#if 0
  affil = ar->NameIDPolicy && ar->NameIDPolicy->SPNameQualifier
    ? ar->NameIDPolicy->SPNameQualifier
    : ZX_GET_CONTENT(ar->Issuer);
  subj = zxid_mk_subj(cf, ses, affil, sp_meta);
#endif
  //a7n = zxid_mk_a7n(cf, affil, subj, 0, 0);
  a7n = zxid_mk_a7n(cf, affil, 0, 0, 0);

  if (azq->Request && azq->Request->Subject) {
    for (xac_at = azq->Request->Subject->Attribute;
	 xac_at;
	 xac_at = (struct zx_xac_Attribute_s*)ZX_NEXT(xac_at)) {
      if (xac_at->gg.g.tok != zx_xac_Attribute_ELEM)
	continue;
      if (xac_at->AttributeId->g.len == sizeof("role")-1
	  && !memcmp(xac_at->AttributeId->g.s, "role", sizeof("role")-1)) {
	ss = ZX_GET_CONTENT(xac_at->AttributeValue);
	if (ss?ss->len:0 == sizeof("deny")-1 && !memcmp(ss->s, "deny", sizeof("deny")-1)) {
	  D("PDP: DENY due to role=deny %d",0);
	  zxid_ins_xacml_az_stmt(cf, a7n, "Deny");
	  return zxid_mk_saml_resp(cf, a7n, 0);
	}
      }
    }
  }
  D("PDP: PERMIT by default %d",0);
  zxid_ins_xacml_az_stmt(cf, a7n, "Permit");
  return zxid_mk_saml_resp(cf, a7n, 0);
}

/* Called by:  zxid_sp_soap_dispatch */
static struct zx_sp_Response_s* zxid_xacml_az_cd1_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_xaspcd1_XACMLAuthzDecisionQuery_s* azq)
{
  zxid_a7n* a7n;
  struct zx_str* affil;
  struct zx_str* subj;
  struct zx_str* ss;
  struct zx_xac_Attribute_s* xac_at;
  
  if (!zxid_chk_sig(cf, cgi, ses, &azq->gg, azq->Signature, azq->Issuer, 0, "XACMLAuthzDecisionQuery"))
    return 0;

  affil = subj = 0;
#if 0
  affil = ar->NameIDPolicy && ar->NameIDPolicy->SPNameQualifier
    ? ar->NameIDPolicy->SPNameQualifier
    : ZX_GET_CONTENT(ar->Issuer);
  subj = zxid_mk_subj(cf, ses, affil, sp_meta);
#endif
  //a7n = zxid_mk_a7n(cf, affil, subj, 0, 0);
  a7n = zxid_mk_a7n(cf, affil, 0, 0, 0);

  if (azq->Request && azq->Request->Subject) {
    for (xac_at = azq->Request->Subject->Attribute;
	 xac_at;
	 xac_at = (struct zx_xac_Attribute_s*)ZX_NEXT(xac_at)) {
      if (xac_at->gg.g.tok == zx_xac_Attribute_ELEM)
	continue;
      if (xac_at->AttributeId->g.len == sizeof("role")-1
	  && !memcmp(xac_at->AttributeId->g.s, "role", sizeof("role")-1)) {
	ss = ZX_GET_CONTENT(xac_at->AttributeValue);
	if (ss?ss->len:0 == sizeof("deny")-1 && !memcmp(ss->s, "deny", sizeof("deny")-1)) {
	  D("PDP: Deny due to role=deny %d",0);
	  zxid_ins_xacml_az_cd1_stmt(cf, a7n, "Deny");
	  return zxid_mk_saml_resp(cf, a7n, 0);
	}
      }
    }
  }
  D("PDP: Permit by default %d",0);
  zxid_ins_xacml_az_cd1_stmt(cf, a7n, "Permit");
  return zxid_mk_saml_resp(cf, a7n, 0);
}

/*() SOAP dispatch can also handle requests and responses received via artifact
 * resolution. However only some combinations make sense.
 * See zxid/sg/wsf-soap11.sg for the master SOAP dispatch from parsing perspective.
 * Despite being called zxid_sp_soap_dispatch(), this actually dispatches
 * the IdP functions, such as ManageNameIDRequest, XACMLAuthzDecisionQuery,
 * SASLRequest (AnSvc), Query (Discovery), and People Service requests.
 *
 * Return 0 for failure, otherwise some success code such as ZXID_SSO_OK */

/* Called by:  zxid_idp_soap_parse, zxid_sp_deref_art, zxid_sp_soap_parse */
int zxid_sp_soap_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_root_s* r)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  struct zxsig_ref refs;
  struct zx_e_Header_s* hdr;  /* Request headers */
  struct zx_e_Body_s* bdy;    /* Request Body */
  struct zx_e_Body_s* body;   /* Response Body */
  ses->sigres = ZXSIG_NO_SIG;

  if (!r) goto bad;
  if (!r->Envelope) goto bad;
  hdr = r->Envelope->Header;
  bdy = r->Envelope->Body;

  if (cf->log_level > 1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "W", "SPDISP", 0, "sid(%s) soap", STRNULLCHK(ses->sid));

  if (bdy->ArtifactResponse) {
    if (!zxid_saml_ok(cf, cgi, bdy->ArtifactResponse->Status, "ArtResp"))
      return 0;
    return zxid_sp_dig_sso_a7n(cf, cgi, ses, bdy->ArtifactResponse->Response);
  }

  if (bdy->Response) {    /* PAOS/ECP response */
    if (!zxid_saml_ok(cf, cgi, bdy->Response->Status, "PAOS Resp"))
      return 0;
    return zxid_sp_dig_sso_a7n(cf, cgi, ses, bdy->Response);
  }

  body = zx_NEW_e_Body(cf->ctx,0);
  
  if (bdy->LogoutRequest) {
    ses->issuer = ZX_GET_CONTENT(bdy->LogoutRequest->Issuer);
    if (!zxid_sp_slo_do(cf, cgi, ses, bdy->LogoutRequest))
      return 0;
    ZX_ADD_KID(body, LogoutResponse, zxid_mk_logout_resp(cf, zxid_OK(cf, 0), &bdy->LogoutRequest->ID->g));
    if (cf->sso_soap_resp_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = &body->LogoutResponse->ID->g;
      refs.canon = zx_easy_enc_elem_sig(cf, &body->LogoutResponse->gg);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert slor")) {
	body->LogoutResponse->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&body->LogoutResponse->gg,&body->LogoutResponse->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
    return zxid_soap_cgi_resp_body(cf, ses, body);
  }

  if (bdy->ManageNameIDRequest) {
    ses->issuer = ZX_GET_CONTENT(bdy->ManageNameIDRequest->Issuer);
    ZX_ADD_KID(body, ManageNameIDResponse, zxid_mni_do(cf, cgi, ses, bdy->ManageNameIDRequest));
    if (cf->sso_soap_resp_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = &body->ManageNameIDResponse->ID->g;
      refs.canon = zx_easy_enc_elem_sig(cf, &body->ManageNameIDResponse->gg);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert mnir")) {
	body->ManageNameIDResponse->Signature = zxsig_sign(cf->ctx, 1, &refs,sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&body->ManageNameIDResponse->gg, &body->ManageNameIDResponse->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
    return zxid_soap_cgi_resp_body(cf, ses, body);
  }
  
  DD("as_ena=%d %p", cf->as_ena, bdy->SASLRequest);
  if (cf->as_ena) {
    if (bdy->SASLRequest) {
      if (hdr && hdr->Sender && hdr->Sender->providerID)
	ses->issuer = &hdr->Sender->providerID->g;
      else
	ses->issuer = 0;
      //ses->issuer = ZX_GET_CONTENT(bdy->SASLRequest->Issuer);
      ZX_ADD_KID(body, SASLResponse, zxid_idp_as_do(cf, bdy->SASLRequest));
#if 0
      if (cf->sso_soap_resp_sign) {
	ZERO(&refs, sizeof(refs));
	refs.id = res->ID;
	refs.canon = zx_EASY_ENC_SO_as_SASLResponse(cf->ctx, res);
	if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert asr")) {
	  res->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	  zx_add_kid(&res->gg, &res->gg);
	}
	zx_str_free(cf->ctx, refs.canon);
      }
#endif
      return zxid_soap_cgi_resp_body(cf, ses, body);
    }
  }
    
  if (cf->pdp_ena) {
    if (bdy->XACMLAuthzDecisionQuery) {
      ses->issuer = ZX_GET_CONTENT(bdy->XACMLAuthzDecisionQuery->Issuer);
      D("XACMLAuthzDecisionQuery %d",0);
      ZX_ADD_KID(body, Response, zxid_xacml_az_do(cf, cgi, ses, bdy->XACMLAuthzDecisionQuery));
      if (cf->sso_soap_resp_sign) {
	ZERO(&refs, sizeof(refs));
	refs.id = &body->Response->ID->g;
	refs.canon = zx_easy_enc_elem_sig(cf, &body->Response->gg);
	if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert azr")) {
	  body->Response->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	  zx_add_kid_after_sa_Issuer(&body->Response->gg, &body->Response->Signature->gg);
	}
	zx_str_free(cf->ctx, refs.canon);
      }
      return zxid_soap_cgi_resp_body(cf, ses, body);
    }
    if (bdy->xaspcd1_XACMLAuthzDecisionQuery) {
      ses->issuer = ZX_GET_CONTENT(bdy->XACMLAuthzDecisionQuery->Issuer);
      D("xaspcd1:XACMLAuthzDecisionQuery %d",0);
      ZX_ADD_KID(body, Response, zxid_xacml_az_cd1_do(cf, cgi, ses, bdy->xaspcd1_XACMLAuthzDecisionQuery));
      if (cf->sso_soap_resp_sign) {
	ZERO(&refs, sizeof(refs));
	refs.id = &body->Response->ID->g;
	refs.canon = zx_easy_enc_elem_sig(cf, &body->Response->gg);
	if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert azr")) {
	  body->Response->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	  zx_add_kid_after_sa_Issuer(&body->Response->gg, &body->Response->Signature->gg);
	}
	zx_str_free(cf->ctx, refs.canon);
      }
      return zxid_soap_cgi_resp_body(cf, ses, body);
    }
  }

  if (cf->idp_ena) {
    if (bdy->ArtifactResolve) {
      D("*** ArtifactResolve not implemented yet %d",0);
      //if (!zxid_saml_ok(cf, cgi, bdy->ArtifactResponse->Status, "ArtResp"))
      //  return 0;
      //return zxid_sp_dig_sso_a7n(cf, cgi, ses, bdy->ArtifactResponse->Response);
    }

    if (bdy->NameIDMappingRequest && cf->imps_ena) {
      ses->issuer = ZX_GET_CONTENT(bdy->NameIDMappingRequest->Issuer);
      ZX_ADD_KID(body, NameIDMappingResponse, zxid_nidmap_do(cf, bdy->NameIDMappingRequest));
      if (cf->sso_soap_resp_sign) {
	ZERO(&refs, sizeof(refs));
	refs.id = &body->NameIDMappingResponse->ID->g;
	refs.canon = zx_easy_enc_elem_sig(cf, &body->NameIDMappingResponse->gg);
	if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert mnir")) {
	  body->NameIDMappingResponse->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	  zx_add_kid_after_sa_Issuer(&body->NameIDMappingResponse->gg, &body->NameIDMappingResponse->Signature->gg);
	}
	zx_str_free(cf->ctx, refs.canon);
      }
      return zxid_soap_cgi_resp_body(cf, ses, body);
    }

    if (!zxid_wsp_validate_env(cf, ses, "Resource=Discovery", r->Envelope)) {
      return zxid_soap_cgi_resp_body(cf, ses, body); /* will include the fault */
    }
    
    if (bdy->Query) { /* Discovery 2.0 Query */
      ZX_ADD_KID(body, QueryResponse, zxid_di_query(cf, ses, bdy->Query));
    idwsf_resp:
#if 0
      // *** should really sign the Body, putting sig in wsse:Security header
      if (cf->sso_soap_resp_sign) {
	ZERO(&refs, sizeof(refs));
	refs.id = di_resp->ID;
	refs.canon = zx_EASY_ENC_SO_e_Body(cf->ctx, body);
	if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert dir")) {
	  res->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	  zx_add_kid_after_sa_Issuer(&res->gg, &res->Signature->gg);
	}
	zx_str_free(cf->ctx, refs.canon);
      }
#endif
      
      return zxid_soap_cgi_resp_body(cf, ses, body);
    }

    if (cf->imps_ena) {
      if (bdy->AddEntityRequest) {
	ZX_ADD_KID(body, AddEntityResponse, zxid_ps_addent_invite(cf, ses, bdy->AddEntityRequest));
	goto idwsf_resp;
      }
      if (bdy->ResolveIdentifierRequest) {
	ZX_ADD_KID(body, ResolveIdentifierResponse, zxid_ps_resolv_id(cf, ses, bdy->ResolveIdentifierRequest));
	goto idwsf_resp;
      }
      if (bdy->IdentityMappingRequest) {
	ZX_ADD_KID(body, IdentityMappingResponse, zxid_imreq(cf,ses, bdy->IdentityMappingRequest));
	goto idwsf_resp;
      }
    }
    if (bdy->AuthnRequest && cf->as_ena) {
      ZX_ADD_KID(body, Response, zxid_ssos_anreq(cf, ses, bdy->AuthnRequest));
      goto idwsf_resp;
    }
  }
  
 bad:
  ERR("Unknown SOAP request %p", r);
  if (cf->log_level > 0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "SPDISP", 0, "sid(%s) unknown soap req", STRNULLCHK(ses->sid));
  return 0;
}

/*() Return 0 for failure, otherwise some success code such as ZXID_SSO_OK */

/* Called by:  chkuid, main x6, zxid_mini_httpd_sso, zxid_simple_cf_ses */
int zxid_sp_soap_parse(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int len, char* buf)
{
  struct zx_root_s* r;
  r = zx_dec_zx_root(cf->ctx, len, buf, "sp soap parse");
  if (!r || !r->Envelope || !r->Envelope->Body) {
    ERR("Failed to parse SOAP request buf(%.*s)", len, buf);
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "BADXML", 0, "sid(%s) bad soap req", STRNULLCHK(ses->sid));
    return 0;
  }
  return zxid_sp_soap_dispatch(cf, cgi, ses, r);
}

/* EOF  --  zxidspx.c */
