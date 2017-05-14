/* zxidhrxmlwsc.c  -  ID-SIS HR-XML WSC
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidhrxmlwsc.c,v 1.12 2009-11-29 12:23:06 sampo Exp $
 *
 * 19.6.2007, created --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           README-zxid, section 10 "zxid_simple() API"
 */

#include "platform.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <zx/errmac.h>
#include <zx/zxid.h>      /* ZXID main API, including zxid_simple(). */
#include <zx/zxidpriv.h>
#include <zx/zxidutil.h>
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/wsf.h>
#include <zx/c/zxidvers.h>
#include <zx/c/zx-ns.h>
#include <zx/c/zx-e-data.h>

char* help =
"zxidhrxmlwsc  -  SAML 2.0 SP + WSC CGI - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidhrxmlwsc [options]   (when used as CGI, no options can be supplied)\n\
  -h               This help message\n\
  --               End of options\n";

#define HRXMLOP_CREATE 1
#define HRXMLOP_QUERY  2
#define HRXMLOP_MODIFY 3
#define HRXMLOP_DELETE 4

struct hrxml_cgi {
  int op;
  char* select;
  char* data;
};

/* Called by:  main */
int hrxml_parse_cgi(struct hrxml_cgi* cgi, char* qs)
{
  char *n, *v;
  D("START qs(%s)", qs);
  while (qs && *qs) {
    qs = zxid_qs_nv_scan(qs, &n, &v, 1);
    if (!n)
      n = "NULL_NAME_ERRX";

    
    printf("<input name=hrxmlselect value=\"\"><br>\n");
    printf("<p>HR-XML Data<br><textarea name=hrxmldata cols=100 rows=5>%.*s</textarea>\n", 0, "");

    switch (n[0]) {
    case 'h':
      if (!strcmp(n, "hrxmlcreate")) {	cgi->op = HRXMLOP_CREATE;	break;      }
      if (!strcmp(n, "hrxmlquery")) {	cgi->op = HRXMLOP_QUERY;	break;      }
      if (!strcmp(n, "hrxmlmodify")) {	cgi->op = HRXMLOP_MODIFY;	break;      }
      if (!strcmp(n, "hrxmldelete")) {	cgi->op = HRXMLOP_DELETE;	break;      }
      if (!strcmp(n, "hrxmlselect")) {	cgi->select = v;	break;      }
      if (!strcmp(n, "hrxmldata")) {	cgi->data = v;	break;      }
      /* fall thru */
    default:  break; //D("Unknown CGI field(%s) val(%s)", n, v);
    }
  }
  //D("END cgi=%p cgi->eid=%p eid(%s) op(%c) magic=%x", cgi, cgi->eid,cgi->eid, cgi->op, cgi->magic);
  return 0;
}

/* ============== M A I N ============== */

#define ZXIDHLO "zxidhrxmlwsc"
#define CONF "PATH=/var/zxid/"

/* Called by: */
int main(int argc, char** argv)
{
  struct zx_ctx ctx;
  zxid_conf cfs;
  struct hrxml_cgi cgi;
  zxid_conf* cf;
  zxid_ses sess;
  zxid_ses* ses;
  struct zx_root_s* r;
  struct zx_e_Envelope_s* env = 0;
  zxid_epr* epr;
  struct zx_str* ss;
  char* p;
  char* sid;
  char* nid;
  char* res;
  char* hrxml_resp = 0;
  char* qs;
  char* qs2;
  char buf[64*1024];
  char urlbuf[256];
  int got, cl=0;

  qs = getenv("CONTENT_LENGTH");
  if (qs)
    sscanf(qs, "%d", &cl);

  if (cl) {
    read_all_fd(fdstdin, buf, MIN(cl, sizeof(buf)-1), &got);
    buf[got] = 0;
    qs2 = buf;
  } else {
    qs2 = getenv("QUERY_STRING");
    if (!qs2)
      qs2 = "";
    cl = strlen(qs2);
  }
  qs = strdup(qs2);
#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  close(2);
  if (open("tmp/zxid.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666) != 2)
    exit(2);
  fprintf(stderr, "=================== Running ===================\n");
  errmac_debug = 1;
#endif

  if (argc > 1) {
    fprintf(stderr, "This is a CGI script (written in C). No arguments are accepted.\n%s", help);
    exit(1);
  }

#if 1
  zx_reset_ctx(&ctx);
  ZERO(&cfs, sizeof(cfs));
  cfs.ctx = &ctx;
  cf = &cfs;
  zxid_conf_to_cf_len(cf, -1, CONF);
#else
  cf = zxid_new_conf_to_cf(CONF);
#endif
  
  /* Dynamic construction of URL configuration parameter */

#if 0  
#define PROTO_STR "https://"
#else
#define PROTO_STR "http://"
#endif

  strcpy(urlbuf, PROTO_STR);
  p = urlbuf + sizeof(PROTO_STR)-1;
  res = getenv("HTTP_HOST");
  strcpy(p, res);
  p+=strlen(res);
  res = getenv("SCRIPT_NAME");
  strcpy(p, res);
  p+=strlen(res);
  if (p > urlbuf + sizeof(urlbuf))
    exit(1);
  zxid_url_set(cf, urlbuf);

  res = zxid_simple_cf(cf, cl, qs2, 0, 0x1fff);
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

  DD("HERE qs(%s)", qs);
  ZERO(&cgi, sizeof(cgi));
  hrxml_parse_cgi(&cgi, qs);  
  
  ses = &sess;
  zxid_get_ses(cf, ses, sid);

  D("HERE cgi.op=%d qs(%s) sid(%s)", cgi.op, qs, sid);
  
  switch (cgi.op) {

  case HRXMLOP_CREATE:
    D("Here %d", 0);
    epr = zxid_get_epr(cf, ses, zx_xmlns_idhrxml, 0, 0, 0, 1);
    if (!epr) {
      ERR("EPR could not be discovered %d", 0);
      break;
    }
    D("Here %p", epr);

    env = zx_NEW_e_Envelope(cf->ctx,0);
    env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
    env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
    env->Body->idhrxml_Create = zx_NEW_idhrxml_Create(cf->ctx, &env->Body->gg);
    env->Body->idhrxml_Create->CreateItem = zx_NEW_idhrxml_CreateItem(cf->ctx, &env->Body->idhrxml_Create->gg);
    env->Body->idhrxml_Create->CreateItem->NewData = zx_NEW_idhrxml_NewData(cf->ctx, &env->Body->idhrxml_Create->CreateItem->gg);
    
    /* Parse the XML from the form field into data structure and include it as NewData. */
    
    r = zx_dec_zx_root(cf->ctx, strlen(cgi.data), cgi.data, "hrxml wsc");
    if (!r || !r->Candidate) {
      ERR("No hrxml:Candidate tag found in form field hrxmldata(%s)", cgi.data);
      hrxml_resp = "No hrxml:Candidate tag found in form field hrxmldata.";
      break;
    }
    env->Body->idhrxml_Create->CreateItem->NewData->Candidate = r->Candidate;
    
    D("Here %p", epr);
    env = zxid_wsc_call(cf, ses, epr, env, 0);
    if (!env || env == (void*)ZXID_REDIR_OK || !env->Body) {
      ERR("Web services call failed %p", env);
      break;
    }
    D("Here %p", epr);
    if (!env->Body->idhrxml_CreateResponse) {
      ERR("There was no result %p", env->Body);
      break;
    }
    if (!memcmp(env->Body->idhrxml_CreateResponse->Status->code->g.s, "OK", 2)) {
      hrxml_resp = "Create OK.";
    } else {
      hrxml_resp = "Create Failed.";
      D("Non OK status(%.*s)", env->Body->idhrxml_CreateResponse->Status->code->g.len, env->Body->idhrxml_CreateResponse->Status->code->g.s);
    }
    D("Here %p", epr);
    break;

  case HRXMLOP_QUERY:
    epr = zxid_get_epr(cf, ses, zx_xmlns_idhrxml, 0, 0, 0, 1);
    if (!epr) {
      ERR("EPR could not be discovered %d", 0);
      break;
    }
    env = zx_NEW_e_Envelope(cf->ctx,0);
    env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
    env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
    env->Body->idhrxml_Query = zx_NEW_idhrxml_Query(cf->ctx, &env->Body->gg);
    env->Body->idhrxml_Query->QueryItem = zx_NEW_idhrxml_QueryItem(cf->ctx, &env->Body->idhrxml_Query->gg);
    env->Body->idhrxml_Query->QueryItem->Select
      = zx_ref_elem(cf->ctx, &env->Body->idhrxml_Query->QueryItem->gg, zx_idhrxml_Select_ELEM, cgi.select);
        
    env = zxid_wsc_call(cf, ses, epr, env, 0);
    D("HERE env=%p", env);
    if (!env || env == (void*)ZXID_REDIR_OK || !env->Body) {
      ERR("Web services call failed %d", 0);
      break;
    }
    if (!env->Body->idhrxml_QueryResponse) {
      ERR("There was no result %p", env->Body);
      break;
    }
    if (!memcmp(env->Body->idhrxml_QueryResponse->Status->code->g.s, "OK", 2)) {
      if (!env->Body->idhrxml_QueryResponse->Data) {
	hrxml_resp = "No data in otherwise successful response.";
	ERR("There was no data %p", env->Body);
	break;
      }
      if (!env->Body->idhrxml_QueryResponse->Data->Candidate) {
	hrxml_resp = "No Candidate in otherwise successful response.";
	ERR("There was no candidate %p", env->Body);
	break;
      }
      ss = zx_easy_enc_elem_opt(cf, &env->Body->idhrxml_QueryResponse->Data->Candidate->gg);
      hrxml_resp = ss->s;
    } else {
      hrxml_resp = "Query Failed.";
      D("Non OK status(%.*s)", env->Body->idhrxml_QueryResponse->Status->code->g.len, env->Body->idhrxml_QueryResponse->Status->code->g.s);
    }
    break;

  case HRXMLOP_MODIFY:
    ss = zxid_callf(cf, ses, zx_xmlns_idhrxml, 0, 0, 0, "<idhrxml:Modify><idhrxml:ModifyItem><idhrxml:Select>%s</idhrxml:Select><idhrxml:NewData>%s</idhrxml:NewData></idhrxml:ModifyItem></idhrxml:Modify>", cgi.select, cgi.data);
    //ZXID_CHK_STATUS(env, idhrxml_ModifyResponse, hrxml_resp = "Modify failed"; break);
    //hrxml_resp = "Modify OK";
    hrxml_resp = ss->s;
    break;

  case HRXMLOP_DELETE:
    epr = zxid_get_epr(cf, ses, zx_xmlns_idhrxml, 0, 0, 0, 1);
    if (!epr) {
      ERR("EPR could not be discovered %d", 0);
      break;
    }
    //env = zxid_new_envf(cf, "<idhrxml:Delete><idhrxml:DeleteItem><idhrxml:Select>%s</idhrxml:Select></idhrxml:DeleteItem></idhrxml:Delete>", cgi.select);
    env = zxid_wsc_call(cf, ses, epr, env, 0);
    D("HERE env=%p", env);
    if (!env || env == (void*)ZXID_REDIR_OK || !env->Body) {
      ERR("Web services call failed %p", env);
      break;
    }
    if (!env->Body->idhrxml_DeleteResponse) {
      ERR("There was no result %p", env->Body);
      break;
    }
    if (!memcmp(env->Body->idhrxml_DeleteResponse->Status->code->g.s, "OK", 2)) {
      hrxml_resp = "Delete OK.";
    } else {
      hrxml_resp = "Delete Failed.";
      D("Non OK status(%.*s)", env->Body->idhrxml_DeleteResponse->Status->code->g.len, env->Body->idhrxml_DeleteResponse->Status->code->g.s);
    }
    break;
  }
  
  /* Render protected content page. You should replace this
   * with your own content, or establishment of your own session
   * and then redirect to your own content. Whatever makes sense. */
  
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
    printf("<hr><h1>ID-SIS HR-XML Client</h1>\n");
    printf("<input type=submit name=hrxmlcreate value=\" Create \"><br>\n");
    printf("<input type=submit name=hrxmlquery value=\" Query \">\n");
    printf(" Select: <input name=hrxmlselect value=\"\"><br>\n");
    printf("<input type=submit name=hrxmlmodify value=\" Modify \"><br>\n");
    printf("<input type=submit name=hrxmldelete value=\" Delete \"><br>\n");
    printf("<p>HR-XML Data<br><textarea name=hrxmldata cols=100 rows=5>%s</textarea>\n",
	   "<hrxml:Candidate xmlns:hrxml=\"http://ns.hr-xml.org/2007-04-15\"></hrxml:Candidate>");

    printf("<p>HR-XML Response<br><textarea name=hrxmlresp cols=100 rows=5>%s</textarea>\n",
	   hrxml_resp?hrxml_resp:"");
  }
  
  printf("</form><hr>\n");
  printf("<a href=\"http://zxid.org/\">zxid.org</a>, %s", zxid_version_str());
  return 0;
}

/* EOF  --  zxidhlowsf.c */
