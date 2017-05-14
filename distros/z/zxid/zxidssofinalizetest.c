/* zxidssofinalizetest.c  -  Test Processing of a7n by zxid_sso_finalize()
 * Copyright (c) 2006-2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidssofinalizetest.c,v 1.6 2009-11-24 23:53:40 sampo Exp $
 *
 * 1.7.2006, started --Sampo
 * 9.2.2007, improved to make basis of a test suite tool --Sampo
 *
 * Test encoding and decoding SAML 2.0 assertions and other related stuff.
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
#include "c/zxidvers.h"
#include "c/zx-data.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"

int read_all_fd(int fd, char* p, int want, int* got_all);
int write_all_fd(int fd, char* p, int pending);

CU8* help =
"zxidssofinalizetest  -  Test processing a7n by zxid_sso_finalize() - R" ZXID_REL "\n\
Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidssofinalizetest [options] <a7n.xml\n\
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

    case 'n': if ((*argv)[0][2]) break;
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
	errmac_instance = (*argv)[0];
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
	  fprintf(stderr, license);
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
    fprintf(stderr, help);
    exit(3);
  }
}

/* ============== M A I N ============== */

/* Called by: */
int main(int argc, char** argv, char** env)
{
  zxid_conf* cf;
  zxid_cgi cgi;
  zxid_ses ses;
  struct zx_root_s* r;
  int ret, got_all, len_so;
  char buf[256*1024];
  opt(&argc, &argv, &env);
  
  len_so = read_all_fd(fdstdin, buf, sizeof(buf)-1, &got_all);
  if (got_all <= 0) DIE("Missing data");
  buf[got_all] = 0;
  
  D("Decoding %d chars, n_iter(%d)\n", got_all, n_iter);

  cf = zxid_new_conf_to_cf("PATH=/var/sfis/");

  for (; n_iter; --n_iter) {
    r = zx_dec_zx_root(cf->ctx, got_all, buf, "fin test");  /* *** n_decode=1000 */
    if (!r)
      DIE("Decode failure");
    
    if (!r->Assertion)
      DIE("No assertion in input");
    
    ses->sigres = ZXSIG_NO_SIG;
    ret = zxid_sp_sso_finalize(cf, &cgi, &ses, r->Assertion);
    D("sso_finalize=%d", ret);

    zx_FREE_root(cf->ctx, r, 0);
  }
  return 0;
}

/* EOF  --  zxidssofinalizetest.c */
