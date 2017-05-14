/* zxididp.c  -  CGI binary for SAML 2 IdP
 * Copyright (c) 2012-2013 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2008-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxididp.c,v 1.9 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.11.2008, created --Sampo
 * 24.8.2009,  perfected for TAS3 workshop --Sampo
 * 13.12.2011, added  VPATH and VURL --Sampo
 *
 * See zxid_idp_dispatch() in zxididpx.c for most interesting parts of IdP implementation.
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           README-zxid, section 10 "zxid_simple() API"
 */

#include <zx/platform.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <malloc.h>

#include <zx/errmac.h>
#include <zx/zxid.h>      /* ZXID main API, including zxid_simple(). */
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/c/zxidvers.h>

char* help =
"zxididp  -  SAML 2.0 IdP CGI (also DI, AS, IM, and PS) - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2012-2013 Synergetics NV (sampo@synergetics.be), All Rights Reserved.\n\
Copyright (c) 2008-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxididp [options]   (when used as CGI, no options can be supplied)\n\
  -h               This help message\n\
  --               End of options\n";

/* ============== M A I N ============== */

/* CONFIG: You must have created /var/zxid OR c:/var/zxid directory hierarchy. See `make dir' */
/* CONFIG: You must edit the URL to match your domain name and port */

#ifdef MINGW
#define CONF "URL=https://idp1.zxidp.org:8443/zxididp&SES_COOKIE_NAME=ZXIDPSES&IDP_ENA=1&PDP_ENA=1&PATH=c:/var/zxid/idp"
#else
/*#define CONF "URL=https://idp1.zxidp.org:8443/zxididp&NICE_NAME=ZXIdP&NOSIG_FATAL=0&SES_COOKIE_NAME=ZXIDPSES&IDP_ENA=1&PDP_ENA=1&PATH=/var/zxid/idp"*/
//#define CONF "IDP_ENA=1&VPATH=%h/&VURL=%a%h%s"
//#define CONF "IDP_ENA=1&PATH=/var/zxid/idp&VPATH=/var/zxid/%h/&VURL=%a%h%s"
#define CONF "IDP_ENA=1"
#endif

/* Called by: */
int main(int argc, char** argv)
{
  char* p;
  char* sid;
  char* nid;
  char* res;
  char* setcookie;

#ifdef _GNU_SOURCE
  if (getenv("MALLOC_TRACE"))
    mtrace();
#endif

#if 0
  /* Allocate and realase memory to cause malloc to grab bigger mmap page */
  /* Apparently this trick does not work - perhaps memory allocation
     is sorted by page size or something. --Sampo */
#ifndef ZXIDIDP_PREALLOC_KB
#define ZXIDIDP_PREALLOC_KB 300
#endif
  free(malloc(ZXIDIDP_PREALLOC_KB*1024));
  mallopt(M_CHECK_ACTION,3); /* core on bad free(3) */
#endif

#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  /* Reopen stderr only in mini_httpd case */
  //p = getenv("SERVER_SOFTWARE");
  //if (p && !memcmp(p, "mini_httpd", sizeof("mini_httpd")-1)) {
    close(2);
    if (open("/var/tmp/zxid.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666) != 2) {
      perror("/var/tmp/zxid.stderr");
      exit(2);
    }
    //}
  /*errmac_debug = 1;*/
  fprintf(stderr, CC_PURY("=================== Running zxididp %s =================== %x p%d qs(%s)\n"), ZXID_REL, errmac_debug, getpid(), getenv("QUERY_STRING"));
  p = getenv(ZXID_ENV_PREFIX "PRE_CONF");
  D(ZXID_ENV_PREFIX "PRE_CONF(%s)", p);
  //fprintf(stderr, "p(%s)\n", p);
#endif

  if (argc > 1) {
    fprintf(stderr, "This is a CGI script (written in C). No arguments are accepted.\n%s", help);
    exit(1);
  }

#if 1
  strncpy(errmac_instance, CC_PURY("\tidp"), sizeof(errmac_instance));
#else
  strncpy(errmac_instance, "\tidp", sizeof(errmac_instance));
#endif

  res = zxid_simple(CONF, 0, 0x0fff);  /* 0xfff == full CGI automation */
  switch (res[0]) {
  default:
    ERR("Unknown zxid_simple() response(%s)", res);
  case 'd': break; /* Logged in case */
  }

  /* Parse the LDIF to figure out session ID and the federated ID */

  sid = strstr(res, "sesid: ");
  nid = strstr(res, "idpnid: ");
  setcookie = strstr(res, "setcookie: ");
  if (sid) {
    sid += sizeof("sesid: ") - 1;
    p = strchr(sid, '\n');
    if (p)
      *p = 0;  /* nul termination */
  }
  if (nid) {
    nid += sizeof("idpnid: ") - 1;
    p = strchr(nid, '\n');
    if (p)
      *p = 0;  /* nul termination */
  }
  if (setcookie) {
    setcookie += sizeof("setcookie: ") - 1;
    p = strchr(setcookie, '\n');
    if (p)
      *p = 0;  /* nul termination */
  }
  
  /* Render protected content page. Usually you would be redirected back to SP. */
  
  if (setcookie && !ONE_OF_2(*setcookie, '-', 0))
    printf("SET-COOKIE: %s\r\n", setcookie);
  printf("Content-Type: text/html\r\n\r\n");
  printf("<title>ZXID IdP Mgmt</title>" ZXID_BODY_TAG "<h1>ZXID IdP Management (user logged in, session active)</h1><pre>\n");
  printf("</pre><form method=post action=\"?o=P\">");
  //if (err) printf("<p><font color=red><i>%s</i></font></p>\n", err);
  //if (msg) printf("<p><i>%s</i></p>\n", msg);
  if (sid) {
    printf("<input type=hidden name=s value=\"%s\">", sid);
    printf("<input type=submit name=gl value=\" Local Logout \">\n");
    printf("<input type=submit name=gr value=\" Single Logout (Redir) \">\n");
    printf("<input type=submit name=gs value=\" Single Logout (SOAP) \">\n");
    printf("<input type=submit name=gt value=\" Defederate (Redir) \">\n");
    printf("<input type=submit name=gu value=\" Defederate (SOAP) \"><br>\n");
    printf("sid(%s) nid(%s) <a href=\"?s=%s\">Reload</a>", sid, nid?nid:"?!?", sid);
  }
  
  printf("</form><hr>");
  printf("<a href=\"http://zxid.org/\">zxid.org</a>, %s", zxid_version_str());
  return 0;
}

/* EOF  --  zxididp.c */
