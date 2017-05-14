/* zxidhrxmlwsp.c  -  ID-SIS HR-XML WSP
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidhrxmlwsp.c,v 1.14 2009-11-29 12:23:06 sampo Exp $
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
#include <zx/zxidutil.h>
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/wsf.h>
#include <zx/c/zxidvers.h>
#include <zx/c/zx-ns.h>
#include <zx/c/zx-data.h>

char* help =
"zxidhrxmlwsp  -  SAML 2.0 WSP CGI - R" ZXID_REL "\n\
SAML 2.0 is a standard for federated identity and Single Sign-On.\n\
Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidhrxmlwsp [options]   (when used as CGI, no options can be supplied)\n\
  -h               This help message\n\
  --               End of options\n";

/* ============== M A I N ============== */

#define ZXIDHLO "zxidhrxmlwsp"
#define CONF "PATH=/var/zxid/"

/* Called by: */
int main(int argc, char** argv)
{
  struct zx_ctx ctx;
  zxid_conf cfs;
  zxid_conf* cf;
  zxid_ses sess;
  zxid_ses* ses = &sess;
  struct zx_root_s* r;
  //struct zx_e_Envelope_s* env;
  //zxid_epr* epr;
  struct zx_str* ss;
  //char* sid;
  char* nid;
  char* p;
  char* res;
  char buf[256*1024];  /* *** should figure the size dynamically */
  char urlbuf[256];
  int got, cl=0;
  fdtype fd;
  char* qs;
  char* qs2;
  ZERO(ses, sizeof(zxid_ses));
  
#if 1
  /* Helps debugging CGI scripts if you see stderr. */
  close(2);
  if (open("/var/tmp/zxid.stderr", O_WRONLY | O_CREAT | O_APPEND, 0666) != 2)
    exit(2);
  fprintf(stderr, "=================== Running idhrxml wsp ===================\n");
  errmac_debug = 2;
#endif
#if 1
  strncpy(errmac_instance, "\t\e[45mhrxml_wsp\e[0m", sizeof(errmac_instance));
#else
  strncpy(errmac_instance, "\thrxml_wsp", sizeof(errmac_instance));
#endif

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
  D_XML_BLOB(0, "HRXML IN", -2, qs);

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
  if (res) {
    strcpy(p, res);
    p+=strlen(res);
  }
  res = getenv("SCRIPT_NAME");
  if (res) {
    strcpy(p, res);
    p+=strlen(res);
  }
  if (p > urlbuf + sizeof(urlbuf))
    exit(1);
  zxid_url_set(cf, urlbuf);

  //if (!memcmp(qs+cl-4, "?o=B", 4)) {
  if (!memcmp(qs, "o=B", 3)) {
    D("Metadata qs(%s)", qs);
    //cf = zxid_new_conf_to_cf(CONF);
    
    res = zxid_simple_cf(cf, cl, qs, 0, 0x1fff);
    switch (res[0]) {
    default:
      ERR("Unknown zxid_simple() response(%s)", res);
    case 'd': break; /* Logged in case */
    }
    ERR("Not a metadata qs(%s)",qs);
    exit(1);
  }

  nid = zxid_wsp_validate(cf, ses, 0, buf);
  if (!nid) {
    DD("Request validation failed buf(%.*s)", got, buf);
    ERR("Request validation failed len=%d", got);
    ss = zxid_wsp_decorate(cf, ses, 0, "<Response><lu:Status code=\"INV\" comment=\"Request validation failed. Replay?\"></lu:Status></Response>");
    DD("ss(%.*s)", ss->len, ss->s);
    printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
    exit(1);
  }
  D("Target nid(%s)", nid);
    
  r = zx_dec_zx_root(cf->ctx, cl, qs2, "hrxml wsp");

  DD("Decoded nid(%s)", nid);
  
  if (!r || !r->Envelope) {
    ERR("No SOAP Envelope found buf(%.*s)", got, buf);
    exit(1);
  }
  if (!r->Envelope->Body) {
    ERR("No SOAP Body found buf(%.*s)", got, buf);
    exit(1);
  }

  if (r->Envelope->Body->idhrxml_Create) {
    D("Create %d",0);
    if (!r->Envelope->Body->idhrxml_Create->CreateItem) {
      ERR("No CreateItem found buf(%.*s)", got, buf);
      exit(1);
    }

    if (!r->Envelope->Body->idhrxml_Create->CreateItem->NewData) {
      ERR("No NewData found buf(%.*s)", got, buf);
      exit(1);
    }
    
    if (!r->Envelope->Body->idhrxml_Create->CreateItem->NewData->Candidate) {
      ERR("No Candidate found buf(%.*s)", got, buf);
#if 0
      env = ZXID_RESP_ENV(cf, "idhrxml:CreateResponse", "Fail", "NewData does not contain Candidate element.");
      ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
      ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:CreateResponse><lu:Status code=\"Fail\" comment=\"NewData does not contain Candidate element.\"></lu:Status></idhrxml:CreateResponse>");
#endif
      printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
      return 0;
    }
    
    ss = zx_easy_enc_elem_opt(cf, &r->Envelope->Body->idhrxml_Create->CreateItem->NewData->Candidate->gg);

    fd = open_fd_from_path(O_CREAT|O_WRONLY|O_TRUNC, 0666, "create", 1, "%shrxml/cv.xml", cf->cpath);
    write_all_fd(fd, ss->s, ss->len);
    close_file(fd, (const char*)__FUNCTION__);

#if 0
    env = ZXID_RESP_ENV(cf, "idhrxml:CreateResponse", "OK", "Fine");
    D("HERE(%p)", env);
    ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
    D("HERE(%p)", ss);
#else
    ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:CreateResponse><lu:Status code=\"OK\" comment=\"Fine\"></lu:Status></idhrxml:CreateResponse>");
#endif
    printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
    D("ss(%.*s)", ss->len, ss->s);
    return 0;
  }
  
  if (r->Envelope->Body->idhrxml_Query) {
    D("Query %d",0);
    if (!r->Envelope->Body->idhrxml_Query->QueryItem) {
      ERR("No QueryItem found buf(%.*s)", got, buf);
      exit(1);
    }

    if (!r->Envelope->Body->idhrxml_Query->QueryItem->Select) {
      ERR("No Select found buf(%.*s)", got, buf);
      exit(1);
    }

    /* *** This mock implementation does not actually interpret the Select string. */
    
    /* Parse the XML from the CV file into data structure and include it as Candidate. */

    got = read_all(sizeof(buf), buf, "query", 1, "%shrxml/cv.xml", cf->cpath);
    if (got < 1) {
      ERR("Reading hrxml/cv.xml resulted in error or the file was empty. ret=%d", got);
#if 0
      env = ZXID_RESP_ENV(cf, "idhrxml:QueryResponse", "Fail", "Empty or no data");
      ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
      ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:QueryResponse><lu:Status code=\"Fail\" comment=\"Empty or no data\"></lu:Status></idhrxml:QueryResponse>");
#endif
      printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
      return 0;
    }
    
    r = zx_dec_zx_root(cf->ctx, got, buf, "hrxml wsp cand");
    if (!r || !r->Candidate) {
      ERR("No hrxml:Candidate tag found in cv.xml(%s)", buf);
#if 0
      env = ZXID_RESP_ENV(cf, "idhrxml:QueryResponse", "Fail", "No Candidate in data");
      ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
      ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:QueryResponse><lu:Status code=\"Fail\" comment=\"No Candidate in data.\"></lu:Status></idhrxml:QueryResponse>");
#endif
      printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
      return 0;
    }

#if 0
    env = ZXID_RESP_ENV(cf, "idhrxml:QueryResponse", "OK", "Fine");
    env->Body->idhrxml_QueryResponse->Data = zx_NEW_idhrxml_Data(cf->ctx,0);
    env->Body->idhrxml_QueryResponse->Data->Candidate = r->Candidate;
    ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
    ss = zxid_wsp_decoratef(cf, ses, 0, "<idhrxml:QueryResponse><lu:Status code=\"OK\" comment=\"Fine\"></lu:Status><idhrxml:Data><idhrxml:Candidate>%s</idhrxml:Candidate></idhrxml:Data></idhrxml:QueryResponse>", buf);
#endif
    printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
    return 0;
  }

  // Modify

  if (r->Envelope->Body->idhrxml_Modify) {
    D("Modify %d",0);
    if (!r->Envelope->Body->idhrxml_Modify->ModifyItem) {
      ERR("No ModifyItem found buf(%.*s)", got, buf);
      exit(1);
    }

    if (!r->Envelope->Body->idhrxml_Modify->ModifyItem->Select) {
      ERR("No Select found buf(%.*s)", got, buf);
      //exit(1);
    }

    /* *** This mock implementation does not actually interpret the Select string. */
    
    if (!r->Envelope->Body->idhrxml_Modify->ModifyItem->NewData) {
      ERR("No NewData found buf(%.*s)", got, buf);
      exit(1);
    }
    
    if (!r->Envelope->Body->idhrxml_Modify->ModifyItem->NewData->Candidate) {
      ERR("No Candidate found buf(%.*s)", got, buf);
#if 0
      env = ZXID_RESP_ENV(cf, "idhrxml:ModifyResponse", "Fail", "NewData does not contain Candidate element.");
      ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
      ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:ModifyResponse><lu:Status code=\"Fail\" comment=\"No Candidate in data.\"></lu:Status></idhrxml:ModifyResponse>");
#endif
      printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
      return 0;
    }
    
    ss = zx_easy_enc_elem_opt(cf, &r->Envelope->Body->idhrxml_Modify->ModifyItem->NewData->Candidate->gg);

    fd = open_fd_from_path(O_CREAT|O_WRONLY|O_TRUNC, 0666, "modify", 1, "%shrxml/cv.xml", cf->cpath);
    write_all_fd(fd, ss->s, ss->len);
    close_file(fd, (const char*)__FUNCTION__);

#if 0
    env = ZXID_RESP_ENV(cf, "idhrxml:ModifyResponse", "OK", "Fine");
    ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
    ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:ModifyResponse><lu:Status code=\"OK\" comment=\"Fine\"></lu:Status></idhrxml:ModifyResponse>");
#endif
    D("ss(%.*s)", ss->len, ss->s);
    printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
    return 0;
  }  

  // Delete

  if (r->Envelope->Body->idhrxml_Delete) {
    D("Delete %d",0);
    if (!r->Envelope->Body->idhrxml_Delete->DeleteItem) {
      ERR("No DeleteItem found buf(%.*s)", got, buf);
      exit(1);
    }

    if (!r->Envelope->Body->idhrxml_Delete->DeleteItem->Select) {
      ERR("No Select found buf(%.*s)", got, buf);
      //exit(1);
    }

    /* *** This mock implementation does not actually interpret the Select string. */
    
    got = name_from_path(buf, sizeof(buf), "%shrxml/cv.xml", cf->cpath);
    unlink(buf);

#if 0
    env = ZXID_RESP_ENV(cf, "idhrxml:DeleteResponse", "OK", "Fine");
    ss = zx_EASY_ENC_SO_e_Envelope(cf->ctx, env);
#else
    ss = zxid_wsp_decorate(cf, ses, 0, "<idhrxml:DeleteResponse><lu:Status code=\"OK\" comment=\"Fine\"></lu:Status></idhrxml:DeleteResponse>");
#endif
    D("ss(%.*s)", ss->len, ss->s);
    printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
    return 0;
  }  

  ss = zxid_wsp_decorate(cf, ses, 0, "<Response><lu:Status code=\"BAD\" comment=\"Unknown XML\"></lu:Status></Response>");
  D("ss(%.*s)", ss->len, ss->s);
  printf("CONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: %d\r\n\r\n%.*s", ss->len, ss->len, ss->s);
  return 0;
}

/* EOF  --  zxidhrxmlwsp.c */
