/* zxiddec.c  -  Handwritten functions for Decoding Redirect or POST bindings
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxiddec.c,v 1.10 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 12.10.2007, tweaked for signing SLO and MNI --Sampo
 * 14.4.2008,  added SimpleSign --Sampo
 * 7.10.2008,  added documentation --Sampo
 * 10.3.2010,  added predecode support --Sampo
 * 18.12.2015, applied patch from soconnor, perceptyx, adding algos --Sampo
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*() Look for issuer in all messages we support. */

/* Called by:  zxid_decode_redir_or_post, zxid_simple_idp_show_an */
struct zx_sa_Issuer_s* zxid_extract_issuer(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_root_s* r)
{
  struct zx_sa_Issuer_s* issuer = 0;
  if      (r->Response)             issuer = r->Response->Issuer;
  else if (r->AuthnRequest)         issuer = r->AuthnRequest->Issuer;
  else if (r->LogoutRequest)        issuer = r->LogoutRequest->Issuer;
  else if (r->LogoutResponse)       issuer = r->LogoutResponse->Issuer;
  else if (r->ManageNameIDRequest)  issuer = r->ManageNameIDRequest->Issuer;
  else if (r->ManageNameIDResponse) issuer = r->ManageNameIDResponse->Issuer;
  else {
    ERR("Unknown message type in redirect, post, or simple sign binding %d", 0);
    cgi->sigval = "I";
    cgi->sigmsg = "Unknown message type (SimpleSign, Redir, or POST).";
    ses->sigres = ZXSIG_NO_SIG;
    return 0;
  }
  if (!issuer) {
    ERR("Missing issuer in redirect, post, or simple sign binding %d", 0);
    cgi->sigval = "I";
    cgi->sigmsg = "Issuer not found (SimpleSign, Redir, or POST).";
    ses->sigres = ZXSIG_NO_SIG;
    return 0;
  }
  return issuer;
}

/*(i) Decode redirect or POST binding message. zxid_saml2_redir_enc()
 * performs the opposite operation. chk_dup is really flags
 * 0x01  =  Check dup
 * 0x02  =  Avoid sig check and logging
 * See:  */

/* Called by:  zxid_idp_dispatch, zxid_simple_idp_show_an, zxid_sp_dispatch */
struct zx_root_s* zxid_decode_redir_or_post(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int chk_dup)
{
  struct zx_sa_Issuer_s* issuer = 0;
  zxid_entity* meta;
  struct zx_str* ss;
  struct zx_str* logpath;
  struct zx_root_s* r = 0;
  struct zx_str id_ss;
  char id_buf[28];
  char sigbuf[1024];  /* 192 is large enough for 1024bit RSA keys, target 4096 bit RSA keys */
  const char* mdalg;
  int simplesig = 0;
  int msglen, len;
  char* p;
  char* m2;
  char* p2;
  char* msg;
  char* b64msg;
  char* field;
  
  if (cgi->saml_resp && *cgi->saml_resp) {
    field = "SAMLResponse";
    b64msg = cgi->saml_resp;
  } else if (cgi->saml_req && *cgi->saml_req) {
    field = "SAMLRequest";
    b64msg = cgi->saml_req;
  } else {
    ERR("No SAMLRequest or SAMLResponse field?! %p", cgi);
    return 0;
  }
  
  msglen = strlen(b64msg);
  msg = ZX_ALLOC(cf->ctx, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(msglen));
  p = unbase64_raw(b64msg, b64msg + msglen, msg, zx_std_index_64);
  *p = 0;
  DD("Msg(%s) x=%x", msg, *msg);

  /* Skip whitespace in the beginning and end of the payload to help correct POST detection. */
  for (m2 = msg; m2 < p; ++m2)
    if (!ONE_OF_4(*m2, ' ', '\t', '\015', '\012'))
      break;
  for (p2 = p-1; m2 < p2; --p2)
    if (!ONE_OF_4(*p2, ' ', '\t', '\015', '\012'))
      break;
  DD("Msg_sans_ws(%.*s) start=%x end=%x", p2-m2+1, m2, *m2, *p2);
  
  if (!(chk_dup & 0x02) && cf->log_level > 1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "W", "REDIRDEC", 0, "sid(%s) len=%d", STRNULLCHK(ses->sid), msglen);

  if (*m2 == '<' && *p2 == '>') {  /* POST profiles do not compress the payload */
    len = p2 - m2 + 1;
    p = m2;
    simplesig = 1;
  } else {
    D("Detected compressed payload. [[m2(%c) %x p2(%c) %x]]", *m2, *m2, *p2, *p2);
    p = zx_zlib_raw_inflate(cf->ctx, p-msg, msg, &len);  /* Redir uses compressed payload. */
    ZX_FREE(cf->ctx, msg);
  }
  
  r = zx_dec_zx_root(cf->ctx, len, p, "decode redir or post");
  if (!r) {
    ERR("Failed to parse redir buf(%.*s)", len, p);
    zxlog(cf, 0, 0, 0, 0, 0, 0, ZX_GET_CONTENT(ses->nameid), "N", "C", "BADXML", 0, "sid(%s) bad redir", STRNULLCHK(ses->sid));
    return 0;
  }

  if (chk_dup & 0x02)
    return r;
  
  issuer = zxid_extract_issuer(cf, cgi, ses, r);
  if (!issuer)
    return 0;

  if (!cgi->sig || !*cgi->sig) {
    D("Redirect or POST was not signed at binding level %d", 0);
log_msg:
    if (cf->log_rely_msg) {
      DD("Logging... %d", 0);
      /* Path will be composed of sha1 hash of the data in p, i.e. the unbase64 data. */
      sha1_safe_base64(id_buf, len, p);
      id_buf[27] = 0;
      id_ss.len = 27;
      id_ss.s = id_buf;
      logpath = zxlog_path(cf, ZX_GET_CONTENT(issuer), &id_ss, ZXLOG_RELY_DIR, ZXLOG_WIR_KIND, 1);
      if (logpath) {
	if (chk_dup & 0x01) {
	  if (zxlog_dup_check(cf, logpath, "Redirect or POST assertion (unsigned)")) {
	    if (cf->dup_msg_fatal) {
	      cgi->err = "C Duplicate message";
	      r = 0;
	    }
	  }
	}
	id_ss.len = len;
	id_ss.s = p;
	zxlog_blob(cf, cf->log_rely_msg, logpath, &id_ss, "dec_redir_post nosig");
      }
    }
    return r;
  }

  meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(issuer));
  if (!meta) {
    ERR("Unable to find metadata for Issuer(%.*s) in Redir or SimpleSign POST binding", ZX_GET_CONTENT_LEN(issuer), ZX_GET_CONTENT_S(issuer));
    cgi->sigval = "I";
    cgi->sigmsg = "Issuer unknown - metadata exchange may be needed (SimpleSign, Redir, POST).";
    ses->sigres = ZXSIG_NO_SIG;
    goto log_msg;
  }

  /* ----- Signed at binding level ----- */
  
  if (simplesig) {
    /* In SimpleSign the signature is over data inside base64. */
    p2 = p = cgi->sigalg;
    URL_DECODE(p, p2, cgi->sigalg + strlen(cgi->sigalg));
    *p = 0;
#if 1
    /* Original SimpleSign specification was ambiguous about handling of missing
     * relay state. Literal reading of the spec seemed to say that empty relay state
     * should be part of the signature computation. This was reported by yours
     * truly to SSTC, which has since issued errata clarifying that if the relay
     * state is empty, then the RelayState label is omitted from signature
     * computation. This is also consistent with how the redirect binding works. */
    if (cgi->rs && *cgi->rs)
      ss = zx_strf(cf->ctx, "%s=%s&RelayState=%s&SigAlg=%s&Signature=%s",
		   field, msg, cgi->rs, STRNULLCHK(cgi->sigalg), STRNULLCHK(cgi->sig));
    else
      ss = zx_strf(cf->ctx, "%s=%s&SigAlg=%s&Signature=%s",
		   field, msg, STRNULLCHK(cgi->sigalg), STRNULLCHK(cgi->sig));
#else
    cgi->rs = "Fake";
    ss = zx_strf(cf->ctx, "%s=%s&RelayState=%s&SigAlg=%s&Signature=%s",
		 field, msg, STRNULLCHK(cgi->rs), STRNULLCHK(cgi->sigalg), STRNULLCHK(cgi->sig));
#endif
  } else {
    /* In Redir binding, the signature is over base64 and url encoded data. This complicates
     * life as we need to know what the URL looked like prior to CGI processing
     * such as URL decoding. As such processing is done by default to all
     * query string fields, this requires special processing. zxid_parse_cgi()
     * has special case code to prevent URL decoding of SAMLRequest and SAMLResponse
     * fields so the b64msg valiable actually has the URL encoding as well. The
     * unbase64_raw() function is smart enough to unravel the URL decoding on
     * the fly, so it all ends up working fine. */
    if (cgi->rs && *cgi->rs)
      ss = zx_strf(cf->ctx, "%s=%s&RelayState=%s&SigAlg=%s&Signature=%s",
		   field, b64msg, cgi->rs /* *** should be URL encoded or preserved? */,
		   STRNULLCHK(cgi->sigalg), STRNULLCHK(cgi->sig));
    else
      ss = zx_strf(cf->ctx, "%s=%s&SigAlg=%s&Signature=%s",
		   field, b64msg, STRNULLCHK(cgi->sigalg), STRNULLCHK(cgi->sig));
  }
  
  DD("Signed data(%.*s) len=%d sig(%s)", ss->len, ss->s, ss->len, cgi->sig);
  p2 = unbase64_raw(cgi->sig, cgi->sig + strlen(cgi->sig), sigbuf, zx_std_index_64);
  ASSERTOPI(p2-sigbuf, <, sizeof(sigbuf));
  
  /* strcmp(cgi->sigalg, SIG_ALGO_RSA_SHA1) would be the right test, but as
   * SigAlg can be arbitrarily URL encoded, we make the match fuzzier. */
  D("cgi->sigalg(%s)", cgi->sigalg);
  if (cgi->sigalg &&
      (   strstr(cgi->sigalg, "rsa-sha1")   || strstr(cgi->sigalg, "rsa-sha512")
       || strstr(cgi->sigalg, "rsa-sha256") || strstr(cgi->sigalg, "dsa-sha1")
       || strstr(cgi->sigalg, "dsa-sha512") || strstr(cgi->sigalg, "dsa-sha256"))) {

    if (strstr(cgi->sigalg, "sha1")) mdalg = "SHA1";
    else if (strstr(cgi->sigalg, "sha256")) mdalg = "SHA256";
    else if (strstr(cgi->sigalg, "sha512")) mdalg = "SHA512";
    else { mdalg="SHA1"; ERR("Unrecognized mdalg(%s)", cgi->sigalg); }
    
    ses->sigres = zxsig_verify_data(ss->len  /* Adjust for Signature= which we log */
				    - (sizeof("&Signature=")-1 + strlen(cgi->sig)),
				    ss->s, p2-sigbuf, sigbuf,
				    meta->sign_cert, "Simple or Redir SigVfy", mdalg);
    zxid_sigres_map(ses->sigres, &cgi->sigval, &cgi->sigmsg);
  } else {
    ERR("Unsupported or bad signature algorithm(%s).", STRNULLCHK(cgi->sigalg));
    cgi->sigval = "I";
    cgi->sigmsg = "Unsupported or bad signature algorithm (in SimpleSign, Redir, or POST).";
    ses->sigres = ZXSIG_NO_SIG;
  }
  
  DD("Signed data(%.*s) len=%d", ss->len, ss->s, ss->len);
  if (cf->log_rely_msg) {
    DD("Logging... %d", 0);
    sha1_safe_base64(id_buf, ss->len, ss->s);
    id_buf[27] = 0;
    id_ss.len = 27;
    id_ss.s = id_buf;
    logpath = zxlog_path(cf, ZX_GET_CONTENT(issuer), &id_ss, ZXLOG_RELY_DIR, ZXLOG_WIR_KIND, 1);
    if (logpath) {
      if (zxlog_dup_check(cf, logpath, "Redirect or POST assertion")) {
	if (cf->dup_msg_fatal) {
	  cgi->err = "C Duplicate message";
	  r = 0;
	}
      }
      zxlog_blob(cf, cf->log_rely_msg, logpath, ss, "dec_redir_post sig");
    }
  }
  zx_str_free(cf->ctx, ss);
  return r;
}

/* EOF  --  zxiddec.c */
