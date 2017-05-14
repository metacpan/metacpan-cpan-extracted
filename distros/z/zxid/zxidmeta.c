/* zxidmeta.c  -  Handwritten functions for metadata parsing and generation as well as CoT handling
 * Copyright (c) 2012 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidmeta.c,v 1.59 2009-11-24 23:53:40 sampo Exp $
 *
 * The CoT cache exists both on disk as directory /var/zxid/cot and in
 * memory as the field cf->cot. The latter is protected by cf->mx lock.
 * The entities in cache are essentially read only, i.e. once the head
 * of the list cf->cot has been dereferenced in a thread safe way,
 * the entity pointers themselves can be passed around threads with
 * impunity. No locking needed for them.
 *
 * 12.8.2006,  created --Sampo
 * 12.10.2007, mild refactoring to process keys for xenc as well. --Sampo
 * 13.12.2007, fixed missing KeyDescriptor/@use as seen in CA IdP metadata --Sampo
 * 14.4.2008,  added SimpleSign --Sampo
 * 7.10.2008,  added documentation --Sampo
 * 1.2.2010,   removed arbitrary size limit --Sampo
 * 12.2.2010,  added pthread locking --Sampo
 * 17.2.2011,  fixed processing of whitespace in metadata --Sampo
 * 10.12.2011, added OAuth2, OpenID Connect, and UMA support --Sampo
 * 11.12.2011, added OrganizationURL support per symlabs-saml-displayname-2008.pdf submitted to OASIS SSTC --Sampo
 * 6.2.2012,   corrected the OrganizationURL to be absolute --Sampo
 */

#include "platform.h"  /* for dirent.h */

#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef USE_OPENSSL
#include <openssl/sha.h>
#include <openssl/x509.h>
#include <openssl/rsa.h>
#endif

#include "errmac.h"
#include "saml2.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* ============== CoT and Metadata of Others ============== */

/*() Process certificates (public keys) from a metadata for entity.
 * Since one entity can be both IdP and SP, this function may
 * be called twice per entity, with different kd argument. */

/* Called by:  zxid_mk_ent x2 */
static void zxid_process_keys(zxid_conf* cf, zxid_entity* ent, struct zx_md_KeyDescriptor_s* kd, const char* logkey)
{
  int len;
  char* pp;
  char* p;
  char* e;
  X509* x;

  for (; kd; kd = (struct zx_md_KeyDescriptor_s*)kd->gg.g.n) {
    if (kd->gg.g.tok != zx_md_KeyDescriptor_ELEM)
      continue;
    if (!kd->KeyInfo || !kd->KeyInfo->X509Data || !ZX_GET_CONTENT(kd->KeyInfo->X509Data->X509Certificate)) {
      ERR("KeyDescriptor for %s missing essential subelements KeyInfo=%p", logkey, kd->KeyInfo);
      return;
    }
    p = ZX_GET_CONTENT_S(kd->KeyInfo->X509Data->X509Certificate);
    len = ZX_GET_CONTENT_LEN(kd->KeyInfo->X509Data->X509Certificate);
    e = p + len;
    pp = ZX_ALLOC(cf->ctx, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(e-p));
    e = unbase64_raw(p, e, pp, zx_std_index_64);
    x = 0;  /* Forces d2i_X509() to alloc the memory. */
    if (!d2i_X509(&x, (const unsigned char**)&pp /* *** compile warning */, e-pp) || !x) {
      ERR("DER decoding of X509 certificate for %s failed. use(%.*s)", logkey, kd->use->g.len, kd->use->g.s);
      D("Extracted %s base64 form of cert(%.*s)", logkey, len, p);
      return;
    }
    if (!kd->use) {
      ent->sign_cert = x;
      ent->enc_cert = x;
      D("KeyDescriptor is missing use attribute. Assume this certificate can be used for both signing and encryption. %d", 0);
      return;
    }
    if (!memcmp("signing", kd->use->g.s, kd->use->g.len)) {
      ent->sign_cert = x;
      DD("Extracted %s sign cert(%.*s)", logkey, len, p);
    } else if (!memcmp("encryption", kd->use->g.s, kd->use->g.len)) {
      ent->enc_cert = x;
      DD("Extracted %s enc cert(%.*s)", logkey, len, p);
    } else {
      ERR("Unknown key use(%.*s) Assume certificate can be used for both signing and encryption.", kd->use->g.len, kd->use->g.s);
      D("Extracted %s cert(%.*s)", logkey, len, p);
      ent->sign_cert = x;
      ent->enc_cert = x;
    }
  }
}

/*() Helper to create EntityDescriptor */

/* Called by:  zxid_parse_meta x2 */
static zxid_entity* zxid_mk_ent(zxid_conf* cf, struct zx_md_EntityDescriptor_s* ed)
{
  struct zx_str* val;
  zxid_entity* ent = ZX_ZALLOC(cf->ctx, zxid_entity);
  ent->ed = ed;
  if (!ed->entityID)
    goto bad_md;
  ent->eid = zx_str_to_c(cf->ctx, &ed->entityID->g);
  sha1_safe_base64(ent->sha1_name, ed->entityID->g.len, ent->eid);
  ent->sha1_name[27] = 0;
  
  if (ed->Organization) {  /* see symlabs-saml-displayname-2008.pdf submitted to OASIS SSTC */
    if (val = ZX_GET_CONTENT(ed->Organization->OrganizationDisplayName))
      ent->dpy_name = zx_str_to_c(cf->ctx, val);
    if (val = ZX_GET_CONTENT(ed->Organization->OrganizationURL)) {
      if (     zx_memmem(val->s, val->len, "saml2_icon", sizeof("saml2_icon")-1)) {
	if (   !zx_memmem(val->s, val->len, "saml2_icon_468x60", sizeof("saml2_icon_468x60")-1)
	    && !zx_memmem(val->s, val->len, "saml2_icon_150x60", sizeof("saml2_icon_150x60")-1)
	    && !zx_memmem(val->s, val->len, "saml2_icon_16x16",  sizeof("saml2_icon_16x16")-1))
	  ERR("OrganizationURL has to specify button image and the image filename MUST contain substring \"saml2_icon\" in it (see symlabs-saml-displayname-2008.pdf submitted to OASIS SSTC). Furthermore, this substring must specify the size, which must be one of 468x60, 150x60, or 16x16. Acceptable substrings are are \"saml2_icon_468x60\", \"saml2_icon_150x60\", \"saml2_icon_16x16\", e.g. \"https://example.com/example-brand-saml2_icon_150x60.png\". Current value(%.*s) may be used despite this error. The preferred size is \"%s\". Only last acceptable specification of OrganizationURL will be used.", val->len, val->s, cf->pref_button_size);
	if (!ent->button_url      /* Pref overrides previous. */
	    || !zx_memmem(val->s, val->len, cf->pref_button_size, strlen(cf->pref_button_size)))
	  ent->button_url = zx_str_to_c(cf->ctx, val);
      } else
	ERR("OrganizationURL SHOULD specify user interface button image and the image filename MUST contain substring \"saml2_icon\" in it. Current value(%.*s) is not usable and will be ignored. See symlabs-saml-displayname-2008.pdf, submitted to OASIS SSTC.", val->len, val->s);
    }
  }
  
  if (ed->IDPSSODescriptor)
    zxid_process_keys(cf, ent, ed->IDPSSODescriptor->KeyDescriptor, "IDP SSO");
  if (ed->SPSSODescriptor)
    zxid_process_keys(cf, ent, ed->SPSSODescriptor->KeyDescriptor, "SP SSO");

  if (!ent->sign_cert && !ent->enc_cert) {
    ERR("Metadata did not have any certificates! Incomplete metadata? %d",0);
  } else if (!ent->sign_cert) {
    INFO("Metadata only had encryption certificate. Using it for signing as well. %d", 0);
    ent->sign_cert = ent->enc_cert;
  } else if (!ent->enc_cert) {
    INFO("Metadata only had signing certificate. Using it for encryption as well. %d", 0);
    ent->enc_cert = ent->sign_cert;
  }

  return ent;
 bad_md:
  ERR("Bad metadata. EntityDescriptor was corrupt. %d", 0);
  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "BADMD", 0, "");
  return 0;
}

/*() Parse Metadata, see [SAML2meta]. This function is quite low level
 * and assumes it is processing a buffer (which may contain multiple
 * instances of various metadata).
 *
 * cf:: ZXID configuration object, used here mainly for memory allocation
 * md:: Value-result parameter. Pointer to char pointer pointing to the
 *     beginning of the metadata. As metadata is scanned and parsed, this
 *     pointer will be advanced
 * lim:: End of the metadata buffer
 * return:: Entity data structure composed from the metadata. If more than
 *     one EntityDescriptor is found, then a linked list is returned. */

/* Called by:  zxid_addmd, zxid_get_ent_file, zxid_get_meta, zxid_lscot_line */
zxid_entity* zxid_parse_meta(zxid_conf* cf, char** md, char* lim)
{
  zxid_entity* ee;
  zxid_entity* ent;
  struct zx_md_EntityDescriptor_s* ed;
  struct zx_root_s* r;

  r = zx_dec_zx_root(cf->ctx, lim-*md, *md, "parse meta");  /* *** n_decode=5 */
  *md = (char*)cf->ctx->p;
  if (!r)
    return 0;
  if (r->EntityDescriptor) {
    ed = r->EntityDescriptor;
    ZX_FREE(cf->ctx, r);  /* N.B Shallow free only, do not free the descriptor. */
    return zxid_mk_ent(cf, ed);
  } else if (r->EntitiesDescriptor) {
    if (!r->EntitiesDescriptor->EntityDescriptor)
      goto bad_md;
    ee = 0;
    for (ed = r->EntitiesDescriptor->EntityDescriptor;
	 ed;
	 ed = (struct zx_md_EntityDescriptor_s*)ZX_NEXT(ed)) {
      if (ed->gg.g.tok != zx_md_EntityDescriptor_ELEM)
	continue;
      ent = zxid_mk_ent(cf, ed);
      ent->n = ee;
      ee = ent;
    }
    ZX_FREE(cf->ctx, r->EntitiesDescriptor);
    ZX_FREE(cf->ctx, r);  /* N.B Shallow free only, do not free the descriptors. */
    return ee;
  }
 bad_md:
  ERR("Bad metadata. EntityDescriptor could not be found or was corrupt. MD(%.*s) %d chars parsed.", ((int)(lim-cf->ctx->bas)), cf->ctx->bas, ((int)(*md - cf->ctx->bas)));
  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "BADMD", 0, "chars_parsed(%d)", ((int)(*md - cf->ctx->bas)));
  zx_free_elem(cf->ctx, &r->gg, 0);
  return 0;
}

/*() Write metadata of an entity to the Circle of Trust (CoT) cache of
 * the entity identified by cf. Mainly used by Auto-CoT. */

/* Called by:  opt x3, zxid_get_ent_ss */
int zxid_write_ent_to_cache(zxid_conf* cf, zxid_entity* ent)
{
  struct zx_str* ss;
  fdtype fd = open_fd_from_path(O_CREAT | O_WRONLY | O_TRUNC, 0666, "write_ent_to_cache", 1, "%s" ZXID_COT_DIR "%s", cf->cpath, ent->sha1_name);
  if (fd == BADFD) {
    perror("open metadata for writing metadata to cache");
    ERR("Failed to open file for writing: sha1_name(%s) to metadata cache", ent->sha1_name);
    return 0;
  }
  
  ss = zx_easy_enc_elem_opt(cf, &ent->ed->gg);
  if (!ss)
    return 0;
  write_all_fd(fd, ss->s, ss->len);
  zx_str_free(cf->ctx, ss);
  close_file(fd, (const char*)__FUNCTION__);
  return 1;
}

/*() Read metadata from a file.
 *
 * Usually the file will be named according to "sha1 name", which
 * is safe base64 encoded SHA1 digest hash over the EntityID. This
 * is used to ensure unique file name for each entity. However,
 * this function will in fact read from any file name supplied.
 * If the file contains multiple EntityDescriptor elements, they
 * are all added to the cot. Also EntitiesDesciptor is handled.
 *
 * See also zxid_get_ent_cache() which will compute the sha1_name
 * and then read the metadata. */

/* Called by:  covimp_test, main x3, test_ibm_cert_problem_enc_dec, zxid_get_ent_by_sha1_name, zxid_get_ent_cache, zxid_load_cot_cache_from_file */
zxid_entity* zxid_get_ent_file(zxid_conf* cf, const char* sha1_name, const char* logkey)
{
  int n, got, siz;
  fdtype fd;
  char* md_buf;
  char* p;
  zxid_entity* first = 0;
  zxid_entity* ent;
  zxid_entity* ee;

  DD("sha1_name(%s)", sha1_name);
  fd = open_fd_from_path(O_RDONLY, 0, logkey, 1, "%s" ZXID_COT_DIR "%s", cf->cpath, sha1_name);
  if (fd == BADFD) {
    perror("open metadata to read");
    D("No metadata file found for sha1_name(%s)", sha1_name);
    return 0;
  }
  siz = get_file_size(fd);
  md_buf = ZX_ALLOC(cf->ctx, siz+1);
  n = read_all_fd(fd, md_buf, siz, &got);
  DD("==========sha1_name(%s)", sha1_name);
  if (n == -1)
    goto readerr;
  close_file(fd, (const char*)__FUNCTION__);

  if (got <= 20) {
    ERR("%s: Metadata found is too short, only %d bytes. sha1_name(%s) md_buf(%.*s)", logkey, got, sha1_name, got, md_buf);
    return 0;
  }
  DD("md_buf(%.*s) got=%d siz=%d sha1_name(%s)", got, md_buf, got, siz, sha1_name);
  
  p = md_buf;
  while (p < md_buf+got) {   /* Loop over concatenated descriptors. */
    ent = zxid_parse_meta(cf, &p, md_buf+got);
    if (!first)
      first = ent;
    DD("++++++++++++sha1_name(%s)", sha1_name);
    if (!ent) {
      ZX_FREE(cf->ctx, md_buf);
      ERR("%s: ***** Parsing metadata failed for sha1_name(%s)", logkey, sha1_name);
      return first;
    }
    LOCK(cf->mx, "add ent to cot");
    while (ent) {
      ee = ent->n;
      ent->n = cf->cot;
      cf->cot = ent;
      ent = ee;
    }
    UNLOCK(cf->mx, "add ent to cot");
    D("GOT META sha1_name(%s) eid(%s)", sha1_name, ent?ent->eid:"?");
  }
  return first;

readerr:
  perror("read metadata");
  D("%s: Failed to read metadata for sha1_name(%s)", logkey, sha1_name);
  close_file(fd, (const char*)__FUNCTION__);
  return 0;
}

/*LOCK_STATIC(zxid_ent_cache_mx);*/
extern struct zx_lock zxid_ent_cache_mx;

/* Called by:  zxid_get_ent_cache, zxid_load_cot_cache */
static void zxid_load_cot_cache_from_file(zxid_conf* cf)
{
  zxid_entity* ee;  
  if (!cf->load_cot_cache)
    return;
  LOCK(zxid_ent_cache_mx, "get ent from cache");
  LOCK(cf->mx, "check cot");
  ee = cf->cot;
  UNLOCK(cf->mx, "check cot");
  if (!ee) {
    D("Loading cot cache from(%s)", cf->load_cot_cache);
    zxid_get_ent_file(cf, cf->load_cot_cache, "load_cot_cache_from_file");
    D("CoT cache loaded from(%s)", cf->load_cot_cache);
  }
  UNLOCK(zxid_ent_cache_mx, "get ent from cache");
}

/*() Search cot datastructure by entity id. Failing to find,
 * compute sha1_name for an entity and then read the metadata from
 * the CoT metadata cache directory, e.g. /var/zxid/cot */

/* Called by:  main x5, zxid_get_ent_ss x3 */
zxid_entity* zxid_get_ent_cache(zxid_conf* cf, struct zx_str* eid)
{
  zxid_entity* ent;
  char sha1_name[28];
  char logkey[256];
  
  zxid_load_cot_cache_from_file(cf);
  for (ent = cf->cot; ent; ent = ent->n)  /* Check in memory cache. */
    if (eid->len == strlen(ent->eid) && !memcmp(eid->s, ent->eid, eid->len)) {
      D("GOT FROM MEM eid(%s)", ent->eid);
      return ent;
    }
  sha1_safe_base64(sha1_name, eid->len, eid->s);
  sha1_name[27] = 0;

  snprintf(logkey, sizeof(logkey)-1, "get_ent_cache EntityID(%.*s)", eid->len, eid->s);
  logkey[sizeof(logkey)-1] = 0;
  return zxid_get_ent_file(cf, sha1_name, logkey);
}

/*(i) Get metadata for entity, either from cache or network (using WKL), depending
 * on configuration options. Main work horse for getting entity metadata.
 *
 * cf:: ZXID configuration object
 * eid:: Entity ID whose metadata is desired
 * return:: Entity data structure, including the metadata */

/* Called by: */
zxid_entity* zxid_get_ent_ss(zxid_conf* cf, struct zx_str* eid)
{
  zxid_entity* old_cot;
  zxid_entity* ent;
  zxid_entity* ee;
  zxid_entity* match = 0;
  
  D("eid(%.*s) path(%.*s) cf->magic=%x, md_cache_first(%d), cot(%p)", eid->len, eid->s, cf->cpath_len, cf->cpath, cf->magic, cf->md_cache_first, cf->cot);
  if (cf->md_cache_first) {
    ent = zxid_get_ent_cache(cf, eid);
    if (ent)
      return ent;
  }
  
  if (cf->md_fetch) {
    ent = zxid_get_meta_ss(cf, eid);
    if (ent) {
      LOCK(cf->mx, "read cot");
      old_cot = cf->cot;
      UNLOCK(cf->mx, "read cot");
      while (ent) {
	if (eid->len == strlen(ent->eid) && !memcmp(eid->s, ent->eid, eid->len)) {
	  match = ent;
	}
	/* Check whether entity is already in the cache. */
	if (zxid_get_ent_cache(cf, &ent->ed->entityID->g)) {
	  INFO("While fetching metadata for eid(%.*s) got metadata for eid(%s), but the metadata was already in the cache. NEW METADATA IGNORED.", eid->len, eid->s, ent->eid);
	  ent = ent->n;
	} else {
	  INFO("While fetching metadata for eid(%.*s) got metadata for eid(%s). New metadata cached.", eid->len, eid->s, ent->eid);
	  ee = ent->n;
	  LOCK(cf->mx, "add fetched ent to cot");
	  ent->n = cf->cot;
	  cf->cot = ent;
	  UNLOCK(cf->mx, "add fetched ent to cot");
	  ent = ee;
	}
      }
      
      if (cf->md_populate_cache) {
	LOCK(cf->mx, "read cot");
	ent = cf->cot;
	UNLOCK(cf->mx, "read cot");
	for (; ent != old_cot; ent = ent->n)
	  zxid_write_ent_to_cache(cf, ent);
      }
      if (match)
	return match;
    }
  }
  
  if (cf->md_cache_last) {
    ent = zxid_get_ent_cache(cf, eid);
    if (ent)
      return ent;
  }
  D("eid(%.*s) NOT FOUND", eid->len, eid->s);
  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "NOMD", 0, "eid(%.*s)", eid->len, eid->s);
  return 0;
}

/*() Wrapper for zxid_get_ent_ss(), which see. */

/* Called by:  hi_vfy_peer_ssl_cred, zxbus_verify_receipt, zxcall_main, zxid_cdc_check x2, zxid_oauth2_az_server_sso, zxid_simple_idp_show_an, zxid_start_sso_url */
zxid_entity* zxid_get_ent(zxid_conf* cf, const char* eid)
{
  struct zx_str ss;
  if (!eid)
    return 0;
  ss.s = (char*)eid;
  ss.len = strlen(eid);
  DD("eid: (%s)", eid);
  return zxid_get_ent_ss(cf, &ss);
}

/*() Given sha1_name, check in memory cache and if not, the disk cache. Do not try net (WKL). */

/* Called by:  zxid_get_ent_by_succinct_id, zxid_load_cot_cache */
zxid_entity* zxid_get_ent_by_sha1_name(zxid_conf* cf, char* sha1_name)
{
  zxid_entity* ent;
  LOCK(cf->mx, "scan cache by sha1_name");
  for (ent = cf->cot; ent; ent = ent->n)  /* Check in-memory cache. */
    if (!strcmp(sha1_name, ent->sha1_name)) {
      UNLOCK(cf->mx, "scan cache by sha1_name");
      return ent;
    }
  UNLOCK(cf->mx, "scan cache by sha1_name");
  ent = zxid_get_ent_file(cf, sha1_name, "get_ent_by_sha1_name");
  if (!ent)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "B", "NOMD", 0, "sha1_name(%s)", sha1_name);
  return ent;
}

/*() In artifact profile concept of "succinct id" appears. If you have one of those,
 * you canuse this function to fetch the entity metadata. Only in-memory
 * and disk caches will be tried. No network connection (WKL) will be initiated. */

/* Called by:  zxid_sp_deref_art */
zxid_entity* zxid_get_ent_by_succinct_id(zxid_conf* cf, char* raw_succinct_id) {
  char sha1_name[28];
  base64_fancy_raw(raw_succinct_id, 20, sha1_name, safe_basis_64, 1<<31, 0, 0, '.');
  sha1_name[27] = 0;
  return zxid_get_ent_by_sha1_name(cf, sha1_name);
}

/*() Usually you will want to use the get_ent() methods if you need
 * only specific entities. Loading the entire cache is expensive and
 * only useful if you really need to enumerate through all
 * available entities. This may be the case when rendering login
 * buttons for all IdPs in a user interface.
 *
 * cf:: ZXID configuration object
 * return:: Linked list of Entity objects (metadata) for CoT partners */

/* Called by:  main x2, zxid_idp_list_cf_cgi, zxid_mk_idp_list */
zxid_entity* zxid_load_cot_cache(zxid_conf* cf)
{
  zxid_entity* ent;
  struct dirent* de;
  DIR* dir;
  char buf[4096];
  if (cf->cpath_len + sizeof(ZXID_COT_DIR) > sizeof(buf)) {
   ERR("Too long path(%.*s) for config dir. Has %d chars. Max allowed %d. (config problem)",
	cf->cpath_len, cf->cpath, cf->cpath_len, ((int)(sizeof(buf) - sizeof(ZXID_COT_DIR))));
    return 0;
  }
  memcpy(buf, cf->cpath, cf->cpath_len);
  memcpy(buf + cf->cpath_len, ZXID_COT_DIR, sizeof(ZXID_COT_DIR));

  zxid_load_cot_cache_from_file(cf);
  
  dir = opendir(buf);
  if (!dir) {
    perror("opendir for /var/zxid/cot (or other if configured) for loading cot cache");
    ERR("opendir failed path(%s) uid=%d gid=%d", buf, geteuid(), getegid());
    return 0;
  }
  
  while (de = readdir(dir))
    if (de->d_name[0] != '.' && de->d_name[strlen(de->d_name)-1] != '~')
      zxid_get_ent_by_sha1_name(cf, de->d_name);
  
  DD("HERE %p", cf);
  closedir(dir);

  LOCK(cf->mx, "return cot");
  ent = cf->cot;
  UNLOCK(cf->mx, "return cot");
  return ent;
}

/* ============== Our Metadata ============== */

/*() Generate XML-DSIG key info given X509 certificate. */

/* Called by:  zxenc_pubkey_enc, zxid_key_desc */
struct zx_ds_KeyInfo_s* zxid_key_info(zxid_conf* cf, struct zx_elem_s* father, X509* x)
{
  int len;
  char* dd;
  char* d;
  char* pp;
  char* p;
  struct zx_ds_KeyInfo_s* ki = zx_NEW_ds_KeyInfo(cf->ctx, father);
  ki->X509Data = zx_NEW_ds_X509Data(cf->ctx, &ki->gg);

#ifdef USE_OPENSSL
  /* Build PEM encoding (which is base64 of the DER encoding + header and footer) */
  
  len = i2d_X509(x, 0);  /* Length of the DER encoding */
  if (len <= 0) {
    ERR("DER encoding certificate failed: %d %p", len, x);
  } else {
    dd = d = ZX_ALLOC(cf->ctx, len);
    i2d_X509(x, (unsigned char**)&d);  /* DER encoding of the cert */
    pp = p = ZX_ALLOC(cf->ctx, (len+4) * 4 / 3 + (len/64) + 6);    
    p = base64_fancy_raw(dd, len, p, std_basis_64, 64, 1, "\n", '=');
    *p = 0;
    ki->X509Data->X509Certificate = zx_ref_len_elem(cf->ctx, &ki->X509Data->gg, zx_ds_X509Certificate_ELEM, p-pp, pp);
  }
#else
  ERR("This copy of zxid was compiled to NOT use OpenSSL. Generating KeyInfo is not supported. Add -DUSE_OPENSSL and recompile. %d", 0);
#endif
  zx_reverse_elem_lists(&ki->gg);
  return ki;
}

/*() Generate key descriptor metadata fragment given X509 certificate [SAML2meta]. */

/* Called by:  zxid_idp_sso_desc x2, zxid_sp_sso_desc x2 */
struct zx_md_KeyDescriptor_s* zxid_key_desc(zxid_conf* cf, struct zx_elem_s* father, char* use, X509* x) {
  struct zx_md_KeyDescriptor_s* kd = zx_NEW_md_KeyDescriptor(cf->ctx, father);
  kd->use = zx_ref_attr(cf->ctx, &kd->gg, zx_use_ATTR, use);
  kd->KeyInfo = zxid_key_info(cf, &kd->gg, x);
  zx_reverse_elem_lists(&kd->gg);
  return kd;
}

/*() Generate Artifact Resolution (AR) Descriptor idp metadata fragment [SAML2meta]. */

/* Called by:  zxid_idp_sso_desc */
struct zx_md_ArtifactResolutionService_s* zxid_ar_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc) {
  struct zx_md_ArtifactResolutionService_s* d = zx_NEW_md_ArtifactResolutionService(cf->ctx,father);
  d->Binding = zx_ref_attr(cf->ctx, &d->gg, zx_Binding_ATTR, binding);
  d->Location = zx_attrf(cf->ctx, &d->gg, zx_Location_ATTR, "%s%s", cf->burl, loc);
  if (resp_loc)
    d->ResponseLocation = zx_attrf(cf->ctx, &d->gg, zx_ResponseLocation_ATTR, "%s%s", cf->burl, resp_loc);
  zx_reverse_elem_lists(&d->gg);
  return d;
}

/*() Constructor for Single Sign-On (SSO) Descriptor idp metadata fragment [SAML2meta]. */

/* Called by:  zxid_idp_sso_desc x2 */
struct zx_md_SingleSignOnService_s* zxid_sso_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc) {
  struct zx_md_SingleSignOnService_s* d = zx_NEW_md_SingleSignOnService(cf->ctx,father);
  d->Binding = zx_ref_attr(cf->ctx, &d->gg, zx_Binding_ATTR, binding);
  d->Location = zx_attrf(cf->ctx, &d->gg, zx_Location_ATTR, "%s%s", cf->burl, loc);
  if (resp_loc)
    d->ResponseLocation = zx_attrf(cf->ctx, &d->gg, zx_ResponseLocation_ATTR, "%s%s", cf->burl, resp_loc);
  zx_reverse_elem_lists(&d->gg);
  return d;
}

/*() Generate Single Logout (SLO) Descriptor metadata fragment [SAML2meta]. */

/* Called by:  zxid_idp_sso_desc x2, zxid_sp_sso_desc x2 */
struct zx_md_SingleLogoutService_s* zxid_slo_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc) {
  struct zx_md_SingleLogoutService_s* d = zx_NEW_md_SingleLogoutService(cf->ctx,father);
  d->Binding = zx_ref_attr(cf->ctx, &d->gg, zx_Binding_ATTR, binding);
  d->Location = zx_attrf(cf->ctx, &d->gg, zx_Location_ATTR, "%s%s", cf->burl, loc);
  if (resp_loc)
    d->ResponseLocation = zx_attrf(cf->ctx, &d->gg, zx_ResponseLocation_ATTR, "%s%s", cf->burl, resp_loc);
  zx_reverse_elem_lists(&d->gg);
  return d;
}

/*() Generate Manage Name Id (MNI) Descriptor metadata fragment [SAML2meta]. */

/* Called by:  zxid_idp_sso_desc x2, zxid_sp_sso_desc x2 */
struct zx_md_ManageNameIDService_s* zxid_mni_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc) {
  struct zx_md_ManageNameIDService_s* d = zx_NEW_md_ManageNameIDService(cf->ctx,father);
  d->Binding = zx_ref_attr(cf->ctx, &d->gg, zx_Binding_ATTR, binding);
  d->Location = zx_attrf(cf->ctx, &d->gg, zx_Location_ATTR, "%s%s", cf->burl, loc);
  if (resp_loc)
    d->ResponseLocation = zx_attrf(cf->ctx, &d->gg, zx_ResponseLocation_ATTR, "%s%s", cf->burl, resp_loc);
  zx_reverse_elem_lists(&d->gg);
  return d;
}

/*() Generate Name ID Mapping Service metadata fragment [SAML2meta]. */

/* Called by:  zxid_idp_sso_desc */
struct zx_md_NameIDMappingService_s* zxid_nimap_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc) {
  struct zx_md_NameIDMappingService_s* d = zx_NEW_md_NameIDMappingService(cf->ctx,father);
  d->Binding = zx_ref_attr(cf->ctx, &d->gg, zx_Binding_ATTR, binding);
  d->Location = zx_attrf(cf->ctx, &d->gg, zx_Location_ATTR, "%s%s", cf->burl, loc);
  if (resp_loc)
    d->ResponseLocation = zx_attrf(cf->ctx, &d->gg, zx_ResponseLocation_ATTR, "%s%s", cf->burl, resp_loc);
  zx_reverse_elem_lists(&d->gg);
  return d;
}

/*() Generate Assertion Consumer Service (SSO) Descriptor metadata fragment [SAML2meta]. */

/* Called by:  zxid_sp_sso_desc x6 */
struct zx_md_AssertionConsumerService_s* zxid_ac_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* ix) {
  struct zx_md_AssertionConsumerService_s* d = zx_NEW_md_AssertionConsumerService(cf->ctx,father);
  d->Binding = zx_ref_attr(cf->ctx, &d->gg, zx_Binding_ATTR, binding);
  d->Location = zx_attrf(cf->ctx, &d->gg, zx_Location_ATTR, "%s%s", cf->burl, loc);
  d->index = zx_ref_attr(cf->ctx, &d->gg, zx_index_ATTR, ix);
  zx_reverse_elem_lists(&d->gg);
  return d;
}

/*() Generate SP SSO Descriptor metadata fragment [SAML2meta]. */

/* Called by:  zxid_sp_meta */
struct zx_md_SPSSODescriptor_s* zxid_sp_sso_desc(zxid_conf* cf, struct zx_elem_s* father)
{
  struct zx_md_SPSSODescriptor_s* sp_ssod = zx_NEW_md_SPSSODescriptor(cf->ctx,father);
  sp_ssod->AuthnRequestsSigned        = zx_ref_attr(cf->ctx, &sp_ssod->gg, zx_AuthnRequestsSigned_ATTR, cf->authn_req_sign?"1":"0");
  sp_ssod->WantAssertionsSigned       = zx_ref_attr(cf->ctx, &sp_ssod->gg, zx_WantAssertionsSigned_ATTR, cf->want_sso_a7n_signed?"1":"0");
  sp_ssod->errorURL                   = zx_attrf(cf->ctx, &sp_ssod->gg, zx_errorURL_ATTR, "%s?o=E", cf->burl);
  sp_ssod->protocolSupportEnumeration = zx_ref_attr(cf->ctx, &sp_ssod->gg, zx_protocolSupportEnumeration_ATTR, SAML2_PROTO);

  LOCK(cf->mx, "read certs for our md");
  if (!cf->enc_cert)
    cf->enc_cert = zxid_read_cert(cf, "enc-nopw-cert.pem");

  if (!cf->sign_cert)
    cf->sign_cert = zxid_read_cert(cf, "sign-nopw-cert.pem");

  if (!cf->enc_cert || !cf->sign_cert) {
    UNLOCK(cf->mx, "read certs for our md");
    ERR("Signing or encryption certificate not found (or both are corrupt). %p", cf->enc_cert);
  } else {
    sp_ssod->KeyDescriptor = zxid_key_desc(cf, &sp_ssod->gg, "encryption", cf->enc_cert);
    sp_ssod->KeyDescriptor = zxid_key_desc(cf, &sp_ssod->gg, "signing", cf->sign_cert);
    UNLOCK(cf->mx, "read certs for our md");
  }

  sp_ssod->SingleLogoutService = zxid_slo_desc(cf, &sp_ssod->gg, SAML2_REDIR, "?o=Q", "?o=Q");
  sp_ssod->SingleLogoutService = zxid_slo_desc(cf, &sp_ssod->gg, SAML2_SOAP,  "?o=S", 0);

  sp_ssod->ManageNameIDService = zxid_mni_desc(cf, &sp_ssod->gg, SAML2_REDIR, "?o=Q", "?o=Q");
  sp_ssod->ManageNameIDService = zxid_mni_desc(cf, &sp_ssod->gg, SAML2_SOAP,  "?o=S", 0);

  sp_ssod->NameIDFormat = zx_ref_elem(cf->ctx, &sp_ssod->gg, zx_md_NameIDFormat_ELEM, SAML2_PERSISTENT_NID_FMT);
  sp_ssod->NameIDFormat = zx_ref_elem(cf->ctx, &sp_ssod->gg, zx_md_NameIDFormat_ELEM, SAML2_TRANSIENT_NID_FMT);

  /* N.B. The index values should not be changed. They are used in
   * AuthnReq to choose profile using AssertionConsumerServiceIndex */

  sp_ssod->AssertionConsumerService = zxid_ac_desc(cf, &sp_ssod->gg, SAML2_ART, "", "1");
  sp_ssod->AssertionConsumerService = zxid_ac_desc(cf, &sp_ssod->gg, SAML2_POST, "?o=P", "2");
  sp_ssod->AssertionConsumerService = zxid_ac_desc(cf, &sp_ssod->gg, SAML2_SOAP, "?o=S", "3");
  sp_ssod->AssertionConsumerService = zxid_ac_desc(cf, &sp_ssod->gg, SAML2_PAOS, "?o=P", "4");
  sp_ssod->AssertionConsumerService = zxid_ac_desc(cf, &sp_ssod->gg, SAML2_POST_SIMPLE_SIGN, "?o=P", "5");
  sp_ssod->AssertionConsumerService = zxid_ac_desc(cf, &sp_ssod->gg, OAUTH2_REDIR, "?o=O", "8");
  zx_reverse_elem_lists(&sp_ssod->gg);
  return sp_ssod;
}

/*() Generate IdP SSO Descriptor metadata fragment [SAML2meta]. */

/* Called by:  zxid_sp_meta */
struct zx_md_IDPSSODescriptor_s* zxid_idp_sso_desc(zxid_conf* cf, struct zx_elem_s* father)
{
  struct zx_md_IDPSSODescriptor_s* idp_ssod = zx_NEW_md_IDPSSODescriptor(cf->ctx,father);
  idp_ssod->WantAuthnRequestsSigned
    = zx_ref_attr(cf->ctx, &idp_ssod->gg, zx_WantAuthnRequestsSigned_ATTR,
		  cf->want_authn_req_signed?"1":"0");
  idp_ssod->errorURL
    = zx_attrf(cf->ctx, &idp_ssod->gg, zx_errorURL_ATTR, "%s?o=E", cf->burl);
  idp_ssod->protocolSupportEnumeration
    = zx_ref_attr(cf->ctx, &idp_ssod->gg, zx_protocolSupportEnumeration_ATTR, SAML2_PROTO);

  LOCK(cf->mx, "read certs for our md idp");
  if (!cf->enc_cert)
    cf->enc_cert = zxid_read_cert(cf, "enc-nopw-cert.pem");

  if (!cf->sign_cert)
    cf->sign_cert = zxid_read_cert(cf, "sign-nopw-cert.pem");

  if (!cf->enc_cert || !cf->sign_cert) {
    UNLOCK(cf->mx, "read certs for our md idp");
    ERR("Neither signing nor encryption certificate found (or both are corrupt). %p", cf->enc_cert);
  } else {
    idp_ssod->KeyDescriptor = zxid_key_desc(cf, &idp_ssod->gg, "encryption", cf->enc_cert);
    idp_ssod->KeyDescriptor = zxid_key_desc(cf, &idp_ssod->gg, "signing", cf->sign_cert);
    UNLOCK(cf->mx, "read certs for our md idp");
  }

#if 0
  /* *** NI */
  idp_ssod->ArtifactResolutionService = zxid_ar_desc(cf, &idp_ssod->gg, SAML2_SOAP, "?o=S", 0);
#endif

  idp_ssod->SingleLogoutService = zxid_slo_desc(cf, &idp_ssod->gg, SAML2_REDIR, "?o=Q", "?o=Q");
  idp_ssod->SingleLogoutService = zxid_slo_desc(cf, &idp_ssod->gg, SAML2_SOAP, "?o=S", 0);

#if 0
  /* *** NI */
  idp_ssod->ManageNameIDService = zxid_mni_desc(cf, &idp_ssod->gg, SAML2_REDIR, "?o=Q", "?o=Q");
  idp_ssod->ManageNameIDService = zxid_mni_desc(cf, &idp_ssod->gg, SAML2_SOAP, "?o=S", 0);
#endif

  idp_ssod->NameIDFormat = zx_ref_elem(cf->ctx, &idp_ssod->gg, zx_md_NameIDFormat_ELEM, SAML2_PERSISTENT_NID_FMT);
  idp_ssod->NameIDFormat = zx_ref_elem(cf->ctx, &idp_ssod->gg, zx_md_NameIDFormat_ELEM, SAML2_TRANSIENT_NID_FMT);

  idp_ssod->SingleSignOnService = zxid_sso_desc(cf, &idp_ssod->gg, SAML2_REDIR, "?o=F", 0);
  idp_ssod->SingleSignOnService = zxid_sso_desc(cf, &idp_ssod->gg, OAUTH2_REDIR, "?o=F", 0); /* Same endpoint as for SAML - the detection is from presence of CGI field response_type */

  if (cf->imps_ena)
    idp_ssod->NameIDMappingService = zxid_nimap_desc(cf, &idp_ssod->gg, SAML2_SOAP, "?o=S", 0);
  
  zx_reverse_elem_lists(&idp_ssod->gg);
  return idp_ssod;
}

/*() Generate Organization metadata fragment [SAML2meta]. */

/* Called by:  zxid_sp_meta */
struct zx_md_Organization_s* zxid_org_desc(zxid_conf* cf, struct zx_elem_s* father)
{
  struct zx_md_Organization_s* org = zx_NEW_md_Organization(cf->ctx,father);
  org->OrganizationName = zx_NEW_md_OrganizationName(cf->ctx, &org->gg);
  org->OrganizationName->lang = zx_ref_attr(cf->ctx, &org->OrganizationName->gg, zx_xml_lang_ATTR, "en");  /* *** config */
  if (cf->org_name && cf->org_name[0])
    zx_add_content(cf->ctx, &org->OrganizationName->gg, zx_ref_str(cf->ctx, cf->org_name));
  else
    zx_add_content(cf->ctx, &org->OrganizationName->gg, zx_ref_str(cf->ctx, STRNULLCHKQ(cf->nice_name)));

  org->OrganizationDisplayName = zx_NEW_md_OrganizationDisplayName(cf->ctx, &org->gg);
  org->OrganizationDisplayName->lang = zx_ref_attr(cf->ctx, &org->OrganizationDisplayName->gg, zx_xml_lang_ATTR, "en");  /* *** config */
  zx_add_content(cf->ctx, &org->OrganizationDisplayName->gg, zx_ref_str(cf->ctx, STRNULLCHKQ(cf->nice_name)));

  if (cf->button_url && cf->button_url[0]) {
    /* see symlabs-saml-displayname-2008.pdf submitted to OASIS SSTC) */
    /* *** add support for multiple $ separated button_url's */
    org->OrganizationURL = zx_NEW_md_OrganizationURL(cf->ctx, &org->gg);
    org->OrganizationURL->lang = zx_ref_attr(cf->ctx, &org->OrganizationURL->gg, zx_xml_lang_ATTR, "en");  /* *** config */
    zx_add_content(cf->ctx, &org->OrganizationURL->gg, zx_ref_str(cf->ctx, cf->button_url));
  }
  zx_reverse_elem_lists(&org->gg);
  return org;
}

/*() Generate Contact Person metadata fragment [SAML2meta]. */

/* Called by:  zxid_sp_meta */
struct zx_md_ContactPerson_s* zxid_contact_desc(zxid_conf* cf, struct zx_elem_s* father)
{
  struct zx_md_ContactPerson_s* contact = zx_NEW_md_ContactPerson(cf->ctx,father);

  contact->contactType = zx_ref_attr(cf->ctx, &contact->gg, zx_contactType_ATTR, "administrative");  /* *** config */

  if (cf->contact_org) {
    if (cf->contact_org[0])
      contact->Company = zx_ref_elem(cf->ctx, &contact->gg, zx_md_Company_ELEM, cf->contact_org);
  } else
    if (cf->org_name && cf->org_name[0])
      contact->Company
	= zx_ref_elem(cf->ctx, &contact->gg, zx_md_Company_ELEM, cf->org_name);
    else
      contact->Company
	= zx_ref_elem(cf->ctx, &contact->gg, zx_md_Company_ELEM, STRNULLCHKQ(cf->nice_name));

  if (cf->contact_name && cf->contact_name[0])
    contact->SurName = zx_ref_elem(cf->ctx, &contact->gg, zx_md_SurName_ELEM, cf->contact_name);
  if (cf->contact_email && cf->contact_email[0])
    contact->EmailAddress = zx_ref_elem(cf->ctx, &contact->gg, zx_md_EmailAddress_ELEM, cf->contact_email);
  if (cf->contact_tel && cf->contact_tel[0])
    contact->TelephoneNumber = zx_ref_elem(cf->ctx, &contact->gg, zx_md_TelephoneNumber_ELEM, cf->contact_tel);

  zx_reverse_elem_lists(&contact->gg);
  return contact;
}

/*(i) Primary interface to our own Entity ID. While this would usually be
 * automatically generated from URL configuration option so as to conform
 * to the Well Known Location (WKL) metadata exchange convention [SAML2meta].
 * On some sites the entity ID may be different and thus everybody who
 * does not know better should use this interface to obtain it.
 *
 * cf:: ZXID configuration object, used to compute EntityID and also for memory allocation
 * return:: Entity ID as zx_str (caller must free with zx_str_free()) */

/* Called by:  zxid_idp_map_nid2uid, zxid_mk_oauth_az_req, zxid_mk_subj, zxid_my_issuer, zxid_nidmap_do, zxid_ses_to_pool, zxid_sp_sso_finalize, zxid_wsf_validate_a7n */
struct zx_str* zxid_my_ent_id(zxid_conf* cf)
{
  if (cf->non_standard_entityid) {
    D("my_entity_id nonstd(%s)", cf->non_standard_entityid);
    return zx_strf(cf->ctx, "%s", cf->non_standard_entityid);
  } else if (cf->bare_url_entityid) {
    D("my_entity_id bare url(%s)", cf->burl);
    return zx_strf(cf->ctx, "%s", cf->burl);
  } else {
    D("my_entity_id(%s?o=B)", cf->burl);
    return zx_strf(cf->ctx, "%s?o=B", cf->burl);
  }
}

/*() Return our EntityID as c-string. Caller must free with ZX_FREE(cf->ctx, eid) */

/* Called by:  main x2, stomp_got_ack, test_receipt, zxbus_send_cmdf, zxid_idp_select_zxstr_cf_cgi, zxid_map_bangbang, zxid_show_conf, zxid_sso_issue_jwt */
char* zxid_my_ent_id_cstr(zxid_conf* cf)
{
  int len;
  char* eid;
  if (cf->non_standard_entityid) {
    D("my_entity_id nonstd(%s)", cf->non_standard_entityid);
    return zx_dup_cstr(cf->ctx, cf->non_standard_entityid);
  } else if (cf->bare_url_entityid) {
    D("my_entity_id bare url(%s)", cf->burl);
    return zx_dup_cstr(cf->ctx, cf->burl);
  } else {
    D("my_entity_id(%s?o=B)", cf->burl);
    len = strlen(cf->burl);
    eid = ZX_ALLOC(cf->ctx, len+sizeof("?o=B"));
    strcpy(eid, cf->burl);
    strcpy(eid+len, "?o=B");
    return eid;
  }
}

/*() Return our EntityID as an attribute. Caller must free. */

/* Called by:  zxid_check_fed, zxid_mk_ecp_Request_hdr, zxid_sp_meta, zxid_wsf_decor */
struct zx_attr_s* zxid_my_ent_id_attr(zxid_conf* cf, struct zx_elem_s* father, int tok)
{
  if (cf->non_standard_entityid) {
    D("my_nonstd_entity_id(%s)", cf->non_standard_entityid);
    return zx_attrf(cf->ctx, father, tok, "%s", cf->non_standard_entityid);
  } else if (cf->bare_url_entityid) {
    D("my_entity_id bare url(%s)", cf->burl);
    return zx_attrf(cf->ctx, father, tok, "%s", cf->burl);
  } else {
    D("my_entity_id(%s?o=B)", cf->burl);
    return zx_attrf(cf->ctx, father, tok, "%s?o=B", cf->burl);
  }
}

/*() Dynamically determine our Common Domain Cookie (IdP discovery) URL. */

/* Called by: */
struct zx_str* zxid_my_cdc_url(zxid_conf* cf)
{
  return zx_strf(cf->ctx, "%s?o=C", cf->cdc_url);
}

/*() Generate Issuer value. Issuer is often same as Entity ID, but sometimes
 * it will be affiliation ID. This function is a low level interface. Usually
 * you would want to use zxid_my_issuer(). */

/* Called by:  zxid_my_issuer */
struct zx_sa_Issuer_s* zxid_issuer(zxid_conf* cf, struct zx_elem_s* father, struct zx_str* nameid, char* affiliation)
{
  struct zx_sa_Issuer_s* is = zx_NEW_sa_Issuer(cf->ctx, father);
  zx_add_content(cf->ctx, &is->gg, nameid);
  if (affiliation && affiliation[0])
    is->NameQualifier = zx_ref_attr(cf->ctx, &is->gg, zx_NameQualifier_ATTR, affiliation);
  /*is->Format = zx_ref_str(cf->ctx, );*/
  return is;
}

/*() Generate Issuer value for our entity. Issuer is often same as Entity ID, but sometimes
 * it will be affiliation ID. */

/* Called by:  zxid_mk_a7n, zxid_mk_art_deref, zxid_mk_authn_req, zxid_mk_az, zxid_mk_az_cd1, zxid_mk_ecp_Request_hdr, zxid_mk_logout, zxid_mk_logout_resp, zxid_mk_mni, zxid_mk_mni_resp, zxid_mk_saml_resp */
struct zx_sa_Issuer_s* zxid_my_issuer(zxid_conf* cf, struct zx_elem_s* father) {
  return zxid_issuer(cf, father, zxid_my_ent_id(cf), cf->affiliation);
}

/*() Generate the (IdP) metadata field indicating presence of a metadata authority. */

static struct zx_md_AdditionalMetadataLocation_s* zxid_md_authority_loc(zxid_conf* cf, struct zx_md_EntityDescriptor_s* ed) {
  struct zx_md_AdditionalMetadataLocation_s* mda;
  mda = zx_NEW_md_AdditionalMetadataLocation(cf->ctx, &ed->gg);
  mda->namespace_is_cxx_keyword = zx_dup_attr(cf->ctx,&mda->gg,zx_namespace_ATTR,"#md-authority");
  zx_add_content(cf->ctx, &mda->gg, zx_strf(cf->ctx, "%s?o=b", cf->burl));
  return mda;
}

/*() Generate our SP metadata and return it as a string. cgi may be specified as null. */

/* Called by:  zxid_genmd, zxid_send_sp_meta, zxid_simple_show_meta */
struct zx_str* zxid_sp_meta(zxid_conf* cf, zxid_cgi* cgi)
{
  struct zx_md_EntityDescriptor_s* ed;
  
  ed = zx_NEW_md_EntityDescriptor(cf->ctx,0);
  ed->entityID = zxid_my_ent_id_attr(cf, &ed->gg, zx_entityID_ATTR);
  if (cf->idp_ena)
    ed->IDPSSODescriptor = zxid_idp_sso_desc(cf, &ed->gg);
  ed->SPSSODescriptor = zxid_sp_sso_desc(cf, &ed->gg);
  ed->Organization = zxid_org_desc(cf, &ed->gg);
  ed->ContactPerson = zxid_contact_desc(cf, &ed->gg);
  if (cf->md_authority_ena)
    ed->AdditionalMetadataLocation = zxid_md_authority_loc(cf, ed);
  zx_reverse_elem_lists(&ed->gg);
  
  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "MYMD", 0, 0);
  return zx_easy_enc_elem_opt(cf, &ed->gg);
}

/*() Generate our SP metadata and send it to remote partner.
 *
 * Limitation:: This function only works with CGI as it will print the
 *     serialized metadata straight to stdout. There are other
 *     methods for getting metadata without this limitation, e.g. zxid_sp_meta() */

/* Called by:  main x2, opt x2 */
int zxid_send_sp_meta(zxid_conf* cf, zxid_cgi* cgi) {
  struct zx_str* ss = zxid_sp_meta(cf, cgi);
  if (!ss)
    return 0;
  //write_all_fd(1, ss->s, ss->len);
  write_all_fd(fdstdout, ss->s, ss->len);
  zx_str_free(cf->ctx, ss);
  return 0;
}

/* ------- CARML ------- */

/*() Generate our SP CARML and return it as a string. */

/* Called by:  zxid_simple_show_carml */
struct zx_str* zxid_sp_carml(zxid_conf* cf)
{
  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "MYCARML", 0, 0);

  /* *** Much work needed to study CARML spec and to convert need and want to comply */

  return zx_strf(cf->ctx,
"<carml:ClientAttrReq"
" AppName=\"ZXID SP\""
" Description=\"ZXID SP Attribute Needs and Wants\""
" xmlns:carml=\"urn:igf:client:0.9:carml\">"
"<carml:DataDefs>"

"  <carml:Attributes>"
"  </carml:Attributes>"

"  <carml:Predicates>"
"  </carml:Predicates>"

"  <carml:Roles>"
"  </carml:Roles>"

"  <carml:Policies>"
"  </carml:Policies>"

"</carml:DataDefs>"

"<carml:ReadInteraction/>"
"<carml:FindInteraction/>"
"<carml:SearchInteraction/>"
"<carml:CompareInteraction/>"
"<carml:ModifyInteraction/>"
"<carml:AddInteraction/>"

"</carml:ClientAttrReq>"
		 );
}

/* EOF  --  zxidmeta.c */
