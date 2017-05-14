/* zxdecode.c  -  SAML Decoding tool
 * Copyright (c) 2012 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2008-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxdecode.c,v 1.8 2009-11-29 12:23:06 sampo Exp $
 *
 * 25.11.2008, created --Sampo
 * 4.10.2010, added -s and ss modes, as well as -i N selector --Sampo
 * 25.1.2011, added -wsc and -wsp validation options --Sampo
 * 7.2.2012,  improved decoding encrypted SAML responses --Sampo
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "platform.h"
#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zxidvers.h"
#include "c/zx-ns.h"
#include "c/zx-const.h"
#include "c/zx-data.h"

char* help =
"zxdecode  -  Decode SAML Redirect and POST Messages R" ZXID_REL "\n\
Copyright (c) 2012 Synergetics SA (sampo@synergetics.be), All Rights Reserved.\n\
Copyright (c) 2008-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxdecode [options] <message >decoded\n\
  -b -B            Prevent or force decode base64 step (default auto detects)\n\
  -z -Z            Prevent or force inflate step (default auto detects)\n\
  -i N             Pick Nth detected decodable structure, default: 1=first\n\
  -s               Enable signature validation step (reads config from -c, see below)\n\
  -s -s            Only validate hashes (check canon), do not fetch meta or check RSA\n\
  -r               Decode and validate already decoded SAML2 reponse, e.g. from audit trail\n\
  -c CONF          For -s, optional configuration string (default -c CPATH=/var/zxid/)\n\
                   Most of the configuration is read from " ZXID_CONF_PATH "\n\
  -wscp            Call zxid_wsc_prepare_call() on SOAP request\n\
  -wspv            Call zxid_wsp_validate() on SOAP request\n\
  -wspd            Call zxid_wsp_decorate() on SOAP response\n\
  -wscv            Call zxid_wsc_valid_resp() on SOAP response\n\
  -sha1            Compute sha1 over input and print as base64. For debugging canon.\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -h               This help message\n\
  --               End of options\n\
\n\
Will attempt to detect many layers of encoding. Will hunt for the\n\
relevant input such as SAMLRequest or SAMLResponse in, e.g., log file.\n";

int b64_flag = 2;      /* Auto */
int inflate_flag = 2;  /* Auto */
int verbose = 1;
int ix = 1;
int sig_flag = 0;  /* No sig checking by default. */
int sha1_flag = 0;
int resp_flag = 0;
char valid_opt = 0;
zxid_conf* cf = 0;
char buf[256*1024];

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
static void opt(int* argc, char*** argv, char*** env)
{
  if (*argc <= 1) return;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* normal exit from options loop */
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'c':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	if (!cf)
	  cf = zxid_new_conf_to_cf(0);
	zxid_parse_conf(cf, (*argv)[0]);
	continue;
      }
      break;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	continue;
      }
      break;

    case 'i':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	sscanf((*argv)[0], "%i", &ix);
	continue;
      }
      break;

    case 's':
      switch ((*argv)[0][2]) {
      case '\0':
	++sig_flag;
	if (!cf)
	  cf = zxid_new_conf_to_cf(0);
	continue;
      case 'h':
	++sha1_flag;
	continue;
      }
      break;

    case 'r':
      switch ((*argv)[0][2]) {
      case '\0':
	++resp_flag;
	continue;
      }
      break;

    case 'b':
      switch ((*argv)[0][2]) {
      case '\0':
	b64_flag = 0;
	continue;
      }
      break;
    case 'B':
      switch ((*argv)[0][2]) {
      case '\0':
	b64_flag = 1;
	continue;
      }
      break;

    case 'z':
      switch ((*argv)[0][2]) {
      case '\0':
	inflate_flag = 0;
	continue;
      }
      break;
    case 'Z':
      switch ((*argv)[0][2]) {
      case '\0':
	inflate_flag = 1;
	continue;
      }
      break;

    case 'w':
      switch ((*argv)[0][2]) {
      case 's':
	switch ((*argv)[0][3]) {
	case 'c':
	  switch ((*argv)[0][4]) {
	  case 'p':
	    valid_opt = 'P';
	    continue;
	  case 'v':
	    valid_opt = 'V';
	    continue;
	  }
	  break;
	case 'p':
	  switch ((*argv)[0][4]) {
	  case 'v':
	    valid_opt = 'v';
	    continue;
	  case 'd':
	    valid_opt = 'd';
	    continue;
	  }
	  break;
	}
	break;
      }
      break;

#if 0
    case 'l':
      switch ((*argv)[0][2]) {
      case 'i':
	if (!strcmp((*argv)[0],"-license")) {
	  extern char* license;
	  fprintf(stderr, license);
	  exit(0);
	}
	break;
      }
      break;
#endif

    case 'q':
      switch ((*argv)[0][2]) {
      case '\0':
	verbose = 0;
	continue;
      }
      break;

    case 'v':
      switch ((*argv)[0][2]) {
      case '\0':
	++verbose;
	continue;
      }
      break;

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
    if (verbose>1) {
      printf("%s", help);
      exit(0);
    }
    fprintf(stderr, "%s", help);
    /*fprintf(stderr, "version=0x%06x rel(%s)\n", zxid_version(), zxid_version_str());*/
    exit(3);
  }
}

/* Called by:  zxdecode_main */
static int ws_validations()
{
  int ret;
  char* nid;
  struct zx_str* ss;
  zxid_ses sess;
  ZERO(&sess, sizeof(sess));
  if (!cf)
    cf = zxid_new_conf_to_cf(0);

  switch (valid_opt) {
  case 'P':
    ss = zxid_wsc_prepare_call(cf, &sess, 0 /*epr*/, "", buf);
    if (!ss)
      return 1;
    if (verbose)
      printf("WSC_PREPARE_CALL(%.*s)\n", ss->len, ss->s);
    return 0;
  case 'v':
    nid = zxid_wsp_validate(cf, &sess, "", buf);
    if (!nid)
      return 1;
    if (verbose)
      printf("WSP_VALIDATE OK nid(%s)\n", nid);
    return 0;
  case 'd':
    ss = zxid_wsp_decorate(cf, &sess, "", buf);
    if (!ss)
      return 1;
    if (verbose)
      printf("WSP_DECORATE(%.*s)\n", ss->len, ss->s);
    return 0;
  case 'V':
    ret = zxid_wsc_valid_resp(cf, &sess, "", buf);
    if (verbose)
      printf("WSC_VALID_RESP(%d)\n", ret);
    if (ret == 1)
      return 0; /* Success */
    return 1;
  }
  return 2;
}

/* Called by:  sig_validate */
static int wsse_sec_validate(struct zx_e_Envelope_s* env)
{
  int ret;
  int n_refs = 0;
  struct zxsig_ref refs[ZXID_N_WSF_SIGNED_HEADERS];
  struct zx_wsse_Security_s* sec = env->Header->Security;

  if (!sec || !sec->Signature) {
    ERR("Missing signature on <wsse:Security> %p", sec);
    return 8;
  }
  if (!sec->Signature->SignedInfo || !sec->Signature->SignedInfo->Reference) {
    ERR("Malformed signature, missing mandatory SignedInfo(%p) or Reference", sec->Signature->SignedInfo);
    return 9;
  }
  
  ZERO(refs, sizeof(refs));
  n_refs = zxid_hunt_sig_parts(cf, n_refs, refs, sec->Signature->SignedInfo->Reference, env->Header, env->Body);
  /*zx_see_elem_ns(cf->ctx, &refs.pop_seen, &resp->gg); *** */
  ret = zxsig_validate(cf->ctx, 0, sec->Signature, n_refs, refs);
  if (ret == ZXSIG_BAD_CERT) {
    INFO("Canon sha1 of <wsse:Security> verified OK %d", ret);
    if (verbose)
      printf("\nCanon sha1 if <wsse:Security> verified OK %d\n", ret);
  } else {
    ERR("Response Signature hash validation error. Bad canonicalization? ret=%d",ret);
    return 10;
  }

  if (ret && verbose)
    printf("\nSIG Verified OK, zxid_sp_sso_finalize() returned %d\n", ret);
  return ret?0:6;
}

/*() Process SAML2 response */

/* Called by:  decode, zxdecode_main */
static int sig_validate(int len, char* p)
{
  int ret;
  zxid_cgi cgi;
  zxid_ses ses;
  struct zx_root_s* r;
  struct zx_sp_Response_s* resp;
  struct zx_ns_s* pop_seen = 0;
  struct zxsig_ref refs;
  zxid_a7n* a7n;
  
  ZERO(&cgi, sizeof(cgi));
  ZERO(&ses, sizeof(ses));

  r = zx_dec_zx_root(cf->ctx, len, p, "decode");
  if (!r) {
    ERR("Failed to parse buf(%.*s)", len, p);
    return 2;
  }

  if (r->Response)
    resp = r->Response;  /* Normal SAML2 Response, e.g. from POST */
  else if (r->Envelope && r->Envelope->Body) {
    if (r->Envelope->Body->Response)
      resp = r->Envelope->Body->Response;
    else if (r->Envelope->Body->ArtifactResponse && r->Envelope->Body->ArtifactResponse->Response)
      resp = r->Envelope->Body->ArtifactResponse->Response;
    else if (r->Envelope->Header && r->Envelope->Header->Security)
      return wsse_sec_validate(r->Envelope);
    else {
      ERR("<e:Envelope> found, but no <sp:Response> element in it %d",0);
      return 3;
    }
  } else {
    a7n = zxid_dec_a7n(cf, r->Assertion, r->EncryptedAssertion);
    if (a7n) {
      INFO("Bare Assertion without Response wrapper detected %p", r->Assertion);
      goto got_a7n;
    }
    ERR("No <sp:Response>, <sa:Assertion>, or <sa:EncryptedAssertion> found buf(%.*s)", len, p);
    return 3;
  }

  /* See zxid_sp_dig_sso_a7n() for similar code. */
  
  if (sig_flag == 2) {
    if (!resp->Signature) {
      INFO("No signature in Response %d", 0);
    } else {
      if (!resp->Signature->SignedInfo || !resp->Signature->SignedInfo->Reference) {
	ERR("Malformed signature, missing mandatory SignedInfo(%p) or Reference", resp->Signature->SignedInfo);
	return 9;
      }

      ZERO(&refs, sizeof(refs));
      refs.sref = resp->Signature->SignedInfo->Reference;
      refs.blob = &resp->gg;
      refs.pop_seen = pop_seen;
      zx_see_elem_ns(cf->ctx, &refs.pop_seen, &resp->gg);
      ret = zxsig_validate(cf->ctx, 0, resp->Signature, 1, &refs);
      if (ret == ZXSIG_BAD_CERT) {
	INFO("Canon sha1 of Response verified OK %d", ret);
	if (verbose)
	  printf("\nCanon sha1 of Response verified OK %d\n", ret);
      } else {
	ERR("Response Signature hash validation error. Bad canonicalization? ret=%d",ret);
	if (sig_flag < 3)
	  return 10;
      }
    }
  } else {
    if (!zxid_chk_sig(cf, &cgi, &ses, &resp->gg, resp->Signature, resp->Issuer, 0, "Response"))
      return 4;
  }
  
  a7n = zxid_dec_a7n(cf, resp->Assertion, resp->EncryptedAssertion);
  if (!a7n) {
    ERR("No Assertion found and not anon_ok in SAML Response %d", 0);
    return 5;
  }
  zx_see_elem_ns(cf->ctx, &pop_seen, &resp->gg);
got_a7n:
  if (sig_flag == 2) {
    if (a7n->Signature && a7n->Signature->SignedInfo && a7n->Signature->SignedInfo->Reference) {
      zx_reset_ns_ctx(cf->ctx);
      ZERO(&refs, sizeof(refs));
      refs.sref = a7n->Signature->SignedInfo->Reference;
      refs.blob = &a7n->gg;
      refs.pop_seen = pop_seen;
      zx_see_elem_ns(cf->ctx, &refs.pop_seen, &a7n->gg);
      ret = zxsig_validate(cf->ctx, 0, a7n->Signature, 1, &refs);
      if (ret == ZXSIG_BAD_CERT) {
	INFO("Canon sha1 of Assertion verified OK %d", ret);
	if (ret && verbose)
	  printf("\nCanon sha1 of Assertion verified OK %d\n", ret);
	return 0;
      }
      ERR("Canon sha1 of Assertion failed to verify ret=%d", ret);
      return 11;
    } else {
      ERR("Assertion does not contain a signature %p", a7n->Signature);
      return 7;
    }
  } else {
    ret = zxid_sp_sso_finalize(cf, &cgi, &ses, a7n, pop_seen);
    INFO("zxid_sp_sso_finalize() returned %d", ret);
  }
  if (ret && verbose)
    printf("\nSIG Verified OK, zxid_sp_sso_finalize() returned %d\n", ret);
  return ret?0:6;
}

/* Called by:  zxdecode_main x4 */
static int decode(char* msg, char* q)
{
  int len;
  char* p;
  char* m2;
  char* p2;
  
  *q = 0;
  D("Original Msg(%s) x=%x", msg, *msg);
  
  if (strchr(msg, '%')) {
    p = p2 = msg;
    URL_DECODE(p, p2, q);
    q = p;
    *q = 0;
    D("URL Decoded Msg(%s) x=%x", msg, *msg);
  } else
    p = q;
  
  switch (b64_flag) {
  case 0:
    D("decode_base64 skipped at user request %d",0);
    break;
  case 1:
    D("decode_base64 forced at user request %d",0);
b64_dec:
    /* msglen = q - msg; */
    p = unbase64_raw(msg, q, msg, zx_std_index_64);  /* inplace */
    *p = 0;
    D("Unbase64 Msg(%s) x=%x len=%d (n.b. message data may be binary at this point)", msg, *msg, ((int)(p-msg)));
    break;
  case 2:
    if (*msg == '<') {
      D("decode_base64 auto detect: no decode due to initial < %p %p", msg, p);
    } else {
      D("decode_base64 auto detect: decode due to initial 0x%x", *msg);
      goto b64_dec;
    }
    break;
  }
  
  switch (inflate_flag) {
  case 0:
    len = p-msg;
    p = msg;
    D("No decompression by user choice len=%d", len);
    break;
  case 1:
    D("Decompressing... (force) %d",0);
decompress:
    p = zx_zlib_raw_inflate(0, p-msg, msg, &len);  /* Redir uses compressed payload. */
    break;
  case 2:
    /* Skip whitespace in the beginning and end of the payload to help correct POST detection. */
    for (m2 = msg; m2 < p; ++m2)
      if (!ONE_OF_4(*m2, ' ', '\t', '\015', '\012'))
	break;
    for (p2 = p-1; m2 < p2; --p2)
      if (!ONE_OF_4(*p2, ' ', '\t', '\015', '\012'))
	break;
    D("Msg_minus_whitespace(%.*s) start=%x end=%x", ((int)(p2-m2+1)), m2, *m2, *p2);
    
    if (*m2 == '<' && *p2 == '>') {  /* POST profiles do not compress the payload */
      len = p2 - m2 + 1;
      p = m2;
    } else {
      D("Decompressing... (auto) %d",0);
      goto decompress;
    }
    break;
  }
  fwrite(p, 1, len, stdout);
  
  if (sig_flag)
    return sig_validate(len, p);
  return 0;
}

#ifndef zxdecode_main
#define zxdecode_main main
#endif

/* Called by: */
int zxdecode_main(int argc, char** argv, char** env)
{
  int got;
  char* pp;
  char* p;
  char* q;
  char* lim;

  strcpy(errmac_instance, "\tzxdec");
  opt(&argc, &argv, &env);

  read_all_fd(fdstdin, buf, sizeof(buf)-1, &got);
  buf[got] = 0;
  lim = buf+got;

  if (sha1_flag) {
    p = sha1_safe_base64(buf, got, buf);
    *p = 0;
    printf("%s\n", buf);
    return 0;
  }

  if (resp_flag)
    return sig_validate(got, buf);

  if (valid_opt)
    return ws_validations();

  /* Try to detect relevant input, iterating if -i N was specified.
   * The detection is supposed to pick SAMLRequest or SAMLResponse from
   * middle of HTML form, or from log output. Whatever is convenient. */

  for (pp = buf; pp && pp < lim; pp = p+1) {
    p = strstr(pp, "SAMLRequest=");
    if (p) {
      if (--ix)	continue;
      q = strchr(p, '&');
      return decode(p + sizeof("SAMLRequest=")-1, q?q:lim);
    }
    p = strstr(pp, "SAMLResponse=");
    if (p) {
      if (--ix)	continue;
      q = strchr(p, '&');
      return decode(p + sizeof("SAMLResponse=")-1, q?q:lim);
    }
    if (*pp == '<') {  /* HTML for POST */
      p = strstr(pp, "SAMLRequest");
      if (p) {
	p += sizeof("SAMLRequest")-1;
      } else {
	p = strstr(pp, "SAMLResponse");
	if (p)
	  p += sizeof("SAMLResponse")-1;
      }
      if (p) {
	p = strstr(p, "value=");
	if (p) {
	  if (--ix)	continue;
	  p += sizeof("value=")-1;
	  if (*p == '"') {
	    ++p;
	    q = strchr(p, '"');
	  } else {
	    q = p+strcspn(p, "\" >");
	  }
	  return decode(p, q?q:lim);
	}
      }
    }
    if (--ix) { p = pp; continue; }
    return decode(pp, lim);  /* Decode the object identified above. */
  }
  ERR("No SAMLRequest or SAMLResponse found to decode %p %p %p", buf, pp, lim);
  return 1;
}

/* EOF  --  zxdecode.c */
