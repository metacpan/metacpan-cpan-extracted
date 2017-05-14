/* zxidim.c  -  Identity Mapping Service
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2010 Risaris Ltd, All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxiddi.c,v 1.2 2009-11-24 23:53:40 sampo Exp $
 *
 * 16.9.2010, created --Sampo
 *
 * See also zxcall for client
 * - liberty-idwsf-authn-svc-v2.0.pdf sec 7 "Identity Mapping Service"
 *
 *   zxcot -e http://idp.tas3.pt:8081/zxididp?o=S 'IDMap Svc' \
 *    http://idp.tas3.pt:8081/zxididp?o=B urn:liberty:ims:2006-08 \
 *   | zxcot -b /var/zxid/idpdimd
 *
 * [SOAPAuthn2] "Liberty ID-WSF Authentication, Single Sign-On, and Identity Mapping Services Specification", liberty-idwsf-authn-svc-2.0-errata-v1.0.pdf from http://projectliberty.org/resource_center/specifications/
 */

#include "platform.h"  /* for dirent.h */
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "wsf.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*() ID-WSF Single Sign-On Service (SSOS): Issue SSO assertion in response to receiving a token.
 * See also zxid_idp_sso() for similar code. */

/* Called by:  a7n_test, zxid_sp_soap_dispatch */
struct zx_sp_Response_s* zxid_ssos_anreq(zxid_conf* cf, zxid_ses* ses, struct zx_sp_AuthnRequest_s* ar)
{
  zxid_a7n* outa7n;
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  struct zxsig_ref refs;
  zxid_cgi cgi;
  char logop[8];
  struct zx_sp_Response_s* resp = zx_NEW_sp_Response(cf->ctx,0);
  struct zx_str* payload;
  struct zx_str* ss;
  zxid_entity* sp_meta;
  char uid[ZXID_MAX_BUF];
  strcpy(logop, "xxxANyy");
  D_INDENT("ssos: ");

  if (!ar || !ZX_GET_CONTENT(ar->Issuer)) {
    ERR("No Issuer found in AuthnRequest %p", ar);
    resp->Status = zxid_mk_Status(cf, &resp->gg, "Fail", 0, 0);
    D_DEDENT("ssos: ");
    return resp;
  }

  if (!zxid_idp_map_nid2uid(cf, sizeof(uid), uid, ses->tgtnameid, 0)) {
    resp->Status = zxid_mk_Status(cf, &resp->gg, "Fail", 0, 0);
    D_DEDENT("ssos: ");
    return resp;
  }
  
  ZERO(&cgi, sizeof(cgi));
  ses->an_instant = time(0);  /* This will be later used by AuthnStatement constructor. */
  ses->an_ctx = SAML_AUTHCTX_PREVSESS;  /* Is there better one to use for token based auth? */
  ss = zxid_mk_id(cf, "OSES", ZXID_ID_BITS);  /* Onetime Master session. Each pairwise SSO should have its own to avoid correlation. The session can not be used for SLO. */
  ses->sesix = ss->s;
  ZX_FREE(cf->ctx, ss);
  ses->sid = cgi.sid = ses->sesix;
  cgi.uid = uid;
  ses->uid = cgi.uid;
  /*zxid_put_ses(cf, ses);*/
  
  sp_meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(ar->Issuer));
  if (!sp_meta) {
    ERR("The metadata for Issuer of the AuthnRequest could not be found or fetched %d", 0);
    resp->Status = zxid_mk_Status(cf, &resp->gg, "Fail", 0, 0);
    D_DEDENT("ssos: ");
    return resp;
  }
  D("sp_eid(%s)", sp_meta->eid);

  outa7n = zxid_sso_issue_a7n(cf, &cgi, ses, &ses->srcts, sp_meta, 0, 0, logop, ar);

  if (cf->sso_sign & ZXID_SSO_SIGN_A7N) {
    ZERO(&refs, sizeof(refs));
    refs.id = &outa7n->ID->g;
    refs.canon = zx_easy_enc_elem_sig(cf, &outa7n->gg);
    if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert paos")) {
      outa7n->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
      zx_add_kid_after_sa_Issuer(&outa7n->gg, &outa7n->Signature->gg);
    }
  }
  resp = zxid_mk_saml_resp(cf, outa7n, cf->post_a7n_enc?sp_meta:0);
  payload = zxid_anoint_sso_resp(cf, cf->sso_sign & ZXID_SSO_SIGN_RESP, resp, ar);
  if (!payload) {
    resp->Status = zxid_mk_Status(cf, &resp->gg, "Fail", 0, 0);
    D_DEDENT("ssos: ");
    return resp;
  }
  zx_str_free(cf->ctx, payload);

  zxlogwsp(cf, ses, "K", logop, uid, "SSOS");

  /* *** Generate SOAP envelope with ECP header as required by ECP PAOS */
  
  D_DEDENT("ssos: ");
  return resp;
}

/*(i) Use Liberty ID-WSF 2.0 Identity Mapping Service to convert
 * the identity of the session to identity token in the namespace
 * of the entity at_eid.
 *
 * This is the main work horse for WSCs wishing to call WSPs via EPR.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file will be searched
 * at_eid:: EntityID of the destination namespace
 * how:: How to make mapping (0 = invocaction identity, 1 = target identity)
 * return:: 0 on failure, token on success
 *
 * This will generate <im:IdentityMappingRequest> in SOAP envelope to the
 * IM service of the user, as discovered dynamically. For the discovery to work,
 * the service must have been provisioned to the discovery, with command
 * similar to
 *
 *  zxcot -e http://idp.tas3.pt:8081/zxididp?o=S 'IDMap Svc' \
 *     http://idp.tas3.pt:8081/zxididp?o=B urn:liberty:ims:2006-08 \
 *   | zxcot -b /var/zxid/idpdimd
 *
 * The received identity token is stored in session. From there it is usually
 * automatically used in appropriate context (see the how argument). Typically
 * you would not use the return value for anything else than checking for an error.
 */

/* Called by:  zxcall_main */
zxid_tok* zxid_map_identity_token(zxid_conf* cf, zxid_ses* ses, const char* at_eid, int how)
{
  struct zx_e_Envelope_s* env;
  struct zx_im_MappingInput_s* inp;
  struct zx_im_MappingOutput_s* out;
  zxid_epr* epr;
  epr = zxid_get_epr(cf, ses, XMLNS_IMS, 0, 0, 0, 1);
  if (!epr) {
    ERR("No Identity Mapping Service discovered svc(%s) how=%d", STRNULLCHK(at_eid), how);
    return 0;
  }
  
  INFO("Identity Mapping Svc svc(%s) how=%d...", STRNULLCHK(at_eid), how);
  env = zx_NEW_e_Envelope(cf->ctx,0);
  env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
  env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
  env->Body->IdentityMappingRequest = zx_NEW_im_IdentityMappingRequest(cf->ctx, &env->Body->gg);
  env->Body->IdentityMappingRequest->MappingInput = inp = zx_NEW_im_MappingInput(cf->ctx, &env->Body->IdentityMappingRequest->gg);
  //inp->Token = zx_NEW_sec_Token(cf->ctx, &inp->gg);
  //inp->Token->ref = zx_dup_str(cf->ctx, "#A7N");
  inp->TokenPolicy = zx_NEW_sec_TokenPolicy(cf->ctx, &inp->gg);
  inp->TokenPolicy->type = zx_dup_attr(cf->ctx, &inp->TokenPolicy->gg, zx_type_ATTR, TOKNUSG_SEC);
#if 0  /* Default is true anyway */
  inp->TokenPolicy->wantDSEPR = zx_dup_attr(cf->ctx, &inp->TokenPolicy->gg, zx_wantDSEPR_ATTR, "1");
#endif
  inp->TokenPolicy->NameIDPolicy = zx_NEW_sp_NameIDPolicy(cf->ctx, &inp->TokenPolicy->gg);
  inp->TokenPolicy->NameIDPolicy->Format = zx_ref_attr(cf->ctx, &inp->TokenPolicy->NameIDPolicy->gg, zx_Format_ATTR, zxid_saml2_map_nid_fmt("prstnt"));
  inp->TokenPolicy->NameIDPolicy->SPNameQualifier = zx_dup_attr(cf->ctx, &inp->TokenPolicy->NameIDPolicy->gg, zx_SPNameQualifier_ATTR, at_eid);
  inp->TokenPolicy->NameIDPolicy->AllowCreate = zx_ref_attr(cf->ctx, &inp->TokenPolicy->NameIDPolicy->gg, zx_AllowCreate_ATTR, XML_TRUE); /* default false */

  env = zxid_wsc_call(cf, ses, epr, env, 0);
  if (!env || env == (void*)ZXID_REDIR_OK || !env->Body) {
    ERR("Identity Mapping call failed envelope=%p", env);
    return 0;
  }
  if (!env->Body->IdentityMappingResponse) {
      ERR("No Identity Mapping Response at_eid(%s)", STRNULLCHK(at_eid));
      return 0;
  }

  for (out = env->Body->IdentityMappingResponse->MappingOutput;
       out;
       out = (void*)ZX_NEXT(out)) {
    if (out->gg.g.tok != zx_im_MappingOutput_ELEM)
      continue;
    switch (how) {
    case 0:
      D("Invocation token set %p", out->Token);
      ses->call_invoktok = out->Token;
      break;
    case 1:
      D("Target Identity token set %p", out->Token);
      ses->call_tgttok = out->Token;
      break;
    }
    return out->Token;  /* Not really iterating */
  }
  return 0; /* never reached */
}

/*() ID-WSF Identity Mapping Service: Issue token in response to receiving a token */

/* Called by:  zxid_sp_soap_dispatch */
struct zx_im_IdentityMappingResponse_s* zxid_imreq(zxid_conf* cf, zxid_ses* ses, struct zx_im_IdentityMappingRequest_s* req)
{
  struct zx_im_IdentityMappingResponse_s* resp = zx_NEW_im_IdentityMappingResponse(cf->ctx,0);
  struct zx_im_MappingInput_s* mapinp;
  struct zx_im_MappingOutput_s* mapout;
  zxid_tok* tok;
  zxid_a7n* ina7n;
  zxid_a7n* outa7n;
  struct zx_str* issue_to;
  char allow_create;
  char* nid_fmt;
  zxid_nid* nameid;
  char* logop;
  int  n_mapped = 0;
  zxid_entity* sp_meta;
  char sp_name_buf[1024];
  char uid[ZXID_MAX_BUF];
  D_INDENT("imreq: ");
  ses->uid = uid;

  if (!req || !req->MappingInput) {
    ERR("No IdentityMappingRequest/MappingInput found (WSC error) %p", req);
    resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
    D_DEDENT("imreq: ");
    return resp;
  }
  
  for (mapinp = req->MappingInput;
       mapinp;
       mapinp = (struct zx_im_MappingInput_s*)mapinp->gg.g.n) {
    if (mapinp->gg.g.tok != zx_im_MappingInput_ELEM)
      continue;
    
    if (tok = mapinp->Token) {
      if (tok->Assertion || tok->EncryptedAssertion) {
	ina7n = zxid_dec_a7n(cf, tok->Assertion, tok->EncryptedAssertion);
	if (!ina7n || !ina7n->Subject) {
	  ERR("Missing or malformed MappingInput/Token/Assertion %p", ina7n);
	  continue;
	}
	ses->tgtnameid = zxid_decrypt_nameid(cf, ina7n->Subject->NameID, ina7n->Subject->EncryptedID);
      } else if (tok->ref && !zx_str_cmp(&tok->ref->g, &ses->a7n->ID->g)) {
	D("Token->ref(%.*s) matches invocation security token.", tok->ref->g.len, tok->ref->g.s);
	/* N.B. This is a common optimization as it often happens that invoker (delegatee) needs to
	 * IDMap his own token, while delegator's token can usually be found using discovery. */
	ina7n = ses->a7n;
      } else {
	ERR("*** Missing IdentityMappingRequest/MappingInput/Token/(Encrypted)Assertion (WSC error). Using invocation identity instead. %p", tok);
	ina7n = ses->a7n;
      }
    } else {
      ERR("*** Missing IdentityMappingRequest/MappingInput/Token (WSC error). Using invocation identity instead. %d", 0);
      ina7n = ses->a7n;
    }
    
    if (!mapinp->TokenPolicy) {
      ERR("Missing TokenPolicy. %d", 0);
      resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
      D_DEDENT("imreq: ");
      return resp;
    }

    if (!zxid_idp_map_nid2uid(cf, sizeof(uid), uid, ses->tgtnameid, &resp->Status)) {
      D_DEDENT("imreq: ");
      return resp;
    }
    
    /* Figure out destination */

    if (mapinp->TokenPolicy->NameIDPolicy) {
      issue_to = &mapinp->TokenPolicy->NameIDPolicy->SPNameQualifier->g;
      nid_fmt = ZX_STR_EQ(&mapinp->TokenPolicy->NameIDPolicy->Format->g, SAML2_TRANSIENT_NID_FMT) ? "trnsnt" : "prstnt";
      allow_create = XML_TRUE_TEST(&mapinp->TokenPolicy->NameIDPolicy->AllowCreate->g) ? '1':'0';
    } else {
      issue_to = &mapinp->TokenPolicy->issueTo->g;
      nid_fmt = "prstnt";
      allow_create = '1';
    }
    
    if (!issue_to) {
      ERR("No NameIDPolicy->SPNameQualifier or issueTo %p", mapinp->TokenPolicy);
      resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
      D_DEDENT("imreq: ");
      return resp;
    }
    zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), issue_to, issue_to, 7);

    /* Check for federation */

    nameid = zxid_check_fed(cf, issue_to, uid, allow_create, 0, 0, 0, sp_name_buf);
    if (nameid) {
      if (nid_fmt && !strcmp(nid_fmt, "trnsnt")) {
	D("Despite old fed, using transient due to nid_fmt(%s)", STRNULLCHKD(nid_fmt));
	zxid_mk_transient_nid(cf, nameid, sp_name_buf, uid);
	logop = "ITIM";
      } else
	logop = "IFIM";
    } else {
      D("No nameid (because of no federation), using transient %d", 0);
      nameid = zx_NEW_sa_NameID(cf->ctx,0);
      zxid_mk_transient_nid(cf, nameid, sp_name_buf, uid);
      logop = "ITIM";
    }

    /* Issue the assertion and sign it. */

    sp_meta = zxid_get_ent_ss(cf, issue_to);
    if (!sp_meta) {
      ERR("The metadata for provider could not be found or fetched. Reject. %d", 0);
      resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
      D_DEDENT("imreq: ");
      return resp;
    }
    
    outa7n = zxid_mk_usr_a7n_to_sp(cf, ses, nameid, sp_meta, sp_name_buf, 1);
    
    if (!zxid_anoint_a7n(cf, cf->sso_sign & ZXID_SSO_SIGN_A7N, outa7n, issue_to, "IMA7N", uid,0)) {
      resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
      D_DEDENT("imreq: ");
      return resp;
    }
    
    /* Formulate mapping output */

    resp->MappingOutput = mapout = zx_NEW_im_MappingOutput(cf->ctx, &resp->gg);
    if (mapinp->reqID && mapinp->reqID->g.len && mapinp->reqID->g.s)
      mapout->reqRef = zx_dup_len_attr(cf->ctx, &mapout->gg, zx_reqRef_ATTR, mapinp->reqID->g.len, mapinp->reqID->g.s);
    mapout->Token = zx_NEW_sec_Token(cf->ctx, &mapout->gg);
    if (cf->di_a7n_enc) {
      mapout->Token->EncryptedAssertion = zxid_mk_enc_a7n(cf, &mapout->Token->gg, outa7n, sp_meta);
    } else {
      zx_add_kid(&mapout->Token->gg, &outa7n->gg);
      mapout->Token->Assertion = outa7n;
    }

    ++n_mapped;
    zxlogwsp(cf, ses, "K", logop, 0,"n=%d", n_mapped);
  }
  
  D("TOTAL Identity Mappings issued %d", n_mapped);
  zxlogwsp(cf, ses, "K", "IMOK", 0, "n=%d", n_mapped);
  resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "OK", 0, 0, 0);
  D_DEDENT("imreq: ");
  return resp;
}

/*(i) Use SAML 2.0 NameID Mapping Service to convert
 * the identity of the session to identity token in the namespace
 * of the entity at_eid.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file will be searched
 * at_eid:: EntityID of the destination namespace
 * how:: How to make mapping (0 = invocaction identity, 1 = target identity)
 * return:: 0 on failure, token on success
 *
 * This will generate <im:IdentityMappingRequest> in SOAP envelope to the
 * IM service of the user, as discovered dynamically. For the discovery to work,
 * the service must have been provisioned to the discovery, with command
 * similar to
 *
 *  zxcot -e http://idp.tas3.pt:8081/zxididp?o=S 'IDMap Svc' \
 *     http://idp.tas3.pt:8081/zxididp?o=B urn:liberty:ims:2006-08 \
 *   | zxcot -b /var/zxid/idpdimd
 *
 * The received identity token is stored in session. From there it is usually
 * automatically used in appropriate context (see the how argument). Typically
 * you would not use the return value for anything else than checking for an error.
 */

/* Called by:  zxcall_main */
zxid_tok* zxid_nidmap_identity_token(zxid_conf* cf, zxid_ses* ses, const char* at_eid, int how)
{
  struct zx_e_Envelope_s* env;
  struct zx_sec_Token_s* tok;
  struct zx_sp_NameIDMappingRequest_s* req;
  zxid_epr* epr;
  epr = zxid_get_epr(cf, ses, XMLNS_IMS, 0, 0, 0, 1);
  if (!epr) {
    ERR("No Identity Mapping Service discovered svc(%s) how=%d", STRNULLCHK(at_eid), how);
    return 0;
  }
  
  INFO("NID Mapping svc(%s) how=%d...", STRNULLCHK(at_eid), how);
  env = zx_NEW_e_Envelope(cf->ctx,0);
  env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
  env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
  env->Body->NameIDMappingRequest = req = zx_NEW_sp_NameIDMappingRequest(cf->ctx, &env->Body->gg);

  req->NameIDPolicy = zx_NEW_sp_NameIDPolicy(cf->ctx, &req->gg);
  req->NameIDPolicy->Format = zx_ref_attr(cf->ctx, &req->NameIDPolicy->gg, zx_Format_ATTR, zxid_saml2_map_nid_fmt("prstnt"));
  req->NameIDPolicy->SPNameQualifier = zx_dup_attr(cf->ctx, &req->NameIDPolicy->gg, zx_SPNameQualifier_ATTR, at_eid);
  req->NameIDPolicy->AllowCreate = zx_ref_attr(cf->ctx, &req->NameIDPolicy->gg, zx_AllowCreate_ATTR, XML_TRUE); /* default false */
  
  req->NameID = ses->nameid;  /* or tgtnameid? */

  env = zxid_wsc_call(cf, ses, epr, env, 0);
  if (!env || env == (void*)ZXID_REDIR_OK || !env->Body) {
    ERR("Identity Mapping call failed envelope=%p", env);
    return 0;
  }
  if (!env->Body->NameIDMappingResponse) {
      ERR("No Identity Mapping Response at_eid(%s)", STRNULLCHK(at_eid));
      return 0;
  }
  
  tok = zx_NEW_sec_Token(cf->ctx, 0);
  if (env->Body->NameIDMappingResponse->NameID) {
    ERR("*** NOT IMPLEMENTED NameIDMappingResponse has NameID %p", tok);

  } else if (env->Body->NameIDMappingResponse->EncryptedID) {
    ERR("*** NOT IMPLEMENTED NameIDMappingResponse has EncryptedID %p", tok);

  } else {
    ERR("NameIDMappingResponse did not contain any ID %p", tok);
    return 0;
  }
      
  switch (how) {
  case 0:
    D("Invocation token set %p", tok);
    ses->call_invoktok = tok;
    break;
  case 1:
    D("Target Identity token set %p", tok);
    ses->call_tgttok = tok;
    break;
  }
  return tok;
}

/*() SAML NameID Mapping Service: Issue token in response to receiving a token */

/* Called by:  zxid_sp_soap_dispatch */
struct zx_sp_NameIDMappingResponse_s* zxid_nidmap_do(zxid_conf* cf, struct zx_sp_NameIDMappingRequest_s* req)
{
  struct zx_sp_NameIDMappingResponse_s* resp = zx_NEW_sp_NameIDMappingResponse(cf->ctx,0);
  struct zx_str* issue_to;
  struct zx_str* affil;
  char allow_create;
  char* nid_fmt;
  zxid_nid* nameid;
  char* logop;
  int len, n_mapped = 0;
  char uid[ZXID_MAX_BUF];
  char sp_name_buf[1024];
  D_INDENT("nidmap: ");
    
  /* *** there should be some strict access control policies here, otherwise
   * privacy can be lost by consulting nameids directly via this service. */
  
  nameid = zxid_decrypt_nameid(cf, req->NameID, req->EncryptedID);
  affil = nameid->SPNameQualifier ? &nameid->SPNameQualifier->g : zxid_my_ent_id(cf);
  
  zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), affil, affil, 7);
  len = read_all(sizeof(uid)-1, uid, "idp_map_nid2uid", 1, "%s" ZXID_NID_DIR "%s/%.*s", cf->cpath, sp_name_buf, ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
  if (!len) {
    ERR("Can not find reverse mapping for SP,SHA1(%s) nid(%.*s)", sp_name_buf, ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
    resp->Status = zxid_mk_Status(cf, &resp->gg, "Fail", 0, 0);
    D_DEDENT("nidmap: ");
    return resp;
  }
  
  /* Figure out destination */
  
  if (req->NameIDPolicy) {
    issue_to = &req->NameIDPolicy->SPNameQualifier->g;
    nid_fmt = ZX_STR_EQ(&req->NameIDPolicy->Format->g, SAML2_TRANSIENT_NID_FMT) ? "trnsnt" : "prstnt";
    allow_create = XML_TRUE_TEST(&req->NameIDPolicy->AllowCreate->g) ? '1':'0';
  } else {
    issue_to = 0;
  }
  
  if (!issue_to) {
    ERR("No NameIDPolicy->SPNameQualifier %p", req->NameIDPolicy);
    resp->Status = zxid_mk_Status(cf, &resp->gg, "Fail", 0, 0);
    D_DEDENT("nidmap: ");
    return resp;
  }
  zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), issue_to, issue_to, 7);
  
  /* Check for federation */
  
  nameid = zxid_check_fed(cf, issue_to, uid, allow_create, 0, 0, 0, sp_name_buf);
  if (nameid) {
    if (nid_fmt && !strcmp(nid_fmt, "trnsnt")) {
      D("Despite old fed, using transient due to nid_fmt(%s)", STRNULLCHKD(nid_fmt));
      zxid_mk_transient_nid(cf, nameid, sp_name_buf, uid);
      logop = "ITNIDMAP";
    } else
      logop = "IFNIDMAP";
  } else {
    D("No nameid (because of no federation), using transient %d", 0);
    nameid = zx_NEW_sa_NameID(cf->ctx,0);
    zxid_mk_transient_nid(cf, nameid, sp_name_buf, uid);
    logop = "ITNIDMAP";
  }
  
  zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(nameid), "N", "K", logop, 0, "n=%d", n_mapped);
  resp->Status = zxid_OK(cf, &resp->gg);
  D_DEDENT("nidmap: ");
  return resp;
}

/* EOF  --  zxidim.c */
