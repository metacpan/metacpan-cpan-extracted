/* zxidsimple.c  -  Shell script helper CGI binary for SAML 2 SP
 * Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidsimple.c,v 1.7 2007-06-21 23:32:32 sampo Exp $
 *
 * 16.1.2007, created --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           README-zxid, section 10 "zxid_simple() API"
 *           zxidhlo.sh
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <zx/zxid.h>
#include <zx/c/zxidvers.h>

char* help =
"zxidsimple  -  SAML 2.0 SP CGI - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Sinlg Sign-On.\n\
Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidsimple [options] -o ldif CONF AUTO_FLAGS <cgi-input\n\
  -o ldif    In the successful login case LDIF fragment with SSO attributes\n\
             is written to specified file.\n\
  CONF       Configuration string such as\n\
               \"PATH=/var/zxid/&URL=https://sp1.zxidsp.org:8443/zxidhlo.sh\"\n\
  AUTO_FLAGS Usually 255 for full autmation\n\
  cgi-input  The stdin should contain CGI input or /dev/null. The latter\n\
             case causes $QUERY_STRING to be automatically consulted.\n\
  -h         This help message\n\
  --         End of options\n\
Exit value: 0 means successful SSO (the ldif file was written), shell script\n\
              should show protected page\n\
            1 means protocol interaction was output. Shell script should exit.\n\
            other exit values are errors.\n";

/* ============== M A I N ============== */

/* Called by: */
int main(int argc, char** argv)
{
  FILE* f;
  char* out = 0;
  char* res;
  int auto_flags;
  --argc; ++argv;
  if (argc == 4 && argv[0][0] == '-' && argv[0][1] == 'o') {
    out = argv[1];
    argc -= 2;
    argv += 2;
  }
  if (argc != 2 || argv[1][0] == '-') { fprintf(stderr, "%s", help); exit(3); }

  auto_flags = atoi(argv[1]);
  auto_flags &= ~ZXID_AUTO_EXIT;
  res = zxid_simple(argv[0], 0, auto_flags);
  if (res && res[0] == 'd') {
    if (out) {
      f = fopen(out, "w");
      if (!f) {
	perror("-o specified LDIF file");
	exit(2);
      }
      fprintf(f, "%s", res);
      fclose(f);
    }
    exit(0);
  }
  printf("%s", res);
  return 1;
}

/* EOF  --  zxidsimple.c */
