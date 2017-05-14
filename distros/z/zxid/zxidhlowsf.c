/* zxidhlowsf.c  -  Hello World CGI binary for SAML 2 SP and ID_WSF
 * Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidhlowsf.c,v 1.16 2010-01-08 02:10:09 sampo Exp $
 *
 * 25.1.2007, created --Sampo
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

#include <zx/errmac.h>
#include <zx/zxid.h>      /* ZXID main API, including zxid_simple(). */
#include <zx/zxidpriv.h>
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/wsf.h>
#include <zx/c/zxidvers.h>
#include <zx/c/zx-e-data.h>

char* help =
"zxidhlowsf  -  SAML 2.0 SP + WSC CGI - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidhlowsf [options]   (when used as CGI, no options can be supplied)\n\
  -h               This help message\n\
  --               End of options\n";


/* ============== M A I N ============== */

#if 1
#define ZXIDHLO "zxidhlowsf"
#define CONF "PATH=/var/zxid/&URL=https://sp1.zxidsp.org:8443/" ZXIDHLO
#else
#define ZXIDHLO "zxidhlowsf"
#define CONF "PATH=/var/zxid/&URL=https://sampo:8443/" ZXIDHLO
#endif

/* Called by: */
int main(int argc, char** argv)
{
  zxid_conf* cf;
  zxid_ses sess;
  zxid_ses* ses;
  //struct zx_root_s* r;
  struct zx_e_Envelope_s* env;
  zxid_epr* epr;
  char* p;
  char* sid;
  char* nid;
  char* res;
  char* qs;
  //char* hrxml_resp = 0;

  qs = getenv("QUERY_STRING");
  qs = strdup(qs);

#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  close(2);
  if (open("tmp/zxid.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666) != 2)
    exit(2);
  fprintf(stderr, "=================== Running ===================\n");
#endif

  if (argc > 1) {
    fprintf(stderr, "This is a CGI script (written in C). No arguments are accepted.\n%s", help);
    exit(1);
  }
  cf = zxid_new_conf_to_cf(CONF);
  
  res = zxid_simple_cf(cf, 0, 0, 0, 0x1fff);
  switch (res[0]) {
  default:
    ERR("Unknown zxid_simple() response(%s)", res);
  case 'd': break; /* Logged in case */
  }

  /* Parse the LDIF to figure out session ID and the federated ID */

  sid = strstr(res, "sesid: ");
  nid = strstr(res, "idpnid: ");
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

  /* Discover ID-DAP (call discovery service using bootstrap) */
  
  ses = &sess;
  zxid_get_ses(cf, ses, sid);
  env = zx_NEW_e_Envelope(cf->ctx,0);
  env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
  env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
  env->Body->Query = zxid_mk_di_query(cf, &env->Body->gg, XMLNS_DAP, 0,0,0);
  epr = zxid_find_epr(cf, ses, XMLNS_DISCO_2_0, 0,0,0, 1);
  env = zxid_wsc_call(cf, ses, epr, env, 0);

#if 0
  /* Call ID-DAP */
  
  r = zxid_wsc_call(cf, ses, res->epr, body);
#endif

  /* Render protected content page. You should replace this
   * with your own content, or establishment of your own session
   * and then redirection to your own content. Whatever makes sense. */
  
  printf("Content-Type: text/html\r\n\r\n");
  printf("<title>ZXID HELLO SP Mgmt</title>" ZXID_BODY_TAG "<h1>ZXID HELLO SP Management (user logged in, session active)</h1><pre>\n");
  printf("</pre><form method=post action=\"" ZXIDHLO "?o=P\">");
  //if (err) printf("<p><font color=red><i>%s</i></font></p>\n", err);
  //if (msg) printf("<p><i>%s</i></p>\n", msg);
  if (sid) {
    printf("<input type=hidden name=s value=\"%s\">", sid);
    printf("<input type=submit name=gl value=\" Local Logout \">\n");
    printf("<input type=submit name=gr value=\" Single Logout (Redir) \">\n");
    printf("<input type=submit name=gs value=\" Single Logout (SOAP) \">\n");
    printf("<input type=submit name=gt value=\" Defederate (Redir) \">\n");
    printf("<input type=submit name=gu value=\" Defederate (SOAP) \"><br>\n");
    printf("sid(%s) nid(%s) <a href=\"" ZXIDHLO "?s=%s\">Reload</a>", sid, nid?nid:"?!?", sid);
  }
  
  printf("</form><hr>");
  printf("<a href=\"http://zxid.org/\">zxid.org</a>, %s", zxid_version_str());
  return 0;
}

/* EOF  --  zxidhlowsf.c */
