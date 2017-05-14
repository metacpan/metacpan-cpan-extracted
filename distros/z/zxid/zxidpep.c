/* zxidpep.c  -  Handwritten functions for XACML Policy Enforcement Point
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidpep.c,v 1.10 2010-01-08 02:10:09 sampo Exp $
 *
 * 24.8.2009, created --Sampo
 * 10.10.2009, added zxid_az() family --Sampo
 * 12.2.2010,  added locking to lazy loading --Sampo
 * 31.5.2010,  generalized to several PEPs model --Sampo
 * 7.9.2010,   merged patches from Stijn Lievens --Sampo
 * 10.1.2011,  added TrustPDP support --Sampo
 *
 * See also: zxid_simple_ab_pep() in zxidpdp.c, zxidwsc.c, zxidwsp.c
 */

#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidconf.h"
#include "saml2.h"
#include "tas3.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"
#include "c/zx-e-data.h"

#if 0
#define XS_STRING "xs:string"
#else
#define XS_STRING "http://www.w3.org/2001/XMLSchema#string"
#endif

/*() Check for duplicate attribute in XACML attribute chain
 * for nth occurance of named attribute.
 *
 * - NULL or zero length name will match any
 * - minus one (-1) as either length field will cause strlen() to be done
 * - the index n is one based
 *
 * *Arguments*
 *
 * xac_at_list:: List of (already existing) xac attributes to scan, potentially NULL.
 * name_len:: Length of the attribute name, or 0 if no matching by attribute name is desired
 * name:: attribute name to match (or 0)
 * n:: Howmanieth instance of the matching attribute is desired. 1 means first.
 * return:: Data structure representing the matching attribute.
 */

/* Called by:  zxid_pepmap_extract x4 */
static struct zx_xac_Attribute_s* zxid_find_xac_attribute(struct zx_xac_Attribute_s* xac_at_list, int name_len, char* name, int n)
{
  struct zx_xac_Attribute_s* at;
  if (!name) { name_len = 0; name = ""; }
  if (name_len == -1 && name) name_len = strlen(name);
  if (!xac_at_list) {
    DD("No xac attribute list when looking for attribute name(%.*s) n=%d", name_len, name, n);
    return 0;
  }
  for (at = xac_at_list;
       at;
       at = (struct zx_xac_Attribute_s*)at->gg.g.n) {
    if (at->gg.g.tok != zx_xac_Attribute_ELEM)
      continue;
    if ((name_len ? (at->AttributeId
		     && at->AttributeId->g.len == name_len
		     && !memcmp(at->AttributeId->g.s, name, name_len)) : 1)
	) {
      --n;
      if (!n)
	return at;
    }
  }
  return 0;
}

/*() Extract attributes from session pool according to pepmap, usually the PEPMAP
 * configuration variable.
 *
 * cf:: the configuration will need to have ~PEPMAP~ and ~PDP_URL~ options
 *     set according to your situation.
 * cgi:: if non-null, will receive error and status codes
 * ses:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO.
 * pepmap:: The map used to extract the attributes from the pool to the XACML request
 * subj:: Value-result parameter. Linked list of subject attributes.
 * rsrc:: Value-result parameter. Linked list of resource attributes.
 * act::  Value-result parameter. Linked list of action attributes (usually just one attribute).
 * env::  Value-result parameter. Linked list of environment attributes.
 */

/* Called by:  zxid_call_trustpdp, zxid_pep_az_base_soap_pepmap, zxid_pep_az_soap_pepmap */
static void zxid_pepmap_extract(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zxid_map* pepmap, struct zx_xac_Attribute_s** subj, struct zx_xac_Attribute_s** rsrc, struct zx_xac_Attribute_s** act, struct zx_xac_Attribute_s** env)
{
  struct zxid_map* map;
  struct zxid_attr* at;
  struct zxid_attr* av;
  struct zx_xac_Attribute_s* xac_at;
  char* name;

  for (at = ses?ses->at:0; at; at = at->n) {
    map = zxid_find_map(pepmap, at->name);
    if (!map) {
      D("ATTR(%s)=VAL(%s): Ignored due to no matching PEPMAP", at->name, at->val);
      continue;
    }

    if (map->rule == ZXID_MAP_RULE_DEL) {
      D("attribute(%s) filtered out by del rule in PEPMAP", at->name);
      continue;
    }
    
    at->map_val = zxid_map_val(cf, ses, 0, map, at->name, at->val);
    
    if (!at->map_val || !at->map_val->len || !at->map_val->s) {
      if (cf->az_opt & 0x02) {
	INFO("attribute(%s) with empty value passed due to AZ_OPT=0x02", at->name);
	continue;
      } else {
	INFO("attribute(%s) filtered out due to empty value", at->name);
	continue;
      }
    }

    if (map->dst && *map->dst && map->src && map->src[0] != '*') {
      D("renaming(%s) to(%s) orig_val(%s) map_val(%.*s)", at->name, map->dst, at->val, at->map_val->len, at->map_val->s);
      name = map->dst;
    } else {
      name = at->name;
    }
    xac_at = zxid_mk_xacml_simple_at(cf, 0,
				     zx_dup_str(cf->ctx, name),
				     zx_dup_str(cf->ctx, XS_STRING),
				     at->issuer, at->map_val);
    if (map->ns && *map->ns) {
      if (!strcmp(map->ns, "subj")) {
	if (cf->az_opt & 0x04) {
	  DD("Dup allowed by AZ_OPT=0x04");
	} else if (zxid_find_xac_attribute(*subj, -1, at->name, 1)) {
	  INFO("attribute(%s) filtered out as duplicate", at->name);
	  continue;
	}
	ZX_NEXT(xac_at) = (void*)*subj;
	*subj = xac_at;
      } else if (!strcmp(map->ns, "rsrc")) {
	if (cf->az_opt & 0x04) {
	  DD("Dup allowed by AZ_OPT=0x04");
	} else if (zxid_find_xac_attribute(*rsrc, -1, at->name, 1)) {
	  INFO("attribute(%s) filtered out as duplicate", at->name);
	  continue;
	}
	ZX_NEXT(xac_at) = (void*)*rsrc;
	*rsrc = xac_at;
      } else if (!strcmp(map->ns, "act")) {
	if (cf->az_opt & 0x04) {
	  DD("Dup allowed by AZ_OPT=0x04");
	} else if (zxid_find_xac_attribute(*act, -1, at->name, 1)) {
	  INFO("attribute(%s) filtered out as duplicate", at->name);
	  continue;
	}
#if 0
	*act = xac_at;  /* there can be only one */
#else
        ZX_NEXT(xac_at) = (void*)*act;
        *act = xac_at;  /* We can have multiple attributes in the action section */
#endif
      } else if (!strcmp(map->ns, "env")) {
	if (cf->az_opt & 0x04) {
	  DD("Dup allowed by AZ_OPT=0x04");
	} else if (zxid_find_xac_attribute(*env, -1, at->name, 1)) {
	  INFO("attribute(%s) filtered out as duplicate", at->name);
	  continue;
	}
	ZX_NEXT(xac_at) = (void*)*env;
	*env = xac_at;
      } else {
	ERR("PEPMAP unknown ns(%s). Valid values are subj, rsrc, act, and env.", map->ns);
      }
    } else {
      ERR("PEPMAP entry lacks ns %p", map->ns);
    }
    
    for (av = at->nv; av; av = av->n) {
      av->map_val = zxid_map_val(cf, ses, 0, map, at->name, av->val);
      xac_at = zxid_mk_xacml_simple_at(cf, 0,
				       zx_dup_str(cf->ctx, name),
				       zx_dup_str(cf->ctx, XS_STRING),
				       at->issuer, at->map_val);
      if (map->ns && *map->ns) {
	if (!strcmp(map->ns, "subj")) {
	  ZX_NEXT(xac_at) = (void*)*subj;
	  *subj = xac_at;
	} else if (!strcmp(map->ns, "rsrc")) {
	  ZX_NEXT(xac_at) = (void*)*rsrc;
	  *rsrc = xac_at;
	} else if (!strcmp(map->ns, "act")) {
	  ERR("PEPMAP: Only one XACML action attribute allowed %d", 0);
	} else if (!strcmp(map->ns, "env")) {
	  ZX_NEXT(xac_at) = (void*)*env;
	  *env = xac_at;
	} else {
	  ERR("PEPMAP unknown ns(%s). Valid values are subj, rsrc, act, and env.", map->ns);
	}
      } else {
	ERR("PEPMAP entry lacks ns %p", map->ns);
      }
    }
  }
  
  if (!*act) {
    *act = zxid_mk_xacml_simple_at(cf, 0,
	     zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:action:action-id"),
	     zx_dup_str(cf->ctx, XS_STRING),
	     0,
	     zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:action:implied-action"));
  }
}

/* ============== Policy Enforcement Point, Authorization Decision Query ============== */

/*() Call Policy Decision Point (PDP) to obtain an authorization decision
 * about a contemplated action on a resource. The attributes from the session
 * pool, as filtered by PEPMAP are fed to the PDP as inputs
 * for the decision. The call is using XACML SAML profile over SOAP.
 *
 * cf:: the configuration will need to have ~PEPMAP~ and ~PDP_URL~ options
 *     set according to your situation.
 * cgi:: if non-null, will receive error and status codes
 * ses:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO.
 * pdp_url:: URL of the PDP to contact
 * subj:: Linked list of subject attributes.
 * rsrc:: Linked list of resource attributes.
 * act::  Linked list of action attributes (usually just one attribute).
 * envi::  Linked list of environment attributes.
 * returns:: SAML Response as data structure or null upon error.
 */

/* Called by:  zxid_call_trustpdp, zxid_pep_az_base_soap_pepmap, zxid_pep_az_soap_pepmap */
static struct zx_sp_Response_s* zxid_az_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* envi)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  struct zxsig_ref refs;
  struct zx_root_s* r;
  struct zx_e_Header_s* hdr;
  struct zx_e_Body_s* body;
  struct zx_wsse_Security_s* sec;
  struct zx_str* ss;
  struct zx_sp_Response_s* resp;

  hdr = zx_NEW_e_Header(cf->ctx,0);
#if 0
  hdr->Action = zx_NEW_a_Action(cf->ctx, &hdr->gg);
  //zx_add_content(cf->ctx, &hdr->Action->gg, zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:2.0:profile:saml2.0:v2:schema:protocol:cd-01"));
  zx_add_content(cf->ctx, &hdr->Action->gg, zx_dup_str(cf->ctx, "urn:oasis:xacml:2.0:saml:protocol:schema:os"));

  //zx_add_content(cf->ctx, &hdr->Action->gg, zx_dup_str(cf->ctx, "SAML2XACMLAuthzRequest"));
  //zx_add_content(cf->ctx, &hdr->Action->gg, zx_dup_str(cf->ctx, "http://ws.apache.org/axis2/TestPolicyPortType/authRequestRequest"));
  hdr->Action->mustUnderstand = zx_ref_str(cf->ctx, XML_TRUE);
  hdr->Action->actor = zx_ref_str(cf->ctx, SOAP_ACTOR_NEXT);
#endif

  /* Add our own token so PDP can do whatever PEP can (they are considered to be
   * part of the same entity). This is TAS3 specific hack. */

  if (!(cf->az_opt & 0x01)) {
    sec = hdr->Security = zx_NEW_wsse_Security(cf->ctx, &hdr->gg);
    sec->actor = zx_ref_attr(cf->ctx, &sec->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
    sec->mustUnderstand = zx_ref_attr(cf->ctx, &sec->gg, zx_e_mustUnderstand_ATTR, XML_TRUE);
    sec->Timestamp = zx_NEW_wsu_Timestamp(cf->ctx, &sec->gg);
    sec->Timestamp->Created = zx_NEW_wsu_Created(cf->ctx, &sec->Timestamp->gg);
    zx_add_content(cf->ctx, &sec->Timestamp->Created->gg, zxid_date_time(cf, time(0)));
    sec->Assertion = ses->tgta7n;
    zx_reverse_elem_lists(&sec->gg);
    D("tgta7n=%p", ses->tgta7n);
  }
  /* Prepare request according to the version */

  body = zx_NEW_e_Body(cf->ctx,0);
  if (!strcmp(cf->xasp_vers, "xac-soap")) {
    ZX_ADD_KID(body, xac_Request, zxid_mk_xac_az(cf, &body->gg, subj, rsrc, act, envi));
#if 0
    /* *** xac:Response does not have signature field */
    if (cf->sso_soap_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = body->xac_Request->ID;
      refs.canon = zx_EASY_ENC_SO_xac_Request(cf->ctx, body->xac_Request);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert az xac-soap")) {
	body->xac_Request->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid(&body->xac_Request->gg, &body->xac_Request->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
#endif
  } else if (!strcmp(cf->xasp_vers, "2.0-cd1")) {
    ZX_ADD_KID(body, xaspcd1_XACMLAuthzDecisionQuery, zxid_mk_az_cd1(cf, subj, rsrc, act, envi));
    if (cf->sso_soap_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = &body->xaspcd1_XACMLAuthzDecisionQuery->ID->g;
      refs.canon = zx_easy_enc_elem_sig(cf, &body->xaspcd1_XACMLAuthzDecisionQuery->gg);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert az cd1")) {
	body->xaspcd1_XACMLAuthzDecisionQuery->Signature
	  = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&body->xaspcd1_XACMLAuthzDecisionQuery->gg, &body->xaspcd1_XACMLAuthzDecisionQuery->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
  } else {
    ZX_ADD_KID(body, XACMLAuthzDecisionQuery, zxid_mk_az(cf, subj, rsrc, act, envi));
    if (cf->sso_soap_sign) {
      ZERO(&refs, sizeof(refs));
      refs.id = &body->XACMLAuthzDecisionQuery->ID->g;
      refs.canon = zx_easy_enc_elem_sig(cf, &body->XACMLAuthzDecisionQuery->gg);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert az")) {
	body->XACMLAuthzDecisionQuery->Signature
	  = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&body->XACMLAuthzDecisionQuery->gg, &body->XACMLAuthzDecisionQuery->Signature->gg);
      }
      zx_str_free(cf->ctx, refs.canon);
    }
  }

  /* Perform the network I/O for the call (connect to PDP) */

#if 0
  //ss = zx_ref_str(cf->ctx, "https://idpdemo.tas3.eu:8443/zxididp?o=S");
  // http://192.168.136.42:1104/axis2/services/TestPolicy.PERMISAuthzServerHttpSoap12Endpoint/
  // http://192.168.1.27:1104/axis2/services/TestPolicy?wsdl
  // http://192.168.1.66:1104/axis2/services/TestPolicy.PERMISAuthzServerHttpEndpoint/
  ss = zx_ref_str(cf->ctx, "http://192.168.1.27:1104/axis2/services/TestPolicy.PERMISAuthzServerHttpEndpoint/");
  //ss = zx_ref_str(cf->ctx, "");
  //ss = zx_ref_str(cf->ctx, "http://192.168.1.66:1104/axis2/services/TestPolicy.PERMISAuthzServerHttpEndpoint/");
  //ss = zx_ref_str(cf->ctx, "http://192.168.1.27:1104/axis2/services/TestPolicy.PERMISAuthzServerHttpSoap12Endpoint/");
#else
  ss = zx_ref_str(cf->ctx, pdp_url);
#endif
  r = zxid_soap_call_hdr_body(cf, ss, hdr, body);
  //r = zxid_idp_soap(cf, cgi, ses, idp_meta, ZXID_MNI_SVC, body);
  if (!r || !r->Envelope || !r->Envelope->Body || !r->Envelope->Body->Response) {
    ERR("Missing Response or other essential element %p %p %p %p", r, r?r->Envelope:0, r && r->Envelope?r->Envelope->Body:0, r && r->Envelope && r->Envelope->Body ? r->Envelope->Body->Response:0);
    return 0;
  }

  resp = r->Envelope->Body->Response;

  /* Parse response from the PDP. */

  if (!zxid_saml_ok(cf, cgi, resp->Status, "AzResp")) {
    ERR("Response->Status no OK (%p)", resp->Status);
    return 0;
  }
  if (!resp->Assertion) {
    ERR("No Assertion in the Response (%p)", resp);
    return 0;
  }
  
  return resp;
}

/*(i) Call Policy Decision Point (PDP) to obtain an authorization decision
 * about a contemplated action on a resource. The attributes from the session
 * pool, as filtered by PEPMAP are fed to the PDP as inputs
 * for the decision. The call is using XACML SAML profile over SOAP.
 *
 * cf:: the configuration will need to have ~PEPMAP~
 *     set according to your situation.
 * cgi:: if non-null, will receive error and status codes
 * ses:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO.
 * pdp_url:: URL of the PDP to contact
 * pepmap:: The map used to extract the attributes from the pool to the XACML request
 * returns:: 0 on error or deny (for any reason, e.g. indeterminate); in case of
 *     permit returns <xac:Response> as string, allowing the obligations to be extracted.
 *
 * For simpler API, see zxid_az() family of functions.
 */

/* Called by:  zxid_pep_az_soap, zxid_query_ctlpt_pdp, zxid_simple_ab_pep, zxid_simple_ses_active_cf */
char* zxid_pep_az_soap_pepmap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url, struct zxid_map* pepmap, const char* lk)
{
  struct zx_xac_Attribute_s* subj = 0;
  struct zx_xac_Attribute_s* rsrc = 0;
  struct zx_xac_Attribute_s* act = 0;
  struct zx_xac_Attribute_s* env = 0;
  struct zx_str* ss;
  struct zx_sp_Response_s* resp;
  struct zx_sa_Statement_s* stmt;
  struct zx_xasa_XACMLAuthzDecisionStatement_s* az_stmt;
  struct zx_xasacd1_XACMLAuthzDecisionStatement_s* az_stmt_cd1;
  struct zx_elem_s* decision = 0;
  char* p;

  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ses?ZX_GET_CONTENT(ses->nameid):0, "N", "W", "AZSOAP", ses?ses->sid:0, " ");
  
  if (!pdp_url || !*pdp_url) {
    if (cf->az_fail_mode & (ZXID_AZ_FAIL_MODE1_MISSING_URL | ZXID_AZ_FAIL_MODE4_PERMIT_ALWAYS)) {
      ERR("%s: No PDP_URL or PDP_CALL_URL set. Permit due to AZ_FAIL_MODE=%d",lk,cf->az_fail_mode);
      goto fail_mode_permit;
    } else {
      ERR("%s: No PDP_URL or PDP_CALL_URL set. Deny. %p", lk, pdp_url);
      return 0;
    }
  }

  zxid_pepmap_extract(cf, cgi, ses, pepmap, &subj, &rsrc, &act, &env);
  resp = zxid_az_soap(cf, cgi, ses, pdp_url, subj, rsrc, act, env);
  if (!resp || !resp->Assertion) {
    if (cf->az_fail_mode & (ZXID_AZ_FAIL_MODE2_NET_FAIL | ZXID_AZ_FAIL_MODE4_PERMIT_ALWAYS)) {
      ERR("%s: Malformed or nonexistent authorization response from PDP(%s) (%p).\nWARNING: Permit due to AZ_FAIL_MODE=%d", lk, pdp_url, resp, cf->az_fail_mode);
      goto fail_mode_permit;
    } else {
      ERR("%s: DENY due to malformed authorization response from PDP. Either no response or response lacking assertion. %p", lk, resp);
      return 0;
    }
  }
  
  az_stmt = resp->Assertion->XACMLAuthzDecisionStatement;
  if (az_stmt && az_stmt->Response && az_stmt->Response->Result) {
    decision = az_stmt->Response->Result->Decision;
    if (ZX_CONTENT_EQ_CONST(decision, "Permit")) {
      ss = zx_easy_enc_elem_opt(cf, &az_stmt->Response->gg);
      if (!ss || !ss->len) goto nomem;
      p = ss->s;
      INFO("%s: PERMIT found in azstmt len=%d", lk, ss->len);
      ZX_FREE(cf->ctx, ss);
      return p;
    }
  }
  az_stmt_cd1 = resp->Assertion->xasacd1_XACMLAuthzDecisionStatement;
  if (az_stmt_cd1 && az_stmt_cd1->Response && az_stmt_cd1->Response->Result) {
    decision = az_stmt_cd1->Response->Result->Decision;
    if (ZX_CONTENT_EQ_CONST(decision, "Permit")) {
      ss = zx_easy_enc_elem_opt(cf, &az_stmt_cd1->Response->gg);
      if (!ss || !ss->len) goto nomem;
      p = ss->s;
      ZX_FREE(cf->ctx, ss);
      INFO("%s: PERMIT found in azstmt_cd1 len=%d", lk, ss->len);
      ZX_FREE(cf->ctx, ss);
      return p;
    }
  }
  stmt = resp->Assertion->Statement;
  if (stmt && stmt->Response && stmt->Response->Result) {  /* Response here is xac:Response */
    decision = stmt->Response->Result->Decision;
    if (ZX_CONTENT_EQ_CONST(decision, "Permit")) {
      ss = zx_easy_enc_elem_opt(cf, &stmt->Response->gg);
      if (!ss || !ss->len) goto nomem;
      p = ss->s;
      INFO("%s: PERMIT found in stmt len=%d", lk, ss->len);
      ZX_FREE(cf->ctx, ss);
      return p;
    }
  }
  /*if (resp->Assertion->AuthzDecisionStatement) {  }*/
  if (decision) {
    if (ZX_CONTENT_EQ_CONST(decision, "Deny")) {
      if (cf->az_fail_mode & ZXID_AZ_FAIL_MODE4_PERMIT_ALWAYS) {
	ERR("%s: DENY found in stmt.\nWARNING: Permit due to AZ_FAIL_MODE=%d",lk,cf->az_fail_mode);
	goto fail_mode_permit;
      } else {
	INFO("%s: DENY found in stmt", lk);
	return 0;
      }
    } else {
      if (cf->az_fail_mode & ZXID_AZ_FAIL_MODE4_PERMIT_ALWAYS) {
	ERR("%s: DENY due to Other(%.*s).\nWARNING: Permit due to AZ_FAIL_MODE=%d", lk, ZX_GET_CONTENT_LEN(decision), ZX_GET_CONTENT_S(decision), cf->az_fail_mode);
	goto fail_mode_permit;
      } else {
	INFO("%s: DENY due to Other(%.*s) (treated as Deny) found in stmt", lk, ZX_GET_CONTENT_LEN(decision), ZX_GET_CONTENT_S(decision));
	return 0;
      }
    }
  }
  if (cf->az_fail_mode & ZXID_AZ_FAIL_MODE4_PERMIT_ALWAYS) {
    ERR("%s: DENY due to error or no xac:Response from PPD.\nWARNING: Permit due to AZ_FAIL_MODE=%d", lk, cf->az_fail_mode);
    goto fail_mode_permit;
  } else {
    ERR("%s: DENY due to error or no xac:Response from PDP %p %p %p", lk,az_stmt,az_stmt_cd1,stmt);
    return 0;
  }
 nomem:
  ERR("%s: DENY due memory allocation error. %p", lk, ss);
  return 0;
 fail_mode_permit:
  return zx_dup_cstr(cf->ctx,"<xac:Response xmlns:xac=\"urn:oasis:names:tc:xacml:2.0:context:schema:os\"><xac:Result><xac:Decision>Permit</xac:Decision><xac:Status><xac:StatusCode Value=\"urn:oasis:names:tc:xacml:1.0:status:ok\"/></xac:Status></xac:Result></xac:Response>");
}

/*(i) Call Policy Decision Point (PDP) to obtain an authorization decision
 * about a contemplated action on a resource. The attributes from the session
 * pool, as filtered by PEPMAP are fed to the PDP as inputs
 * for the decision. The call is using XACML SAML profile over SOAP.
 *
 * This is similar to zxid_pep_az_soap_pepmap() with the difference that the <xac:Response>
 * element is returned even in the deny and indeterminate cases (null
 * is still returned if there was an error). Effectively this +base+
 * form does not make judgement about whether <xac:Response> means
 * permit, deny, or something else.
 *
 * You should use this function if the Deny message contains interesting
 * obligations (normally it does not).
 *
 * cf:: the configuration will need to have ~PEPMAP~ and ~PDP_URL~ options
 *     set according to your situation.
 * cgi:: if non-null, will receive error and status codes
 * ses:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO.
 * pdp_url:: URL of the PDP to contact
 * pepmap:: The map used to extract the attributes from the pool to the XACML request
 * returns:: 0 on error; in case of deny (or indeterminate, etc.) as well as
 *     permit returns <xac:Response> as string, allowing the obligations to be extracted.
 *
 * For simpler API, see zxid_az_base() family of functions.
 */

/* Called by:  zxid_pep_az_base_soap */
char* zxid_pep_az_base_soap_pepmap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url, struct zxid_map* pepmap)
{
  struct zx_xac_Attribute_s* subj = 0;
  struct zx_xac_Attribute_s* rsrc = 0;
  struct zx_xac_Attribute_s* act = 0;
  struct zx_xac_Attribute_s* env = 0;
  char* res;
  struct zx_str* ss;
  struct zx_sp_Response_s* resp;
  struct zx_sa_Statement_s* stmt;
  struct zx_xasa_XACMLAuthzDecisionStatement_s* az_stmt;
  struct zx_xasacd1_XACMLAuthzDecisionStatement_s* az_stmt_cd1;

  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ses?ZX_GET_CONTENT(ses->nameid):0, "N", "W", "AZSOAP", ses?ses->sid:0, " ");
  
  if (!pdp_url || !*pdp_url) {
    ERR("No PDP_URL or PDP_CALL_URL set. Deny. %p", pdp_url);
    return 0;
  }

  zxid_pepmap_extract(cf, cgi, ses, pepmap, &subj, &rsrc, &act, &env);
  resp = zxid_az_soap(cf, cgi, ses, pdp_url, subj, rsrc, act, env);
  if (!resp || !resp->Assertion) {
    ERR("DENY due to malformed authorization response from PDP. Either no response or response lacking assertion. %p", resp);
    return 0;
  }

  az_stmt = resp->Assertion->XACMLAuthzDecisionStatement;
  if (az_stmt && az_stmt->Response) {
    ss = zx_easy_enc_elem_opt(cf, &az_stmt->Response->gg);
    if (!ss || !ss->len)
      return 0;
    res = ss->s;
    ZX_FREE(cf->ctx, ss);
    D("azstmt(%s)", res);
    return res;
  }
  az_stmt_cd1 = resp->Assertion->xasacd1_XACMLAuthzDecisionStatement;
  if (az_stmt_cd1 && az_stmt_cd1->Response) {
    ss = zx_easy_enc_elem_opt(cf, &az_stmt_cd1->Response->gg);
    if (!ss || !ss->len)
      return 0;
    res = ss->s;
    ZX_FREE(cf->ctx, ss);
    D("cd1(%s)", res);
    return res;
  }
  stmt = resp->Assertion->Statement;
  if (stmt && stmt->Response) {  /* Response here is xac:Response */
    ss = zx_easy_enc_elem_opt(cf, &stmt->Response->gg);
    if (!ss || !ss->len)
      return 0;
    res = ss->s;
    ZX_FREE(cf->ctx, ss);
    D("stmt(%s)", res);
    return res;
  }

  D("Missing az related Response element %d",0);
  return 0;
}

/*() Call Policy Decision Point (PDP) to obtain an authorization decision.
 * Uses default PEPMAP to call zxid_pep_az_soap_pepmap(). */

/* Called by:  zxid_az_cf_ses */
char* zxid_pep_az_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url) {
  return zxid_pep_az_soap_pepmap(cf, cgi, ses, pdp_url, cf->pepmap, "az_soap");
}

/* Called by:  zxid_az_base_cf_ses */
char* zxid_pep_az_base_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url) {
  return zxid_pep_az_base_soap_pepmap(cf, cgi, ses, pdp_url, cf->pepmap);
}

/*int zxid_az_cf_cgi_ses(zxid_conf* cf,  zxid_cgi* cgi, zxid_ses* ses);*/

/*(i) Call Policy Decision Point (PDP) to obtain an authorization decision
 * about a contemplated action on a resource. The attributes from the session
 * pool, as filtered by ~PEPMAP~ are fed to the PDP as inputs
 * for the decision. Session object is passed in as an argument.
 *
 * cf:: the configuration will need to have ~PEPMAP~ and ~PDP_URL~
 *     or ~PDP_CALL_URL~ options set according to your situation.
 * qs:: if non-null, will resceive error and status codes
 * ses:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO.
 *     The session object, e.g. from zxid_get_ses()
 * returns:: 0 on deny (for any reason, e.g. indeterminate),  or string
 *     containing the obligations on permit.
 *
 * For simpler API, see zxid_az() family of functions.
 */

/* Called by:  zxcall_main, zxid_az_cf */
char* zxid_az_cf_ses(zxid_conf* cf, const char* qs, zxid_ses* ses)
{
  zxid_cgi cgi;
  char* ret;
  char* url = (cf->pdp_call_url&&*cf->pdp_call_url) ? cf->pdp_call_url : cf->pdp_url;
  D_INDENT("az: ");
  ZERO(&cgi, sizeof(cgi));
  /*zxid_parse_cgi(cf, &cgi, "");  DD("qs(%s) ses=%p", STRNULLCHKD(qs), ses);*/
  if (qs && ses)
    zxid_add_qs2ses(cf, ses, zx_dup_cstr(cf->ctx, qs), 1);
  ret = zxid_pep_az_soap(cf, &cgi, ses, url);
  D_DEDENT("az: ");
  return ret;
}

/* Called by:  zxid_az_base_cf */
char* zxid_az_base_cf_ses(zxid_conf* cf, const char* qs, zxid_ses* ses)
{
  zxid_cgi cgi;
  char* ret;
  char* url = (cf->pdp_call_url&&*cf->pdp_call_url) ? cf->pdp_call_url : cf->pdp_url;
  D_INDENT("azb: ");
  ZERO(&cgi, sizeof(cgi));
  /*zxid_parse_cgi(cf, &cgi, "");  DD("qs(%s) ses=%p", STRNULLCHKD(qs), ses);*/
  if (qs && ses)
    zxid_add_qs2ses(cf, ses, zx_dup_cstr(cf->ctx, qs), 1);
  ret = zxid_pep_az_base_soap(cf, &cgi, ses, url);
  D_DEDENT("azb: ");
  return ret;
}

/*(i) Call Policy Decision Point (PDP) to obtain an authorization decision
 * about a contemplated action on a resource. The attributes from the session
 * pool, as filtered by ~PEPMAP~ are fed to the PDP as inputs
 * for the decision. Session is identified by a session id.
 *
 * cf:: the configuration will need to have ~PEPMAP~ and ~PDP_URL~ options
 *     set according to your situation.
 * qs:: if non-null, will resceive error and status codes
 * sid:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO. The
 *     session id, such as returned from SSO.
 * returns:: 0 on deny (for any reason, e.g. indeterminate),  or string
 *     containing the obligations on permit.
 *
 * For simpler API, see zxid_az() family of functions.
 */

/* Called by:  zxid_az */
char* zxid_az_cf(zxid_conf* cf, const char* qs, const char* sid)
{
  zxid_ses ses;
  ZERO(&ses, sizeof(ses));
  if (sid && sid[0]) {
    zxid_get_ses(cf, &ses, sid);
    zxid_ses_to_pool(cf, &ses);
  }
  return zxid_az_cf_ses(cf, qs, &ses);
}

/* Called by:  zxid_az_base */
char* zxid_az_base_cf(zxid_conf* cf, const char* qs, const char* sid)
{
  zxid_ses ses;
  ZERO(&ses, sizeof(ses));
  if (sid && sid[0]) {
    zxid_get_ses(cf, &ses, sid);
    zxid_ses_to_pool(cf, &ses);
  }
  return zxid_az_base_cf_ses(cf, qs, &ses);
}

/*() See zxid_az_cf() for description. Only difference is that the configuration
 * is accepted as a string instead of an object. */

/* Called by: */
char* zxid_az(const char* conf, const char* qs, const char* sid)
{
  struct zx_ctx ctx;
  zxid_conf cf;
  zx_reset_ctx(&ctx);
  ZERO(&cf, sizeof(cf));
  cf.ctx = &ctx;
  zxid_conf_to_cf_len(&cf, -1, conf);
  return zxid_az_cf(&cf, qs, sid);
}

/* Called by: */
char* zxid_az_base(const char* conf, const char* qs, const char* sid)
{
  struct zx_ctx ctx;
  zxid_conf cf;
  zx_reset_ctx(&ctx);
  ZERO(&cf, sizeof(cf));
  cf.ctx = &ctx;
  zxid_conf_to_cf_len(&cf, -1, conf);
  return zxid_az_base_cf(&cf, qs, sid);
}

/*() Call Trust Policy Decision Point (PDP) to obtain a trust evaluation and scoring
 *
 * You should use this function if the Deny message contains interesting
 * obligations (normally it does not).
 *
 * cf:: the configuration will need to have ~PEPMAP~ and ~PDP_URL~ options
 *     set according to your situation.
 * cgi:: if non-null, will receive error and status codes
 * ses:: all attributes are obtained from the session. You may wish
 *     to add additional attributes that are not known by SSO.
 * pepmap:: The map used to extract the attributes from the pool to the XACML request
 * start:: Start of query string format buffer of trust options
 * lim:: One past end of trust option buffer
 * returns:: 0 on error; in case of deny (or indeterminate, etc.) as well as
 *     permit returns <xac:Response> as string, allowing the obligations to be extracted.
 */

/* Called by:  zxid_di_query */
int zxid_call_trustpdp(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zxid_map* pepmap, const char* start, const char* lim, zxid_epr* epr)
{
  struct zx_xac_Attribute_s* xac_at;
  struct zx_xac_Attribute_s* subj = 0;
  struct zx_xac_Attribute_s* rsrc = 0;
  struct zx_xac_Attribute_s* act = 0;
  struct zx_xac_Attribute_s* env = 0;
  const char* val;
  const char* sep;
  struct zx_str* ss;
  struct zx_sp_Response_s* resp;
  struct zx_sp_StatusCode_s* sc;
  struct zx_sa_Statement_s* stmt;
  struct zx_xasa_XACMLAuthzDecisionStatement_s* az_stmt;
  struct zx_xasacd1_XACMLAuthzDecisionStatement_s* az_stmt_cd1;
  struct zx_elem_s* decision;
  struct zx_tas3_TrustRanking_s* tr;

  D("option(%.*s)", ((int)(lim-start)), start);

  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ses?ZX_GET_CONTENT(ses->nameid):0, "N", "W", "TRUSTPDP", ses?ses->sid:0, " ");
  
  if (!cf->trustpdp_url || !*cf->trustpdp_url) {
    ERR("No TRUSTPDP_URL. Deny. %p", cf->trustpdp_url);
    return 0;
  }

#if 1
  if (epr->Metadata && epr->Metadata->ProviderID) {
    ss = ZX_GET_CONTENT(epr->Metadata->ProviderID);
    D("Using ProviderID(%.*s) as resource-id", ss->len, ss->s);
    rsrc = zxid_mk_xacml_simple_at(cf, 0,
				     zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:resource:resource-id"),
				     zx_dup_str(cf->ctx, XS_STRING),
				     0, zx_dup_zx_str(cf->ctx, ss));
    ss = ZX_GET_CONTENT(epr->Metadata->ServiceType);
    xac_at = zxid_mk_xacml_simple_at(cf, 0,
				     zx_dup_str(cf->ctx, "urn:tas3:servicetype"),
				     zx_dup_str(cf->ctx, XS_STRING),
				     0, zx_dup_zx_str(cf->ctx, ss));
    ZX_NEXT(xac_at) = &rsrc->gg.g;
    rsrc = xac_at;
  } else {
    ERR("EPR does not have Metadata or Metadata/ProviderID. resource-id not set %p",epr->Metadata);
  }

  if (ses->nid && *ses->nid) {
#if 0
    /* Pass user as subject. This is TAS3 correct behaviour. */
    subj = zxid_mk_xacml_simple_at(cf, 0,
		zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:subject:subject-id"),
		zx_dup_str(cf->ctx, XS_STRING),
		0,
		zx_dup_str(cf->ctx, ses->nid));
#else
    /* *** Pass service to rank as subject. This is a kludge to work around Jerry's bug. */
    ss = ZX_GET_CONTENT(epr->Metadata->ProviderID);
    D("*** Using ProviderID(%.*s) as subject-id", ss->len, ss->s);
    subj = zxid_mk_xacml_simple_at(cf, 0,
		zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:subject:subject-id"),
		zx_dup_str(cf->ctx, XS_STRING),
		0, zx_dup_zx_str(cf->ctx, ss));
#endif
  } else {
    D("No ses->nid %p", ses->nid);
  }

  act = zxid_mk_xacml_simple_at(cf, 0,
	     zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:action:action-id"),
	     zx_dup_str(cf->ctx, XS_STRING),
	     0,
	     zx_dup_str(cf->ctx, "urn:oasis:names:tc:xacml:1.0:action:implied-action"));
#else
  zxid_pepmap_extract(cf, cgi, ses, pepmap, &subj, &rsrc, &act, &env);
#endif
  
  while (start < lim && (start = zx_memmem(start, (lim - start), TAS3_TRUST_INPUT_CTL1, sizeof(TAS3_TRUST_INPUT_CTL1)-1))) {

    val = memchr(start+sizeof(TAS3_TRUST_INPUT_CTL1)-1, '=', lim - (start+sizeof(TAS3_TRUST_INPUT_CTL1)-1));
    if (!val) {
      ERR("Malformed trust option(%.*s)", ((int)(lim-start)), start);
      break;
    }
    ++val;
    sep = memchr(val, '&', lim-val);
    if (!sep) {
      sep = lim;
    }
    
    D("add trust attr(%.*s) val(%.*s)", ((int)(val-1-start)), start, ((int)(sep-val)), val);
    xac_at = zxid_mk_xacml_simple_at(cf, 0,
				     zx_dup_len_str(cf->ctx, val-1-start, start),
				     zx_dup_str(cf->ctx, XS_STRING),
				     0, zx_dup_len_str(cf->ctx, sep-val, val));
    ZX_NEXT(xac_at) = &env->gg.g;
    env = xac_at;
    start = sep;
  }

  resp = zxid_az_soap(cf, cgi, ses, cf->trustpdp_url, subj, rsrc, act, env);
  if (!resp)
    return 0;

  az_stmt = resp->Assertion->XACMLAuthzDecisionStatement;
  if (az_stmt && az_stmt->Response) {
    decision = az_stmt->Response->Result->Decision;
  } else {
    az_stmt_cd1 = resp->Assertion->xasacd1_XACMLAuthzDecisionStatement;
    if (az_stmt_cd1 && az_stmt_cd1->Response) {
      decision = az_stmt_cd1->Response->Result->Decision;
    } else {
      stmt = resp->Assertion->Statement;
      if (stmt && stmt->Response) {  /* Response here is xac:Response */
	decision = stmt->Response->Result->Decision;
      } else {
	D("Missing az related Response element %d",0);
	return 0;
      }
    }
  }
  if (ZX_CONTENT_EQ_CONST(decision, "Permit")) {
    D("Permit %d",0);
    if (resp->Status && resp->Status->StatusCode && resp->Status->StatusCode->StatusCode) {
      /* Second and further layer status codes may contain Trust Rankings */
      for (sc = resp->Status->StatusCode->StatusCode; sc; sc = sc->StatusCode) {
	if (!sc->Value || !sc->Value->g.len < sizeof(TAS3_TRUST_RANKING_CTL1)-1 ||!sc->Value->g.s
	    || memcmp(sc->Value->g.s, TAS3_TRUST_RANKING_CTL1,sizeof(TAS3_TRUST_RANKING_CTL1)-1))
	  continue;
	val = memchr(sc->Value->g.s + sizeof(TAS3_TRUST_RANKING_CTL1)-1, '=', sc->Value->g.len - (sizeof(TAS3_TRUST_RANKING_CTL1)-1));
	if (!val) {
	  ERR("Malformed trust ranking(%.*s)", sc->Value->g.len, sc->Value->g.s);
	  continue;
	}
	
	if (!epr->Metadata)
	  epr->Metadata = zx_NEW_a_Metadata(cf->ctx, &epr->gg);
	if (!epr->Metadata->Trust)
	  epr->Metadata->Trust = zx_NEW_tas3_Trust(cf->ctx, &epr->Metadata->gg);
	tr = zx_NEW_tas3_TrustRanking(cf->ctx, &epr->Metadata->Trust->gg);
	tr->metric = zx_dup_len_attr(cf->ctx, &tr->gg, zx_metric_ATTR,
				     val - sc->Value->g.s, sc->Value->g.s);
	++val;
	tr->val = zx_dup_len_attr(cf->ctx, &tr->gg, zx_val_ATTR,
				  sc->Value->g.len - (val - sc->Value->g.s), val);
      }
    }
    
    INFO("PERMIT found in azstmt len=%d", ss->len);
    ZX_FREE(cf->ctx, ss);
    return 1;
  } else {
    D("Deny %d",0);
    return 0;
  }
}

/* EOF  --  zxidpep.c */
