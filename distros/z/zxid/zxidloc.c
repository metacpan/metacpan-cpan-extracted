/* zxidloc.c  -  Handwritten functions implementing service locator (based on metadata)
 * Copyright (c) 2006-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidloc.c,v 1.13 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 16.1.2007, split from zxidlib.c --Sampo
 * 7.10.2008, added documentation --Sampo
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "errmac.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-data.h"

/* err_res = "ERR-metadata-does-not-have-url-for-binding";*/

/* ============== IdP Service Locator ============= */

/* *** figure out a way to leverage commonality. */

/*() Raw computation of IdP URL given service type, binding, and whether operation is a
 * request. See zxid_idp_loc() for full description. */

/* Called by:  zxid_idp_loc x3, zxid_slo_resp_redir, zxid_sp_dispatch */
struct zx_str* zxid_idp_loc_raw(zxid_conf* cf, zxid_cgi* cgi,
				zxid_entity* idp_meta, int svc_type, char* binding, int req)
{
  struct zx_str* loc;
  struct zx_md_SingleLogoutService_s* slo_svc;
  struct zx_md_ManageNameIDService_s* mni_svc;
  
  if (!idp_meta || !idp_meta->eid || !idp_meta->ed->IDPSSODescriptor) {
    ERR("Entity(%s) does not have IdP SSO Descriptor (metadata problem)", idp_meta?STRNULLCHKQ(idp_meta->eid):"-");
    return 0;
  }

  switch (svc_type) {
  case ZXID_SLO_SVC:
    for (slo_svc = idp_meta->ed->IDPSSODescriptor->SingleLogoutService;
	 slo_svc;
	 slo_svc = (struct zx_md_SingleLogoutService_s*)slo_svc->gg.g.n) {
      if (slo_svc->gg.g.tok != zx_md_SingleLogoutService_ELEM)
	continue;
      if (slo_svc->Binding  && !memcmp(binding, slo_svc->Binding->g.s, slo_svc->Binding->g.len)
	  /*&& svc->index && !memcmp(end_pt_ix, svc->index->s, svc->index->len)*/
	  && slo_svc->Location)
	break;
    }
    if (!slo_svc)
      break;
    loc = req ? &slo_svc->Location->g : (slo_svc->ResponseLocation ? &slo_svc->ResponseLocation->g : &slo_svc->Location->g);
    if (!loc)
      break;
    return loc;
  case ZXID_MNI_SVC:
    for (mni_svc = idp_meta->ed->IDPSSODescriptor->ManageNameIDService;
	 mni_svc;
	 mni_svc = (struct zx_md_ManageNameIDService_s*)mni_svc->gg.g.n) {
      if (mni_svc->gg.g.tok != zx_md_ManageNameIDService_ELEM)
	continue;
      if (mni_svc->Binding  && !memcmp(binding, mni_svc->Binding->g.s, mni_svc->Binding->g.len)
	  /*&& svc->index && !memcmp(end_pt_ix, svc->index->s, svc->index->len)*/
	  && mni_svc->Location)
	break;
    }
    if (!mni_svc)
      break;
    loc = req ? &mni_svc->Location->g : (mni_svc->ResponseLocation ? &mni_svc->ResponseLocation->g : &mni_svc->Location->g);
    if (!loc)
      break;
    return loc;
  }

  ERR("IdP Entity(%s) does not have any %d service with binding(%s) (metadata problem)", idp_meta->eid, svc_type, binding);
  return 0;
}

/*() SAML2 service locator. Given desired service, like SLO or MNI, and possibly binding,
 * locate the appropriate service descriptor from the IdP metadata.
 *
 * cf:: ZXID configuration object, used for preferences and for memory allocation
 * cgi:: May contain CGI variables that further indicate preference. Often specified
 *     as 0 (no preference).
 * ses:: Session object, which may be used to remember historical events, such as
 *     binding of SSO transaction, that may act as preferences for binding. The
 *     session MUST have assertion.
 * idp_meta:: Metadata for the IdP
 * svc_type:: The desired service, indicated as URN
 * binding:: preferred binding URN, or 0 if no preference. In that case the built in
 *     preference is used, or if that is indifferent, then first applicable metadata
 *     item is picked. If IdP only supports one binding 0 will match that. If nonzero,
 *     then the IdP metadata MUST have exactly matching entry or else 0 is returned.
 * return:: URL for accessing the service or 0 upon failure
 *
 * *Limitation:* If binding is not specified, it may be ambiguous what binding the returned
 * URL relates to. Generally the decision will have been taken prior to calling
 * this function. */

/* Called by:  zxid_idp_soap, zxid_sp_mni_redir, zxid_sp_slo_redir */
struct zx_str* zxid_idp_loc(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses,
			    zxid_entity* idp_meta, int svc_type, char* binding)
{
  zxid_get_ses_sso_a7n(cf, ses);
  
  if (ses->a7n) {
    return zxid_idp_loc_raw(cf, cgi, idp_meta, svc_type, binding, 1);
  }
  if (ses->a7n11) {
    ERR("Not implemented: obtaining location from SAML 1.1 assetion %d", 0);
    //return zxid_idp_loc_raw(cf, cgi, ses->a7n->Issuer, svc_type, binding, 1);
  }
  if (ses->a7n12) {
    ERR("Not implemented: obtaining location from ID-FF 1.2 type SAML 1.1 assetion %d", 0);
    //return zxid_idp_loc_raw(cf, cgi, ses->a7n->Issuer, svc_type, binding, 1);
  }
  
  ERR("Session sid(%s) appears to lack SSO assertion.", ses->sid);
  return 0;
}

/*() Deternine URL for SOAP binding to given service and perform a SOAP call.
 *
 * cf:: ZXID configuration object
 * cgi:: CGI variables that may influence determination of end point. Or 0 if no preference.
 * ses:: Session information that may influence the choice of the end point. The
 *     session MUST have asserion.
 * idp_meta:: Metadata for the IdP
 * svc_type:: The desired service, indicated as URN
 * body:: XML data structure for the SOAP call <Body> element payload
 * return:: XML data structure for Body element of the SOAP call response. */

/* Called by:  zxid_az_soap, zxid_sp_mni_soap, zxid_sp_slo_soap */
struct zx_root_s* zxid_idp_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses,
				zxid_entity* idp_meta, int svc_type, struct zx_e_Body_s* body)
{
  struct zx_root_s* r;
  struct zx_str* loc = zxid_idp_loc(cf, cgi, ses, idp_meta, svc_type, SAML2_SOAP);
  if (!loc)
    return 0;
  r = zxid_soap_call_hdr_body(cf, loc, 0, body);
  zx_str_free(cf->ctx, loc);
  return r;
}

/* ============== SP Service Locator ============= */

/* *** figure out a way to leverage commonality. */

/* Called by:  zxid_idp_sso */
struct zx_str* zxid_sp_loc_by_index_raw(zxid_conf* cf, zxid_cgi* cgi,
					zxid_entity* sp_meta, int svc_type,
					struct zx_str* ix, int* binding)
{
  struct zx_str* loc;
  struct zx_md_AssertionConsumerService_s* acs_svc;
  
  if (!sp_meta || !sp_meta->eid || !sp_meta->ed->SPSSODescriptor) {
    ERR("Entity(%s) does not have SP SSO Descriptor (metadata problem)", sp_meta?STRNULLCHKQ(sp_meta->eid):"-");
    return 0;
  }

  switch (svc_type) {
  case ZXID_ACS_SVC:
    for (acs_svc = sp_meta->ed->SPSSODescriptor->AssertionConsumerService;
	 acs_svc;
	 acs_svc = (struct zx_md_AssertionConsumerService_s*)acs_svc->gg.g.n) {
      if (acs_svc->gg.g.tok != zx_md_AssertionConsumerService_ELEM)
	continue;
      if (acs_svc->index && ix->len == acs_svc->index->g.len
	  && !memcmp(ix->s, acs_svc->index->g.s, ix->len)
	  && acs_svc->Location)
	break;
    }
    if (!acs_svc)
      break;
    loc = &acs_svc->Location->g;
    if (!loc)
      break;
    *binding = zxid_protocol_binding_map_saml2(&acs_svc->Binding->g);
    return loc;
  }

  ERR("SP Entity(%s) does not have any %d service with index(%.*s) (metadata problem)", sp_meta->eid, svc_type, ix->len, ix->s);
  *binding = 0;
  return 0;
}


/*() Raw computation of SP URL given service type, binding, and whether operation is a
 * request. See zxid_sp_loc() for full description.
 *
 * return:: URL for the protocol end point, or 0 on failure */

/* Called by:  zxid_idp_dispatch, zxid_idp_sso x2, zxid_oauth2_az_server_sso, zxid_slo_resp_redir, zxid_sp_loc x3 */
struct zx_str* zxid_sp_loc_raw(zxid_conf* cf, zxid_cgi* cgi, zxid_entity* sp_meta, int svc_type, char* binding, int req)
{
  struct zx_str* loc;
  struct zx_md_SingleLogoutService_s* slo_svc;
  struct zx_md_ManageNameIDService_s* mni_svc;
  struct zx_md_AssertionConsumerService_s* acs_svc;
  
  if (!sp_meta || !sp_meta->eid || !sp_meta->ed->SPSSODescriptor) {
    ERR("Entity(%s) does not have SP SSO Descriptor (metadata problem)", sp_meta?STRNULLCHKQ(sp_meta->eid):"-");
    return 0;
  }
  
  switch (svc_type) {
  case ZXID_SLO_SVC:
    for (slo_svc = sp_meta->ed->SPSSODescriptor->SingleLogoutService;
	 slo_svc;
	 slo_svc = (struct zx_md_SingleLogoutService_s*)slo_svc->gg.g.n) {
      if (slo_svc->gg.g.tok != zx_md_SingleLogoutService_ELEM)
	continue;
      if (slo_svc->Binding  && !memcmp(binding, slo_svc->Binding->g.s, slo_svc->Binding->g.len)
	  /*&& svc->index && !memcmp(end_pt_ix, svc->index->s, svc->index->len)*/
	  && slo_svc->Location)
	break;
    }
    if (!slo_svc)
      break;
    loc = req ? &slo_svc->Location->g : (slo_svc->ResponseLocation ? &slo_svc->ResponseLocation->g : &slo_svc->Location->g);
    if (!loc)
      break;
    return loc;
  case ZXID_MNI_SVC:
    for (mni_svc = sp_meta->ed->SPSSODescriptor->ManageNameIDService;
	 mni_svc;
	 mni_svc = (struct zx_md_ManageNameIDService_s*)mni_svc->gg.g.n) {
      if (mni_svc->gg.g.tok != zx_md_ManageNameIDService_ELEM)
	continue;
      if (mni_svc->Binding  && !memcmp(binding, mni_svc->Binding->g.s, mni_svc->Binding->g.len)
	  /*&& svc->index && !memcmp(end_pt_ix, svc->index->s, svc->index->len)*/
	  && mni_svc->Location)
	break;
    }
    if (!mni_svc)
      break;
    loc = req ? &mni_svc->Location->g : (mni_svc->ResponseLocation ? &mni_svc->ResponseLocation->g : &mni_svc->Location->g);
    if (!loc)
      break;
    return loc;
  case ZXID_ACS_SVC:
    for (acs_svc = sp_meta->ed->SPSSODescriptor->AssertionConsumerService;
	 acs_svc;
	 acs_svc = (struct zx_md_AssertionConsumerService_s*)acs_svc->gg.g.n) {
      if (acs_svc->gg.g.tok != zx_md_AssertionConsumerService_ELEM)
	continue;
      if (acs_svc->Binding  && !memcmp(binding, acs_svc->Binding->g.s, acs_svc->Binding->g.len)
	  /*&& svc->index && !memcmp(end_pt_ix, svc->index->s, svc->index->len)*/
	  && acs_svc->Location)
	break;
    }
    if (!acs_svc)
      break;
    loc = &acs_svc->Location->g;
    if (!loc)
      break;
    return loc;
  }

  ERR("SP Entity(%s) does not have any %d service with binding(%s) (metadata problem)", sp_meta->eid, svc_type, binding);
  return 0;
}

/*() SAML2 service locator for SP. Given desired service, like SLO or MNI, and possibly binding,
 * locate the appropriate service descriptor from the Sp metadata.
 *
 * cf:: ZXID configuration object, used for preferences and for memory allocation
 * cgi:: May contain CGI variables that further indicate preference. Often specified
 *     as 0 (no preference).
 * ses:: Session object, which may be used to remember historical events, such as
 *     binding of SSO transaction, that may act as preferences for binding. The
 *     session MUST have assertion.
 * sp_meta:: Metadata for the Sp
 * svc_type:: The desired service, indicated as URN
 * binding:: preferred binding URN, or 0 if no preference. In that case the built in
 *     preference is used, or if that is indifferent, then first applicable metadata
 *     item is picked. If Sp only supports one binding 0 will match that. If nonzero,
 *     then the Sp metadata MUST have exactly matching entry or else 0 is returned.
 * return:: URL for accessing the service or 0 upon failure
 *
 * *Limitation:* If binding is not specified, it may be ambiguous what binding the returned
 * URL relates to. Generally the decision will have been taken prior to calling
 * this function. */

/* Called by:  zxid_sp_soap */
struct zx_str* zxid_sp_loc(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_entity* sp_meta, int svc_type, char* binding)
{
  zxid_get_ses_sso_a7n(cf, ses);
  
  if (ses->a7n) {
    return zxid_sp_loc_raw(cf, cgi, sp_meta, svc_type, binding, 1);
  }
  if (ses->a7n11) {
    ERR("Not implemented: obtaining location from SAML 1.1 assetion %d", 0);
    //return zxid_sp_loc_raw(cf, cgi, ses->a7n->Issuer, svc_type, binding, 1);
  }
  if (ses->a7n12) {
    ERR("Not implemented: obtaining location from ID-FF 1.2 type SAML 1.1 assetion %d", 0);
    //return zxid_sp_loc_raw(cf, cgi, ses->a7n->Issuer, svc_type, binding, 1);
  }
  
  ERR("Session sid(%s) appears to lack SSO assertion.", ses->sid);
  return 0;
}

/*() Deternine URL for SOAP binding to given service on SP and perform a SOAP call.
 *
 * cf:: ZXID configuration object
 * cgi:: CGI variables that may influence determination of end point. Or 0 if no preference.
 * ses:: Session information that may influence the choice of the end point. The
 *     session MUST have asserion.
 * sp_meta:: Metadata for the Sp
 * svc_type:: The desired service, indicated as URN
 * body:: XML data structure for the SOAP call <Body> element payload
 * return:: XML data structure for Body element of the SOAP call response. */

/* Called by: */
struct zx_root_s* zxid_sp_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_entity* sp_meta, int svc_type, struct zx_e_Body_s* body)
{
  struct zx_root_s* r;
  struct zx_str* loc = zxid_sp_loc(cf, cgi, ses, sp_meta, svc_type, SAML2_SOAP);
  if (!loc)
    return 0;
  r = zxid_soap_call_hdr_body(cf, loc, 0, body);
  zx_str_free(cf->ctx, loc);
  return r;
}

/* EOF  --  zxidloc.c */
