/* zxidmk.c  -  Handwritten nitty-gritty functions for constructing various elems
 * Copyright (c) 2006-2011 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidmk.c,v 1.27 2009-11-24 23:53:40 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 8.10.2007, added signing ArtifactResolve --Sampo
 * 7.10.2008, added documentation --Sampo
 * 24.8.2009, added XACML stuff --Sampo
 */

#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*() Interpret ZXID standard form fields to construct a XML structure for AuthnRequest */

/* Called by:  a7n_test, x509_test, zxid_lecp_check, zxid_start_sso_url */
struct zx_sp_AuthnRequest_s* zxid_mk_authn_req(zxid_conf* cf, zxid_cgi* cgi)
{
  char index[2] = "1";
  struct zx_sp_AuthnRequest_s* ar = zx_NEW_sp_AuthnRequest(cf->ctx,0);
  ar->ID = zxid_mk_id_attr(cf, &ar->gg, zx_ID_ATTR, "N", ZXID_ID_BITS);
  ar->Version = zx_ref_attr(cf->ctx, &ar->gg, zx_Version_ATTR, SAML2_VERSION);
  ar->IssueInstant = zxid_date_time_attr(cf, &ar->gg, zx_IssueInstant_ATTR, time(0));

  if (cf->nice_name && cf->nice_name[0])
    ar->ProviderName = zx_ref_attr(cf->ctx, &ar->gg, zx_ProviderName_ATTR, cf->nice_name);

  if (BOOL_STR_TEST(cgi->force_authn))
    ar->ForceAuthn = zx_ref_attr(cf->ctx, &ar->gg, zx_ForceAuthn_ATTR, XML_TRUE);

  if (BOOL_STR_TEST(cgi->ispassive))
    ar->IsPassive = zx_ref_attr(cf->ctx, &ar->gg, zx_IsPassive_ATTR, XML_TRUE);

  if (cgi->consent && cgi->consent[0])
    ar->Consent = zx_ref_attr(cf->ctx, &ar->gg, zx_Consent_ATTR, cgi->consent);

  ar->Issuer = zxid_my_issuer(cf, &ar->gg);
  
  D("nid_fmt(%s) allow_create=%c ispassive=%c", cgi->nid_fmt, cgi->allow_create, cgi->ispassive);
  if (cgi->nid_fmt && cgi->nid_fmt[0] || cgi->affil && cgi->affil[0]
      || BOOL_STR_TEST(cgi->allow_create)) {
    ar->NameIDPolicy = zx_NEW_sp_NameIDPolicy(cf->ctx, &ar->gg);

    if (cgi->nid_fmt && cgi->nid_fmt[0])
      ar->NameIDPolicy->Format = zx_ref_attr(cf->ctx, &ar->NameIDPolicy->gg, zx_Format_ATTR, zxid_saml2_map_nid_fmt(cgi->nid_fmt));

    if (cgi->affil && cgi->affil[0])
      ar->NameIDPolicy->SPNameQualifier = zx_ref_attr(cf->ctx, &ar->NameIDPolicy->gg, zx_SPNameQualifier_ATTR, cgi->affil);

    if (BOOL_STR_TEST(cgi->allow_create))
      ar->NameIDPolicy->AllowCreate = zx_ref_attr(cf->ctx, &ar->NameIDPolicy->gg, zx_AllowCreate_ATTR, XML_TRUE);  /* default false */
  }

  if (cgi->authn_ctx && cgi->authn_ctx[0]) {
    ar->RequestedAuthnContext = zx_NEW_sp_RequestedAuthnContext(cf->ctx, &ar->gg);
    ar->RequestedAuthnContext->AuthnContextClassRef
      = zx_ref_elem(cf->ctx, &ar->RequestedAuthnContext->gg, zx_sa_AuthnContextClassRef_ELEM, zxid_saml2_map_authn_ctx(cgi->authn_ctx));
    if (cgi->matching_rule && cgi->matching_rule[0])
      ar->RequestedAuthnContext->Comparison = zx_ref_attr(cf->ctx, &ar->RequestedAuthnContext->gg, zx_Comparison_ATTR, cgi->matching_rule);
  }
  if (cgi->pr_ix) {
    index[0] = cgi->pr_ix+'0';
    ar->AssertionConsumerServiceIndex = zx_dup_attr(cf->ctx, &ar->gg, zx_AssertionConsumerServiceIndex_ATTR, index);
  }
  if (cgi->get_complete && cgi->get_complete[0]
      || cgi->pxy_count && cgi->pxy_count[0]
      || cgi->idppxylist && cgi->idppxylist[0]) {
    ar->Scoping = zx_NEW_sp_Scoping(cf->ctx, &ar->gg);
    if (cgi->pxy_count && cgi->pxy_count[0])
      ar->Scoping->ProxyCount = zx_ref_attr(cf->ctx, &ar->gg, zx_ProxyCount_ATTR, cgi->pxy_count);
#if 0
    if (cgi->get_complete && cgi->get_complete[0] || cgi->idppxylist) {
      ar->Scoping->IDPList = zx_NEW_sp_IDPList(cf->ctx, &ar->Scoping->gg);
      /* *** Add IDPEntry and GetComplete */
    }
#endif
  }
  zx_reverse_elem_lists(&ar->gg);  /* Ensure Issuer comes first. */
  return ar;
}

/*() Make the body for the ArtifactResolve SOAP message, signing it if needed. */

/* Called by:  covimp_test, zxid_sp_deref_art */
struct zx_sp_ArtifactResolve_s* zxid_mk_art_deref(zxid_conf* cf, struct zx_elem_s* father, zxid_entity* idp_meta, const char* artifact)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  struct zxsig_ref refs;
  struct zx_sp_ArtifactResolve_s* ar = zx_NEW_sp_ArtifactResolve(cf->ctx, father);
  ar->Version = zx_ref_attr(cf->ctx, &ar->gg, zx_Version_ATTR, SAML2_VERSION);
  ar->IssueInstant = zxid_date_time_attr(cf, &ar->gg, zx_IssueInstant_ATTR, time(0));
  ar->ID = zxid_mk_id_attr(cf, &ar->gg, zx_ID_ATTR, "R", ZXID_ID_BITS);
  ar->Artifact = zx_ref_elem(cf->ctx, &ar->gg, zx_sp_Artifact_ELEM, artifact);
  ar->Issuer = zxid_my_issuer(cf, &ar->gg);
  if (cf->sso_soap_sign) {
    ZERO(&refs, sizeof(refs));
    refs.id = &ar->ID->g;
    refs.canon = zx_easy_enc_elem_sig(cf, &ar->gg);
    if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert art deref")) {
      ar->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
      zx_add_kid_after_sa_Issuer(&ar->gg, &ar->Signature->gg);
    }
    zx_str_free(cf->ctx, refs.canon);
  }
  return ar;
}

/*() Create SAML protocol <Status> element, given various levels of error input. */

/* Called by:  so_enc_dec, zxid_OK, zxid_nidmap_do x2, zxid_ssos_anreq x4 */
struct zx_sp_Status_s* zxid_mk_Status(zxid_conf* cf, struct zx_elem_s* father, const char* sc1, const char* sc2, const char* msg)
{
  struct zx_sp_Status_s* st = zx_NEW_sp_Status(cf->ctx, father);
  if (msg)
    st->StatusMessage = zx_ref_elem(cf->ctx, &st->gg, zx_sp_StatusMessage_ELEM, msg);
  st->StatusCode = zx_NEW_sp_StatusCode(cf->ctx, &st->gg);
  st->StatusCode->Value = zx_ref_attr(cf->ctx, &st->StatusCode->gg, zx_Value_ATTR, sc1);
  if (sc2) {
    st->StatusCode->StatusCode = zx_NEW_sp_StatusCode(cf->ctx, &st->StatusCode->gg);
    st->StatusCode->StatusCode->Value = zx_ref_attr(cf->ctx, &st->StatusCode->StatusCode->gg, zx_Value_ATTR, sc2);
  }
  return st;
}

/*() Create SAML <Status> element indicating success. */

/* Called by:  zxid_idp_soap_dispatch, zxid_mk_saml_resp, zxid_mni_do, zxid_mni_do_ss, zxid_nidmap_do, zxid_slo_resp_redir, zxid_sp_soap_dispatch */
struct zx_sp_Status_s* zxid_OK(zxid_conf* cf, struct zx_elem_s* father)
{
  return zxid_mk_Status(cf, father, SAML2_SC_SUCCESS, 0, 0);
}

/*() Create EncryptedID given normal NameID and metadata of destination. Encryption
 * will be done using encryption certificate of the receiver identified by the metadata. */

/* Called by:  zxid_mk_logout, zxid_mk_mni, zxid_mk_subj */
struct zx_sa_EncryptedID_s* zxid_mk_enc_id(zxid_conf* cf, struct zx_elem_s* father, zxid_nid* nid, zxid_entity* meta)
{
  struct zx_xenc_EncryptedData_s* ed;
  struct zx_sa_EncryptedID_s* encid;
  struct zx_str* ss;
  if (!cf || !nid) {
    ERR("NULL arguments (programmer error) %p", cf);
    return 0;
  }
  if (!meta || !meta->enc_cert) {
    ERR("Missing destination metadata or the metadata does not have encryption certificate. %p", meta);
    return 0;
  }
  ss = zx_easy_enc_elem_opt(cf, &nid->gg);
  if (!ss) {
    ERR("Failed to XML serialize nameid %p", nid);
    return 0;
  }
  encid = zx_NEW_sa_EncryptedID(cf->ctx, father);
  if (cf->enckey_opt & 0x20) {
    /* Nested EncryptedKey approach (Shibboleth early 2010) */
    ed = zxenc_pubkey_enc(cf, ss, 0, meta->enc_cert, "41", 0);
  } else {
    /* RetrievalMethod approach */
    ed = zxenc_pubkey_enc(cf, ss, &encid->EncryptedKey, meta->enc_cert, "38", meta);
  }
  if (!ed) {
    ERR("Failed to encrypt a nameid (this could be due to problems with encryption certificate of the destination or destination's metadata; you may be able to work around this problem by manipulating NAMEID_ENC config option, but consider the security implication) cert=%p", meta->enc_cert);
    return 0;
  }
  ZX_ADD_KID(encid, EncryptedData, ed);
  zx_str_free(cf->ctx, ss);
  return encid;
}

/*() Create EncryptedAssertion given normal A7N and metadata of destination. Encryption
 * will be done using encryption certificate of the receiver identified by the metadata. */

/* Called by:  zxid_add_fed_tok2epr, zxid_imreq, zxid_mk_saml_resp */
struct zx_sa_EncryptedAssertion_s* zxid_mk_enc_a7n(zxid_conf* cf, struct zx_elem_s* father, zxid_a7n* a7n, zxid_entity* meta)
{
  struct zx_xenc_EncryptedData_s* ed;
  struct zx_str* ss;
  struct zx_sa_EncryptedAssertion_s* enc_a7n;
  if (!cf || !a7n) {
    ERR("NULL arguments (programmer error) %p", cf);
    return 0;
  }
  if (!meta || !meta->enc_cert) {
    ERR("Missing destination metadata or the metadata does not have encryption certificate. %p", meta);
    return 0;
  }
  ss = zx_easy_enc_elem_opt(cf, &a7n->gg);
  if (!ss) {
    ERR("Failed to XML serialize assertion %p", a7n);
    return 0;
  }
  enc_a7n = zx_NEW_sa_EncryptedAssertion(cf->ctx, father);
  if (cf->enckey_opt & 0x20) {
    /* Nested EncryptedKey approach (Shibboleth early 2010) */
    ed = zxenc_pubkey_enc(cf, ss, 0, meta->enc_cert, "40", 0);
  } else {
    /* RetrievalMethod approach */
    ed = zxenc_pubkey_enc(cf, ss, &enc_a7n->EncryptedKey, meta->enc_cert, "39", meta);
  }
  if (!ed) {
    ERR("Failed to encrypt assertion %p (this could be due to problems with encryption certificate of the destination or destination's metadata; you may be able to work around this problem by manipulating POST_A7N_ENC or DI_A7N_ENC config option, but consider the security implication)", a7n);
    return 0;
  }
  ZX_ADD_KID(enc_a7n, EncryptedData, ed);
  zx_str_free(cf->ctx, ss);
  return enc_a7n;
}

/*() Create XML data structure for <LogoutRequest> element. Low level API. */

/* Called by:  test_ibm_cert_problem_enc_dec, zxid_sp_slo_redir, zxid_sp_slo_soap */
struct zx_sp_LogoutRequest_s* zxid_mk_logout(zxid_conf* cf, zxid_nid* nid, struct zx_str* ses_ix, zxid_entity* idp_meta)
{
  struct zx_sp_LogoutRequest_s* r = zx_NEW_sp_LogoutRequest(cf->ctx,0);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "L", ZXID_ID_BITS);
  r->Version = zx_ref_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));

  D("nameid_enc(%d) idp_meta(%p) enc_cert(%p)", cf->nameid_enc, idp_meta, idp_meta->enc_cert);
  if (cf->nameid_enc && idp_meta)
    r->EncryptedID = zxid_mk_enc_id(cf, &r->gg, nid, idp_meta);
  else
    r->NameID = nid;
  if (ses_ix)
    r->SessionIndex = zx_new_str_elem(cf->ctx, &r->gg, zx_sp_SessionIndex_ELEM, ses_ix);
  return r;
}

/*() Create XML data structure for <LogoutResponse> element. Low level API. */

/* Called by:  zxid_idp_soap_dispatch, zxid_slo_resp_redir, zxid_sp_soap_dispatch */
struct zx_sp_LogoutResponse_s* zxid_mk_logout_resp(zxid_conf* cf, struct zx_sp_Status_s* st, struct zx_str* req_id)
{
  struct zx_sp_LogoutResponse_s* r = zx_NEW_sp_LogoutResponse(cf->ctx,0);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "r", ZXID_ID_BITS);
  r->Version = zx_ref_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));
  if (req_id)
    r->InResponseTo = zx_ref_len_attr(cf->ctx, &r->gg, zx_InResponseTo_ATTR, req_id->len, req_id->s);
  zx_add_kid(&r->gg, &st->gg);
  r->Status = st;
  return r;
}

/*() Change SPNameID (newnym supplied), or Terminate federation (newnym not supplied).
 * Create XML data structure for <ManageNameIDRequest> element. Low level API. */

/* Called by:  a7n_test, zxid_sp_mni_redir, zxid_sp_mni_soap */
struct zx_sp_ManageNameIDRequest_s* zxid_mk_mni(zxid_conf* cf, zxid_nid* nid, struct zx_str* new_nym, zxid_entity* idp_meta)
{
  struct zx_str* ss;
  struct zx_xenc_EncryptedKey_s* ek;
  struct zx_elem_s* newid;
  struct zx_sp_ManageNameIDRequest_s* r = zx_NEW_sp_ManageNameIDRequest(cf->ctx,0);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "R", ZXID_ID_BITS);
  r->Version = zx_ref_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));
  if (cf->nameid_enc && idp_meta) {
    r->EncryptedID = zxid_mk_enc_id(cf, &r->gg, nid, idp_meta);
    if (new_nym && new_nym->len) {
      newid = zx_new_str_elem(cf->ctx, 0, zx_sp_NewID_ELEM, new_nym);
      ss = zx_easy_enc_elem_opt(cf, newid);
      r->NewEncryptedID = zx_NEW_sp_NewEncryptedID(cf->ctx, &r->gg);
      if (cf->enckey_opt & 0x20) {
	/* Nested EncryptedKey approach (Shibboleth early 2010) */
	ZX_ADD_KID(r->NewEncryptedID, EncryptedData, zxenc_pubkey_enc(cf, ss, 0, idp_meta->enc_cert, "43",0));
      } else {
	/* RetrievalMethod approach */
	ZX_ADD_KID(r->NewEncryptedID, EncryptedData, zxenc_pubkey_enc(cf, ss, &ek, idp_meta->enc_cert, "39", idp_meta));
	ZX_ADD_KID(r->NewEncryptedID, EncryptedKey, ek);
	zx_reverse_elem_lists(&r->NewEncryptedID->gg);
      }
      zx_str_free(cf->ctx, ss);
      zx_free_elem(cf->ctx, newid, 0);
    } else
      r->Terminate = zx_new_str_elem(cf->ctx, &r->gg, zx_sp_Terminate_ELEM, 0);
  } else {
    r->NameID = nid;
    if (new_nym && new_nym->len)
      r->NewID = zx_new_str_elem(cf->ctx, &r->gg, zx_sp_NewID_ELEM, new_nym);
    else
      r->Terminate = zx_new_str_elem(cf->ctx, &r->gg, zx_sp_Terminate_ELEM, 0);
  }
  return r;
}

/*() Create XML data structure for <ManageNameIDResponse> element. Low level API.*/

/* Called by:  zxid_mni_do, zxid_mni_do_ss */
struct zx_sp_ManageNameIDResponse_s* zxid_mk_mni_resp(zxid_conf* cf, struct zx_sp_Status_s* st, struct zx_str* req_id)
{
  struct zx_sp_ManageNameIDResponse_s* r = zx_NEW_sp_ManageNameIDResponse(cf->ctx,0);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "r", ZXID_ID_BITS);
  r->Version = zx_ref_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));
  if (req_id)
    r->InResponseTo = zx_ref_len_attr(cf->ctx, &r->gg,zx_InResponseTo_ATTR, req_id->len,req_id->s);
  zx_add_kid(&r->gg, &st->gg);
  r->Status = st;
  return r;
}

/* ======== IdP SSO Related ======== */

/*() Constructor for Assertion */

/* Called by:  zxid_map_val_ss, zxid_mk_usr_a7n_to_sp, zxid_xacml_az_cd1_do x2, zxid_xacml_az_do x2 */
zxid_a7n* zxid_mk_a7n(zxid_conf* cf, struct zx_str* audience, struct zx_sa_Subject_s* subj, struct zx_sa_AuthnStatement_s* an_stmt, struct zx_sa_AttributeStatement_s* at_stmt)
{
  zxid_a7n* a7n =  zx_NEW_sa_Assertion(cf->ctx,0);
  a7n->Version = zx_dup_attr(cf->ctx, &a7n->gg, zx_Version_ATTR, SAML2_VERSION);
  a7n->ID = zxid_mk_id_attr(cf, &a7n->gg, zx_ID_ATTR, "A", ZXID_ID_BITS);
  a7n->IssueInstant = zxid_date_time_attr(cf, &a7n->gg, zx_IssueInstant_ATTR, time(0));
  a7n->Issuer = zxid_my_issuer(cf, &a7n->gg);
  a7n->Subject = subj;
  if (subj)
    zx_add_kid(&a7n->gg, &subj->gg);
  a7n->Conditions = zx_NEW_sa_Conditions(cf->ctx, &a7n->gg);
  a7n->Conditions->NotOnOrAfter = zxid_date_time_attr(cf, &a7n->Conditions->gg, zx_NotOnOrAfter_ATTR, time(0) + cf->a7nttl);
  a7n->Conditions->NotBefore = zxid_date_time_attr(cf, &a7n->Conditions->gg, zx_NotBefore_ATTR, time(0));
  if (audience) {
    a7n->Conditions->AudienceRestriction = zx_NEW_sa_AudienceRestriction(cf->ctx, &a7n->Conditions->gg);
    a7n->Conditions->AudienceRestriction->Audience = zx_new_str_elem(cf->ctx, &a7n->Conditions->AudienceRestriction->gg, zx_sa_Audience_ELEM, audience);
  }
  a7n->AuthnStatement = an_stmt;
  if (an_stmt)
    zx_add_kid(&a7n->gg, &an_stmt->gg);
  a7n->AttributeStatement = at_stmt;
  if (at_stmt)
    zx_add_kid(&a7n->gg, &at_stmt->gg);
  zx_reverse_elem_lists(&a7n->gg);
  return a7n;
}

/*() Construct Subject, possibly with EncryptedID */

/* Called by:  zxid_map_val_ss, zxid_mk_usr_a7n_to_sp, zxid_xacml_az_cd1_do, zxid_xacml_az_do */
struct zx_sa_Subject_s* zxid_mk_subj(zxid_conf* cf, struct zx_elem_s* father, zxid_entity* sp_meta, zxid_nid* nid)
{
  struct zx_sa_Subject_s* subj = zx_NEW_sa_Subject(cf->ctx, father);

#if 0
  // , struct zx_str* affil, char* fmt
  nid = zx_NEW_sa_NameID(cf->ctx,0);
  nid->SPNameQualifier = affil;
  nid->NameQualifier = zxid_my_ent_id(cf);
  nid->Format = zx_dup_str(cf->ctx, fmt);  /* *** implement persistent */
  if (!strcmp(fmt, SAML2_TRANSIENT_NID_FMT)) {
    zx_add_content(cf->ctx, nid, zxid_mk_id(cf, "T", ZXID_ID_BITS));
  } else {
    /* *** see also zxid_get_user_nameid() */
  }
#endif

  if (cf->nameid_enc) {
    if (sp_meta)
      subj->EncryptedID = zxid_mk_enc_id(cf, &subj->gg, nid, sp_meta);
    else {
      ERR("NameID encryption configred, but no metadata supplied. Defaulting to unencrypted NameID %d", 0);
      ZX_ADD_KID(subj, NameID, nid);
    }
  } else {
    ZX_ADD_KID(subj, NameID, nid);
  }
  /* SAML spec is more lax than the schema: saml-core-2.0-os.pdf ll.653-657 says <SubjectConfirmation> [Zero or More] */
  return subj;
}

/*() Construct AuthnStatement */

/* Called by:  zxid_mk_usr_a7n_to_sp */
struct zx_sa_AuthnStatement_s* zxid_mk_an_stmt(zxid_conf* cf, zxid_ses* ses, struct zx_elem_s* father, const char* eid)
{
  struct zx_str sesix;
  struct zx_str eid_ss;
  struct zx_str* ss;
  struct zx_sa_AuthnStatement_s* an_stmt = zx_NEW_sa_AuthnStatement(cf->ctx, father);
  if (ses->sesix) {
#if 0
    an_stmt->SessionIndex = zx_dup_str(cf->ctx, ses->sesix);
#else
    /* Need noncorrelatable session index */
    eid_ss.len = strlen(eid);
    eid_ss.s = (char*)eid;
    sesix.len = strlen(ses->sesix);
    sesix.s = ses->sesix;
    ss = zxid_psobj_enc(cf, &eid_ss, "ZS", &sesix);
    an_stmt->SessionIndex = zx_ref_len_attr(cf->ctx, &an_stmt->gg, zx_SessionIndex_ATTR, ss->len, ss->s);
#endif
  }
  an_stmt->AuthnInstant = zxid_date_time_attr(cf, &an_stmt->gg, zx_AuthnInstant_ATTR, ses->an_instant);
  an_stmt->AuthnContext = zx_NEW_sa_AuthnContext(cf->ctx, &an_stmt->gg);
  if (ses->an_ctx)
    an_stmt->AuthnContext->AuthnContextClassRef
      = zx_dup_elem(cf->ctx, &an_stmt->AuthnContext->gg, zx_sa_AuthnContextClassRef_ELEM, ses->an_ctx);
  else {
    ERR("Session(%s) lacks AuthentContextClassRef. Output AuthnStatement will not satisfy all processing rules. See configuration option ISSUE_AUTHNCTX_PW.", ses->sesix);
  }
  return an_stmt;
}

/*() Construct SAML SAML Attribute from string */

/* Called by:  zxid_add_mapped_attr, zxid_map_val_ss, zxid_mk_sa_attribute */
struct zx_sa_Attribute_s* zxid_mk_sa_attribute_ss(zxid_conf* cf, struct zx_elem_s* father, const char* name, const char* namfmt, struct zx_str* val)
{
  struct zx_root_s* r;
  struct zx_sa_Attribute_s* at = zx_NEW_sa_Attribute(cf->ctx, father);
  if (namfmt)
    at->NameFormat = zx_ref_attr(cf->ctx, &at->gg, zx_NameFormat_ATTR, namfmt);
  at->Name = zx_dup_attr(cf->ctx, &at->gg, zx_Name_ATTR, name);
  at->AttributeValue = zx_NEW_sa_AttributeValue(cf->ctx, &at->gg);
  if (!val)
    return at;

  if (val->s[0] == '<') {
    /* Looks like the value may be XML data. We need to pass it as XML data structure for
     * canonicalization to work right (e.g. value is an A7N that is rendered one
     * way when canonicalized independently, but in different way when canonicalized
     * as part of a bigger structure - for example sa namespace may be omitted as it
     * is already supplied by the parent element). */
    r = zx_dec_zx_root(cf->ctx, val->len, val->s, "sa at parse");
    if (r && r->gg.kids) {
      at->AttributeValue->gg.kids = r->gg.kids;
      switch (r->gg.kids->g.tok) {
      case zx_sa_Assertion_ELEM:          at->AttributeValue->Assertion = (void*)r->gg.kids; break;
      case zx_sa_EncryptedAssertion_ELEM: at->AttributeValue->EncryptedAssertion = (void*)r->gg.kids; break;
      case zx_di12_ResourceOffering_ELEM: at->AttributeValue->ResourceOffering = (void*)r->gg.kids; break;
      case zx_a_EndpointReference_ELEM:   at->AttributeValue->EndpointReference = (void*)r->gg.kids; break;
      }
      ZX_FREE(cf->ctx, r);
    } else {
      /* XML did not parse, may be its just string data, after all. */
      zx_add_content(cf->ctx, &at->AttributeValue->gg, val);
    }
  } else {
    zx_add_content(cf->ctx, &at->AttributeValue->gg, val);
  }
  return at;
}

/*() Construct SAML SAML Attribute */

/* Called by:  zxid_gen_boots, zxid_mk_usr_a7n_to_sp x2 */
struct zx_sa_Attribute_s* zxid_mk_sa_attribute(zxid_conf* cf, struct zx_elem_s* father, const char* name, const char* namfmt, const char* val)
{
  return zxid_mk_sa_attribute_ss(cf, father, name, namfmt, val?zx_dup_str(cf->ctx, val):0);
}

/*() Construct SAML protocol Response (such as may be used to carry assertion in SSO) */

/* Called by:  zxid_idp_sso x4, zxid_ssos_anreq, zxid_xacml_az_cd1_do x2, zxid_xacml_az_do x2 */
struct zx_sp_Response_s* zxid_mk_saml_resp(zxid_conf* cf, zxid_a7n* a7n, zxid_entity* enc_meta)
{
  struct zx_sp_Response_s* r = zx_NEW_sp_Response(cf->ctx,0);
  r->Version = zx_dup_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "R", ZXID_ID_BITS);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));
  r->Status = zxid_OK(cf, &r->gg);
  if (a7n) {
    if (enc_meta) {
      /* See saml-bindings-2.0-os.pdf, sec 3.5.5.2 Security Considerations, p.24, ll.847-851
       * After publication it was understood that the SHOULD NOT could be eliminated
       * if EncryptedAssertion is used. */

      r->EncryptedAssertion = zxid_mk_enc_a7n(cf, &r->gg, a7n, enc_meta);
    } else {
      r->Assertion = a7n;
      zx_add_kid(&r->gg, &a7n->gg);
    }
  }
  zx_reverse_elem_lists(&r->gg);
  return r;
}

/*() Construct XACML Response */

/* Called by:  zxid_ins_xacml_az_cd1_stmt x2, zxid_ins_xacml_az_stmt x2 */
struct zx_xac_Response_s* zxid_mk_xacml_resp(zxid_conf* cf, char* decision)
{
  struct zx_xac_Response_s* resp = zx_NEW_xac_Response(cf->ctx,0);
  resp->Result = zx_NEW_xac_Result(cf->ctx, &resp->gg);
  resp->Result->Decision = zx_ref_elem(cf->ctx, &resp->Result->gg, zx_xac_Decision_ELEM, decision);
  resp->Result->Status = zx_NEW_xac_Status(cf->ctx, &resp->Result->gg);
  resp->Result->Status->StatusCode = zx_NEW_xac_StatusCode(cf->ctx, &resp->Result->Status->gg);
  resp->Result->Status->StatusCode->Value
    = zx_ref_attr(cf->ctx, &resp->Result->Status->StatusCode->gg, zx_Value_ATTR, "urn:oasis:names:tc:xacml:1.0:status:ok");
  zx_reverse_elem_lists(&resp->Result->gg);
  return resp;
}

/*() Low level constructor for simple XACML attribute (see the
 * source to understand how "simple" they are). */

/* Called by:  zxid_call_trustpdp x6, zxid_pepmap_extract x3 */
struct zx_xac_Attribute_s* zxid_mk_xacml_simple_at(zxid_conf* cf, struct zx_elem_s* father, struct zx_str* atid, struct zx_str* attype, struct zx_str* atissuer, struct zx_str* atvalue)
{
  struct zx_root_s* r;
  struct zx_xac_Attribute_s* at = zx_NEW_xac_Attribute(cf->ctx, father);
  at->AttributeId = zx_ref_len_attr(cf->ctx, &at->gg, zx_AttributeId_ATTR, atid->len, atid->s);
  at->DataType = zx_ref_len_attr(cf->ctx, &at->gg, zx_DataType_ATTR, attype->len, attype->s);
  if (atissuer)
    at->Issuer = zx_ref_len_attr(cf->ctx, &at->gg, zx_Issuer_ATTR, atissuer->len, atissuer->s);
  if (atvalue->s[0] == '<') {
    /* Looks like the value may be XML data. We need to pass it as XML data structure for
     * canonicalization to work right (e.g. value is an A7N that is rendered one
     * way when canonicalized independently, but in different way when canonicalized
     * as part of a bigger structure - for example sa namespace may be omitted as it
     * is already supplied by the parent element). */
    r = zx_dec_zx_root(cf->ctx, atvalue->len, atvalue->s, "xac at parse");
    if (r && r->gg.kids) {
      at->AttributeValue = zx_new_elem(cf->ctx, &at->gg, zx_xac_AttributeValue_ELEM);
      at->AttributeValue->kids = r->gg.kids;
      ZX_FREE(cf->ctx, r);
    } else {
      /* XML did not parse, may be its just string data, after all. */
      at->AttributeValue = zx_new_str_elem(cf->ctx, &at->gg, zx_xac_AttributeValue_ELEM, atvalue);
    }
  } else {
    at->AttributeValue = zx_new_str_elem(cf->ctx, &at->gg, zx_xac_AttributeValue_ELEM, atvalue);
  }
  zx_reverse_elem_lists(&at->gg);
  return at;
}

/*() Construct xac_Request */

/* Called by:  zxid_az_soap, zxid_mk_az, zxid_mk_az_cd1 */
struct zx_xac_Request_s* zxid_mk_xac_az(zxid_conf* cf, struct zx_elem_s* father, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* env)
{
  struct zx_xac_Request_s* r = zx_NEW_xac_Request(cf->ctx, father);
  /* N.B. The lists are already linked and only need to be attached to kids lists. */
  r->Subject  = zx_NEW_xac_Subject(cf->ctx, &r->gg);
  r->Subject->gg.kids = (struct zx_elem_s*)(r->Subject->Attribute = subj);

  r->Resource = zx_NEW_xac_Resource(cf->ctx, &r->gg);
  r->Resource->gg.kids = (struct zx_elem_s*)(r->Resource->Attribute = rsrc);

  r->Action   = zx_NEW_xac_Action(cf->ctx, &r->gg);
  r->Action->gg.kids = (struct zx_elem_s*)(r->Action->Attribute = act);

  r->Environment = zx_NEW_xac_Environment(cf->ctx, &r->gg);
  r->Environment->gg.kids = (struct zx_elem_s*)(r->Environment->Attribute = env);

  zx_reverse_elem_lists(&r->gg);
  return r;
}

/*() Construct XACMLAuthzDecisionQuery */

/* Called by:  attribute_sort_test, zxid_az_soap */
struct zx_xasp_XACMLAuthzDecisionQuery_s* zxid_mk_az(zxid_conf* cf, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* env)
{
  struct zx_xasp_XACMLAuthzDecisionQuery_s* r = zx_NEW_xasp_XACMLAuthzDecisionQuery(cf->ctx,0);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "R", ZXID_ID_BITS);
  r->Version = zx_ref_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));
  r->Request = zxid_mk_xac_az(cf, &r->gg, subj, rsrc, act, env);
  zx_reverse_elem_lists(&r->gg);
  return r;
}

/*() Construct XACMLAuthzDecisionQuery according to Commitee Draft 1 */

/* Called by:  attribute_sort_test, zxid_az_soap */
struct zx_xaspcd1_XACMLAuthzDecisionQuery_s* zxid_mk_az_cd1(zxid_conf* cf, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* env)
{
  struct zx_xaspcd1_XACMLAuthzDecisionQuery_s* r = zx_NEW_xaspcd1_XACMLAuthzDecisionQuery(cf->ctx,0);
  r->Issuer = zxid_my_issuer(cf, &r->gg);
  r->ID = zxid_mk_id_attr(cf, &r->gg, zx_ID_ATTR, "R", ZXID_ID_BITS);
  r->Version = zx_ref_attr(cf->ctx, &r->gg, zx_Version_ATTR, SAML2_VERSION);
  r->IssueInstant = zxid_date_time_attr(cf, &r->gg, zx_IssueInstant_ATTR, time(0));
  r->Request = zxid_mk_xac_az(cf, &r->gg, subj, rsrc, act, env);
  zx_reverse_elem_lists(&r->gg);
  return r;
}

/* EOF  --  zxidmk.c */
