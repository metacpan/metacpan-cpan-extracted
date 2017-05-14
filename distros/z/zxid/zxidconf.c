/* zxidconf.c  -  Handwritten functions for parsing ZXID configuration file
 * Copyright (c) 2012-2016 Synergetics (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidconf.c,v 1.51 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 16.1.2007, split from zxidlib.c --Sampo
 * 27.3.2007, lazy reading of certificates --Sampo
 * 22.2.2008, added path_supplied feature --Sampo
 * 7.10.2008, added documentation --Sampo
 * 29.8.2009, added Auto-Cert feature a.k.a. zxid_mk_self_signed_cert() --Sampo
 * 4.9.2009,  added NEED, WANT, INMAP, PEPMAP, OUTMAP, and ATTRSRC --Sampo
 * 15.11.2009, added SHOW_CONF (o=d) option --Sampo
 * 7.1.2010,  added WSC and WSP signing options --Sampo
 * 12.2.2010, added pthread locking --Sampo
 * 31.5.2010, added 4 web service call PEPs --Sampo
 * 21.4.2011, fixed DSA key reading and reading unqualified keys --Sampo
 * 3.12.2011, added VPATH feature --Sampo
 * 10.12.2011, added VURL and BUTTON_URL, deleted ORG_URL except for legacy check --Sampo
 * 17.8.2012, added audit bus configuration --Sampo
 * 16.2.2013, added WD option --Sampo
 * 21.6.2013, added wsp_pat --Sampo
 * 20.11.2013, added %d expansion for VURL, added ECHO for debug prints --Sampo
 * 29.11.2013, added INCLUDE feature --Sampo
 * 4.12.2013,  changed URL to BURL --Sampo
 * 11.4.2015,  added UNIX_GRP_AZ_MAP --Sampo
 * 18.12.2015, applied patch from soconnor, perceptyx, including detection of
 *             signature algorithm from certificate. --Sampo
 * 8.1.2016,   added configuration options for signature and digest algorithms --Sampo
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include <malloc.h>
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <grp.h>
#ifdef USE_CURL
#include <curl/curl.h>
#endif

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "zxidpriv.h"
#include "c/zxidvers.h"

/* ============== Configuration ============== */
/* Eventually configuration will be read from some file, but for
 * now, we settle for compilation time configuration, see zxidconf.h */

#ifdef USE_OPENSSL

#include <openssl/rand.h>
#include <openssl/x509.h>
#include <openssl/rsa.h>

#if 0
/*(-) Compute raw SHA1 digest hash over contents of a file.
 *
 * cf:: ZXID configuration object, used for deteminin path prefix and for memory allocation
 * name:: Name of the file (under hierarchy defined by PATH configuration option)
 * sha1:: A sha1 buffer which should be exactly 20 bytes (160 bits) long. The
 *     buffer will be modified in place by this function. */

/* Called by:  zxid_init_conf */
void zxid_sha1_file(zxid_conf* cf, char* name, char* sha1)
{
  int gotall;
  char* buf;
  ZERO(sha1, 20);
  buf = read_all_alloc(cf->ctx, "sha1_file", 1, &gotall, "%s%s", cf->cpath, name);
  if (!buf)
    return;
  SHA1(buf, gotall, sha1);
  ZX_FREE(cf->ctx, buf);
}
#endif

char* zxid_extract_cert_pem(char* buf, char* name)
{
  char* p;
  char* e;
  p = strstr(buf, PEM_CERT_START);
  if (!p) {
    ERR("No certificate found in file(%s)\n", name);
    return 0;
  }
  p += sizeof(PEM_CERT_START) - 1;
  if (*p == 0xd) ++p;
  if (*p != 0xa) return 0;
  ++p;
  
  e = strstr(buf, PEM_CERT_END);
  if (!e) return 0;
  *e = 0;
  return p;
}

/*() Extract a certificate as base64 textr from PEM encoded file. */

char* zxid_read_cert_pem(zxid_conf* cf, char* name, int siz, char* buf)
{
  int got = read_all(siz, buf, "read_cert", 1, "%s" ZXID_PEM_DIR "%s", cf->cpath, name);
  if (!got && cf->auto_cert)
    zxid_mk_self_sig_cert(cf, siz, buf, "read_cert", name);
  return zxid_extract_cert_pem(buf, name);
}


/*() Extract a certificate from PEM encoded string. */

/* Called by:  opt, test_mode, zxid_read_cert */
X509* zxid_extract_cert(char* buf, char* name)
{
  X509* x = 0;  /* Forces d2i_X509() to alloc the memory. */
  char* p;
  char* e;
  p = zxid_extract_cert_pem(buf, name);
  if (!p)
    return 0;
  e = unbase64_raw(p, p+strlen(p), p, zx_std_index_64);
  OpenSSL_add_all_algorithms();
  if (!d2i_X509(&x, (const unsigned char**)&p /* *** compile warning */, e-p) || !x) {
    ERR("DER decoding of X509 certificate failed.\n%d", 0);
    return 0;
  }
  return x;
}

/*() Extract a certificate from PEM encoded file. */

/* Called by:  hi_new_shuffler, zxid_idp_sso_desc x2, zxid_init_conf x3, zxid_lazy_load_sign_cert_and_pkey, zxid_sp_sso_desc x2, zxlog_write_line */
X509* zxid_read_cert(zxid_conf* cf, char* name)
{
  X509* x = 0;  /* Forces d2i_X509() to alloc the memory. */
  char buf[8192];
  char* p;
  char* e;
  p = zxid_read_cert_pem(cf, name, sizeof(buf), buf);
  if (!p)
    return 0;
  OpenSSL_add_all_algorithms();
  e = unbase64_raw(p, p+strlen(p), p, zx_std_index_64);
  if (!d2i_X509(&x, (const unsigned char**)&p /* *** compile warning */, e-p) || !x) {
    ERR("DER decoding of X509 certificate failed.\n%d", 0);
    return 0;
  }
  return x;
}

/*() Extract a private key from PEM encoded string.
 * *** This function needs to expand to handle DSA and EC */

/* Called by: */
EVP_PKEY* zxid_extract_private_key(char* buf, char* name)
{
  char* p;
  char* e;
  int typ;
  EVP_PKEY* pk = 0;  /* Forces d2i_PrivateKey() to alloc the memory. */
  OpenSSL_add_all_algorithms();
  
  if (p = strstr(buf, PEM_RSA_PRIV_KEY_START)) {
    typ = EVP_PKEY_RSA;
    e = PEM_RSA_PRIV_KEY_END;
    p += sizeof(PEM_RSA_PRIV_KEY_START) - 1;
  } else if (p = strstr(buf, PEM_DSA_PRIV_KEY_START)) {
    typ = EVP_PKEY_DSA;
    e = PEM_DSA_PRIV_KEY_END;
    p += sizeof(PEM_DSA_PRIV_KEY_START) - 1;
  } else if (p = strstr(buf, PEM_PRIV_KEY_START)) {  /* Not official format, but sometimes seen. */
    typ = EVP_PKEY_RSA;
    e = PEM_PRIV_KEY_END;
    p += sizeof(PEM_PRIV_KEY_START) - 1;
  } else {
    ERR("No private key found in file(%s). Looking for separator (%s) or (%s).\npem data(%s)", name, PEM_RSA_PRIV_KEY_START, PEM_DSA_PRIV_KEY_START, buf);
    return 0;
  }
  if (*p == 0xd) ++p;
  if (*p != 0xa) {
    ERR("Bad privkey missing newline ch(0x%x) at %ld (%.*s) of buf(%s)", *p, (long)(p-buf), 5, p-2, buf);
    return 0;
  }
  ++p;

  e = strstr(buf, e);
  if (!e) {
    ERR("End marker not found, typ=%d", typ);
    return 0;
  }
  
  zx_report_openssl_err("extract_private_key0"); /* *** seems something leaves errors on stack */
  p = unbase64_raw(p, e, buf, zx_std_index_64);
  if (!d2i_PrivateKey(typ, &pk, (const unsigned char**)&buf, p-buf) || !pk) {
    zx_report_openssl_err("extract_private_key"); /* *** seems d2i can leave errors on stack */
    ERR("DER decoding of private key failed.\n%d", 0);
    return 0;
  }
  zx_report_openssl_err("extract_private_key2"); /* *** seems d2i can leave errors on stack */
  return pk; /* RSA* rsa = EVP_PKEY_get1_RSA(pk); */
}

/*() Extract a private key from PEM encoded file. */

/* Called by:  hi_new_shuffler, test_ibm_cert_problem x2, test_ibm_cert_problem_enc_dec x2, zxbus_mint_receipt x2, zxenc_privkey_dec, zxid_init_conf x3, zxid_lazy_load_sign_cert_and_pkey, zxlog_write_line x2 */
EVP_PKEY* zxid_read_private_key(zxid_conf* cf, char* name)
{
  char buf[8192];
  int got = read_all(sizeof(buf),buf,"read_private_key",1, "%s" ZXID_PEM_DIR "%s", cf->cpath, name);
  if (!got && cf->auto_cert)
    zxid_mk_self_sig_cert(cf, sizeof(buf), buf, "read_private_key", name);
  return zxid_extract_private_key(buf, name);
}

/*() Lazy load signing certificate and private key. This reads them from disk
 * if needed. If they do not exist and auto_cert is enabled, they will be
 * generated on disk and then read. Once read from disk, they will be cached in
 * memory.
 *
 * > N.B. If the cert does not yet exist, write access to disk will be needed.
 * > If it already exists, read access is sufficient. Thus it is more secure
 * > to pregenerate the certificate and then set the permissions so that
 * > the process can read it, but can not alter it.
 *
 * cf:: Configuration object
 * cert:: result parameter. If non null, the certificate will be extracted
 *     from file and pointer to the X509 data structure will be deposited
 *     to place pointed by this parameter. If null, certificate is neither
 *     extracted nor returned. The data structure should be freed by the
 *     caller.
 * pkey:: result parameter. Must be specified. The private key data structure
 *     is extracted from the file and returned using this parameter. The
 *     data structure should be freed by the caller.
 * logkey:: Free form string describing why the cert and private key are
 *     being requested. Used for logging and debugging.
 * return:: Returns 1 on success and 0 on failure.
 */

/* Called by:  zxid_anoint_a7n, zxid_anoint_sso_resp, zxid_az_soap x3, zxid_idp_soap_dispatch x2, zxid_idp_sso, zxid_mk_art_deref, zxid_mk_at_cert, zxid_saml2_post_enc, zxid_saml2_redir_enc, zxid_sp_mni_soap, zxid_sp_slo_soap, zxid_sp_soap_dispatch x7, zxid_ssos_anreq, zxid_wsf_sign */
int zxid_lazy_load_sign_cert_and_pkey(zxid_conf* cf, X509** cert, EVP_PKEY** pkey, const char* logkey)
{
  LOCK(cf->mx, logkey);
  if (cert) {
    if (!(*cert = cf->sign_cert)) // Lazy load cert and private key
      *cert = cf->sign_cert = zxid_read_cert(cf, "sign-nopw-cert.pem");
  }
  if (!(*pkey = cf->sign_pkey))
    *pkey = cf->sign_pkey = zxid_read_private_key(cf, "sign-nopw-cert.pem");
  UNLOCK(cf->mx, logkey);
  if (cert && !*cert || !*pkey)
    return 0;
  return 1;
}

#endif  /* USE_OPENSSL */

/*() Set obscure options of ZX and ZXID layers. Used to set debug options.
 * Generally setting these options is not supported, but this function
 * exists to avoid uncontrolled access to global variables. At least this
 * way the unsupported activity will happen in one controlled place where
 * it can be ignored, if need to be. You have been warned. */

/* Called by:  main, zxid_fed_mgmt_cf, zxid_idp_list_cf_cgi, zxid_simple_cf_ses */
int zxid_set_opt(zxid_conf* cf, int which, int val)
{
  switch (which) {
  case 1: errmac_debug = val; INFO("errmac_debug=%d",val); return val;
  case 5: exit(val);  /* This is typically used to force __gcov_flush() */
  case 6: zxid_set_opt_cstr(cf, 6, "/var/zxid/log/log.dbg"); return 0;
#ifdef M_CHECK_ACTION  /* glibc specific */
  case 7: mallopt(M_CHECK_ACTION, val); return 0;  /* val==3 enables cores on bad free() */
#endif
  default: ERR("zxid_set_opt: this version " ZXID_REL " does not support which=%d val=%d (ignored)", which, val);
  }
  return -1;
}

/*() Set obscure options of ZX and ZXID layers. Used to set debug options.
 * Generally setting these options is not supported, but this function
 * exists to avoid uncontrolled access to global variables. At least this
 * way the unsupported activity will happen in one controlled place where
 * it can be ignored, if need to be. You have been warned. */

/* Called by:  zxid_parse_conf_raw, zxid_set_opt */
char* zxid_set_opt_cstr(zxid_conf* cf, int which, char* val)
{
  char buf[PATH_MAX];
  switch (which) {
  case 2: strncpy(errmac_instance, val, sizeof(errmac_instance)); return errmac_instance;
  case 3: D_INDENT(val); return errmac_indent;
  case 4: D_DEDENT(val); return errmac_indent;
  case 6:
    D("Forwarding debug output to file(%s) cwd(%s)", STRNULLCHK(val), getcwd(buf, sizeof(buf)));
    errmac_debug_log = fopen(val, "a");
    if (!errmac_debug_log) {
      perror("zxid_set_opt_cstr: failed to open new log file");
      fprintf(stderr, "zxid_set_opt_cstr: failed to open new log file(%s), euid=%d egid=%d cwd(%s)", STRNULLCHK(val), geteuid(), getegid(), getcwd(buf, sizeof(buf)));
      exit(1);
    }
    INFO("zxid_set_opt_cstr: opened new log file(%s), rel=" ZXID_REL " euid=%d egid=%d cwd(%s)", STRNULLCHK(val), geteuid(), getegid(), getcwd(buf, sizeof(buf)));
    return "";
  default: ERR("zxid_set_opt_cstr: this version " ZXID_REL " does not support which=%d val(%s) (ignored)", which, STRNULLCHK(val));
  }
  return 0;
}

/*() Set the BURL configuration variable.  Special accessor function to
 * manipulate BURL config option. Manipulating this option is common in
 * virtual hosting situations - hence this convenience function.  You
 * could use zxid_parse_conf() instead to manipulate BURL and some other
 * options. */

/* Called by:  main x2, zxidwspcgi_main */
void zxid_url_set(zxid_conf* cf, const char* burl)
{
  if (!cf || !burl) {
    ERR("NULL pointer as cf or url argument cf=%p url=%p", cf, burl);
    return;
  }
  D("Setting url(%s)", burl);
  cf->burl = zx_dup_cstr(cf->ctx, burl);
}

/* ================== Attribute Broker Config ================*/

#define IS_RULE(rule, val) (!memcmp((rule), (val), sizeof(val)-1) && (rule)[sizeof(val)-1] == '$')

/*() Create new (common pool) attribute and add it to a linked list */

/* Called by:  zxid_add_at_vals x3, zxid_add_attr_to_ses x2, zxid_add_qs2ses, zxid_load_atsrc, zxid_load_need */
struct zxid_attr* zxid_new_at(zxid_conf* cf, struct zxid_attr* at, int name_len, char* name, int val_len, char* val, char* lk)
{
  struct zxid_attr* aa = ZX_ZALLOC(cf->ctx, struct zxid_attr);
  aa->n = at;
  at = aa;
  COPYVAL(at->name, name, name+name_len);
  if (val)
    COPYVAL(at->val, val, val+val_len);
  D("%s:\tATTR(%.*s)=(%.*s)", lk, name_len, name, MIN(val_len, 80), STRNULLCHK(val));
  return aa;
}

/*() Reverse of zxid_new_at(). */

/* Called by:  zxid_free_atsrc, zxid_free_need */
void zxid_free_at(struct zxid_conf *cf, struct zxid_attr *attr)
{
  while (attr) {
    struct zxid_attr *next = attr->n;
    ZX_FREE(cf->ctx, attr->name);
    if (attr->val) ZX_FREE(cf->ctx, attr->val);
    ZX_FREE(cf->ctx, attr);
    attr = next;
  }
}

/*() Parse need specification and add it to linked list
 * A,B$usage$retention$oblig$ext;A,B$usage$retention$oblig$ext;...
 */

/* Called by:  zxid_init_conf x2, zxid_parse_conf_raw x2 */
struct zxid_need* zxid_load_need(zxid_conf* cf, struct zxid_need* need, char* v)
{
  char* attrs;
  char* usage;
  char* retent;
  char* oblig;
  char* ext;
  char* p = v;
  char* a;
  int len;
  struct zxid_need* nn;

  while (p && *p) {
    attrs = p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed NEED or WANT directive: attribute list at pos %d", ((int)(p-v)));
      return need;
    }

    usage = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed NEED or WANT directive: usage missing at pos %d", ((int)(p-v)));
      return need;
    }

    retent = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed NEED or WANT directive: retention missing at pos %d", ((int)(p-v)));
      return need;
    }

    oblig = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed NEED or WANT directive: obligations missing at pos %d", ((int)(p-v)));
      return need;
    }
    
    ext = ++p;
    p = strchr(p, ';');  /* Stanza ends in separator ; or end of string nul */
    if (!p)
      p = ext + strlen(ext);
    
    if (IS_RULE(usage, "reset")) {
      INFO("Reset need %p", need);
      zxid_free_need(cf, need);
      need = 0;
      if (!*p) break;
      ++p;
      continue;
    }
    
    nn = ZX_ZALLOC(cf->ctx, struct zxid_need);
    nn->n = need;
    need = nn;

    COPYVAL(nn->usage,  usage,  retent-1);
    COPYVAL(nn->retent, retent, oblig-1);
    COPYVAL(nn->oblig,  oblig,  ext-1);
    COPYVAL(nn->ext,    ext,    p);

    DD("need attrs(%.*s) usage(%s) retent(%s) oblig(%s) ext(%s)", usage-attrs-1, attrs, nn->usage, nn->retent, nn->oblig, nn->ext);

    for (a = attrs; ; a += len+1) {
      len = strcspn(a, ",$");
      nn->at = zxid_new_at(cf, nn->at, len, a, 0,0, "need/want");
      if (a[len] == '$')
	break;
    }
    if (!*p) break;
    ++p;
  }

  return need;
}

/*() Reverse of zxid_load_need(). */

/* Called by:  zxid_free_conf x2, zxid_load_need */
void zxid_free_need(struct zxid_conf *cf, struct zxid_need *need)
{
  while (need) {
    struct zxid_need *next = need->n;
    ZX_FREE(cf->ctx, need->usage);
    ZX_FREE(cf->ctx, need->retent);
    ZX_FREE(cf->ctx, need->oblig);
    ZX_FREE(cf->ctx, need->ext);
    zxid_free_at(cf, need->at);
    ZX_FREE(cf->ctx, need);
    need = next;
  }
}

/*() Parse map specification and add it to linked list
 * srcns$A$rule$b$ext;src$A$rule$b$ext;...
 * The list ends up being built in reverse order, which at runtime
 * causes last stanzas to be evaluated first and first match is used.
 * Thus you should place most specific rules last and most generic rules first.
 * See also: zxid_find_map() and zxid_map_val()
 */

/* Called by:  zxid_init_conf x7, zxid_mk_usr_a7n_to_sp, zxid_parse_conf_raw x7, zxid_read_map */
struct zxid_map* zxid_load_map(zxid_conf* cf, struct zxid_map* map, char* v)
{
  char* ns;
  char* A;
  char* rule;
  char* b;
  char* ext;
  char* p = v;
  int len;
  struct zxid_map* mm;

  DD("v(%s)", v);

  while (p && *p) {
    ns = p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed MAP directive: source namespace missing at pos %d", ((int)(p-v)));
      return map;
    }

    A = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed MAP directive: source attribute name missing at pos %d", ((int)(p-v)));
      return map;
    }

    rule = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed MAP directive: rule missing at pos %d", ((int)(p-v)));
      return map;
    }

    b = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed MAP directive: destination attribute name missing at pos %d", ((int)(p-v)));
      return map;
    }
    
    ext = ++p;
    len = strcspn(p, ";\n");  /* Stanza ends in separator ; or end of string nul */
    p = ext + len;
    
    if (IS_RULE(rule, "reset")) {
      INFO("Reset map %p", map);
      for (; map; map = mm) {
	mm = map->n;
	ZX_FREE(cf->ctx, map);
      }
      if (!*p) break;
      ++p;
      continue;
    }
    
    mm = ZX_ZALLOC(cf->ctx, struct zxid_map);
    mm->n = map;
    map = mm;
    
    if (IS_RULE(rule, "") || IS_RULE(rule, "rename")) { mm->rule = ZXID_MAP_RULE_RENAME; }
    else if (IS_RULE(rule, "del"))           { mm->rule = ZXID_MAP_RULE_DEL; }
    else if (IS_RULE(rule, "feidedec"))      { mm->rule = ZXID_MAP_RULE_FEIDEDEC; }
    else if (IS_RULE(rule, "feideenc"))      { mm->rule = ZXID_MAP_RULE_FEIDEENC; }
    else if (IS_RULE(rule, "unsb64-inf"))    { mm->rule = ZXID_MAP_RULE_UNSB64_INF; }
    else if (IS_RULE(rule, "def-sb64"))      { mm->rule = ZXID_MAP_RULE_DEF_SB64; }
    else if (IS_RULE(rule, "unsb64"))        { mm->rule = ZXID_MAP_RULE_UNSB64; }
    else if (IS_RULE(rule, "sb64"))          { mm->rule = ZXID_MAP_RULE_SB64; }

    else if (IS_RULE(rule, "a7n"))           { mm->rule = ZXID_MAP_RULE_WRAP_A7N; }
    else if (IS_RULE(rule, "a7n-feideenc"))  { mm->rule = ZXID_MAP_RULE_WRAP_A7N | ZXID_MAP_RULE_FEIDEENC; }
    else if (IS_RULE(rule, "a7n-def-sb64"))  { mm->rule = ZXID_MAP_RULE_WRAP_A7N | ZXID_MAP_RULE_DEF_SB64; }
    else if (IS_RULE(rule, "a7n-sb64"))      { mm->rule = ZXID_MAP_RULE_WRAP_A7N | ZXID_MAP_RULE_SB64; }

    else if (IS_RULE(rule, "x509"))          { mm->rule = ZXID_MAP_RULE_WRAP_X509; }
    else if (IS_RULE(rule, "x509-feideenc")) { mm->rule = ZXID_MAP_RULE_WRAP_X509 | ZXID_MAP_RULE_FEIDEENC; }
    else if (IS_RULE(rule, "x509-def-sb64")) { mm->rule = ZXID_MAP_RULE_WRAP_X509 | ZXID_MAP_RULE_DEF_SB64; }
    else if (IS_RULE(rule, "x509-sb64"))     { mm->rule = ZXID_MAP_RULE_WRAP_X509 | ZXID_MAP_RULE_SB64; }

    else if (IS_RULE(rule, "file"))          { mm->rule = ZXID_MAP_RULE_WRAP_FILE; }
    else if (IS_RULE(rule, "file-feideenc")) { mm->rule = ZXID_MAP_RULE_WRAP_FILE | ZXID_MAP_RULE_FEIDEENC; }
    else if (IS_RULE(rule, "file-def-sb64")) { mm->rule = ZXID_MAP_RULE_WRAP_FILE | ZXID_MAP_RULE_DEF_SB64; }
    else if (IS_RULE(rule, "file-sb64"))     { mm->rule = ZXID_MAP_RULE_WRAP_FILE | ZXID_MAP_RULE_SB64; }

    else {
      ERR("Unknown map rule(%.*s) at col %d of (%s)", ((int)(b-rule)), rule, ((int)(rule-v)), v);
      //ERR("sizeof(rename)=%d cmp=%d c(%c)", sizeof("rename"), memcmp(rule, "rename", sizeof("rename")-1), rule[sizeof("rename")]);
    }

    COPYVAL(mm->ns,  ns,  A-1);
    COPYVAL(mm->src, A,   rule-1);
    COPYVAL(mm->dst, b,   ext-1);
    COPYVAL(mm->ext, ext, p);

    DD("map ns(%s) src(%s) rule=%d dst(%s) ext(%s)", mm->ns, mm->src, mm->rule, mm->dst, mm->ext);
    if (!*p || *p == '\n') break;
    ++p;
  }

  return map;
}

/*() Parse unix_grp_az_map specification and add it to linked list
 * srcns$A$rule$b$ext;src$A$rule$b$ext;...
 * The list ends up being built in reverse order, which at runtime
 * causes last stanzas to be evaluated first and first match is used.
 * Thus you should place most specific rules last and most generic rules first.
 * See also: zxid_find_map() and zxid_map_val()
 */

/* Called by:  zxid_init_conf x7, zxid_mk_usr_a7n_to_sp, zxid_parse_conf_raw x7, zxid_read_map */
struct zxid_map* zxid_load_unix_grp_az_map(zxid_conf* cf, struct zxid_map* map, char* v)
{
  char* ns;
  char* A;
  char* val;
  char* group;
  char* ext;
  char* p = v;
  int len, n_grps, i;
  struct zxid_map* mm;
  struct group* grp;
  gid_t* gids;

  DD("v(%s)", v);

  n_grps = getgroups(0,0);
  gids = ZX_ALLOC(cf->ctx, (n_grps+1)*sizeof(gid_t));
  getgroups(n_grps, gids);
  gids[n_grps] = getegid();  /* getgroups(2) is not guaranteed to return egid */

  while (p && *p) {
    ns = p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed UNIX_GRP_AZ_MAP directive: source namespace missing at pos %d", ((int)(p-v)));
      return map;
    }

    A = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed UNIX_GRP_AZ_MAP directive: source attribute name missing at pos %d", ((int)(p-v)));
      return map;
    }

    val = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed UNIX_GRP_AZ_MAP directive: value missing at pos %d", ((int)(p-v)));
      return map;
    }

    group = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed UNIX_GRP_AZ_MAP directive: unix group name missing at pos %d", ((int)(p-v)));
      return map;
    }
    
    ext = ++p;
    len = strcspn(p, ";\n");  /* Stanza ends in separator ; or end of string nul */
    p = ext + len;
    
    mm = ZX_ZALLOC(cf->ctx, struct zxid_map);
    mm->n = map;
    map = mm;
    
    COPYVAL(mm->ns,  ns,  A-1);
    COPYVAL(mm->src, A,   val-1);
    COPYVAL(mm->dst, val, group-1);
    COPYVAL(mm->ext, ext, p);
    
    *(ext-1) = 0;
    grp = getgrnam(group);
    *(ext-1) = '$';
    if (grp) {
      for (i = 0; i <= n_grps; ++i)
	if (grp->gr_gid == gids[i])
	  goto have_group;
      ERR("UNIX_GRP_AZ_MAP: The current process does not belong to unix group name %s at pos %d (Config Error: see /etc/group for listing of groups)", group, ((int)(p-v)));
      return map;      
    have_group:
      mm->rule = grp->gr_gid;
    } else {
      ERR("UNIX_GRP_AZ_MAP: unix group name %s does not exist at pos %d (Config Error: see /etc/group for listing of groups)", group, ((int)(p-v)));
      return map;      
    }

    DD("map ns(%s) A(%s) val(%s) gid=%d ext(%s)", mm->ns, mm->src, mm->dst, mm->rule, mm->ext);
    if (!*p || *p == '\n') break;
    ++p;
  }

  ZX_FREE(cf->ctx, gids);
  return map;
}

/*() Reverse of zxid_load_map(). */

/* Called by:  zxid_free_conf x7 */
void zxid_free_map(struct zxid_conf *cf, struct zxid_map *map)
{
  while (map) {
    struct zxid_map *next = map->n;
    ZX_FREE(cf->ctx, map->ns);
    ZX_FREE(cf->ctx, map->src);
    ZX_FREE(cf->ctx, map->dst);
    ZX_FREE(cf->ctx, map->ext);
    ZX_FREE(cf->ctx, map);
    map = next;
  }
}

/*() Parse comma separated strings (nul terminated) and add to linked list */

/* Called by:  zxid_init_conf x4, zxid_load_obl_list, zxid_parse_conf_raw x4 */
struct zxid_cstr_list* zxid_load_cstr_list(zxid_conf* cf, struct zxid_cstr_list* l, char* p)
{
  char* q;
  struct zxid_cstr_list* cs;

  for (; p && *p; (void)(*p && ++p)) {
    q = p;
    p = strchr(p, ',');
    if (!p)
      p = q + strlen(q);
    cs = ZX_ZALLOC(cf->ctx, struct zxid_cstr_list);
    cs->n = l;
    l = cs;
    COPYVAL(cs->s, q, p);    
  }
  return l;
}

/*() Free list nodes and strings of zxid_cstr_list. */

/* Called by:  zxid_free_conf x4, zxid_free_obl_list */
void zxid_free_cstr_list(struct zxid_conf* cf, struct zxid_cstr_list* l)
{
  while (l) {
    struct zxid_cstr_list* next = l->n;
    ZX_FREE(cf->ctx, l->s);
    ZX_FREE(cf->ctx, l);
    l = next;
  }
}

// *** print obl_list

/*() Parse and construct an obligations list with multiple values as cstr_list.
 * The input string obl will be modified in place and used for long term reference,
 * so do not pass a constant string or something that will be freed immadiately. */

/* Called by:  zxid_eval_sol1, zxid_parse_conf_raw x2 */
struct zxid_obl_list* zxid_load_obl_list(zxid_conf* cf, struct zxid_obl_list* ol, char* obl)
{
  struct zxid_obl_list* ob;
  char *val, *name;
  DD("obl(%s) len=%d", STRNULLCHK(obl), obl?strlen(obl):-1);
  if (!obl)
    return 0;
  while (obl && *obl) {
    obl = zxid_qs_nv_scan(obl, &name, &val, 1);
    if (!name)
      name = "NULL_NAM_ERRO";
    if (!strcmp(name, "reset")) {
      ol = 0;
      continue;
    }
    ob = ZX_ZALLOC(cf->ctx, struct zxid_obl_list);
    ob->name = name;
    ob->vals = zxid_load_cstr_list(cf, 0, val);
    ob->n = ol;
    ol = ob;
    D("ALLOC OBL(%s) %p", ol->name, ol);
  }
  return ol;
}

/*() Free list nodes and strings of zxid_obl_list. */

/* Called by:  zxid_eval_sol1 x2 */
void zxid_free_obl_list(struct zxid_conf* cf, struct zxid_obl_list* ol)
{
  //return; /* *** LEAK temporary fix 20130319 --Sampo */
  while (ol) {
    struct zxid_obl_list* next = ol->n;
    zxid_free_cstr_list(cf, ol->vals);
    /* ZX_FREE(cf->ctx, ol->name); BAD IDEA: the name comes from external static storage */
    D("FREE OBL(%s) %p", ol->name, ol);
    ZX_FREE(cf->ctx, ol);
    ol = next;
  }
}

/*() Parse comma separated bus_urls and add to linked list */

/* Called by:  zxid_init_conf, zxid_parse_conf_raw */
struct zxid_bus_url* zxid_load_bus_url(zxid_conf* cf, struct zxid_bus_url* bu_root, char* p)
{
  char* q;
  struct zxid_bus_url* bu;

  for (; p && *p; (void)(*p && ++p)) {
    q = p;
    p = strchr(p, ',');
    if (!p)
      p = q + strlen(q);
    bu = ZX_ZALLOC(cf->ctx, struct zxid_bus_url);
    bu->n = bu_root;
    bu_root = bu;
    COPYVAL(bu->s, q, p);
    COPYVAL(bu->eid, q, p);  /* *** convention is that contact URL and eid are the same?!? */
  }
  return bu_root;
}

/*() Reverse of zxid_load_bus_url(). */

/* Called by:  zxid_free_conf */
void zxid_free_bus_url(struct zxid_conf* cf, struct zxid_bus_url* bu)
{
  struct zxid_bus_url* next;
  while (bu) {
    next = bu->n;
    ZX_FREE(cf->ctx, bu->s);
    ZX_FREE(cf->ctx, bu->eid);
    ZX_FREE(cf->ctx, bu);
    bu = next;
  }
}

/*() Parse ATTRSRC specification and add it to linked list
 *   namespace$A,B$weight$accessparamURL$AAPMLref$otherLim$ext;namespace$A,B$weight$accessparamURL$AAPMLref$otherLim$ext;...
 */

/* Called by:  zxid_init_conf, zxid_parse_conf_raw */
struct zxid_atsrc* zxid_load_atsrc(zxid_conf* cf, struct zxid_atsrc* atsrc, char* v)
{
  char* ns;
  char* attrs;
  char* weight;
  char* url;
  char* aapml;
  char* otherlim;
  char* ext;
  char* p = v;
  char* a;
  int len;
  struct zxid_atsrc* as;

  while (p && *p) {
    ns = p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed ATSRC directive: namespace missing at pos %d", ((int)(p-v)));
      return atsrc;
    }

    attrs = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed ATSRC directive: attribute list missing at pos %d", ((int)(p-v)));
      return atsrc;
    }

    weight = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed ATSRC directive: weight missing at pos %d", ((int)(p-v)));
      return atsrc;
    }

    url = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed ATSRC directive: url missing at pos %d", ((int)(p-v)));
      return atsrc;
    }

    aapml = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed ATSRC directive: aapml ref missing at pos %d", ((int)(p-v)));
      return atsrc;
    }
    
    otherlim = ++p;
    p = strchr(p, '$');
    if (!p) {
      ERR("Malformed ATSRC directive: otherlim missing at pos %d", ((int)(p-v)));
      return atsrc;
    }
    
    ext = ++p;
    p = strchr(p, ';');  /* Stanza ends in separator ; or end of string nul */
    if (!p)
      p = ext + strlen(ext);
    
    if (IS_RULE(url, "reset")) {
      INFO("Reset atsrc %p", atsrc);
      zxid_free_atsrc(cf, atsrc);
      atsrc = NULL;
      if (!*p) break;
      ++p;
      continue;
    }
    
    as = ZX_ZALLOC(cf->ctx, struct zxid_atsrc);
    as->n = atsrc;
    atsrc = as;

    COPYVAL(as->ns,       ns,        attrs-1);
    COPYVAL(as->weight,   weight,    url-1);
    COPYVAL(as->url,      url,       aapml-1);
    COPYVAL(as->aapml,    aapml,     otherlim-1);
    COPYVAL(as->otherlim, otherlim,  ext-1);
    COPYVAL(as->ext,      ext,       p);

    D("atsrc ns(%s) attrs(%.*s) weight(%s) url(%s) aapml(%s) otherlim(%s) ext(%s)", as->ns, ((int)(weight-attrs-1)), attrs, as->weight, as->url, as->aapml, as->otherlim, as->ext);

    for (a = attrs; ; a += len+1) {
      len = strcspn(a, ",$");
      as->at = zxid_new_at(cf, as->at, len, a, 0,0, "atsrc");
      if (a[len] == '$')
	break;
    }
    if (!*p) break;
    ++p;
  }

  return atsrc;
}

/*() Reverse of zxid_load_atsrc(). */

/* Called by:  zxid_free_conf, zxid_load_atsrc */
void zxid_free_atsrc(struct zxid_conf *cf, struct zxid_atsrc *src)
{
  while (src) {
    struct zxid_atsrc *next = src->n;
    zxid_free_at(cf, src->at);
    ZX_FREE(cf->ctx, src->ns);
    ZX_FREE(cf->ctx, src->weight);
    ZX_FREE(cf->ctx, src->url);
    ZX_FREE(cf->ctx, src->aapml);
    ZX_FREE(cf->ctx, src->otherlim);
    ZX_FREE(cf->ctx, src->ext);
    ZX_FREE(cf->ctx, src);
    src = next;
  }
}

/*() Check whether attribute is in a (needed or wanted) list. Just a linear
 * scan as it is simple and good enough for handful of attributes. */

/* Called by:  zxid_add_at_vals x2, zxid_add_attr_to_ses x2 */
struct zxid_need* zxid_is_needed(struct zxid_need* need, const char* name)
{
  struct zxid_attr* at;
  if (!name || !*name)
    return 0;
  for (; need; need = need->n)
    for (at = need->at; at; at = at->n)
      if (at->name[0] == '*' && !at->name[1]   /* Wild card */
	  || !strcmp(at->name, name)) /* Match! */
	return need;
  return 0;
}

/*() Check whether attribute is in a (needed or wanted) list. Just a linear
 * scan as it is simple and good enough for handful of attributes.
 * The list ends up being built in reverse order, which at runtime
 * causes last stanzas to be evaluated first and first match is used.
 * Thus you should place most specific rules last and most generic rules first.
 * See also: zxid_load_map() and zxid_map_val() */

/* Called by:  pool2apache, zxid_add_at_vals, zxid_add_attr_to_ses, zxid_add_mapped_attr x2, zxid_pepmap_extract, zxid_pool2env, zxid_pool_to_json x2, zxid_pool_to_ldif x2, zxid_pool_to_qs x2 */
struct zxid_map* zxid_find_map(struct zxid_map* map, const char* name)
{
  if (!name || !*name)
    return 0;
  for (; map; map = map->n) {
    DD("HERE src(%s)", STRNULLCHKNULL(map->src));
    if (map->src[0] == '*' && !map->src[1] /* Wild card (only sensible for del and data xform) */
	|| !strcmp(map->src, name)) /* Match! */
      return map;
  }
  return 0;
}

/*() Check whether name is in the list. Used for Local PDP white and black lists. */

/* Called by:  zxid_eval_sol1, zxid_localpdp x4 */
struct zxid_cstr_list* zxid_find_cstr_list(struct zxid_cstr_list* cs, const char* name)
{
  if (!name || !*name)
    return 0;
  for (; cs; cs = cs->n)
    if (cs->s[0] == '*' && !cs->s[1] /* Wild card */
	|| !strcmp(cs->s, name))     /* Match! */
      return cs;
  return 0;
}

/*() Chech whether any of multivalues of an attribute is on the list. */

struct zxid_cstr_list* zxid_find_at_multival_on_cstr_list(struct zxid_cstr_list* cs, struct zxid_attr* at)
{
  struct zxid_cstr_list* ret;
  for (; at; at = at->nv)
    if ((ret = zxid_find_cstr_list(cs, at->val)))
      return ret;
  return 0;
}

/*() Check whether name is in the obligations list. */

/* Called by:  zxid_eval_sol1 */
struct zxid_obl_list* zxid_find_obl_list(struct zxid_obl_list* obl, const char* name)
{
  if (!name || !*name)
    return 0;
  for (; obl; obl = obl->n)
    if (obl->name[0] == '*' && !obl->name[1] /* Wild card */
	|| !strcmp(obl->name, name))     /* Match! */
      return obl;
  return 0;
}

/*() Check whether attribute is in pool. */

/* Called by:  zxid_localpdp x2 */
struct zxid_attr* zxid_find_at(struct zxid_attr* pool, const char* name)
{
  if (!name || !*name)
    return 0;
  for (; pool; pool = pool->n)
    if (!strcmp(pool->name, name))     /* Match! */
      return pool;
  return 0;
}

/*() Check that the user, who is logged into session, maps to group.
 * This is used by UNIX_GRP_AZ_MAP to check that filesystem
 * permissions allow user to access a file (existence of g+r and
 * user mapping to the correct group).
 *
 * return:: 0=deny, 1=permit */

int zxid_unix_grp_az_check(zxid_conf* cf, zxid_ses* ses, int gid)
{
  struct zxid_map* grp_map = 0;
  struct zxid_attr* at = 0;
  
  if (!cf || !ses) {
    ERR("missing argument cf=%p", cf);
    return 0;
  }
  if (!ses->nid || !ses->nid[0]) {
    INFO("user not logged in ses->nid=%p", ses->nid);
    return 0;
  }
  for (grp_map = cf->unix_grp_az_map; grp_map; grp_map = grp_map->n) {
    if (grp_map->rule != gid)
      continue;

    /* If affiliation filter is specified, check it. */
    if (grp_map->ns && strcmp(grp_map->ns, "") /* none of the wild card cases */
	&& strcmp(grp_map->ns, "*") && strcmp(grp_map->ns, "**")) {
      at = zxid_find_at(ses->at, "affid");
      if (!at || !zx_match(grp_map->ns, at->val /*ses->nameid->NameQualifier*/))
	continue;
    }

    /* If attribute filter is specified, check it. */
    if (grp_map->src && strcmp(grp_map->src, "") /* none of the wild card cases */
	&& strcmp(grp_map->src, "*") && strcmp(grp_map->src, "**")) {
      at = zxid_find_at(ses->at, grp_map->src);
      if (!at || !zx_match(grp_map->dst, at->val /*ses->nameid->NameQualifier*/))
	continue;
    }
    D("%s=%s maps to gid=%d", STRNULLCHKD(grp_map?grp_map->src:0), STRNULLCHKD(at?at->val:0), gid);
    return 1;
  }
  INFO("user does not map to gid=%d", gid);
  return 0;
}

/*() Given URL, return a newly allocated string corresponding
 * to the domain name part of the URL. Used to grab fedusername_suffix
 * from the url config option. */

/* Called by:  zxid_parse_conf_raw */
char* zxid_grab_domain_name(zxid_conf* cf, const char* url)
{
  char* dom;
  char* p;
  int len;
  if (!url || !*url)
    return 0;
  dom = strchr(url, ':');
  if (!dom || dom[1] != '/' || dom[2] != '/')
    return 0;
  dom += 3;
  /* After shipping https:// scan for domain name allowable characters. */
  len = strspn(dom, ".abcdefghijklmnopqrstuvwxyz0123456789-ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  p = ZX_ALLOC(cf->ctx, len+1);
  memcpy(p, dom, len);
  p[len] = 0;
  return p;
}

struct zx_lock zxid_ent_cache_mx;
int zxid_ent_cache_mx_init = 0;

/*(i) Initialize configuration object, which must have already been
 * allocated, to factory defaults (i.e. compiled in defaults, see
 * zxidconf.h). Config file is not read.
 *
 * cf:: Pointer to previously allocated configuration object
 * path:: Since this configuration option is so fundamental, it can
 *     be supplied directly as argument. However, unlike zxid_new_conf()
 *     this does not cause the config file to be read.
 * return:: 0 on success (currently, 2008, this function can not
 *     fail - thus it is common to ignore the return value)
 *
 * N.B. This function does NOT initialize the ZX context object although
 * it is a field of this object. You MUST separately initialize
 * the ZX context object, e.g. using zx_reset_ctx() or zx_init_ctx(),
 * before you can use ZXID configuration object in any memory allocation prone
 * activity (which is nearly every function in this API).
 */

/* Called by:  zxid_conf_to_cf_len, zxid_init_conf_ctx */
int zxid_init_conf(zxid_conf* cf, const char* zxid_path)
{
  DD("Initconf with path(%s)", zxid_path);
  cf->magic = ZXID_CONF_MAGIC;
  cf->cpath_len = zxid_path ? strlen(zxid_path) : 0;
  cf->cpath = ZX_ALLOC(cf->ctx, cf->cpath_len+1);
  memcpy(cf->cpath, zxid_path, cf->cpath_len);
  cf->cpath[cf->cpath_len] = 0;
  cf->nice_name     = ZXID_NICE_NAME;
  cf->button_url    = ZXID_BUTTON_URL;
  cf->pref_button_size = ZXID_PREF_BUTTON_SIZE;
  cf->org_name      = ZXID_ORG_NAME;
  cf->locality      = ZXID_LOCALITY;
  cf->state         = ZXID_STATE;
  cf->country       = ZXID_COUNTRY;
  cf->contact_org   = ZXID_CONTACT_ORG;
  cf->contact_name  = ZXID_CONTACT_NAME;
  cf->contact_email = ZXID_CONTACT_EMAIL;
  cf->contact_tel   = ZXID_CONTACT_TEL;
  /* NB: Typically allocated by zxid_grab_domain_name(). */
  COPYVAL(cf->fedusername_suffix, ZXID_FEDUSERNAME_SUFFIX,
	  ZXID_FEDUSERNAME_SUFFIX + strlen(ZXID_FEDUSERNAME_SUFFIX));
  cf->burl = ZXID_BURL;
  cf->non_standard_entityid = ZXID_NON_STANDARD_ENTITYID;
  cf->redirect_hack_imposed_url = ZXID_REDIRECT_HACK_IMPOSED_URL;
  cf->redirect_hack_zxid_url = ZXID_REDIRECT_HACK_ZXID_URL;
  cf->defaultqs     = ZXID_DEFAULTQS;
  cf->wsp_pat       = ZXID_WSP_PAT;
  cf->uma_pat       = ZXID_UMA_PAT;
  cf->sso_pat       = ZXID_SSO_PAT;
  cf->cdc_url       = ZXID_CDC_URL;
  cf->cdc_choice    = ZXID_CDC_CHOICE;
  cf->authn_req_sign = ZXID_AUTHN_REQ_SIGN;
  cf->want_sso_a7n_signed = ZXID_WANT_SSO_A7N_SIGNED;
  cf->want_authn_req_signed = ZXID_WANT_AUTHN_REQ_SIGNED;
  cf->sso_soap_sign = ZXID_SSO_SOAP_SIGN;
  cf->sso_soap_resp_sign = ZXID_SSO_SOAP_RESP_SIGN;
  cf->sso_sign      = ZXID_SSO_SIGN;
  cf->wsc_sign      = ZXID_WSC_SIGN;
  cf->wsp_sign      = ZXID_WSP_SIGN;
  cf->oaz_jwt_sigenc_alg = ZXID_OAZ_JWT_SIGENC_ALG;
  cf->wspcgicmd     = ZXID_WSPCGICMD;
  cf->nameid_enc    = ZXID_NAMEID_ENC;
  cf->post_a7n_enc  = ZXID_POST_A7N_ENC;
  cf->canon_inopt   = ZXID_CANON_INOPT;
  if (cf->ctx) cf->ctx->canon_inopt = cf->canon_inopt;
  cf->enc_tail_opt  = ZXID_ENC_TAIL_OPT;
  cf->enckey_opt    = ZXID_ENCKEY_OPT;
  cf->valid_opt     = ZXID_VALID_OPT;
  cf->idpatopt      = ZXID_IDPATOPT;
  cf->idp_list_meth = ZXID_IDP_LIST_METH;
  cf->di_allow_create = ZXID_DI_ALLOW_CREATE;
  cf->di_nid_fmt    = ZXID_DI_NID_FMT;
  cf->di_a7n_enc    = ZXID_DI_A7N_ENC;
  cf->bootstrap_level = ZXID_BOOTSTRAP_LEVEL;
  cf->show_conf     = ZXID_SHOW_CONF;
#ifdef USE_OPENSSL
  if (zxid_path) {
#if 0
    /* DO NOT ENABLE! The certificates and keys are read "just in time" if and when needed. */
    cf->sign_cert = zxid_read_cert(cf, "sign-nopw-cert.pem");
    cf->sign_pkey = zxid_read_private_key(cf, "sign-nopw-cert.pem");
    cf->enc_cert = zxid_read_cert(cf, "enc-nopw-cert.pem");
    cf->enc_pkey = zxid_read_private_key(cf, "enc-nopw-cert.pem");
    cf->log_sign_pkey = zxid_read_private_key(cf, "logsign-nopw-cert.pem");
    cf->log_enc_cert = zxid_read_cert(cf, "logenc-nopw-cert.pem");
    zxid_sha1_file(cf, "pem/logenc.key", cf->log_symkey);
#endif
  }
#else
  ERR("This copy of zxid was compiled to NOT use OpenSSL. Reading certificate and private key is not supported. Signing and signature verification are not supported either. Add -DUSE_OPENSSL and recompile. %d", 0);
#endif
  cf->md_fetch = ZXID_MD_FETCH;
  cf->md_populate_cache = ZXID_MD_POPULATE_CACHE;
  cf->md_cache_first    = ZXID_MD_CACHE_FIRST;
  cf->md_cache_last     = ZXID_MD_CACHE_LAST;
  cf->md_authority      = ZXID_MD_AUTHORITY;
  cf->load_cot_cache    = ZXID_LOAD_COT_CACHE;
  cf->auto_cert         = ZXID_AUTO_CERT;
  cf->ses_arch_dir      = ZXID_SES_ARCH_DIR;
  cf->ses_cookie_name   = ZXID_SES_COOKIE_NAME;
  cf->ptm_cookie_name   = ZXID_PTM_COOKIE_NAME;
  cf->user_local        = ZXID_USER_LOCAL;
  cf->idp_ena           = ZXID_IDP_ENA;
  cf->idp_pxy_ena       = ZXID_IDP_PXY_ENA;
  cf->imps_ena          = ZXID_IMPS_ENA;
  cf->as_ena            = ZXID_AS_ENA;
  cf->md_authority_ena  = ZXID_MD_AUTHORITY_ENA;
  cf->backwards_compat_ena  = ZXID_BACKWARDS_COMPAT_ENA;
  cf->pdp_ena           = ZXID_PDP_ENA;
  cf->cpn_ena           = ZXID_CPN_ENA;
  cf->az_opt            = ZXID_AZ_OPT;
  cf->az_fail_mode      = ZXID_AZ_FAIL_MODE;

  cf->loguser = ZXID_LOGUSER;
  cf->log_level = ZXLOG_LEVEL;
  cf->log_err = ZXLOG_ERR;      /* Log enables and signing and encryption flags (if USE_OPENSSL) */
  cf->log_act = ZXLOG_ACT;
  cf->log_issue_a7n  = ZXLOG_ISSUE_A7N;
  cf->log_issue_msg  = ZXLOG_ISSUE_MSG;
  cf->log_rely_a7n   = ZXLOG_RELY_A7N;
  cf->log_rely_msg   = ZXLOG_RELY_MSG;
  cf->log_err_in_act = ZXLOG_ERR_IN_ACT;
  cf->log_act_in_err = ZXLOG_ACT_IN_ERR;
  cf->log_sigfail_is_err = ZXLOG_SIGFAIL_IS_ERR;
  cf->bus_rcpt       = ZXBUS_RCPT;
  cf->bus_url        = zxid_load_bus_url(cf, 0, ZXID_BUS_URL);
  cf->bus_pw         = ZXID_BUS_PW;

  cf->sig_fatal      = ZXID_SIG_FATAL;
  cf->nosig_fatal    = ZXID_NOSIG_FATAL;
  cf->msg_sig_ok     = ZXID_MSG_SIG_OK;
  cf->timeout_fatal  = ZXID_TIMEOUT_FATAL;
  cf->audience_fatal = ZXID_AUDIENCE_FATAL;
  cf->dup_a7n_fatal  = ZXID_DUP_A7N_FATAL;
  cf->dup_msg_fatal  = ZXID_DUP_MSG_FATAL;
  cf->relto_fatal    = ZXID_RELTO_FATAL;
  cf->wsp_nosig_fatal = ZXID_WSP_NOSIG_FATAL;
  cf->notimestamp_fatal = ZXID_NOTIMESTAMP_FATAL;
  cf->anon_ok        = ZXID_ANON_OK;
  cf->optional_login_pat = ZXID_OPTIONAL_LOGIN_PAT;
  cf->required_authnctx = ZXID_REQUIRED_AUTHNCTX;	/* NB: NULL. */
  cf->issue_authnctx = zxid_load_cstr_list(cf, 0, ZXID_ISSUE_AUTHNCTX);
  cf->idp_pref_acs_binding = ZXID_IDP_PREF_ACS_BINDING;
  cf->mandatory_attr = ZXID_MANDATORY_ATTR;

  cf->before_slop    = ZXID_BEFORE_SLOP;
  cf->after_slop     = ZXID_AFTER_SLOP;
  cf->timeskew       = ZXID_TIMESKEW;
  cf->a7nttl         = ZXID_A7NTTL;
  cf->pdp_url        = ZXID_PDP_URL;
  cf->pdp_call_url   = ZXID_PDP_CALL_URL;
  cf->xasp_vers      = ZXID_XASP_VERS;
  cf->trustpdp_url   = ZXID_TRUSTPDP_URL;

  cf->need           = zxid_load_need(cf, 0, ZXID_NEED);
  cf->want           = zxid_load_need(cf, 0, ZXID_WANT);
  cf->attrsrc        = zxid_load_atsrc(cf, 0, ZXID_ATTRSRC);
  cf->inmap          = zxid_load_map(cf, 0, ZXID_INMAP);
  cf->outmap         = zxid_load_map(cf, 0, ZXID_OUTMAP);
  cf->pepmap         = zxid_load_map(cf, 0, ZXID_PEPMAP);
  cf->pepmap_rqout   = zxid_load_map(cf, 0, ZXID_PEPMAP_RQOUT);
  cf->pepmap_rqin    = zxid_load_map(cf, 0, ZXID_PEPMAP_RQIN);
  cf->pepmap_rsout   = zxid_load_map(cf, 0, ZXID_PEPMAP_RSOUT);
  cf->pepmap_rsin    = zxid_load_map(cf, 0, ZXID_PEPMAP_RSIN);

  cf->localpdp_role_permit    = zxid_load_cstr_list(cf, 0, ZXID_LOCALPDP_ROLE_PERMIT);
  cf->localpdp_role_deny      = zxid_load_cstr_list(cf, 0, ZXID_LOCALPDP_ROLE_DENY);
  cf->localpdp_idpnid_permit  = zxid_load_cstr_list(cf, 0, ZXID_LOCALPDP_IDPNID_PERMIT);
  cf->localpdp_idpnid_deny    = zxid_load_cstr_list(cf, 0, ZXID_LOCALPDP_IDPNID_DENY);

  cf->wsc_localpdp_obl_pledge = ZXID_WSC_LOCALPDP_OBL_PLEDGE;
  cf->wsp_localpdp_obl_req    = ZXID_WSP_LOCALPDP_OBL_REQ;
  cf->wsp_localpdp_obl_emit   = ZXID_WSP_LOCALPDP_OBL_EMIT;
  cf->wsc_localpdp_obl_accept = ZXID_WSC_LOCALPDP_OBL_ACCEPT;

  cf->unix_grp_az_map   = zxid_load_unix_grp_az_map(cf, 0, ZXID_UNIX_GRP_AZ_MAP);

  cf->redir_to_content  = ZXID_REDIR_TO_CONTENT;
  cf->remote_user_ena   = ZXID_REMOTE_USER_ENA;
  cf->max_soap_retry    = ZXID_MAX_SOAP_RETRY;
  cf->mod_saml_attr_prefix  = ZXID_MOD_SAML_ATTR_PREFIX;
  cf->wsc_soap_content_type = ZXID_WSC_SOAP_CONTENT_TYPE;
  cf->wsc_to_hdr        = ZXID_WSC_TO_HDR;
  cf->wsc_replyto_hdr   = ZXID_WSC_REPLYTO_HDR;
  cf->wsc_action_hdr    = ZXID_WSC_ACTION_HDR;
  cf->soap_action_hdr   = ZXID_SOAP_ACTION_HDR;

  cf->bare_url_entityid = ZXID_BARE_URL_ENTITYID;
  cf->show_tech         = ZXID_SHOW_TECH;
  cf->wd                = ZXID_WD;
  cf->idp_sel_page      = ZXID_IDP_SEL_PAGE;
  cf->idp_sel_templ_file= ZXID_IDP_SEL_TEMPL_FILE;
  cf->idp_sel_templ     = ZXID_IDP_SEL_TEMPL;
#if 0
  cf->idp_sel_start     = ZXID_IDP_SEL_START;
  cf->idp_sel_new_idp   = ZXID_IDP_SEL_NEW_IDP;
  cf->idp_sel_our_eid   = ZXID_IDP_SEL_OUR_EID;
  cf->idp_sel_tech_user = ZXID_IDP_SEL_TECH_USER;
  cf->idp_sel_tech_site = ZXID_IDP_SEL_TECH_SITE;
  cf->idp_sel_footer    = ZXID_IDP_SEL_FOOTER;
  cf->idp_sel_end       = ZXID_IDP_SEL_END;
#endif

  cf->an_page           = ZXID_AN_PAGE;
  cf->an_templ_file     = ZXID_AN_TEMPL_FILE;
  cf->an_templ          = ZXID_AN_TEMPL;

  cf->post_templ_file   = ZXID_POST_TEMPL_FILE;
  cf->post_templ        = ZXID_POST_TEMPL;

  cf->err_page          = ZXID_ERR_PAGE;
  cf->err_templ_file    = ZXID_ERR_TEMPL_FILE;
  cf->err_templ         = ZXID_ERR_TEMPL;

  cf->new_user_page     = ZXID_NEW_USER_PAGE;
  cf->recover_passwd    = ZXID_RECOVER_PASSWD;
  cf->atsel_page        = ZXID_ATSEL_PAGE;

  cf->mgmt_start        = ZXID_MGMT_START;
  cf->mgmt_logout       = ZXID_MGMT_LOGOUT;
  cf->mgmt_defed        = ZXID_MGMT_DEFED;
  cf->mgmt_footer       = ZXID_MGMT_FOOTER;
  cf->mgmt_end          = ZXID_MGMT_END;
  
  cf->xmldsig_sig_meth  = ZXID_XMLDSIG_SIG_METH;
  cf->xmldsig_digest_algo = ZXID_XMLDSIG_DIGEST_ALGO;
  cf->samlsig_digest_algo = ZXID_SAMLSIG_DIGEST_ALGO;
  cf->blobsig_digest_algo = ZXID_BLOBSIG_DIGEST_ALGO;

  LOCK_INIT(cf->mx);
  LOCK_INIT(cf->curl_mx);
  if (!zxid_ent_cache_mx_init) {
    LOCK_INIT(zxid_ent_cache_mx);
    zxid_ent_cache_mx_init = 1;
  }
  
#if 1
  DD("path(%.*s) cf->magic=%x", cf->cpath_len, cf->cpath, cf->magic);
#else
  fprintf(stderr, "t %9s:%-3d %-16s %s d " "path(%.*s) cf->magic=%x" "\n",
	  __FILE__, __LINE__, __FUNCTION__, ERRMAC_INSTANCE, cf->cpath_len, cf->cpath, cf->magic);
  fflush(stderr);
#endif
  return 0;
}

/*() Reverse of zxid_init_conf() and zxid_parse_conf_raw(). */

/* Called by: */
void zxid_free_conf(zxid_conf *cf)
{
  zxid_free_need(cf, cf->need);
  zxid_free_need(cf, cf->want);
  zxid_free_atsrc(cf, cf->attrsrc);
  zxid_free_bus_url(cf, cf->bus_url);
  zxid_free_map(cf, cf->inmap);
  zxid_free_map(cf, cf->outmap);
  zxid_free_map(cf, cf->pepmap);
  zxid_free_map(cf, cf->pepmap_rqout);
  zxid_free_map(cf, cf->pepmap_rqin);
  zxid_free_map(cf, cf->pepmap_rsout);
  zxid_free_map(cf, cf->pepmap_rsin);
  zxid_free_cstr_list(cf, cf->localpdp_role_permit);
  zxid_free_cstr_list(cf, cf->localpdp_role_deny);
  zxid_free_cstr_list(cf, cf->localpdp_idpnid_permit);
  zxid_free_cstr_list(cf, cf->localpdp_idpnid_deny);
  zxid_free_cstr_list(cf, cf->issue_authnctx);
  zxid_free_map(cf, cf->unix_grp_az_map);
  if (cf->required_authnctx) {
    ZX_FREE(cf->ctx, cf->required_authnctx);
  }
  if (cf->fedusername_suffix) {
    ZX_FREE(cf->ctx, cf->fedusername_suffix);
  }
  if (cf->cpath) {
    ZX_FREE(cf->ctx, cf->cpath);
  }
}

/*() Reset the doubly linked seen list and unknown_ns list to empty.
 * This is "light" version of zx_reset_ctx() that can be called
 * safely from inside lock. */

/* Called by:  sig_validate, zx_prepare_dec_ctx, zx_reset_ctx, zxid_sp_sso_finalize */
void zx_reset_ns_ctx(struct zx_ctx* ctx)
{
  ctx->guard_seen_n.seen_n = &ctx->guard_seen_p;
  ctx->guard_seen_p.seen_p = &ctx->guard_seen_n;
  ctx->unknown_ns = 0;
}

/*() Reset the seen doubly linked list to empty and initialize memory
 * allocation related function pointers to system malloc(3). Without
 * such initialization, any memory allocation activity as well as
 * any XML parsing activity is doomed to segmentation fault. */

/* Called by:  dirconf, main x3, zx_init_ctx, zxid_az, zxid_az_base, zxid_simple_len */
void zx_reset_ctx(struct zx_ctx* ctx)
{
  ZERO(ctx, sizeof(struct zx_ctx));
  LOCK_INIT(ctx->mx);
  ctx->malloc_func = &malloc;
  ctx->realloc_func = &realloc;
  ctx->free_func = &free;
  zx_reset_ns_ctx(ctx);
}

/*() Allocate new ZX object and initialize it in standard
 * way, i.e. use malloc(3) for memory allocation. */

/* Called by:  zxid_conf_to_cf_len, zxid_init_conf_ctx */
struct zx_ctx* zx_init_ctx()
{
  struct zx_ctx* ctx;
  ctx = malloc(sizeof(struct zx_ctx));
  D("malloc %p size=%d", ctx, (int)sizeof(struct zx_ctx));
  if (!ctx) {
    ERR("out-of-memory in ctx alloc sizeof=%d", (int)sizeof(struct zx_ctx));
    return 0;
  }
  zx_reset_ctx(ctx);
  return ctx;
}

/*() Reverse of zx_init_ctx().
 * N.B. As of now (20111210) does not free the dependency structures. This
 * may be added in future. */

/* Called by: */
void zx_free_ctx(struct zx_ctx* ctx)
{
  free(ctx);
}

/*() Minimal initialization of
 * the context is performed. Certificate and key operations as well as
 * CURL initialization are omitted. However the zx_ctx is installed so
 * that memory allocation against the context should work.
 * Supplying zxid_path merely initializes the PATH config option,
 * but does not cause configuration file to be read.
 *
 * Just initializes the config object to factory defaults (see zxidconf.h).
 * Previous content of the config object is lost. */

/* Called by:  zxid_conf_to_cf_len, zxid_new_conf */
zxid_conf* zxid_init_conf_ctx(zxid_conf* cf, const char* zxid_path)
{
#if 0
  fprintf(stderr, "Waiting 60 secs for gdb attach...\n");
  sleep(60);
#endif
  cf->ctx = zx_init_ctx();
  if (!cf->ctx)
    return 0;
  zxid_init_conf(cf, zxid_path);
#ifdef USE_CURL
  if (zxid_path) {
    cf->curl = curl_easy_init();
    if (!cf->curl) {
      ERR("Failed to initialize libcurl %d",0);
      exit(2);
    }
  }
#endif
  return cf;
}

/*() Allocate conf object and initialize it with default config (config file is not read).
 * See zxid_new_conf_to_cf() for a more complete solution.
 * Just initializes the config object to factory defaults (see zxidconf.h).
 * Previous content of the config object is lost. */

/* Called by:  attribute_sort_test, covimp_test, main x4, so_enc_dec, test_ibm_cert_problem, test_ibm_cert_problem_enc_dec, test_mode, timegm_test, timegm_tester, x509_test */
zxid_conf* zxid_new_conf(const char* zxid_path)
{
  /* *** unholy malloc()s: should use our own allocator! */
  zxid_conf* cf = malloc(sizeof(zxid_conf));
  if (!cf) {
    ERR("out-of-memory %d", (int)sizeof(zxid_conf));
    exit(1);
  }
  return zxid_init_conf_ctx(cf, zxid_path);
}

/* ======================= CONF PARSING ======================== */

#if defined(ZXID_CONF_FILE) || defined(ZXID_CONF_FLAG)

#define SCAN_INT(v, lval) sscanf(v,"%i",&i); lval=i /* Safe for char, too. Decimal or hex 0x */

/*(-) Helper to evaluate a new PATH. check_file_exists helps to implement
 * the sematic where PATH is not changed unless corresponding zxid.conf
 * is found. This is used by VPATH. */

/* Called by:  zxid_parse_conf_raw, zxid_parse_vpath */
static void zxid_parse_conf_path_raw(zxid_conf* cf, const char* v, int check_file_exists)
{
  int len;
  char *buf;

  /* N.B: The buffer read here leaks on purpose as conf parsing takes references inside it. */
  buf = read_all_alloc(cf->ctx, "-parse_conf_raw", 1, &len, "%s" ZXID_CONF_FILE, v);
  if (!buf || !len)
    buf = read_all_alloc(cf->ctx, "-parse_conf_raw", 1, &len, "%szxid.conf", v);
  if (buf && len) {
    cf->cpath = (char*)v;
    cf->cpath_len = strlen(v);
    ++cf->cpath_supplied;   /* Record level of recursion so we can avoid infinite recursion. */
    if (len)
      zxid_parse_conf_raw(cf, len, buf);  /* Recurse */
    --cf->cpath_supplied;
  } else if (!check_file_exists) {
    cf->cpath = (char*)v;   /* Set PATH anyway. */
    cf->cpath_len = strlen(v);
  }
}

/*(-) Helper to parse an include file. check_file_exists helps to implement
 * the sematic where PATH is not changed unless corresponding zxid.conf
 * is found. This is used by VPATH. */

/* Called by:  zxid_parse_conf_raw */
static void zxid_parse_inc(zxid_conf* cf, const char* inc_file, int check_file_exists)
{
  int len;
  char *buf;

  /* N.B: The buffer read here leaks on purpose as conf parsing takes references inside it. */
  buf = read_all_alloc(cf->ctx, "-parse_inc", 1, &len, "%s", inc_file);
  if (buf && len) {
    ++cf->cpath_supplied;   /* Record level of recursion so we can avoid infinite recursion. */
    if (len)
      zxid_parse_conf_raw(cf, len, buf);  /* Recurse */
    --cf->cpath_supplied;
  } else if (check_file_exists) {
    ERR("Mandatory configuration include file(%s) not found. Aborting.", inc_file);
    DIE_ACTION(errno);
  } else {
    ERR("Optional configuration include file(%s) not found. Ignored.", inc_file);
  }
}

int zxid_suppress_vpath_warning = 30;

/*() Helper to evaluate environment variables for VPATH and VURL.
 * squash_type: 0=VPATH, 1=VURL
 * Squashing conversts everything to lowercase and anything
 * not understood to underscore ("_"). In case of VURL squash,
 * URL characters [/:?&=] are left intact. */

/* Called by:  zxid_expand_percent x4 */
static int zxid_eval_squash_env(char* vorig, const char* exp, char* env_hdr, char* out, char* lim, int squash_type)
{
  int len;
  char* val = getenv(env_hdr);
  if (!val) {
    if (--zxid_suppress_vpath_warning > 0) ERR("VPATH or VURL(%s) %s expansion specified, but env(%s) not defined?!? Violation of CGI spec? SERVER_SOFTWARE(%s)", vorig, exp, env_hdr, STRNULLCHKQ(getenv("SERVER_SOFTWARE")));
    return 0;
  }
  len = strlen(val);
  if (out + len > lim) {
    ERR("TOO LONG: VPATH or VURL(%s) %s expansion specified env(%s) val(%s) does not fit, missing %ld bytes. SERVER_SOFTWARE(%s)", vorig, exp, env_hdr, val, (long)(lim - (out + len)), STRNULLCHKQ(getenv("SERVER_SOFTWARE")));
    return 0;
  }

  /* Squash suspicious */

  for (; *val; ++val, ++out)
    if (!squash_type && IN_RANGE(*val, 'A', 'Z')) {
      *out = *val - ('A' - 'a');  /* lowercase host names */
    } else if (IN_RANGE(*val, 'a', 'z') || IN_RANGE(*val, '0', '9') || ONE_OF_2(*val, '.', '-')) {
      *out = *val;
    } else if (squash_type == 1 && ONE_OF_5(*val, '/', ':', '?', '&', '=')) {
      *out = *val;
    } else {
      *out = '_';
    }
  return len;
}

/*() Expand percent expansions as found in VPATH and VURL
 * squash_type: 0=VPATH, 1=VURL.
 * See CGI specification for environment variables such as
 *   %h expands to HTTP_HOST (from Host header, e.g. Host: sp.foo.bar or Host: sp.foo.bar:8443)
 *   %s expands to SCRIPT_NAME
 *   %d expands to directory portion of SCRIPT_NAME
 */

/* Called by:  zxid_parse_vpath, zxid_parse_vurl */
static char* zxid_expand_percent(char* vorig, char* out, char* lim, int squash_type)
{
  int len;
  char* x;
  char* p;
  char* val;
  --lim;
  for (p = vorig; *p && out < lim; ++p) {
    if (*p != '%') {
      *out++ = *p;
      continue;
    }
    switch (*++p) {
    case 'a':
      val = getenv("SERVER_PORT");
      if (!val)
	val = "";
      if (!memcmp(val, "80", MIN(strlen(val), 2)) || !memcmp(val, "88", MIN(strlen(val), 2)))
	x = squash_type?"http://":"http_";
      else
	x = squash_type?"https://":"https_";
      if (out + strlen(x) >= lim)
	goto toobig;
      strcpy(out, x);
      out += strlen(out);
      break;
    case 'h': out += zxid_eval_squash_env(vorig, "%h", "HTTP_HOST", out, lim, squash_type); break;
    case 'P': 
      val = getenv("SERVER_PORT");
      if (!val)
	val = "";
      if (!strcmp(val, "443") || !strcmp(val, "80"))
	break;     /* omit default ports */
      if (out >= lim)
	goto toobig;
      *out++ = ':';  /* colon in front of port, e.g. :8080 */
      /* fall thru */
    case 'p': out += zxid_eval_squash_env(vorig,"%p", "SERVER_PORT", out, lim, squash_type); break;
    case 's': out += zxid_eval_squash_env(vorig,"%s", "SCRIPT_NAME", out, lim, squash_type); break;
    case 'd':
      len = zxid_eval_squash_env(vorig, "%d", "SCRIPT_NAME", out, lim, squash_type);
      for (out += len; len && out[-1] != '/'; --out, --len) ;
      break;
    case '%': *out++ = '%';  break;
    default:
      ERR("VPATH or VURL(%s): Syntactically wrong percent expansion character(%c) 0x%x, ignored", vorig, p[-1], p[-1]);
    }
  }
  *out = 0;
  return out;
 toobig:
  ERR("VPATH or VURL(%s) extrapolation does not fit in buffer", vorig);
  *out = 0;
  return out;
}

/*(-) Convert, in place, $ to & as needed for WSC_LOCALPDP_PLEDGE */

/* Called by:  zxid_parse_conf_raw x2 */
static char* zxid_dollar_to_amp(char* p)
{
  char* ret = p;
  for (p = strchr(p, '$'); p; p = strchr(p, '$'))
    *p = '&';
  return ret;
}

/*() Parse VPATH (virtual host) related config file.
 * If the file VPATHzxid.conf does not exist (note that the specified
 * VPATH usually ends in a slash ("/")), the PATH is not changed.
 * Effectively unconfigured VPATHs are handled by the default PATH. */

/* Called by:  zxid_parse_conf_raw */
static int zxid_parse_vpath(zxid_conf* cf, char* vpath)
{
  char newpath[PATH_MAX];
  char *np, *lim;

  DD("VPATH inside file(%.*s) %d new(%s)", cf->cpath_len, cf->cpath, cf->cpath_supplied, vpath);
  if (cf->cpath_supplied && !memcmp(cf->cpath, vpath, cf->cpath_len)
      || cf->cpath_supplied > ZXID_PATH_MAX_RECURS_EXPAND_DEPTH) {
    D("Skipping VPATH inside file(%.*s) path_supplied=%d", cf->cpath_len, cf->cpath, cf->cpath_supplied);
    return 0;
  }

  /* Check for relative path and prepend PATH if needed. */
  
  np = newpath;
  lim = newpath + sizeof(newpath);
  
  if (*vpath != '/') {
    if (cf->cpath_len > lim-np) {
      ERR("TOO LONG: CPATH(%.*s) len=%d does not fit in vpath buffer size=%ld", cf->cpath_len, cf->cpath, cf->cpath_len, (long)(lim-np));
      return 0;
    }
    memcpy(np, cf->cpath, cf->cpath_len);
    np +=  cf->cpath_len;
  }
  
  zxid_expand_percent(vpath, np, lim, 0);
  if (--zxid_suppress_vpath_warning > 0) {
    INFO("VPATH(%s) alters CPATH(%s) to new CPATH(%s)", vpath, cf->cpath, newpath);
  }
  zxid_parse_conf_path_raw(cf, zx_dup_cstr(cf->ctx, newpath), 1);
  return 1;
}

/*() Parse VURL (virtual host) to URL */

/* Called by:  zxid_parse_conf_raw */
static int zxid_parse_vurl(zxid_conf* cf, char* vurl)
{
  char newurl[PATH_MAX];
  zxid_expand_percent(vurl, newurl, newurl + sizeof(newurl), 1);
  if (--zxid_suppress_vpath_warning > 0) {
    INFO("VURL(%s) alters BURL(%s) to new BURL(%s)", vurl, cf->burl, newurl);
  }
  cf->burl = zx_dup_cstr(cf->ctx, newurl);
  return 1;
}

/*(i) Parse partial configuration specifications, such as may occur
 * on command line or in a configuration file.
 *
 * Generally you should
 * call first zxid_new_conf(), or at least zxid_init_conf(), and
 * then call this function to apply modifications over the defaults.
 * The configuration options are named after the config options
 * that appear in zxidconf.h, except that prefix ZXID_ is removed.
 *
 * N.B. The qs memory must come from static or permanently allocated
 * source as direct pointers to inside it will be taken. The memory
 * will be modified to add nul terminations. Do not use stack based
 * memory like local variable (unless local of main()).
 * Do consider strdup() or similar before calling this function.
 *
 * cf:: Previously allocated and initialized ZXID configuration object
 * qs_len:: Query String length. -1 means nul terminated C string
 * qs:: Configuration data in extended CGI Query String format. "extended"
 *     means newline can be used as separator, in addition to ampersand ("&")
 *     This argument is modified in place, changing separators to nul string
 *     terminations and performing URL decoding.
 * return:: -1 on failure, 0 on success */

/* Called by:  zxid_conf_to_cf_len x4, zxid_parse_conf, zxid_parse_conf_path_raw */
int zxid_parse_conf_raw(zxid_conf* cf, int qs_len, char* qs)
{
  int i;
  int lineno;
  char *p, *n, *v;
  if (qs_len != -1 && qs[qs_len]) {  /* *** access one past end of buffer */
    ERR("LIMITATION: The configuration strings MUST be nul terminated (even when length is supplied explicitly). qs_len=%d qs(%.*s)", qs_len, qs_len, qs);
    return -1;
  }
  for (lineno = 1; qs && *qs; ++lineno) {
    qs = zxid_qs_nv_scan(qs, &n, &v, 1);
    if (!n) {
      if (!qs)
	break;
      n = "NULL_NAME_ERR";
    }
    
    if (!strcmp(n, ZXID_PATH_OPT))       goto path;
    
    switch (n[0]) {
    case 'A':  /* AUTHN_REQ_SIGN, ACT, AUDIENCE_FATAL, AFTER_SLOP */
      if (!strcmp(n, "AUTO_CERT"))       { SCAN_INT(v, cf->auto_cert); break; }
      if (!strcmp(n, "AUTHN_REQ_SIGN"))  { SCAN_INT(v, cf->authn_req_sign); break; }
      if (!strcmp(n, "ACT"))             { SCAN_INT(v, cf->log_act); break; }
      if (!strcmp(n, "ACT_IN_ERR"))      { SCAN_INT(v, cf->log_err_in_act); break; }
      if (!strcmp(n, "AUDIENCE_FATAL"))  { SCAN_INT(v, cf->audience_fatal); break; }
      if (!strcmp(n, "AFTER_SLOP"))      { SCAN_INT(v, cf->after_slop); break; }
      if (!strcmp(n, "ANON_OK"))         { cf->anon_ok = v; D("anon_ok(%s)", cf->anon_ok); break; }
      if (!strcmp(n, "AN_PAGE"))         { cf->an_page = v; break; }
      if (!strcmp(n, "AN_TEMPL_FILE"))   { cf->an_templ_file = v; break; }
      if (!strcmp(n, "AN_TEMPL"))        { cf->an_templ = v; break; }
      if (!strcmp(n, "ATSEL_PAGE"))      { cf->atsel_page = v; break; }
      if (!strcmp(n, "ATTRSRC"))     { cf->attrsrc = zxid_load_atsrc(cf, cf->attrsrc, v); break; }
      if (!strcmp(n, "A7NTTL"))          { SCAN_INT(v, cf->a7nttl); break; }
      if (!strcmp(n, "AS_ENA"))          { SCAN_INT(v, cf->as_ena); break; }
      if (!strcmp(n, "AZ_OPT"))          { SCAN_INT(v, cf->az_opt); break; }
      if (!strcmp(n, "AZ_FAIL_MODE"))    { SCAN_INT(v, cf->az_fail_mode); break; }
      goto badcf;
    case 'B':  /* BEFORE_SLOP */
      if (!strcmp(n, "BURL"))            { cf->burl = v; cf->fedusername_suffix = zxid_grab_domain_name(cf, cf->burl); break; }
      if (!strcmp(n, "BEFORE_SLOP"))       { SCAN_INT(v, cf->before_slop); break; }
      if (!strcmp(n, "BOOTSTRAP_LEVEL"))   { SCAN_INT(v, cf->bootstrap_level); break; }
      if (!strcmp(n, "BARE_URL_ENTITYID")) { SCAN_INT(v, cf->bare_url_entityid); break; }
      if (!strcmp(n, "BUTTON_URL"))        {
	if (!strstr(v, "saml2_icon_468x60") && !strstr(v, "saml2_icon_150x60") && !strstr(v, "saml2_icon_16x16"))
	  ERR("BUTTON_URL has to specify button image and the image filename MUST contain substring \"saml2_icon\" in it (see symlabs-saml-displayname-2008.pdf submitted to OASIS SSTC). Furthermore, this substring must specify the size, which must be one of 468x60, 150x60, or 16x16. Acceptable substrings are are \"saml2_icon_468x60\", \"saml2_icon_150x60\", \"saml2_icon_16x16\", e.g. \"https://your-domain.com/your-brand-saml2_icon_150x60.png\". Current value(%s) may be used despite this error. Only last acceptable specification of BUTTON_URL will be used. (conf line %d", v, lineno);
	if (!cf->button_url || strstr(v, cf->pref_button_size)) /* Pref overrides previous. */
	  cf->button_url = v;
	break;
      }
      if (!strcmp(n, "BUS_URL"))         { cf->bus_url = zxid_load_bus_url(cf, cf->bus_url, v);   break; }
      if (!strcmp(n, "BUS_PW"))          { cf->bus_pw = v; break; }
      if (!strcmp(n, "BACKWARDS_COMPAT_ENA")) { SCAN_INT(v, cf->backwards_compat_ena); break; }
      if (!strcmp(n, "BLOBSIG_DIGEST_ALGO")) { cf->blobsig_digest_algo = v; break; }
      goto badcf;
    case 'C':  /* CDC_URL, CDC_CHOICE */
      if (!strcmp(n, "CPATH"))           goto path;
      if (!strcmp(n, "CDC_URL"))         { cf->cdc_url = v; break; }
      if (!strcmp(n, "CDC_CHOICE"))      { SCAN_INT(v, cf->cdc_choice); break; }
      if (!strcmp(n, "CONTACT_ORG"))     { cf->contact_org = v; break; }
      if (!strcmp(n, "CONTACT_NAME"))    { cf->contact_name = v; break; }
      if (!strcmp(n, "CONTACT_EMAIL"))   { cf->contact_email = v; break; }
      if (!strcmp(n, "CONTACT_TEL"))     { cf->contact_tel = v; break; }
      if (!strcmp(n, "COUNTRY"))         { cf->country = v; break; }
      if (!strcmp(n, "CANON_INOPT"))     { SCAN_INT(v, cf->canon_inopt); if (cf->ctx) cf->ctx->canon_inopt = cf->canon_inopt; break; }
      if (!strcmp(n, "CPN_ENA"))         { SCAN_INT(v, cf->cpn_ena); break; }
      goto badcf;
    case 'D':  /* DUP_A7N_FATAL, DUP_MSG_FATAL */
      if (!strcmp(n, "DEFAULTQS"))       { cf->defaultqs = v; break; }
      if (!strcmp(n, "DUP_A7N_FATAL"))   { SCAN_INT(v, cf->dup_a7n_fatal); break; }
      if (!strcmp(n, "DUP_MSG_FATAL"))   { SCAN_INT(v, cf->dup_msg_fatal); break; }
      if (!strcmp(n, "DI_ALLOW_CREATE")) { cf->di_allow_create = *v; break; }
      if (!strcmp(n, "DI_NID_FMT"))      { SCAN_INT(v, cf->di_nid_fmt); break; }
      if (!strcmp(n, "DI_A7N_ENC"))      { SCAN_INT(v, cf->di_a7n_enc); break; }
      if (!strcmp(n, "DEBUG"))           { SCAN_INT(v, errmac_debug); INFO("errmac_debug:%d", errmac_debug); break; }
      if (!strcmp(n, "DEBUG_LOG"))       { zxid_set_opt_cstr(cf, 6, v); break; }
      if (!strcmp(n, "D"))               { D("D=%s (conf line %d)", v, lineno); break; }
      if (!strcmp(n, "DIE"))             { ERR("DIE=%s (conf line %d)", v, lineno); DIE_ACTION(1); break; }
      goto badcf;
    case 'E':  /* ERR, ERR_IN_ACT */
      if (!strcmp(n, "ERR"))             { SCAN_INT(v, cf->log_err); break; }
      if (!strcmp(n, "ERR_IN_ACT"))      { SCAN_INT(v, cf->log_err_in_act); break; }
      if (!strcmp(n, "ENC_TAIL_OPT"))    { SCAN_INT(v, cf->enc_tail_opt); break; }
      if (!strcmp(n, "ENCKEY_OPT"))      { SCAN_INT(v, cf->enckey_opt); break; }
      if (!strcmp(n, "ERR_PAGE"))        { cf->err_page = v; break; }
      if (!strcmp(n, "ERR_TEMPL_FILE"))  { cf->err_templ_file = v; break; }
      if (!strcmp(n, "ERR_TEMPL"))       { cf->err_templ = v; break; }
      if (!strcmp(n, "ECHO"))            { INFO("ECHO=%s (conf line %d)", v, lineno); break; }
      goto badcf;
    case 'F':
      if (!strcmp(n, "FEDUSERNAME_SUFFIX")) { cf->fedusername_suffix = v; break; }
      goto badcf;
    case 'I':  /* ISSUE_A7N, ISSUE_MSG */
      if (!strcmp(n, "ISSUE_A7N"))       { SCAN_INT(v, cf->log_issue_a7n); break; }
      if (!strcmp(n, "ISSUE_MSG"))       { SCAN_INT(v, cf->log_issue_msg); break; }
      if (!strcmp(n, "ISSUE_AUTHNCTX"))  { cf->issue_authnctx = zxid_load_cstr_list(cf, cf->issue_authnctx, v); break; }
#if 0
      if (!strcmp(n, "IDP_SEL_START"))   { cf->idp_sel_start = v; break; }
      if (!strcmp(n, "IDP_SEL_NEW_IDP")) { cf->idp_sel_new_idp = v; break; }
      if (!strcmp(n, "IDP_SEL_OUR_EID")) { cf->idp_sel_our_eid = v; break; }
      if (!strcmp(n, "IDP_SEL_TECH_USER")) { cf->idp_sel_tech_user =v; break; }
      if (!strcmp(n, "IDP_SEL_TECH_SITE")) { cf->idp_sel_tech_site =v; break; }
      if (!strcmp(n, "IDP_SEL_FOOTER"))  { cf->idp_sel_footer = v; break; }
      if (!strcmp(n, "IDP_SEL_END"))     { cf->idp_sel_end = v; break; }
#endif
      if (!strcmp(n, "IDP_SEL_PAGE"))    { cf->idp_sel_page = v; break; }
      if (!strcmp(n, "IDP_SEL_TEMPL_FILE")) { cf->idp_sel_templ_file = v; break; }
      if (!strcmp(n, "IDP_SEL_TEMPL"))   { cf->idp_sel_templ = v; break; }
      if (!strcmp(n, "IDP_ENA"))         { SCAN_INT(v, cf->idp_ena); break; }
      if (!strcmp(n, "IDP_PXY_ENA"))     { SCAN_INT(v, cf->idp_pxy_ena); break; }
      if (!strcmp(n, "IMPS_ENA"))        { SCAN_INT(v, cf->imps_ena); break; }
      if (!strcmp(n, "IDP_PREF_ACS_BINDING")) { cf->idp_pref_acs_binding = v; break; }
      if (!strcmp(n, "IDPATOPT"))        { SCAN_INT(v, cf->idpatopt); break; }
      if (!strcmp(n, "IDP_LIST_METH"))   { SCAN_INT(v, cf->idp_list_meth); break; }
      if (!strcmp(n, "INMAP"))           { cf->inmap = zxid_load_map(cf, cf->inmap, v); break; }
      if (!strcmp(n, "INFO"))            { INFO("INFO=%s (conf line %d)", v, lineno); break; }
      if (!strcmp(n, "INCLUDE"))         { zxid_parse_inc(cf, v, 1); break; }
      goto badcf;
    case 'L':  /* LEVEL (log level) */
      if (!strcmp(n, "LEVEL"))     { SCAN_INT(v, cf->log_level); break; }
      if (!strcmp(n, "LOGUSER"))   { SCAN_INT(v, cf->loguser); break; }
      if (!strcmp(n, "LOCALPDP_ROLE_PERMIT"))   { cf->localpdp_role_permit   = zxid_load_cstr_list(cf, cf->localpdp_role_permit, v);   break; }
      if (!strcmp(n, "LOCALPDP_ROLE_DENY"))     { cf->localpdp_role_deny     = zxid_load_cstr_list(cf, cf->localpdp_role_deny, v);     break; }
      if (!strcmp(n, "LOCALPDP_IDPNID_PERMIT")) { cf->localpdp_idpnid_permit = zxid_load_cstr_list(cf, cf->localpdp_idpnid_permit, v); break; }
      if (!strcmp(n, "LOCALPDP_IDPNID_DENY"))   { cf->localpdp_idpnid_deny   = zxid_load_cstr_list(cf, cf->localpdp_idpnid_deny, v);   break; }
      if (!strcmp(n, "LOAD_COT_CACHE"))  { cf->load_cot_cache = v; break; }
      if (!strcmp(n, "LOCALITY"))        { cf->locality = v; break; }
      goto badcf;
    case 'M':  /* MD_FETCH, MD_POPULATE_CACHE, MD_CACHE_FIRST, MD_CACHE_LAST */
      if (!strcmp(n, "MANDATORY_ATTR"))    { cf->mandatory_attr = v; break; }
      if (!strcmp(n, "MD_FETCH"))          { SCAN_INT(v, cf->md_fetch); break; }
      if (!strcmp(n, "MD_POPULATE_CACHE")) { SCAN_INT(v, cf->md_populate_cache); break; }
      if (!strcmp(n, "MD_CACHE_FIRST"))    { SCAN_INT(v, cf->md_cache_first); break; }
      if (!strcmp(n, "MD_CACHE_LAST"))     { SCAN_INT(v, cf->md_cache_last); break; }
      if (!strcmp(n, "MD_AUTHORITY_ENA"))  { SCAN_INT(v, cf->md_authority_ena); break; }
      if (!strcmp(n, "MD_AUTHORITY")) { cf->md_authority = v; break; }
      if (!strcmp(n, "MGMT_START"))   { cf->mgmt_start = v; break; }
      if (!strcmp(n, "MGMT_LOGOUT"))  { cf->mgmt_logout = v; break; }
      if (!strcmp(n, "MGMT_DEFED"))   { cf->mgmt_defed = v; break; }
      if (!strcmp(n, "MGMT_FOOTER"))  { cf->mgmt_footer = v; break; }
      if (!strcmp(n, "MGMT_END"))     { cf->mgmt_end = v; break; }
      if (!strcmp(n, "MSG_SIG_OK"))   { SCAN_INT(v, cf->msg_sig_ok); break; }
      if (!strcmp(n, "MAX_SOAP_RETRY"))        { SCAN_INT(v, cf->max_soap_retry); break; }
      if (!strcmp(n, "MOD_SAML_ATTR_PREFIX"))  { cf->mod_saml_attr_prefix = v; break; }

      goto badcf;
    case 'N':  /* NAMEID_ENC, NICE_NAME, NOSIG_FATAL */
      if (!strcmp(n, "NAMEID_ENC"))     { SCAN_INT(v, cf->nameid_enc); break; }
      if (!strcmp(n, "NICE_NAME"))      { cf->nice_name = v; break; }
      if (!strcmp(n, "NON_STANDARD_ENTITYID")) { cf->non_standard_entityid = v; D("NON_STANDARD_ENTITYID set(%s)", v); break; }
      if (!strcmp(n, "NOSIG_FATAL"))    { SCAN_INT(v, cf->nosig_fatal); break; }
      if (!strcmp(n, "NOTIMESTAMP_FATAL")) { SCAN_INT(v, cf->notimestamp_fatal); break; }
      if (!strcmp(n, "NEED"))           { cf->need = zxid_load_need(cf, cf->need, v); break; }
      if (!strcmp(n, "NEW_USER_PAGE"))  { cf->new_user_page = v; break; }
      goto badcf;
    case 'O':  /* OUTMAP */
      if (!strcmp(n, "OUTMAP"))         { cf->outmap = zxid_load_map(cf, cf->outmap, v); break; }
      if (!strcmp(n, "ORG_NAME"))       { cf->org_name = v; break; }
      if (!strcmp(n, "ORG_URL"))        {
	ERR("Discontinued configuration option ORG_URL supplied. This option has been deleted. Use BUTTON_URL instead, but note that the URL has to specify button image instead of home page (the image filename MUST contain substring \"saml2_icon\" in it). Current value(%s) (conf line %d)", v, lineno);
	cf->button_url = v;
	break;
      }
      if (!strcmp(n, "OAZ_JWT_SIGENC_ALG")) { cf->oaz_jwt_sigenc_alg = *v; break; }
      if (!strcmp(n, "OPT_INCLUDE"))    { zxid_parse_inc(cf, v, 0); break; }
      if (!strcmp(n, "OPTIONAL_LOGIN_PAT")) { cf->optional_login_pat = v; D("optional_login_pat(%s)", cf->optional_login_pat); break; }
      goto badcf;
    case 'P':  /* PATH (e.g. /var/zxid) */
      DD("PATH maybe n(%s)=v(%s)", n, v);
      if (!strcmp(n, "PATH")) {
    path:
	DD("CPATH inside file(%.*s) %d new(%s)", cf->cpath_len, cf->cpath, cf->cpath_supplied, v);
	if (cf->cpath_supplied && !memcmp(cf->cpath, v, cf->cpath_len)
	    || cf->cpath_supplied > ZXID_PATH_MAX_RECURS_EXPAND_DEPTH) {
	  D("Skipping CPATH inside file(%.*s) cpath_supplied=%d", cf->cpath_len, cf->cpath, cf->cpath_supplied);
	  break;
	}
	zxid_parse_conf_path_raw(cf, v, 0);
	break;
      }
      if (!strcmp(n, "PDP_ENA"))        { SCAN_INT(v, cf->pdp_ena); break; }
      if (!strcmp(n, "PDP_URL"))        { cf->pdp_url = v; break; }
      if (!strcmp(n, "PDP_CALL_URL"))   { cf->pdp_call_url = v; break; }
      if (!strcmp(n, "PEPMAP"))         { cf->pepmap = zxid_load_map(cf, cf->pepmap, v); break; }
      if (!strcmp(n, "PEPMAP_RQOUT"))   { cf->pepmap_rqout = zxid_load_map(cf, cf->pepmap_rqout, v); break; }
      if (!strcmp(n, "PEPMAP_RQIN"))    { cf->pepmap_rqin  = zxid_load_map(cf, cf->pepmap_rqin,  v); break; }
      if (!strcmp(n, "PEPMAP_RSOUT"))   { cf->pepmap_rsout = zxid_load_map(cf, cf->pepmap_rsout, v); break; }
      if (!strcmp(n, "PEPMAP_RSIN"))    { cf->pepmap_rsin  = zxid_load_map(cf, cf->pepmap_rsin,  v); break; }
      if (!strcmp(n, "POST_A7N_ENC"))   { SCAN_INT(v, cf->post_a7n_enc); break; }
      if (!strcmp(n, "POST_TEMPL_FILE"))   { cf->post_templ_file = v; break; }
      if (!strcmp(n, "POST_TEMPL"))        { cf->post_templ = v; break; }
      if (!strcmp(n, "PREF_BUTTON_SIZE"))        {
	if (!strstr(v, "468x60") && !strstr(v, "150x60") && !strstr(v, "16x16"))
	  ERR("PREF_BUTTON_SIZE should specify one of the standard button image sizes, such as 468x60, 150x60, or 16x16 (and the image filename MUST contain substring \"saml2_icon\" in it, see symlabs-saml-displayname-2008.pdf submitted to OASIS SSTC). Current value(%s) is used despite this error. (conf line %d", v, lineno);
	cf->pref_button_size = v;
	break;
      }
      if (!strcmp(n, "PTM_COOKIE_NAME")) { cf->ptm_cookie_name = (!v[0] || v[0]=='0' && !v[1]) ? 0 : v; break; }
      if (!strcmp(n, "PRAGMA"))          { D("PRAGMA(%s)", v); break; }
      goto badcf;
    case 'R':  /* RELY_A7N, RELY_MSG */
      if (!strcmp(n, "REDIRECT_HACK_IMPOSED_URL")) { cf->redirect_hack_imposed_url = v; break; }
      if (!strcmp(n, "REDIRECT_HACK_ZXID_URL")) {
	cf->redirect_hack_zxid_url = v;
	p = strchr(v, '?');
	if (p) {
	  *p = 0;
	  cf->redirect_hack_zxid_qs = p+1;
	}
	break;
      }
      if (!strcmp(n, "REDIR_TO_CONTENT"))  { SCAN_INT(v, cf->redir_to_content); break; }
      if (!strcmp(n, "REMOTE_USER_ENA"))   { SCAN_INT(v, cf->remote_user_ena); break; }
      if (!strcmp(n, "RELY_A7N"))          { SCAN_INT(v, cf->log_rely_a7n); break; }
      if (!strcmp(n, "RELY_MSG"))          { SCAN_INT(v, cf->log_rely_msg); break; }
      if (!strcmp(n, "REQUIRED_AUTHNCTX")) {
	/* Count how many */
        for (i=2, p=v; *p; ++p)
	  if (*p == '$')
	    ++i;
	cf->required_authnctx = zx_zalloc(cf->ctx, sizeof(char*) * i);
	/* Populate array with strings, stomping the separator char $ to nul termination. */
        for (i=0, p=v; *p; ++i) {
	  cf->required_authnctx[i] = p;
	  p = strchr(p, '$');
	  if (!p)
	    break;
	  *p++ = 0;
	}
	break;
      }
      if (!strcmp(n, "RECOVER_PASSWD")) { cf->recover_passwd = v; break; }
      if (!strcmp(n, "RELTO_FATAL"))    { SCAN_INT(v, cf->relto_fatal); break; }
      if (!strcmp(n, "RCPT"))           { SCAN_INT(v, cf->bus_rcpt); break; }
      if (!strcmp(n, "REM"))            { /* no-op */ break; }
      goto badcf;
    case 'S':  /* SES_ARCH_DIR, SIGFAIL_IS_ERR, SIG_FATAL */
      if (!strcmp(n, "SES_ARCH_DIR"))   { cf->ses_arch_dir = (!v[0] || v[0]=='0' && !v[1]) ? 0 : v; break; }
      if (!strcmp(n, "SES_COOKIE_NAME")) { cf->ses_cookie_name = (!v[0] || v[0]=='0' && !v[1]) ? 0 : v; break; }
      if (!strcmp(n, "SIGFAIL_IS_ERR")) { SCAN_INT(v, cf->log_sigfail_is_err); break; }
      if (!strcmp(n, "SIG_FATAL"))      { SCAN_INT(v, cf->sig_fatal); break; }
      if (!strcmp(n, "SSO_SIGN"))       { SCAN_INT(v, cf->sso_sign); break; }
      if (!strcmp(n, "SSO_SOAP_SIGN"))  { SCAN_INT(v, cf->sso_soap_sign); break; }
      if (!strcmp(n, "SSO_SOAP_RESP_SIGN"))  { SCAN_INT(v, cf->sso_soap_resp_sign); break; }
      if (!strcmp(n, "SHOW_CONF"))      { SCAN_INT(v, cf->show_conf); break; }
      if (!strcmp(n, "SHOW_TECH"))      { SCAN_INT(v, cf->show_tech); break; }
      if (!strcmp(n, "STATE"))          { cf->state = v; break; }
      if (!strcmp(n, "SSO_PAT"))        { cf->sso_pat = v; break; }
      if (!strcmp(n, "SOAP_ACTION_HDR")) { cf->soap_action_hdr = v; break; }
      if (!strcmp(n, "SAMLSIG_DIGEST_ALGO")) { cf->samlsig_digest_algo = v; break; }
      goto badcf;
    case 'T':  /* TIMEOUT_FATAL */
      if (!strcmp(n, "TIMEOUT_FATAL"))  { SCAN_INT(v, cf->timeout_fatal); break; }
      if (!strcmp(n, "TIMESKEW"))       { SCAN_INT(v, cf->timeskew); break; }
      if (!strcmp(n, "TRUSTPDP_URL"))   { cf->trustpdp_url = v; break; }
      goto badcf;
    case 'U':  /* URL, USER_LOCAL */
      if (!strcmp(n, "URL"))            { cf->burl = v; cf->fedusername_suffix = zxid_grab_domain_name(cf, cf->burl); break; }
      if (!strcmp(n, "USER_LOCAL"))     { SCAN_INT(v, cf->user_local); break; }
      if (!strcmp(n, "UMA_PAT"))        { cf->uma_pat = v; break; }
      if (!strcmp(n, "UNIX_GRP_AZ_MAP")) { cf->unix_grp_az_map = zxid_load_unix_grp_az_map(cf, cf->unix_grp_az_map, v); break; }
      goto badcf;
    case 'V':  /* VALID_OPT */
      if (!strcmp(n, "VALID_OPT"))      { SCAN_INT(v, cf->valid_opt); break; }
      if (!strcmp(n, "VPATH"))          { zxid_parse_vpath(cf, v); break; }
      if (!strcmp(n, "VURL"))           { zxid_parse_vurl(cf, v); break; }
      goto badcf;
    case 'W':  /* WANT_SSO_A7N_SIGNED */
      if (!strcmp(n, "WANT"))           { cf->want = zxid_load_need(cf, cf->want, v); break; }
      if (!strcmp(n, "WANT_SSO_A7N_SIGNED"))   { SCAN_INT(v, cf->want_sso_a7n_signed); break; }
      if (!strcmp(n, "WANT_AUTHN_REQ_SIGNED")) { SCAN_INT(v, cf->want_authn_req_signed); break; }
      if (!strcmp(n, "WSC_SIGN"))       { SCAN_INT(v, cf->wsc_sign); break; }
      if (!strcmp(n, "WSP_SIGN"))       { SCAN_INT(v, cf->wsp_sign); break; }
      if (!strcmp(n, "WSPCGICMD"))      { cf->wspcgicmd = v; break; }
      if (!strcmp(n, "WSP_NOSIG_FATAL")) { SCAN_INT(v, cf->wsp_nosig_fatal); break; }
      if (!strcmp(n, "WSC_LOCALPDP_OBL_PLEDGE"))  { cf->wsc_localpdp_obl_pledge = zxid_dollar_to_amp(v);   break; }
      if (!strcmp(n, "WSP_LOCALPDP_OBL_REQ"))     { cf->wsp_localpdp_obl_req    = zxid_load_obl_list(cf, cf->wsp_localpdp_obl_req, v);   break; }
      if (!strcmp(n, "WSP_LOCALPDP_OBL_EMIT"))    { cf->wsp_localpdp_obl_emit   = zxid_dollar_to_amp(v);   break; }
      if (!strcmp(n, "WSC_LOCALPDP_OBL_ACCEPT"))  { cf->wsc_localpdp_obl_accept = zxid_load_obl_list(cf, cf->wsc_localpdp_obl_accept, v);   break; }
      if (!strcmp(n, "WD"))             { cf->wd = v; chdir(v); break; }
      if (!strcmp(n, "WSP_PAT"))        { cf->wsp_pat = v; break; }
      if (!strcmp(n, "WSC_SOAP_CONTENT_TYPE")) { cf->wsc_soap_content_type = v; break; }
      if (!strcmp(n, "WSC_TO_HDR"))     { cf->wsc_to_hdr = v; break; }
      if (!strcmp(n, "WSC_REPLYTO_HDR")) { cf->wsc_replyto_hdr = v; break; }
      if (!strcmp(n, "WSC_ACTION_HDR")) { cf->wsc_action_hdr = v; break; }
      if (!strcmp(n, "WARN"))           { WARN("WARN=%s (conf line %d)", v, lineno); break; }
      goto badcf;
    case 'X':  /* XASP_VERS */
      if (!strcmp(n, "XASP_VERS"))      { cf->xasp_vers = v; break; }
      if (!strcmp(n, "XMLDSIG_SIG_METH")) { cf->xmldsig_sig_meth = v; break; }
      if (!strcmp(n, "XMLDSIG_DIGEST_ALGO")) { cf->xmldsig_digest_algo = v; break; }
      goto badcf;
    default:
    badcf:
      ERR("Unknown config option(%s) val(%s), ignored (conf line %d)", n, v, lineno);
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "S", "BADCF", n, 0);
    }
  }
  return 0;
}

/*() Wrapper with initial error checking for zxid_parse_conf_raw(), which see. */

/* Called by:  opt x13, set_zxid_conf */
int zxid_parse_conf(zxid_conf* cf, char* qs)
{
  if (!cf || !qs)
    return -1;
  return zxid_parse_conf_raw(cf, strlen(qs), qs);
}

#endif

/*() Pretty print need or want chain.
 * *** leaks some ss and need nodes */

/* Called by:  zxid_show_conf x2 */
static struct zx_str* zxid_show_need(zxid_conf* cf, struct zxid_need* np)
{
  struct zxid_attr* ap;
  struct zx_str* ss;
  struct zx_str* need = zx_dup_str(cf->ctx, "");
  for (; np; np = np->n) {
    ss = zx_dup_str(cf->ctx, "");
    for (ap = np->at; ap; ap = ap->n) {
      ss = zx_strf(cf->ctx, "%s,%.*s", STRNULLCHK(ap->name), ss->len, ss->s);
    }
    if (ss->len) {  /* chop off last comma separator */
      ss->len -= 1;
      ss->s[ss->len] = 0;
    }
    need = zx_strf(cf->ctx, "  attrs(%s)\n    usage(%s)\n    retent(%s)\n    oblig(%s)\n    ext(%s)$\n%.*s",
		   ss->s, STRNULLCHK(np->usage), STRNULLCHK(np->retent),
		   STRNULLCHK(np->oblig), STRNULLCHK(np->ext),
		   need->len, need->s);
    ZX_FREE(cf->ctx, ss);
  }
  if (need->len) {  /* chop off last dollar separator */
    need->len -= 2;
    need->s[need->len] = 0;
  }
  return need;
}

/*() Pretty print map chain. */

/* Called by:  zxid_show_conf x7 */
static struct zx_str* zxid_show_map(zxid_conf* cf, struct zxid_map* mp)
{
  struct zx_str* inmap = zx_dup_str(cf->ctx, "");
  for (; mp; mp = mp->n) {
    inmap = zx_strf(cf->ctx, "  rule=%d$ ns(%s)$ src(%s)$ dst(%s)$ ext(%s);\n%.*s", mp->rule, STRNULLCHK(mp->ns), STRNULLCHK(mp->src), STRNULLCHK(mp->dst), STRNULLCHK(mp->ext), inmap->len, inmap->s);
  }
  if (inmap->len) {  /* chop off last semicolon separator */
    inmap->len -= 2;
    inmap->s[inmap->len] = 0;
  }
  return inmap;
}


/*() Pretty print cstr list as used in local PDP. */

/* Called by:  zxid_show_conf x4 */
static struct zx_str* zxid_show_cstr_list(zxid_conf* cf, struct zxid_cstr_list* cp)
{
  struct zx_str* ss = zx_dup_str(cf->ctx, "");
  for (; cp; cp = cp->n) {
    ss = zx_strf(cf->ctx, "  %s,\n%.*s", STRNULLCHK(cp->s), ss->len, ss->s);
  }
  if (ss->len) {  /* chop off last comma separator */
    ss->len -= 2;
    ss->s[ss->len] = 0;
  }
  return ss;
}

/*() Pretty print bus_url list. */

/* Called by:  zxid_show_conf */
static struct zx_str* zxid_show_bus_url(zxid_conf* cf, struct zxid_bus_url* cp)
{
  struct zx_str* ss = zx_dup_str(cf->ctx, "");
  for (; cp; cp = cp->n) {
    ss = zx_strf(cf->ctx, "  %s,\n%.*s", STRNULLCHK(cp->s), ss->len, ss->s);
  }
  if (ss->len) {  /* chop off last comma separator */
    ss->len -= 2;
    ss->s[ss->len] = 0;
  }
  return ss;
}

/*() Generate our SP CARML and return it as a string. */

/* Called by:  opt x5, zxid_simple_show_conf */
struct zx_str* zxid_show_conf(zxid_conf* cf)
{
  char* eid;
  char* p;
  struct zxid_attr* ap;
  struct zxid_atsrc* sp;
  struct zx_str* ss;
  struct zx_str* required_authnctx;
  struct zx_str* need;
  struct zx_str* want;
  struct zx_str* attrsrc;
  struct zx_str* bus_url;
  struct zx_str* inmap;
  struct zx_str* outmap;
  struct zx_str* pepmap;
  struct zx_str* pepmap_rqout;
  struct zx_str* pepmap_rqin;
  struct zx_str* pepmap_rsout;
  struct zx_str* pepmap_rsin;
  struct zx_str* localpdp_role_permit;
  struct zx_str* localpdp_role_deny;
  struct zx_str* localpdp_idpnid_permit;
  struct zx_str* localpdp_idpnid_deny;
  struct zx_str* issue_authnctx;
  struct zx_str* unix_grp_az_map;
  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "MYCONF", 0, 0);

  if (!cf->show_conf) {
    return zx_strf(cf->ctx, "<title>Conf dump disabled</title><body bgcolor=white>Conf viewing disabled using SHOW_CONF=0 option.");
  }

  /* N.B. The following way of "concatenating" strings leaks memory of the intermediate
   * results. We can't be bothered as the o=d is just a debug page. */

  required_authnctx = zx_dup_str(cf->ctx, "");
  for (p = cf->required_authnctx ? *cf->required_authnctx:0; p; ++p) {
    required_authnctx = zx_strf(cf->ctx, "  %s$\n%.*s", p, required_authnctx->len, required_authnctx->s);
  }
  if (required_authnctx->len) {  /* chop off last dollar separator */
    required_authnctx->len -= 2;
    required_authnctx->s[required_authnctx->len] = 0;
  }

  need = zxid_show_need(cf, cf->need);
  want = zxid_show_need(cf, cf->want);

  attrsrc = zx_dup_str(cf->ctx, "");
  for (sp = cf->attrsrc; sp; sp = sp->n) {
    ss = zx_dup_str(cf->ctx, "");
    for (ap = sp->at; ap; ap = ap->n) {
      ss = zx_strf(cf->ctx, "%s,%.*s", STRNULLCHK(ap->name), ss->len, ss->s);
    }
    if (ss->len) {  /* chop off last dollar separator */
      ss->len -= 1;
      ss->s[ss->len] = 0;
    }
    attrsrc = zx_strf(cf->ctx, "  attrs(%s)\n    ns(%s)\n    weight(%s)\n    burl(%s)\n    aapml(%s)\n    otherlim(%s)\n    ext(%s)$\n%.*s", ss->s, STRNULLCHK(sp->ns), STRNULLCHK(sp->weight), STRNULLCHK(sp->url), STRNULLCHK(sp->aapml), STRNULLCHK(sp->otherlim), STRNULLCHK(sp->ext),
		   attrsrc->len, attrsrc->s);
  }
  if (attrsrc->len) {  /* chop off last dollar separator */
    attrsrc->len -= 2;
    attrsrc->s[attrsrc->len] = 0;
  }

  bus_url = zxid_show_bus_url(cf, cf->bus_url);

  inmap = zxid_show_map(cf, cf->inmap);
  outmap = zxid_show_map(cf, cf->outmap);
  pepmap = zxid_show_map(cf, cf->pepmap);
  pepmap_rqout = zxid_show_map(cf, cf->pepmap_rqout);
  pepmap_rqin  = zxid_show_map(cf, cf->pepmap_rqin);
  pepmap_rsout = zxid_show_map(cf, cf->pepmap_rsout);
  pepmap_rsin  = zxid_show_map(cf, cf->pepmap_rsin);

  localpdp_role_permit   = zxid_show_cstr_list(cf, cf->localpdp_role_permit);
  localpdp_role_deny     = zxid_show_cstr_list(cf, cf->localpdp_role_deny);
  localpdp_idpnid_permit = zxid_show_cstr_list(cf, cf->localpdp_idpnid_permit);
  localpdp_idpnid_deny   = zxid_show_cstr_list(cf, cf->localpdp_idpnid_deny);

  issue_authnctx = zxid_show_cstr_list(cf, cf->issue_authnctx);

  unix_grp_az_map = zxid_show_map(cf, cf->unix_grp_az_map);

  eid = zxid_my_ent_id_cstr(cf);

  return zx_strf(cf->ctx,
"<title>Conf for %s</title><body bgcolor=white><h1>Conf for %s</h1>"
"<p>Please see config file in %s" ZXID_CONF_FILE ", and documentation in zxid-conf.pd and zxidconf.h\n"
"<p>[ <a href=\"?o=B\">Metadata</a> | <a href=\"?o=c\">CARML</a> | <a href=\"?o=d\">This Conf Dump</a> ]\n"
"<p>Version: R" ZXID_REL " (" ZXID_COMPILE_DATE ")\n"

"<pre>"
"DEBUG=0x%x\n"
"CPATH=%s\n"
"BURL=%s\n"
"AFFILIATION=%s\n"
"NICE_NAME=%s\n"
"BUTTON_URL=%s\n"
"PREF_BUTTON_SIZE=%s\n"
"ORG_NAME=%s\n"
"LOCALITY=%s\n"
"STATE=%s\n"
"COUNTRY=%s\n"
"CONTACT_ORG=%s\n"
"CONTACT_NAME=%s\n"
"CONTACT_EMAIL=%s\n"
"CONTACT_TEL=%s\n"
"FEDUSERNAME_SUFFIX=%s\n"
"#ZXID_CONF_FILE_ENA=%d (compile)\n"
"#ZXID_CONF_FLAG=%d (compile)\n"
"NON_STANDARD_ENTITYID=%s\n"
"REDIRECT_HACK_IMPOSED_URL=%s\n"
"REDIRECT_HACK_ZXID_URL=%s\n"
"REDIRECT_HACK_ZXID_QS=%s\n"
"DEFAULTQS=%s\n"
"WSP_PAT=%s\n"
"UMA_PAT=%s\n"
"SSO_PAT=%s\n"
"WSC_SOAP_CONTENT_TYPE=%s\n"
"WSC_TO_HDR=%s\n"
"WSC_REPLYTO_HDR=%s\n"
"WSC_ACTION_HDR=%s\n"
"SOAP_ACTION_HDR=%s\n"
"CDC_URL=%s\n"
"CDC_CHOICE=%d\n"

"LOAD_COT_CACHE=%s\n"
"MD_FETCH=%d\n"
"MD_POPULATE_CACHE=%d\n"
"MD_CACHE_FIRST=%d\n"
"MD_CACHE_LAST=%d\n"
"MD_AUTHORITY=%s\n"

"AUTO_CERT=%d\n"
"AUTHN_REQ_SIGN=%d\n"
"WANT_AUTHN_REQ_SIGNED=%d\n"
"WANT_SSO_A7N_SIGNED=%d\n"
"SSO_SOAP_SIGN=%d\n"
"SSO_SOAP_RESP_SIGN=%d\n"
"SSO_SIGN=%x\n"
"WSC_SIGN=%x\n"
"WSP_SIGN=%x\n"
"OAZ_JWT_SIGENC_ALG=%c\n"
"WSPCGICMD=%s\n"
"NAMEID_ENC=%x\n"
"POST_A7N_ENC=%d\n"
"CANON_INOPT=%x\n"
"ENC_TAIL_OPT=%x\n"
"ENCKEY_OPT=%d\n"
"VALID_OPT=0x%x\n"
"IDPATOPT=%d\n"
"DI_ALLOW_CREATE=%d\n"
"DI_NID_FMT=%d\n"
"DI_A7N_ENC=%d\n"
"BOOTSTRAP_LEVEL=%d\n"
"SHOW_CONF=%x\n"
"#ZXID_ID_BITS=%d (compile)\n"
"#ZXID_ID_MAX_BITS=%d (compile)\n"
"#ZXID_TRUE_RAND=%d (compile)\n"
"SES_ARCH_DIR=%s\n"
"SES_COOKIE_NAME=%s\n"
"PTM_COOKIE_NAME=%s\n"
"IPPORT=%s\n"
"USER_LOCAL=%d\n"
"IDP_ENA=%d\n"
"IDP_PXY_ENA=%d\n"
"IMPS_ENA=%d\n"
"AS_ENA=%d\n"
"MD_AUTHORITY_ENA=%d\n"
"BACKWARDS_COMPAT_ENA=%d\n"
"PDP_ENA=%d\n"
"CPN_ENA=%d\n"
"AZ_OPT=%d\n"
"AZ_FAIL_MODE=%d\n"
"#ZXID_MAX_BUF=%d (compile)\n"

/* *** should these be prefixed by LOG? */
"LOG_ERR=%d\n"
"LOG_ACT=%d\n"
"LOG_ISSUE_A7N=%d\n"
"LOG_ISSUE_MSG=%d\n"
"LOG_RELY_A7N=%d\n"
"LOG_RELY_MSG=%d\n"
"LOG_ERR_IN_ACT=%d\n"
"LOG_ACT_IN_ERR=%d\n"
"LOG_SIGFAIL_IS_ERR=%d\n"
"LOG_LEVEL=%d\n"
"LOGUSER=%d\n"

"SIG_FATAL=%d\n"
"NOSIG_FATAL=%d\n"
"MSG_SIG_OK=%d\n"
"TIMEOUT_FATAL=%d\n"
"AUDIENCE_FATAL=%d\n"
"DUP_A7N_FATAL=%d\n"
"DUP_MSG_FATAL=%d\n"
"RELTO_FATAL=%d\n"
"WSP_NOSIG_FATAL=%d\n"
"NOTIMESTAMP_FATAL=%d\n"
"REDIR_TO_CONTENT=%d\n"
"REMOTE_USER_ENA=%d\n"
"MAX_SOAP_RETRY=%d\n"

"BEFORE_SLOP=%d\n"
"AFTER_SLOP=%d\n"
"TIMESKEW=%d\n"
"A7NTTL=%d\n"

"ANON_OK=%s\n"
"OPTIONAL_LOGIN_PAT=%s\n"
"ISSUE_AUTHNCTX=%s\n"
"IDP_PREF_ACS_BINDING=%s\n"
"MANDATORY_ATTR=%s\n"
"PDP_URL=%s\n"
"PDP_CALL_URL=%s\n"
"XASP_VERS=%s\n"
"TRUSTPDP_URL=%s\n"
"MOD_SAML_ATTR_PREFIX=%s\n"
"BARE_URL_ENTITYID=%d\n"
"SHOW_TECH=%d\n"
"WD=%s\n"

"XMLDSIG_SIG_METH=%s\n"
"XMLDSIG_DIGEST_ALGO=%s\n"
"SAMLSIG_DIGEST_ALGO=%s\n"
"BLOBSIG_DIGEST_ALGO=%s\n"

"IDP_LIST_METH=%d\n"
"IDP_SEL_PAGE=%s\n"
"IDP_SEL_TEMPL_FILE=%s\n"
"</pre>"
"<textarea cols=100 rows=20>"
"IDP_SEL_TEMPL=%s\n"
#if 0
"IDP_SEL_START=%s\n"
"IDP_SEL_NEW_IDP=%s\n"
"IDP_SEL_OUR_EID=%s\n"
"IDP_SEL_TECH_USER=%s\n"
"IDP_SEL_TECH_SITE=%s\n"
"IDP_SEL_FOOTER=%s\n"
"IDP_SEL_END=%s\n"
#endif
"</textarea><pre>\n"

"AN_PAGE=%s\n"
"AN_TEMPL_FILE=%s\n"
"</pre><textarea cols=100 rows=20>"
"AN_TEMPL=%s\n"
"</textarea><pre>\n"

"POST_TEMPL_FILE=%s\n"
"</pre><textarea cols=100 rows=7>"
"POST_TEMPL=%s\n"
"</textarea><pre>\n"

"ERR_PAGE=%s\n"
"ERR_TEMPL_FILE=%s\n"
"</pre><textarea cols=100 rows=7>"
"ERR_TEMPL=%s\n"
"</textarea><pre>\n"

"NEW_USER_PAGE=%s\n"
"RECOVER_PASSWD=%s\n"
"ATSEL_PAGE=%s\n"

"</pre><textarea cols=100 rows=15>"
"MGMT_START=%s\n"
"MGMT_LOGOUT=%s\n"
"MGMT_DEFED=%s\n"
"MGMT_FOOTER=%s\n"
"MGMT_END=%s\n"
"</textarea>"

"<pre>\n"
"DBG=%s\n"

"REQUIRED_AUTHN_CTX=\n%s\n"
"NEED=\n%s\n"
"WANT=\n%s\n"
"ATTRSRC=\n%s\n"
"BUS_URL=\n%s\n"
"BUS_PW=%s\n"
"RCPT=%d\n"
"INMAP=\n%s\n"
"OUTMAP=\n%s\n"
"PEPMAP=\n%s\n"
"PEPMAP_RQOUT=\n%s\n"
"PEPMAP_RQIN=\n%s\n"
"PEPMAP_RSOUT=\n%s\n"
"PEPMAP_RSIN=\n%s\n"
"LOCALPDP_ROLE_PERMIT=\n%s\n"
"LOCALPDP_ROLE_DENY=\n%s\n"
"LOCALPDP_IDPNID_PERMIT=\n%s\n"
"LOCALPDP_IDPNID_DENY=\n%s\n"
"WSC_LOCALPDP_OBL_PLEDGE=%s\n"
//"WSP_LOCALPDP_OBL_REQ=%s\n"
"WSP_LOCALPDP_OBL_EMIT=%s\n"
//"WSC_LOCALPDP_OBL_ACCEPT=%s\n"
"UNIX_GRP_AZ_MAP=\n%s\n"
"</pre>",
		 cf->burl, eid,
		 cf->cpath,

		 errmac_debug,
		 cf->cpath,
		 cf->burl,
		 STRNULLCHK(cf->affiliation),
		 STRNULLCHK(cf->nice_name),
		 STRNULLCHK(cf->button_url),
		 STRNULLCHK(cf->pref_button_size),
		 STRNULLCHK(cf->org_name),
		 STRNULLCHK(cf->locality),
		 STRNULLCHK(cf->state),
		 STRNULLCHK(cf->country),
		 STRNULLCHK(cf->contact_org),
		 STRNULLCHK(cf->contact_name),
		 STRNULLCHK(cf->contact_email),
		 STRNULLCHK(cf->contact_tel),
		 STRNULLCHK(cf->fedusername_suffix),
		 ZXID_CONF_FILE_ENA,
		 ZXID_CONF_FLAG,
		 STRNULLCHK(cf->non_standard_entityid),
		 STRNULLCHK(cf->redirect_hack_imposed_url),
		 STRNULLCHK(cf->redirect_hack_zxid_url),
		 STRNULLCHK(cf->redirect_hack_zxid_qs),
		 STRNULLCHK(cf->defaultqs),
		 STRNULLCHK(cf->wsp_pat),
		 STRNULLCHK(cf->uma_pat),
		 STRNULLCHK(cf->sso_pat),
		 STRNULLCHK(cf->wsc_soap_content_type),
		 STRNULLCHK(cf->wsc_to_hdr),
		 STRNULLCHK(cf->wsc_replyto_hdr),
		 STRNULLCHK(cf->wsc_action_hdr),
		 STRNULLCHK(cf->soap_action_hdr),
		 STRNULLCHK(cf->cdc_url),
		 cf->cdc_choice,

		 STRNULLCHK(cf->load_cot_cache),
		 cf->md_fetch,
		 cf->md_populate_cache,
		 cf->md_cache_first,
		 cf->md_cache_last,
		 STRNULLCHK(cf->md_authority),

		 cf->auto_cert,
		 cf->authn_req_sign,
		 cf->want_authn_req_signed,
		 cf->want_sso_a7n_signed,
		 cf->sso_soap_sign,
		 cf->sso_soap_resp_sign,
		 cf->sso_sign,
		 cf->wsc_sign,
		 cf->wsp_sign,
		 cf->oaz_jwt_sigenc_alg,
		 cf->wspcgicmd,
		 cf->nameid_enc,
		 cf->post_a7n_enc,
		 cf->canon_inopt,
		 cf->enc_tail_opt,
		 cf->enckey_opt,
		 cf->valid_opt,
		 cf->idpatopt,
		 cf->di_allow_create,
		 cf->di_nid_fmt,
		 cf->di_a7n_enc,
		 cf->bootstrap_level,
		 cf->show_conf,
		 ZXID_ID_BITS,
		 ZXID_ID_MAX_BITS,
		 ZXID_TRUE_RAND,
		 STRNULLCHK(cf->ses_arch_dir),
		 STRNULLCHK(cf->ses_cookie_name),
		 STRNULLCHK(cf->ptm_cookie_name),
		 STRNULLCHK(cf->ipport),
		 cf->user_local,
		 cf->idp_ena,
		 cf->idp_pxy_ena,
		 cf->imps_ena,
		 cf->as_ena,
		 cf->md_authority_ena,
		 cf->backwards_compat_ena,
		 cf->pdp_ena,
		 cf->cpn_ena,
		 cf->az_opt,
		 cf->az_fail_mode,
		 ZXID_MAX_BUF,

		 cf->log_err,
		 cf->log_act,
		 cf->log_issue_a7n,
		 cf->log_issue_msg,
		 cf->log_rely_a7n,
		 cf->log_rely_msg,
		 cf->log_err_in_act,
		 cf->log_act_in_err,
		 cf->log_sigfail_is_err,
		 cf->log_level,
		 cf->loguser,
  
		 cf->sig_fatal,
		 cf->nosig_fatal,
		 cf->msg_sig_ok,
		 cf->timeout_fatal,
		 cf->audience_fatal,
		 cf->dup_a7n_fatal,
		 cf->dup_msg_fatal,
		 cf->relto_fatal,
		 cf->wsp_nosig_fatal,
		 cf->notimestamp_fatal,
		 cf->redir_to_content,
		 cf->remote_user_ena,
		 cf->max_soap_retry,

		 cf->before_slop,
		 cf->after_slop,
		 cf->timeskew,
		 cf->a7nttl,

		 STRNULLCHK(cf->anon_ok),
		 STRNULLCHK(cf->optional_login_pat),
		 issue_authnctx->s,
		 STRNULLCHK(cf->idp_pref_acs_binding),
		 STRNULLCHK(cf->mandatory_attr),
		 STRNULLCHK(cf->pdp_url),
		 STRNULLCHK(cf->pdp_call_url),
		 STRNULLCHK(cf->xasp_vers),
		 STRNULLCHK(cf->trustpdp_url),
		 STRNULLCHK(cf->mod_saml_attr_prefix),
		 cf->bare_url_entityid,
		 cf->show_tech,
		 STRNULLCHK(cf->wd),
		 STRNULLCHK(cf->xmldsig_sig_meth),
		 STRNULLCHK(cf->xmldsig_digest_algo),
		 STRNULLCHK(cf->samlsig_digest_algo),
		 STRNULLCHK(cf->blobsig_digest_algo),

		 cf->idp_list_meth,
		 STRNULLCHK(cf->idp_sel_page),
		 STRNULLCHK(cf->idp_sel_templ_file),
		 STRNULLCHK(cf->idp_sel_templ),
#if 0
		 STRNULLCHK(cf->idp_sel_start),
		 STRNULLCHK(cf->idp_sel_new_idp),
		 STRNULLCHK(cf->idp_sel_our_eid),
		 STRNULLCHK(cf->idp_sel_tech_user),
		 STRNULLCHK(cf->idp_sel_tech_site),
		 STRNULLCHK(cf->idp_sel_footer),
		 STRNULLCHK(cf->idp_sel_end),
#endif
		 STRNULLCHK(cf->an_page),
		 STRNULLCHK(cf->an_templ_file),
		 STRNULLCHK(cf->an_templ),

		 STRNULLCHK(cf->post_templ_file),
		 STRNULLCHK(cf->post_templ),

		 STRNULLCHK(cf->err_page),
		 STRNULLCHK(cf->err_templ_file),
		 STRNULLCHK(cf->err_templ),

		 STRNULLCHK(cf->new_user_page),
		 STRNULLCHK(cf->recover_passwd),
		 STRNULLCHK(cf->atsel_page),

		 STRNULLCHK(cf->mgmt_start),
		 STRNULLCHK(cf->mgmt_logout),
		 STRNULLCHK(cf->mgmt_defed),
		 STRNULLCHK(cf->mgmt_footer),
		 STRNULLCHK(cf->mgmt_end),

		 STRNULLCHK(cf->dbg),

		 required_authnctx->s,
		 need->s,
		 want->s,
		 attrsrc->s,
		 bus_url->s,
		 STRNULLCHK(cf->bus_pw),
		 cf->bus_rcpt,
		 inmap->s,
		 outmap->s,
		 pepmap->s,
		 pepmap_rqout->s,
		 pepmap_rqin->s,
		 pepmap_rsout->s,
		 pepmap_rsin->s,
		 localpdp_role_permit->s,
		 localpdp_role_deny->s,
		 localpdp_idpnid_permit->s,
		 localpdp_idpnid_deny->s,
		 STRNULLCHK(cf->wsc_localpdp_obl_pledge),
		 //STRNULLCHK(cf->wsp_localpdp_obl_req),
		 STRNULLCHK(cf->wsp_localpdp_obl_emit),
		 //STRNULLCHK(cf->wsc_localpdp_obl_accept)
		 unix_grp_az_map->s //,
	 );
}

/* EOF  --  zxidconf.c */
