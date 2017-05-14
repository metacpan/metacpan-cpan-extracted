/* zxidlib.c  -  Handwritten functions for implementing common application logic for SP
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidlib.c,v 1.73 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006, created --Sampo
 * 16.1.2007, factored out ses, conf, cgi, ecp, cdc, and loc --Sampo
 * 7.10.2008, added documentation --Sampo
 * 4.9.2009,  added zxid_map_val() --Sampo
 * 18.12.2015, applied patch from soconnor, perceptyx, adding algos --Sampo
 */

#include "platform.h"
#include <string.h>
#include <stdio.h>
#include <sys/stat.h>     /* umask(2) */
//#include <openssl/evp.h>  /* EVP_PKEY */

#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zxidvers.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

int errmac_debug = 0;              /* declared in errmac.h */
FILE* errmac_debug_log = 0;        /* declared in errmac.h, 0 means stderr will be used */
char errmac_indent[256] = "";      /* declared in errmac.h */
char errmac_instance[64] = "\tzx"; /* declared in errmac.h */
int assert_nonfatal = 0;
char* assert_msg = "%s: Internal error caused an ASSERT to fire. Deliberately trying to dump core.\nSorry for the inconvenience. If no core appears, try `ulimit -c unlimited'\n";
int trace = 0;

#ifndef ZXID_LIBNAME
#define ZXID_LIBNAME " libzxid (zxid.org)"
#endif

int zxid_version_var = ZXID_VERSION;
const char* zxid_version_str_var = ZXID_REL " " ZXID_COMPILE_DATE ZXID_LIBNAME;

/*() Obtain the hex encoded version integer describing the libzxid. This can be
 * used to effectuate a runtime version number check. For compile time you
 * should check the value of the ~ZXID_VERSION~ macro. */

/* Called by:  covimp_test, opt x2 */
int zxid_version()
{
  return ZXID_VERSION;
}

/*() Obtain the version string describing the libzxid. This can be
 * used for runtime version display. For compile time you
 * should check the value of the ~ZXID_VERSION~ macro. */

/* Called by:  main x7, opt x2, zxid_fed_mgmt_cf, zxid_idp_select_zxstr_cf_cgi, zxid_map_bangbang, zxid_mgmt */
const char* zxid_version_str()
{
  return zxid_version_str_var;
}

/*(i) Render any element with some options, controlled by
 * config option ENC_TAIL_OPT. Often used to generate slightly optimized
 * version for wire transfer. Not suitable for generating canonicalization.
 * The lists are assumed to be in forward order, i.e. opposite
 * of what zx_dec_zx_root() and zx_DEC_elem() return. You should call
 * zx_reverse_elem_lists() if needed.
 * Wire Order is respected first, and then kids list forward order. */

/* Called by:  main x3, so_enc_dec, zxid_add_env_if_needed x2, zxid_addmd, zxid_anoint_sso_resp, zxid_cache_epr, zxid_call_epr x2, zxid_idp_sso, zxid_lecp_check, zxid_map_val_ss, zxid_mk_enc_a7n, zxid_mk_enc_id, zxid_mk_mni, zxid_mni_do_ss, zxid_pep_az_base_soap_pepmap x3, zxid_pep_az_soap_pepmap x3, zxid_reg_svc, zxid_ses_to_pool x2, zxid_slo_resp_redir, zxid_snarf_eprs_from_ses, zxid_soap_call_raw, zxid_soap_cgi_resp_body, zxid_sp_meta, zxid_sp_mni_redir, zxid_sp_slo_redir, zxid_start_sso_url, zxid_write_ent_to_cache, zxid_wsc_prepare_call, zxid_wsp_decorate */
struct zx_str* zx_easy_enc_elem_opt(zxid_conf* cf, struct zx_elem_s* x)
{
  struct zx_str* ss;
  cf->ctx->enc_tail_opt = cf->enc_tail_opt;
  ss = zx_EASY_ENC_elem(cf->ctx, x);
  cf->ctx->enc_tail_opt = 0;
  return ss;
}

/* Called by:  attribute_sort_test x2, zxid_a7n2str, zxid_anoint_a7n x2, zxid_anoint_sso_resp, zxid_az_soap x2, zxid_epr2str, zxid_get_epr_tas3_trust, zxid_idp_sso, zxid_mk_art_deref, zxid_nid2str, zxid_sp_mni_soap, zxid_sp_slo_soap, zxid_sp_soap_dispatch x5, zxid_sp_sso_finalize, zxid_ssos_anreq, zxid_token2str, zxid_wsf_validate_a7n */
struct zx_str* zx_easy_enc_elem_sig(zxid_conf* cf, struct zx_elem_s* x)
{
  cf->ctx->enc_tail_opt = 0;
  return zx_EASY_ENC_elem(cf->ctx, x);
}

/*() Generate pseudorandom or statistically unique identifier of given length. The
 * unique identifier will be safe base64 encoded.
 *
 * cf::     Configuration object, used for memory allocation.
 * prefix:: A prefix string, usually used to distinguish classes of unique ids.
 * bits::   Number of pseudorandom bits in the unique ID. For best results,
 *     bits should be multiple of 24 (3 bytes expands to 4 safe base64 chars)
 * return:: The identifier as zx_str. Caller should eventually free this memory.
 */
/* Called by:  zxid_check_fed, zxid_mk_oauth_az_req, zxid_mk_subj, zxid_mk_transient_nid, zxid_ps_addent_invite x3, zxid_ps_resolv_id, zxid_put_ses, zxid_pw_authn, zxid_ssos_anreq, zxid_wsc_prep_secmech, zxid_wsf_decor */
struct zx_str* zxid_mk_id(zxid_conf* cf, char* prefix, int bits)
{
  char bit_buf[ZXID_ID_MAX_BITS/8];
  char base64_buf[ZXID_ID_MAX_BITS/6 + 1];
  char* p;
  if (bits > ZXID_ID_MAX_BITS || bits & 0x07) {
    ERR("Requested bits(%d) more than internal limit(%d), or bits not divisible by 8.", bits, ZXID_ID_MAX_BITS);
    return 0;
  }
  zx_rand(bit_buf, bits >> 3);
  p = base64_fancy_raw(bit_buf, bits >> 3, base64_buf, safe_basis_64, 1<<31, 0, 0, '.');
  return zx_strf(cf->ctx, "%s%.*s", prefix?prefix:"", p-base64_buf, base64_buf);
}

/* Called by:  zxid_mk_a7n, zxid_mk_art_deref, zxid_mk_authn_req, zxid_mk_az, zxid_mk_az_cd1, zxid_mk_dap_query_item, zxid_mk_dap_resquery, zxid_mk_dap_subscription, zxid_mk_dap_test_item, zxid_mk_logout, zxid_mk_logout_resp, zxid_mk_mni, zxid_mk_mni_resp, zxid_mk_saml_resp */
struct zx_attr_s* zxid_mk_id_attr(zxid_conf* cf, struct zx_elem_s* father, int tok, char* prefix, int bits)
{
  char bit_buf[ZXID_ID_MAX_BITS/8];
  char base64_buf[ZXID_ID_MAX_BITS/6 + 1];
  char* p;
  if (bits > ZXID_ID_MAX_BITS || bits & 0x07) {
    ERR("Requested bits(%d) more than internal limit(%d), or bits not divisible by 8.", bits, ZXID_ID_MAX_BITS);
    return 0;
  }
  zx_rand(bit_buf, bits >> 3);
  p = base64_fancy_raw(bit_buf, bits >> 3, base64_buf, safe_basis_64, 1<<31, 0, 0, '.');
  return zx_attrf(cf->ctx, father, tok, "%s%.*s", prefix?prefix:"", p-base64_buf, base64_buf);
}

/*() Format a date-time string as usually used in XML, SAML, and Liberty. Apparently
 * there are two ways to format this: with or with-out milliseconds. ZXID accepts
 * either form as input, as they are both legal, but will only generate the
 * without milliseconds form. Some other softwares are buggy and fail to
 * accept the without milliseconds form. You can change the format at compile time
 * by editing zxidlib.c:140.
 *
 * See also: zx_date_time_to_secs()
 */
/* Called by:  timegm_tester, zxid_az_soap, zxid_put_invite x2, zxid_put_psobj x2, zxid_wsc_prep_secmech, zxid_wsf_decor */
struct zx_str* zxid_date_time(zxid_conf* cf, time_t secs)
{
  struct tm t;
  secs += cf->timeskew;
  GMTIME_R(secs, t);
#if 0
  /*                      "2002-10-31T21:42:14.002Z" */
  return zx_strf(cf->ctx, "%04d-%02d-%02dT%02d:%02d:%02d.002Z",
		 t.tm_year+1900, t.tm_mon+1, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec);
#else
  /*                      "2002-10-31T21:42:14Z" */
  return zx_strf(cf->ctx, "%04d-%02d-%02dT%02d:%02d:%02dZ",
		 t.tm_year+1900, t.tm_mon+1, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec);
#endif
}

/* Called by:  zxid_mk_a7n x3, zxid_mk_an_stmt, zxid_mk_art_deref, zxid_mk_authn_req, zxid_mk_az, zxid_mk_az_cd1, zxid_mk_logout, zxid_mk_logout_resp, zxid_mk_mni, zxid_mk_mni_resp, zxid_mk_saml_resp, zxid_ps_addent_invite x2 */
struct zx_attr_s* zxid_date_time_attr(zxid_conf* cf, struct zx_elem_s* father, int tok, time_t secs)
{
  struct tm t;
  secs += cf->timeskew;
  GMTIME_R(secs, t);
#if 0
  /*                                    "2002-10-31T21:42:14.002Z" */
  return zx_attrf(cf->ctx, father, tok, "%04d-%02d-%02dT%02d:%02d:%02d.002Z",
		  t.tm_year+1900, t.tm_mon+1, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec);
#else
  /*                                    "2002-10-31T21:42:14Z" */
  return zx_attrf(cf->ctx, father, tok, "%04d-%02d-%02dT%02d:%02d:%02dZ",
		  t.tm_year+1900, t.tm_mon+1, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec);
#endif
}

/* ============== Redirect Encodings ============= */

#define ETSIGNATURE_EQ "&Signature="

/*(i) Encode (and sign if Simple Sign) a form according to SAML2 POST binding.
 * zxid_decode_redir_or_post() performs the opposite operation.
 *
 * cf::          ZXID configuration object, also used for memory allocation
 * field::       The name of the CGI variable, e.g. "SAMLRequest" or "SAMLResponse"
 * payload::     What should be encoded in the redirect URL. Effectively becomes the query string
 * relay_state:: Optional relay state argument. Ends up being encoded in the query string
 * sign::        Whether binding layer signature is to be applied: 0=no, 1=POST-Simple-Sign
 * action_url::  URL where the form should be posted
 * return::      Query string encoding of the request. The memory should be freed by the caller.
 *     0 on failure.  */

/* Called by:  zxid_idp_sso x3 */
struct zx_str* zxid_saml2_post_enc(zxid_conf* cf, char* field, struct zx_str* payload, char* relay_state, int sign, struct zx_str* action_url)
{
  const char* sig_alg_url;
  const char* sig_alg_urlenc;
  const char* mdalg;
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  struct zx_str id_str;
  struct zx_str* logpath;
  char* sigbuf[SIG_SIZE];
  char* zbuf;
  char* url;
  char* sig;
  char* p;
  int alloc_len, zlen, slen, field_len, rs_len;
  zxid_cgi cgi;

  field_len = strlen(field);
  rs_len = relay_state?strlen(relay_state):0;
  if (rs_len) {
    /* Inplace decode. Decode is needed because the browser will encode again when
     * submitting the form hidden field. */
    p = url = relay_state;
    URL_DECODE(p, url, relay_state + rs_len);
    *p = 0;
    rs_len = p - relay_state;
    while (p = strchr(relay_state,'"')) {
      ERR("RelayState(%s) MUST NOT contain double quote character because it would interfere with HTML form hidden field double quotes. Bad character squashed at position %d.", relay_state, ((int)(p-relay_state)));
      *p = '_';
    }
  }

  /* The url buf is allocated large enough to be used for both signing and/or base64 encoding. */
  alloc_len = MAX((field_len + 1 + payload->len
		   + sizeof("&RelayState=")-1 + rs_len
		   + sizeof("&SigAlg=")-1 + MAX(sizeof(SIG_ALGO),sizeof(SIG_ALGO_RSA_SHA512))-1
		   + sizeof(ETSIGNATURE_EQ)-1 + SIG_SIZE),
		  SIMPLE_BASE64_LEN(payload->len));
  url = p = ZX_ALLOC(cf->ctx, alloc_len + 1);  /* +1 for nul term */

  if (sign) {   /* Additional POST-Simple-Sign signing (sign payload prior to base64 & URL enc) */
    memcpy(p, field, field_len);
    p += field_len;
    *p++ = '=';
    memcpy(p, payload->s, payload->len);
    p += payload->len;

    if (rs_len) {
      memcpy(p, "&RelayState=", sizeof("&RelayState=")-1);
      p += sizeof("&RelayState=")-1;
      memcpy(p, relay_state, rs_len);
      p += rs_len;
    }

    if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "SAML2 post")) {
      mdalg = cf->samlsig_digest_algo;
      if (!mdalg || (mdalg[0]=='0'&&!mdalg[1]))
	mdalg = zxid_get_cert_signature_algo(sign_cert);
      sig_alg_urlenc = zxsig_choose_xmldsig_sig_meth_urlenc(sign_pkey, mdalg);
      memcpy(p, "&SigAlg=", sizeof("&SigAlg=")-1);
      p+=sizeof("&SigAlg=")-1;
      memcpy(p, sig_alg_urlenc, strlen(sig_alg_urlenc));
      p+=strlen(sig_alg_urlenc);
      zlen = zxsig_data(cf->ctx, p-url, url, &zbuf, sign_pkey, "SAML2 post", mdalg);
      if (zlen == -1)
	return 0;
    } else {
      ERR("Simple Signing requested, but private key could not be loaded. Fail. %d", 0);
      return 0;
    }

    memcpy(p, ETSIGNATURE_EQ, sizeof(ETSIGNATURE_EQ)-1);
    p += sizeof(ETSIGNATURE_EQ)-1;
    sig = p;
    p = base64_fancy_raw(zbuf, zlen, p, std_basis_64, 1<<31, 0, 0, '=');
    ASSERTOPI(p-url, <, alloc_len);  /* Check sig did not overrun its fixed size alloc SIG_SIZE */
    slen = p-sig;
    ZX_FREE(cf->ctx, zbuf);
    
    if (cf->log_issue_msg) {
      id_str.len = p-url;
      id_str.s = url;
      logpath = zxlog_path(cf, action_url, &id_str, ZXLOG_ISSUE_DIR, ZXLOG_WIR_KIND, 1);
      if (logpath) {
	if (zxlog_dup_check(cf, logpath, "IdP POST SimpleSign")) {
	  ERR("Duplicate wire msg(%.*s) (Simple Sign)", ((int)(p-url)), url);
	  if (cf->dup_msg_fatal) {
	    ERR("FATAL (by configuration): Duplicate wire msg(%.*s) (Simple Sign)", ((int)(p-url)), url);
	    zxlog_blob(cf, 1, logpath, &id_str, "POST SimpleSign dup");
	    zx_str_free(cf->ctx, logpath);
	    ZX_FREE(cf->ctx, url);
	    return 0;
	  }
	}
	zxlog_blob(cf, 1, logpath, &id_str, "POST SimpleSign");
	zx_str_free(cf->ctx, logpath);
      }
    }
    ASSERTOPI(SIG_SIZE-1, >, slen);
    memcpy(sigbuf, sig, slen);
    sigbuf[slen] = 0;
  } else {
    sigbuf[0] = 0;
  }

  p = base64_fancy_raw(payload->s, payload->len, url, std_basis_64, 1<<31, 0, 0, '=');
  *p = 0;
  ASSERTOPI(p-url, <=, alloc_len); /* Check sig didn't overrun its fixed size alloc SIG_SIZE */  

  /* Template based POST page, see post.html */
  ZERO(&cgi, sizeof(cgi));
  cgi.action_url = zx_str_to_c(cf->ctx, action_url);
  DD("action_url(%s)", cgi.action_url);
  cgi.saml_art   = field;
  cgi.saml_resp  = url;
  if (rs_len) {
    cgi.rs = zx_alloc_sprintf(cf->ctx, 0, "<input type=hidden name=RelayState value=\"%s\">", relay_state);
  }
  if (sign) {
    sig_alg_url = zxsig_choose_xmldsig_sig_meth_url(sign_pkey, mdalg);
    cgi.sig = zx_alloc_sprintf(cf->ctx, 0, "<input type=hidden name=SigAlg value=\"%s\"><input type=hidden name=Signature value=\"%s\">", sig_alg_url, sigbuf);
  }
  payload = zxid_template_page_cf(cf, &cgi, cf->post_templ_file, cf->post_templ, 64*1024, 0);
  ZX_FREE(cf->ctx, url);
  return payload;
}

struct zx_str zxstr_unknown = {0,0,sizeof("UNKNOWN")-1, "UNKNOWN"};

/*(i) Encode and sign a URL according to SAML2 redirect binding.
 * zxid_decode_redir_or_post() performs the opposite operation.
 *
 * 1. Compress payload
 * 2. Base64 encode payload
 * 3. URL encode and concatenate RelayState (if any)
 * 4. Sign the URL encoded form (SimpleSign signs message prior to base64 and URL encodings)
 * 5. Base64 encode the sig and concatenate to the URL
 *
 * cf::          ZXID configuration object, also used for memory allocation
 * field::       The name of the CGI variable, e.g. "SAMLRequest=" or "SAMLResponse="
 * payload::     What should be encoded in the redirect URL. Effectively becomes the query string
 * relay_state:: Optional relay state argument. Ends up being encoded in the query string
 * return::      Query string encoding of the request. The memory should be freed by the caller. */

/* Called by:  zxid_saml2_redir, zxid_saml2_redir_url, zxid_saml2_resp_redir */
struct zx_str* zxid_saml2_redir_enc(zxid_conf* cf, char* field, struct zx_str* pay_load, char* relay_state)
{
  X509* sign_cert;
  EVP_PKEY* sign_pkey;
  struct zx_str* logpath;
  struct zx_str* ss;
  char* zbuf;
  char* b64;
  char* url;
  char* sig;
  char* p;
  const char* sig_alg_urlenc;
  const char* mdalg;
  int zlen, len, slen, field_len, rs_len;
  field_len = strlen(field);
  rs_len = relay_state?strlen(relay_state):0;
  
  /* RFC1951 per SAML2 binding line 576 (p.17), i.e. NOT gzip or ordinary zlib */
  zbuf = zx_zlib_raw_deflate(cf->ctx, pay_load->len, pay_load->s, &zlen);
  if (!zbuf)
    return 0;
  
  len = SIMPLE_BASE64_LEN(zlen);
  b64 = ZX_ALLOC(cf->ctx, len);
  p = base64_fancy_raw(zbuf, zlen, b64, std_basis_64, 1<<31, 0, 0, '=');
  
  len = field_len + zx_url_encode_len(p-b64, b64) - 1 /* zap nul termination */;
  url = ZX_ALLOC(cf->ctx, len + sizeof("&SigAlg=")-1
		 + MAX(sizeof(SIG_ALGO_URLENC),sizeof(SIG_ALGO_RSA_SHA512_URLENC))-1
		 + (rs_len?(sizeof("&RelayState=")-1+rs_len):0) + 1 /* nul term */);
  memcpy(url, field, field_len);

  zx_url_encode_raw(p-b64, b64, url+field_len);
  ZX_FREE(cf->ctx, b64);
  
  if (rs_len) {
    memcpy(url + len, "&RelayState=", sizeof("&RelayState=")-1);
    memcpy(url + len + sizeof("&RelayState=")-1, relay_state, rs_len);
    len += sizeof("&RelayState=")-1+rs_len;
  }
  
  if (!cf->authn_req_sign) {    /* Simple nonsigned case. */
    url[len] = 0;  /* Reservation for ETSIG_ALGO_RSA_SHA1_URLENC provides space for nul term. */
    return zx_ref_len_str(cf->ctx, len, url);
  }
  
  /* Additional URL signing */

#if 0  
  memcpy(url+len, "&SigAlg=" SIG_ALGO_URLENC, sizeof("&SigAlg=" SIG_ALGO_URLENC)-1);
  len += sizeof("&SigAlg=" SIG_ALGO_URLENC)-1;
  if (zxid_lazy_load_sign_cert_and_pkey(cf, 0, &sign_pkey, "SAML2 redir"))
    zlen = zxsig_data(cf->ctx, len, url, &zbuf, sign_pkey, "SAML2 redir", 0);
#else
  if (zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "SAML2 redir")) {
    mdalg = cf->samlsig_digest_algo;
    if (!mdalg || (mdalg[0]=='0'&&!mdalg[1]))
      mdalg = zxid_get_cert_signature_algo(sign_cert);
    sig_alg_urlenc = zxsig_choose_xmldsig_sig_meth_urlenc(sign_pkey, mdalg);
    memcpy(url+len, "&SigAlg=", sizeof("&SigAlg=")-1);
    len+=sizeof("&SigAlg=")-1;
    memcpy(url+len, sig_alg_urlenc, strlen(sig_alg_urlenc));
    len+=strlen(sig_alg_urlenc);
    zlen = zxsig_data(cf->ctx, len, url, &zbuf, sign_pkey, "SAML2 redir", mdalg);
    if (zlen == -1)
      return 0;
  } else {
    ERR("Signature requested, but failed to read private key. %d",0);
    return 0;
  }
#endif
  D("siglen=%d", zlen);
  
  /* Base64 and URL encode the sig. Had SAML2 specified safe base64, world would be simpler! */
  
  b64 = ZX_ALLOC(cf->ctx, SIMPLE_BASE64_LEN(zlen));
  p = base64_fancy_raw(zbuf, zlen, b64, std_basis_64, 1<<31, 0, 0, '=');
  
  slen = zx_url_encode_len(p-b64, b64) - 1;
  sig = ZX_ALLOC(cf->ctx, len + sizeof(ETSIGNATURE_EQ)-1 + slen + 1);
  memcpy(sig, url, len);
  memcpy(sig + len, ETSIGNATURE_EQ, sizeof(ETSIGNATURE_EQ)-1);
  len += sizeof(ETSIGNATURE_EQ)-1;
  zx_url_encode_raw(p-b64, b64, sig + len);
  ZX_FREE(cf->ctx, b64);
  ZX_FREE(cf->ctx, url);
  sig[len + slen] = 0;
  
  ss = zx_ref_len_str(cf->ctx, len + slen, sig);

  if (cf->log_issue_msg) {
    logpath = zxlog_path(cf, &zxstr_unknown, ss, ZXLOG_ISSUE_DIR, ZXLOG_WIR_KIND, 1);
    if (logpath) {
      if (zxlog_dup_check(cf, logpath, "Redir")) {
	ERR("Duplicate wire msg(%.*s) (Redir)", ss->len, ss->s);
	if (cf->dup_msg_fatal) {
	  ERR("FATAL (by configuration): Duplicate wire msg(%.*s) (Redir)", ss->len, ss->s);
	  zxlog_blob(cf, 1, logpath, ss, "Redir dup");
	  zx_str_free(cf->ctx, logpath);
	  ZX_FREE(cf->ctx, ss);
	  return 0;
	}
      }
      zxlog_blob(cf, 1, logpath, ss, "Redir");
      zx_str_free(cf->ctx, logpath);
    }
  }

  return ss;
}

/*() SAMLRequest. Return the URL needed for redirect. You need to pass this to
 * some application layer facility to effectuate the actual redirect.
 * Wrapper for zxid_saml2_redir_enc(). This function is different from
 * zxid_saml2_redir() in that only the URL is returned, not the complete
 * Location header.
 *
 * cf::          ZXID configuration object, also used for memory allocation
 * loc::         The URL up to query string
 * pay_load::    What should be encoded in the redirect URL. Effectively becomes the query string
 * relay_state:: Optional relay state argument. Ends up being encoded in the query string
 * return::      URL suitable for redirection as ~zx_str~. The memory should be freed by the caller. */

/* Called by:  zxid_start_sso_url */
struct zx_str* zxid_saml2_redir_url(zxid_conf* cf, struct zx_str* loc, struct zx_str* pay_load, char* relay_state)
{
  struct zx_str* ss;
  struct zx_str* rse = zxid_saml2_redir_enc(cf, "SAMLRequest=", pay_load, relay_state);
  if (!loc || !rse) {
    ERR("Redirection location URL missing. rse(%.*s) %p", rse?rse->len:0, rse?STRNULLCHK(rse->s):"", rse);
    return 0;
  }
  ss = zx_strf(cf->ctx, (memchr(loc->s, '?', loc->len)
			 ? "%.*s&%.*s" CRLF2
			 : "%.*s?%.*s" CRLF2), loc->len, loc->s, rse->len, rse->s);
  D("%.*s", ss->len, ss->s);
  if (errmac_debug & ERRMAC_INOUT) INFO("%.*s", ss->len, ss->s);
  zx_str_free(cf->ctx, rse);
  return ss;
}

/*() SAMLRequest. Return the HTTP 302 redirect LOCATION header + CRLF2. You need to pass this to
 * some application layer facility to effectuate the actual redirect.
 * Wrapper for zxid_saml2_redir_enc(). This is different from zxid_saml2_redir_url()
 * in that the entire Location header is returned, rather than just the url.
 *
 * cf::          ZXID configuration object, also used for memory allocation
 * loc::         The URL up to query string
 * pay_load::    What should be encoded in the redirect URL. Effectively becomes the query string
 * relay_state:: Optional relay state argument. Ends up being encoded in the query string
 * return::      HTTP Location header as ~zx_str~. The memory should be freed by the caller. */

/* Called by:  zxid_sp_mni_redir, zxid_sp_slo_redir */
struct zx_str* zxid_saml2_redir(zxid_conf* cf, struct zx_str* loc, struct zx_str* pay_load, char* relay_state)
{
  struct zx_str* ss;
  struct zx_str* rse = zxid_saml2_redir_enc(cf, "SAMLRequest=", pay_load, relay_state);
  if (!loc || !rse) {
    ERR("Redirection location URL missing. rse(%.*s) %p", rse?rse->len:0, rse?STRNULLCHK(rse->s):"", rse);
    return zx_dup_str(cf->ctx, "* ERR");
  }
  ss = zx_strf(cf->ctx, (memchr(loc->s, '?', loc->len)
			 ? "Location: %.*s&%.*s" CRLF2
			 : "Location: %.*s?%.*s" CRLF2), loc->len, loc->s, rse->len, rse->s);
  if (errmac_debug & ERRMAC_INOUT) INFO("%.*s", ((int)(ss->len - sizeof(CRLF2) + 1)), ss->s);
  zx_str_free(cf->ctx, rse);
  return ss;
}

/*() SAMLResponse. Return the HTTP 302 redirect LOCATION header + CRLF2. You
 * need to pass this to some application layer facility to effectuate the actual redirect.
 * Wrapper for zxid_saml2_redir_enc().
 *
 * cf::          ZXID configuration object, also used for memory allocation
 * loc::         The URL up to query string
 * pay_load::    What should be encoded in the redirect URL. Effectively becomes the query string
 * relay_state:: Optional relay state argument. Ends up being encoded in the query string
 * return::      HTTP Location header as ~zx_str~. The memory should be freed by the caller. */

/* Called by:  zxid_idp_dispatch, zxid_slo_resp_redir, zxid_sp_dispatch */
struct zx_str* zxid_saml2_resp_redir(zxid_conf* cf, struct zx_str* loc, struct zx_str* pay_load, char* relay_state)
{
  struct zx_str* ss;
  struct zx_str* rse = zxid_saml2_redir_enc(cf, "SAMLResponse=", pay_load, relay_state);
  if (!loc || !rse) {
    ERR("Redirection location(%.*s) URL missing or redirect encoding(%.*s) failed.", loc?loc->len:0, loc?loc->s:"", rse?rse->len:0, rse?rse->s:"");
    return zx_dup_str(cf->ctx, "* ERR");
  }
  ss = zx_strf(cf->ctx, (memchr(loc->s, '?', loc->len)
			 ? "Location: %.*s&%.*s" CRLF2
			 : "Location: %.*s?%.*s" CRLF2), loc->len, loc->s, rse->len, rse->s);
  if (errmac_debug & ERRMAC_INOUT) INFO("%.*s", ((int)(ss->len - sizeof(CRLF2) + 1)), ss->s);
  zx_str_free(cf->ctx, rse);
  return ss;
}

/*() Check status codes in SAML response to verify that request was completed OK.
 *
 * cf::     ZXID configuration object, also used for memory allocation
 * cgi::    CGI variables decoded from the query string. ~err~ field of
 *     the CGI object will be set upon failure.
 * st::     The SAML <Status> element from the response, as XML data structure
 * what::   Explanatory string used in error and log messages
 * return:: 1 of SAML message is OK, 0 if message is not OK. */

/* Called by:  zxid_az_soap, zxid_idp_dispatch x2, zxid_idp_soap_dispatch, zxid_sp_dispatch x3, zxid_sp_mni_soap, zxid_sp_slo_soap, zxid_sp_soap_dispatch x3 */
int zxid_saml_ok(zxid_conf* cf, zxid_cgi* cgi, struct zx_sp_Status_s* st, char* what)
{
  struct zx_str* ss;
  struct zx_str* m = 0;
  struct zx_str* sc1 = 0;
  struct zx_str* sc2 = 0;
  struct zx_sp_StatusCode_s* sc = st->StatusCode;
  if (!memcmp(SAML2_SC_SUCCESS, sc->Value->g.s, sc->Value->g.len)) {
    D("SAML ok what(%s)", what);
    if (cf->log_level>0)
      zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "K", "SAMLOK", what, 0);
    return 1;
  }
  if (st->StatusMessage && (m = ZX_GET_CONTENT(st->StatusMessage)))
    ERR("SAML Fail what(%s) msg(%.*s)", what, m->len, m->s);
  if (sc1 = &sc->Value->g)
    ERR("SAML Fail what(%s) SC1(%.*s)", what, sc1->len, sc1->s);
  if (sc->StatusCode)
    sc2 = &sc->StatusCode->Value->g;
  for (sc = sc->StatusCode; sc; sc = sc->StatusCode)
    ERR("SAML Fail what(%s) subcode(%.*s)", what, sc->Value->g.len, sc->Value->g.s);
    
  ss = zx_strf(cf->ctx, "SAML Fail what(%s) msg(%.*s) SC1(%.*s) subcode(%.*s)", what,
	       m?m->len:0, m?m->s:"",
	       sc1?sc1->len:0, sc1?sc1->s:"",
	       sc2?sc2->len:0, sc2?sc2->s:"");

  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "F", "SAMLFAIL", what, ss->s);
  
  D("SAML Response NOT OK what(%s)", what);
  if (!cgi)
    return 0;
  cgi->err = ss->s;
  return 0;
}

/*() Given NameID or <EncryptedID>, return Name ID. Typically used by SSO and SLO.
 * If unencrypted NameID is available, then decryption will not be attempted.
 * This facilitates code that handles either encrypted or non-encrypted
 * case in one line:
 *
 *   req->NameID = zxid_decrypt_nameid(cf, req->NameID, req->EncryptedID);
 *
 * cf::     ZXID configuration object, also used for memory allocation
 * nid::    XML data structure for Name ID. Possibly 0 (NULL). In that case ~encid~
 *     should be specified.
 * encid::  XML Data Structure for Encrypted Name ID. If no ~nid~ is specified, this
 *     structure is decrypted and its contents returned as the Name ID
 * return:: XML data structure corresponding to (possibly decrypted) Name ID */

/* Called by:  test_ibm_cert_problem, test_ibm_cert_problem_enc_dec, zxid_idp_slo_do, zxid_imreq, zxid_mni_do, zxid_nidmap_do, zxid_sp_slo_do, zxid_sp_sso_finalize, zxid_wsf_validate_a7n */
zxid_nid* zxid_decrypt_nameid(zxid_conf* cf, zxid_nid* nid, struct zx_sa_EncryptedID_s* encid)
{
  struct zx_str* ss;
  struct zx_root_s* r;
  if (nid)
    return nid;
  if (encid) {
    ss = zxenc_privkey_dec(cf, encid->EncryptedData, encid->EncryptedKey);
    if (!ss) {
      ERR("Failed to decrypt NameID. Most probably certificate-private key mismatch or metadata problem. Could also be corrupt message. %d", 0);
      return 0;
    }
    r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "dec nid");
    if (!r) {
      ERR("Failed to parse EncryptedID buf(%.*s)", ss->len, ss->s);
      return 0;
    }
    return r->NameID;
  }
  ERR("Neither NameID nor EncryptedID available %d", 0);
  return 0;
}

/*() Given new nym or <NewEncryptedID>, return Name ID. Typically used by Name ID Management
 *
 * cf::     ZXID configuration object, also used for memory allocation
 * newnym:: XML data structure for new Name ID. Possibly 0 (NULL). In that case ~encid~
 *     should be specified.
 * encid::  XML Data Structure for Encrypted Name ID. If no ~newnym~ is specified, this
 *     structure is decrypted and its contents returned as the Name ID
 * return:: XML data structure corresponding to (possibly decrypted) new Name ID */

/* Called by:  zxid_mni_do */
struct zx_str* zxid_decrypt_newnym(zxid_conf* cf, struct zx_str* newnym, struct zx_sp_NewEncryptedID_s* encid)
{
  struct zx_str* ss;
  struct zx_root_s* r;
  if (newnym)
    return newnym;
  if (encid) {
    ss = zxenc_privkey_dec(cf, encid->EncryptedData, encid->EncryptedKey);
    if (!ss) {
      ERR("Failed to decrypt NewEncryptedID. Most probably certificate-private key mismatch or metadata problem. Could also be corrupt message. %d", 0);
      return 0;
    }
    r = zx_dec_zx_root(cf->ctx, ss->len, ss->s, "dec newnym");
    if (!r) {
      ERR("Failed to parse NewEncryptedID buf(%.*s)", ss->len, ss->s);
      return 0;
    }
    return ZX_GET_CONTENT(r->NewID);
  }
  ERR("Neither NewNameID nor NewEncryptedID available %d", 0);
  return 0;
}

/*(i) Check single item signature on given Request, Response, or Assertion. Typical usage
 *
 *     if (!zxid_chk_sig(cf, cgi, ses, (struct zx_elem_s*)req,
 *                       req->Signature, req->Issuer, "LogoutRequest"))
 *       return 0;
 *
 * cf:: ZXID configuration and context object, used for settings and memory allocation
 * cgi:: cgi or invocation variables object. cgi->sigval and cgi->sigmsg
 *     will be altered, if there is any signature.
 * ses:: Session object. The ses->sigres will be altered to reflect result
 *     of verification, if there is signature.
 * elem:: Element that was signed, usually needs type cast.
 * sig:: Signature element within elem
 * issue_ent:: The EntityID zx_str of the signer (Issuer)
 * pop_seen:: Namespaces collected from outer layers
 * lk:: Log key
 * return:: 0 if sig check could not be made due to error, 1 if there was
 *     no signature to check, 2 if check was made, in which case the result is
 *     in ses->sigres, 3 if check was not possible (due to error), but sig was not
 *     configured to be required (NOSIG_FATAL option).
 *
 * See also: Signature validation codes VVV in zxid-log.pd, section "ZXID Log Format".
 * N.B: If the signature is over multiple references, you need to do many processing steps
 * manually and then call zxsig_validate() with correctly populate refs array.
 */

/* Called by:  sig_validate, zxid_idp_slo_do, zxid_mni_do, zxid_sp_dig_oauth_sso_a7n, zxid_sp_dig_sso_a7n, zxid_sp_slo_do, zxid_xacml_az_cd1_do, zxid_xacml_az_do */
int zxid_chk_sig(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_elem_s* elem, struct zx_ds_Signature_s* sig, struct zx_sa_Issuer_s* issue_ent, struct zx_ns_s* pop_seen, const char* lk)
{
  struct zx_str* issuer = 0;
  struct zxsig_ref refs;
  zxid_entity* idp_meta;
  char* err = "S"; /* See: RES in zxid-log.pd, section "ZXID Log Format" */
  
  if (!sig) { D("No signature in %s", lk); return 1; /* Not an error */ }
  if (!sig->SignedInfo || !sig->SignedInfo->Reference) {
    ERR("Malformed signature in %s, missing mandatory SignedInfo(%p) or Reference", lk, sig->SignedInfo);
    cgi->sigval = "M";
    cgi->sigmsg = "Malformed signature.";
    ses->sigres = ZXSIG_NO_SIG;
    err = "C";
    goto erro;
  }

  if (!issue_ent || !(issuer = ZX_GET_CONTENT(issue_ent)) || !issuer->len || !issuer->s[0]) {
    ERR("Issuer of %s is empty although %s was signed. %p", lk, lk, issuer);
    cgi->sigval = "I";
    cgi->sigmsg = "Issuer of signed Response missing.";
    ses->sigres = ZXSIG_NO_SIG;
    if (!cf->nosig_fatal)
      goto nosig_allow;
    err = "C";
    goto erro;
  }
  
  idp_meta = zxid_get_ent_ss(cf, issuer);
  if (!idp_meta) {
    ERR("Unable to find metadata for Issuer(%.*s).", issuer->len, issuer->s);
    cgi->sigval = "I";
    cgi->sigmsg = "Issuer of signed Response unknown.";
    ses->sigres = ZXSIG_NO_SIG;
    if (!cf->nosig_fatal)
      goto nosig_allow;
    err = "P";  /* Policy issue */
    goto erro;
  }

  ZERO(&refs, sizeof(refs));
  refs.sref = sig->SignedInfo->Reference;
  refs.blob = elem;
  refs.pop_seen = pop_seen;
  zx_see_elem_ns(cf->ctx, &refs.pop_seen, elem);
  ses->sigres = zxsig_validate(cf->ctx, idp_meta->sign_cert, sig, 1, &refs);
  zxid_sigres_map(ses->sigres, &cgi->sigval, &cgi->sigmsg);
  D("Response sigres(%d) 0=ZXSIG_OK", ses->sigres);
  return 2;

nosig_allow:
  return 3;

erro:
  cgi->msg = "SSO failed due to Response that was signed, but badly (or did not have Issuer).";
  zxlog(cf, 0, 0, 0, issuer, 0, 0, 0,
	cgi->sigval, err, ses->nidfmt?"FEDSSO":"TMPSSO", ses->sesix?ses->sesix:"-", "Error.");
  return 0;
}

/*() Figure out sp_name_buf corresponding to affiliation */

/* Called by:  zxid_add_fed_tok2epr, zxid_map_val_ss x3 */
struct zx_str* zxid_get_affil_and_sp_name_buf(zxid_conf* cf, zxid_entity* meta, char* sp_name_buf)
{
  struct zx_str* affil;
  if (meta && meta->ed && meta->ed->AffiliationDescriptor
      && (affil = &meta->ed->AffiliationDescriptor->affiliationOwnerID->g)
      && affil->s && affil->len)
    ; /* affil is good */
  else
    affil = meta && meta->ed ? &meta->ed->entityID->g : 0;
  if (!affil) {
    ERR("Unable to determine affiliation ID or provider ID. Metadata missing? %p %p", meta, meta?meta->ed:0);
    *sp_name_buf = 0;
    return 0;
  }
  zxid_nice_sha1(cf, sp_name_buf, ZXID_MAX_SP_NAME_BUF, affil, affil, 7);
  return affil;
}

/*() Determine federation specific nameid */

/* Called by:  zxid_add_fed_tok2epr, zxid_map_val_ss x2, zxid_sso_issue_a7n, zxid_sso_issue_jwt */
zxid_nid* zxid_get_fed_nameid(zxid_conf* cf, struct zx_str* prvid, struct zx_str* affil, const char* uid, const char* sp_name_buf, int allow_create, int want_transient, struct timeval* srcts, struct zx_str* id, char* logop)
{
  zxid_nid* nameid = zxid_check_fed(cf, affil, uid, allow_create, srcts, prvid, id, sp_name_buf);
  if (nameid) {
    if (want_transient) {
      D("Despite old fed, using transient due to want_transient=%d", want_transient);
      zxid_mk_transient_nid(cf, nameid, sp_name_buf, uid);
      if (logop) strcpy(logop, "TMPDI");
    } else
      if (logop) strcpy(logop, "FEDDI");
  } else {
    D("No nameid (because of no federation), using transient %d", 0);
    nameid = zx_NEW_sa_NameID(cf->ctx,0);
    zxid_mk_transient_nid(cf, nameid, sp_name_buf, uid);
    if (logop) strcpy(logop, "TMPDI");
  }
  return nameid;
}

/*() Transform content according to map. The returned zx_str will be nul terminated.
 * The list ends up being built in reverse order, which at runtime
 * causes last stanzas to be evaluated first and first match is used.
 * Thus you should place most specific rules last and most generic rules first.
 * See also: zxid_load_map() and zxid_find_map() */

/* Called by:  zxid_add_at_vals, zxid_map_val */
struct zx_str* zxid_map_val_ss(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, struct zxid_map* map, const char* atname, struct zx_str* val)
{
  zxid_a7n* a7n;
  zxid_nid* nameid;
  struct zx_sa_AttributeStatement_s* at_stmt;
  struct zx_str* prvid;
  struct zx_str* affil;
  struct zx_str* ss;
  char buf[MIN(ZXID_MAX_SP_NAME_BUF,4096)];
  char* bin;
  char* p;
  int len;
  if (!val) {
    ERR("NULL ponter as val %p", map);
    val = zx_dup_str(cf->ctx, "");
  }
  if (!map)
    return val;

  switch (map->rule & ZXID_MAP_RULE_WRAP_MASK) {
  case 0: break; /* No wrap */
  case ZXID_MAP_RULE_WRAP_A7N:   /* 0x10 Wrap the attribute in SAML2 assertion */
    if (!meta || !ses || !ses->uid) {
      ERR("MAP_RULE_WRAP_A7N requires SP metadata and session to be specified. %p %p", meta, ses);
      break;
    }
    affil = zxid_get_affil_and_sp_name_buf(cf, meta, buf);
    prvid = meta->ed ? &meta->ed->entityID->g : 0;
    nameid = zxid_get_fed_nameid(cf, prvid, affil, ses->uid, buf, cf->di_allow_create,
				 (cf->di_nid_fmt == 't'), 0, 0, 0);

    at_stmt = zx_NEW_sa_AttributeStatement(cf->ctx, 0);
    if (map->dst && *map->dst && map->src && map->src[0] != '*')
      atname = map->dst;
    at_stmt->Attribute = zxid_mk_sa_attribute_ss(cf, &at_stmt->gg, atname, 0, val);

    a7n = zxid_mk_a7n(cf, prvid, zxid_mk_subj(cf, 0, meta, nameid), 0, at_stmt);
    zxid_anoint_a7n(cf, 1, a7n, prvid, "map_val", ses->uid, 0);
    val = zx_easy_enc_elem_opt(cf, &a7n->gg);
    break;
  case ZXID_MAP_RULE_WRAP_X509:  /* 0x20 Wrap the attribute in X509 attribute certificate */
    if (!meta || !ses || !ses->uid) {
      ERR("MAP_RULE_WRAP_X509 requires SP metadata and session to be specified. %p %p", meta, ses);
      break;
    }
    affil = zxid_get_affil_and_sp_name_buf(cf, meta, buf);
    prvid = meta->ed ? &meta->ed->entityID->g : 0;
    nameid = zxid_get_fed_nameid(cf, prvid, affil, ses->uid, buf, cf->di_allow_create,
				 (cf->di_nid_fmt == 't'), 0, 0, 0);

    if (map->dst && *map->dst && map->src && map->src[0] != '*')
      atname = map->dst;
    zxid_mk_at_cert(cf, sizeof(buf), buf, "map_val", nameid, atname, val);
    val = zx_dup_str(cf->ctx, buf);
    break;
  case ZXID_MAP_RULE_WRAP_FILE:  /* 0x30 Get attribute value from file specified in ext */
    if (!meta || !ses || !ses->uid) {
      ERR("MAP_RULE_WRAP_FILE requires SP metadata and session to be specified. %p %p", meta, ses);
      break;
    }
    zxid_get_affil_and_sp_name_buf(cf, meta, buf);
    if (!map->ext || !*map->ext) {
      ERR("WRAP_FILE rule without file name in ext field of stanza %p", map->ext);
      break;
    } else if (!strcmp(map->ext, "_VAL_FROM_FILE")) {
      D("_VAL_FROM_FILE specified, taking filename from attribute value(%.*s)", val->len, val->s);
      p = zx_str_to_c(cf->ctx, val);
    } else {
      p = map->ext;
    }
    bin = read_all_alloc(cf->ctx, "map_val from file", 0, &len,
			 "%s" ZXID_UID_DIR "%s/%s/%s", cf->cpath, ses->uid, buf, p);
    if (!bin)
      bin = read_all_alloc(cf->ctx, "map_val from file", 0, &len,
			   "%s" ZXID_UID_DIR "%s/.bs/%s", cf->cpath, ses->uid, p);
    if (!bin)
      bin = read_all_alloc(cf->ctx, "map_val from file", 0, &len,
			   "%s" ZXID_UID_DIR ".all/%s/%s", cf->cpath, buf, p);
    if (!bin)
      bin = read_all_alloc(cf->ctx, "map_val from file", 0, &len,
			   "%s" ZXID_UID_DIR ".all/.bs/%s", cf->cpath, p);
    if (bin) {
      val = zx_ref_len_str(cf->ctx, len, bin);
      D("FILE RULE uid(%s) sp_name_buf(%s) file(%s) GOT(%.*s)",ses->uid,buf,p,val->len,val->s);
    } else {
      INFO("Attribute(%s) value not found in any file(%s" ZXID_UID_DIR "%s/%s/%s)", STRNULLCHKQ(atname), cf->cpath, ses->uid, buf, p);
      val = zx_ref_str(cf->ctx, "");
    }
    break;
  default:
    NEVER("unknow map_val rule=%x", map->rule);
  }

  switch (map->rule & ZXID_MAP_RULE_ENC_MASK) {
  case ZXID_MAP_RULE_RENAME:     ss = val; break;
  case ZXID_MAP_RULE_FEIDEDEC:   /* Norway */
    /*  "feide": FEIDE currently (2008) stores several values in a single
     *           AttributeValue element. The values are base64 encoded
     *           and separated by an underscore. This decoder reverses that encoding. */
    DD("*** FEIDEDEC only base64 decodes one attribute: it does not handle the concatenatenation with _ of several attributes. val_before(%.*s)", val->len, val->s);
    ss = zx_new_len_str(cf->ctx, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(val->len));
    p = unbase64_raw(val->s, val->s + val->len, ss->s, zx_std_index_64);
    *p = 0;
    ss->len = p - ss->s;
    break;
  case ZXID_MAP_RULE_FEIDEENC:   /* Norway */
    DD("*** FEIDEENC only base64 encodes one attribute: it does not concatenate with _ several attributes. %d", 0);
    ss = zx_new_len_str(cf->ctx, SIMPLE_BASE64_LEN(val->len));
    base64_fancy_raw(val->s, val->len, ss->s, std_basis_64, 1<<31, 0, 0, '=');
    break;
  case ZXID_MAP_RULE_UNSB64_INF: /* Decode safebase64-inflate ([RFC3548], [RFC1951]) */
    ss = ZX_ZALLOC(cf->ctx, struct zx_str);
    if (!val->len || !(ss->s = zxid_unbase64_inflate(cf->ctx, val->len, val->s, &ss->len))) {
      ss->len = 0;
      ss->s = "";
      return ss;    /* should return 0, but caller may be assuming this can not fail */
    }
    ss->s[ss->len] = 0;
    break;
  case ZXID_MAP_RULE_DEF_SB64:   /* Encode gzip-safebase64 ([RFC1951], [RFC3548]) */
    if (!val->len || !(bin = zx_zlib_raw_deflate(cf->ctx, val->len, val->s, &len))) {
      return zx_dup_str(cf->ctx, "");
    }
    ss = zx_new_len_str(cf->ctx, SIMPLE_BASE64_LEN(len));
    base64_fancy_raw(bin, len, ss->s, safe_basis_64, 1<<31, 0, 0, '=');
    ZX_FREE(cf->ctx, bin);
    break;
  case ZXID_MAP_RULE_UNSB64:     /* NZ: Decode safebase64 ([RFC3548]) */
    ss = zx_new_len_str(cf->ctx, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(val->len));
    p = unbase64_raw(val->s, val->s + val->len, ss->s, zx_std_index_64);
    *p = 0;
    ss->len = p - ss->s;
    break;
  case ZXID_MAP_RULE_SB64:       /* NZ: Encode safebase64 ([RFC3548]) */
    ss = zx_new_len_str(cf->ctx, SIMPLE_BASE64_LEN(val->len));
    base64_fancy_raw(val->s, val->len, ss->s, safe_basis_64, 1<<31, 0, 0, '=');
    break;
  default:
    NEVER("unknow map_val rule=%x", map->rule);
  }
  return ss;
}

/* Called by:  pool2apache x2, zxid_add_mapped_attr, zxid_pepmap_extract x2, zxid_pool2env x3, zxid_pool_to_json x2, zxid_pool_to_ldif x2, zxid_pool_to_qs x2 */
struct zx_str* zxid_map_val(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, struct zxid_map* map, const char* atname, const char* val) {
  return zxid_map_val_ss(cf, ses, meta, map, atname, zx_dup_str(cf->ctx, STRNULLCHK(val)));
}

/*() Extract the payload part in the SOAP Body from a string representing SOAP Envelope.
 * This does not really parse the XML. It uses simple, but robust, string matching
 * based heuristic that can tolerate some garbage input. */

/* Called by:  zxcall_main */
char* zxid_extract_body(zxid_conf* cf, char* enve)
{
  char* p;
  char* q;

  if (!enve)
    goto nobody;
  for (p = enve; p; p+=4) {
    p = strstr(p, "Body");
    if (!p) {
nobody:
      ERR("Response does not contain <Body> res(%s)", STRNULLCHKD(enve));
      return 0;
    }
    if (p > enve && ONE_OF_2(p[-1], '<', ':') && ONE_OF_5(p[4], '>', ' ', '\t', '\r', '\n'))
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

  enve = ZX_ALLOC(cf->ctx, q-p+1);
  memcpy(enve, p, q-p);
  enve[q-p] = 0;
  return enve;
}

/*() Get symmetric key, generating it if necessary. The symkey buffer must
 * already have been allocated and MUST hold 20 characters. It will not be
 * nul terminated and in fact will contain binary data (sha1 hash output). */

/* Called by:  zxid_mk_jwt, zxid_psobj_key_setup, zxlog_write_line */
char* zx_get_symkey(zxid_conf* cf, const char* keyname, char* symkey)
{
  char buf[1024];
  int um, gotall = read_all(sizeof(buf), buf, "symkey", 1, "%s" ZXID_PEM_DIR "%s", cf->cpath, keyname);
  if (!gotall && cf->auto_cert) {
    INFO("AUTO_CERT: generating symmetric encryption key in %s" ZXID_PEM_DIR "%s", cf->cpath, keyname);
    gotall = 128 >> 3; /* 128 bits as bytes */
    zx_rand(buf, gotall);
    um = umask(0077);  /* Key material should be readable only by owner */
    INFO("gotall=%d", gotall);
    hexdmp("symkey ", buf, gotall, 16);
    write_all_path("auto_cert", "%s" ZXID_PEM_DIR "%s", cf->cpath, keyname, gotall, buf);
    umask(um);
  }
  SHA1((unsigned char*)buf, gotall, (unsigned char*)symkey);
  return symkey;
}

/* EOF  --  zxidlib.c */
