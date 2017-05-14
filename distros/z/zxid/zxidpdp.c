/* zxidpdp.c  -  Handwritten functions for Local Policy Decision Point (PDP)
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
 * 18.7.2011,  improved debug prints --Sampo
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
#include "c/zx-e-data.h"

/* ------------ Attribute Broker and PEP ------------ */

/*() Local Policy Decision Point - decide on role and idpnid.
 * Return: 0 for Deny and 1 for Permit.  */

/* Called by:  zxid_query_ctlpt_pdp, zxid_simple_ab_pep */
int zxid_localpdp(zxid_conf* cf, zxid_ses* ses)
{
  struct zxid_attr* at = 0;

  if (cf->localpdp_role_permit || cf->localpdp_role_deny) {
    at = zxid_find_at(ses->at, "role");
    if (cf->localpdp_role_permit) {  /* whitelist of roles: not on list means deny */
      if (!at) {
	INFO("DENY due to no role attribute (whitelist) nid(%s)", STRNULLCHK(ses?ses->nid:0));
	return 0;
      }
      /* Permit if any of the attribute values matches any of the whitelisted roles. */
      if (!zxid_find_at_multival_on_cstr_list(cf->localpdp_role_permit, at)) {
	INFO("DENY: role(%s) not on whitelist nid(%s)", at->val, STRNULLCHK(ses?ses->nid:0));
	return 0;
      }
    }
    if (cf->localpdp_role_deny) {    /* blacklist of roles: on list means deny */
      /* Deny if any of the attribute values matches any of the blacklisted roles. */
      if (at && zxid_find_at_multival_on_cstr_list(cf->localpdp_role_deny, at)) {
	INFO("DENY: role(%s) or other multivalue on blacklist nid(%s)", at->val, STRNULLCHK(ses?ses->nid:0));
	return 0;
      }
    }
  }

  if (cf->localpdp_idpnid_permit || cf->localpdp_idpnid_deny) {
    at = zxid_find_at(ses->at, "idpnid");
    if (cf->localpdp_idpnid_permit) {  /* whitelist of idpnids: not on list means deny */
      if (!at) {
	INFO("DENY due to no idpnid attribute (whitelist) nid(%s)", STRNULLCHK(ses?ses->nid:0));
	return 0;
      }
      if (!zxid_find_cstr_list(cf->localpdp_idpnid_permit, at->val)) {
	INFO("DENY: idpnid(%s) not on whitelist nid(%s)", at->val, STRNULLCHK(ses?ses->nid:0));
	return 0;
      }
    }
    if (cf->localpdp_idpnid_deny) {    /* blacklist of idpnids: on list means deny */
      if (at && zxid_find_cstr_list(cf->localpdp_idpnid_deny, at->val)) {
	INFO("DENY: idpnid(%s) on blacklist nid(%s)", at->val, STRNULLCHK(ses?ses->nid:0));
	return 0;
      }
    }
  }

  INFO("PERMIT by local PDP val(%s) nid(%s)",STRNULLCHK(at?at->val:0),STRNULLCHK(ses?ses->nid:0));
  return 1;
}

/*(i) Postprocessing of SSO: Attribute Broker handles attributes and PEP/PDP
 * decide on authorization. */

/* Called by:  chkuid, zxid_mini_httpd_sso, zxid_show_protected_content_setcookie, zxid_simple_cf_ses, zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
char* zxid_simple_ab_pep(zxid_conf* cf, zxid_ses* ses, int* res_len, int auto_flags)
{
  char* res;
  struct zx_str* ss;
  D_INDENT("ab_pep: ");
  DD("ab_pep %d", 0);
  zxid_ses_to_pool(cf, ses);  /* Process SSO a7n, applying NEED, WANT, and INMAP */

  if (!zxid_localpdp(cf, ses)) {
    DD("Deny by local PDP %d",0);
    D_DEDENT("ab_pep: ");
    return "z";
  }

  if (cf->pdp_url && *cf->pdp_url) {
    //zxid_add_attr_to_ses(cf, ses, "Action", zx_dup_str(cf->ctx, "access"));
    //zxid_add_attr_to_ses(cf, ses, "URL", zx_dup_str(cf->ctx, ses->rs));
    if (!zxid_pep_az_soap_pepmap(cf, 0, ses, cf->pdp_url, cf->pepmap, "sso az")) {
      INFO("DENY by remote PDP %d", 0);
      D_DEDENT("ab_pep: ");
      return "z";
    }
  }
  
  switch (auto_flags & (ZXID_AUTO_FMTQ | ZXID_AUTO_FMTJ)) {
  case ZXID_AUTO_FMTQ|ZXID_AUTO_FMTJ: ss = zx_dup_str(cf->ctx, ""); break; /* No output */
  case ZXID_AUTO_FMTQ:  ss = zxid_ses_to_qs(cf, ses); break;
  case ZXID_AUTO_FMTJ:  ss = zxid_ses_to_json(cf, ses); break;
  default: ERR("Unsupported output format bits %x", auto_flags & (ZXID_AUTO_FMTQ|ZXID_AUTO_FMTJ));
  case 0:               ss = zxid_ses_to_ldif(cf, ses); break;
  }
  if (errmac_debug & ERRMAC_INOUT)
    INFO("LDIF(%.*s)", ss?ss->len:1, ss?ss->s:"-");
  if (cf->log_level > 0)
    zxlog(cf, 0,0,0,0,0,0, ZX_GET_CONTENT(ses->nameid), "N", "K", "SHOWPC", ses->sid, 0);
  res = ss->s;
  if (res_len)
    *res_len = ss->len;
  ZX_FREE(cf->ctx, ss);
  D_DEDENT("ab_pep: ");
  return res;
}

/* EOF  --  zxidpdp.c */
