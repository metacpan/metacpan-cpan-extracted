/* zxidwsf.c  -  Handwritten nitty-gritty functions for Liberty ID-WSF Framework level
 * Copyright (c) 2009-2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidwsc.c,v 1.19 2010-01-08 02:10:09 sampo Exp $
 *
 * 7.1.2007,  created --Sampo
 * 7.10.2008, added documentation --Sampo
 * 7.1.2010,  added WSC signing --Sampo
 * 31.5.2010, added complex sig validation and hunt --Sampo
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidconf.h"
#include "saml2.h"
#include "wsf.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

#define XS_STRING "http://www.w3.org/2001/XMLSchema#string"
#define BOOL_STR_TEST(x) ((x) && (x) != '0')

/*() Try to map security mechanisms across different frame works. Low level
 * function. This also makes some elementary checks as to whether the
 * EPR is even capable of supporting the sec mech. */

/* Called by:  covimp_test, zxid_wsc_prep_secmech */
int zxid_map_sec_mech(zxid_epr* epr)
{
  int len;
  const char* s;
  struct zx_elem_s* secmechid;
  if (!epr || !epr->Metadata || !epr->Metadata->SecurityContext) {
    INFO("EPR lacks Metadata or SecurityContext. Forcing X509. %p", epr->Metadata);
    return ZXID_SEC_MECH_X509;
  }
  secmechid = epr->Metadata->SecurityContext->SecurityMechID;
  if (!ZX_SIMPLE_ELEM_CHK(secmechid)) {
    if (epr->Metadata->SecurityContext->Token) {
      INFO("EPR does not specify sec mech id. Forcing Bearer. %p", secmechid);
      return ZXID_SEC_MECH_BEARER;
    } else {
      INFO("EPR lacks Token. Forcing X509. %p", secmechid);
      return ZXID_SEC_MECH_X509;
    }
  }

  len = ZX_GET_CONTENT_LEN(secmechid);
  s   = ZX_GET_CONTENT_S(secmechid);

  D("mapping secmec(%.*s)", len, s);

#define SEC_MECH_TEST(ret, val) if (len == sizeof(val)-1 && !memcmp(s, val, sizeof(val)-1)) return ret;

  SEC_MECH_TEST(ZXID_SEC_MECH_X509, WSF11_SEC_MECH_NULL_X509);
  SEC_MECH_TEST(ZXID_SEC_MECH_X509, WSF11_SEC_MECH_TLS_X509);
  SEC_MECH_TEST(ZXID_SEC_MECH_X509, WSF11_SEC_MECH_CLTLS_X509);
  
  SEC_MECH_TEST(ZXID_SEC_MECH_NULL, WSF11_SEC_MECH_NULL_NULL);
  SEC_MECH_TEST(ZXID_SEC_MECH_NULL, WSF11_SEC_MECH_TLS_NULL);
  SEC_MECH_TEST(ZXID_SEC_MECH_NULL, WSF11_SEC_MECH_CLTLS_NULL);
  SEC_MECH_TEST(ZXID_SEC_MECH_NULL, WSF20_SEC_MECH_NULL_NULL);
  SEC_MECH_TEST(ZXID_SEC_MECH_NULL, WSF20_SEC_MECH_TLS_NULL);

  SEC_MECH_TEST(ZXID_SEC_MECH_PEERS, WSF20_SEC_MECH_CLTLS_PEERS2);

  if (!epr->Metadata->SecurityContext->Token) {
      INFO("EPR lacks Token despite not being NULL or X509. Forcing X509. %.*s", len, s);
      return ZXID_SEC_MECH_X509;
  }
  
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF10_SEC_MECH_NULL_BEARER);
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF10_SEC_MECH_TLS_BEARER);
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF11_SEC_MECH_NULL_BEARER);
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF11_SEC_MECH_TLS_BEARER);
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF11_SEC_MECH_CLTLS_BEARER);
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF20_SEC_MECH_NULL_BEARER);
  SEC_MECH_TEST(ZXID_SEC_MECH_BEARER, WSF20_SEC_MECH_TLS_BEARER);
     
  SEC_MECH_TEST(ZXID_SEC_MECH_SAML, WSF11_SEC_MECH_NULL_SAML);
  SEC_MECH_TEST(ZXID_SEC_MECH_SAML, WSF11_SEC_MECH_TLS_SAML);
  SEC_MECH_TEST(ZXID_SEC_MECH_SAML, WSF11_SEC_MECH_CLTLS_SAML);
  SEC_MECH_TEST(ZXID_SEC_MECH_SAML, WSF20_SEC_MECH_NULL_SAML2);
  SEC_MECH_TEST(ZXID_SEC_MECH_SAML, WSF20_SEC_MECH_TLS_SAML2);
  SEC_MECH_TEST(ZXID_SEC_MECH_SAML, WSF20_SEC_MECH_CLTLS_SAML2);

  ERR("Unknown security mechanism(%.*s), taking a guess...", len, s);
  
  if (len >= sizeof("Bearer")-1 && zx_memmem(s, len, "Bearer", sizeof("Bearer")-1))
    return ZXID_SEC_MECH_BEARER;
  if (len >= sizeof("SAML")-1 && zx_memmem(s, len, "SAML", sizeof("SAML")-1))
    return ZXID_SEC_MECH_BEARER;
  if (len >= sizeof("X509")-1 && zx_memmem(s, len, "X509", sizeof("X509")-1))
    return ZXID_SEC_MECH_BEARER;
  
  ERR("Unknown security mechanism(%.*s), uable to guess.", len, s);
  return ZXID_SEC_MECH_NULL;
}

#define ZX_URI_Id_CMP(hdr) ((hdr) && (hdr)->Id && (hdr)->Id->g.len == sref->URI->g.len-1 && !memcmp((hdr)->Id->g.s, sref->URI->g.s+1, (hdr)->Id->g.len))
#define ZX_URI_id_CMP(hdr) ((hdr) && (hdr)->id && (hdr)->id->g.len == sref->URI->g.len-1 && !memcmp((hdr)->id->g.s, sref->URI->g.s+1, (hdr)->id->g.len))

/*() For purposes of signature validation, add references and xml data structures
 * of all apparently signed message parts.
 * See also: zxid_add_header_refs() and zxsig_sign() or zxid_chk_sig() + zxsig_validate() */

/* Called by:  wsse_sec_validate, zxid_wsc_valid_re_env, zxid_wsp_validate_env */
int zxid_hunt_sig_parts(zxid_conf* cf, int n_refs, struct zxsig_ref* refs, struct zx_ds_Reference_s* sref, struct zx_e_Header_s* hdr, struct zx_e_Body_s* bdy)
{
  for (; sref && n_refs < ZXID_N_WSF_SIGNED_HEADERS; sref = (void*)ZX_NEXT(sref)) {
    if (sref->gg.g.tok != zx_ds_Reference_ELEM)
      continue;
    if (!sref->URI || !sref->URI->g.len || !sref->URI->g.s || !sref->URI->g.s[0]) {
      ERR("Malformed signature: Reference is missing URI %p n_refs=%d", sref->URI, n_refs);
      continue;
    }
    refs[n_refs].sref = sref;
    refs[n_refs].blob = 0;

    /* Addressing and Security Headers */

    if (ZX_URI_Id_CMP(hdr->Framework)) {
      D("Found ref URI(%.*s) Framework %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Framework;
      ++n_refs;
      continue;
    }
  
    if (hdr->Security) {
      if (ZX_URI_Id_CMP(hdr->Security->Timestamp)) {
	D("Found ref URI(%.*s) Timestamp %d", sref->URI->g.len, sref->URI->g.s, n_refs);
	refs[n_refs].blob = (struct zx_elem_s*)hdr->Security->Timestamp;
	++n_refs;
	continue;
      }
      if (ZX_URI_Id_CMP(hdr->Security->SecurityTokenReference)) {
	D("Found ref URI(%.*s) SecurityTokenReference %d", sref->URI->g.len, sref->URI->g.s, n_refs);
	refs[n_refs].blob = (struct zx_elem_s*)hdr->Security->SecurityTokenReference;
	++n_refs;
	continue;
      }
    }

    if (ZX_URI_Id_CMP(hdr->MessageID)) {
      D("Found ref URI(%.*s) MessageID %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->MessageID;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->RelatesTo)) {
      D("Found ref URI(%.*s) RelatesTo %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->RelatesTo;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->Action)) {
      D("Found ref URI(%.*s) Action %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Action;
      ++n_refs;
      continue;
    }

    if (ZX_URI_Id_CMP(hdr->To)) {
      D("Found ref URI(%.*s) To %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->To;
      ++n_refs;
      continue;
    }

    if (ZX_URI_Id_CMP(hdr->ReplyTo)) {
      D("Found ref URI(%.*s) ReplyTo %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->ReplyTo;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->From)) {
      D("Found ref URI(%.*s) From %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->From;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->Sender)) {
      D("Found ref URI(%.*s) Sender %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Sender;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->FaultTo)) {
      D("Found ref URI(%.*s) FaultTo %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->FaultTo;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->ReferenceParameters)) {
      D("Found ref URI(%.*s) ReferenceParameters %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->ReferenceParameters;
      ++n_refs;
      continue;
    }
  
    /* ID-WSF headers */
  
    if (ZX_URI_Id_CMP(hdr->TargetIdentity)) {
      D("Found ref URI(%.*s) TargetIdentity %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->TargetIdentity;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->UsageDirective)) {
      D("Found ref URI(%.*s) UsageDirective %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->UsageDirective;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->UserInteraction)) {
      D("Found ref URI(%.*s) UserInteraction %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->UserInteraction;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->ProcessingContext)) {
      D("Found ref URI(%.*s) ProcessingContext %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->ProcessingContext;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->EndpointUpdate)) {
      D("Found ref URI(%.*s) EndpointUpdate %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->EndpointUpdate;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->Timeout)) {
      D("Found ref URI(%.*s) Timeout %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Timeout;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->Consent)) {
      D("Found ref URI(%.*s) Consent %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Consent;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->ApplicationEPR)) {
      D("Found ref URI(%.*s) ApplicationEPR %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->ApplicationEPR;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->RedirectRequest)) {
      D("Found ref URI(%.*s) RedirectRequest %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->RedirectRequest;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->CredentialsContext)) {
      D("Found ref URI(%.*s) CredentialsContext %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->CredentialsContext;
      ++n_refs;
      continue;
    }
  
    /* TAS3 specifics */
  
    if (ZX_URI_Id_CMP(hdr->Credentials)) {
      D("Found ref URI(%.*s) Credentials %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Credentials;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_Id_CMP(hdr->ESLPolicies)) {
      D("Found ref URI(%.*s) ESLPolicies %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->ESLPolicies;
      ++n_refs;
      continue;
    }
  
    /* Old ID-WSF 1.2 Headers and App specific headers */
  
    if (ZX_URI_id_CMP(hdr->Correlation)) {
      D("Found ref URI(%.*s) Correlation %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Correlation;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_id_CMP(hdr->Provider)) {
      D("Found ref URI(%.*s) Provider %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->Provider;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_id_CMP(hdr->b12_ProcessingContext)) {
      D("Found ref URI(%.*s) b12_ProcessingContext %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->b12_ProcessingContext;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_id_CMP(hdr->b12_Consent)) {
      D("Found ref URI(%.*s) b12_Consent %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->b12_Consent;
      ++n_refs;
      continue;
    }
  
    if (ZX_URI_id_CMP(hdr->b12_UsageDirective)) {
      D("Found ref URI(%.*s) b12_UsageDirective %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->b12_UsageDirective;
      ++n_refs;
      continue;
    }
#if 0
    if (ZX_URI_id_CMP(hdr->TransactionID)) {
      D("Found ref URI(%.*s) TransactionID %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)hdr->TransactionID;
      ++n_refs;
      continue;
    }
#endif
    if (ZX_URI_id_CMP(bdy)) {
      D("Found ref URI(%.*s) Body %d", sref->URI->g.len, sref->URI->g.s, n_refs);
      refs[n_refs].blob = (struct zx_elem_s*)bdy;
      ++n_refs;
      continue;
    }
  }
  return n_refs;
}

#define ZXID_ADD_WSU_ID(H,idval) MB if (!H->Id) \
  H->Id = zx_ord_ins_at(&H->gg, zx_ref_attr(cf->ctx, 0, zx_wsu_Id_ATTR, idval)); \
  refs[n_refs].id = &H->Id->g; \
  refs[n_refs].canon = zx_easy_enc_elem_sig(cf, &H->gg); \
  ++n_refs; ME

#define ZXID_ADD_ID(H,idval) MB if (!H->id) \
  H->id = zx_ord_ins_at(&H->gg, zx_ref_attr(cf->ctx, 0, zx_id_ATTR, idval)); \
  refs[n_refs].id = &H->id->g; \
  refs[n_refs].canon = zx_easy_enc_elem_sig(cf, &H->gg); \
  ++n_refs; ME


/*() For purposes of signing, add references and canon forms of all known SOAP headers.
 * N.B. This function only works for preparing for signing.
 * See also: zxsig_sign(), zxid_hunt_sig_parts() or zxid_chk_sig() + zxsig_validate() */

/* Called by:  zxid_wsf_sign */
int zxid_add_header_refs(zxid_conf* cf, int n_refs, struct zxsig_ref* refs, struct zx_e_Header_s* hdr)
{
  /* Addressing and Security Headers */

  if (hdr->Framework)
    ZXID_ADD_WSU_ID(hdr->Framework,"FWK");
  if (hdr->Security && hdr->Security->Timestamp)
    ZXID_ADD_WSU_ID(hdr->Security->Timestamp,"TS");
  if (hdr->MessageID)
    ZXID_ADD_WSU_ID(hdr->MessageID,"MID");
  if (hdr->RelatesTo)
    ZXID_ADD_WSU_ID(hdr->RelatesTo,"REL");
  if (hdr->Action)
    ZXID_ADD_WSU_ID(hdr->Action,"ACT");
  if (hdr->To)
    ZXID_ADD_WSU_ID(hdr->To,"TO");
  if (hdr->ReplyTo)
    ZXID_ADD_WSU_ID(hdr->ReplyTo,"REP");
  if (hdr->From)
    ZXID_ADD_WSU_ID(hdr->From,"FRM");
  if (hdr->Sender)
    ZXID_ADD_WSU_ID(hdr->Sender,"PRV");
  if (hdr->FaultTo)
    ZXID_ADD_WSU_ID(hdr->FaultTo,"FLT");
  if (hdr->ReferenceParameters)
    ZXID_ADD_WSU_ID(hdr->ReferenceParameters,"PAR");
  
  /* ID-WSF headers */
  
  if (hdr->TargetIdentity)
    ZXID_ADD_WSU_ID(hdr->TargetIdentity,"TRG");
  if (hdr->UsageDirective)
    ZXID_ADD_WSU_ID(hdr->UsageDirective,"UD");
  if (hdr->UserInteraction)
    ZXID_ADD_WSU_ID(hdr->UserInteraction,"UI");
  if (hdr->ProcessingContext)
    ZXID_ADD_WSU_ID(hdr->ProcessingContext,"PC");
  if (hdr->EndpointUpdate)
    ZXID_ADD_WSU_ID(hdr->EndpointUpdate,"EP");
  if (hdr->Timeout)
    ZXID_ADD_WSU_ID(hdr->Timeout,"TI");
  if (hdr->Consent)
    ZXID_ADD_WSU_ID(hdr->Consent,"CON");
  if (hdr->ApplicationEPR)
    ZXID_ADD_WSU_ID(hdr->ApplicationEPR,"AEP");
  if (hdr->RedirectRequest)
    ZXID_ADD_WSU_ID(hdr->RedirectRequest,"RR");
  if (hdr->CredentialsContext)
    ZXID_ADD_WSU_ID(hdr->CredentialsContext,"CCX");
  
  /* TAS3 specifics */
  
  if (hdr->Credentials)
    ZXID_ADD_WSU_ID(hdr->Credentials,"CRED");
  if (hdr->ESLPolicies)
    ZXID_ADD_WSU_ID(hdr->ESLPolicies,"ESL");
  
  /* Old ID-WSF 1.2 Headers and App specific headers */
  
  if (hdr->Correlation)
    ZXID_ADD_ID(hdr->Correlation,"COR");
  if (hdr->Provider)
    ZXID_ADD_ID(hdr->Provider,"PROV12");
  if (hdr->b12_ProcessingContext)
    ZXID_ADD_ID(hdr->b12_ProcessingContext,"PC12");
  if (hdr->b12_Consent)
    ZXID_ADD_ID(hdr->b12_Consent,"CON12");
  if (hdr->b12_UsageDirective)
    ZXID_ADD_ID(hdr->b12_UsageDirective,"UD12");
#if 0
  if (hdr->TransactionID)
    ZXID_ADD_ID(hdr->TransactionID,"MM7TX"); /* *** mm7:TransactionID does not have id or Id */
#endif
  return n_refs;
}

/*() Apply WSF style signature. */

/* Called by:  zxid_wsc_prep_secmech x3, zxid_wsf_decor */
void zxid_wsf_sign(zxid_conf* cf, int sign_flags, struct zx_wsse_Security_s* sec, struct zx_wsse_SecurityTokenReference_s* str, struct zx_e_Header_s* hdr, struct zx_e_Body_s* bdy)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  int n_refs;
  struct zxsig_ref refs[ZXID_N_WSF_SIGNED_HEADERS];
      
  if (sign_flags) {
    n_refs = 0;
    
    if (sign_flags & ZXID_SIGN_HDR)
      n_refs = zxid_add_header_refs(cf, n_refs, refs, hdr);
    
    if (str)
      ZXID_ADD_WSU_ID(str,"STR");
    
    if (bdy && (sign_flags & ZXID_SIGN_BDY))
      ZXID_ADD_ID(bdy,"BDY");
   
    ASSERTOPI(ZXID_N_WSF_SIGNED_HEADERS, >=, n_refs);

    if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert wsc")) {
      sec->Signature = zxsig_sign(cf->ctx, n_refs, refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
      zx_add_kid(&sec->gg, &sec->Signature->gg);
    }
  }
}

/*() Check ID-WSF Timestamp.
 * The validity is controlled by configuration parameters BEFORE_SLOP and AFTER_SLOP.
 * returns 1 on success, 0 on failure. */

/* Called by:  zxid_wsc_valid_re_env, zxid_wsp_validate_env */
int zxid_timestamp_chk(zxid_conf* cf, zxid_ses* ses, struct zx_wsu_Timestamp_s* ts, struct timeval* ourts, struct timeval* srcts, const char* ctlpt, const char* faultactor)
{
  if (ts && ZX_SIMPLE_ELEM_CHK(ts->Created)) {
    srcts->tv_sec = zx_date_time_to_secs(ZX_GET_CONTENT_S(ts->Created));
     
    if (srcts->tv_sec >= ourts->tv_sec - cf->before_slop
	&& srcts->tv_sec <= ourts->tv_sec + cf->after_slop) {
      D("Timestamp accepted src=%d our=%d before_slop=%d after_slop=%d", (int)srcts->tv_sec, (int)ourts->tv_sec, cf->before_slop, cf->after_slop);
    } else {
      if (cf->notimestamp_fatal) {
	ERR("Timestamp rejected: src=%d our=%d before_slop=%d after_slop=%d secs", (int)srcts->tv_sec, (int)ourts->tv_sec, cf->before_slop, cf->after_slop);
	zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, ctlpt, faultactor, "Message signature did not validate.", "StaleMsg", 0, 0, 0));
	return 0;
      } else {
	INFO("Timestamp rejected: src=%d our=%d before_slop=%d after_slop=%d secs, but configured to ignore this (NOTIMESTAMP_FATAL=0)", (int)srcts->tv_sec, (int)ourts->tv_sec, cf->before_slop, cf->after_slop);
      }
    }

  } else {
    if (cf->notimestamp_fatal) {
      ERR("No Security/Timestamp found. %p", ts);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, ctlpt, faultactor, "No unable to find wsse:Security/Timestamp.", "StaleMsg", 0, 0, 0));
      return 0;
    } else {
      INFO("No Security/Timestamp found, but configured to ignore this (NOTIMESTAMP_FATAL=0). %p", ts);
      D("No ts OK %p", ts);
    }
  }
  return 1;
}

/*() Attach a SOL usage directive, unless the envelope already has UsageDirective
 * header. If you wish to add other UsageDirectives, you must provide all of the
 * usage directives to zxid_call() envelope argument.
 * The obl argument typically comes from cf->wsc_localpdp_obl_pledge
 * or cf->wsp_localpdp_obl_emit */

/* Called by:  zxid_wsc_prep, zxid_wsf_decor */
void zxid_attach_sol1_usage_directive(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env, const char* attrid, const char* obl)
{
  struct zx_b_UsageDirective_s* ud;
  if (!env || !env->Header) {
    ERR("Malformed envelope %p", env);
    return;
  }
  if (!attrid || !*attrid) {
    ERR("attrid argument must be supplied %p", attrid);
    return;
  }
  if (env->Header->UsageDirective) {
    INFO("UsageDirective already set by caller %d",0);
    return;
  }
  if (!obl || !*obl)
    return;

  env->Header->UsageDirective = ud = zx_NEW_b_UsageDirective(cf->ctx, &env->Header->gg);
  ud->mustUnderstand = zx_ref_attr(cf->ctx, &ud->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  ud->actor = zx_ref_attr(cf->ctx, &ud->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  ud->Obligation = zx_NEW_xa_Obligation(cf->ctx, &ud->gg);
  ud->Obligation->ObligationId = zx_ref_attr(cf->ctx, &ud->Obligation->gg, zx_ObligationId_ATTR, TAS3_SOL1_ENGINE);
  ud->Obligation->FulfillOn = zx_ref_attr(cf->ctx, &ud->Obligation->gg, zx_FulfillOn_ATTR, "Permit");
  ud->Obligation->AttributeAssignment = zx_NEW_xa_AttributeAssignment(cf->ctx, &ud->Obligation->gg);
  ud->Obligation->AttributeAssignment->DataType = zx_ref_attr(cf->ctx, &ud->Obligation->AttributeAssignment->gg, zx_DataType_ATTR, XS_STRING);
  ud->Obligation->AttributeAssignment->AttributeId = zx_dup_attr(cf->ctx, &ud->Obligation->AttributeAssignment->gg, zx_AttributeId_ATTR, attrid);
  zx_add_content(cf->ctx, &ud->Obligation->AttributeAssignment->gg, zx_dup_str(cf->ctx, obl));
  D("Attached (%s) obligations(%s)", attrid, obl);
}

/*() Evaluate pledges from UsageDirective against the configured SOL policy.
 *
 * cf:: zxid configuration object
 * ses:: session object
 * obl:: pledges from UsageDirective in the request
 * req:: required policies, usually from cf->wsp_localpdp_obl_req or cf->wsc_localpdp_obl_accept
 * return:: 0 if pladges fail, 1 if pledges are compatible with the required policies
 *
 * All clauses in req must be satisfied by obl. If obl pledges more than required, the excess
 * is silently ignored. If comma separated list of values is specified either as
 * obl or req, all values on obl (pledge) must be found in req, but not all values
 * of req need to be found in obl. This semantic would allow, for example, req to specify
 * all acceptable uses and require each use in pledges to match some use in req.
 * Wild cards (any value, but not prefix, suffix, or substring) in req (and obl) are possible.
 * Negation is not supported: if it is not explicitly listed as ok, then it is rejected.
 */

/* Called by:  zxid_wsp_validate_env */
int zxid_eval_sol1(zxid_conf* cf, zxid_ses* ses, const char* obl, struct zxid_obl_list* req)
{
  char* oblig;
  struct zxid_obl_list* ol;
  struct zxid_obl_list* ob = 0;
  struct zxid_cstr_list* cs = 0;
  
  if (!obl) {
    if (!req)
      return 1;
    ERR("Fail: no pledges supplied and pledges required %p", req);
    return 0;
  }

  oblig = zx_dup_cstr(cf->ctx, obl);     /* Will be modified in place so we need a copy */
  ol = zxid_load_obl_list(cf, 0, oblig);
  for (; req; req = req->n) {
    ob = zxid_find_obl_list(ol, req->name);
    if (!ob)
      goto fail;
    /* Validate every value of the pledge as accpteble in requirement. */
    for (cs = ob->vals; cs; cs = cs->n)
      if (!zxid_find_cstr_list(req->vals, cs->s))
	goto fail;
  }

  INFO("OK: Pledges match requirements. Pledges(%s)", obl);
  zxid_free_obl_list(cf, ol);
  ZX_FREE(cf->ctx, oblig);
  return 1;

 fail:
  ERR("Fail: missing required obligation(%s), value(%s). Pledge(%s)", req?req->name:"-", cs?cs->s:"*", STRNULLCHKD(obl));
  zxid_free_obl_list(cf, ol);
  ZX_FREE(cf->ctx, oblig);
  return 0;
}

/*() Create Action attribute, which will be used by XACML authorization,
 * by concatenating the namespace URL and first child of SOAP Body. As
 * the first child usually is the action verb in many SOAP Requests,
 * we get a usable action. This convention is also recommended
 * in Liberty Alliance Data Services Template 2.1 section 9 "Actions".
 *
 * Example:
 *   ...<e:Body><di:Query xmlns:di="urn:liberty:disco:2006-08">...
 * results
 *   Action=urn:liberty:disco:2006-08:Query
 */

/* Called by:  zxid_query_ctlpt_pdp */
void zxid_add_action_from_body_child(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env)
{
  struct zx_elem_s* el;
  int len;
  char* p;

  /* Skip over any string data, like whitespace, that may precede the element. */
  for (el = env->Body->gg.kids; el && el->g.tok == ZX_TOK_DATA; el = (struct zx_elem_s*)el->g.n) ;
  if (!el) {
    ERR("No Body child element could be found for setting Action %p", env->Body->gg.kids);
    return;
  }
  len = el->g.len;
  p = el->g.s;

  D("Action from Body child ns(%s) name(%.*s)", el->ns->url, len, p);
  if (p = memchr(p, ':', len)) {
    ++p;
    len -= p - el->g.s;
  }
  zxid_add_attr_to_ses(cf, ses, "Action", zx_strf(cf->ctx, "%s:%.*s", el->ns->url, len, p));
}

/*() Query Local PDP and remote PDP (if PDP_URL is defined). */

/* Called by:  zxid_call_epr, zxid_wsc_prepare_call, zxid_wsc_valid_re_env, zxid_wsp_decorate, zxid_wsp_validate_env */
int zxid_query_ctlpt_pdp(zxid_conf* cf, zxid_ses* ses, const char* az_cred, struct zx_e_Envelope_s* env, const char* ctlpt, const char* faultparty, struct zxid_map* pepmap)
{
  /* Populate action from first subelement of body */
  if (env->Body && env->Body->gg.kids) {
    zxid_add_action_from_body_child(cf, ses, env);
  } else {
    ERR("SOAP Body does not appear to have any subelements?!? %p", env->Body);
  }

  /* Populate other attributes, such as rs to indicate resource. */
  if (az_cred)
    zxid_add_qs2ses(cf, ses, zx_dup_cstr(cf->ctx, az_cred), 1);
  zxid_add_qs2ses(cf, ses, zx_alloc_sprintf(cf->ctx, 0, "urn:tas3:ctlpt=%s", ctlpt), 1);
  
  if (!zxid_localpdp(cf, ses)) {
    ERR("%s: Deny by local PDP", ctlpt);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, ctlpt, faultparty, "Denied by local policy", TAS3_STATUS_DENY, 0, 0, 0));
    return 0;
  } else if (cf->pdp_url && *cf->pdp_url) {
    if (!zxid_pep_az_soap_pepmap(cf, 0, ses, cf->pdp_url, pepmap, ctlpt)) {
      ERR("%s: Deny", ctlpt);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, ctlpt, faultparty, "Denied by policy at PDP", TAS3_STATUS_DENY, 0, 0, 0));
      return 0;
    }
  }
  return 1;
}

/* EOF  --  zxidwsf.c */
