/* zxidepr.c  -  Handwritten functions for client side EPR and bootstrap handling
 * Copyright (c) 2012-2014 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidepr.c,v 1.19 2009-11-29 12:23:06 sampo Exp $
 *
 * 5.2.2007,  created --Sampo
 * 7.10.2008, added documentation --Sampo
 * 22.4.2012, fixed folding EPR names (to avoid folding comma) --Sampo
 * 7.12.2013, added EPR ranking --Sampo
 * 27.5.2014, improved nth progessing in zxid_find_epr() --Sampo
 *
 * See also: zxidsimp.c (attributes to LDIF), and zxida7n.c (general attribute querying)
 *
 * N.B. Like session storage, the epr cache makes case preserving assumption about
 * underlying filesystem. Case insensitive filesystem will insignificantly increase
 * chances of naming collitions.
 *
 * See also zxiddi.c for discovery server code.
 */

#include "platform.h"  /* for dirent.h */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-ns.h"
#include "c/zx-a-data.h"

/*() Fold service type (or any URN or URL) to file name. Typically
 * a service is represented by cached EPR file in session directory
 * or in /var/zxid/dimd/ directory in the IdP case. This file name
 * will have comma separated structure:
 *   FOLDEDSVCTYP,RANKKEY,NICE_SHA1_OF_CONTENTS
 * This function computes the first component of the comma separated structure. */

/* Called by:  zxid_di_query, zxid_find_epr, zxid_nice_sha1, zxid_reg_svc */
void zxid_fold_svc(char* svctyp, int len)
{
  for (; *svctyp && len; ++svctyp, --len)
    if (ONE_OF_6(*svctyp, ':','/',',','?','&','='))
      *svctyp = '_';
}

/*() Compute (and fold) unique nice sha1 name according to NAME,SHA1
 *
 * This name format is designed to ensure unique name, while
 * maintainting human (=sysadmin) readability. This is
 * useful in the common case where WSC wants to call a specific type of web service.
 *
 * cf::  ZXID configuration object, also used for memory allocation
 * buf:: result parameter. The buffer, which must have been allocated, will be
 *     modified to have the path. The path will be nul terminated.
 * buf_len:: The length of the buf (including nul termination), usually sizeof(buf)
 * name:: Often Service type name or SP Entity ID
 * cont:: content of EPR or the SP EntityID, used to compute sha1 hash that becomes part
 *     of the file name
 * ign_prefix:: How many characters to ignore from beginning of name: 0 or 7 (http://)
 * return:: 0 on success (the real return value is returned via ~buf~ result parameter) */

/* Called by: */
int zxid_nice_sha1(zxid_conf* cf, char* buf, int buf_len, struct zx_str* name, struct zx_str* cont, int ign_prefix)
{
  int len = MAX(name->len - ign_prefix, 0);
  char sha1_cont[28];
  sha1_safe_base64(sha1_cont, cont->len, cont->s);
  sha1_cont[27] = 0;
  snprintf(buf, buf_len, "%.*s,%s", len, name->s+ign_prefix, sha1_cont);
  buf[buf_len-1] = 0; /* must terminate manually as on win32 termination is not guaranteed */
  zxid_fold_svc(buf, len);
  return 0;
}

/*() Compute (and fold) unique EPR name according to /var/zxid/ses/SESID/SVC,RANK,SHA1
 *
 * This name format is designed to ensure unique name for each EPR, while
 * also making it easy to determine the service type and rank from the name. This is
 * useful in the common case where WSC wants to call a specific type of web service.
 *
 * cf::  ZXID configuration object, also used for memory allocation
 * dir:: Directory, such as "ses/"
 * sid:: Session ID whose EPR cache the file is/will be located
 * buf:: result parameter. The buffer, which must have been allocated, will be
 *     modified to have the path. The path will be nul terminated.
 * buf_len:: The length of the buf (including nul termination), usually sizeof(buf)
 * svc:: Service type name
 * rank:: Ranking key, used to ensure ordering of EPRs in discovery
 * cont:: content of EPR, used to compute sha1 hash that becomes part of the file name
 * return:: 0 on success (the real return value is returned via ~buf~ result parameter)
 *
 * N.B. This function relies on specific, ANSI documented, functioning
 * of snprintf(3) library function. Unfortunately, it has been found that
 * on some platforms this function only works correctly in the 'C' locale. If
 * you suspect this to be the case, you may want to try
 *
 *    export LANG=C
 *
 * especially if you get errors about multibyte characters. */

/* Called by:  zxid_cache_epr, zxid_snarf_eprs_from_ses */
int zxid_epr_path(zxid_conf* cf, char* dir, char* sid, char* buf, int buf_len, struct zx_str* svc, int rank, struct zx_str* cont)
{
  int len = svc->len;
  char sha1_cont[28];
  sha1_safe_base64(sha1_cont, cont->len, cont->s);
  sha1_cont[27] = 0;

  len = snprintf(buf, buf_len, "%s%s%s/", cf->cpath, dir, sid);
  if (len <= 0) {
    platform_broken_snprintf(len, __FUNCTION__, buf_len, "%s%s%s/");
    if (buf && buf_len > 0)
      buf[0] = 0;
    return 1;
  }
  buf[buf_len-1] = 0; /* must terminate manually as on win32 termination is not guaranteed */
  buf += len;
  buf_len -= len;

  if (buf_len < svc->len + 1 + 4 + 1 + sizeof(sha1_cont)) {
    ERR("buf too short buf_len=%ld need=%ld svc(%.*s)", (long)buf_len, svc->len + 1 + 4 + 1 + sizeof(sha1_cont), svc->len, svc->s);
    return 1;
  }
  memcpy(buf, svc->s, svc->len);
  zxid_fold_svc(buf, svc->len);
  buf += svc->len;
  buf_len -= svc->len;

  len = snprintf(buf, buf_len, ",%04d,%s", rank, sha1_cont);
  if (len <= 0) {
    platform_broken_snprintf(len, __FUNCTION__, buf_len, ",%04d,%s");
    if (buf && buf_len > 0)
      buf[0] = 0;
    return 1;
  }
  buf[buf_len-1] = 0; /* must terminate manually as on win32 termination is not guaranteed */
  return 0;
}

/*() Serialize EPR data structure to XML and write it to session's EPR cache under
 * file name that is both unique and indicates the service type and ranking.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file will be located
 * epr:: XML data structure representing the EPR
 * return:: 1 on success, 0 on failure
 *
 * Known bug:: If an EPR is meant to substitute a previously discovered
 *     one, it will not as the content (and possibly rank) will be different,
 *     thus causing the new EPR to have different name so it will not overwrite
 *     the old one. Perhaps the simple sha1 hash of the content is not the
 *     right solution. Better sha1 the svctype+eid+epurl? */

/* Called by:  main, zxid_get_epr, zxid_snarf_eprs */
int zxid_cache_epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, int rank)
{
  fdtype fd;
  struct zx_str* ss;
  char path[ZXID_MAX_BUF];
  
  if (!ses || !ses->sid || !ses->sid[0]) {
    ERR("Valid session required %p", ses);
    return 0;
  }
  if (!epr || !epr->Metadata || !epr->Metadata->ServiceType) {
    ERR("EPR is not a ID-WSF 2.0 Bootstrap: no Metadata %p", epr);
    return 0;
  }
  ss = zx_easy_enc_elem_opt(cf, &epr->gg);
  if (!ss) {
    ERR("Encoding EndpointReference failed %p", epr);
    return 0;
  }

  // *** respect rank and detect cache duplicates
  zxid_epr_path(cf, ZXID_SES_DIR, ses->sid, path, sizeof(path),
		ZX_GET_CONTENT(epr->Metadata->ServiceType), rank, ss);
  //fd = open(path, O_CREAT | O_WRONLY | O_TRUNC, 0666);
  fd = open_fd_from_path(O_CREAT | O_WRONLY | O_TRUNC, 0666, "zxid_cache_epr", 1, "%s", path);
  if (fd == BADFD) {
    perror("open for write cache_epr");
    ERR("EPR path(%s) creation failed", path);
  } else if (write_all_fd(fd, ss->s, ss->len) == -1) {
    perror("Trouble writing EPR");
  }
  close_file(fd, (const char*)__FUNCTION__);
  zx_str_free(cf->ctx, ss);
  return 1;
}

/*() Look into attribute statements of a SSO assertion and extract anything
 * that looks like EPR, storing results in the session for later reference.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache will be populated
 *
 * N.B. This approach ignores the official attribute names totally. Anything
 * that looks like an EPR and that is strcturally in right place will work.
 * Typical name /var/zxid/ses/SESID/SVCTYPE,SHA1 */

/* Called by:  zxid_as_call_ses, zxid_snarf_eprs_from_ses */
void zxid_snarf_eprs(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr)
{
  struct zx_str* ss;
  struct zx_str* urlss;
  int wsf20 = 0;
  if (!epr)
    return;
  for (; epr; epr = (zxid_epr*)epr->gg.g.n) {
    if (epr->gg.g.tok != zx_a_EndpointReference_ELEM)
      continue;
    ss = ZX_GET_CONTENT(epr->Metadata->ServiceType);
    urlss = ZX_GET_CONTENT(epr->Address);
    D("%d: EPR svc(%.*s) url(%.*s)", wsf20, ss?ss->len:0, ss?ss->s:"", urlss?urlss->len:0, urlss?urlss->s:"");
    if (zxid_cache_epr(cf, ses, epr, wsf20)) {
      ++wsf20;
      D("%d: EPR cached svc(%.*s) url(%.*s)", wsf20, ss?ss->len:0, ss?ss->s:"", urlss?urlss->len:0, urlss?urlss->s:"");
    }
  }
  D("TOTAL wsf20 EPRs snarfed: %d", wsf20);
}

/*() Look into attribute statements of a SSO assertion and extract anything
 * that looks like EPR, storing results in the session for later reference.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache will be populated
 *
 * N.B. This approach ignores the official attribute names totally. Anything
 * that looks like an EPR and that is structurally in right place will work.
 * Typical name /var/zxid/ses/SESID/SVCTYPE,SHA1 */

/* Called by:  zxid_sp_anon_finalize, zxid_sp_sso_finalize, zxid_wsc_valid_re_env, zxid_wsp_validate_env */
void zxid_snarf_eprs_from_ses(zxid_conf* cf, zxid_ses* ses)
{
  struct zx_sa_AttributeStatement_s* as;
  struct zx_sa_Attribute_s* at;
  struct zx_sa_AttributeValue_s* av;
  int wsf11 = 0;
  
  D_INDENT("snarf_eprs: ");
  zxid_get_ses_sso_a7n(cf, ses);
  if (ses->a7n) {
    for (as = ses->a7n->AttributeStatement; as;
	 as = (struct zx_sa_AttributeStatement_s*)as->gg.g.n) {
      if (as->gg.g.tok != zx_sa_AttributeStatement_ELEM)
	continue;
      for (at = as->Attribute; at; at = (struct zx_sa_Attribute_s*)at->gg.g.n) {
	if (at->gg.g.tok != zx_sa_Attribute_ELEM)
	  continue;
	for (av = at->AttributeValue; av; av = (struct zx_sa_AttributeValue_s*)av->gg.g.n) {
	  if (av->gg.g.tok != zx_sa_AttributeValue_ELEM)
	    continue;
	  zxid_snarf_eprs(cf, ses, av->EndpointReference);
	  if (av->ResourceOffering) {
	    ++wsf11;
	    D("Detected wsf11 resource offering. %d", wsf11);
#if 0	    
	    ss = zx_easy_enc_elem_opt(cf, &av->ResourceOffering->gg);
	    zxid_epr_path(cf, ZXID_SES_DIR, ses->sid, path, sizeof(path),
			  ZX_GET_CONTENT(av->EndpointReference->Metadata->ServiceType), ss);
	    fd = open(path, O_CREAT | O_WRONLY | O_TRUNC, 0666);
	    if (fd == -1) {
	      perror("open for write epr");
	      ERR("EPR path(%s) creation failed", path);
	    } else if (write_all_fd(fd, ss->s, ss->len) == -1) {
	      perror("Trouble writing EPR");
	      close__file(fd, __FUNCTION__);
	    }
	    zx_str_free(cf->ctx, ss);
#endif
	  }
	}
      }
    }
  }
#if 0
  if (ses->a7n12) {
    for (as = ses->a7n->AttributeStatement; as;
	 as = (struct zx_sa11_AttributeStatement_s*)as->gg.g.n) {
      if (as->gg.g.tok != zx_sa11_AttributeStatement_ELEM)
	continue;
      for (at = as->Attribute; at; at = (struct zx_sa11_Attribute_s*)at->gg.g.n) {
	if (at->gg.g.tok != zx_sa11_Attribute_ELEM)
	  continue;
	for (av = at->AttributeValue; av; av = (struct zx_sa11_AttributeValue_s*)av->gg.g.n) {
	  if (av->gg.g.tok != zx_sa11_AttributeValue_ELEM)
	    continue;
	}
      }
    }
  }
#endif
  D_DEDENT("snarf_eprs: ");
}

/*() Search the EPRs cached under the session for a match. First the directory is searched
 * for files whose name starts by service type. These files are opened and parsed
 * as EPR and further checks are made. The nth match is returned. 1 means first.
 * Typical filename: /var/zxid/ses/SESID/SVCTYPE,RANK,SHA1
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file is searched
 * svc:: Service type (usually a URN)
 * url:: (Optional) If provided, this argument has to match either
 *     the ProviderID, EntityID, or actual service endpoint URL.
 * di_opt:: (Optional) Additional discovery options for selecting the service, query string format
 * action:: (Optional) The action, or method, that must be invocable on the service (default: any)
 * n:: How manieth matching instance is returned. 1 means first
 * return:: EPR data structure (or linked list of EPRs) on success, 0 on failure
 *
 * See also: zxid_print_session() in zxcall.c and zxid_di_query() in zxiddi.c */

/* Called by:  main x2, zxid_get_epr x3 */
zxid_epr* zxid_find_epr(zxid_conf* cf, zxid_ses* ses, const char* svc, const char* url, const char* di_opt, const char* action, int nth)
{
  struct zx_root_s* r;
  struct zx_str* ss;
  struct zx_str* pi;
  int len, epr_len, iter = 0;
  char path[ZXID_MAX_BUF];
  char* epr_buf;  /* MUST NOT come from stack. */
  DIR* dir;
  struct dirent * de;
  zxid_epr* found = 0;  /* List of found eligible EPRs for sorting and nth selection */
  zxid_epr* epr = 0;
  zxid_epr* nxt;
  struct zx_a_Metadata_s* md = 0;  
  D_INDENT("find_epr: ");

  if (!svc || !*svc) {
    /* *** Relax this to allow discovery of multiple or all service types */
    ERR("Must supply service type %p", svc);
    D_DEDENT("find_epr: ");
    return 0;
  }
  
  if (!name_from_path(path, sizeof(path), "%s" ZXID_SES_DIR "%s", cf->cpath, ses->sid)) {
    D_DEDENT("find_epr: ");
    return 0;
  }
  
  D("Looking in session dir(%s) svc(%s) pses=%p", path, svc, ses);
  dir = opendir(path);
  if (!dir) {
    ERR("Opening session for find epr by opendir failed path(%s): %d %s; euid=%d egid=%d (sesptr=%p)", path, errno, STRERROR(errno), geteuid(), getegid(), ses);
    D_DEDENT("find_epr: ");
    return 0;
  }

  len = strlen(svc);
  len = MIN(len, sizeof(path)-1);
  memcpy(path, svc, len);
  path[len] = 0;
  zxid_fold_svc(path, len);
  D("%d Folded path prefix(%.*s) len=%d", iter, len, path, len);
  
  for (; de = readdir(dir); ++iter) {
    D("%d Considering file(%s)", iter, de->d_name);
    if (de->d_name[0] == '.')  /* . .. and "hidden" files */
      continue;
    if (de->d_name[strlen(de->d_name)-1] == '~')  /* Ignore backups from hand edited EPRs. */
      continue;
    if (memcmp(de->d_name, path, len) || de->d_name[len] != ',')
      continue;
    D("%d Checking EPR content file(%s)", iter, de->d_name);
    epr_buf = read_all_alloc(cf->ctx, "find_epr", 1, &epr_len,
			     "%s" ZXID_SES_DIR "%s/%s", cf->cpath, ses->sid, de->d_name);
    if (!epr_buf)
      continue;
    
    r = zx_dec_zx_root(cf->ctx, epr_len, epr_buf, "find epr");
    if (!r || !r->EndpointReference) {
      ERR("No EPR found. Failed to parse epr_buf(%.*s)", epr_len, epr_buf);
      ZX_FREE(cf->ctx, epr_buf);
      continue;
    }
    epr = r->EndpointReference;
    ZX_FREE(cf->ctx, r);
    if (!ZX_SIMPLE_ELEM_CHK(epr->Address)) {
      ERR("The EPR does not have <Address> element. Rejected. %p", epr->Address);
      goto next_file;
    }
    /* *** add ID-WSF 1.1 handling */
    md = epr->Metadata;
    if (!md || !ZX_SIMPLE_ELEM_CHK(md->ServiceType)) {
      ERR("No Metadata %p or ServiceType. Failed to parse epr_buf(%.*s)", md, epr_len, epr_buf);
      goto next_file;
    }
    ss = ZX_GET_CONTENT(md->ServiceType);
    if (!ss || len != ss->len || memcmp(svc, ss->s, len)) {
      D("%d Internal svctype(%.*s) does not match desired(%s). Reject.", iter, ss?ss->len:0, ss?ss->s:"", svc);
      goto next_file;
    }
    
    ss = ZX_GET_CONTENT(epr->Address);
    if (url && (!ss || strlen(url) != ss->len || memcmp(url, ss->s, ss->len))) {
      pi = md?ZX_GET_CONTENT(md->ProviderID):0;
      if (pi && (strlen(url) != pi->len || memcmp(url, pi->s, pi->len))) {
	D("%d ProviderID(%.*s) or endpoint URL(%.*s) does not match desired url(%s). Reject.", iter, pi->len, pi->s, ss?ss->len:0, ss?ss->s:"", url);
	goto next_file;
      }
    }

    /* *** Evaluate di_opt */

    /* *** Evaluate action */
    
    /* Add to the front of the list of the eligible candidates. */
    D("%d Add to candidate set svc(%s) url(%.*s)", iter, svc, ZX_GET_CONTENT_LEN(epr->Address), ZX_GET_CONTENT_S(epr->Address));
    zxid_di_set_rankKey_if_needed(cf, epr->Metadata, iter, de);
    epr->gg.g.n = &found->gg.g;
    found = epr;
    continue;

next_file:
    zx_free_elem(cf->ctx, &epr->gg, 0);
    ZX_FREE(cf->ctx, epr_buf);
    continue;
  }
  closedir(dir);

  if (!found) {
    D_DEDENT("find_epr: ");
    return 0;
  }
  
  epr = zxid_di_sort_eprs(cf, found);
  found = 0;
  for (iter=1; epr; ++iter, epr = nxt) {
    nxt = (zxid_epr*)epr->gg.g.n;
    if (iter == nth) {
      epr->gg.g.n = 0;
      found = epr;
    } else {
      zx_free_elem(cf->ctx, &epr->gg, 0);  /* not returned, better free it! */
      /* ZX_FREE(cf->ctx, epr_buf);  *** this pointer is already lost. No way to free. Bummer! */
    }
  }
  
  if (!found) {
    D("nth=%d beyond available result set iter=%d", nth, iter);
    D_DEDENT("find_epr: ");
    return 0;
  }
  
  D("%d/%d Found svc(%s) epurl(%.*s)", nth, iter, svc, ZX_GET_CONTENT_LEN(found->Address), ZX_GET_CONTENT_S(found->Address));
  D_DEDENT("find_epr: ");
  return found;
}

/*() Discover an EPR over the net.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file will be searched
 * svc:: Service type (usually the namespace URN)
 * url:: (Optional) If provided, this argument has to match either
 *     the ProviderID, EntityID, or actual service endpoint URL.
 * di_opt:: (Optional) Additional discovery options for selecting the service, query string format
 * action:: (Optional) The action, or method, that must be invocable on the service
 * return:: EPR data structure on success, 0 on failure (no discovery EPR in cache, or
 *     not found by the discovery service). If more than one were found, a linked list
 *     of EPRs is returned.
 */

zxid_epr* zxid_discover_epr(zxid_conf* cf, zxid_ses* ses, const char* svc, const char* url, const char* di_opt, const char* action)
{
  int wsf20 = 0;
  struct zx_str* ss;
  struct zx_str* urlss;
  struct zx_e_Envelope_s* env;
  zxid_epr* epr;

  D_INDENT("di: ");
  INFO("Discovering svc(%s)...", STRNULLCHK(svc));
  env = zx_NEW_e_Envelope(cf->ctx,0);
  env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
  env->Body->Query = zxid_mk_di_query(cf, &env->Body->gg, svc, url, di_opt, 0);
  if (ses->deleg_di_epr) {
    epr = ses->deleg_di_epr;
    D("Using delegated discovery EPR %p", epr);
  } else {
    epr = zxid_find_epr(cf, ses, zx_xmlns_di, 0, 0, 0, 1);
    if (!epr) {
      ERR("EPR for svc(%s) not found in cache and no discovery EPR in cache, thus no way to discover the svc.", STRNULLCHK(svc));
      D_DEDENT("di: ");
      return 0;
    }
  }
  env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
  env = zxid_wsc_call(cf, ses, epr, env, 0);
  if (!env || env == (void*)ZXID_REDIR_OK || !env->Body || !env->Body->QueryResponse) {
    ERR("Discovery call failed: No di:QueryResponse seen env=%p body=%p", env, env?env->Body:0);
    D_DEDENT("di: ");
    return 0;
  }
  D("HERE %p", env);
  for (epr = env->Body->QueryResponse->EndpointReference;
       epr;
       epr = (zxid_epr*)ZX_NEXT(epr)) {
    if (epr->gg.g.tok != zx_a_EndpointReference_ELEM)
      continue;
    ss = ZX_GET_CONTENT(epr->Metadata->ServiceType);
    urlss = ZX_GET_CONTENT(epr->Address);
    D("%d: EPR svc(%.*s) url(%.*s)", wsf20, ss?ss->len:0, ss?ss->s:"", urlss?urlss->len:0, urlss?urlss->s:"");
    if (zxid_cache_epr(cf, ses, epr, wsf20)) {
      ++wsf20;
      D("%d: EPR cached svc(%.*s) url(%.*s)", wsf20, ss?ss->len:0, ss?ss->s:"", urlss?urlss->len:0, urlss?urlss->s:"");
    }
  }
  epr = env->Body->QueryResponse->EndpointReference;
  if (!epr)
    ERR("No end point discovered for svc(%s)", STRNULLCHK(svc));
  D("TOTAL wsf20 EPRs discovered: %d for svc(%s)", wsf20, STRNULLCHK(svc));
  D_DEDENT("di: ");
  return epr;
}

/*(i) First search epr cache, and if miss, go discover an EPR over the net.
 * This is the main work horse for a WSCs wishing to call WSPs via EPR.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file will be searched
 * svc:: Service type (usually the namespace URN)
 * url:: (Optional) If provided, this argument has to match either
 *     the ProviderID, EntityID, or actual service endpoint URL.
 * di_opt:: (Optional) Additional discovery options for selecting the service, query string format
 * action:: (Optional) The action, or method, that must be invocable on the service (default: any)
 * nth:: How manieth matching instance is returned. 1 means first. n>1 assumes
 *     all EPRs are already in cache and prevents querying Discovery Service.
 *     0 forces re-querying Discovery service. If nth is larger than number of entries
 *     in the cache, then return null (0) - this allows one to first call with nth==0 to refresh
 *     the cache and then to iterate over it. As a legacy compliance feature, if nth==1
 *     and there is nothing in the cache, then discovery query is made anyway
 *     to see if something could be found.
 * return:: EPR data structure on success, 0 on failure (no discovery EPR in cache, or
 *     not found by the discovery service). If more than one were found, a linked list
 *     of EPRs is returned.
 *
 * See also:: zxid_get_epr_address() for extracting URL as a string
 */

/* Called by:  main x5, zxcall_main x2, zxid_call, zxid_map_identity_token, zxid_nidmap_identity_token, zxid_show_protected_content_setcookie */
zxid_epr* zxid_get_epr(zxid_conf* cf, zxid_ses* ses, const char* svc, const char* url, const char* di_opt, const char* action, int nth)
{
  zxid_epr* epr;
  
  if (nth > 0) {
    epr = zxid_find_epr(cf, ses, svc, url, di_opt, action, nth);
    if (epr)
      return epr;
    if (nth > 1)
      return 0;  /* Do not discover any more */
    /* nth == 1 and no-epr-in-cache-case: fall thru */
    D("nth=%d fallthru", nth);
  }
  zxid_discover_epr(cf, ses, svc, url, di_opt, action);
  /* We need to call zxid_find_epr() to ensure the order is always same. */
  epr = zxid_find_epr(cf, ses, svc, url, di_opt, action, nth);
  return epr;
}

/*() Accessor function for extracting endpoint address URL. */

/* Called by:  zxcall_main, zxid_print_session, zxid_show_protected_content_setcookie */
struct zx_str* zxid_get_epr_address(zxid_conf* cf, zxid_epr* epr) {
  if (!epr)
    return 0;
  return ZX_GET_CONTENT(epr->Address);
}

/*() Accessor function for extracting endpoint ProviderID. */

/* Called by:  zxcall_main, zxid_print_session */
struct zx_str* zxid_get_epr_entid(zxid_conf* cf, zxid_epr* epr) {
  if (!epr || !epr->Metadata || !epr->Metadata->ProviderID) {
    D("Missing epr=%p epr->Metadata=%p or epr->Metadata->ProviderID", epr, epr?epr->Metadata:0);
    return 0;
  }
  D("epr->Metadata->ProviderID=%p", epr->Metadata->ProviderID);
  return ZX_GET_CONTENT(epr->Metadata->ProviderID);
}

/*() Accessor function for extracting endpoint Description (Abstract). */

/* Called by:  zxcall_main, zxid_print_session */
struct zx_str* zxid_get_epr_desc(zxid_conf* cf, zxid_epr* epr) {
  if (!epr || !epr->Metadata)
    return 0;
  return ZX_GET_CONTENT(epr->Metadata->Abstract);
}

/*() Accessor function for extracting endpoint TAS3 Trust scores. */

/* Called by: */
struct zx_str* zxid_get_epr_tas3_trust(zxid_conf* cf, zxid_epr* epr) {
  if (!epr || !epr->Metadata || !epr->Metadata->Trust)
    return 0;
  return zx_easy_enc_elem_sig(cf, &epr->Metadata->Trust->gg);
}

/*() Accessor function for extracting security mechanism ID. */

/* Called by: */
struct zx_str* zxid_get_epr_secmech(zxid_conf* cf, zxid_epr* epr) {
  struct zx_elem_s* secmech;
  if (!epr || !epr->Metadata)
    return 0;
  if (!epr->Metadata->SecurityContext
      || (secmech = epr->Metadata->SecurityContext->SecurityMechID)) {
    ERR("Null EPR or EPR is missing Metadata, SecurityContext or SecurityMechID. %p", epr);
    return 0;
  }
  return ZX_GET_CONTENT(secmech);
}

/*() Set security mechanism ID.
 *
 * WARNING! Usually security mechanism ID is set by the
 * discovery process. Do not manipulate it unless you
 * know what you are doing. If security mechanism requires
 * a token, you need to arrange it separately, either via
 * discovery (recommended) or using zxid_set_epr_token() (if
 * you know what you are doing). */

/* Called by: */
void zxid_set_epr_secmech(zxid_conf* cf, zxid_epr* epr, const char* secmec) {
  if (!epr) {
    ERR("Null EPR. %p", epr);
    return;
  }
  if (!epr->Metadata)
    epr->Metadata = zx_NEW_a_Metadata(cf->ctx, &epr->gg);
  if (!epr->Metadata->SecurityContext)
    epr->Metadata->SecurityContext = zx_NEW_di_SecurityContext(cf->ctx, &epr->Metadata->gg);
  if (secmec) {
    epr->Metadata->SecurityContext->SecurityMechID
      = zx_dup_elem(cf->ctx, &epr->Metadata->SecurityContext->gg, zx_di_SecurityMechID_ELEM, secmec);
    INFO("SecurityMechID set to(%s)", secmec);
  } else {
    epr->Metadata->SecurityContext->SecurityMechID
      = zx_dup_elem(cf->ctx, &epr->Metadata->SecurityContext->gg, zx_di_SecurityMechID_ELEM, 0);
    INFO("SecurityMechID set null %d", 0);
  }
}

/*() Accessor function for extracting endpoint's (SAML2 assertion) token. */

/* Called by: */
zxid_tok* zxid_get_epr_token(zxid_conf* cf, zxid_epr* epr) {
  if (!epr || !epr->Metadata || !epr->Metadata->SecurityContext) {
    ERR("Null EPR or EPR is missing Metadata or SecurityContext. %p", epr);
    return 0;
  }
  return epr->Metadata->SecurityContext->Token;
}

/*() Set endpoint's (SAML2 assertion) token.
 *
 * WARNING! Generally you should not call this function. Instead
 * you should use discovery to obtain a token properly targeted
 * to the destination of the EPR. This includes correct audience
 * restriction, correct name id, and possible encryption of the
 * token so that only destination can open it. Perticular things
 * you should NOT do: just copy SSO token and pass it to web service
 * call (the audience restriction will be wrong); just copy
 * token that was received on WSP interface and use it on WSC interface. */

/* Called by: */
void zxid_set_epr_token(zxid_conf* cf, zxid_epr* epr, zxid_tok* tok) {
  if (!epr) {
    ERR("Null EPR. %p", epr);
    return;
  }
  if (!epr->Metadata)
    epr->Metadata = zx_NEW_a_Metadata(cf->ctx, &epr->gg);
  if (!epr->Metadata->SecurityContext)
    epr->Metadata->SecurityContext = zx_NEW_di_SecurityContext(cf->ctx, &epr->Metadata->gg);
  epr->Metadata->SecurityContext->Token = tok;
  INFO("EPR token set %p", tok);
}

/*() Constructor for "blank" EPR. Such EPR lacks security context so it is
 * not directly usable for identity web service calls. However, it could
 * be useful as a building block, or for non-identity web service.
 * Also id, actor, and mustUnderstand fields need to be filled in by
 * other means (we may eventually have defaults for some of these). */

/* Called by: */
zxid_epr* zxid_new_epr(zxid_conf* cf, char* address, char* desc, char* entid, char* svctype)
{
  zxid_epr* epr = zx_NEW_a_EndpointReference(cf->ctx,0);
  if (address) {
    epr->Address = zx_NEW_a_Address(cf->ctx, &epr->gg);
    zx_add_content(cf->ctx, &epr->Address->gg, zx_dup_str(cf->ctx, address));
  }
  if (desc || entid || svctype) {
    epr->Metadata = zx_NEW_a_Metadata(cf->ctx, &epr->gg);
    if (desc)
      epr->Metadata->Abstract
	= zx_dup_elem(cf->ctx, &epr->Metadata->gg, zx_di_Abstract_ELEM, desc);
    if (entid)
      epr->Metadata->ProviderID
	= zx_dup_elem(cf->ctx, &epr->Metadata->gg, zx_di_ProviderID_ELEM, entid);
    if (svctype)
      epr->Metadata->ServiceType
	= zx_dup_elem(cf->ctx, &epr->Metadata->gg, zx_di_ServiceType_ELEM, svctype);
  }
  return epr;
}

/*() Returns delegated discovery EPR, such as someone else's discovery epr. */
/* Called by: */
zxid_epr* zxid_get_delegated_discovery_epr(zxid_conf* cf, zxid_ses* ses)
{
  return ses->deleg_di_epr;
}

/*(i) Allows explicit control over which Discovery Service is used, such
 * as selecting somebody else's Discovery Service. This allows delegated
 * access. */

/* Called by: */
void zxid_set_delegated_discovery_epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr)
{
  ses->deleg_di_epr = epr;
}

/*() Get session's call invokation token. */

/* Called by: */
zxid_tok* zxid_get_call_invoktok(zxid_conf* cf, zxid_ses* ses) {
  if (!ses) {
    ERR("Null session. %p", ses);
    return 0;
  }
  return ses->call_invoktok;
}

/*() Set session's call invokation token. */

/* Called by: */
void zxid_set_call_invoktok(zxid_conf* cf, zxid_ses* ses, zxid_tok* tok) {
  if (!ses) {
    ERR("Null session. %p", ses);
    return;
  }
  ses->call_invoktok = tok;
}

/*() Get session's call target token. */

/* Called by: */
zxid_tok* zxid_get_call_tgttok(zxid_conf* cf, zxid_ses* ses) {
  if (!ses) {
    ERR("Null session. %p", ses);
    return 0;
  }
  return ses->call_tgttok;
}

/*() Set session's call target token. */

/* Called by: */
void zxid_set_call_tgttok(zxid_conf* cf, zxid_ses* ses, zxid_tok* tok) {
  if (!ses) {
    ERR("Null session. %p", ses);
    return;
  }
  ses->call_tgttok = tok;
}

/*() Serialize an EPR. */

/* Called by: */
struct zx_str* zxid_epr2str(zxid_conf* cf, zxid_epr* epr) {
  if (!epr) {
    ERR("NULL EPR. %p", epr);
    return 0;
  }
  return zx_easy_enc_elem_sig(cf, &epr->gg);
}

/*() Serialize a token. */

/* Called by: */
struct zx_str* zxid_token2str(zxid_conf* cf, zxid_tok* tok) {
  if (!tok) {
    ERR("NULL Token. %p", tok);
    return 0;
  }
  if (!tok)
    return 0;
  return zx_easy_enc_elem_sig(cf, &tok->gg);
}

/*() Parse string into token. */

/* Called by: */
zxid_tok* zxid_str2token(zxid_conf* cf, struct zx_str* ss) {
  struct zx_root_s* r;
  zxid_tok* tok;

  if (!ss || !ss->len || !ss->s)
    return 0;
  
  r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "decode token");
  if (!r) {
    ERR("Failed to parse token buf(%.*s)", ss->len, ss->s);
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "BADXML", 0, "bad token");
    return 0;
  }
  if (r->Token)
    return r->Token;
  tok = zx_NEW_sec_Token(cf->ctx,0);
  tok->Assertion = r->Assertion;
  tok->EncryptedAssertion = r->EncryptedAssertion;
  tok->sa11_Assertion = r->sa11_Assertion;
  tok->ff12_Assertion = r->ff12_Assertion;
  return tok;
}

/*() Serialize an assertion. */

/* Called by: */
struct zx_str* zxid_a7n2str(zxid_conf* cf, zxid_a7n* a7n) {
  if (!a7n)
    return 0;
  return zx_easy_enc_elem_sig(cf, &a7n->gg);
}

/*() Parse string into assertion. */

/* Called by: */
zxid_a7n* zxid_str2a7n(zxid_conf* cf, struct zx_str* ss) {
  struct zx_root_s* r;

  if (!ss || !ss->len || !ss->s)
    return 0;
  
  r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "decode a7n");
  if (!r) {
    ERR("Failed to parse assertion buf(%.*s)", ss->len, ss->s);
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "BADXML", 0, "bad a7n");
    return 0;
  }
  return r->Assertion;
}

/*() Serialize a NameID. */

/* Called by: */
struct zx_str* zxid_nid2str(zxid_conf* cf, zxid_nid* nid) {
  if (!nid)
    return 0;
  return zx_easy_enc_elem_sig(cf, &nid->gg);
}

/*() Parse string into NameID. */

/* Called by: */
zxid_nid* zxid_str2nid(zxid_conf* cf, struct zx_str* ss) {
  struct zx_root_s* r;

  if (!ss || !ss->len || !ss->s)
    return 0;
  
  r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "decode nid");
  if (!r) {
    ERR("Failed to parse NameID buf(%.*s)", ss->len, ss->s);
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "BADXML", 0, "bad nid");
    return 0;
  }
  return r->NameID;
}

/* ---------- Session field accessor functions ---------- */

/*() Get session's invoker nameid. */

/* Called by: */
zxid_nid* zxid_get_nameid(zxid_conf* cf, zxid_ses* ses) {
  if (!ses)
    return 0;
  return ses->nameid;
}

/*() Set session's invoker nameid. */

/* Called by: */
void zxid_set_nameid(zxid_conf* cf, zxid_ses* ses, zxid_nid* nid) {
  if (!ses)
    return;
  ses->nameid = nid;
}

/*() Get session's target nameid. */

/* Called by: */
zxid_nid* zxid_get_tgtnameid(zxid_conf* cf, zxid_ses* ses) {
  if (!ses)
    return 0;
  return ses->tgtnameid;
}

/*() Set session's target nameid. */

/* Called by: */
void zxid_set_tgtnameid(zxid_conf* cf, zxid_ses* ses, zxid_nid* nid) {
  if (!ses)
    return;
  ses->tgtnameid = nid;
}

/*() Get session's invoker assertion. */

/* Called by: */
zxid_a7n* zxid_get_a7n(zxid_conf* cf, zxid_ses* ses) {
  if (!ses)
    return 0;
  return ses->a7n;
}

/*() Set session's invoker assertion. */

/* Called by: */
void zxid_set_a7n(zxid_conf* cf, zxid_ses* ses, zxid_a7n* a7n) {
  if (!ses)
    return;
  ses->a7n = a7n;
}

/*() Get session's target assertion. */

/* Called by: */
zxid_a7n* zxid_get_tgta7n(zxid_conf* cf, zxid_ses* ses) {
  if (!ses)
    return 0;
  return ses->tgta7n;
}

/*() Set session's target assertion. */

/* Called by: */
void zxid_set_tgta7n(zxid_conf* cf, zxid_ses* ses, zxid_a7n* a7n) {
  if (!ses)
    return;
  ses->tgta7n = a7n;
}

/* EOF  --  zxidepr.c */
