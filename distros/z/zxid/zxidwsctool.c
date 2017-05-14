/* zxidwsctool.c  -  Command line Web Services Client, a tool for making ID-WSF calls
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidwsctool.c,v 1.10 2010-01-08 02:10:09 sampo Exp $
 *
 * 25.1.2007, created --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           README-zxid, section 10 "zxid_simple() API"
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <zx/platform.h>
#include <zx/errmac.h>
#include <zx/zxid.h>      /* ZXID main API, including zxid_simple(). */
#include <zx/zxidpriv.h>
#include <zx/zxidconf.h>  /* Default and compile-time configuration options. */
#include <zx/wsf.h>
#include <zx/c/zxidvers.h>
#include <zx/c/zx-ns.h>
#include <zx/c/zx-e-data.h>

char* help =
"zxidwsctool  - Command Line ID-WSF WSC - R" ZXID_REL "\n\
Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@iki.fi)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well-researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxidwsctool [options] sesid svc\n\
  sesid            Session ID referring to a directory in /var/zxid/ses\n\
                   Use zxidhlo to do SSO and then cut and paste from there.\n\
  svc              Service type or abbreviation (di = discovery 2.0, dap = ID-DAP)\n\
  -d               Increase debug prints\n\
  -s               Simple API\n\
  -h               This help message\n\
  --               End of options\n";

/* ============== M A I N ============== */

#if 0
#define ZXIDHLO "zxidhlowsf"
#define CONF "PATH=/var/zxid/&URL=https://sp1.zxidsp.org:8443/" ZXIDHLO
#define ZXIDHLO "zxidhlo"
#define CONF "PATH=/var/zxid/&URL=https://sp1.zxidsp.org:8443/" ZXIDHLO
#else
#define ZXIDHLO "zxidhlowsf"
#define CONF "PATH=/var/zxid/&URL=https://sampo:8443/" ZXIDHLO
#endif

/* Called by: */
int main(int argc, char** argv)
{
  zxid_ses sess;
  zxid_conf* cf;
  zxid_ses* ses;
  //struct zx_root_s* r;
  struct zx_e_Envelope_s* env;
  zxid_epr* epr;
  int simple = 0;
  char* sid;
  char* svc;
  
  --argc; ++argv;
  while (argc) {
    if (argv[0][0] != '-') break;
    switch (argv[0][1]) {
    case 'd': ++errmac_debug; break;
    case 's': ++simple; break;
    default:  fprintf(stderr, "Unknown option(%s)\n%s", argv[0], help); exit(1);
    }
    --argc; ++argv;
  }
  if (argc != 2) { fprintf(stderr, "Wrong number of args(%d), (!= 2)\n%s", argc, help); exit(1); }
  sid = argv[0];
  svc = argv[1];
  
  if (!strcmp(svc, "di"))  svc = XMLNS_DISCO_2_0;
  if (!strcmp(svc, "dap")) svc = XMLNS_DAP;
  if (!strcmp(svc, "demomed")) svc = zx_xmlns_demomed;

#if 0
  if (simple) {
    char* res = zxid_dap_call(sid, );
    D("Result(%s)", res);
    exit(1);
  }
#endif

  ses = &sess;
  cf = zxid_new_conf_to_cf(CONF);
  zxid_get_ses(cf, ses, sid);

  if (!strcmp(svc, XMLNS_DISCO_2_0)) {
    /* Discover service (call discovery service using bootstrap) */
    
    env = zx_NEW_e_Envelope(cf->ctx,0);
    env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
    env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
    env->Body->Query = zxid_mk_di_query(cf, &env->Body->gg, svc, 0,0,0);
    epr = zxid_find_epr(cf, ses, XMLNS_DISCO_2_0, 0,0,0, 1);
    env = zxid_wsc_call(cf, ses, epr, env, 0);
    if (env || env != (void*)ZXID_REDIR_OK && env->Body && env->Body->QueryResponse)
      for (epr = env->Body->QueryResponse->EndpointReference;
	   epr;
	   epr = (void*)ZX_NEXT(epr)) {
	if (epr->gg.g.tok != zx_a_EndpointReference_ELEM)
	  continue;
	zxid_cache_epr(cf, ses, epr, 1);
      }
    
  } else if (!strcmp(svc, XMLNS_DAP)) {

    epr = zxid_get_epr(cf, ses, XMLNS_DAP, 0,0,0, 1);
    if (epr) {
      env = zx_NEW_e_Envelope(cf->ctx,0);
      env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
      env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
#if 1
      env->Body->dap_Query
	= zxid_mk_dap_query(cf, &env->Body->gg,
			    0,   /* No tests */
			    zxid_mk_dap_query_item(cf, 0,
						   zxid_mk_dap_select(cf, 0,
								      0,  /* DN from ID-WSF */
								      "objecttype=svcprofile",
								      0,  /* all attributes */
								      1,  /* chase symlinks */
								      ZXID_DAP_SCOPE_SUBTREE,
								      0,  /* no size limit */
								      0,  /* no time limit */
								      0), /* return data */
						   0,  /* regular data entries */
						   0,  /* No predefined operation */
						   0,  /* No sorting. */
						   0,  /* No changed since specification. */
						   0,  /* Do not include LDAP common attributes. */
						   0,  /* Start from first result (offset == 0) */
						   0,  /* Return all results (count == 0) */
						   0,  /* Do not request snapshot */
						   0,  /* Do not refer to snapshot */
						   0), /* No contingent item ID reference */
			    0);  /* No subscriptions */
      env->Body->dap_Query
	= zxid_mk_dap_query(cf, &env->Body->gg, 0,
			    zxid_mk_dap_query_item(cf, 0,
						   zxid_mk_dap_select(cf, 0, 0,
								      "objecttype=svcprofile",
								      0, 1,
								      ZXID_DAP_SCOPE_SUBTREE,
								      0, 0, 0),
						   0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
			    0);  /* No subscriptions */
#else
      env->Body->dap_Query
	= zxid_mk_dap_query(cf, &env->Body->gg,
			    zxid_mk_dap_test_item(cf, 0,
						  zxid_mk_dap_testop(cf, 0,
								     0,  /* DN from ID-WSF */
								     "objecttype=svcprofile",
								     0,  /* all attributes */
								     1,  /* chase symlinks */
								     ZXID_DAP_SCOPE_SUBTREE,
								     0,  /* no size limit */
								     0,  /* no time limit */
								     0), /* return data */
						  0,   /* regular data entries */
						  0),  /* No predefined operation */
			    zxid_mk_dap_query_item(cf, 0,
						   zxid_mk_dap_select(cf, 0,
								      0,  /* DN from ID-WSF */
								      "objecttype=svcprofile",
								      0,  /* all attributes */
								      1,  /* chase symlinks */
								      ZXID_DAP_SCOPE_SUBTREE,
								      0,  /* no size limit */
								      0,  /* no time limit */
								      0), /* return data */
						   0,  /* regular data entries */
						   0,  /* No predefined operation */
						   0,  /* No sorting. */
						   0,  /* No changed since specification. */
						   0,  /* Do not include LDAP common attributes. */
						   0,  /* Start from first result (offset == 0) */
						   0,  /* Return all results (count == 0) */
						   0,  /* Do not request snapshot */
						   0,  /* Do not refer to snapshot */
						   0), /* No contingent item ID reference */
			    zxid_mk_dap_subscription(cf, 0,
						     "subsid",
						     0,  /* No item ID reference */
						     zxid_mk_dap_resquery(cf, 0,
									  zxid_mk_dap_select(cf, 0,
											     0,  /* DN from ID-WSF */
											     "objecttype=svcprofile",
											     0,  /* all attributes */
											     1,  /* chase symlinks */
											     ZXID_DAP_SCOPE_SUBTREE,
											     0,  /* no size limit */
											     0,  /* no time limit */
											     0), /* return data */
									  0,  /* regular data entries */
									  0,  /* No predefined operation */
									  0,  /* No sorting. */
									  0,  /* No changed since specification. */
									  0,  /* Do not include LDAP common attributes. */
									  0), /* No contingent item ID reference */
						     0, /* No notification aggregation spec. */
						     0, /* No notification trigger spec. */
						     0, /* Subscription starts immediately. */
						     0, /* Subscription never expires. */
						     1, /* Include changed data in the notifications. */
						     0, /* Use notification reference for administrative notifications. */
						     "http://host/notif_sink")
			    );
#endif
      env = zxid_wsc_call(cf, ses, epr, env, 0);
      if (env && env != (void*)ZXID_REDIR_OK && env->Body)
	if (env->Body->dap_QueryResponse)
	  D("Result is LDIF(%.*s)",
	    ZX_GET_CONTENT_LEN(env->Body->dap_QueryResponse->Data->LDIF),
	    ZX_GET_CONTENT_S(env->Body->dap_QueryResponse->Data->LDIF));
	else
	  ERR("There was no result %p", env->Body);
      else
	ERR("Web services call failed %p", env);
    } else
      ERR("EPR could not be discovered svc(%s)", svc);

  } else if (!strcmp(svc, zx_xmlns_demomed)) {
    struct zx_demomed_ObjectInfo_s* objinfo;
    struct zx_demomed_ObjectInfo_s* first_objinfo;
    struct zx_demomed_ObjectData_s* objdata;
    struct zx_demomed_ObjectData_s* first_objdata;

    epr = zxid_get_epr(cf, ses, zx_xmlns_demomed, 0,0,0, 1);
    if (epr) {
      
      /* Get list of media objects. */
      
      env = zx_NEW_e_Envelope(cf->ctx,0);
      env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
      env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
      env->Body->GetObjectListRequest = zx_NEW_demomed_GetObjectListRequest(cf->ctx, &env->Body->gg);
      env->Body->GetObjectListRequest->ObjectSearchParm = zx_NEW_demomed_ObjectSearchParm(cf->ctx, &env->Body->GetObjectListRequest->gg);

      env = zxid_wsc_call(cf, ses, epr, env, 0);

      if (env && env != (void*)ZXID_REDIR_OK && env->Body)
	if (env->Body->GetObjectListResponse) {
	  if (!memcmp(env->Body->GetObjectListResponse->Status->code->g.s, "OK", 2)) {
	    first_objinfo = env->Body->GetObjectListResponse->ObjectInfo;
	    D("Successful response %p", first_objinfo);
	    for (objinfo = first_objinfo;
		 objinfo;
		 objinfo = (struct zx_demomed_ObjectInfo_s*)objinfo->gg.g.n) {
	      if (objinfo->gg.g.tok != zx_demomed_ObjectInfo_ELEM)
		continue;
	      D("objectID(%.*s) Dir(%.*s) Name(%.*s) Type(%.*s) Created(%.*s) Comment(%.*s)",
		objinfo->objectID->g.len,       objinfo->objectID->g.s,
		ZX_GET_CONTENT_LEN(objinfo->Dir),     ZX_GET_CONTENT_S(objinfo->Dir),
		ZX_GET_CONTENT_LEN(objinfo->Name),    ZX_GET_CONTENT_S(objinfo->Name),
		ZX_GET_CONTENT_LEN(objinfo->Type),    ZX_GET_CONTENT_S(objinfo->Type),
		ZX_GET_CONTENT_LEN(objinfo->Created), ZX_GET_CONTENT_S(objinfo->Created),
		ZX_GET_CONTENT_LEN(objinfo->Comment), ZX_GET_CONTENT_S(objinfo->Comment));
	    }
	  } else {
	    D("Non OK status(%.*s)", env->Body->GetObjectListResponse->Status->code->g.len, env->Body->GetObjectListResponse->Status->code->g.s);
	  }
	} else
	  ERR("There was no result %p", env->Body);
      else
	ERR("Web services call failed %p", env);

      /* Get first media object from the list */

      env = zx_NEW_e_Envelope(cf->ctx,0);
      env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);
      env->Body = zx_NEW_e_Body(cf->ctx, &env->gg);
      env->Body->GetObjectRequest = zx_NEW_demomed_GetObjectRequest(cf->ctx, &env->Body->gg);
      env->Body->GetObjectRequest->ObjectID = zx_new_str_elem(cf->ctx, &env->Body->GetObjectRequest->gg, zx_demomed_ObjectID_ELEM, &first_objinfo->objectID->g);

      env = zxid_wsc_call(cf, ses, epr, env, 0);

      if (env && env != (void*)ZXID_REDIR_OK && env->Body)
	if (env->Body->GetObjectResponse) {
	  if (!memcmp(env->Body->GetObjectResponse->Status->code->g.s, "OK", 2)) {
	    first_objdata = env->Body->GetObjectResponse->ObjectData;
	    D("Successful response %p", first_objdata);
	    for (objdata = first_objdata;
		 objdata;
		 objdata = (struct zx_demomed_ObjectData_s*)objdata->gg.g.n) {
	      if (objdata->gg.g.tok != zx_demomed_ObjectData_ELEM)
		continue;
	      // show image
	    }
	  } else {
	    D("Non OK status(%.*s)", env->Body->GetObjectResponse->Status->code->g.len, env->Body->GetObjectListResponse->Status->code->g.s);
	  }
	} else
	  ERR("There was no result %p", env->Body);
      else
	ERR("Web services call failed %p", env);

    } else
      ERR("EPR could not be discovered svc(%s)", svc);

  } else
    ERR("Unknown (and unimplemented) svc(%s)", svc);
  return 0;
}

/* EOF  --  zxidwsctool.c */
