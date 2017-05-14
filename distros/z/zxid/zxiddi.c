/* zxiddi.c  -  Discovery Server
 * Copyright (c) 2013 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxiddi.c,v 1.2 2009-11-24 23:53:40 sampo Exp $
 *
 * 15.11.2009, created --Sampo
 * 10.1.2011,  added TrustPDP and CPN support --Sampo
 * 7.12.2013,  added EPR ranking --Sampo
 *
 * See also zxidepr.c for discovery client code.
 *
 *   zxcot -e http://idp.tas3.pt:8081/zxididp?o=S 'Discovery Svc' \
 *     http://idp.tas3.pt:8081/zxididp?o=B urn:liberty:disco:2006-08 \
 *   | zxcot -bs /var/zxid/idpdimd
 */

#include "platform.h"  /* for dirent.h */
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "tas3.h"
#include "wsf.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*() Recover end user's identity: uid at IdP. This is actually done via "self federation"
 * that was created when token for accessing discovery was issued.
 * Returns 1 on success, 0 on failure. */

/* Called by:  zxid_di_query, zxid_imreq, zxid_ps_addent_invite, zxid_ps_resolv_id, zxid_ssos_anreq */
int zxid_idp_map_nid2uid(zxid_conf* cf, int len, char* uid, zxid_nid* nameid, struct zx_lu_Status_s** stp)
{
  struct zx_str* affil;
  char sp_name_buf[1024];
  if (!nameid) {
    ERR("Missing nameid %d",0);
    return 0;
  }

  affil = nameid->SPNameQualifier ? &nameid->SPNameQualifier->g : zxid_my_ent_id(cf);
  zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), affil, affil, 7);
  len = read_all(len-1, uid, "idp_map_nid2uid", 1, "%s" ZXID_NID_DIR "%s/%.*s", cf->cpath, sp_name_buf, ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
  if (!len) {
    ERR("Can not find reverse mapping for SP,SHA1(%s) nid(%.*s)", sp_name_buf, ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
    if (stp)
      *stp = zxid_mk_lu_Status(cf, 0, "Fail", 0, 0, 0);
    return 0;
  }
  return 1;
}

/*(-) Return 1 if any requested servicetype prefix matches filename, i.e. EPR file
 * is a viable candidate. Return 0 if no match. */

static int zxid_di_match_prefix(int nth, struct zx_di_RequestedService_s* rs, struct dirent* de)
{
  struct zx_elem_s* el;
  struct zx_str* ss;
  int len;
  char prefix[ZXID_MAX_BUF];

  if (!rs->ServiceType)
    return 1;  /* No svctype specified in query: all match */
  for (el = rs->ServiceType; el; el = (struct zx_elem_s*)el->g.n) {
    if (el->g.tok != zx_di_ServiceType_ELEM)
      continue;
    ss = ZX_GET_CONTENT(el);
    if (!ss || !ss->len)
      continue;
    len = MIN(ss->len, sizeof(prefix)-1);
    memcpy(prefix, ss->s, len);
    prefix[len] = 0;
    zxid_fold_svc(prefix, len);
    if (memcmp(de->d_name, prefix, len) || de->d_name[len] != ',') {
      D("%d:     no match prefix(%s) file(%s)", nth, prefix, de->d_name);
    } else {
      D("%d:     candidate due to prefix(%s) file(%s)", nth, prefix, de->d_name);
      return 1;
    }
  }
  return 0;
}

/*(-) Return 1 if any requested svctype matches svctype parsed from file. Return 0 if no match. */

static int zxid_di_match_svctype(int nth, struct zx_di_RequestedService_s* rs, struct zx_str* svctyp, struct dirent* de)
{
  struct zx_elem_s* el;
  struct zx_str* ss;

  if (!svctyp || !svctyp->len) {
    INFO("EPR missing ServiceType. Rejected file(%s).", de->d_name);
    return 0;
  }
  if (!rs->ServiceType)
    return 1;  /* No svctype specified in query: all match */
  for (el = rs->ServiceType; el; el = (struct zx_elem_s*)el->g.n) {
    if (el->g.tok != zx_di_ServiceType_ELEM)
      continue;
    ss = ZX_GET_CONTENT(el);
    if (!ss || !ss->len)
      continue;
    if (ss->len != svctyp->len || memcmp(ss->s, svctyp->s, ss->len)) {
      D("%d: Requested svctype(%.*s) does not match file prefix(%.*s)", nth, ss->len, ss->s, svctyp->len, svctyp->s);
      continue;
    }
    D("%d: ServiceType matches. file(%s)", nth, de->d_name);
    return 1;
  }
  D("%d: Rejected due to ServiceType. file(%s)", nth, de->d_name);
  return 0;
}

/*(-) Return 1 if any requested svctype matches svctype parsed from file. Return 0 if no match. */

static int zxid_di_match_entid(int nth, struct zx_di_RequestedService_s* rs, struct zx_str* prvid, struct zx_str* addr, struct dirent* de)
{
  struct zx_elem_s* el;
  struct zx_str* ss;
  
  if (!prvid || !prvid->len) {
    INFO("EPR missing ProviderID. Rejected file(%s).", de->d_name);
    return 0;
  }
  if (!rs->ProviderID)
    return 1;  /* No ProviderID specified in query: all match */
  for (el = rs->ProviderID; el; el = (struct zx_elem_s*)el->g.n) {
    if (el->g.tok != zx_di_ProviderID_ELEM)
      continue;
    ss = ZX_GET_CONTENT(el);
    if (!ss || !ss->len)
      continue;
    if (ss->len != prvid->len || memcmp(ss->s, prvid->s, ss->len)) {
      D("%d: ProviderID(%.*s) does not match desired(%.*s)", nth, prvid->len, prvid->s, ss->len, ss->s);
      continue;
    }
    D("%d: ProviderID matches. file(%s)", nth, de->d_name);
    return 1;
  }

  /* TAS3 extension: allow matching ProviderID by the Address (URL) as well */
  for (el = rs->ProviderID; el; el = (struct zx_elem_s*)el->g.n) {
    if (el->g.tok != zx_di_ProviderID_ELEM)
      continue;
    ss = ZX_GET_CONTENT(el);
    if (!ss || !ss->len)
      continue;
    if (ss->len != addr->len || memcmp(ss->s, addr->s, ss->len)) {
      D("%d: Address(%.*s) does not match desired(%.*s)", nth, addr->len, addr->s, ss->len, ss->s);
      continue;
    }
    D("%d: Address matches. file(%s)", nth, de->d_name);
    return 1;
  }
  return 0;
}

/*(-) Return 1 if Discovery Options match. Return 0 if no match. */

static int zxid_di_match_options(zxid_conf* cf, zxid_ses* ses, int nth, struct zx_di_RequestedService_s* rs, zxid_epr* epr, struct dirent* de)
{
  struct zx_elem_s* el;
  struct zx_str* ss;
  char* p;
  char* start;
  char* lim;
  
  if (!rs->Options)
    return 1;  /* none specified, automatic match */
  for (el = rs->Options->Option; el; el = (struct zx_elem_s*)el->g.n) {
    if (el->g.tok != zx_di_Option_ELEM)
      continue;
    ss = ZX_GET_CONTENT(el);
    if (!ss || !ss->len) {
      D("Option element does not have content %p", ss);
      continue;
    }
    p = zx_memmem(ss->s, ss->len, TAS3_TRUST_INPUT_CTL1, sizeof(TAS3_TRUST_INPUT_CTL1)-1);
    if (!p) {
      D("Option(%.*s) is not trust related", ss->len, ss->s);
      /* *** what about all other types of options?!? */
      continue;
    }
    start = p;
    lim = memchr(p+sizeof(TAS3_TRUST_INPUT_CTL1)-1, '&', ss->len - (p - ss->s));
    if (!lim) {
      lim = ss->s + ss->len;
    } else {
      while (p = zx_memmem(lim, ss->len - (lim - ss->s), TAS3_TRUST_INPUT_CTL1, sizeof(TAS3_TRUST_INPUT_CTL1)-1)) {
	lim = memchr(p+sizeof(TAS3_TRUST_INPUT_CTL1)-1, '&', ss->len - (p - ss->s));
	if (!lim) {
	  lim = ss->s + ss->len;
	  break;
	}
      }
    }
    
    if (cf->trustpdp_url && *cf->trustpdp_url) {
      D("Trust related discovery options(%.*s), TRUSTPDP_URL(%s)", ((int)(lim-start)), start, cf->trustpdp_url);
      if (zxid_call_trustpdp(cf, 0, ses, cf->pepmap_rsin, start, lim, epr)) {
	D("%d: Trust PERMIT. file(%s)", nth, de->d_name);
	/* *** return trust scorings as part of the EPR */
	continue;
      } else {
	D("%d: Rejected due to Trust DENY. file(%s)", nth, de->d_name);
	return 0;
      }
    } else {
      INFO("Trust related discovery options(%.*s), but no TRUSTPDP_URL configured", ((int)(lim-start)), start);
      continue;
    }
  }
  return 1;
}

/*(-) Return 1 if credentials and Privacy Negotation matches. Return 0 if no match.
 * This is a TAS3 extension. */

static int zxid_di_match_cpn(zxid_conf* cf, zxid_ses* ses, int nth, struct zx_str* svctyp, struct zx_str* prvid, struct dirent* de)
{
  struct zx_str* ss;
  if (!cf->cpn_ena)
    return 1;
#if 0
  /* Call Trust and Privacy Negotiation (TrustBuilder), Andreas. */
  systemf("./tpn-client.sh %s %s %s", idpnid, "urn:idhrxml:cv:update", host);
#else
  if (svctyp && svctyp->len && prvid && prvid->len) {
    ss = zxid_callf(cf, ses, "urn:tas3:cpn-agent",0,0,0,
		 "<tas3cpn:CPNRequest xmlns:tas3cpn=\"urn:tas3:cpn-agent\">"
		   "<di:RequestedService xmlns:di=\"urn:liberty:disco:2006-08\">"
		     "<di:ServiceType>%.*s</di:ServiceType>"
		     "<di:ProviderID>%.*s</di:ProviderID>"
		     "<di:Framework version=\"2.0\"/>"
		     /*"<di:Action>urn:x-foobar:Create</di:Action>"*/
		   "</di:RequestedService>"
		 "</tas3cpn:CPNRequest>",
			  svctyp->len, svctyp->s,
			  prvid->len, prvid->s);
    if (!ss || !ss->s) {
      D("CPN returned nothing or emptiness (no CPN agent discoverable?) %p", ss);
    } else {
      D("CPN returned(%.*s)", ss->len, ss->s);	  
    }
  }
#endif
  return 1;
}

/*() Add rankKey field based on filename, if no rank key was specified
 * in the EPR XML parsed from the file.
 * Typically a service is represented by cached EPR file in session directory
 * or in /var/zxid/dimd/ directory in the IdP case. This file name
 * will have comma separated structure:
 *
 *   FOLDEDSVCTYP,RANKKEY,NICE_SHA1_OF_CONTENTS
 *
 * The goals of this arrangement are that discovery results would be predictable
 * in ordering so that index numbers can be used to select one of the many
 * discovered EPRS, and that the normally (LANG=C) sorted ls(1) listing matches
 * discovery order.
 *
 * This function extracts everything after the first comma as rankKey.  */

void zxid_di_set_rankKey_if_needed(zxid_conf* cf, struct zx_a_Metadata_s* md, int nth, struct dirent* de)
{
  char buf[48];
  char* p;
  if (!md) {
    ERR("%d: EPR lacks Metadata element", nth);
    return;
  }
  if (md->rankKey)
    return;  /* Already set in the XML parsed from file */
  
  p = strchr(de->d_name, ',');
  if (!p) {
    snprintf(buf, sizeof(buf), "Z%04d", nth);
    buf[sizeof(buf)-1] = 0;
    p = buf;
  }
  md->rankKey = zx_dup_attr(cf->ctx, &md->gg, zx_rankKey_ATTR, p);  /* strdup as de buf is temp */
}

/*(-) We do not want to leak IdP internal ranking infor so clean these out. This
 * also means better standards compliant output. The WSC can always recreate
 * its own rankKey from the order in which the EPRs were received.
 *
 * See:: zxid_snarf_eprs() and zxid_get_epr() */

static void zxid_di_sanitize_rankKey_out(zxid_epr* epr) {
  for (; epr; epr = (zxid_epr*)epr->gg.g.n)
    if (epr->Metadata)
      epr->Metadata->rankKey = 0;  /* *** should we also free them? */
}

/*(-) Compare two EPRs by rankKey (string comparison) to help sorting discovery results.
 * Return -1 if a<b; 0 if a==b; 1 if a>b. */

static int zxid_id_epr_cmp(zxid_epr* a, zxid_epr* b) {
  if (!a || !a->Metadata || !a->Metadata->rankKey)
    return 1;  /* missing parts: sort to end of list */
  if (!b || !b->Metadata || !b->Metadata->rankKey)
    return -1;
  return zx_str_cmp(&a->Metadata->rankKey->g, &b->Metadata->rankKey->g);
}

/*() Sort discovery results (epr list) according to rankKey. */

zxid_epr* zxid_di_sort_eprs(zxid_conf* cf, zxid_epr* epr)
{
  zxid_epr* out;
  zxid_epr* ep;
  zxid_epr* nxt;
  zxid_epr* prv;
  
  if (!epr)
    return 0;
  
  /* The number of EPRs is expected to be from one to several tens, but not hundreds.
   * Thus a simple list insertion sort should be good enough, even optimal. */

  out = epr;
  epr = (zxid_epr*)epr->gg.g.n;
  out->gg.g.n = 0;

  for (; epr; epr = nxt) {
    nxt = (zxid_epr*)epr->gg.g.n;
    /* scan already sorted list out for right place for new insertion */
    if (zxid_id_epr_cmp(out, epr) >= 0) {
      out = epr;
      epr = (zxid_epr*)epr->gg.g.n;
      out->gg.g.n = 0;
      continue;
    }
    for (prv = out, ep = (zxid_epr*)out->gg.g.n;
	 ep && zxid_id_epr_cmp(ep, epr) < 0;
	 prv = ep, ep = (zxid_epr*)ep->gg.g.n);
    epr->gg.g.n = prv->gg.g.n;
    prv->gg.g.n = &epr->gg.g;
  }
  return out;
}

/*() Server side Discovery Service Query processing.
 * See also:: zxid_gen_bootstraps(), zxid_find_epr() */

/* Called by:  zxid_sp_soap_dispatch */
struct zx_di_QueryResponse_s* zxid_di_query(zxid_conf* cf, zxid_ses* ses,struct zx_di_Query_s* req)
{
  struct zx_di_RequestedService_s* rs;
  struct zx_di_QueryResponse_s* resp = zx_NEW_di_QueryResponse(cf->ctx,0);
  struct zx_root_s* r;
  int epr_len, n_discovered = 0;
  char logop[8];
  char uid[ZXID_MAX_USER];
  char mdpath[ZXID_MAX_BUF];
  char* epr_buf;
  DIR* dir;
  struct dirent* de;
  struct zx_a_Metadata_s* md = 0;  
  struct zx_str* ss;
  struct zx_str* svctyp;
  struct zx_str* prvid;
  struct zx_str* addr = 0;  
  zxid_epr* epr = 0;
  strcpy(logop, "xxxDIyy");
  D_INDENT("di_query: ");
  ses->uid = uid;
  
  if (!zxid_idp_map_nid2uid(cf, sizeof(uid), uid, ses->tgtnameid, &resp->Status)) {
    D_DEDENT("di_query: ");
    return resp;
  }
  name_from_path(mdpath, sizeof(mdpath), "%sdimd", cf->cpath);

  /* Work through all requests */

  for (rs = req->RequestedService; rs; rs = (struct zx_di_RequestedService_s*)ZX_NEXT(rs)) {
    if (rs->gg.g.tok != zx_di_RequestedService_ELEM)
      continue;

    /* Look for all entities providing service */

    D("%d: Looking for service metadata in dir(%s)", n_discovered, mdpath);
    dir = opendir(mdpath);
    if (!dir) {
      perror("opendir to find service metadata");
      ERR("Opening service metadata directory failed path(%s)", mdpath);
      resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
      D_DEDENT("di_query: ");
      return resp;
    }
    
    /* Work through all available providers, filtering out insuitable ones. */
    
    while (de = readdir(dir)) {
      D("%d: Considering file(%s)", n_discovered, de->d_name);

      if (de->d_name[strlen(de->d_name)-1] == '~')  /* Ignore backups from hand edited EPRs. */
	continue;
      
      /* Filter file name by service type... */
      if (!zxid_di_match_prefix(n_discovered, rs, de))
	continue;
      
      /* ...Probable enough, read and parse EPR so we can continue examination. */
      epr_buf = read_all_alloc(cf->ctx, "find_svcmd", 1, &epr_len, "%s/%s", mdpath, de->d_name);
      if (!epr_buf)
	continue;
      
      r = zx_dec_zx_root(cf->ctx, epr_len, epr_buf, "diq epr");
      if (!r) {
	ERR("Failed to XML parse epr_buf(%.*s) file(%s)", epr_len, epr_buf, de->d_name);
	ZX_FREE(cf->ctx, epr_buf);
	continue;
      }
      /* *** add ID-WSF 1.1 handling */
      epr = r->EndpointReference;
      ZX_FREE(cf->ctx, r);
      if (!epr || !epr->Metadata) {
	ERR("No EPR or missing <Metadata>. epr_buf(%.*s) file(%s)", epr_len, epr_buf, de->d_name);
        goto next_file;
      }
      if (!ZX_SIMPLE_ELEM_CHK(epr->Address)) {
	ERR("EPR missing <Address>. epr_buf(%.*s) file(%s)", epr_len, epr_buf, de->d_name);
        goto next_file;
      }
      addr = ZX_GET_CONTENT(epr->Address);
      md = epr->Metadata;
      svctyp = ZX_GET_CONTENT(md->ServiceType);
      prvid = ZX_GET_CONTENT(md->ProviderID);
      
      if (!zxid_di_match_svctype(n_discovered, rs, svctyp, de))    /* Filter by service type */
        goto next_file;

      if (!zxid_di_match_entid(n_discovered, rs, prvid, addr, de)) /* Filter by provider id */
        goto next_file;
      
      /* Check Options, in particular whether Trust parameters are there. */
      if (!zxid_di_match_options(cf, ses, n_discovered, rs, epr, de))
        goto next_file;

      /* *** Check Framework */

      /* *** Check Action */

      /* TAS3 Trust Credentials and Privacy Negotiation (if configured) */
      if (!zxid_di_match_cpn(cf, ses, n_discovered, svctyp, prvid, de))
        goto next_file;

      ++n_discovered;
      D("%d: DISCOVERED EPR epurl(%.*s)", n_discovered, addr->len, addr->s);
      if (!zxid_add_fed_tok2epr(cf, ses, epr, 1, logop))
	goto next_file;
      zxid_di_set_rankKey_if_needed(cf, md, n_discovered, de);
      
      zx_add_kid(&resp->gg, &epr->gg);
      if (!resp->EndpointReference)
	resp->EndpointReference = epr;

      zxlogwsp(cf, ses, "K", logop, uid, 0);

      if (rs->resultsType && rs->resultsType->g.s
	  && (!memcmp(rs->resultsType->g.s, "only-one", rs->resultsType->g.len)
	      || !memcmp(rs->resultsType->g.s, "best", rs->resultsType->g.len))) {
	D("only-one or best requested (%.*s)", rs->resultsType->g.len, rs->resultsType->g.s);
	break;
      }
      /* All epr_bufs that are in the discovered set are leaked at this point because
       * the XML structures used in preparing the response still reference the epr_buf. */
      continue;

next_file:
      if (epr)
	zx_free_elem(cf->ctx, &epr->gg, 0);
      ZX_FREE(cf->ctx, epr_buf);  /* free the reject EPR */
      continue;
    }
    
    closedir(dir);
  }

  r->EndpointReference = zxid_di_sort_eprs(cf, (zxid_epr*)resp->gg.kids);
  resp->gg.kids = &r->EndpointReference->gg;
  zxid_di_sanitize_rankKey_out(r->EndpointReference);
  
  ss = ZX_GET_CONTENT(req->RequestedService->ServiceType);
  D("TOTAL discovered %d svctype1(%.*s)", n_discovered, ss?ss->len:0, ss?ss->s:"");
  zxlogwsp(cf, ses, "K", "DIOK", 0, "%.*s n=%d", ss?ss->len:1, ss?ss->s:"-", n_discovered);
  resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "OK", 0, 0, 0);  /* last is first */
  D_DEDENT("di_query: ");
  return resp;
}

/* EOF  --  zxiddi.c */
