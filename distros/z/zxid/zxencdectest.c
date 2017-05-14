/* zxencdectest.c  -  Test XML encoding and decoding using zx generated code
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxencdectest.c,v 1.9 2009-11-24 23:53:40 sampo Exp $
 *
 * 1.7.2006, started --Sampo
 * 9.2.2007, improved to make basis of a test suite tool --Sampo
 * 1.3.2011, added zx_timegm() testing --Sampo
 *
 * Test encoding and decoding SAML 2.0 assertions and other related stuff.
 */

#include "platform.h"  /* This needs to appear first to avoid mingw64 problems. */
#include "errmac.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "zx.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "saml2.h"
#include "c/zxidvers.h"
#include "c/zx-data.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"

char* help =
"zxencdectest  -  ZX encoding and decoding tester - R" ZXID_REL "\n\
Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
Copyright (c) 2006-2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxencdectest [options] <foo.xml >reencoded-foo.xml\n\
  -r N         Run test number N. 1 = IBM cert dec, 2 = IBM cert enc dec\n\
  -i N         Number of iterations to benchmark (default 1).\n\
  -t SECONDS   Timeout. Default: 0=no timeout.\n\
  -c CIPHER    Enable crypto on DTS interface using specified cipher. Use '?' for list.\n\
  -k FDNUMBER  File descriptor for reading symmetric key. Use 0 for stdin.\n\
  -egd PATH    Specify path of Entropy Gathering Daemon socket, default\n\
               on Solaris: /tmp/entropy; Linux: /dev/urandom\n\
               See http://www.lothar.com/tech/crypto/ or\n\
               http://www.aet.tu-cottbus.de/personen/jaenicke/postfix_tls/prngd.html\n\
  -rand PATH   Location of random number seed file. On Solaris EGD is used.\n\
               On Linux the default is /dev/urandom. See RFC1750.\n\
  -wo PATH     File to write wire order encoding in\n\
  -v           Verbose messages.\n\
  -q           Be extra quiet.\n\
  -d           Turn on debugging.\n\
  -license     Show licensing and NO WARRANTY details.\n\
  -h           This help message\n\
  --           End of options\n";

#define DIE(reason) MB fprintf(stderr, "%s\n", reason); exit(2); ME

int ak_buf_size = 0;
int verbose = 1;
extern int debug;
int timeout = 0;
int gcthreshold = 0;
int leak_free = 0;
extern int assert_nonfatal;
int drop_uid = 0;
int drop_gid = 0;
char* rand_path;
char* egd_path;
char  symmetric_key[1024];
int symmetric_key_len;
int n_iter = 1;
char* wo_path = 0;
char buf[256*1024];

/* Called by:  opt */
void test_ibm_cert_problem()  /* -r 1 */
{
  int got_all;
  zxid_conf* cf;
  struct zx_root_s* r;
  struct zx_sp_LogoutRequest_s* req;

  read_all_fd(fdstdin, buf, sizeof(buf)-1, &got_all);
  if (got_all <= 0) DIE("Missing data");
  buf[got_all] = 0;

  /* IBM padding debug */
  cf = zxid_new_conf("/var/zxid/");
  r = zx_dec_zx_root(cf->ctx, got_all, buf, "zxencdectest");
  if (!r || !r->Envelope || r->Envelope->Body || r->Envelope->Body->LogoutRequest)
    DIE("Decode failure");

#if 1
  cf->enc_pkey = zxid_read_private_key(cf, "sym-idp-enc.pem");
#else
  cf->enc_pkey = zxid_read_private_key(cf, "ibm-idp-enc.pem");
#endif
  
  req = r->Envelope->Body->LogoutRequest;
  req->NameID = zxid_decrypt_nameid(cf, req->NameID, req->EncryptedID);
  printf("r1 nid(%.*s)\n", ZX_GET_CONTENT_LEN(req->NameID), ZX_GET_CONTENT_S(req->NameID));
}

/* Called by:  opt */
void test_ibm_cert_problem_enc_dec()  /* -r 2 */
{
  zxid_conf* cf;
  struct zx_sp_LogoutRequest_s* req;
  zxid_nid* nameid;
  zxid_entity* idp_meta;

  cf = zxid_new_conf("/var/zxid/");

  nameid = zx_NEW_sa_NameID(cf->ctx,0);
  /*nameid->SPNameQualifier = zx_ref_attr(cf->ctx, &nameid->gg, zx_SPNameQualifier_ATTR, spqual);*/
  nameid->NameQualifier = zx_ref_attr(cf->ctx, &nameid->gg, zx_NameQualifier_ATTR, "ibmidp");
  nameid->Format = zx_ref_attr(cf->ctx, &nameid->gg, zx_Format_ATTR, "persistent");
  zx_add_content(cf->ctx, &nameid->gg, zx_ref_str(cf->ctx, "a-persistent-nid"));

#if 0
  cf->enc_pkey = zxid_read_private_key(cf, "sym-idp-enc.pem");
#else
  cf->enc_pkey = zxid_read_private_key(cf, "ibm-idp-enc.pem");
  idp_meta = zxid_get_ent_file(cf, "N9zsU-AwbI1O-U3mvjLmOALtbtU", "test_ibm"); /* IBMIdP */
#endif
  
  req = zxid_mk_logout(cf, nameid, 0, idp_meta);  
  req->NameID = zxid_decrypt_nameid(cf, req->NameID, req->EncryptedID);
  printf("r2 nid(%.*s) should be(a-persistent-nid)\n", ZX_GET_CONTENT_LEN(req->NameID), ZX_GET_CONTENT_S(req->NameID));
}

/* Called by:  opt */
void so_enc_dec()     /* -r 3 */
{
  zxid_conf* cf;
  struct zx_sp_Status_s* st;
  struct zx_str* ss;
  cf = zxid_new_conf("/var/zxid/");
  st = zxid_mk_Status(cf, 0, "SC1", "SC2", "MESSAGE");
  ss = zx_easy_enc_elem_opt(cf, &st->gg);
  printf("%.*s", ss->len, ss->s);  zx_dump_ns_tab(cf->ctx, 0);
}

/* Called by:  opt */
void attribute_sort_test()  /* -r 4 */
{
  zxid_conf* cf;
  struct zx_xasp_XACMLAuthzDecisionQuery_s* q;
  struct zx_xaspcd1_XACMLAuthzDecisionQuery_s* q2;
  struct zx_str* ss;
  cf = zxid_new_conf("/var/zxid/");
  q = zxid_mk_az(cf, 0, 0, 0, 0);
  ss = zx_easy_enc_elem_sig(cf, &q->gg);
  printf("%.*s", ss->len, ss->s);

  q2 = zxid_mk_az_cd1(cf, 0, 0, 0, 0);
  ss = zx_easy_enc_elem_sig(cf, &q2->gg);
  printf("CD1: %.*s", ss->len, ss->s);
}

/* Called by:  opt */
void a7n_test()       /* -r 6 */
{
  struct timeval srctss;
  zxid_conf* cf;
  zxid_cgi cgi;
  zxid_ses sess;
  zxid_nid* nameid;
  struct zx_str* issuer;
  struct zx_sp_AuthnRequest_s* ar;
  zxid_entity* sp_meta;
  zxid_a7n* a7n;
  memset(&cgi, 0, sizeof(cgi));
  memset(&sess, 0, sizeof(sess));
  memset(&srctss, 0, sizeof(srctss));

  sess.sid = "MSES1234";
  sess.uid = "test";
  cf = zxid_new_conf_to_cf("PATH=/var/zxid/&URL=http://sp1.zxidsp.org:8081/zxidhlo");
#if 1
  ar = zxid_mk_authn_req(cf, &cgi);
  issuer = ZX_GET_CONTENT(ar->Issuer);
  D("issuer(%.*s)", issuer->len, issuer->s);
  sp_meta = zxid_get_ent_ss(cf, issuer);
  a7n = zxid_sso_issue_a7n(cf, &cgi, &sess, &srctss, sp_meta, 0, &nameid, 0, ar);
#else
  a7n = zxid_mk_usr_a7n_to_sp(cf, &sess, const char* uid, zxid_nid* nameid, zxid_entity* sp_meta, const char* sp_name_buf, 0);
#endif
  zxid_find_attribute(a7n, 0, 0, 0, 0, 0, 0, 1);
  //zxid_ssos_anreq(cf, a7n, ar, ZX_GET_CONTENT(ar->Issuer));
  zxid_mni_do_ss(cf, &cgi, &sess, zxid_mk_mni(cf, nameid, zx_ref_str(cf->ctx, "newnym"), sp_meta), zx_ref_str(cf->ctx, "loc-dummy"));
  zxid_sp_mni_soap(cf, &cgi, &sess, zx_ref_str(cf->ctx, "newnym"));
}

/* Called by:  opt */
void x509_test()      /* -r 7 */
{
  struct timeval srctss;
  zxid_conf* cf;
  zxid_cgi cgi;
  zxid_ses sess;
  zxid_nid* nameid;
  char buf[4096];
  memset(&cgi, 0, sizeof(cgi));
  memset(&sess, 0, sizeof(sess));
  memset(&srctss, 0, sizeof(srctss));

  sess.uid = "test";
  cf = zxid_new_conf("/var/zxid/");

#if 1
  nameid = zx_NEW_sa_NameID(cf->ctx,0);
  nameid->SPNameQualifier = zx_ref_attr(cf->ctx, &nameid->gg, zx_SPNameQualifier_ATTR, "http://mysp?o=B");
  nameid->NameQualifier = zx_ref_attr(cf->ctx, &nameid->gg, zx_NameQualifier_ATTR, "http://myidp?o=B");
  nameid->Format = zx_ref_attr(cf->ctx, &nameid->gg, zx_Format_ATTR, "persistent");
  zx_add_content(cf->ctx, &nameid->gg, zx_ref_str(cf->ctx, "a-persistent-nid"));
#else
  struct zx_sp_AuthnRequest_s* ar;
  zxid_entity* sp_meta;
  zxid_a7n* a7n;
  ar = zxid_mk_authn_req(cf, &cgi);
  sp_meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(ar->Issuer));
  a7n = zxid_sso_issue_a7n(cf, &cgi, &sess, &srctss, sp_meta, 0, &nameid, 0, ar);
#endif
  zxid_mk_at_cert(cf, sizeof(buf), buf, "test", nameid, "1.2.826.0.1.3344810.1.1.14", zx_ref_str(cf->ctx, "Role0"));
  printf("%s",buf);
}

/* Called by:  timegm_test x16 */
int timegm_tester(zxid_conf* cf, const char* date_time)
{
  struct zx_str* ss;
  int secs;
  cf = zxid_new_conf("/var/zxid/");
  secs = zx_date_time_to_secs(date_time);
  ss = zxid_date_time(cf, secs);
  if (memcmp(date_time, ss->s, ss->len)) {
    printf("%s %d\n%.*s ERR\n\n", date_time, secs, ss->len, ss->s);
    return 0;
  } else {
    if (verbose)
      printf("%s %d\n%.*s OK\n\n", date_time, secs, ss->len, ss->s);
    return 1;
  }
}

/* Called by:  timegm_test */
int leap_test(int aa) {
  return LEAP(aa);
}

/* Called by:  opt */
void timegm_test()      /* -r 8 */
{
  int aa;
  zxid_conf* cf = zxid_new_conf("/var/zxid/");
  printf("leap(2011)=%d\n", leap_test(2011));

  timegm_tester(cf, "2011-02-28T11:30:19Z");
  timegm_tester(cf, "2011-03-01T11:30:19Z");
  timegm_tester(cf, "2011-03-02T11:30:19Z");
  timegm_tester(cf, "2011-03-03T11:30:19Z");
  timegm_tester(cf, "2011-03-04T11:30:19Z");
  timegm_tester(cf, "2011-03-31T11:30:19Z");
  timegm_tester(cf, "2011-04-01T11:30:19Z");
  timegm_tester(cf, "2011-04-02T11:30:19Z");

  for (aa = 1970; aa < 2028; ++aa) {
    snprintf(buf, sizeof(buf), "%d-02-28T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-03-01T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-03-02T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-03-03T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-03-04T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-03-31T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-04-01T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
    snprintf(buf, sizeof(buf), "%d-04-02T11:30:19Z", aa); if (!timegm_tester(cf, buf)) exit(1);
  }
}

const char foobar[] = "foobar";
const char goobar[] = "goo\r\n~[]";

int zxid_wsc_valid_re_env(zxid_conf* cf, zxid_ses* ses, const char* az_cred, struct zx_e_Envelope_s* env, const char* enve);

/* Called by:  opt */
void covimp_test()       /* -r 5 */
{
  char buf[256];
  int outlen;
  char* out;
  char* sigval;
  char* sigmsg;
  struct zx_str* ss;
  struct zx_e_Envelope_s* env;
  zxid_fault* flt;
  zxid_tas3_status* st;
  zxid_entity* meta;
  zxid_conf* cf;
  zxid_cgi cgi;
  zxid_ses sess;
  memset(&cgi, 0, sizeof(cgi));
  memset(&sess, 0, sizeof(sess));

  printf("version(%x)\n", zxid_version());
  cf = zxid_new_conf("/var/zxid/");
  printf("urlenc(%s)\n", zx_url_encode(cf->ctx, sizeof("test1://foo?a=b&c=d e")-1, "test1://foo?a=b&c=d e", &outlen));
  zx_hexdec(buf, "313233", 6, hex_trans);
  printf("hexdec(%.3s)\n", buf);
  hexdmp("test2: ", (char*)foobar, sizeof(foobar), 1000);
  hexdmp("test2b: ", (char*)goobar, sizeof(goobar), 1000);
  copy_file("t/XML1.out","tmp/foo3","test3",0);
  copy_file("t/XML1.out","tmp/foo4","test4",1);
  copy_file("t/XML1.out","tmp/foo5","test5",2);
  copy_file("/impossible","tmp/foo5a","test5a",0);
  copy_file("t/XML1.out","tmp/impossiblefoo5b","test5b",0);
  read_all(sizeof(buf), buf, "test5c", 1, "/impossible");
  read_all_alloc(cf->ctx, "test5d", 1, &outlen, "/impossible");
  zx_prepare_dec_ctx(cf->ctx, zx_ns_tab, zx__NS_MAX, foobar, foobar+sizeof(foobar));
  zx_format_parse_error(cf->ctx, buf, sizeof(buf), "test6");
  printf("parse err(%s)\n", buf);
  zx_xml_parse_err(cf->ctx, '?', __FUNCTION__, "test7");
  printf("memmem(%s)\n", zx_memmem("foobar", 6, "oba", 3));
  ss = zx_ref_str(cf->ctx, "abc");
  zx_str_conv(ss, &outlen, &out);
  zxid_wsp_decorate(cf, &sess, 0, "<foo/>");
#ifndef MINGW
  setenv("HTTP_COOKIE", "_liberty_idp=\"test8\"", 1);
  zxid_cdc_read(cf, &cgi);
#endif
  cgi.cdc = "test9";
  zxid_cdc_check(cf, &cgi);
  zxid_new_cgi(cf, "=test10&ok=1&okx=2&s=S123&c=test11&e=abc&d=def&&l=x&l1=y&l1foo=z&inv=qwe&fg=1&fh=7&fr=RS&gu=1&gn=asa&ge=1&an=&aw=&at=&SAMLart=artti&SAMLResponse=respis");

  printf("n=%s\n", zxid_saml2_map_nid_fmt("n"));
  printf("p=%s\n", zxid_saml2_map_nid_fmt("p"));
  printf("t=%s\n", zxid_saml2_map_nid_fmt("t"));
  printf("u=%s\n", zxid_saml2_map_nid_fmt("u"));
  printf("e=%s\n", zxid_saml2_map_nid_fmt("e"));
  printf("x=%s\n", zxid_saml2_map_nid_fmt("x"));
  printf("w=%s\n", zxid_saml2_map_nid_fmt("w"));
  printf("k=%s\n", zxid_saml2_map_nid_fmt("k"));
  printf("s=%s\n", zxid_saml2_map_nid_fmt("s"));
  printf("X=%s\n", zxid_saml2_map_nid_fmt("X"));

  printf("r=%s\n", zxid_saml2_map_protocol_binding("r"));
  printf("a=%s\n", zxid_saml2_map_protocol_binding("a"));
  printf("p=%s\n", zxid_saml2_map_protocol_binding("p"));
  printf("q=%s\n", zxid_saml2_map_protocol_binding("q"));
  printf("s=%s\n", zxid_saml2_map_protocol_binding("s"));
  printf("e=%s\n", zxid_saml2_map_protocol_binding("e"));
  printf("X=%s\n", zxid_saml2_map_protocol_binding("X"));

  printf("NULL=%d\n",       zxid_protocol_binding_map_saml2(0));
  printf("SAML2_REDIR=%d\n", zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, SAML2_REDIR)));
  printf("SAML2_ART=%d\n",   zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, SAML2_ART)));
  printf("SAML2_POST=%d\n",  zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, SAML2_POST)));
  printf("SAML2_POST_SIMPLE_SIGN=%d\n", zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, SAML2_POST_SIMPLE_SIGN)));
  printf("SAML2_SOAP=%d\n",  zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, SAML2_SOAP)));
  printf("SAML2_PAOS=%d\n",  zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, SAML2_PAOS)));
  printf("unknown=%d\n",    zxid_protocol_binding_map_saml2(zx_ref_str(cf->ctx, "unknown")));

  printf("n=%s\n",       zxid_saml2_map_authn_ctx("n"));
  printf("pwp=%s\n",     zxid_saml2_map_authn_ctx("pwp"));
  printf("pw=%s\n",      zxid_saml2_map_authn_ctx("pw"));
  printf("prvses=%s\n",  zxid_saml2_map_authn_ctx("prvses"));
  printf("clicert=%s\n", zxid_saml2_map_authn_ctx("clicert"));
  printf("unspcf=%s\n",  zxid_saml2_map_authn_ctx("unspcf"));
  printf("ip=%s\n",      zxid_saml2_map_authn_ctx("ip"));
  printf("X=%s\n",       zxid_saml2_map_authn_ctx("X"));

  zxid_sigres_map(ZXSIG_OK, &sigval, &sigmsg);         printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_BAD_DALGO, &sigval, &sigmsg);  printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_DIGEST_LEN, &sigval, &sigmsg); printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_BAD_DIGEST, &sigval, &sigmsg); printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_BAD_SALGO, &sigval, &sigmsg);  printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_BAD_CERT, &sigval, &sigmsg);   printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_VFY_FAIL, &sigval, &sigmsg);   printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_NO_SIG, &sigval, &sigmsg);     printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_TIMEOUT, &sigval, &sigmsg);    printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(ZXSIG_AUDIENCE, &sigval, &sigmsg);   printf("%s %s\n", sigval, sigmsg);
  zxid_sigres_map(99, &sigval, &sigmsg);               printf("%s %s (other)\n", sigval, sigmsg);

  printf("fake_sso=%d\n", zxid_sp_anon_finalize(cf, &cgi, &sess));

#ifndef MINGW
  setenv("HTTP_PAOS", SAML2_SSO_ECP, 1);
  zxid_lecp_check(cf, &cgi);        /* *** should test in realistic context */
#endif

  meta = zxid_get_ent_file(cf, "N9zsU-AwbI1O-U3mvjLmOALtbtU", "covimp"); /* IBMIdP */
  zxid_mk_art_deref(cf, 0, meta, "ART124121");  /* *** should test in realistic context */
  
  zxid_mk_lu_Status(cf, 0, 0, "SC2-dummy", "MSG-dummy", "REF-dummy");
  st = zxid_mk_tas3_status(cf, 0, 0, 0, "SC2-dummy", "MSG-dummy", "REF-dummy");
  zxid_get_fault(cf, &sess);
  zxid_get_tas3_status(cf, &sess);

  zxid_get_tas3_fault_sc1(cf, 0);
  zxid_get_tas3_fault_sc2(cf, 0);
  zxid_get_tas3_fault_comment(cf, 0);
  zxid_get_tas3_fault_ref(cf, 0);
  zxid_get_tas3_fault_actor(cf, 0);

  zxid_get_tas3_status_sc1(cf, 0);
  zxid_get_tas3_status_sc2(cf, 0);
  zxid_get_tas3_status_comment(cf, 0);
  zxid_get_tas3_status_ref(cf, 0);
  zxid_get_tas3_status_ctlpt(cf, 0);

  flt = zxid_mk_fault(cf, 0, "actor", "fc1", "fault string", "SC1", "SC2", "MSG", "REF");
  zxid_get_tas3_fault_sc1(cf, flt);
  zxid_get_tas3_fault_sc2(cf, flt);
  zxid_get_tas3_fault_comment(cf, flt);
  zxid_get_tas3_fault_ref(cf, flt);
  zxid_get_tas3_fault_actor(cf, flt);

  zxid_get_tas3_status_sc1(cf, st);
  zxid_get_tas3_status_sc2(cf, st);
  zxid_get_tas3_status_comment(cf, st);
  zxid_get_tas3_status_ref(cf, st);
  zxid_get_tas3_status_ctlpt(cf, st);

  /* *** should test in realistic context */
  zxid_mk_dap_query(cf, 0, 
		    zxid_mk_dap_test_item(cf, 0,
					  zxid_mk_dap_testop(cf, 0, 0, 0, 0, 1, 2, 3, 4, 5),
					  0, 0),
		    zxid_mk_dap_query_item(cf, 0,
					   zxid_mk_dap_select(cf, 0, 0, 0, 0, 0, 1, 0, 0, 0),
					   0, 0, 0, 0, 1, 2, 3, 0, 0, 0),
		    zxid_mk_dap_subscription(cf, 0, "SUBSID", "#ITEMID",
					     zxid_mk_dap_resquery(cf, 0,
								   zxid_mk_dap_select(cf, 0, 0, 0, 0, 0, 1, 0, 0, 0),
								   0, 0, 0, 0, 1, 0),
					     0, 0, 0, 0, 1, 0, 0));

  zxid_wsf_decor(cf,0,0,0,0);
  zxid_map_sec_mech(0);
  zxid_wsc_valid_re_env(cf,0,0,0,0);
  env = zx_NEW_e_Envelope(cf->ctx, 0);
  zxid_wsc_valid_re_env(cf,0,0,env,0);
  zxid_wsf_decor(cf,0,env,0,0);
  zxid_wsc_valid_re_env(cf,0,0,env,0);
  printf("covimp ok\n");
}

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
void opt(int* argc, char*** argv, char*** env)
{
  if (*argc < 1) goto argerr;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'i': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      n_iter = atoi((*argv)[0]);
      continue;

    case 't': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
      timeout = atoi((*argv)[0]);
      continue;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	continue;
      case 'i':  if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	strncpy(errmac_instance, (*argv)[0], sizeof(errmac_instance));
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

    case 'q':
      switch ((*argv)[0][2]) {
      case '\0':
	verbose = 0;
	continue;
      }
      break;

    case 'e':
      switch ((*argv)[0][2]) {
      case 'g': if ((*argv)[0][3] != 'd' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	egd_path = (*argv)[0];
	continue;
      }
      break;
      
    case 'r':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	switch (atoi((*argv)[0])) {
	case 1: test_ibm_cert_problem(); break;
	case 2: test_ibm_cert_problem_enc_dec(); break;
	case 3: so_enc_dec(); break;
	case 4: attribute_sort_test(); break;
	case 5: covimp_test(); break;
	case 6: a7n_test(); break;
	case 7: x509_test(); break;
	case 8: timegm_test(); break;
	}
	exit(0);

      case 'f':
	/*AK_TS(LEAK, 0, "memory leaks enabled");*/
#if 1
	ERR("*** WARNING: You have turned memory frees to memory leaks. We will (eventually) run out of memory. Using -rf is not recommended. %d\n", 0);
#endif
	++leak_free;
	continue;
#if 0
      case 'e':
	if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if ((*argc) < 4) break;
	sscanf((*argv)[0], "%i", &abort_funcno);
	++(*argv); --(*argc);
	sscanf((*argv)[0], "%i", &abort_line);
	++(*argv); --(*argc);
	sscanf((*argv)[0], "%i", &abort_error_code);
	++(*argv); --(*argc);
	sscanf((*argv)[0], "%i", &abort_iter);
	fprintf(stderr, "Will force core upon %x:%x err=%d iter=%d\n",
		abort_funcno, abort_line, abort_error_code, abort_iter);
	continue;
#endif
      case 'g':
	if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	gcthreshold = atoi((*argv)[0]);
	if (!gcthreshold)
	  ERR("*** WARNING: You have disabled garbage collection. This may lead to increased memory consumption for scripts that handle a lot of PDUs or run for long time. Using `-rg 0' is not recommended. %d\n", 0);
	continue;
      case 'a':
	if ((*argv)[0][3] == 0) {
	  /*AK_TS(ASSERT_NONFATAL, 0, "assert nonfatal enabled");*/
#if 1
	  ERR("*** WARNING: YOU HAVE TURNED ASSERTS OFF USING -ra FLAG. THIS MEANS THAT YOU WILL NOT BE ABLE TO OBTAIN ANY SUPPORT. IF PROGRAM NOW TRIES TO ASSERT IT MAY MYSTERIOUSLY AND UNPREDICTABLY CRASH INSTEAD, AND NOBODY WILL BE ABLE TO FIGURE OUT WHAT WENT WRONG OR HOW MUCH DAMAGE MAY BE DONE. USING -ra IS NOT RECOMMENDED. %d\n", assert_nonfatal);
#endif
	  ++assert_nonfatal;
	  continue;
	}
	if (!strcmp((*argv)[0],"-rand")) {
	  ++(*argv); --(*argc);
	  if (!(*argc)) break;
	  rand_path = (*argv)[0];
	  continue;
	}
	break;
      }
      break;

    case 'w':
      switch ((*argv)[0][2]) {
      case 'o': if ((*argv)[0][3]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	wo_path = (*argv)[0];
	continue;
      }
      break;

#ifndef MINGW
    case 'k':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if (!(*argc)) break;
	read_all_fd(atoi((*argv)[0]), symmetric_key, sizeof(symmetric_key), &symmetric_key_len);
	D("Got %d characters of symmetric key", symmetric_key_len);
	continue;
      }
      break;
#endif

    case 'c': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      if (!(*argc)) break;
#ifndef ENCRYPTION
      ERR("Encryption not compiled in. %d",0);
#endif
      continue;

    case 'u':
      switch ((*argv)[0][2]) {
      case 'i': if ((*argv)[0][3] != 'd' || (*argv)[0][4]) break;
	++(*argv); --(*argc);
	if (!(*argc)) break;
	sscanf((*argv)[0], "%i:%i", &drop_uid, &drop_gid);
	continue;
      }
      break;

    case 'l':
      switch ((*argv)[0][2]) {
      case 'i':
	if (!strcmp((*argv)[0],"-license")) {
	  extern char* license;
	  fprintf(stderr, "%s", license);
	  exit(0);
	}
	break;
      }
      break;

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
  argerr:
    fprintf(stderr, "%s", help);
    exit(3);
  }
}

/* ============== M A I N ============== */

/* Called by: */
int main(int argc, char** argv, char** env)
{
  struct zx_ctx ctx;
  struct zx_root_s* r;
  int got_all, len_wo;
  char wo_out[256*1024];
  char* wo_p;
  opt(&argc, &argv, &env);
  
  len_wo = read_all_fd(fdstdin, buf, sizeof(buf)-1, &got_all);
  if (got_all <= 0) DIE("Missing data");
  buf[got_all] = 0;

  D("Decoding %d chars, n_iter(%d)\n", got_all, n_iter);
  
  for (; n_iter; --n_iter) {
    ZERO(&ctx, sizeof(ctx));
    r = zx_dec_zx_root(&ctx, got_all, buf, "zxencdectest main");  /* n_decode=1000 ?!? */
    if (!r)
      DIE("Decode failure");

    len_wo = zx_LEN_WO_any_elem(&ctx, &r->gg);
    D("Enc wo len %d chars", len_wo);

    ctx.bas = wo_out;
    wo_p = zx_ENC_WO_any_elem(&ctx, &r->gg, wo_out);
    if (!wo_p)
      DIE("encoding error");

    zx_free_elem(&ctx, &r->gg, 0);
  }

  if (got_all != len_wo)
    printf("Original and WO are different lengths %d != %d\n", got_all, len_wo);

  if (memcmp(buf, wo_out, MIN(got_all, len_wo)))
    printf("Original and WO differ.\n");

  if (wo_p - wo_out != len_wo)
    ERR("WO encode length mismatch %d vs %d (len)", ((int)(wo_p - wo_out)), len_wo);
  printf("Re-encoded result WO (len=%d):\n%.*s\n\n", len_wo, len_wo, wo_out);

  if (wo_path)
    write_all_path("WO", "%s", wo_path, 0, len_wo, wo_out);
  return 0;
}

/* EOF  --  zxencdectest.c */
