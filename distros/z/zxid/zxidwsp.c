/* zxidwsp.c  -  Handwritten nitty-gritty functions for Liberty ID-WSF Web Services Provider
 * Copyright (c) 2013-2015 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidwsc.c,v 1.16 2009-11-20 20:27:13 sampo Exp $
 *
 * 22.11.2009, created --Sampo
 * 7.1.2010,   added WSP signing --Sampo
 * 31.5.2010,  reworked PEPs extensively --Sampo
 * 25.1.2011,  tweaked RelatesTo header --Sampo
 * 26.10.2013, improved error reporting on credential expired case --Sampo
 * 12.3.2014,  added partial mime multipart support --Sampo
 * 19.2.2015,  fixed Action header detection in the non-XML body case --Sampo
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */
#include <string.h>
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

#define BOOL_STR_TEST(x) ((x) && (x) != '0')

/*() Create SOAP header Action (which is distinct from HTTP headers SOAPaction).
 * This is driven by the configuration option WSC_ACTION_HDR */

static void zxid_add_action_hdr(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env)
{
  struct zx_e_Header_s* hdr = env->Header;
  struct zx_elem_s* first;
  struct zx_el_tok* el_tok;
  struct zx_str* ss;
  char* p;
  
  if (!strcmp(cf->wsc_action_hdr, "#ses")) {
    ERR("***NOT IMPLEMENTED %d", 0);  /* *** TBD */
    return;
  } else if (!strcmp(cf->wsc_action_hdr, "#body1st")) {
    if (env->Body && (first = env->Body->gg.kids)) {
      if (first->g.s && first->g.tok != ZX_TOK_DATA) {
	if (!(p = memchr(first->g.s, ':', first->g.len))) {
	  ss = &first->g;
	} else {
	  ++p;
	  ss = zx_ref_len_str(cf->ctx, first->g.len - (p - first->g.s), p);
	}
      } else {
	if (el_tok = zx_get_el_tok(first)) {
	  ss = zx_ref_str(cf->ctx, el_tok->name);
	} else {
	  ERR("First child element of <e:Body> does not have tag string and is not known token %x", first->g.tok);
	  return;
	}
      }
    } else {
      ERR("Tried to set <a:Action> SOAP header from first child of <e:Body>, but the body does not exist or does not have child element (e.g. JSON or other non-XML body) %p", env->Body);
      return;
    }
  } else if (!strcmp(cf->wsc_action_hdr, "#body1stns")) {
    if (env->Body && (first = env->Body->gg.kids)) {
      if (first->g.s && first->g.tok != ZX_TOK_DATA) {
	if (!(p = memchr(first->g.s, ':', first->g.len))) {
	  ss = zx_strf(cf->ctx, "%s:%.*s", first->ns&&first->ns->url?first->ns->url:"", first->g.len, first->g.s);
	} else {
	  ++p;
	  ss = zx_strf(cf->ctx, "%s:%.*s", first->ns&&first->ns->url?first->ns->url:"", first->g.len - (p - first->g.s), p);
	}
      } else {
	if (el_tok = zx_get_el_tok(first)) {
	  ss = zx_strf(cf->ctx, "%s:%s", first->ns&&first->ns->url?first->ns->url:"", el_tok->name);
	} else {
	  ERR("First child element of <e:Body> does not have tag string and is not known token %x", first->g.tok);
	  return;
	}
      }
    } else {
      ERR("Tried to set <a:Action> SOAP header from first child of <e:Body>, but the Body does not exist or does not have child element %p", env->Body);
      return;
    }
  } else {
    ss = zx_ref_str(cf->ctx, cf->wsc_action_hdr);
  }
  hdr->Action = zx_NEW_a_Action(cf->ctx, &hdr->gg);
  hdr->Action->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->Action->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->Action->actor = zx_ref_attr(cf->ctx, &hdr->Action->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  zx_add_content(cf->ctx, &hdr->Action->gg, ss);
}

/* Possible child elements of e:Header and their order (see c/zx-elem.c, generated from sg)
paos_Request
paos_Response
ecp_Request
ecp_Response
ecp_RelayState
1.    sbf_Framework
2.    b_Sender
3.    a_MessageID
4.    wsse_Security
5.    tas3_Status
6.rs  a_RelatesTo
6.rq  a_ReplyTo      Often omitted, defaults to anonymous, i.e. other end of TCP conn.
a_From               Not used in ID-WSF2
a_FaultTo            Omitted, defaults to ReplyTo
7.rq  a_To
8.rq  a_Action
a_ReferenceParameters
b_Framework
9.rq  b_TargetIdentity
b_CredentialsContext
b_EndpointUpdate
b_Timeout
b_ProcessingContext
b_Consent
10.   b_UsageDirective
b_ApplicationEPR
b_UserInteraction
b_RedirectRequest
b12_Correlation
b12_Provider
b12_ProcessingContext
b12_Consent
b12_UsageDirective
mm7_TransactionID
tas3_Credentials
tas3_ESLPolicies
 */

/*(i) zxid_wsf_decor() implements the main low level ID-WSF web service call logic, including
 * preparation of SOAP headers, use of sec mech (e.g. preparation of wsse:Security
 * header and signing of appropriate compoments of the message), and sequencing
 * of the call. In particular, it is possible that WSP requests user interaction
 * and thus the caller web application will need to perform a redirect and then
 * later call this function again to continue the web service call after interaction.
 *
 * env (rather than Body) is taken as argument so that caller can prepare
 * additional SOAP headers at will before calling this function. This function
 * will add Liberty ID-WSF specific SOAP headers.
 * The returned lists are in reverse order, remember to call zx_reverse_elem_lists(),
 * unless is_resp is set in which case the list is in forward order.
 * epr must be set for request and can be null for response. */

/* Called by:  covimp_test x2, zxid_soap_cgi_resp_body, zxid_wsc_prep, zxid_wsp_decorate x2 */
int zxid_wsf_decor(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env, int is_resp, zxid_epr* epr)
{
  struct zx_wsse_Security_s* sec;
  struct zx_e_Header_s* hdr;
  
  if (!env || !env->Body) {
    ERR("NULL SOAP envelope or body %p", env);
    return 0;
  }
  
  if (!env->Header)
    env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
  hdr = env->Header;

  /* 1. Populate SOAP headers. */
  
  hdr->Framework = zx_NEW_sbf_Framework(cf->ctx, &hdr->gg);
  hdr->Framework->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->Framework->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->Framework->actor = zx_ref_attr(cf->ctx, &hdr->Framework->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  hdr->Framework->version = zx_ref_attr(cf->ctx, &hdr->Framework->gg, zx_version_ATTR, "2.0");

#if 1
  /* 2. *** Conor claims Sender is not mandatory */
  if (!hdr->Sender || !hdr->Sender->providerID) {
    hdr->Sender = zx_NEW_b_Sender(cf->ctx, &hdr->gg);
    hdr->Sender->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->Sender->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
    hdr->Sender->actor = zx_ref_attr(cf->ctx, &hdr->Sender->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
    hdr->Sender->providerID = zxid_my_ent_id_attr(cf, &hdr->Sender->gg, zx_providerID_ATTR);
    if (cf->affiliation)
      hdr->Sender->affiliationID = zx_ref_attr(cf->ctx, &hdr->Sender->gg, zx_affiliationID_ATTR, cf->affiliation);
  } else {
    D("Using caller supplied Sender(%.*s)", hdr->Sender->providerID->g.len, hdr->Sender->providerID->g.s);
  }
#endif
  /* 3. MessageID */
  if (!hdr->MessageID) {
    hdr->MessageID = zx_NEW_a_MessageID(cf->ctx, &hdr->gg);
    hdr->MessageID->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->MessageID->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
    hdr->MessageID->actor = zx_ref_attr(cf->ctx, &hdr->MessageID->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  } else {
    D("Using caller supplied MessageID(%.*s)", ZX_GET_CONTENT_LEN(hdr->MessageID), ZX_GET_CONTENT_S(hdr->MessageID));
  }

  /* 4. Security */

  sec = hdr->Security = zx_NEW_wsse_Security(cf->ctx, &hdr->gg);
  sec->actor = zx_ref_attr(cf->ctx, &sec->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  sec->mustUnderstand = zx_ref_attr(cf->ctx, &sec->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  sec->Timestamp = zx_NEW_wsu_Timestamp(cf->ctx, &sec->gg);
  sec->Timestamp->Created = zx_NEW_wsu_Created(cf->ctx, &sec->Timestamp->gg);
  zx_reverse_elem_lists(&sec->gg);

  /* 5. Status */

  if (ses && ses->curstatus) {
    ZX_ADD_KID(hdr, Status, ses->curstatus);
  }

  if (is_resp) {

    /* 6.rs: RelatesTo and other WSA headers... */

    if (ses && ses->wsp_msgid && ses->wsp_msgid->len) {
      D("wsp_msgid(%.*s) %p %d %p", ses->wsp_msgid->len, ses->wsp_msgid->s, ses->wsp_msgid, ses->wsp_msgid->len, ses->wsp_msgid->s);
      hdr->RelatesTo = zx_NEW_a_RelatesTo(cf->ctx, &hdr->gg);
      zx_add_content(cf->ctx, &hdr->RelatesTo->gg, ses->wsp_msgid);
      hdr->RelatesTo->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->RelatesTo->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
      hdr->RelatesTo->actor = zx_ref_attr(cf->ctx, &hdr->RelatesTo->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
    } else {
      ERR("RelatesTo header not created due to missing wsp_msgid. Are you passing same session to zxid_wsp_validate() and zxid_wsp_decorate()? %p", ses);
    }
  }

#if 0
  /* <a:From> is not used by ID-WSF2 as it is redundant with <b:Sender> */
  hdr->From = zx_NEW_a_From(cf->ctx, &hdr->gg);
  hdr->From->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->From->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->From->actor = zx_ref_attr(cf->ctx, &hdr->From->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  hdr->From->Address = zxid_mk_addr(cf, zx_strf(cf->ctx, "%s?o=P", cf->burl));
#endif


  /* 7.rq a:To */
  
  if (!is_resp && cf->wsc_to_hdr && strcmp(cf->wsc_to_hdr, "#inhibit")) {
    hdr->To = zx_NEW_a_To(cf->ctx, &hdr->gg);
    if (!strcmp(cf->wsc_to_hdr, "#url")) {
      if (epr && epr->Address) {
	zx_add_content(cf->ctx, &hdr->To->gg, ZX_GET_CONTENT(epr->Address));
      } else {
	ERR("WSC_TO_HDR specified as #url, but no epr supplied %p (programmer error)", epr);
      }
    } else {
      zx_add_content(cf->ctx, &hdr->To->gg, zx_dup_str(cf->ctx, cf->wsc_to_hdr));
    }
    hdr->To->mustUnderstand = zx_ref_attr(cf->ctx,&hdr->To->gg,zx_e_mustUnderstand_ATTR,XML_TRUE);
    hdr->To->actor = zx_ref_attr(cf->ctx, &hdr->To->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
  }
  
  /* 8. a:Action */
  
  if (!is_resp && !hdr->Action && cf->wsc_action_hdr)
    zxid_add_action_hdr(cf, ses, env);
  
#if 0
  hdr->ReferenceParameters = zx_NEW_a_ReferenceParameters(cf->ctx, &hdr->gg);
  hdr->ReferenceParameters->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->ReferenceParameters->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->ReferenceParameters->actor = zx_ref_attr(cf->ctx, &hdr->ReferenceParameters->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
#endif

#if 0
  hdr->Credentials = zx_NEW_tas3_Credentials(cf->ctx, &hdr->gg);
  hdr->Credentials->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->Credentials->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->Credentials->actor = zx_ref_attr(cf->ctx, &hdr->Credentials->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
#endif

#if 0
  /* If you want this header, you should
   * create it prior to calling zxid_wsc_call() */
  hdr->UsageDirective = zx_NEW_b_UsageDirective(cf->ctx, &hdr->gg);
  hdr->UsageDirective->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->UsageDirective->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->UsageDirective->actor = zx_ref_attr(cf->ctx, &hdr->UsageDirective->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
#endif

#if 0
  /* Interaction or redirection. If you want this header, you should
   * create it prior to calling zxid_wsc_call() */
  hdr->UserInteraction = zx_NEW_b_UserInteraction(cf->ctx, &hdr->gg);
  hdr->UserInteraction->mustUnderstand = zx_ref_attr(cf->ctx, &hdr->UserInteraction->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
  hdr->UserInteraction->actor = zx_ref_attr(cf->ctx, &hdr->UserInteraction->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
#endif
  
  if (is_resp) {
    zx_add_content(cf->ctx, &sec->Timestamp->Created->gg, zxid_date_time(cf, time(0)));
    if (!ZX_GET_CONTENT(hdr->MessageID))
      zx_add_content(cf->ctx, &hdr->MessageID->gg, zxid_mk_id(cf, "urn:M", ZXID_ID_BITS));
    /* Clear away any credentials from previous iteration. *** clear kids list, too */
    sec->Signature = 0;
    sec->BinarySecurityToken = 0;
    sec->SecurityTokenReference = 0;
    sec->Assertion = 0;
    sec->sa11_Assertion = 0;
    sec->ff12_Assertion = 0;
    
    zxid_attach_sol1_usage_directive(cf, ses, env, TAS3_REQUIRE, cf->wsp_localpdp_obl_emit);
    zx_reverse_elem_lists(&hdr->gg);
    zxid_wsf_sign(cf, cf->wsp_sign, sec, 0, hdr, env->Body);
  }
  return 1;
}

/* ----------------------------------------
 * Simplify writing WSPs */

/*(i) Add ID-WSF (and TAS3) specific headers and signatures to
 * web service response. Simple and intuitive specification of
 * XML as string: no need to build complex data structures.
 *
 * If the string starts by "<e:Envelope", then string should be
 * a complete SOAP envelope including <e:Header> and <e:Body> parts. This
 * allows caller to specify custom SOAP headers, in addition to the ones
 * that the underlying zxid_wsc_call() will add. Usually the payload service
 * will be passed as the contents of the body. If the string starts by
 * "<e:Body", then the <e:Envelope> and <e:Header> are automatically added. If
 * the string starts by neither of the above (be careful to use the "e:" as
 * namespace prefix), the it is assumed to be the payload content to be
 * wrapped in the <e:Body> and the rest of the SOAP envelope.
 *
 * cf:: ZXID configuration object, see zxid_new_conf()
 * ses:: Session object that contains the EPR cache
 * az_cred:: (Optional) Additional authorization credentials or
 *     attributes, query string format. These credentials will be populated
 *     to the attribute pool in addition to the ones obtained from token and
 *     other sources. Then a PDP is called to get an authorization
 *     decision (generating obligations). See also PEPMAP_RSOUT configuration
 *     option. This implements generalized (application independent)
 *     Responder Out PEP. To implement application dependent PEP features
 *     you should call zxid_az() directly.
 * enve:: XML payload as a string
 * return:: SOAP Envelope of the response, as a string, ready to be
 *     sent as HTTP response. */

/* Called by:  covimp_test, main x9, ws_validations, zxid_mini_httpd_wsp_response, zxid_wsp_decoratef, zxidwspcgi_parent */
struct zx_str* zxid_wsp_decorate(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* enve)
{
  struct zx_str* ss;
  struct zx_e_Envelope_s* env;

  if (!cf || !ses || !enve) {
    ERR("Missing config, session, or envelope argument %p %p %p (programmer error)", cf,ses,enve);
    return 0;
  }
  D_INDENT("decor: ");

  env = zxid_add_env_if_needed(cf, enve);
  if (!env) {
    D_DEDENT("decor: ");
    return 0;
  }
  
  //*** Needs thought and development

  /* Call Rs-Out PDP */

  if (!zxid_query_ctlpt_pdp(cf, ses, az_cred, env, TAS3_PEP_RS_OUT,"e:Server", cf->pepmap_rsout)) {
    /* Fall through, letting zxid_wsf_decor() pick up the fault and package it as response. */
  }

  if (ses->curflt) {
    D("Detected curflt, abandoning previous Body content. %d", 0);
    /* *** LEAK: Should free previous body content */
    env->Body = (struct zx_e_Body_s*)zx_replace_kid(&env->gg, (struct zx_elem_s*)zx_NEW_e_Body(cf->ctx, 0));
    ZX_ADD_KID(env->Body, Fault, ses->curflt);
  }
  
  if (!zxid_wsf_decor(cf, ses, env, 1, 0)) {
    ERR("Response decoration failed %p", env);
    D_DEDENT("decor: ");
    return 0;
  }
  //zx_reverse_elem_lists(&env->Header->gg); //*** Again?!? Already done in zxid_wsf_decor(is_resp)
  
  ss = zx_easy_enc_elem_opt(cf, &env->gg);
  DD("DECOR len=%d envelope(%.*s)", ss->len, ss->len, ss->s);
  D_XML_BLOB(cf, "WSP_DECOR", ss->len, ss->s);
  D_DEDENT("decor: ");
  return ss;
}

/*() Create web service response, printf style. See zxid_wsp_decorate() for more documentation. */

/* Called by:  main */
struct zx_str* zxid_wsp_decoratef(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* env_f, ...)
{
  char* s;
  va_list ap;
  va_start(ap, env_f);
  s = zx_alloc_vasprintf(cf->ctx, 0, env_f, ap);
  va_end(ap);
  return zxid_wsp_decorate(cf, ses, az_cred, s);
}

/*() Perform necessary validation steps to check either requester or target identity
 * assertion. Also log the assertion and extract from assertion relevant information
 * into the session. The two types of assertion are distinguished by lk == "req" or "tgt".
 * returns 0 on failure and 1 on success.
 * See zxid_sp_sso_finalize() for similar code.  *** consider factoring out commonality */

/* Called by:  zxid_wsp_validate_env x2 */
static int zxid_wsf_validate_a7n(zxid_conf* cf, zxid_ses* ses, zxid_a7n* a7n, const char* lk, struct timeval* srcts)
{
  struct zx_str* logpath;
  struct zx_str* a7nss;
  struct zxsig_ref refs;
  zxid_nid* nameid;
  int fmt;
  struct zx_str* issuer;
  zxid_entity* idp_meta;
  zxid_cgi cgi;
  
  if (!a7n || !a7n->Subject) {
    ERR("%s: Assertion lacking or does not have Subject. %p", lk, a7n);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Assertion does not have Subject.", "IDStarMsgNotUnderstood", 0, lk, 0));
    return 0;
  }
  
  issuer = ZX_GET_CONTENT(a7n->Issuer);
  nameid = zxid_decrypt_nameid(cf, a7n->Subject->NameID, a7n->Subject->EncryptedID);
  if (!ZX_GET_CONTENT(nameid)) {
    ERR("%s: Assertion does not have Subject->NameID. %p", lk, ses->nameid);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Assertion does not have Subject->NameID.", "IDStarMsgNotUnderstood", 0, lk, 0));
    return 0;
  }
  
  if (nameid->Format && !memcmp(nameid->Format->g.s, SAML2_TRANSIENT_NID_FMT, nameid->Format->g.len)) {
    fmt = 0;
  } else {
    fmt = 1;  /* anything nontransient may be a federation */
  }

  D("A7N received. NID(%s) FMT(%d) SESIX(%s)", STRNULLCHKQ(ses->nid), ses->nidfmt, STRNULLCHK(ses->sesix));
  if (!strcmp(lk, "tgt")) {
    ses->tgtnameid = nameid;
    ses->tgt = zx_str_to_c(cf->ctx, ZX_GET_CONTENT(nameid));
    ses->tgtfmt = fmt;
  } else {
    ses->nameid = nameid;
    ses->nid = zx_str_to_c(cf->ctx, ZX_GET_CONTENT(nameid));
    ses->nidfmt = fmt;
  }
  
  /* Validate signature (*** add Issuer trusted check, CA validation, etc.) */
  
  idp_meta = zxid_get_ent_ss(cf, issuer);
  if (!idp_meta) {
    ses->sigres = ZXSIG_NO_SIG;
    if (!cf->nosig_fatal) {
      ERR("%s: Unable to find metadata for Assertion Issuer(%.*s).", lk, issuer->len, issuer->s);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No unable to find SAML metadata for Assertion Issuer.", "ProviderIDNotValid", 0, lk, 0));
      return 0;
    } else {
      INFO("%s: Unable to find metadata for Assertion Issuer(%.*s), but configured to ignore this problem (NOSIG_FATAL=0).", lk, issuer->len, issuer->s);
    }
  } else {
    if (a7n->Signature && a7n->Signature->SignedInfo && a7n->Signature->SignedInfo->Reference) {
      ZERO(&refs, sizeof(refs));
      refs.sref = a7n->Signature->SignedInfo->Reference;
      refs.blob = (struct zx_elem_s*)a7n;
      ses->sigres = zxsig_validate(cf->ctx, idp_meta->sign_cert, a7n->Signature, 1, &refs);
      zxid_sigres_map(ses->sigres, &cgi.sigval, &cgi.sigmsg);
    } else {
      if (cf->msg_sig_ok && !ses->sigres) {
	INFO("Assertion without signature accepted due to message level signature (SimpleSign) %d", 0);
      } else {
	ses->sigres = ZXSIG_NO_SIG;
	if (!cf->nosig_fatal) {
	  ERR("Assertion not signed. Sigval(%s) %p", STRNULLCHKNULL(cgi.sigval), a7n->Signature);
	  zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Assertion not signed.", TAS3_STATUS_NOSIG, 0, lk, 0));
	  return 0;
	} else {
	  INFO("SSO warn: assertion not signed, but configured to ignore this problem (NOSIG_FATAL=0). Sigval(%s) %p", STRNULLCHKNULL(cgi.sigval), a7n->Signature);
	}
      }
    }
  }
  if (cf->sig_fatal && ses->sigres) {
    ERR("Fail due to failed assertion signature sigres=%d", ses->sigres);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Assertion signature did not validate.", TAS3_STATUS_BADSIG, 0, lk, 0));
    return 0;
  }
  
  if (zxid_validate_cond(cf, &cgi, ses, a7n, zxid_my_ent_id(cf), 0, 0)) {
    /* Fault (ses->curflt) already set in zxid_validate_cond() */
    return 0;
  }
  
  if (cf->log_rely_a7n) {
    DD("Logging... %d", 0);
    logpath = zxlog_path(cf, issuer, &a7n->ID->g, ZXLOG_RELY_DIR, ZXLOG_A7N_KIND, 1);
    if (logpath) {
      ses->sso_a7n_path = ses->tgt_a7n_path = zx_str_to_c(cf->ctx, logpath);
      a7nss = zx_easy_enc_elem_sig(cf, &a7n->gg);
      if (zxlog_dup_check(cf, logpath, "SSO assertion")) {
	if (cf->dup_a7n_fatal) {
	  zxlog_blob(cf, cf->log_rely_a7n, logpath, a7nss, "wsp_validade dup err");
	  zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Duplicate use of credential (assertion). Replay attack?", TAS3_STATUS_REPLAY, 0, lk, 0));
	  return 0;
	}
      }
      zxlog_blob(cf, cf->log_rely_a7n, logpath, a7nss, "wsp_validate");
      zxlog(cf, 0, srcts, ses->ipport, issuer, ses->wsp_msgid, &a7n->ID->g, ZX_GET_CONTENT(nameid), "N", "K", "A7N VALID", logpath->s, lk);
      zx_str_free(cf->ctx, a7nss);
    }
  }
  return 1;
}

/*() Validate SOAP request envelope, specified as data structure
 *
 * cf:: ZXID configuration object, see zxid_new_conf()
 * ses:: Session object that contains the EPR cache
 * az_cred:: (Optional) Additional authorization credentials or
 *     attributes, query string format. These credentials will be populated
 *     to the attribute pool in addition to the ones obtained from token and
 *     other sources. Then a PDP is called to get an authorization
 *     decision (matching obligations we support to those in the request,
 *     and obligations pleged by caller to those we insist on). See
 *     also PEPMAP configuration option. This implements generalized
 *     (application independent) Responder In PEP. To implement
 *     application dependent PEP features you should call zxid_az() directly.
 * env:: SOAP envelope as data structure
 * return:: idpnid of target identity of the request (rest of the information
 *     is populated to the session object, from where it can be retrieved).
 *     NULL if the validation fails. The target identity is still retrievable
 *     from the session, should there be desire to process the message despite
 *     the validation failure.
 *
 * See also: zxid_wsc_validate_resp_env() */

/* Called by:  zxid_sp_soap_dispatch, zxid_wsp_validate */
char* zxid_wsp_validate_env(zxid_conf* cf, zxid_ses* ses, const char* az_cred, struct zx_e_Envelope_s* env)
{
  int n_refs = 0;
  struct zxsig_ref refs[ZXID_N_WSF_SIGNED_HEADERS];
  struct timeval ourts;
  zxid_entity* wsc_meta;
  struct zx_e_Header_s* hdr;
  struct zx_wsse_Security_s* sec;
  zxid_cgi cgi;
  /*struct zx_b_UsageDirective_s* ud;*/
  struct zx_xa_Obligation_s* obl;

  D_INDENT("valid: ");
  GETTIMEOFDAY(&ourts, 0);
  zxid_set_fault(cf, ses, 0);
  zxid_set_tas3_status(cf, ses, 0);
  
  if (!env) {
    ERR("No <e:Envelope> found. %d", 0);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No SOAP Envelope found.", "IDStarMsgNotUnderstood", 0, 0, 0));
    D_DEDENT("valid: ");
    return 0;
  }

  hdr = env->Header;
  if (!hdr) {
    ERR("No <e:Header> found. %d", 0);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No SOAP Header found.", "IDStarMsgNotUnderstood", 0, 0, 0));
    D_DEDENT("valid: ");
    return 0;
  }
  if (!ZX_SIMPLE_ELEM_CHK(hdr->MessageID)) {
    ERR("No <a:MessageID> found. %d", 0);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No MessageID header found.", "IDStarMsgNotUnderstood", 0, 0, 0));
    D_DEDENT("valid: ");
    return 0;
  }
  /* Remember MessageID for generating RelatesTo in Response */
  ses->wsp_msgid = zx_dup_zx_str(cf->ctx, ZX_GET_CONTENT(hdr->MessageID));
  DD("wsp_msgid(%.*s) %p %d %p", ses->wsp_msgid->len, ses->wsp_msgid->s, ses->wsp_msgid, ses->wsp_msgid->len, ses->wsp_msgid->s);
  
  if (!hdr->Sender || !hdr->Sender->providerID && !hdr->Sender->affiliationID) {
    ERR("No <b:Sender> found (or missing providerID or affiliationID). %p", hdr->Sender);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No b:Sender header found (or missing providerID or affiliationID).", "IDStarMsgNotUnderstood", 0, 0, 0));
    D_DEDENT("valid: ");
    return 0;
  }
  ses->issuer = zx_dup_zx_str(cf->ctx, hdr->Sender->providerID?
			      &hdr->Sender->providerID->g : &hdr->Sender->affiliationID->g);
  
  /* Validate message signature (*** add Issuer trusted check, CA validation, etc.) */
  
  if (!(sec = hdr->Security)) {
    ERR("No <wsse:Security> found. %d", 0);
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No wsse:Security header found.", "IDStarMsgNotUnderstood", 0, 0, 0));
    D_DEDENT("valid: ");
    return 0;
  }

  if (!sec->Signature || !sec->Signature->SignedInfo || !sec->Signature->SignedInfo->Reference) {
    ses->sigres = ZXSIG_NO_SIG;
    if (cf->wsp_nosig_fatal) {
      ERR("No Security/Signature found. %p", sec->Signature);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No wsse:Security/ds:Signature found.", TAS3_STATUS_NOSIG, 0, 0, 0));
      D_DEDENT("valid: ");
      return 0;
    } else {
      INFO("No Security/Signature found, but configured to ignore this problem (NOSIG_FATAL=0). %p", sec->Signature);
    }
  }
  
  wsc_meta = zxid_get_ent_ss(cf, ses->issuer);
  if (wsc_meta) {
    ZERO(refs, sizeof(refs));
    n_refs = zxid_hunt_sig_parts(cf, n_refs, refs, sec->Signature->SignedInfo->Reference, hdr, env->Body);
    /* *** Consider adding BDY and STR */
    ses->sigres = zxsig_validate(cf->ctx, wsc_meta->sign_cert, sec->Signature, n_refs, refs);
    zxid_sigres_map(ses->sigres, &cgi.sigval, &cgi.sigmsg);
    if (cf->sig_fatal && ses->sigres) {
      ERR("Fail due to failed message signature sigres=%d", ses->sigres);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Message signature did not validate.", TAS3_STATUS_BADSIG, 0, 0, 0));
      D_DEDENT("valid: ");
      return 0;
    }
  } else {
    ses->sigres = ZXSIG_NO_SIG;
    if (cf->nosig_fatal) {
      INFO("Unable to find SAML metadata for Sender(%.*s), but configured to ignore this problem (NOSIG_FATAL=0).", ses->issuer->len, ses->issuer->s);
    } else {
      ERR("Unable to find SAML metadata for Sender(%.*s).", ses->issuer->len, ses->issuer->s);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No unable to find SAML metadata for sender.", "ProviderIDNotValid", 0, 0, 0));
      D_DEDENT("valid: ");
      return 0;
    }
  }

  if (!zxid_timestamp_chk(cf, ses, sec->Timestamp, &ourts, &ses->srcts, TAS3_PEP_RQ_IN,"e:Client"))
    return 0;
  
  /* Check Requester Identity */

  ses->a7n = zxid_dec_a7n(cf, sec->Assertion, sec->EncryptedAssertion);
  if (ses->a7n && ses->a7n->Subject) {
    if (!zxid_wsf_validate_a7n(cf, ses, ses->a7n, "req", &ses->srcts)) {
      D_DEDENT("valid: ");
      return 0;
    }
  } else {
    if (sec->EncryptedAssertion && !ses->a7n) {
      ERR("<sa:EncryptedAssertion> could not be decrypted. Perhaps the certificate used to encrypt does not match your private key. This could be due to IdP/Discovery service having wrong copy of your metadata. %d", 0);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "EncryptedAssertion could not be decrypted. (your metadata at the IdP/Discovery has problem?)", TAS3_STATUS_BADCOND, 0, 0, 0));
    } else {
      /* *** should there be absolute requirement for a requester assertion to exist? */
      ERR("No Requester <sa:Assertion> found or assertion missing Subject. %p", ses->a7n);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No assertion found.", TAS3_STATUS_BADCOND, 0, 0, 0));
    }
    D_DEDENT("valid: ");
    return 0;
  }

  /* Check Target Identity */

  if (hdr->TargetIdentity) {
    ses->tgta7n = zxid_dec_a7n(cf, hdr->TargetIdentity->Assertion, hdr->TargetIdentity->EncryptedAssertion);
    if (ses->tgta7n && ses->tgta7n->Subject) {
      if (!zxid_wsf_validate_a7n(cf, ses, ses->a7n, "tgt", &ses->srcts)) {
	D_DEDENT("valid: ");
	return 0;
      }
    } else {
      ERR("No TargetIdentity <sa:Assertion> found. %p", ses->tgta7n);
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "No TargetIdentity Assertion found.", TAS3_STATUS_BADCOND, 0, 0, 0));
      D_DEDENT("valid: ");
      return 0;
    }
    
  } else {
    INFO("No explicit TargetIdentity, using requester identity(%s) as target identity.", ses->nid);
    ses->tgta7n = ses->a7n;
    ses->tgtnameid = ses->nameid;
    ses->tgt = ses->nid;
    ses->tgtfmt = ses->nidfmt;
    ses->tgt_a7n_path = ses->sso_a7n_path;
  }

  if (hdr->UsageDirective) {
    if (obl = hdr->UsageDirective->Obligation) {
      if (ZX_GET_CONTENT(obl->AttributeAssignment)) {
	ses->rcvd_usagedir = zx_str_to_c(cf->ctx, ZX_GET_CONTENT(obl->AttributeAssignment));
	D("Found TAS3 UsageDirective with obligation(%s)", ses->rcvd_usagedir);
      }
      if (obl->ObligationId
	  && ZX_STR_EQ(&obl->ObligationId->g, TAS3_SOL1_ENGINE)) {
	if (ses->rcvd_usagedir
	     && obl->AttributeAssignment->AttributeId) {
	  if (ZX_STR_EQ(&obl->AttributeAssignment->AttributeId->g, TAS3_PLEDGE)) {
	    if (!zxid_eval_sol1(cf, ses, ses->rcvd_usagedir, cf->wsp_localpdp_obl_req)) {
	      return 0;
	    }
	  } else if (ZX_STR_EQ(&obl->AttributeAssignment->AttributeId->g, TAS3_REQUIRE)) {
	    /* *** extract inbound sticky policies */
	    INFO("*** Extraction of inbound sticky policies at WSP not implemented yet %d", 0);
	  } else {
	    ERR("UsageDirective/Obligation/AttributeAssignment@AttributeId(%.*s) not understood", obl->AttributeAssignment->AttributeId->g.len, obl->AttributeAssignment->AttributeId->g.s);
	  }
	} else {
	  ERR("UsageDirective/Obligation/AttributeAssignment missing %p",obl->AttributeAssignment);
	}
      }
    } else if (ZX_GET_CONTENT(hdr->UsageDirective)) {
      ses->rcvd_usagedir = zx_str_to_c(cf->ctx, ZX_GET_CONTENT(hdr->UsageDirective));
      D("Found unknown UsageDirective(%s)", ses->rcvd_usagedir);
    } else {
      ERR("UsageDirective empty or not understood. %p", hdr->UsageDirective->Dict);
    }
  }

  zxid_put_ses(cf, ses);
  zxid_ses_to_pool(cf, ses);
  zxid_snarf_eprs_from_ses(cf, ses);  /* Harvest attributes and bootstrap(s) */
  zxid_put_user(cf, &ses->nameid->Format->g, &ses->nameid->NameQualifier->g, &ses->nameid->SPNameQualifier->g, ZX_GET_CONTENT(ses->nameid), 0);
  zxlogwsp(cf, ses, "K", "PNEWSES", ses->sid, 0);
  
  /* Call Rq-In PDP */

  if (!zxid_query_ctlpt_pdp(cf, ses, az_cred, env, TAS3_PEP_RQ_IN, "e:Server", cf->pepmap_rqin)) {
    return 0;
  }
  
  D_DEDENT("valid: ");
  return ses->tgt;
}

/*(i) Validate SOAP request (envelope), specified by the string.
 *
 * The string should start by "<e:Envelope" (namespace prefix may vary)
 * and should be a complete SOAP envelope including <e:Header> (and <e:Body>)
 * parts.
 *
 * cf:: ZXID configuration object, see zxid_new_conf()
 * ses:: Session object that contains the EPR cache. New data is extracted from request to session.
 * az_cred:: (Optional) Additional authorization credentials or
 *     attributes, query string format. These credentials will be populated
 *     to the attribute pool in addition to the ones obtained from token and
 *     other sources. Then a PDP is called to get an authorization
 *     decision (matching obligations we support to those in the request,
 *     and obligations pleged by caller to those we insist on). See
 *     also PEPMAP configuration option. This implements generalized
 *     (application independent) Responder-In PEP. To implement
 *     application dependent PEP features you should call zxid_az() directly.
 * env:: Entire SOAP envelope as a string
 * return:: idpnid of target identity of the request (rest of the information
 *     is populated to the session object, from where it can be retrieved).
 *     NULL if the validation fails. The target identity is still retrievable
 *     from the session, should there be desire to process the message despite
 *     the validation failure.
 *
 * See also: zxid_wsc_validate_resp_env() */

/* Called by:  chkuid, main, ws_validations, zxid_mini_httpd_wsp, zxidwspcgi_main */
char* zxid_wsp_validate(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* enve)
{
  struct zx_str  ss;
  const char* enve_start;
  char* p;
  char msg[256];
  struct zx_str* logpath;
  struct zx_root_s* r;

  if (!cf || !ses || !enve) {
    ERR("Missing config, session, or envelope argument %p %p %p (programmer error)", cf,ses,enve);
    return 0;
  }

  enve_start = zxid_locate_soap_Envelope(enve);
  if (!enve_start) {
    ERR("SOAP request does not have Envelope element %d", 0);
    D_XML_BLOB(cf, "NO ENVELOPE SOAP request", -2, enve);
    return 0;
  }
  
  ss.s = (char*)enve_start;
  ss.len = strlen(enve_start);
  D_XML_BLOB(cf, "WSP_VALIDATE", ss.len, ss.s);
  r = zx_dec_zx_root(cf->ctx, ss.len, enve, "valid");
  if (!r) {
    zx_format_parse_error(cf->ctx, msg, sizeof(msg), "valid");
    ERR("Malformed XML: %s", msg);
    /* Squash " to ' because the message will appear in XML attribute value delimited by " */
    for (p = msg; *p; ++p)
      if (*p == '"')
	*p = '\'';
    zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RQ_IN, "e:Client", "Malformed XML", "IDStarMsgNotUnderstood", 0, msg, 0));
    return 0;
  }
  p = zxid_wsp_validate_env(cf, ses, az_cred, r->Envelope);
  ZX_FREE(cf->ctx, r);
  
  logpath = zxlog_path(cf, ses->issuer, ses->wsp_msgid, ZXLOG_RELY_DIR, ZXLOG_MSG_KIND, 1);
  if (!logpath) {
    ERR("Log path not valid, empty issuer? %p %p", ses->issuer, ses->wsp_msgid);
    return 0;
  }
  if (zxlog_dup_check(cf, logpath, "validate request")) {
    if (cf->dup_msg_fatal) {
      zxlog_blob(cf, cf->log_rely_msg, logpath, &ss, "validate request dup err");
      zxid_set_fault(cf, ses, zxid_mk_fault(cf, 0, TAS3_PEP_RS_IN, "e:Client", "Duplicate Message.", "DuplicateMsg", 0, 0, 0));
      return 0;
    } else {
      INFO("Duplicate message detected, but configured to ignore this (DUP_MSG_FATAL=0). %d",0);
    }
  }
  zxlog_blob(cf, cf->log_rely_msg, logpath, &ss, "validate request");
  zxlogwsp(cf, ses, "K", "VALID", logpath->s, 0);
  return p;
}

/* EOF  --  zxidwsp.c */
