/* zxbench.c  -  Benchmark zxid libraries
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxbench.c,v 1.25 2009-11-24 23:53:40 sampo Exp $
 *
 * 1.7.2006, started --Sampo
 *
 * Test encoding and decoding SAML 2.0 assertions and other related stuff.
 *
 * ./zxbench -d -i 1 <t/hp-idp-post-resp.xml
 *
 * WARNING: This code appears to be seriously out of date and historical as of Oct-2010. --Sampo
 */

#include <signal.h>
#include <fcntl.h>
#include <netdb.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <openssl/x509.h>

#include "errmac.h"

#include "zx.h"
#include "zxid.h"
#include "c/zx-data.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zxidvers.h"

int read_all_fd(int fd, char* p, int want, int* got_all);
int write_all_fd(int fd, char* p, int pending);

const char* help =
"zxbench  -  SAML 2.0 encoding and decoding benchmark - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxbench [options] <saml-assertion.xml >reencoded-a7n.xml\n\
  -i  N            Number of iterations to benchmark.\n\
  -t  SECONDS      Timeout. Default: 0=no timeout.\n\
  -c  CIPHER       Enable crypto on DTS interface using specified cipher. Use '?' for list.\n\
  -k  FDNUMBER     File descriptor for reading symmetric key. Use 0 for stdin.\n\
  -egd PATH        Specify path of Entropy Gathering Daemon socket, default on\n\
                   Solaris: /tmp/entropy. On Linux /dev/urandom is used instead\n\
                   See http://www.lothar.com/tech/crypto/ or\n\
                   http://www.aet.tu-cottbus.de/personen/jaenicke/postfix_tls/prngd.html\n\
  -rand PATH       Location of random number seed file. On Solaris EGD is used.\n\
                   On Linux the default is /dev/urandom. See RFC1750.\n\
  -uid UID:GID     If run as root, drop privileges and assume specified uid and gid.\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -license         Show licensing and NO WARRANTY details.\n\
  -h               This help message\n\
  --               End of options\n";

#define DIE(reason) MB fprintf(stderr, "%s\n", reason); exit(2); ME

int ak_buf_size = 0;
int verbose = 1;
extern int errmac_debug;
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

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
void opt(int* argc, char*** argv, char*** env)
{
  if (*argc <= 1) goto argerr;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* probably the remote host and port */
    
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
	strcpy(errmac_instance, (*argv)[0]);
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
  struct zx_str* eid;
  struct zx_root_s* r;
  struct zxsig_ref refs;
  zxid_entity* ent;
  zxid_conf* cf;
  int got_all, len_so, len_wo, res;
  char buf[256*1024];
  char out[256*1024];
  char* p;
  char wo_out[256*1024];
  char* wo_p;
  opt(&argc, &argv, &env);

  /*if (stats_prefix) init_cmdline(argc, argv, env, stats_prefix);*/
  CMDLINE("init");
  
#ifndef MINGW  
  if (signal(SIGPIPE, SIG_IGN) == SIG_ERR) {   /* Ignore SIGPIPE */
    perror("INIT: signal ignore pipe");
    exit(2);
  }

  /* Cause exit(3) to be called with the intent that any gcov profiling will get
   * written to disk before we die. If dsproxy is not stopped `kill -USR1' but you
   * use plain kill instead, the profile will indicate many unexecuted (#####) lines. */
  if (signal(SIGUSR1, exit) == SIG_ERR) {
    perror("INIT: signal USR1 exit");
    exit(2);
  }
#endif
  
  /* Drop privileges, if requested. */
  
  if (drop_gid) if (setgid(drop_gid)) { perror("INIT: setgid"); exit(1); }
  if (drop_uid) if (setuid(drop_uid)) { perror("INIT: setuid"); exit(1); }
  
  len_so = read_all_fd(fdstdin, buf, sizeof(buf)-1, &got_all);
  if (got_all <= 0) DIE("Missing data");
  buf[got_all] = 0;
  
  D("Decoding %d chars, n_iter(%d)", got_all, n_iter);
  
  for (;n_iter; --n_iter) {
    cf = zxid_new_conf("/var/zxid/");
    r = zx_dec_zx_root(cf->ctx, got_all, buf, "zxbench");  /* n_decode=1000 ?!? */
    if (!r) DIE("Decode failure");
    
    //ent = zxid_get_ent_file(cf, "YV7HPtu3bfqW3I4W_DZr-_DKMP4" /* cxp06 */, "bench");
    //ent = zxid_get_ent_file(cf, "zIDxx57qGA-qwnsymUf4JD0Er2A" /* s-idp */, "bench");
    //ent = zxid_get_ent_file(cf, "7S4XRMew6HHKey9j8fESiJUV-Cs" /* hp-idp */, "bench");
    //r->Envelope->Body->ArtifactResolve
    if (r->Envelope && r->Envelope->Body) {
      if (r->Envelope->Body->ArtifactResponse) {
	if (r->Envelope->Body->ArtifactResponse->Signature) {
	  eid = ZX_GET_CONTENT(r->Envelope->Body->ArtifactResponse->Issuer);
	  D("Found sig in Envelope/Body/ArtifactResponse eid(%.*s)", eid->len, eid->s);
	  ent = zxid_get_ent_cache(cf, eid);
	  ZERO(&refs, sizeof(refs));
	  refs.sref = r->Envelope->Body->ArtifactResponse->Signature->SignedInfo->Reference;
	  refs.blob = (struct zx_elem_s*)r->Envelope->Body->ArtifactResponse;
	  res = zxsig_validate(cf->ctx, ent->sign_cert,
			       r->Envelope->Body->ArtifactResponse->Signature,
			       1, &refs);
	  if (res == ZXSIG_OK) {
	    D("sig vfy ok %d", res);
	  } else {
	    ERR("sig vfy failed due to(%d)", res);
	  }
	}
	if (r->Envelope->Body->ArtifactResponse->Response) {
	  if (r->Envelope->Body->ArtifactResponse->Response->Assertion) {
	    if (r->Envelope->Body->ArtifactResponse->Response->Assertion->Signature) {
	      eid = ZX_GET_CONTENT(r->Envelope->Body->ArtifactResponse->Response->Assertion->Issuer);
	      D("Found sig in Envelope/Body/ArtifactResponse/Response/Assertion eid(%.*s)", eid->len, eid->s);
	      ent = zxid_get_ent_cache(cf, eid);
	      refs.sref = r->Envelope->Body->ArtifactResponse->Response->Assertion->Signature->SignedInfo->Reference;
	      refs.blob = (struct zx_elem_s*)r->Envelope->Body->ArtifactResponse->Response->Assertion;
	      res = zxsig_validate(cf->ctx, ent->sign_cert,
				   r->Envelope->Body->ArtifactResponse->Response->Assertion->Signature,
				   1, &refs);
	      if (res == ZXSIG_OK) {
		D("sig vfy ok %d", res);
	      } else {
		ERR("sig vfy failed due to(%d)", res);
	      }
	    }
	  }
	}
      }
    } else if (r->Assertion) {
      if (r->Assertion->Signature) {
	eid = ZX_GET_CONTENT(r->Assertion->Issuer);
	D("Found sig in (bare) Assertion eid(%.*s)", eid->len, eid->s);
	ent = zxid_get_ent_cache(cf, eid);
	refs.sref = r->Assertion->Signature->SignedInfo->Reference;
	refs.blob = (struct zx_elem_s*)r->Assertion;
	res = zxsig_validate(cf->ctx, ent->sign_cert,
			     r->Assertion->Signature,
			     1, &refs);
	if (res == ZXSIG_OK) {
	  D("sig vfy ok %d", res);
	} else {
	  ERR("sig vfy failed due to(%d)", res);
	}
      }
    } else if (r->Response) {

      if (r->Response->Signature) {
	eid = ZX_GET_CONTENT(r->Response->Issuer);
	D("Found sig in Response eid(%.*s)", eid->len, eid->s);
	ent = zxid_get_ent_cache(cf, eid);
	refs.sref = r->Response->Signature->SignedInfo->Reference;
	refs.blob = (struct zx_elem_s*)r->Response;
	res = zxsig_validate(cf->ctx, ent->sign_cert,
			     r->Response->Signature,
			     1, &refs);
	if (res == ZXSIG_OK) {
	  D("sig vfy ok %d", res);
	} else {
	  ERR("sig vfy failed due to(%d)", res);
	}
      }

      if (r->Response->Assertion) {
	if (r->Response->Assertion->Signature) {
	  eid = ZX_GET_CONTENT(r->Response->Assertion->Issuer);
	  D("Found sig in Response/Assertion eid(%.*s)", eid->len, eid->s);
	  ent = zxid_get_ent_cache(cf, eid);
	  refs.sref = r->Response->Assertion->Signature->SignedInfo->Reference;
	  refs.blob = (struct zx_elem_s*)r->Response->Assertion;
	  res = zxsig_validate(cf->ctx, ent->sign_cert,
			       r->Response->Assertion->Signature,
			       1, &refs);
	  if (res == ZXSIG_OK) {
	    D("sig vfy ok %d", res);
	  } else {
	    ERR("sig vfy failed due to(%d)", res);
	  }
	}
      }
    }

#if 1
    len_so = zx_LEN_SO_root(cf->ctx, r);
    D("Enc so len %d chars", len_so);

    p = zx_ENC_SO_root(cf->ctx, r, out);
    if (!p)
      DIE("encoding error");

    len_wo = zx_LEN_WO_any_elem(cf->ctx, r);
    D("Enc wo len %d chars", len_wo);

    wo_p = zx_ENC_WO_any_elem(cf->ctx, r, wo_out);
    if (!wo_p)
      DIE("encoding error");
#endif
    zx_FREE_root(cf->ctx, r, 0);
  }
  printf("Re-encoded result SO:\n%.*s\n", len_so, out);
  if (p - out != len_so)
    D("encode length mismatch %d vs. %d (len)", p - out, len_so);

  printf("Re-encoded result WO:\n%.*s\n", len_wo, wo_out);
  if (wo_p - wo_out != len_wo)
    D("encode length mismatch %d vs %d (len)", wo_p - wo_out, len_wo);

  if (memcmp(out, wo_out, MIN(len_so, len_wo)))
    printf("SO and WO differ.\n");
  
  return 0;
}

/* EOF  --  zxbench.c */
