/* zxidpsso.c  -  Handwritten functions for implementing Single Sign-On logic on IdP
 * Copyright (c) 2009-2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2008-2009 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidpsso.c,v 1.16 2010-01-08 02:10:09 sampo Exp $
 *
 * 14.11.2008, created --Sampo
 * 4.9.2009,   added persistent nameid support --Sampo
 * 24.11.2009, fixed handling of transient nameid --Sampo
 * 12.2.2010,  added locking to lazy loading --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 */

#include "platform.h"  /* for dirent.h */

#include <sys/stat.h>
#include <errno.h>

#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "wsf.h"
#include "c/zxidvers.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*() Helper function to sign, if needed, and log the issued assertion.
 * Checks for Assertion ID duplicate and returns 0 on
 * failure (i.e. duplicate), 1 on success. The ret_logpath argument,
 * if not NULL, allows returnign the logpath to caller, e.g. to use
 * as an artifact (caller frees). */

/* Called by:  zxid_add_fed_tok2epr, zxid_idp_sso x3, zxid_imreq, zxid_map_val_ss */
int zxid_anoint_a7n(zxid_conf* cf, int sign, zxid_a7n* a7n, struct zx_str* issued_to, const char* lk, const char* uid, struct zx_str** ret_logpath)
{
  X509* sign_cert;
  EVP_PKEY*  sign_pkey;
  struct zxsig_ref refs;
  struct zx_str* ss;
  struct zx_str* logpath;
  struct timeval ourts;
  GETTIMEOFDAY(&ourts, 0);
  
  if (sign) {
    ZERO(&refs, sizeof(refs));
    refs.id = &a7n->ID->g;
    refs.canon = zx_easy_enc_elem_sig(cf, &a7n->gg);
    if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey,"use sign cert anoint a7n")) {
      a7n->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
      zx_add_kid_after_sa_Issuer(&a7n->gg, &a7n->Signature->gg);
    }
    zx_str_free(cf->ctx, refs.canon);
  }
  
  /* Log the issued a7n */

  if (cf->loguser)
    zxlogusr(cf, uid, &ourts, &ourts, 0, issued_to, 0, &a7n->ID->g,
	     (ZX_GET_CONTENT(a7n->Subject->NameID)
	      ?ZX_GET_CONTENT(a7n->Subject->NameID)
	      :(zx_dup_str(cf->ctx, (a7n->Subject->EncryptedID?"ENC":"-")))),
	     sign?"U":"N", "K", lk, "-", 0);

  zxlog(cf, &ourts, &ourts, 0, issued_to, 0, &a7n->ID->g,
	(ZX_GET_CONTENT(a7n->Subject->NameID)
	 ?ZX_GET_CONTENT(a7n->Subject->NameID)
	 :(zx_dup_str(cf->ctx, (a7n->Subject->EncryptedID?"ENC":"-")))),
	sign?"U":"N", "K", lk, "-", 0);
  
  if (cf->log_issue_a7n) {
    logpath = zxlog_path(cf, issued_to, &a7n->ID->g, ZXLOG_ISSUE_DIR, ZXLOG_A7N_KIND, 1);
    if (logpath) {
      ss = zx_easy_enc_elem_sig(cf, &a7n->gg);
      if (zxlog_dup_check(cf, logpath, "IdP POST Assertion")) {
	ERR("Duplicate Assertion ID(%.*s)", a7n->ID->g.len, a7n->ID->g.s);
	if (cf->dup_a7n_fatal) {
	  ERR("FATAL (by configuration): Duplicate Assertion ID(%.*s)", a7n->ID->g.len, a7n->ID->g.s);
	  zxlog_blob(cf, 1, logpath, ss, "anoint_a7n dup");
	  zx_str_free(cf->ctx, ss);
	  zx_str_free(cf->ctx, logpath);
	  return 0;
	}
      }
      zxlog_blob(cf, 1, logpath, ss, "anoint_a7n");
      if (ret_logpath)
	*ret_logpath = logpath;
      else
	zx_str_free(cf->ctx, logpath);
      zx_str_free(cf->ctx, ss);
    }
  }
  return 1;
}

/*() Helper function to sign, if needed, and log the issued response.
 * Checks for message ID duplicate and returns 0 on failure (i.e. duplicate),
 * or the canonicalized response message string on success. This string
 * may be useful for caller to send further and should be freed by the caller. */

/* Called by:  zxid_idp_sso x4, zxid_ssos_anreq */
struct zx_str* zxid_anoint_sso_resp(zxid_conf* cf, int sign, struct zx_sp_Response_s* resp, struct zx_sp_AuthnRequest_s* ar)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  zxid_a7n* a7n;
  struct zxsig_ref refs;
  struct zx_str* ss;
  struct zx_str* logpath;
  struct timeval ourts;
  GETTIMEOFDAY(&ourts, 0);
  
  if (sign) {
    ZERO(&refs, sizeof(refs));
    refs.id = &resp->ID->g;
    refs.canon = zx_easy_enc_elem_sig(cf, &resp->gg);
    if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert,&sign_pkey,"use sign cert anoint resp")) {
      resp->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
      zx_add_kid_after_sa_Issuer(&resp->gg, &resp->Signature->gg);
    }
    zx_str_free(cf->ctx, refs.canon);
  }
  
  /* Log the issued Response */
  
  a7n = resp->Assertion;
  zxlog(cf, &ourts, &ourts, 0, ZX_GET_CONTENT(ar->Issuer), &resp->ID->g,
	a7n&&a7n->ID?&a7n->ID->g:zx_dup_str(cf->ctx, "-"),
	(a7n
	 ?(ZX_GET_CONTENT(a7n->Subject->NameID)
	   ?ZX_GET_CONTENT(a7n->Subject->NameID)
	   :(zx_dup_str(cf->ctx, (a7n->Subject->EncryptedID?"ENC":"-"))))
	 :zx_dup_str(cf->ctx,"-")),
	sign?"U":"N", "K", "SSORESP", "-", 0);

  ss = zx_easy_enc_elem_opt(cf, &resp->gg);

  if (cf->log_issue_msg) {
    logpath = zxlog_path(cf, ZX_GET_CONTENT(ar->Issuer), &resp->ID->g, ZXLOG_ISSUE_DIR, ZXLOG_MSG_KIND,1);
    if (logpath) {
      if (zxlog_dup_check(cf, logpath, "IdP POST Response")) {
	ERR("Duplicate Response ID(%.*s)", resp->ID->g.len, resp->ID->g.s);
	if (cf->dup_msg_fatal) {
	  ERR("FATAL (by configuration): Duplicate Response ID(%.*s)", resp->ID->g.len, resp->ID->g.s);
	  zxlog_blob(cf, 1, logpath, ss, "anoint_sso_resp dup");
	  zx_str_free(cf->ctx, ss);
	  zx_str_free(cf->ctx, logpath);
	  return 0;
	}
      }
      zxlog_blob(cf, 1, logpath, ss, "anoint_sso_resp");
      zx_str_free(cf->ctx, logpath);
    }
  }
  return ss;
}

#define ZXID_ADD_BS_LVL_LIM 2  /* 2=only add full bootstraps on SSO. Only add di there after. */

/*() Process .bs directory. See also zxid_di_query() */

/* Called by:  zxid_idp_as_do x2, zxid_mk_usr_a7n_to_sp x2 */
void zxid_gen_boots(zxid_conf* cf, zxid_ses* ses, struct zx_sa_AttributeStatement_s* father, char* path, int bs_lvl)
{
  struct timeval srcts = {0,501000};
  struct zx_sa_Attribute_s* at;
  zxid_epr* epr;
  struct zx_root_s* r;
  struct zx_str* ss;
  DIR* dir;
  struct dirent * de;
  char mdpath[ZXID_MAX_BUF];
  char logop[8];
  char* epr_buf;
  int epr_len, is_di, ret;
  strcpy(logop, "xxxBSyy");
  D_INDENT("gen_bs: ");

  if (!bs_lvl) {
    D("bs_lvl=%d: nothing to add", bs_lvl);
    D_DEDENT("gen_bs: ");
    return;  /* Discovery EPRs do not need any bootstraps. */
  }
  
  name_from_path(mdpath, sizeof(mdpath), "%s" ZXID_DIMD_DIR, cf->cpath);
  D("Looking for service metadata in dir(%s) bs_lvl=%d", mdpath, bs_lvl);
  
  dir = opendir(path);
  if (!dir) {
    perror("opendir to find bootstraps");
    ERR("Opening bootstrap directory failed path(%s)", path);
    D_DEDENT("gen_bs: ");
    return;
  }
  
  while (de = readdir(dir)) {
    D("Consider bs(%s%s)", path, de->d_name);
    
    if (de->d_name[strlen(de->d_name)-1] == '~')  /* Ignore backups from hand edited EPRs. */
      continue;
    if (de->d_name[0] == '.')  /* Ignore hidden files. */
      continue;
    
    /* Probable enough, read and parse EPR so we can continue examination. */
    
    epr_buf = read_all_alloc(cf->ctx, "find_bs_svcmd", 1, &epr_len, "%s/%s", mdpath, de->d_name);
    if (!epr_buf) {
      ERR("User's (%s) bootstrap(%s) lacks service metadata registration. Reject. Consider using zxcot -e ... | zxcot -bs. See zxid-idp.pd for further information.", ses->uid, de->d_name);
      ZX_FREE(cf->ctx, epr_buf);
      continue;
    }
    r = zx_dec_zx_root(cf->ctx, epr_len, epr_buf, "gen boots");
    if (!r) {
      ERR("Failed to XML parse epr_buf(%.*s) file(%s)", epr_len, epr_buf, de->d_name);
      ZX_FREE(cf->ctx, epr_buf);
      continue;
    }
    /* *** add ID-WSF 1.1 handling */
    epr = r->EndpointReference;
    ZX_FREE(cf->ctx, r);

    if (!epr || !epr->Metadata || !ZX_SIMPLE_ELEM_CHK(epr->Metadata->ServiceType)) {
      ERR("No EPR, corrupt EPR, or missing <Metadata> %p or <ServiceType>. epr_buf(%.*s) file(%s)", epr->Metadata, epr_len, epr_buf, de->d_name);
      ZX_FREE(cf->ctx, epr_buf);
      continue;
    }
    ss = ZX_GET_CONTENT(epr->Metadata->ServiceType);
    is_di = ss? !memcmp(ss->s, XMLNS_DISCO_2_0, ss->len) : 0;
    D("FOUND BOOTSTRAP url(%.*s) is_di=%d", ZX_GET_CONTENT_LEN(epr->Address), ZX_GET_CONTENT_S(epr->Address), is_di);
    
    if (is_di) {
      ret = zxid_add_fed_tok2epr(cf, ses, epr, 0, logop); /* recurse, di tail */
    } else if (bs_lvl > cf->bootstrap_level) {
      D("No further bootstraps generated due to boostrap_level=%d (except di boostraps)", bs_lvl);
      ZX_FREE(cf->ctx, epr_buf);
      continue;
    } else
      ret = zxid_add_fed_tok2epr(cf, ses, epr, bs_lvl+1, logop); /* recurse */
    D("bs_lvl=%d: adding logop(%s)", bs_lvl, logop);
    if (!ret)
      goto next_file;
    
    D("ADD BOOTSTRAP url(%.*s) is_di=%d", ZX_GET_CONTENT_LEN(epr->Address), ZX_GET_CONTENT_S(epr->Address), is_di);
    father->Attribute = at = zxid_mk_sa_attribute(cf, &father->gg, WSF20_DI_RO, 0, 0);
    ZX_ADD_KID(at->AttributeValue, EndpointReference, epr);
    
    zxlog(cf, 0, &srcts, 0, 0, 0, 0 /*a7n->ID*/, 0 /*nameid->gg.content*/,"N","K", logop, ses->uid, "gen_bs");
    
  next_file:
    continue;
  }
  
  closedir(dir);
  D_DEDENT("gen_bs: ");
}

/* Called by:  zxid_add_ldif_attrs, zxid_mk_usr_a7n_to_sp x3 */
static void zxid_add_mapped_attr(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, struct zx_elem_s* father, char* lk, struct zxid_map* sp_aamap, const char* name, const char* val)
{
  struct zxid_map* map;
  map = zxid_find_map(sp_aamap, name);
  if (!map)
    map = zxid_find_map(cf->aamap, name);
  if (map && map->rule != ZXID_MAP_RULE_DEL) {
    D("%s: ATTR(%s)=VAL(%s)", lk, name, val);
    if (map->dst && *map->dst && map->src && map->src[0] != '*')
      name = map->dst;
    zxid_mk_sa_attribute_ss(cf, father, name, 0,
			    zxid_map_val(cf, ses, meta, map, name, val));
  } else {
    D("%s: Attribute(%s) filtered out either by del rule in aamap, or does not match aamap %p", lk, name, map);
  }
}

/*() Parse LDIF format and insert attributes to linked list. Return new head of the list.
 * The input is temporarily modified and then restored. Do not pass const string.
 * Multiple attribute lines by same name (meaning multivalued attribute) generate
 * multiple <sa:Attribute> elements. At least zxid sp code will corretly interpret
 * this as single multivalued attribute. */

/* Called by:  zxid_read_ldif_attrs */
static void zxid_add_ldif_attrs(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, struct zx_elem_s* father, char* p, char* lk, struct zxid_map* sp_aamap)
{
  char* name;
  char* val;

  for (; p; ++p) {
    name = p;
    p = strstr(p, ": ");
    if (!p)
      break;
    *p = 0;
    val = p+2;
    p = strchr(val, '\n');  /* *** parsing LDIF is fragile if values are multiline */
    if (p)
      *p = 0;
    
    zxid_add_mapped_attr(cf, ses, meta, father, lk, sp_aamap, name, val);
    
    val[-2] = ':'; /* restore */
    if (p)
      *p = '\n';
    else
      break;
  }
}

/*() Read Attribute Authority Map */

/* Called by:  zxid_mk_usr_a7n_to_sp x2 */
static struct zxid_map* zxid_read_map(zxid_conf* cf, const char* sp_name_buf, const char* mapname)
{
  char* p;
  char* buf = read_all_alloc(cf->ctx, "read_aamap", 0, 0, "%s" ZXID_UID_DIR ".all/%s/.cf", cf->cpath,sp_name_buf);
  if (!buf)
    return 0;
  p = strstr(buf, mapname);
  if (!p) {
    ERR(".cf file does not contain AAMAP directive buf(%s)", buf);
    return 0;
  }
  if (p > buf && p[-1] == '#') {
    INFO(".cf file contains commented out AAMAP directive buf(%s)", buf);
    return 0;
  }
  p += strlen(mapname);
  return zxid_load_map(cf, 0, p);
}

/* Called by:  zxid_mk_usr_a7n_to_sp x4 */
static void zxid_read_ldif_attrs(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, const char* sp_name_buf, const char* uid, struct zxid_map* sp_aamap, struct zx_sa_AttributeStatement_s* at_stmt)
{
  char* buf = read_all_alloc(cf->ctx, "read_ldif_attrs", 0, 0,
			     "%s" ZXID_UID_DIR "%s/%s/.at", cf->cpath, uid, sp_name_buf);
  if (buf)
    zxid_add_ldif_attrs(cf, ses, meta, &at_stmt->gg, buf, "read_ldif_attrs", sp_aamap);
}

/*(i) Construct an assertion given user's attribute and bootstrap configuration.
 * This involves adding attributes in user's .bs/.at, SP specific .at, as well as
 * .all/.bs/.at and .all's SP specific attributes. The attributes are filtered
 * and converted according to global and SP specific AAMAP.
 * Finally the bootstrap EPRs are added.
 *
 * bs_lvl:: 0: DI (do not add any bs), 1: add all bootstraps at sso level,
 *     <= cf->bootstrap_level: add all boostraps, > cf->bootstrap_level: only add di BS. */

/* Called by:  a7n_test, zxid_add_fed_tok2epr, zxid_imreq, zxid_sso_issue_a7n */
zxid_a7n* zxid_mk_usr_a7n_to_sp(zxid_conf* cf, zxid_ses* ses, zxid_nid* nameid, zxid_entity* sp_meta, const char* sp_name_buf, int bs_lvl)
{
  struct zxid_map* sp_aamap;
  zxid_a7n* a7n;
  struct zx_sa_AttributeStatement_s* at_stmt;
  char dir[ZXID_MAX_DIR];

  D_INDENT("mka7n: ");
  D("sp_eid(%s)", sp_meta->eid);

  if (!cf->aamap)
    cf->aamap = zxid_read_map(cf, ".bs", "AAMAP=");
  if (!cf->aamap)
    cf->aamap = zxid_load_map(cf, 0, ZXID_DEFAULT_IDP_AAMAP);
  sp_aamap = zxid_read_map(cf, sp_name_buf, "AAMAP=");

  at_stmt = zx_NEW_sa_AttributeStatement(cf->ctx, 0);
  at_stmt->Attribute = zxid_mk_sa_attribute(cf, &at_stmt->gg, "zxididp", 0, ZXID_REL " " ZXID_COMPILE_DATE);

  a7n = zxid_mk_a7n(cf,
		    zx_dup_str(cf->ctx, sp_meta->eid),
		    zxid_mk_subj(cf, 0, sp_meta, nameid),
		    ses ? zxid_mk_an_stmt(cf, ses, 0, sp_meta->eid) : 0,
		    at_stmt);

  if (cf->fedusername_suffix && cf->fedusername_suffix[0]) {
    snprintf(dir, sizeof(dir), "%.*s@%s", ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid), cf->fedusername_suffix);
    dir[sizeof(dir)-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
    zxid_add_mapped_attr(cf, ses, sp_meta, &at_stmt->gg, "mk_usr_a7n_to_sp", sp_aamap, "fedusername", dir);
    if (cf->idpatopt & 0x01)
      zxid_add_mapped_attr(cf, ses, sp_meta, &at_stmt->gg, "mk_usr_a7n_to_sp", sp_aamap, "urn:oid:1.3.6.1.4.1.5923.1.1.1.6" /* eduPersonPrincipalName */, dir);
    //zxid_mk_sa_attribute(cf, &at_stmt->gg, "urn:oid:1.3.6.1.4.1.5923.1.1.1.6" /* eduPersonPrincipalName */, "urn:oasis:names:tc:SAML:2.0:attrname-format:uri", zx_dup_cstr(cf->ctx, dir));
  }

  /* Following idpsesid attribute risks exposing federation-wide temporary unique ID.
   * This is dangerous as it provides a correlation handle to participants of the
   * session that would otherwise just have had pairwise pseudonyms. Even the regular
   * session index is pariwise safe.
   * As this is dangerous to privacy, it is disabled in the default AAMAP. You need to
   * enable it explicitly in deployment specific AAMAP (in .all/.bs/.cf file) if you
   * want it. There you can also specify whether it will be wrapped in assertion. */
  if (ses && ses->sid && *ses->sid)
    zxid_add_mapped_attr(cf, ses, sp_meta, &at_stmt->gg, "mk_usr_a7n_to_sp", sp_aamap, "idpsesid", ses->sid);

  zxid_read_ldif_attrs(cf, ses, sp_meta, ".bs",       ses->uid, sp_aamap, at_stmt);
  zxid_read_ldif_attrs(cf, ses, sp_meta, sp_name_buf, ses->uid, sp_aamap, at_stmt);
  zxid_read_ldif_attrs(cf, ses, sp_meta, ".bs",       ".all",   sp_aamap, at_stmt);
  zxid_read_ldif_attrs(cf, ses, sp_meta, sp_name_buf, ".all",   sp_aamap, at_stmt);
  D("sp_eid(%s) bs_lvl=%d", sp_meta->eid, bs_lvl);
  
  /* Process bootstraps */

  name_from_path(dir, sizeof(dir), "%s" ZXID_UID_DIR "%s/.bs/", cf->cpath, ses->uid);
  zxid_gen_boots(cf, ses, at_stmt, dir, bs_lvl);
  
  name_from_path(dir, sizeof(dir), "%s" ZXID_UID_DIR ".all/.bs/", cf->cpath);
  zxid_gen_boots(cf, ses, at_stmt, dir, bs_lvl);
  
  D_DEDENT("mka7n: ");
  return a7n;
}

/*(i) Check federation, create federation if appropriate. */

/* Called by:  zxid_get_fed_nameid, zxid_imreq, zxid_nidmap_do */
zxid_nid* zxid_check_fed(zxid_conf* cf, struct zx_str* affil, const char* uid, char allow_create, struct timeval* srcts, struct zx_str* issuer, struct zx_str* req_id, const char* sp_name_buf)
{
  int got;
  char buf[ZXID_MAX_USER];
  char dir[ZXID_MAX_DIR];
  zxid_nid* nameid;
  struct zx_str* nid;
  struct zx_attr_s* idp_eid;

  got = read_all(sizeof(buf)-1, buf, "idpsso", 0, "%s" ZXID_UID_DIR "%s/%s/.mni" , cf->cpath, uid, sp_name_buf);

  if (!got) {
    if (allow_create == '1') {

      D_INDENT("allowcreate: ");
      
      name_from_path(dir, sizeof(dir), "%s" ZXID_UID_DIR "%s/%s", cf->cpath, uid, sp_name_buf);
      if (MKDIR(dir, 0777) && errno != EEXIST) {
	perror("mkdir for uid/sp fed");
	ERR("Creating uid/sp federation directory(%s) failed", dir);
	zxlog(cf, 0, srcts, 0, issuer, req_id, 0, 0, "N", "S", "EFILE", dir, "mkdir fail, permissions?");
	D_DEDENT("allowcreate: ");
	return 0;
      }
      
      nid = zxid_mk_id(cf, "F", ZXID_ID_BITS);
      nameid = zx_NEW_sa_NameID(cf->ctx,0);
      nameid->SPNameQualifier = zx_ref_len_attr(cf->ctx, &nameid->gg, zx_SPNameQualifier_ATTR, affil->len, affil->s);
      nameid->NameQualifier = idp_eid = zxid_my_ent_id_attr(cf,&nameid->gg,zx_NameQualifier_ATTR);
      nameid->Format = zx_ref_attr(cf->ctx, &nameid->gg, zx_Format_ATTR, SAML2_PERSISTENT_NID_FMT);
      zx_add_content(cf->ctx, &nameid->gg, nid);

      if (!write_all_path_fmt("put_fed", ZXID_MAX_USER, buf,
			      "%s%s", dir, "/.mni",
			      "%.*s|%.*s|%.*s|%.*s|",
			      sizeof(SAML2_PERSISTENT_NID_FMT), SAML2_PERSISTENT_NID_FMT,
			      idp_eid->g.len, idp_eid->g.s,
			      affil->len, affil->s,
			      nid->len, nid->s)) {
	zxlog(cf, 0, srcts, 0, issuer, req_id, 0, nid, "N", "S", "EFILE", uid, "put_fed fail, permissions?");
	D_DEDENT("allowcreate: ");
	return 0;
      }

      /* Create entry for reverse mapping from pseudonym nid to uid */

      name_from_path(dir, sizeof(dir), "%s" ZXID_NID_DIR "%s", cf->cpath, sp_name_buf);
      if (MKDIR(dir, 0777) && errno != EEXIST) {
	perror("mkdir for nid fed");
	ERR("Creating nid index directory(%s) failed", dir);
	zxlog(cf, 0, srcts, 0, issuer, req_id, 0, nid, "N", "S", "EFILE", dir, "mkdir fail, permissions?");
	D_DEDENT("allowcreate: ");
	return 0;
      }
      
      name_from_path(dir, sizeof(dir), "%s" ZXID_NID_DIR "%s/%.*s", cf->cpath, sp_name_buf, nid->len, nid->s);
      if (!write_all_path("put_nidmap", "%s", dir, 0, -1, uid)) {
	zxlog(cf, 0, srcts, 0, issuer, req_id, 0, nid, "N", "S", "EFILE", uid, "put_nidmap fail, permissions?");
	D_DEDENT("allowcreate: ");
	return 0;
      }
      
      zxlog(cf, 0, srcts, 0, issuer, req_id, 0, nid, "N", "K", "FEDNEW", uid, 0);
      D_DEDENT("allowcreate: ");

    } else {
      ERR("No federation for uid(%s) in affil(%.*s) and AllowCreate false %d", uid, affil->len, affil->s, allow_create);
      return 0;
    }
  } else {
    buf[got] = 0;
    nameid = zxid_parse_mni(cf, buf, 0);
    D("Old fed uid(%s) affil(%.*s) nid(%.*s)", uid, affil->len, affil->s, ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
  }

  if (!nameid) {
    ERR("No federation for affil(%.*s) and AllowCreate false %d", affil->len, affil->s, allow_create);
    return 0;
  }
  return nameid;
}

/*() Change NameID to be transient and record corresponding mapping. */

/* Called by:  zxid_get_fed_nameid x2, zxid_imreq x2, zxid_nidmap_do x2 */
void zxid_mk_transient_nid(zxid_conf* cf, zxid_nid* nameid, const char* sp_name_buf, const char* uid)
{
  struct zx_str* nid;
  char dir[ZXID_MAX_DIR];

  D_INDENT("mk_trans: ");
  nameid->Format = zx_ref_attr(cf->ctx, &nameid->gg, zx_Format_ATTR, SAML2_TRANSIENT_NID_FMT);
  zx_add_content(cf->ctx, &nameid->gg, (nid = zxid_mk_id(cf, "T", ZXID_ID_BITS)));
  
  /* Create entry for reverse mapping from pseudonym nid to uid */
  
  name_from_path(dir, sizeof(dir), "%s" ZXID_NID_DIR "%s", cf->cpath, sp_name_buf);
  if (MKDIR(dir, 0777) && errno != EEXIST) {
    perror("mkdir for nid tmp");
    ERR("Creating nid index directory(%s) failed", dir);
    zxlog(cf, 0, 0, 0, 0, 0, 0, nid, "N", "S", "EFILE", dir, "mkdir fail, permissions?");
    D_DEDENT("mk_trans: ");
    return;
  }
  
  name_from_path(dir, sizeof(dir), "%s" ZXID_NID_DIR "%s/%.*s", cf->cpath, sp_name_buf, nid->len, nid->s);
  if (!write_all_path("put_nidmap_tmp", "%s", dir, 0, -1, uid)) {
    zxlog(cf, 0, 0, 0, 0, 0, 0, nid, "N", "S", "EFILE", uid, "put_nidmap fail, permissions?");
    D_DEDENT("mk_trans: ");
    return;
  }
  
  /*zxlog(cf, 0, srcts, 0, issuer, req_id, 0, nid, "N", "K", "TMPNEW", uid, 0);*/
  D_DEDENT("mk_trans: ");
}

/*() Consider an EPR and user and generate the necessary access credential (SAML a7n).
 * The EPR, which the caller obtained by parsing XML, is modified in place by adding
 * the SecurityContext to the end of the kids list.
 * Returns 1 on success, 0 on failure. */

/* Called by:  zxid_di_query, zxid_gen_boots x2 */
int zxid_add_fed_tok2epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, int bs_lvl, char* logop)
{
  struct timeval srcts = {0,501000};
  zxid_nid* nameid;
  zxid_a7n* a7n;
  zxid_entity* sp_meta;
  struct zx_di_SecurityContext_s* sc;
  struct zx_str* prvid;
  struct zx_str* affil;
  char sp_name_buf[ZXID_MAX_SP_NAME_BUF];

  if (prvid = ZX_GET_CONTENT(epr->Metadata->ProviderID)) {
    sp_meta = zxid_get_ent_ss(cf, prvid);
    if (!sp_meta) {
      ERR("The metadata for provider could not be found or fetched. Reject. %d", 0);
      return 0;
    }
  } else {
    ERR("The EPR does not have ProviderID element. Reject. %d", 0);
    return 0;
  }
  
  affil = zxid_get_affil_and_sp_name_buf(cf, sp_meta, sp_name_buf);
  D("sp_name_buf(%s) ProviderID(%.*s) di_allow_create=%d", sp_name_buf, prvid->len, prvid->s, cf->di_allow_create);
  
  nameid = zxid_get_fed_nameid(cf, prvid, affil, ses->uid, sp_name_buf, cf->di_allow_create,
			       (cf->di_nid_fmt == 't'), &srcts, 0, logop);
  
  /* Generate access credential */
  
  a7n = zxid_mk_usr_a7n_to_sp(cf, ses, nameid, sp_meta, sp_name_buf, bs_lvl);
  
  if (!zxid_anoint_a7n(cf, cf->sso_sign & ZXID_SSO_SIGN_A7N, a7n, prvid, "DIA7N", ses->uid, 0)) {
    ERR("Failed to sign the assertion %d", 0);
    return 0;
  }
  
  if (!(sc = epr->Metadata->SecurityContext)) {
    epr->Metadata->SecurityContext = sc = zx_NEW_di_SecurityContext(cf->ctx, 0);
    zx_add_kid_before(&epr->Metadata->gg, ZX_TOK_NOT_FOUND, &sc->gg);
  }

  if (!sc->SecurityMechID) {
    sc->SecurityMechID = zx_dup_elem(cf->ctx, &sc->gg, zx_di_SecurityMechID_ELEM, WSF20_SEC_MECH_TLS_BEARER);
  }

  if (!sc->Token)
    sc->Token = zx_NEW_sec_Token(cf->ctx, &sc->gg);
  
  if (cf->di_a7n_enc) {
    sc->Token->EncryptedAssertion = zxid_mk_enc_a7n(cf, &sc->Token->gg, a7n, sp_meta);
  } else {
    sc->Token->Assertion = a7n;
    zx_add_kid(&sc->Token->gg, &a7n->gg);
  }
  zx_reverse_elem_lists(&sc->gg);
  return 1;
}

/*() Internal function, just to factor out some commonality between SSO and SSOS. */

/* Called by:  a7n_test, x509_test, zxid_idp_sso, zxid_ssos_anreq */
zxid_a7n* zxid_sso_issue_a7n(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct timeval* srcts, zxid_entity* sp_meta, struct zx_str* acsurl, zxid_nid** nameid, char* logop, struct zx_sp_AuthnRequest_s* ar)
{
  zxid_a7n* a7n;
  struct zx_sp_NameIDPolicy_s* nidpol;
  struct zx_sa_SubjectConfirmation_s* sc;
  struct zx_str* issuer;
  struct zx_str* affil;
  zxid_nid* tmpnameid;
  char sp_name_buf[ZXID_MAX_SP_NAME_BUF];
  D("sp_eid(%s)", sp_meta->eid);
  if (!nameid)
    nameid = &tmpnameid;

  if (ar && ar->IssueInstant && ar->IssueInstant->g.len && ar->IssueInstant->g.s)
    srcts->tv_sec = zx_date_time_to_secs(ar->IssueInstant->g.s);
  
  nidpol = ar ? ar->NameIDPolicy : 0;
  if (!cgi->allow_create && nidpol && nidpol->AllowCreate && nidpol->AllowCreate->g.s) {
    D("No allow_create from form, extract from SAMLRequest (%.*s) len=%d", nidpol->AllowCreate->g.len, nidpol->AllowCreate->g.s, nidpol->AllowCreate->g.len);
    cgi->allow_create = XML_TRUE_TEST(&nidpol->AllowCreate->g) ? '1':'0';
  }

  if ((!cgi->nid_fmt || !cgi->nid_fmt[0]) && nidpol && nidpol->Format && nidpol->Format->g.s) {
    D("No Name ID Format from form, extract from SAMLRequest (%.*s) len=%d", nidpol->Format->g.len, nidpol->Format->g.s, nidpol->Format->g.len);
    cgi->nid_fmt = nidpol->Format->g.len == sizeof(SAML2_TRANSIENT_NID_FMT)-1
      && !memcmp(nidpol->Format->g.s, SAML2_TRANSIENT_NID_FMT, sizeof(SAML2_TRANSIENT_NID_FMT)-1)
      ? "trnsnt" : "prstnt";
  }

  /* Check for federation. */
  
  issuer = ar ? ZX_GET_CONTENT(ar->Issuer) : 0;  /* *** must arrange AR issuer somehow */
  affil = nidpol && nidpol->SPNameQualifier ? &nidpol->SPNameQualifier->g : issuer;
  zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), affil, affil, 7);
  D("sp_name_buf(%s)  allow_create=%d", sp_name_buf, cgi->allow_create);

  *nameid = zxid_get_fed_nameid(cf, issuer, affil, ses->uid, sp_name_buf, cgi->allow_create,
				(cgi->nid_fmt && !strcmp(cgi->nid_fmt, "trnsnt")),
				srcts, ar?&ar->ID->g:0, logop);
  if (logop) { logop[3]='S';  logop[4]='S';  logop[5]='O';  logop[6]=0;  /* Patch in SSO */ }

  a7n = zxid_mk_usr_a7n_to_sp(cf, ses, *nameid, sp_meta, sp_name_buf, 1);  /* SSO a7n */

  /* saml-profiles-2.0-os.pdf ll.549-551 requires SubjectConfirmation even though
   * saml-core-2.0-os.pdf ll.653-657 says <SubjectConfirmation> [Zero or More]. The
   * profile seems to make it mandatory. See profiles ll.554-560. */

  a7n->Subject->SubjectConfirmation = sc = zx_NEW_sa_SubjectConfirmation(cf->ctx, 0);
  zx_add_kid_before(&a7n->Subject->gg, ZX_TOK_NOT_FOUND, &sc->gg);
  sc->Method = zx_ref_attr(cf->ctx, &sc->gg, zx_Method_ATTR, SAML2_BEARER);
  sc->SubjectConfirmationData = zx_NEW_sa_SubjectConfirmationData(cf->ctx, &sc->gg);
  if (acsurl)
    sc->SubjectConfirmationData->Recipient = zx_ref_len_attr(cf->ctx, &sc->SubjectConfirmationData->gg, zx_Recipient_ATTR, acsurl->len, acsurl->s);
  sc->SubjectConfirmationData->NotOnOrAfter
    = zx_ref_len_attr(cf->ctx, &sc->SubjectConfirmationData->gg, zx_NotOnOrAfter_ATTR, a7n->Conditions->NotOnOrAfter->g.len, a7n->Conditions->NotOnOrAfter->g.s);

  return a7n;
}

/*() Given uid, look up the idpnid (pairwise pseudonym) as seen by given SP (eid) */

char* zxid_get_idpnid_at_eid(zxid_conf* cf, const char* uid, const char* eid, int allow_create)
{
  zxid_nid* nameid;
  struct zx_str* affil;
  char sp_name_buf[ZXID_MAX_SP_NAME_BUF];
  affil = zx_dup_str(cf->ctx, eid);
  zxid_nice_sha1(cf, sp_name_buf, sizeof(sp_name_buf), affil, affil, 7);
  nameid = zxid_check_fed(cf, affil, uid, allow_create, 0, 0, 0, sp_name_buf);
  if (!nameid || !nameid->gg.g.len || !nameid->gg.g.s) {
    D("No nameid for uid(%s) eid(%s) allow_create(%d) %p", STRNULLCHK(uid), STRNULLCHK(eid), allow_create, nameid);
    return 0;
  }
  return zx_str_to_c(cf->ctx, &nameid->gg.g);
}

/*(i) Generate SSO assertion and ship it to SP by chosen binding. User has already
 * logged in by the time this is called. See also zxid_ssos_anreq()
 * and zxid_oauth2_az_server_sso() */

/* Called by:  zxid_idp_dispatch */
struct zx_str* zxid_idp_sso(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_AuthnRequest_s* ar)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  int binding = 0;
  struct zxsig_ref refs;
  zxid_entity* sp_meta;
  struct zx_str* acsurl = 0;
  struct zx_str tmpss;
  struct zx_str* ss;
  struct zx_str* payload;
  struct zx_str* logpath;
  struct timeval srcts = {0,501000};
  zxid_nid* nameid;
  zxid_a7n* a7n;
  struct zx_sp_Response_s* resp;
  struct zx_e_Envelope_s* e;
  char* p;
  char logop[8];
  strcpy(logop, "IDPxxxx");

  if (!ar || !ZX_GET_CONTENT(ar->Issuer)) {
    ERR("No Issuer found in AuthnRequest %p", ar);
    return zx_dup_str(cf->ctx, "* ERR");
  }

  sp_meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(ar->Issuer));
  if (!sp_meta) {
    ERR("The metadata for Issuer of the AuthnRequest could not be found or fetched %d", 0);
    return zx_dup_str(cf->ctx, "* ERR");
  }
  D("sp_eid(%s)", sp_meta->eid);

  /* Figure out the binding and url */

  if (ar->AssertionConsumerServiceIndex) {
    if (ar->ProtocolBinding || ar->AssertionConsumerServiceURL) {
      ERR("When SP specifies AssertionConsumerServiceIndex in AuthnRequest, it SHOULD NOT specify ProtocolBinding(%p) or AssertionConsumerServiceURL(%p). They are ignored. AssertionConsumerServiceIndex approach is the preferred approach.", ar->ProtocolBinding, ar->AssertionConsumerServiceURL);
    }
    acsurl = zxid_sp_loc_by_index_raw(cf, cgi, sp_meta, ZXID_ACS_SVC, &ar->AssertionConsumerServiceIndex->g, &binding);
  } else if (ar->ProtocolBinding) {
    p = zx_str_to_c(cf->ctx, &ar->ProtocolBinding->g);
    acsurl = zxid_sp_loc_raw(cf, cgi, sp_meta, ZXID_ACS_SVC, p, 0);
    ZX_FREE(cf->ctx, p);
    if (acsurl && ar->AssertionConsumerServiceURL) {
      if (acsurl->len != ar->AssertionConsumerServiceURL->g.len
	  || memcmp(acsurl->s, ar->AssertionConsumerServiceURL->g.s, acsurl->len)) {
	ERR("SECURITY/SPOOFING: SP specified in AuthnRequest an AssertionConsumerServiceURL(%.*s) but this does not agree with the metadata specified url(%.*s) for Binding(%.*s). SP would be better off using AssertionConsumerServiceIndex approach. The metadata is relied on and the AssertionConsumerServiceURL is ignored.", ar->AssertionConsumerServiceURL->g.len, ar->AssertionConsumerServiceURL->g.s, acsurl->len, acsurl->s, ar->ProtocolBinding->g.len, ar->ProtocolBinding->g.s);
      }
      binding = zxid_protocol_binding_map_saml2(&ar->ProtocolBinding->g);
    }
  }
  if (!acsurl) {
    D("AuthnRequest did not specify any ACS or binding. Using idp_pref_acs_binding(%s)", cf->idp_pref_acs_binding);
    acsurl = zxid_sp_loc_raw(cf, cgi, sp_meta, ZXID_ACS_SVC, cf->idp_pref_acs_binding, 0);
    if (acsurl) {
      tmpss.len = strlen(cf->idp_pref_acs_binding);
      tmpss.s = cf->idp_pref_acs_binding;
      binding = zxid_protocol_binding_map_saml2(&tmpss);
    } else {
      D("Preferred binding not supported by SP metadata, using first ACS entry from metadata %d", 0);
      if (!sp_meta->ed || !sp_meta->ed->SPSSODescriptor || !sp_meta->ed->SPSSODescriptor->AssertionConsumerService || !sp_meta->ed->SPSSODescriptor->AssertionConsumerService->Location) {
	ERR("SP metadata does not contain any AssertionConsumerService. Can not complete SSO (SP metadata problem) %d", 0);
	return zx_dup_str(cf->ctx, "* ERR");
      }
      acsurl = &sp_meta->ed->SPSSODescriptor->AssertionConsumerService->Location->g;
      binding = zxid_protocol_binding_map_saml2(&sp_meta->ed->SPSSODescriptor->AssertionConsumerService->Binding->g);
    }
  }

  /* User ses->uid is already logged in, now check for federation with sp */

  a7n = zxid_sso_issue_a7n(cf, cgi, ses, &srcts, sp_meta, acsurl, &nameid, logop, ar);
  
  /* Sign, encrypt, and ship the assertion according to the binding. */
  
  switch (binding) {
  case 'e':
    D("SAML2 PAOS ep(%.*s)", acsurl->len, acsurl->s);
    
    if (cf->sso_sign & ZXID_SSO_SIGN_A7N) {
      ZERO(&refs, sizeof(refs));
      refs.id = &a7n->ID->g;
      refs.canon = zx_easy_enc_elem_sig(cf, &a7n->gg);
      if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "use sign cert paos")) {
	a7n->Signature = zxsig_sign(cf->ctx, 1, &refs, sign_cert, sign_pkey, cf->xmldsig_sig_meth, cf->xmldsig_digest_algo);
	zx_add_kid_after_sa_Issuer(&a7n->gg, &a7n->Signature->gg);
      }
    }
    resp = zxid_mk_saml_resp(cf, a7n, cf->post_a7n_enc?sp_meta:0);
    payload = zxid_anoint_sso_resp(cf, cf->sso_sign & ZXID_SSO_SIGN_RESP, resp, ar);
    if (!payload)
      return zx_dup_str(cf->ctx, "* ERR");
    zx_str_free(cf->ctx, payload);

    /* Generate SOAP envelope with ECP header */

    e = zx_NEW_e_Envelope(cf->ctx,0);

    e->Header = zx_NEW_e_Header(cf->ctx, &e->gg);
    e->Header->ecp_Response = zx_NEW_ecp_Response(cf->ctx, &e->Header->gg);
    e->Header->ecp_Response->mustUnderstand = zx_dup_attr(cf->ctx, &e->Header->ecp_Response->gg, zx_e_mustUnderstand_ATTR, "1");
    e->Header->ecp_Response->actor = zx_ref_attr(cf->ctx, &e->Header->ecp_Response->gg, zx_e_actor_ATTR, SOAP_ACTOR_NEXT);
    e->Header->ecp_Response->AssertionConsumerServiceURL = zx_ref_len_attr(cf->ctx, &e->Header->ecp_Response->gg, zx_AssertionConsumerServiceURL_ATTR, acsurl->len, acsurl->s);

    e->Body = zx_NEW_e_Body(cf->ctx, &e->gg);
    e->Body->Response = resp;
    
    ss = zx_easy_enc_elem_opt(cf, &e->gg);

    zxlog(cf, 0, &srcts, 0, ZX_GET_CONTENT(ar->Issuer), 0, &a7n->ID->g, ZX_GET_CONTENT(nameid), "N", "K", logop, ses->uid, "PAOS2");


    /* *** Check what HTTP level headers PAOS needs */
    return zx_strf(cf->ctx, "Content-type: text/xml\r\nContent-Length: %d\r\n%s%s%s\r\n%.*s",
		   ss->len,
		   ses->setcookie?"Set-Cookie: ":"", ses->setcookie?ses->setcookie:"", ses->setcookie?"\r\n":"",
		   ss->len, ss->s);

  case 'q':
    D("SAML2 BRWS-POST-SIMPLE-SIGN ep(%.*s)", acsurl->len, acsurl->s);

    if (!zxid_anoint_a7n(cf, cf->sso_sign & ZXID_SSO_SIGN_A7N_SIMPLE, a7n, ZX_GET_CONTENT(ar->Issuer), "SSOA7N", ses->uid, 0))
      return zx_dup_str(cf->ctx, "* ERR");
    resp = zxid_mk_saml_resp(cf, a7n, cf->post_a7n_enc?sp_meta:0);
    payload = zxid_anoint_sso_resp(cf, 0, resp, ar);
    if (!payload)
      return zx_dup_str(cf->ctx, "* ERR");
    ss = zxid_saml2_post_enc(cf, "SAMLResponse", payload, cgi->rs, 1, acsurl);
    zx_str_free(cf->ctx, payload);
    if (!ss)
      return zx_dup_str(cf->ctx, "* ERR");

    zxlog(cf, 0, &srcts, 0, ZX_GET_CONTENT(ar->Issuer), 0, &a7n->ID->g, ZX_GET_CONTENT(nameid), "N", "K", logop, ses->uid, "SIMPSIG");

    return zx_strf(cf->ctx, "Content-type: text/html\r\nContent-Length: %d\r\n%s%s%s\r\n%.*s",
		   ss->len,
		   ses->setcookie?"Set-Cookie: ":"", ses->setcookie?ses->setcookie:"", ses->setcookie?"\r\n":"",
		   ss->len, ss->s);

  case 'p':
    D("SAML2 BRWS-POST ep(%.*s)", acsurl->len, acsurl->s);

    if (!zxid_anoint_a7n(cf, cf->sso_sign & ZXID_SSO_SIGN_A7N, a7n, ZX_GET_CONTENT(ar->Issuer), "SSOA7N", ses->uid, 0))
      return zx_dup_str(cf->ctx, "* ERR");
    resp = zxid_mk_saml_resp(cf, a7n, cf->post_a7n_enc?sp_meta:0);
    payload = zxid_anoint_sso_resp(cf, cf->sso_sign & ZXID_SSO_SIGN_RESP, resp, ar);
    if (!payload)
      return zx_dup_str(cf->ctx, "* ERR");
    
    ss = zxid_saml2_post_enc(cf, "SAMLResponse", payload, cgi->rs, 0, acsurl);
    zx_str_free(cf->ctx, payload);
    if (!ss)
      return zx_dup_str(cf->ctx, "* ERR");
    
    zxlog(cf, 0, &srcts, 0, ZX_GET_CONTENT(ar->Issuer), 0, &a7n->ID->g, ZX_GET_CONTENT(nameid), "N", "K", logop, ses->uid, "BRWS-POST");
    
    return zx_strf(cf->ctx, "Content-type: text/html\r\nContent-Length: %d\r\n%s%s%s\r\n%.*s",
		   ss->len,
		   ses->setcookie?"Set-Cookie: ":"", ses->setcookie?ses->setcookie:"", ses->setcookie?"\r\n":"",
		   ss->len, ss->s);
    
  case 'a':
    D("SAML2 BRWS-ART ep(%.*s)", acsurl->len, acsurl->s);

    if (!cf->log_issue_a7n) {
      INFO("LOG_ISSUE_A7N must be turned on in IdP configuration for artifact profile to work. Turning on now automatically. %d", 0);
      cf->log_issue_a7n = 1;
    }
    if (!zxid_anoint_a7n(cf, cf->sso_sign & ZXID_SSO_SIGN_A7N, a7n, ZX_GET_CONTENT(ar->Issuer), "SSOA7N", ses->uid, &logpath))
      return zx_dup_str(cf->ctx, "* ERR");
    resp = zxid_mk_saml_resp(cf, a7n, 0);
    payload = zxid_anoint_sso_resp(cf, cf->sso_sign & ZXID_SSO_SIGN_RESP, resp, ar);
    if (!payload)
      return zx_dup_str(cf->ctx, "* ERR");
    
    //ss = zxid_saml2_post_enc(cf, "SAMLResponse", pay_load, ar->RelayState);  *** redirect
    /* *** Do artifact processing: artifact can be the file name in /var/zxid/idplog/issue/SPEID/art/ */

    ERR("Trying to use SAML2 Artifact Binding, but code not fully implemented. %d", 0);

    zxlog(cf, 0, &srcts, 0, ZX_GET_CONTENT(ar->Issuer), 0, &a7n->ID->g, ZX_GET_CONTENT(nameid), "N", "K", logop, ses->uid, "BRWS-ART");

    ss = zx_strf(cf->ctx, "Location: %.*s%c"
		 "SAMLResponse=%.*s" CRLF
		 "%s%s%s",   /* Set-Cookie */
		 acsurl->len, acsurl->s, (memchr(acsurl->s, '?', acsurl->len) ? '&' : '?'),
		 payload->len, payload->s,
		 (ses->setcookie?"Set-Cookie: ":""), (ses->setcookie?ses->setcookie:""), (ses->setcookie?CRLF:""));
    zx_str_free(cf->ctx, payload);
    return ss;
    
  default:
    NEVER("Unknown or unsupported binding %d", binding);
  }

  return zx_dup_str(cf->ctx, "* ERR");
}

/*() ID-WSF Authentication Service: check password and emit bootstrap(s)
 * To generate the data, use:
 *   perl -MMIME::Base64 -e 'print encode_base64("\0user\0pw\0")'
 *   perl -MMIME::Base64 -e 'print encode_base64("\0tastest\0tas123\0")'
 * See also: zxid_as_call_ses()
 */

/* Called by:  zxid_sp_soap_dispatch */
struct zx_as_SASLResponse_s* zxid_idp_as_do(zxid_conf* cf, struct zx_as_SASLRequest_s* req)
{
  zxid_cgi cgi;
  zxid_ses sess;
  struct zx_as_SASLResponse_s* res = zx_NEW_as_SASLResponse(cf->ctx,0);
  struct zx_sa_AttributeStatement_s* at_stmt;
  struct zx_sa_Attribute_s* at;
  struct zx_sa_Attribute_s* at_next;
  char* q;
  char* u;
  char* p;
  char buf[1024];
  char path[ZXID_MAX_BUF];

  ZERO(&cgi, sizeof(zxid_cgi));
  ZERO(&sess, sizeof(zxid_ses));

  if (SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(ZX_GET_CONTENT_LEN(req->Data)) >= sizeof(buf)-1) {
    ERR("Too long username and password %p. limit=%d", ZX_GET_CONTENT(req->Data), (int)sizeof(buf)-1);
    res->Status = zxid_mk_lu_Status(cf, &res->gg, "ERR", 0, 0, 0);
    return res;
  }
  q = unbase64_raw(ZX_GET_CONTENT_S(req->Data), ZX_GET_CONTENT_S(req->Data) + ZX_GET_CONTENT_LEN(req->Data), buf, zx_std_index_64);
  *q = 0;
  for (u = buf; *u && u < q; ++u) ;  /* skip initial */
  for (p = ++u; *p && p < q; ++p) ;
  ++p;
  cgi.uid = u;
  cgi.pw = p;

  if (zxid_pw_authn(cf, &cgi, &sess)) {
    D_INDENT("as: ");
    at_stmt = zx_NEW_sa_AttributeStatement(cf->ctx, 0 /* Do not attach */);
    name_from_path(path, sizeof(path), "%s" ZXID_UID_DIR "%s/.bs/", cf->cpath, cgi.uid);
    zxid_gen_boots(cf, &sess, at_stmt, path, 1);
    name_from_path(path, sizeof(path), "%s" ZXID_UID_DIR ".all/.bs/", cf->cpath);
    zxid_gen_boots(cf, &sess, at_stmt, path, 1);

    /* Kludgy extraction of the EPRs from the attributes. */

    at = at_stmt->Attribute;
    if (at) {
      res->EndpointReference = at->AttributeValue->EndpointReference;
      D("TRANSMIT EPR to res %p %p", res->EndpointReference, res->EndpointReference->gg.g.n);
      for (; at; at = at_next) {
	if (at->AttributeValue->EndpointReference) {
	  D("TRANSMIT ANOTHER EPR to res %p %p", at->AttributeValue->EndpointReference, at->AttributeValue->EndpointReference->gg.g.n);
	  zx_add_kid(&res->gg, &at->AttributeValue->EndpointReference->gg);
	} else {
	  D("NO EPR %p", at->AttributeValue->EndpointReference);
	}
	at_next = (struct zx_sa_Attribute_s*)at->gg.g.n;
	ZX_FREE(cf->ctx, at);
      }
    }
    ZX_FREE(cf->ctx, at_stmt);
    res->Status = zxid_mk_lu_Status(cf, &res->gg, "OK", 0, 0, 0);
    /*zx_reverse_elem_lists(&res->gg); already built right */
    D_DEDENT("as: ");
  } else {
    ERR("Authentication failed uid(%s) pw(%s)", cgi.uid, cgi.pw);
    res->Status = zxid_mk_lu_Status(cf, &res->gg, "ERR", 0, 0, 0);
  }
  return res;
}

/* EOF  --  zxidpsso.c */
