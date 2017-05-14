/* zxidhlo.c  -  Hello World CGI binary for SAML 2 SP
 * Copyright (c) 2012 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidhlo.c,v 1.16 2009-08-30 15:09:26 sampo Exp $
 *
 * 16.1.2007, created --Sampo
 * 28.2.2011, added attribute dump --Sampo
 * 13.12.2011, added VPATH and VURL specs --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           README-zxid, section 10 "zxid_simple() API"
 *
 * make zxidhlo CDEF="-DZX_CONF='\"URL=http://sp1.zxid.org/demohlo&NICE_NAME=ZXID SP Hello\"'"
 * cp zxidhlo /var/zxid/webroot/demohlo
 */

#include <zx/platform.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <zx/errmac.h>
#include <zx/zxid.h>      /* ZXID main API, including zxid_simple(). */
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/c/zxidvers.h>

char* help =
"zxidhlo  -  SAML 2.0 SP CGI - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2012 Synergetics SA (sampo@synergetics.be), All Rights Reserved.\n\
Copyright (c) 2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidhlo [options]   (when used as CGI, no options can be supplied)\n\
  -h               This help message\n\
  --               End of options\n";

/* ============== M A I N ============== */

/* CONFIG: You must have created /var/zxid directory hierarchy. See `make dir' */
/* CONFIG: You must edit the URL to match your domain name and port */

#define ZXIDHLO "zxidhlo"
//#define ZX_CONF "PATH=/var/zxid/&URL=http://sp1.zxid.org/demohlo"
#ifndef ZX_CONF
//#define ZX_CONF "VPATH=%h/&VURL=%a%h%s&NOSIG_FATAL=0&DUP_A7N_FATAL=0&DUP_MSG_FATAL=0&OUTMAP=$*$$$;$IdPSesID$unsb64-inf$IdPsesid$;$testa7nsb64$unsb64$$;$testfeide$feidedec$$;$testfilefeide$del$$"
#define ZX_CONF "NOSIG_FATAL=0&DUP_A7N_FATAL=0&DUP_MSG_FATAL=0&OUTMAP=$*$$$;$IdPSesID$unsb64-inf$IdPsesid$;$testa7nsb64$unsb64$$;$testfeide$feidedec$$;$testfilefeide$del$$"
#endif
//#define ZX_CONF "URL=https://sp1.zxidsp.org:8443/" ZXIDHLO "&NOSIG_FATAL=0&PATH=/var/zxid/"
//#define ZX_CONF "URL=https://lima.tas3.eu:8443/" ZXIDHLO "&NOSIG_FATAL=0&PATH=/var/zxid/"

/* Called by: */
int main(int argc, char** argv)
{
  char* res;
  char* p;
  char* q;
  char sid[192];
  char nid[ZXID_MAX_EID];
  char setcookie[256];

#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  /* Reopen stderr only in mini_httpd case */
  //p = getenv("SERVER_SOFTWARE");
  //if (p && (!memcmp(p, "mini_httpd", sizeof("mini_httpd")-1)||!memcmp(p, "zxid_httpd", sizeof("zxid_httpd")-1))) {
    close(2);
    if (open("/var/tmp/zxid.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666) != 2) {
      perror("/var/tmp/zxid.stderr");
      exit(2);
    }
  //}
  fprintf(stderr, "=================== Running " ZXIDHLO " ===================\n");
#endif

  if (argc > 1) {
    fprintf(stderr, "This is a CGI script (written in C). No arguments are accepted.\n%s", help);
    exit(1);
  }
  
  res = zxid_simple(ZX_CONF, 0, 0x0fff);  /* 0xfff == full CGI automation */
  switch (res[0]) {
  default:
    ERR("Unknown zxid_simple() response(%s)", res);
  case 'd': break; /* Logged in case */
  }

  /* Parse the LDIF to figure out session ID and the federated ID */

  p = strstr(res, "sesid: ");
  if (p) {
    p += sizeof("sesid: ")-1;
    q = strchr(p, '\n');
    if (q) {
      memcpy(sid, p, MIN(q-p, sizeof(sid)-1));
      sid[MIN(q-p, sizeof(sid)-1)] = 0;
      D("sid(%s)",sid);
    } else {
      strncpy(sid, p, sizeof(sid));
      sid[sizeof(sid)-1] = 0;
      D("sid(%s)",sid);
    }
  } else
    sid[0] = 0;

  p = strstr(res, "idpnid: ");
  if (p) {
    p += sizeof("idpnid: ")-1;
    q = strchr(p, '\n');
    if (q) {
      memcpy(nid, p, MIN(q-p, sizeof(nid)-1));
      nid[MIN(q-p, sizeof(nid)-1)] = 0;
      D("nid(%s)",nid);
    } else {
      strncpy(nid, p, sizeof(nid));
      nid[sizeof(nid)-1] = 0;
      D("nid(%s)",nid);
    }
  } else
    nid[0] = 0;

  p = strstr(res, "setcookie: ");
  if (p) {
    p += sizeof("setcookie: ")-1;
    q = strchr(p, '\n');
    if (q) {
      memcpy(setcookie, p, MIN(q-p, sizeof(setcookie)-1));
      setcookie[MIN(q-p, sizeof(setcookie)-1)] = 0;
      D("setcookie(%s)",setcookie);
    } else {
      strncpy(setcookie, p, sizeof(setcookie));
      setcookie[sizeof(setcookie)-1] = 0;
      D("setcookie(%s)",setcookie);
    }
  } else
    setcookie[0] = 0;
  
  /* Render protected content page. You should replace this
   * with your own content, or establishment of your own session
   * and then redirection to your own content. Whatever makes sense. */
  
  if (!ONE_OF_2(*setcookie, '-', 0))
    printf("SET-COOKIE: %s\r\n", setcookie);
  printf("Content-Type: text/html\r\n\r\n");
  printf("<title>ZXID HELLO SP Mgmt</title>" ZXID_BODY_TAG "<h1>ZXID HELLO SP Management (user logged in, session active)</h1><pre>\n");
  printf("</pre><form method=post action=\"?o=P\">");
  //if (err) printf("<p><font color=red><i>%s</i></font></p>\n", err);
  //if (msg) printf("<p><i>%s</i></p>\n", msg);
  if (*sid) {
    printf("<input type=hidden name=s value=\"%s\">", sid);
    printf("<input type=submit name=gl value=\" Local Logout \">\n");
    printf("<input type=submit name=gr value=\" Single Logout (Redir) \">\n");
    printf("<input type=submit name=gs value=\" Single Logout (SOAP) \">\n");
    printf("<input type=submit name=gt value=\" Defederate (Redir) \">\n");
    printf("<input type=submit name=gu value=\" Defederate (SOAP) \"><br>\n");
    printf("sid(%s) nid(%s) <a href=\"?s=%s\">Reload</a> | "
	   "<a href=\"?o=v&s=%s\">PEP</a>", sid, *nid?nid:"?!?", sid, sid);
  } else {
    printf("<p>No session established.\n");
  }
  
  printf("</form><hr>\n");
  printf("<pre>%s</pre>\n<hr>\n", res);
  printf("<a href=\"http://zxid.org/\">zxid.org</a>, %s", zxid_version_str());
  return 0;
}

/* EOF  --  zxidhlo.c */
