/* zxlog.c  -  Liberty oriented logging facility with log signing and encryption
 * Copyright (c) 2012-2013 Synergetics (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxlog.c,v 1.32 2009-11-24 23:53:40 sampo Exp $
 *
 * 18.11.2006, created --Sampo
 * 10.10.2007, added ipport --Sampo
 * 7.10.2008,  added inline documentation --Sampo
 * 29.8.2009,  added hmac chaining field --Sampo
 * 12.3.2010,  added per user logging facility --Sampo
 * 9.9.2012,   added persist support --Sampo
 * 30.11.2013, fixed seconds handling re gmtime_r() - found by valgrind --Sampo
 * 18.12.2015, applied patch from soconnor, perceptyx --Sampo
 *
 * See also: Logging chapter in README.zxid
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include <fcntl.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef USE_OPENSSL
#include <openssl/x509.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>
#include <openssl/aes.h>
#endif

#include "errmac.h"
#include "zxid.h"
#include "zxidutil.h"  /* for zx_zlib_raw_deflate(), safe_basis_64, and name_from_path */
#include "zxidconf.h"
#include "c/zx-data.h"  /* Generated. If missing, run `make dep ENA_GEN=1' */

/*() Allocate memory for logging purposes.
 * Generally memory allocation goes via zx_alloc() family of functions. However
 * dues to special requirements of cryptographically implemeted logging,
 * we maintain this special allocation function (which backends to zx_alloc()).
 * Among the special features: This function makes sure the buffer size is
 * rounded up to multiple of nonce to accommodate block ciphers.
 *
 * This function is considered internal. Do not use unless you know what you are doing. */

/* Called by:  zxlog_write_line x3 */
static char* zxlog_alloc_zbuf(zxid_conf* cf, int *zlen, char* zbuf, int len, char* sig, int nonce)
{
  char* p;
  int siz = nonce + 2 + len + *zlen;
  ROUND_UP(siz, nonce);        /* Round up to block size */
  p = ZX_ALLOC(cf->ctx, siz);
  if (nonce)
    zx_rand(p, nonce);
  p[nonce] = (len >> 8) & 0xff;
  p[nonce+1] = len & 0xff;
  if (len) {
    memcpy(p+nonce+2, sig, len);
    ZX_FREE(cf->ctx, sig);
  }
  memcpy(p+nonce+2+len, zbuf, *zlen);
  ZX_FREE(cf->ctx, zbuf);
  *zlen += nonce + 2 + len;
  return p;
}

/*() Write a line to a log, taking care of all formalities of locking and
* observing all special options for signing and encryption of the logs.
* Not usually called directly (but you can if you want to), this is the
* work horse behind zxlog().
*
* cf::  ZXID configuration object, used for memory allocation.
* c_path:: Path to the log file, as C string
* encflags:: Encryption flags. See LOG_ERR or LOG_ACT configuration options in zxidconf.h
* n:: length of log data
* logbuf:: The data that should be logged
*/

/* Called by:  test_mode x12, zxlog_output x2 */
void zxlog_write_line(zxid_conf* cf, char* c_path, int encflags, int n, const char* logbuf)
{
  EVP_PKEY* log_sign_pkey;
  struct rsa_st* rsa_pkey;
  struct aes_key_st aes_key;
  int len = 0, blen, zlen;
  char sigletter = 'P';
  char encletter = 'P';
  char* p;
  char* sig = 0;
  char* zbuf;
  char* b64;
  char sigbuf[28+4];   /* Space for "SP " and sha1 */
  char keybuf[16];
  char ivec[16];
  if (n == -2)
    n = strlen(logbuf);
  if (encflags & 0x70) {          /* Encrypt check */
    zbuf = zx_zlib_raw_deflate(cf->ctx, n-1, logbuf, &zlen);
    switch (encflags & 0x06) {     /* Sign check */
    case 0x02:      /* Sx plain sha1 */
      sigletter = 'S';
      sig = ZX_ALLOC(cf->ctx, 20);
      SHA1((unsigned char*)zbuf, zlen, (unsigned char*)sig);
      len = 20;
      break;
    case 0x04:      /* Rx RSA-SHA1 signature */
      sigletter = 'R';
      LOCK(cf->mx, "logsign wrln");      
      if (!(log_sign_pkey = cf->log_sign_pkey))
	log_sign_pkey = cf->log_sign_pkey = zxid_read_private_key(cf, "logsign-nopw-cert.pem");
      UNLOCK(cf->mx, "logsign wrln");      
      if (!log_sign_pkey)
	break;
      len = zxsig_data(cf->ctx, zlen, zbuf, &sig, log_sign_pkey, "enc log line", cf->blobsig_digest_algo);
      break;
    case 0x06:      /* Dx DSA-SHA1 signature */
      ERR("DSA-SHA1 sig not implemented in encrypted mode. Use RSA-SHA1 or none. %x", encflags);
      break;
    case 0: break;  /* Px no signing */
    }
    
    switch (encflags & 0x70) {
    case 0x10:  /* xZ RFC1951 zip + safe base64 */
      encletter = 'Z';
      zbuf = zxlog_alloc_zbuf(cf, &zlen, zbuf, len, sig, 0);
      break;
    case 0x20:  /* xA RSA-AES */
      encletter = 'A';
      zbuf = zxlog_alloc_zbuf(cf, &zlen, zbuf, len, sig, 16);
      zx_rand(keybuf, 16);
      AES_set_encrypt_key((unsigned char*)keybuf, 128, &aes_key);
      memcpy(ivec, zbuf, sizeof(ivec));
      AES_cbc_encrypt((unsigned char*)zbuf+16, (unsigned char*)zbuf+16, zlen-16, &aes_key, (unsigned char*)ivec, 1);
      ROUND_UP(zlen, 16);        /* Round up to block size */

      LOCK(cf->mx, "logenc wrln");
      if (!cf->log_enc_cert)
	cf->log_enc_cert = zxid_read_cert(cf, "logenc-nopw-cert.pem");
      rsa_pkey = zx_get_rsa_pub_from_cert(cf->log_enc_cert, "log_enc_cert");
      UNLOCK(cf->mx, "logenc wrln");
      if (!rsa_pkey)
	break;
      
      len = RSA_size(rsa_pkey);
      sig = ZX_ALLOC(cf->ctx, len);
      if (RSA_public_encrypt(16, (unsigned char*)keybuf, (unsigned char*)sig, rsa_pkey, RSA_PKCS1_OAEP_PADDING) < 0) {
	ERR("RSA enc fail %x", encflags);
	zx_report_openssl_err("zxlog rsa enc");
	return;
      }
      p = ZX_ALLOC(cf->ctx, 2 + len + zlen);
      p[0] = (len >> 8) & 0xff;
      p[1] = len & 0xff;
      memcpy(p+2, sig, len);
      memcpy(p+2+len, zbuf, zlen);
      ZX_FREE(cf->ctx, sig);
      ZX_FREE(cf->ctx, zbuf);
      zbuf = p;
      zlen += 2 + len;
      break;
    case 0x30:  /* xT RSA-3DES */
      encletter = 'T';
      ERR("Enc not implemented %x", encflags);
      break;
    case 0x40:  /* xB AES */
      encletter = 'B';
      zbuf = zxlog_alloc_zbuf(cf, &zlen, zbuf, len, sig, 16);
      if (!cf->log_symkey[0])
	zx_get_symkey(cf, "logenc.key", cf->log_symkey);
      AES_set_encrypt_key((unsigned char*)cf->log_symkey, 128, &aes_key);
      memcpy(ivec, zbuf, sizeof(ivec));
      AES_cbc_encrypt((unsigned char*)zbuf+16, (unsigned char*)zbuf+16, zlen-16, &aes_key, (unsigned char*)ivec, 1);
      ROUND_UP(zlen, 16);        /* Round up to block size */
      break;
    case 0x50:  /* xU 3DES */
      encletter = 'U';
      ERR("Enc not implemented %x", encflags);
      break;
    default:
      ERR("Enc not implemented %x", encflags);
      break;
    }

    blen = SIMPLE_BASE64_LEN(zlen) + 3 + 1;
    b64 = ZX_ALLOC(cf->ctx, blen);
    b64[0] = sigletter;
    b64[1] = encletter;
    b64[2] = ' ';
    p = base64_fancy_raw(zbuf, zlen, b64+3, safe_basis_64, 1<<31, 0, 0, '.');
    blen = p-b64 + 1;
    *p = '\n';
    write2_or_append_lock_c_path(c_path, 0, 0, blen, b64, "zxlog enc", SEEK_END, O_APPEND);
    return;
  }

  /* Plain text, possibly signed. */

  switch (encflags & 0x06) {
  case 0x02:   /* SP plain sha1 */
    strcpy(sigbuf, "SP ");
    sha1_safe_base64(sigbuf+3, n-1, logbuf);
    sigbuf[3+27] = ' ';
    len = 3+27+1;
    p = sigbuf;
    break;
  case 0x04:   /* RP RSA-SHA1 signature */
    LOCK(cf->mx, "logsign wrln");      
    if (!(log_sign_pkey = cf->log_sign_pkey))
      log_sign_pkey = cf->log_sign_pkey = zxid_read_private_key(cf, "logsign-nopw-cert.pem");
    UNLOCK(cf->mx, "logsign wrln");
    if (!log_sign_pkey)
      break;
    zlen = zxsig_data(cf->ctx, n-1, logbuf, &zbuf, log_sign_pkey, "log line", cf->blobsig_digest_algo);
    len = SIMPLE_BASE64_LEN(zlen) + 4;
    sig = ZX_ALLOC(cf->ctx, len);
    strcpy(sig, "RP ");
    p = base64_fancy_raw(zbuf, zlen, sig+3, safe_basis_64, 1<<31, 0, 0, '.');
    len = p-sig + 1;
    *p = ' ';
    p = sig;
    break;
  case 0x06:   /* DP DSA-SHA1 signature */
    ERR("DSA-SHA1 signature not implemented %x", encflags);
    break;
  case 0:      /* Plain logging, no signing, no encryption. */
    len = 5;
    p = "PP - ";
    break;
  }
  write2_or_append_lock_c_path(c_path, len, p, n, logbuf, "zxlog sig", SEEK_END, O_APPEND);
  if (sig)
    ZX_FREE(cf->ctx, sig);
}

/*() Helper function for formatting all kinds of logs.
 * This is the real workhorse. */

static int zxlog_fmt(zxid_conf* cf,   /* 1 */
		     int len, char* logbuf,
		     struct timeval* ourts,  /* 2 null allowed, will use current time */
		     struct timeval* srcts,  /* 3 null allowed, will use start of unix epoch... */
		     const char* ipport,     /* 4 null allowed, -:- or cf->ipport if not given */
		     struct zx_str* entid,   /* 5 null allowed, - if not given */
		     struct zx_str* msgid,   /* 6 null allowed, - if not given */
		     struct zx_str* a7nid,   /* 7 null allowed, - if not given */
		     struct zx_str* nid,     /* 8 null allowed, - if not given */
		     const char* sigval,     /* 9 null allowed, - if not given */
		     const char* res,        /* 10 */
		     const char* op,         /* 11 */
		     const char* arg,        /* 12 null allowed, - if not given */
		     const char* fmt,        /* 13 null allowed as format, ends the line */
		     va_list ap)
{
  int n;
  char* p;
  char sha1_name[28];
  struct tm ot;
  struct tm st;
  struct timeval ourtsdefault;
  struct timeval srctsdefault;
  
  /* Prepare values */

  if (!ourts) {
    ourts = &ourtsdefault;
    GETTIMEOFDAY(ourts, 0);
  }
  if (!srcts) {
    srcts = &srctsdefault;
    srctsdefault.tv_sec = 0;
    srctsdefault.tv_usec = 501000;
  }
  GMTIME_R(ourts->tv_sec, ot);
  GMTIME_R(srcts->tv_sec, st);
  
  if (entid && entid->len && entid->s) {
    sha1_safe_base64(sha1_name, entid->len, entid->s);
    sha1_name[27] = 0;
  } else {
    sha1_name[0] = '-';
    sha1_name[1] = 0;
  }
  
  if (!ipport) {
    ipport = cf->ipport;
    if (!ipport)
      ipport = "-:-";
  }
  
  /* Format */
  
  n = snprintf(logbuf, len-3, ZXLOG_TIME_FMT " " ZXLOG_TIME_FMT
	       " %s %s"  /* ipport  sha1_name-of-ent */
	       " %.*s"
	       " %.*s"
	       " %.*s"
	       " %s %s %s %s %s ",
	       ZXLOG_TIME_ARG(ot, ourts->tv_usec), ZXLOG_TIME_ARG(st, srcts->tv_usec),
	       ipport, sha1_name,
	       msgid?msgid->len:1, msgid?msgid->s:"-",
	       a7nid?a7nid->len:1, a7nid?a7nid->s:"-",
	       nid?nid->len:1,     nid?nid->s:"-",
	       errmac_instance, STRNULLCHKD(sigval), res, op, arg?arg:"-");
  logbuf[len-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  if (n <= 0 || n >= len-3) {
    if (n < 0) platform_broken_snprintf(n, __FUNCTION__, len-3, "log line");
    D("Log buffer too short: %d chars needed", n);
    if (n <= 0)
      n = 0;
    else
      n = len-3;
  } else { /* Space left: try printing the format string as well! */
    p = logbuf+n;
    if (fmt && fmt[0]) {
      n = vsnprintf(p, len-n-2, fmt, ap);
      logbuf[len-1] = 0;  /* must terminate manually as on win32 nul term is not guaranteed */
      if (n <= 0 || n >= len-(p-logbuf)-2) {
	if (n < 0) platform_broken_snprintf(n, __FUNCTION__, len-n-2, fmt);
	D("Log buffer truncated during format print: %d chars needed", n);
	if (n <= 0)
	  n = p-logbuf;
	else
	  n = len-(p-logbuf)-2;
      } else
	n += p-logbuf;
    } else {
      logbuf[n++] = '-';
    }
  }
  logbuf[n++] = '\n';
  logbuf[n] = 0;
  /*logbuf[len-1] = 0;*/
  return n;
}

/*() Figure out which log file should receive the message */

/* Called by: */
static int zxlog_output(zxid_conf* cf, int n, const char* logbuf, const char* res)
{
  char c_path[ZXID_MAX_BUF];
  DD("LOG(%.*s)", n-1, logbuf);
  if ((cf->log_err_in_act || res[0] == 'K') && cf->log_act) {
    name_from_path(c_path, sizeof(c_path), "%s" ZXID_LOG_DIR "act", cf->cpath);
    zxlog_write_line(cf, c_path, cf->log_act, n, logbuf);
  }
  if (cf->log_err && (cf->log_act_in_err || res[0] != 'K')) {  /* If enabled, everything goes to err */
    name_from_path(c_path, sizeof(c_path), "%s" ZXID_LOG_DIR "err", cf->cpath);
    zxlog_write_line(cf, c_path, cf->log_err, n, logbuf);
  }
  return 0;
}

/*(i) Log to activity and/or error log depending on ~res~ and configuration settings.
 * This is the main audit logging function you should call. Please see <<link:../../html/zxid-log.html: zxid-log.pd>>
 * for detailed description of the log format and features. See <<link:../../html/zxid-conf.html: zxid-conf.pd>> for
 * configuration options governing the logging. (*** check the links)
 *
 * Proper audit trail is essential for any high value transactions based on SSO. Also
 * some SAML protocol Processing Rules, such as duplicate detection, depend on the
 * logging.
 *
 * cf     (1)::  ZXID configuration object, used for configuration options and memory allocation
 * ourts  (2)::  Timestamp as observed by localhost. Typically the wall clock
 *     time. See gettimeofday(3)
 * srcts  (3)::  Timestamp claimed by the message to which the log entry pertains
 * ipport (4)::  IP address and port number from which the message appears to have originated
 * entid  (5)::  Entity ID to which the message pertains, usually the issuer. Null ok.
 * msgid  (6)::  Message ID, can be used for correlation to establish audit trail continuity
 *     from request to response. Null ok.
 * a7nid  (7)::  Assertion ID, if message contained assertion (outermost and first
 *     assertion if there are multiple relevant assertions). Null ok.
 * nid    (8)::  Name ID pertaining to the message
 * sigval (9)::  Signature validation letters
 * res   (10)::  Result letters
 * op    (11)::  Operation code for the message
 * arg   (12)::  Operation specific argument
 * fmt, ...  ::  Free format message conveying additional information
 * return:: 0 on success, nonzero on failure (often ignored as zxlog() is very
 *     robust and rarely fails - and when it does, situation is so hopeless that
 *     you would not be able to report its failure anyway)
 */

/* Called by:  zxid_an_page_cf, zxid_anoint_sso_a7n, zxid_anoint_sso_resp, zxid_chk_sig, zxid_decode_redir_or_post x2, zxid_fed_mgmt_cf, zxid_get_ent_by_sha1_name, zxid_get_ent_ss, zxid_get_meta x2, zxid_idp_dispatch, zxid_idp_select_zxstr_cf_cgi, zxid_idp_soap_dispatch x2, zxid_idp_soap_parse, zxid_parse_conf_raw, zxid_parse_meta, zxid_saml_ok x2, zxid_simple_render_ses, zxid_simple_ses_active_cf, zxid_sp_anon_finalize, zxid_sp_deref_art x5, zxid_sp_dig_sso_a7n x2, zxid_sp_dispatch, zxid_sp_meta, zxid_sp_mni_redir, zxid_sp_mni_soap, zxid_sp_slo_redir, zxid_sp_slo_soap, zxid_sp_soap_dispatch x2, zxid_sp_soap_parse, zxid_sp_sso_finalize x2, zxid_start_sso_url x3 */
int zxlog(zxid_conf* cf,   /* 1 */
	  struct timeval* ourts,  /* 2 null allowed, will use current time */
	  struct timeval* srcts,  /* 3 null allowed, will use start of unix epoch + 501 usec */
	  const char* ipport,     /* 4 null allowed, -:- or cf->ipport if not given */
	  struct zx_str* entid,   /* 5 null allowed, - if not given */
	  struct zx_str* msgid,   /* 6 null allowed, - if not given */
	  struct zx_str* a7nid,   /* 7 null allowed, - if not given */
	  struct zx_str* nid,     /* 8 null allowed, - if not given */
	  const char* sigval,     /* 9 null allowed, - if not given */
	  const char* res,        /* 10 */
	  const char* op,         /* 11 */
	  const char* arg,        /* 12 null allowed, - if not given */
	  const char* fmt, ...)   /* 13 null allowed as format, ends the line w/o further ado */
{
  int n;
  char logbuf[1024];
  va_list ap;
  
  /* Avoid computation if logging is hopeless. */
  
  if (!((cf->log_err_in_act || res[0] == 'K') && cf->log_act)
      && !(cf->log_err && res[0] != 'K')) {
    return 0;
  }

  va_start(ap, fmt);
  n = zxlog_fmt(cf, sizeof(logbuf), logbuf,
		ourts, srcts, ipport, entid, msgid, a7nid, nid, sigval, res,
		op, arg, fmt, ap);
  va_end(ap);
  return zxlog_output(cf, n, logbuf, res);
}

/*() Log to activity and/or error log depending on ~res~ and configuration settings.
 * This variant uses the ses object to extract many of the log fields. These fields
 * were populated to ses by zxid_wsp_validate()
 */

int zxlogwsp(zxid_conf* cf,    /* 1 */
	     zxid_ses* ses,    /* 2 */
	     const char* res,  /* 3 */
	     const char* op,   /* 4 */
	     const char* arg,  /* 5 null allowed, - if not given */
	     const char* fmt, ...)   /* 13 null allowed as format, ends the line w/o further ado */
{
  int n;
  char logbuf[1024];
  va_list ap;
  
  /* Avoid computation if logging is hopeless. */
  
  if (!((cf->log_err_in_act || res[0] == 'K') && cf->log_act)
      && !(cf->log_err && res[0] != 'K')) {
    return 0;
  }

  va_start(ap, fmt);
  n = zxlog_fmt(cf, sizeof(logbuf), logbuf,
		0, ses?&ses->srcts:0, ses?ses->ipport:0,
		ses?ses->issuer:0, ses?ses->wsp_msgid:0,
		ses&&ses->a7n?&ses->a7n->ID->g:0,
		ses?ZX_GET_CONTENT(ses->nameid):0,
		ses&&ses->sigres?&ses->sigres:"-", res,
		op, arg, fmt, ap);
  va_end(ap);
  return zxlog_output(cf, n, logbuf, res);
}

/*() Log user specific data */

int zxlogusr(zxid_conf* cf,   /* 1 */
	     const char* uid,
	     struct timeval* ourts,  /* 2 null allowed, will use current time */
	     struct timeval* srcts,  /* 3 null allowed, will use start of unix epoch + 501 usec */
	     const char* ipport,     /* 4 null allowed, -:- or cf->ipport if not given */
	     struct zx_str* entid,   /* 5 null allowed, - if not given */
	     struct zx_str* msgid,   /* 6 null allowed, - if not given */
	     struct zx_str* a7nid,   /* 7 null allowed, - if not given */
	     struct zx_str* nid,     /* 8 null allowed, - if not given */
	     const char* sigval,     /* 9 null allowed, - if not given */
	     const char* res,        /* 10 */
	     const char* op,         /* 11 */
	     const char* arg,        /* 12 null allowed, - if not given */
	     const char* fmt, ...)   /* 13 null allowed as format, ends the line w/o further ado */
{
  int n;
  char logbuf[1024];
  char c_path[ZXID_MAX_BUF];
  va_list ap;

  if (!uid) {
    ERR("NULL uid argument %p", cf);
    return 1;
  }

  va_start(ap, fmt);
  n = zxlog_fmt(cf, sizeof(logbuf), logbuf,
		ourts, srcts, ipport, entid, msgid, a7nid, nid, sigval, res,
		op, arg, fmt, ap);
  va_end(ap);

  /* Output stage */
  
  D("UID(%s) LOG(%.*s)", uid, n-1, logbuf);
  name_from_path(c_path, sizeof(c_path), "%s" ZXID_UID_DIR "%s/.log", cf->cpath, uid);
  zxlog_write_line(cf, c_path, cf->log_act, n, logbuf);
  return 0;
}

/*(-) Create a directory and perform error checking. */

/* Called by:  zxlog_path x3 */
static int zx_create_dir_with_check(zxid_conf* cf, const char* dir, int create_dirs)
{
  struct stat st;
  if (stat(dir, &st)) {
    if (create_dirs) {
      if (MKDIR(dir, 0777)) {
	ERR("mkdir path(%s) failed: %d %s; euid=%d egid=%d", dir, errno, STRERROR(errno), geteuid(), getegid());
	return 0;	
      }
    } else {
      ERR("directory missing path(%s) and no create_dirs (stat: %d %s; euid=%d egid=%d)", dir, errno, STRERROR(errno), geteuid(), getegid());
      return 0;
    }
  }
  return 1;
}

/*() Compute path for logging. Optionally attempt to create the necessary
 * directories if they are missing (you should do `zxcot -dirs' rather than
 * depend on this).
 *
 * cf::     ZXID configuration object uded for deternining root if the logging
 *     hierarchy, see PATH configuration option. Also used for memory allocation.
 * entid::  Issuer or target entity ID. For wire messages the URL.
 * objid::  AssertionID or MessageID. For wire messages the payload.
 * dir::    Directory prefix indicating branch of audit trail ("rely/" or "issue/")
 * kind::   Kind of object, used as path component ("/a7n/" or "/msg/")
 * create_dirs::  Flag: should creating directories be attempted. Usually 1 if intent
 *     is to write a file to the computed path. Usually 0 if the intent is to read.
 * return:: The path, as zx_str or 0 if failure */

/* Called by:  zxbus_send_cmdf, zxid_anoint_a7n, zxid_anoint_sso_resp, zxid_decode_redir_or_post x2, zxid_saml2_post_enc, zxid_saml2_redir_enc, zxid_soap_cgi_resp_body, zxid_sp_sso_finalize, zxid_sso_issue_jwt, zxid_wsc_valid_re_env, zxid_wsf_validate_a7n, zxid_wsp_validate */
struct zx_str* zxlog_path(zxid_conf* cf,
			  struct zx_str* entid,  /* issuer or target entity ID */
			  struct zx_str* objid,  /* AssertionID or MessageID */
			  const char* dir,       /* rely/ or issue/ */
			  const char* kind,      /* /a7n/ or /msg/ */
			  int create_dirs)
{
  struct stat st;
  int dir_len = strlen(dir);
  int kind_len = strlen(kind);
  int len = cf->cpath_len + sizeof("log/")-1 + dir_len + 27 + kind_len + 27;
  char* s = ZX_ALLOC(cf->ctx, len+1);
  char* p;

  if (!entid) {
    ERR("No EntityID supplied %p dir(%s) kind(%s)", objid, STRNULLCHK(dir), STRNULLCHK(kind));
    ZX_FREE(cf->ctx, s);
    return 0;
  }

  memcpy(s, cf->cpath, cf->cpath_len);
  p = s + cf->cpath_len;
  memcpy(p, "log/", sizeof("log/"));
  p += sizeof("log/")-1;
  if (stat(s, &st)) {
    ERR("zxid log directory missing path(%s): giving up (stat: %d %s; euid=%d egid=%d). Consider checking permissions and running zxcot -dirs", s, errno, STRERROR(errno), geteuid(), getegid());
    goto nodir;
  }
  
  memcpy(p, dir, dir_len+1);
  p += dir_len;
  if (!zx_create_dir_with_check(cf, s, create_dirs)) goto nodir;
  
  sha1_safe_base64(p, entid->len, entid->s);
  p[27] = 0;
  p+=27;
  if (!zx_create_dir_with_check(cf, s, create_dirs)) goto nodir;
  
  memcpy(p, kind, kind_len+1);
  p += kind_len;
  if (!zx_create_dir_with_check(cf, s, create_dirs)) goto nodir;
  
  sha1_safe_base64(p, objid->len, objid->s);
  p[27] = 0;
  p+=27;
  return zx_ref_len_str(cf->ctx, len, s);
 nodir:
  ZX_FREE(cf->ctx, s);
  return 0;
}

/*() Check if file by path already exist.
 * Since each uniquely ID'd object has unique path, mere existence of a file
 * serves as duplicate ID check. This is used to satisfy some SAML processing rule
 * requirements such as duplicate ID check for assertions.
 *
 * cf::      ZXID configuration object, used for memory allocation
 * path::    Path where file is to be written, usually from zxlog_path()
 * logkey::  String that will help to identify reason of failure
 * return::  0 if no duplicate (success), 1 if duplicate (failure)
 */

/* Called by:  zxid_anoint_a7n, zxid_anoint_sso_resp, zxid_decode_redir_or_post x2, zxid_saml2_post_enc, zxid_saml2_redir_enc, zxid_soap_cgi_resp_body, zxid_sp_sso_finalize, zxid_sso_issue_jwt, zxid_wsc_valid_re_env, zxid_wsf_validate_a7n, zxid_wsp_validate */
int zxlog_dup_check(zxid_conf* cf, struct zx_str* path, const char* logkey)
{
  struct stat st;
  if (!cf || !path || !logkey) {
    ERR("Missing config, path, or logkey argument %p %p (programmer error)", path, logkey);
    return 0;
  }
  /* We need a c path, but get zx_str. However, the zx_str will come from zxlog_path()
   * so we should be having the nul termination as needed. Just checking. */
  ASSERTOPI(path->s[path->len], ==, 0);
  if (!stat(path->s, &st)) {
    ERR("Duplicate %s path(%.*s)", logkey, path->len, path->s);
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "C", "EDUP", path->s, "%s", logkey);
    return 1;
  }
  return 0;
}

/*() Write a blob of content to log file according to logflag (see zxidconf.h). If
 * the file already exists, i.e. there is a duplicate, the data is simply appended.
 * When logging objects such as assertions, the duplicate check should be done
 * as preprocessing step, see example below.
 *
 * cf::      ZXID configuration object, used for memory allocation
 * logflag:: 0 if logging should not happen, 1 for normal logging, other values reserved
 * path::    Path where file is to be written, usually from zxlog_path()
 * blob::    The data to be logged.
 * lk::      Log key. Indicates which part of the program invoked the logging function.
 * return::  0 if no log written (failure or logflag false), 1 if log written. Often ignored.
 *
 * *Example*
 *
 *   logpath = zxlog_path(cf, issuer, a7n->ID, "rely/", "/a7n/", 1);
 *   if (logpath) {
 *     if (zxlog_dup_check(cf, logpath, "SSO assertion")) {
 *       zxlog_blob(cf, cf->log_rely_a7n, logpath, zx_easy_enc_elem_sig(cf,&a7n->gg), "E");
 *       goto erro;
 *     }
 *     zxlog_blob(cf, cf->log_rely_a7n, logpath, zx_easy_enc_elem_sig(cf, a7n), "OK");
 *   }
 *
 * In the above example we determine the logpath and check for the duplicate and then log even
 * if duplicate. The logic of this is that in case of duplicate, the audit trail
 * captures both the original and the duplicate assertion (the logging is an append),
 * which may have forensic value. */

/* Called by:  zxbus_send_cmdf, zxid_anoint_a7n x2, zxid_anoint_sso_resp x2, zxid_decode_redir_or_post x2, zxid_saml2_post_enc x2, zxid_saml2_redir_enc x2, zxid_soap_cgi_resp_body x2, zxid_sp_sso_finalize x2, zxid_sso_issue_jwt x2, zxid_wsc_valid_re_env x2, zxid_wsf_validate_a7n x2, zxid_wsp_validate x2 */
int zxlog_blob(zxid_conf* cf, int logflag, struct zx_str* path, struct zx_str* blob, const char* lk)
{
  if (!logflag || !blob)
    return 0;
  if (logflag != 1) {
    ERR("Unimplemented blob logging format: %x", logflag);
    return 0;
  }
  
  /* We need a c path, but get zx_str. However, the zx_str will come from zxlog_path()
   * so we should be having the nul termination as needed. Just checking. */
  D("%s: LOGBLOB15(%.*s) len=%d path(%.*s)", lk, MIN(blob->len,15), blob->s, blob->len, path->len, path->s);
  DD("%s: LOGBLOB(%.*s)", lk, blob->len, blob->s);
  ASSERTOPI(path->s[path->len], ==, 0);
  if (!write2_or_append_lock_c_path(path->s, blob->len, blob->s, 0, 0, "zxlog blob", SEEK_END,O_APPEND)) {
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "EFILE", 0, "Could not write blob. Permissions?");
  }
  return 1;
}

#define XML_LOG_FILE ZXID_PATH "log/xml.dbg"
FILE* zx_xml_debug_log = 0;
int zx_xml_debug_log_err = 0;
int zxlog_seq = 0;

#if !defined(USE_STDIO) && !defined(MINGW)
/* *** Static initialization of struct flock is suspect since man fcntl() documentation
 * does not guarantee ordering of the fields, or that they would be the first fields.
 * On Linux-2.4 and 2.6 as well as Solaris-8 the ordering is as follows, but this needs
 * to be checked on other platforms.
 *                       l_type,  l_whence, l_start, l_len */
extern struct flock errmac_rdlk; /* = { F_RDLCK, SEEK_SET, 0, 1 };*/
extern struct flock errmac_wrlk; /* = { F_WRLCK, SEEK_SET, 0, 1 };*/
extern struct flock errmac_unlk; /* = { F_UNLCK, SEEK_SET, 0, 1 };*/
#endif

/* Called by:  errmac_debug_xml_blob */
static FILE* zx_open_xml_log_file(zxid_conf* cf)
{
  FILE* f;
  char buf[ZXID_MAX_DIR];
  if (!cf||!cf->cpath) {
    strncpy(buf, XML_LOG_FILE, sizeof(buf));
  } else {
    snprintf(buf, sizeof(buf)-1, "%slog/xml.dbg", cf->cpath);
    buf[sizeof(buf)-1]=0;
  }
  f = fopen(buf, "a+");
  if (!f) {  /* If it did not work out, do not insist. */
    perror(buf);
    ERR("Can't open for appending %s: %d %s; euid=%d egid=%d", buf, errno, STRERROR(errno), geteuid(), getegid());
    zx_xml_debug_log_err = 1;
    return 0;
  }
  D("OPEN BLOB LOG: tailf %s | ./xml-pretty.pl", buf);
  return f;
}

/*() Log a blob of XML data to auxiliary log file. This avoids
 * mega clutter in the main debug logs. You are supposed
 * to view this file with:
 * tailf /var/zxid/log/xml.dbg | ./xml-pretty.pl
 *
 * cf:: Config (and memory allocation) object
 * file:: Source code file, see __FILE__ in D_XML_BLOB() macro, in errmac.h
 * line:: Source code line number, see __LINE__ in D_XML_BLOB()
 * func:: Source code function name, see __FUNCTION__ in D_XML_BLOB()
 * lk:: Log key
 * len:: Length of the blob, or -1 for error or -2 to use strlen()
 * xml:: blob data (not always XML)
 */

/* Called by: */
void errmac_debug_xml_blob(zxid_conf* cf, const char* file, int line, const char* func, const char* lk, int len, const char* xml)
{
  int bdy_len;
  const char* bdy;
  const char* p;
  const char* q;
  if (!(errmac_debug & ERRMAC_XMLDBG) || len == -1 || !xml)
    return;
  if (len == -2)
    len = strlen(xml);

  /* Detect body */

  for (p = xml; p; p+=4) {
    p = strstr(p, "Body");
    if (!p) {
nobody:
      bdy = xml;
      bdy_len = 40;
      goto print_it;
    }
    if (p > xml && ONE_OF_2(p[-1], '<', ':') && ONE_OF_5(p[4], '>', ' ', '\t', '\r', '\n'))
      break; /* Opening <Body> detected. */
  }
  if (!p)
    goto nobody;
  
  p = strchr(p+4, '>');  /* Scan for close of opening <Body */
  if (!p)
    goto nobody;
  
  for (q = ++p; q; q+=5) {
    q = strstr(q, "Body>");
    if (!q)
      goto nobody;  /* Missing closing </Body> tag */
    if (ONE_OF_2(q[-1], '<', ':'))
      break;
  }
  for (--q; *q != '<'; --q) ;  /* Scan for the start of </Body>, skipping any namespace prefix */
  bdy = p;
  bdy_len = MIN(q-p, 100);

print_it:
  ++zxlog_seq;
#ifdef USE_PTHREAD
# ifdef USE_AKBOX_FN
  fprintf(stderr, "%d.%lx %04x:%-3d %s d %s%s(%.*s) len=%d %d:%d\n", getpid(), (long)pthread_self(), akbox_fn(func), __LINE__, ERRMAC_INSTANCE, errmac_indent, lk, bdy_len, bdy, len, getpid(), zxlog_seq);
# else
  fprintf(stderr, "%d.%lx %10s:%-3d %-16s %s d %s%s(%.*s) len=%d %d:%d\n", getpid(), (long)pthread_self(), file, line, func, ERRMAC_INSTANCE, errmac_indent, lk, bdy_len, bdy, len, getpid(), zxlog_seq);
# endif
#else
# ifdef USE_AKBOX_FN
  fprintf(stderr, "%d %04x:%-3d %s d %s%s(%.*s) len=%d %d:%d\n", getpid(), akbox_fn(func), __LINE__, ERRMAC_INSTANCE, errmac_indent, lk, bdy_len, bdy, len, getpid(), zxlog_seq);
# else
  fprintf(stderr, "%d %10s:%-3d %-16s %s d %s%s(%.*s) len=%d %d:%d\n", getpid(), file, line, func, ERRMAC_INSTANCE, errmac_indent, lk, bdy_len, bdy, len, getpid(), zxlog_seq);
# endif
#endif

  if (!zx_xml_debug_log) {
    if (zx_xml_debug_log_err)
      return;
    zx_xml_debug_log = zx_open_xml_log_file(cf);
    if (!zx_xml_debug_log)
      return;
  }
  
  if (FLOCKEX(fileno(zx_xml_debug_log)) == -1) {
    ERR("Locking exclusively file `%s' failed: %d %s. Check permissions and that the file system supports locking. euid=%d egid=%d", XML_LOG_FILE, errno, STRERROR(errno), geteuid(), getegid());
    /* Fall thru to print without locking */
  }
#ifdef USE_PTHREAD
# ifdef USE_AKBOX_FN
  fprintf(zx_xml_debug_log, "<!-- XMLBEG %d.%lx:%d %04x:%-3d %s d %s %s len=%d -->\n%.*s\n<!-- XMLEND %d.%lx:%d %s -->\n", getpid(), (long)pthread_self(), zxlog_seq, akbox_fn(func), line, ERRMAC_INSTANCE, errmac_indent, lk, len, len, xml, getpid(), (long)pthread_self(), zxlog_seq, lk);
# else
  fprintf(zx_xml_debug_log, "<!-- XMLBEG %d.%lx:%d %10s:%-3d %-16s %s d %s %s len=%d -->\n%.*s\n<!-- XMLEND %d.%lx:%d %s -->\n", getpid(), (long)pthread_self(), zxlog_seq, file, line, func, ERRMAC_INSTANCE, errmac_indent, lk, len, len, xml, getpid(), (long)pthread_self(), zxlog_seq, lk);
# endif
#else
# ifdef USE_AKBOX_FN
  fprintf(zx_xml_debug_log, "<!-- XMLBEG %d:%d %04x:%-3d %s d %s %s len=%d -->\n%.*s\n<!-- XMLEND %d:%d %s -->\n", getpid(), zxlog_seq, akbox_fn(func), line, ERRMAC_INSTANCE, errmac_indent, lk, len, len, xml, getpid(), zxlog_seq, lk);
# else
  fprintf(zx_xml_debug_log, "<!-- XMLBEG %d:%d %10s:%-3d %-16s %s d %s %s len=%d -->\n%.*s\n<!-- XMLEND %d:%d %s -->\n", getpid(), zxlog_seq, file, line, func, ERRMAC_INSTANCE, errmac_indent, lk, len, len, xml, getpid(), zxlog_seq, lk);
# endif
#endif
  fflush(zx_xml_debug_log);
  FUNLOCK(fileno(zx_xml_debug_log));
}

/*() Generate a timestamped receipt for data.
 * Typically used for issuing receipts on audit bus. The current time
 * and our own signing certificate are used.
 *
 * cf::         ZXID configuration object, used for memory allocation and cert mgmt
 * sigbuf_len:: Maximum length of signature buffer, e.g. 1024. On return buffer is nul terminated.
 * sigbuf::     Result parameter. Caller allocated buffer that receives the receipt. nul term.
 * mid_len::    Length of message id to issue receipt about (-1 to use strlen(mid))
 * mid::        Message ID to issue receipt about, will be part of signature.
 * dest_len::   Length of destination to issue receipt about (-1 to use strlen(dest))
 * dest::       Destination channel to issue receipt about, will be signed.
 * eid_len::    Length of entity id to issue receipt to (-1 to use strlen(eid))
 * eid::        Entity ID to issue receipt about, will be part of signature.
 * body_len::   Length of data to issue receipt about (-1 to use strlen(body))
 * body::       Data to issue receipt about, i.e. data that will be signed.
 * return::     sigbuf. If there was error, first character of sigbuf is set to 'E' */

/* Called by:  stomp_send_receipt, test_receipt x9 */
char* zxbus_mint_receipt(zxid_conf* cf, int sigbuf_len, char* sigbuf, int mid_len, const char* mid, int dest_len, const char* dest, int eid_len, const char* eid, int body_len, const char* body)
{
  int len, zlen;
  char* zbuf = 0;
  char* p;
  char* buf;
  struct tm ot;
  struct timeval ourts;
  
  if (!mid)
    mid_len = 0;
  if (mid_len == -1)
    mid_len = strlen(mid);
  else if (mid_len == -2)
    mid_len = strchr(mid, '\n') - mid;

  if (!dest)
    dest_len = 0;
  if (dest_len == -1)
    dest_len = strlen(dest);
  else if (dest_len == -2)
    dest_len = strchr(dest, '\n') - dest;

  if (!eid)
    eid_len = 0;
  if (eid_len == -1)
    eid_len = strlen(eid);
  else if (eid_len == -2)
    eid_len = strchr(eid, '\n') - eid;

  if (!body)
    body_len = 0;
  if (body_len == -1)
    body_len = strlen(body);
  else if (body_len == -2)
    body_len = strchr(body, '\n') - body;

  /* Prepare values */

  GETTIMEOFDAY(&ourts, 0);
  GMTIME_R(ourts.tv_sec, ot);

  /* Prepare timestamp prepended data for hashing */
  len = ZXLOG_TIME_SIZ+1+mid_len+1+dest_len+1+eid_len+1+body_len;
  buf = ZX_ALLOC(cf->ctx, len+1);
  zlen = snprintf(buf, len+1, ZXLOG_TIME_FMT " %.*s %.*s %.*s %.*s",
		  ZXLOG_TIME_ARG(ot, ourts.tv_usec),
		  mid_len, mid_len?mid:"",
		  dest_len, dest_len?dest:"",
		  eid_len, eid_len?eid:"",
		  body_len, body_len?body:"");
  ASSERTOPI(zlen, ==, len);
  buf[len] = 0; /* must terminate manually as on win32 nul is not guaranteed */

  ASSERT(sigbuf_len >= 3+ZXLOG_TIME_SIZ+1);
  strcpy(sigbuf, "EP ");
  memcpy(sigbuf+3, buf, ZXLOG_TIME_SIZ);
  sigbuf[3+ZXLOG_TIME_SIZ] = ' ';
  memcpy(sigbuf+3+ZXLOG_TIME_SIZ+1, mid, mid_len);
  sigbuf[3+ZXLOG_TIME_SIZ+1+mid_len] = 0;
  
  switch (cf->bus_rcpt & 0x06) {
  case 0x02:   /* SP plain sha */
    if (sigbuf_len < 3+ZXLOG_TIME_SIZ+1+mid_len+1+27+1) { ERR("Too small sigbuf %d", sigbuf_len); break; }
    D("sha len=%d input(%.*s)", len, len, buf);
    sigbuf[3+ZXLOG_TIME_SIZ+1+mid_len] = ' ';
    sha1_safe_base64(sigbuf+3+ZXLOG_TIME_SIZ+1+mid_len+1, len, buf);
    sigbuf[3+ZXLOG_TIME_SIZ+1+mid_len+1+27] = 0;
    sigbuf[0] = 'S';
    break;
  case 0x04:   /* RP RSA-SHA signature (detected from key) */
  case 0x06:   /* RP DSA-SHA signature (detected from key) */
    LOCK(cf->mx, "mint_receipt");      
    /* The sign_pkey is used instead of log_sign_pkey because metadata is used to distribute it. */
    if (!cf->sign_pkey)
      cf->sign_pkey = zxid_read_private_key(cf, "sign-nopw-cert.pem");
    UNLOCK(cf->mx, "mint_receipt");
    DD("sign_pkey=%p buf(%.*s) len=%d buf(%s)", cf->sign_pkey, len, buf, len, buf);
    if (!cf->sign_pkey)
      break;

    zlen = zxsig_data(cf->ctx, len, buf, &zbuf, cf->sign_pkey, "receipt", cf->blobsig_digest_algo);

    if (errmac_debug>2) HEXDUMP("zbuf:", zbuf, zbuf+zlen, 4096);
    len = 3+ZXLOG_TIME_SIZ+1+mid_len+1+SIMPLE_BASE64_LEN(zlen)+1;
    if (sigbuf_len < len) { ERR("Too small sigbuf_len=%d, need=%d", sigbuf_len, len); break; }
    sigbuf[3+ZXLOG_TIME_SIZ+1+mid_len] = ' ';
    p = base64_fancy_raw(zbuf, zlen, sigbuf+3+ZXLOG_TIME_SIZ+1+mid_len+1, safe_basis_64, 1<<31, 0, 0, '.');
    *p = 0;
    switch (EVP_PKEY_type(cf->sign_pkey->type)) {
    case EVP_PKEY_RSA: sigbuf[0] = 'R'; break;
    case EVP_PKEY_DSA: sigbuf[0] = 'D'; break;
    case EVP_PKEY_EC:  sigbuf[0] = 'C'; break;
    default: sigbuf[0] = 'E'; ERR("Unknown pkey type=%d", EVP_PKEY_type(cf->sign_pkey->type));
    }
    break;
  case 0:      /* Plain logging, no signing, no encryption. */
    sigbuf[0] = 'P';
    break;
  }

  DD("body(%.*s) body_len=%d", body_len, body_len?body:"", body_len);
  if (errmac_debug>1)
    D("zx-rcpt-sig(%s) sigbuf_len=%d len=%d\nbuf(%s) buflen=%d %x %x", sigbuf, (int)strlen(sigbuf), len, buf, (int)strlen(buf), cf->bus_rcpt, cf->bus_rcpt&0x06);
  else
    D("zx-rcpt-sig(%s) %x", sigbuf, cf->bus_rcpt);
  if (zbuf)
    ZX_FREE(cf->ctx, zbuf);
  ZX_FREE(cf->ctx, buf);
  return sigbuf;
}

/*() Verify a zxbus receipt signature.
 *
 * cf::         ZXID configuration object, used for memory allocation and CoT mgmt
 * eid::        EntityID of the receipt issuing party, used to lookup metadata
 * sigbuf_len:: Length of signature buffer (from zx-rcpt-sig header) or -1 for strlen(sigbuf)
 * sigbuf::     The receipt (from zx-rcpt-sig header)
 * mid_len::    Length of message id (-1 to use strlen(mid))
 * mid::        Message ID
 * dest_len::   Length of destination (-1 to use strlen(dest))
 * dest::       Destination channel for the receipt
 * deid_len::   Length of destination entity id (-1 to use strlen(eid))
 * deid::       Entity ID of receiving party
 * body_len::   Length of data pertaining to receipt (-1 to use strlen(body))
 * body::       Data pertaining to receipt
 * return::     0 (ZXSIG_OK) on success, nonzero on failure. */

/* Called by:  stomp_got_ack, test_receipt x10, zxbus_send_cmdf */
int zxbus_verify_receipt(zxid_conf* cf, const char* eid, int sigbuf_len, char* sigbuf, int mid_len, const char* mid, int dest_len, const char* dest, int deid_len, const char* deid, int body_len, const char* body)
{
  int ver = -4, len, zlen;
  char* p;
  char* buf;
  char sig[1024];
  char sha1[20];
  zxid_entity* meta;

  if (sigbuf_len == -1)
    sigbuf_len = strlen(sigbuf);
  else if (sigbuf_len == -2)
    sigbuf_len = strchr(sigbuf, '\n') - sigbuf;
  
  if (!mid)
    mid_len = 0;
  if (mid_len == -1)
    mid_len = strlen(mid);
  else if (mid_len == -2)
    mid_len = strchr(mid, '\n') - mid;

  if (!dest)
    dest_len = 0;
  if (dest_len == -1)
    dest_len = strlen(dest);
  else if (dest_len == -2)
    dest_len = strchr(dest, '\n') - dest;

  if (!deid)
    deid_len = 0;
  if (deid_len == -1)
    deid_len = strlen(deid);
  else if (deid_len == -2)
    deid_len = strchr(deid, '\n') - deid;

  if (!body)
    body_len = 0;
  if (body_len == -1)
    body_len = strlen(body);
  else if (body_len == -2)
    body_len = strchr(body, '\n') - body;
  
  DD("body(%.*s) body_len=%d", body_len, body_len?body:"", body_len);
  D("zx-rcpt-sig(%.*s) sigbuf_len=%d", sigbuf_len, sigbuf, sigbuf_len);

  len = ZXLOG_TIME_SIZ+1+mid_len+1+dest_len+1+deid_len+1+body_len;
  //len = ZXLOG_TIME_SIZ+1+body_len;
  buf = ZX_ALLOC(cf->ctx, len+1);
  zlen = snprintf(buf, len+1, "%.*s %.*s %.*s %.*s %.*s",
		  ZXLOG_TIME_SIZ, sigbuf+3,
		  mid_len, mid_len?mid:"",
		  dest_len, dest_len?dest:"",
		  deid_len, deid_len?deid:"",
		  body_len, body_len?body:"");
  ASSERTOPI(zlen, ==, len);
  buf[len] = 0; /* must terminate manually as on win32 nul is not guaranteed */

  switch (sigbuf[0]) {
  case 'R':
  case 'D':
  case 'C':
    meta = zxid_get_ent(cf, eid);
    if (!meta) {
      ERR("Unable to find metadata for eid(%s) in verify receipt", eid);
      ver = -2;
      break;
    }
    //D("check_private_key(%d)",X509_check_private_key(meta->sign_cert, cf->sign_pkey));
    if (SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(sigbuf_len) > sizeof(sig)) {
      ERR("Available signature decoding buffer is too short len=%d, need=%d", (int)sizeof(sig), SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(sigbuf_len));
      ver = -3;
      break;
    }
    p = sigbuf+3+ZXLOG_TIME_SIZ+1+mid_len+1;
    DD("zx-rcpt-sig(%.*s) sigbuf_len=%d", sigbuf_len, sigbuf, sigbuf_len);
    D("sigbuf(%.*s) len=%d sigbuf=%p lim=%p", (int)(sigbuf_len-(p-sigbuf)), p, (int)(sigbuf_len-(p-sigbuf)), p, sigbuf+sigbuf_len);
    p = unbase64_raw(p, sigbuf+sigbuf_len, sig, zx_std_index_64);

    ver = zxsig_verify_data(len, buf, p-sig, sig, meta->sign_cert, "rcpt vfy", cf->blobsig_digest_algo);

    if (ver)
      D("ver=%d buf(%.*s) len=%d", ver, len, buf, len);
    break;
  case 'S':
    if (SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(sigbuf_len) > sizeof(sig)) {
      ERR("Available signature decoding buffer is too short len=%d, need=%d", (int)sizeof(sig), SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(sigbuf_len));
      ver = -3;
      break;
    }
    p = sigbuf+3+ZXLOG_TIME_SIZ+1+mid_len+1;
    unbase64_raw(p, sigbuf+sigbuf_len, sig, zx_std_index_64);
    SHA1((unsigned char*)buf, len, (unsigned char*)sha1);
    ver = memcmp(sig, sha1, 20);  /* 0 on success */
    if (ver) {
      ERR("SHA1 mismatch in receipt %d",ver);
      D("sha len=%d input(%.*s)", len, len, buf);
      D("sigbuf(%.*s) len=%d sigbuf=%p lim=%p", (int)(sigbuf_len-(p-sigbuf)), p, (int)(sigbuf_len-(p-sigbuf)), p, sigbuf+sigbuf_len);
      D("old sha1 %d", hexdmp("old sha1",sig,20,20));
      D("new sha1 %d", hexdmp("new sha1",sha1,20,20));
    }
    break;
  case 'P': D("P: no sig to check %d",0); ver = 0; break;
  default:
    ERR("Unsupported receipt signature algo(%c) sig(%.*s)", sigbuf[0], sigbuf_len, sigbuf);
  }
  ZX_FREE(cf->ctx, buf);
  return ver;
}

int zxbus_persist_flag = 1;

/*() Attempt to persist a message.
 * Persisting involves synchronous write and an atomic filesystem rename
 * operation, ala Maildir. The persisted message is a file that contains
 * the entire STOMP 1.1 PDU including headers and body. Filename is the sha1
 * hash of the contents of the file.
 *
 * return:: 0 on failure, nonzero len of c_path on success.
 * See also:: persist feature in zxbus_listen_msg() */

/* Called by:  zxbus_persist */
int zxbus_persist_msg(zxid_conf* cf, int c_path_len, char* c_path, int dest_len, const char* dest, int data_len, const char* data)
{
  int len;
   const char* p;
  char t_path[ZXID_MAX_BUF];  /* temp path before atomic rename */
  
  if (dest_len < 1)
    return 0;
  while (*dest == '/') {      /* skip initial /s, if any. I.e. no absolute path permitted */
    ++dest;
    --dest_len;
  }
  if (dest_len < 1)
    return 0;
  if (ONE_OF_3(*dest, '\n', 0, '\r')) {
    ERR("Empty dest (or one consisting etirely of slashes) %x", *dest);
    return 0;
  }
  
  /* Sanity check destination for any cracking attempts. */
  for (p = dest; p < dest+dest_len; ++p) {
    if (p[0] == '.' && p[1] == '.') {
      ERR("SEND destination is a .. hack(%.*s)", dest_len, dest);
      return 0;
    }
    if (ONE_OF_2(*p, '~', '\\') || *p > 122 || *p < 33) {
      ERR("SEND destination bad char 0x%x hack(%.*s)", *p, dest_len, dest);
      return 0;
    }
  }
  
  /* Persist the message, use Maildir style rename from tmp/ to ch/ */
  
  len = name_from_path(c_path, c_path_len, "%s" ZXBUS_CH_DIR "%.*s/", cf->cpath, dest_len, dest);
  if (sizeof(c_path)-len < 28+1 /* +1 accounts for t_path having one more char (tmp vs. ch) */) {
    ERR("The c_path for persisting exceeds limit. len=%d", len);
    return 0;
  }
  DD("c_path(%s) len=%d PATH(%s) dest(%.*s)", c_path, len, cf->cpath, dest_len, dest);
  sha1_safe_base64(c_path+len, data_len, data);
  len += 27;
  c_path[len] = 0;
  DD("c_path(%s)", c_path);
  
  name_from_path(t_path, sizeof(t_path), "%stmp/%s", cf->cpath, c_path+len-27);
  
  /* Perform synchronous write to disk. Read man 2 open for discussion. It is not
   * completely clear, but it appears that this is still not sufficient to guarantee
   * the appearance of the file in the respective directory, but perhaps fsck(8) could
   * recover it. *** we may want to make a fsync(2) call on the directory fd as well!
   * The disk should not be NFS mounted as O_SYNC is illdefined in NFS. Also, the
   * tmp/, ch/DEST/, and ch/DEST/.del directories should be on the same filesystem - otherwise
   * the rename(2) will not work.*/
  //  | O_DIRECT  -- seems to give alignment problems, i.e. 22 EINVAL Invalid Argument
  if (!write2_or_append_lock_c_path(t_path, 0, 0, data_len, data, "zxbus persist", SEEK_SET, O_TRUNC | O_SYNC)) {
    return 0;
  }
  
  if (rename(t_path, c_path)) {
    ERR("Renaming file(%s) to(%s) for atomicity failed: %d %s. Check permissions and that directories exist. Directories must be on the same filesystem. euid=%d egid=%d", t_path, c_path, errno, STRERROR(errno), geteuid(), getegid());
    return 0;
  }
  return len;
}

/* EOF  --  zxlog.c */
