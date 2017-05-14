/* zxidses.c  -  Handwritten functions for SP session handling
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidses.c,v 1.30 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 16.1.2007, split from zxidlib.c --Sampo
 * 5.2.2007,  added EPR handling --Sampo
 * 7.8.2008,  added session lookup by NameID --Sampo
 * 7.10.2008, added documentation --Sampo
 * 12.2.2010,  added pthread locking --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
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
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-ns.h"
#include "c/zx-e-data.h"

/* ============== Sessions ============== */

#define ZXID_MAX_SES (256)      /* Just the session nid and path to assertion */

/*() When session is loaded, we only get the reference to assertion. This
 * is to avoid parsing overhead when the assertion really is not needed.
 * But when the assertion is needed, you have to call this function to load
 * it from file (under /var/zxid/log/rely/EID/a7n/AID) and parse it. */

/* Called by:  zxid_get_ses_idp, zxid_idp_loc, zxid_ses_to_pool, zxid_simple_ses_active_cf, zxid_snarf_eprs_from_ses, zxid_sp_loc, zxid_sp_mni_redir, zxid_sp_mni_soap, zxid_sp_slo_redir, zxid_sp_slo_soap */
int zxid_get_ses_sso_a7n(zxid_conf* cf, zxid_ses* ses)
{
  struct zx_sa_EncryptedID_s* encid;
  struct zx_str* ss;
  struct zx_root_s* r;
  struct zx_str* subj;
  int gotall;
  if (ses->a7n || ses->a7n11 || ses->a7n12)  /* already in cache */
    return 1;
  if (!ses->sso_a7n_path) {
    D("Session object does not have any SSO assertion sid(%s)", STRNULLCHK(ses->sid));
    return 0;
  }
  ses->sso_a7n_buf = read_all_alloc(cf->ctx, "get_ses_sso_a7n", 1, &gotall, "%s", ses->sso_a7n_path);
  if (!ses->sso_a7n_buf)
    return 0;
  
  DD("a7n(%s)", ses->sso_a7n_buf);
  r = zx_dec_zx_root(cf->ctx, gotall, ses->sso_a7n_buf, "sso a7n");
  if (!r) {
    ERR("Failed to decode the sso assertion of session sid(%s) from  path(%s), a7n data(%.*s)",
	STRNULLCHK(ses->sid), ses->sso_a7n_path, gotall, ses->sso_a7n_buf);
    return 0;
  }
  
  ses->a7n   = r->Assertion;
  ses->a7n11 = r->sa11_Assertion;
  ses->a7n12 = r->ff12_Assertion;
  if (ses->a7n && ses->a7n->Subject) {
    ses->nameid = ses->a7n->Subject->NameID;
    encid = ses->a7n->Subject->EncryptedID;
    if (!ses->nameid && encid) {
      ss = zxenc_privkey_dec(cf, encid->EncryptedData, encid->EncryptedKey);
      if (!ss) {
	ERR("Failed to decrypt EncryptedID. Most probably certificate-private key mismatch or metadata problem. Could also be corrupt message. %d", 0);
	return 0;
      }
      r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "ses nid");
      if (!r) {
	ERR("Failed to parse EncryptedID buf(%.*s)", ss->len, ss->s);
	return 0;
      }
      ses->nameid = r->NameID;
    }
    if (ses->nameid)
      subj = ZX_GET_CONTENT(ses->nameid);
  } else if (ses->a7n11)
    subj = ZX_GET_CONTENT(ses->a7n11->AuthenticationStatement->Subject->NameIdentifier);
  else if (ses->a7n12)
    subj = ZX_GET_CONTENT(ses->a7n12->AuthenticationStatement->Subject->NameIdentifier);
  
  if (subj) {
    if (ses->nid) {
      if (memcmp(ses->nid, subj->s, subj->len)) {
	ERR("Session sid(%s), nid(%s), SSO assertion in path(%s) had different nid(%.*s). a7n data(%.*s)",
	    STRNULLCHK(ses->sid), ses->nid, ses->sso_a7n_path, subj->len, subj->s, gotall, ses->sso_a7n_buf);
      }
    } else
      ses->nid = zx_str_to_c(cf->ctx, subj);
    ses->tgt = ses->nid;
  } else
    ERR("Session sid(%s) SSO assertion in path(%s) did not have Name ID. a7n data(%.*s)",
	STRNULLCHK(ses->sid), ses->sso_a7n_path, gotall, ses->sso_a7n_buf);
  return 1;
}

/*() Get the IdP entity associated with the session. Generally this is figured out from
 * the Issuer field of the SSO assertion that started the session. */

/* Called by:  zxid_sp_mni_redir, zxid_sp_mni_soap, zxid_sp_slo_redir, zxid_sp_slo_soap */
zxid_entity* zxid_get_ses_idp(zxid_conf* cf, zxid_ses* ses)
{
  if (!zxid_get_ses_sso_a7n(cf, ses))
    return 0;
  if (!ses->a7n || ! ses->a7n->Issuer) {
    ERR("Session assertion is missing Issuer (the IdP) %p", ses->a7n);
    return 0;
  }
  return zxid_get_ent_ss(cf, ZX_GET_CONTENT(ses->a7n->Issuer));
}

/*() Allocate memory for session object. Used with zxid_simple_cf_ses(). */

/* Called by:  zxid_as_call, zxid_fetch_ses, zxid_mini_httpd_sso, zxid_mini_httpd_wsp */
zxid_ses* zxid_alloc_ses(zxid_conf* cf)
{
  zxid_ses* ses = ZX_ZALLOC(cf->ctx, zxid_ses);
  LOCK_INIT(ses->mx);
  return ses;
}

/*(i) Allocate memory and get session object from the filesystem, populating
 * attributes to pool so they are available for use. You mus obtain session id
 * from some source. */

/* Called by:  zxcall_main */
zxid_ses* zxid_fetch_ses(zxid_conf* cf, const char* sid)
{
  zxid_ses* ses = zxid_alloc_ses(cf);
  if (sid && sid[0])
    if (!zxid_get_ses(cf, ses, sid)) {
      ZX_FREE(cf->ctx, ses);
      return 0;
    }
  zxid_ses_to_pool(cf, ses);
  return ses;
}

/*() Get simple session object from the filesystem. This just gets the nameid
 * and reference to the assertion. Use zxid_get_ses_sso_a7n() to actually
 * load the assertion, if needed. Or zxid_ses_to_pool() if you need attributes
 * as well. Returns 1 if session gotten, 0 if fail. */

/* Called by:  chkuid x2, main x5, zxid_az_base_cf, zxid_az_cf, zxid_fetch_ses, zxid_find_ses, zxid_mini_httpd_sso x2, zxid_simple_cf_ses */
int zxid_get_ses(zxid_conf* cf, zxid_ses* ses, const char* sid)
{
  char* p;
  int gotall;
#if 0
  /* *** why would this set-cookie preservation code ever be needed? */
  if (cf->ses_cookie_name && ses->setcookie
      && !memcmp(cf->ses_cookie_name, ses->setcookie, strlen(cf->ses_cookie_name)))
    p = ses->setcookie;
  else
    p = 0;
  ZERO(ses, sizeof(zxid_ses));
  ses->magic = ZXID_SES_MAGIC;
  ses->setcookie = p;
#else
  ZERO(ses, sizeof(zxid_ses));
  ses->magic = ZXID_SES_MAGIC;
#endif

  gotall = strlen(sid);
  if (gotall != strspn(sid, safe_basis_64)) {
    ERR("EVIL Session ID(%s)", sid);
    return 0;
  }
  
  ses->sesbuf = ZX_ALLOC(cf->ctx, ZXID_MAX_SES);
  gotall = read_all(ZXID_MAX_SES-1, ses->sesbuf, "get_ses", 1,
		    "%s" ZXID_SES_DIR "%s/.ses", cf->cpath, sid);
  if (!gotall)
    return 0;
  D("ses(%.*s) len=%d sid(%s) sesptr=%p", gotall, ses->sesbuf, gotall, sid, ses);
  ses->sesbuf[gotall] = 0;
  DD("ses(%s)", ses->sesbuf);
  ses->sid = zx_dup_cstr(cf->ctx, sid);

  ses->nid = ses->sesbuf;
  p = strchr(ses->sesbuf, '|');
  if (!p) goto out;
  *p++ = 0;

  ses->sso_a7n_path = p;
  p = strchr(p, '|');
  if (!p) goto out;
  *p++ = 0;

  ses->sesix = p;
  p = strchr(p, '|');
  if (!p) goto out;
  *p++ = 0;

  ses->an_ctx = p;
  p = strchr(p, '|');
  if (!p) goto out;
  *p++ = 0;

  ses->uid = p;
  p = strchr(p, '|');
  if (!p) goto out;
  *p++ = 0;

  ses->an_instant = atol(p);

 out:
  D("GOT sesdir(%s" ZXID_SES_DIR "%s) uid(%s) nid(%s) sso_a7n_path(%s) sesix(%s) an_ctx(%s)", cf->cpath, ses->sid, STRNULLCHK(ses->uid), STRNULLCHK(ses->nid), STRNULLCHK(ses->sso_a7n_path), STRNULLCHK(ses->sesix), STRNULLCHK(ses->an_ctx));
  return 1;
}

/*() Create new session object in file system. The assertion must have
 * been created separately.
 *
 * cf:: Configuration object
 * ses:: Pointer to previously allocated and populated session object
 * return:: 1 upon success, 0 on failure. */

/* Called by:  zxid_as_call_ses, zxid_pw_authn, zxid_sp_anon_finalize, zxid_sp_sso_finalize, zxid_wsp_validate_env */
int zxid_put_ses(zxid_conf* cf, zxid_ses* ses)
{
  char dir[ZXID_MAX_BUF];
  char* buf;
  struct zx_str* ss;
  
  if (ses->sid) {
    if (strlen(ses->sid) != strspn(ses->sid, safe_basis_64)) {
      ERR("EVIL Session ID(%s)", ses->sid);
      return 0;
    }
  } else {  /* New session */
    ss = zxid_mk_id(cf, "S", ZXID_ID_BITS);
    ses->sid = ss->s;
    ZX_FREE(cf->ctx, ss);
  }
  
  name_from_path(dir, sizeof(dir), "%s" ZXID_SES_DIR "%s", cf->cpath, ses->sid);
  if (MKDIR(dir, 0777) && errno != EEXIST) {
    ERR("Creating session directory(%s) failed: %d %s; euid=%d egid=%d", dir, errno, STRERROR(errno), geteuid(), getegid());
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", dir, "mkdir fail, permissions?");
    return 0;
  }
  
  buf = ZX_ALLOC(cf->ctx, ZXID_MAX_SES);
  if (!write_all_path_fmt("put_ses", ZXID_MAX_SES, buf,
			  "%s" ZXID_SES_DIR "%s/.ses", cf->cpath, ses->sid,
			  "%s|%s|%s|%s|%s|%d|",
			  STRNULLCHK(ses->nid),
			  STRNULLCHK(ses->sso_a7n_path),
			  STRNULLCHK(ses->sesix),
			  STRNULLCHK(ses->an_ctx),
			  STRNULLCHK(ses->uid),
			  ses->an_instant)) {
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", ses->sid, "writing ses fail, permissions?");
    ZX_FREE(cf->ctx, buf);
    return 0;
  }
  ZX_FREE(cf->ctx, buf);
  D("SESSION CREATED sid(%s)", STRNULLCHK(ses->sid));
  return 1;
}

/*() Delete, or archive, session object from file system. Assertion, if any,
 * is not deleted. This is called upon explicit logout events. However, in reality
 * many sessions are simply abandoned, thus a deploying site should implement
 * some mechanism, such as a cron(8) job to remove or archive expired sessions. */

/* Called by:  zxid_idp_dispatch, zxid_idp_slo_do, zxid_mgmt x3, zxid_simple_ses_active_cf x3, zxid_sp_dispatch, zxid_sp_slo_do */
int zxid_del_ses(zxid_conf* cf, zxid_ses* ses)
{
  char old[ZXID_MAX_BUF];
  char new[ZXID_MAX_BUF];
  int len;
  if (!ses || !ses->sid) {
    D("No session in place. %p", ses);
    return 0;
  }
  
  if (ses->sid) {
    len = strlen(ses->sid);
    if (len != strspn(ses->sid, safe_basis_64)) {
      ERR("EVIL Session ID(%s)", ses->sid);
      return 0;
    }
  }
  
  if (!name_from_path(old, sizeof(old), "%s" ZXID_SES_DIR "%s", cf->cpath, ses->sid))
    return 0;
  
  if (cf->ses_arch_dir) {
    if (!name_from_path(new, sizeof(new), "%s%s", cf->ses_arch_dir, ses->sid))
      return 0;
    if (rename(old,new) == -1) {
      perror("rename to archieve session");
      ERR("Deleting session by renaming failed old(%s) new(%s), euid=%d egid=%d", old, new, geteuid(), getegid());
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", old, "ses arch rename, permissions?");
      return 0;
    }
  } else {
    DIR* dir;
    struct dirent * de;
    
    dir = opendir(old);
    if (!dir) {
      perror("opendir to delete session");
      ERR("Deleting session by opendir failed old(%s), euid=%d egid=%d", old, geteuid(), getegid());
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", old, "ses del opendir, permissions?");
      return 0;
    }
    while (de = readdir(dir)) {
      if (de->d_name[0] == '.' && ONE_OF_2(de->d_name[1], '.', 0))   /* skip . and .. */
	continue;
      if (!name_from_path(new, sizeof(new), "%s" ZXID_SES_DIR "%s/%s", cf->cpath, ses->sid, de->d_name))
	return 0;
      if (unlink(new) == -1) {
	perror("unlink to delete files in session");
	ERR("Deleting session file(%s) by unlink failed, euid=%d egid=%d", new, geteuid(), getegid());
	zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", new, "ses unlink, permissions?");
	return 0;
      }
    }
    closedir(dir);
    if (rmdir(old) == -1) {
      perror("rmdir to delete session");
      ERR("Deleting session by rmdir failed old(%s), euid=%d egid=%d", old, geteuid(), getegid());
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", old, "ses rmdir, permissions?");
      return 0;
    }
  }
  return 1;
}

/*() Find a session object by a number of criteria.
 *
 * cf:: ZXID configuration object
 * ses:: Result parameter. Must have been previously allocated. This will be modified
 *     to match the found session.
 * ses_ix:: Session Index, usually from SSO asserion or from SLO request. If not
 *     supplied (i.e. 0), the ~nid~ MUST be supplied and will be used as sole basis for
 *     deleting the session.
 * nid:: The idp assigned Name ID associated with the session. If supplied as 0, then
 *     ~ses_ix~ MUST be supplied and will be used to determine which session is deleted.
 * return:: 0 unknown session or error, 1 session found successfully */

/* Called by:  zxid_idp_slo_do, zxid_sp_slo_do */
int zxid_find_ses(zxid_conf* cf, zxid_ses* ses, struct zx_str* ses_ix, struct zx_str* nid)
{
  char buf[ZXID_MAX_BUF];
  DIR* dir;
  struct dirent * de;
  
  D("ses_ix(%.*s) nid(%.*s)", ses_ix?ses_ix->len:0, ses_ix?ses_ix->s:"", nid?nid->len:0, nid?nid->s:"");
  
  if (!name_from_path(buf, sizeof(buf), "%s" ZXID_SES_DIR, cf->cpath))
    return 0;
  
  dir = opendir(buf);
  if (!dir) {
    perror("opendir to find session");
    ERR("Finding session by opendir failed buf(%s), euid=%d egid=%d", buf, geteuid(), getegid());
    return 0;
  }
  while (de = readdir(dir)) {
    if (de->d_name[0] == '.' && ONE_OF_2(de->d_name[1], '.', 0))   /* skip . and .. */
      continue;
    if (zxid_get_ses(cf, ses, de->d_name)) {
      if (nid && (!ses->nid || memcmp(ses->nid, nid->s, nid->len) || ses->nid[nid->len]))
	continue;
      if (ses_ix && (!ses->sesix || memcmp(ses->sesix, ses_ix->s, ses_ix->len) || ses->sesix[ses_ix->len]))
	continue;
      return 1;
    }
  }
  closedir(dir);
  ZERO(ses, sizeof(zxid_ses));
  return 0;
}

/* EOF  --  zxidses.c */
