/* zxumacall.c  -  UMA Client and Debugging Tool
 * Copyright (c) 2014 Synergetics NV, All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@synergetics.be)
 * This is confidential unpublished proprietary source code.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxcot.c,v 1.5 2009-11-29 12:23:06 sampo Exp $
 *
 * 9.10.2014, created --Sampo
 */

#include "platform.h"  /* for dirent.h */

#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>

#include "platform.h"
#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zxidvers.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"
#include "saml2.h"

char* help =
"zxumacall  - UMA Client and Debugging tool R" ZXID_REL "\n\
UMA - User Managed Access and OAUTH2.0 are standards for access authorization of web services.\n\
Copyright (c) 2014 Synergetics NV, All Rights Reserved.\n\
Author: Sampo Kellomaki (sampo@synergetics.be)\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: zxid.org\n\
\n\
Usage: zxumacall [options] -s SESID -t SVCTYPE <req >resp\n\
       zxumacall [options] -a IDP USER:PW -t SVCTYPE <req >resp\n\
       zxumacall [options] -ua IDP UAT    -t SVCTYPE <req >resp\n\
       zxumacall [options] -a IDP USER:PW -t SVCTYPE -nd # Discovery only\n\
       zxumacall [options] -a IDP USER:PW   # Authentication only\n\
       zxumacall [options] -dynclireg az_entity # Dynamic Client Registration\n\
       zxumacall [options] -s SESID -im EID # Identity Mapping to EID\n\
       zxumacall [options] -s SESID -l      # List session cache\n\
  -c CONF          Optional configuration string (default -c CPATH=/var/zxid/)\n\
                   Most of the configuration is read from " ZXID_CONF_PATH "\n\
  -s SESID         Session ID referring to a directory in /var/zxid/ses\n\
                   Use zxidhlo to do SSO and then cut and paste from there.\n\
  -a IDP USER:PW   Use Authentication service to authenticate the user and\n\
                   create session. IDP is IdP's Entity ID. This is alternative to -s\n\
  -t SVCTYPE       Service Type URI. Used for discovery. Mandatory (omitting -t\n\
                   causes authorization only mode, provided that -az was specified).\n\
  -dynclireg       Invoke Dynamic Client Registration client to call Az Server's client registration endpoint\n\
  -swstmt file     (Optional) File containing signed Software Statement for dynreg\n\
  -iat IAT         (Optional) Initial Access Token for dynamic client registration\n\
  -ua IDP UAT      (Optional) Token for _uma_authn query string passed to OpenID-Connect server\n\
  -client_id ID    client_id (same as returned by dynamic client registration)\n\
  -client_secret SS  client_secret (same as returned by dynamic client registration)\n\
  -rr NAME ICON_URI SCOPE TYPE Perform OAUTH2 Resource Set Registration\n\
  -u EPURL         Optional endpoint URL or ProviderID. Discovery must match this.\n\
  -di DISCOOPTS    Optional discovery options. Query string format.\n\
  -din N           Discovery index (default: 1=pick first).\n\
  -az AZCREDS      Optional authorization credentials. Query string format.\n\
                   N.B. For authorization to work PDP_URL configuration option is needed.\n\
  -im DSTEID       Map session's login identity to identity at some other SP using ID-WSF\n\
  -nidmap DSTEID   Map session's login identity to identity at some other SP using SAML\n\
  -e ODY           Pass request body as argument (default is to read from STDIN)\n\
  -b               In response, only return content of response body, omitting headers.\n\
  -nd              Discovery only (you need to specify -t SVCTYPE as well)\n\
  -n               Dryrun. Do not actually make call. Instead print it to stdout.\n\
  -l               List EPR cache (you need to specify -s SEDID or -a as well)\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -dc              Dump config.\n\
  -h               This help message\n\
  --               End of options\n\
\n\
echo '<query>Foo</query>' | zxcall -a https://idp.tas3.eu/zxididp?o=B user:pw -t urn:x-demo-svc\n\
\n";

int dryrun  = 0;
int verbose = 1;
int out_fmt = 0;
int din = 1;
int di_only = 0;
/* int ssos = 0;    -nssos           SSOS only (you need to specify -a IDP USER:PW as well)\n\ */
int listses = 0;
int dynclireg = 0;
extern char* iat;          /* see zxidoauth.c */
extern char* _uma_authn;   /* see zxidoauth.c */
char* swstmt = 0;
char* client_id;
char* client_secret;
char* rsrc_name = 0;
char* rsrc_icon_uri = 0;
char* rsrc_scope_url = 0;
char* rsrc_type = 0;
char* entid = 0;
char* idp   = 0;
char* user  = 0;
char* sid = 0;
char* svc = 0;
char* url = 0;
char* di  = 0;
char* az  = 0;
char* im_to = 0;
char* nidmap_to = 0;
char* bdy = 0;
zxid_conf* cf;

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
static void opt(int* argc, char*** argv, char*** env)
{
  struct zx_str* ss;
  if (*argc <= 1) return;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* normal exit from options loop */
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'a':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 2) break;
	idp = (*argv)[0];
	++(*argv); --(*argc);
	user = (*argv)[0];
	continue;
      case 'z':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	az = (*argv)[0];
	continue;
      }
      break;

    case 'b':
      switch ((*argv)[0][2]) {
      case '\0':
	++out_fmt;
	continue;
      }
      break;

    case 'c':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	zxid_parse_conf(cf, (*argv)[0]);
	continue;
      case 'l':
	if (!strcmp((*argv)[0],"-client_id")) {
	  ++(*argv); --(*argc);
	  if ((*argc) < 1) break;
	  client_id = (*argv)[0];
	  continue;
	}
	if (!strcmp((*argv)[0],"-client_secret")) {
	  ++(*argv); --(*argc);
	  if ((*argc) < 1) break;
	  client_secret = (*argv)[0];
	  continue;
	}
	break;	
      }
      break;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	if (errmac_debug == 2)
	  strncpy(errmac_instance, "\t\e[43mzxuma\e[0m", sizeof(errmac_instance));
	continue;
      case 'i':
        switch ((*argv)[0][3]) {
	case '\0':
	  ++(*argv); --(*argc);
	  if ((*argc) < 1) break;
	  di = (*argv)[0];
	  continue;
	case 'n':
	  ++(*argv); --(*argc);
	  if ((*argc) < 1) break;
	  sscanf((*argv)[0], "%i", &din);
	  continue;
	}
	break;
      case 'c':
	ss = zxid_show_conf(cf);
	if (verbose>1) {
	  printf("\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
	  exit(0);
	}
	fprintf(stderr, "\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
	continue;
      case 'y':
	if (!strcmp((*argv)[0],"-dynclireg")) {
	  ++(*argv); --(*argc);
	  ++dynclireg;
	  continue;
	}
	break;
      }
      break;

    case 'e':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	bdy = (*argv)[0];
	continue;
      }
      break;

    case 'i':
      switch ((*argv)[0][2]) {
      case 'm':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	im_to = (*argv)[0];
	continue;
      case 'a':
	switch ((*argv)[0][3]) {
	case 't':
	  ++(*argv); --(*argc);
	  if ((*argc) < 1) break;
	  iat = (*argv)[0];
	  continue;
	}
	break;
      }
      break;

    case 'l':
      switch ((*argv)[0][2]) {
      case '\0':
	++listses;
	continue;
#if 0
      case 'i':
	if (!strcmp((*argv)[0],"-license")) {
	  extern char* license;
	  fprintf(stderr, license);
	  exit(0);
	}
	break;
#endif
      }
      break;

    case 'n':
      switch ((*argv)[0][2]) {
      case 'd':
	++di_only;
	continue;
#if 0
      case 's':
	if (!strcmp((*argv)[0],"-nssos")) {
	  ++ssos;
	  continue;
	}
	break;
#endif
      case 'i':
	if (!strcmp((*argv)[0],"-nidmap")) {
	  ++(*argv); --(*argc);
	  if ((*argc) < 1) break;
	  nidmap_to = (*argv)[0];
	  continue;
	}
	break;
      case '\0':
	++dryrun;
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

    case 'r':
      switch ((*argv)[0][2]) {
      case 'r':
	++(*argv); --(*argc);
	if ((*argc) < 4) break;
	rsrc_name = (*argv)[0];
	rsrc_icon_uri = (*argv)[1];
	rsrc_scope_url = (*argv)[2];
	rsrc_type = (*argv)[3];
	++(*argv); --(*argc);
	++(*argv); --(*argc);
	++(*argv); --(*argc);
	continue;
      }
      break;

    case 's':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	sid = (*argv)[0];
	continue;
      }
      break;

    case 't':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	svc = (*argv)[0];
	continue;
      }
      break;

    case 'u':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	url = (*argv)[0];
	continue;
      case 'a':
	++(*argv); --(*argc);
	if ((*argc) < 2) break;
	idp = (*argv)[0];
	_uma_authn = (*argv)[1];
	++(*argv); --(*argc);
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

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
help:
    if (verbose>1) {
      printf("%s", help);
      exit(0);
    }
    fprintf(stderr, "%s", help);
    /*fprintf(stderr, "version=0x%06x rel(%s)\n", zxid_version(), zxid_version_str());*/
    exit(3);
  }
#if 0
  if (!sid && !idp) {
    fprintf(stderr, "MUST specify either -s or -a\n");
    goto help;
  }
#endif
}


/*() List session and especially its EPR cache to stdout.
 * Typical name: /var/zxid/ses/SESID/SVCTYPE,SHA1
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * ses:: Session object in whose EPR cache the file is searched
 *
 * See also: zxid_find_epr() */

/* Called by:  zxcall_main */
int zxid_print_session(zxid_conf* cf, zxid_ses* ses)
{
  struct zx_root_s* r;
  int epr_len, din = 0;
  char path[ZXID_MAX_BUF];
  char* epr_buf;  /* MUST NOT come from stack. */
  DIR* dir;
  struct dirent * de;
  zxid_epr* epr;
  struct zx_a_Metadata_s* md;
  struct zx_str* ss;
  
  D_INDENT("lstses: ");

  if (!name_from_path(path, sizeof(path), "%s" ZXID_SES_DIR "%s", cf->cpath, ses->sid)) {
    D_DEDENT("lstses: ");
    return 0;
  }
  
  printf("SESID:  %s\nSESDIR: %s\n", ses->sid, path);
  dir = opendir(path);
  if (!dir) {
    perror("opendir to find epr in session");
    ERR("Opening session for find epr by opendir failed path(%s) sesptr=%p", path, ses);
    D_DEDENT("lstses: ");
    return 0;
  }

  while (de = readdir(dir)) {
    D("%d Considering file(%s)", din, de->d_name);
    if (de->d_name[0] == '.')  /* . .. and "hidden" files */
      continue;
    if (de->d_name[strlen(de->d_name)-1] == '~')  /* Ignore backups from hand edited EPRs. */
      continue;
    D("%d Checking EPR content file(%s)", din, de->d_name);
    epr_buf = read_all_alloc(cf->ctx, "lstses", 1, &epr_len,
			     "%s" ZXID_SES_DIR "%s/%s", cf->cpath, ses->sid, de->d_name);
    if (!epr_buf)
      continue;
    
    r = zx_dec_zx_root(cf->ctx, epr_len, epr_buf, "lstses");
    if (!r || !r->EndpointReference) {
      ERR("No EPR found. Failed to parse epr_buf(%.*s)", epr_len, epr_buf);
      continue;
    }
    epr = r->EndpointReference;
    ZX_FREE(cf->ctx, r);

    md = epr->Metadata;
    if (!md || !ZX_SIMPLE_ELEM_CHK(md->ServiceType)) {
      ERR("No Metadata %p or ServiceType. Failed to parse epr_buf(%.*s)", md, epr_len, epr_buf);
      printf("EPR %d no service type\n", ++din);
    } else {
      ss = ZX_GET_CONTENT(md->ServiceType);
      printf("EPR %d SvcType: %.*s\n", ++din, ss->len, ss->s);
    }
    ss = zxid_get_epr_address(cf, epr);
    printf("  URL:         %.*s\n", ss?ss->len:0, ss?ss->s:"");
    ss = zxid_get_epr_entid(cf, epr);
    printf("  EntityID:    %.*s\n", ss?ss->len:0, ss?ss->s:"");
    ss = zxid_get_epr_desc(cf, epr);
    printf("  Description: %.*s\n", ss?ss->len:0, ss?ss->s:"");
  }
  ZX_FREE(cf->ctx, epr_buf);
  closedir(dir);
  D_DEDENT("lstses: ");
  return 0;
}

#if 0
char* zxid_scan_quoted(zxid_conf* cf, char* p, char** val, const char* res, comma_expected)
{
  char quote;
  char* p;
  if (ONE_OF_2(*val, '"', '\'')) {
    quote = *val;
    ++val;
    p = strchr(val, quote);
    if (!p) {
      ERR("Mismatched quote res(%s)", res);
      return 0;
    }
    val = zx_dup_len_cstr(cf->ctx, val, p-val);
    ++p;
    if (comma_expected) {
      if (*p != ',') {
	ERR("Comma expected res(%s)", res);
	return 0;	  
      }
    }
    ++p;
  } else {
    p = strchr(val, ',');
    if (comma_expected) {
      if (!p) {
	ERR("Comma expected res(%s)", res);
	return 0;	  
      }
    } else {

    }
    val = zx_dup_len_cstr(cf->ctx, val, p-val);
    ++p;
  }
  return val;

  // *** buggy
}
#endif

/*(i) Make a HTTP POST call given payload string.
 * The call is protected by UMA.
 *
 * cf:: ZXID configuration object, see zxid_new_conf()
 * ses:: Session object that contains the EPR cache
 * svctype:: URI (often the namespace URI) specifying the kind of service we
 *     wish to call. Used for EPR lookup or discovery.
 * url:: (Optional) If provided, this argument has to match either
 *     the ProviderID, EntityID, or actual service endpoint URL.
 * di_opt:: (Optional) Additional discovery options for selecting the
 *     service, query string format
 * az_cred:: (Optional) Additional authorization credentials or
 *     attributes, query string format. These credentials will be populated
 *     to the attribute pool in addition to the ones obtained from SSO and
 *     other sources. Then a PDP is called to get an authorization decision
 *     (as well as obligations we pledge to support). See also PEPMAP
 *     configuration option. This implementes generalized (application
 *     independent) Requestor Out and Requestor In PEPs. To implement
 *     application dependent PEP features you should call zxid_az() directly.
 * req:: request payload as string
 * return:: SOAP Envelope of the response, as a string. You can parse this
 *     string to obtain all returned SOAP headers as well as the Body and its
 *     content. NULL on failure. ses->curflt and/or ses->curstatus contain
 *     more detailed error information. */

/* Called by:  zxcall_main, zxid_callf */
struct zx_str* zxid_uma_call(zxid_conf* cf, zxid_ses* ses, const char* svctype, const char* url, const char* di_opt, const char* az_cred, const char* req)
{
  long rc;
  struct zx_str* res;
  char* p;
  char* realm;
  char* host_id;
  char* as_uri;
  char* error;
  char* ticket = 0;
  char* azhdr = 0;
  /* *** try
GET /umaprotected/resource HTTP/1.1

HTTP/1.1 401 Unauthorized
   WWW-Authenticate: UMA realm="example",
    host_id="photoz.example.com",
    as_uri="https://as.example.com"
  
*** obtain RPT by calling AS with AAT

GET /umaprotected/resource HTTP/1.1
Authorization: Bearer RPT

(see ResourceServer registers the desired permissions)

HTTP/1.1 403 Forbidden
   WWW-Authenticate: UMA realm="example",
    host_id="photoz.example.com",
    as_uri="https://as.example.com",
    error="insufficient_scope"

{
"ticket": "016f84e8-f9b9-11e0-bd6f-0021cc6004de"
}

OR

HTTP/1.1 200 OK

*** ResourceServer registers the desired permissions

POST /host/scope_reg_uri/photoz.example.com HTTP/1.1
Content-Type: application/json
Host: as.example.com

{
  "resource_set_id": "112210f47de98100",
  "scopes": [
      "http://photoz.example.com/dev/actions/view",
      "http://photoz.example.com/dev/actions/all"
  ]
}

HTTP/1.1 201 Created
Content-Type: application/json
Location: https://as.example.com/permreg/host/photoz.example.com/5454345rdsaa4543
...

{
"ticket": "016f84e8-f9b9-11e0-bd6f-0021cc6004de"
}

*** With ticket, enhance the RPT

  */

  while (1) {
    curl_easy_setopt(cf->curl, CURLOPT_HEADER, 1);
    res = zxid_http_cli(cf, -1, url, -1, req, "application/json", azhdr, 0x01);
    if (!res) {
      ERR("Call to url(%s) failed", url);
      return 0;
    }
    curl_easy_getinfo(cf->curl, CURLINFO_RESPONSE_CODE, &rc);
    switch (rc) {
    case 200:
      p = strstr(res->s, CRLF CRLF);  /* find where headers end */
      if (!p) {
	ERR("Failed to find empty line separating headers from the body(%s)", res->s);
	return res;
      }
      p = zx_dup_cstr(cf->ctx, p + sizeof(CRLF CRLF)-1);
      ZX_FREE(cf->ctx, res->s);
      res->s = p;
      return res;
    case 401:
#if 0
      p = strstr(res->s, "WWW-Authenticate: UMA realm=");
      if (!p) {
	ERR("Failed to find WWW-Authenticate header or it is not of uma type res(%s)", res->s);
	return res;
      }
      p = p + sizeof("WWW-Authenticate: UMA realm=")+1;
      p = zxid_scan_quoted(cf, p, &realm);

      p = strstr(p, "host_id=");
      p = p + sizeof("host_id=")+1;
      p = zxid_scan_quoted(cf, p, &host_id);
#else
      if (sscanf(res->s, "WWW-Authenticate: UMA realm=\"%m[^\"]\" , host_id=\"%m[^\"]\", as_uri=\"%m[^\"]\"",
		  &realm, &host_id, &as_uri) != 3) {
	ERR("Failed to find WWW-Authenticate header or it is not correctly formatted for UMA. res(%s)", res->s);
	return res;
      }
#endif 

      // Call AS to get RPT
      zxid_oauth_call_rpt_endpoint(cf, ses, host_id, as_uri);
      azhdr = zx_alloc_sprintf(cf->ctx, 0, "Authorization: Bearer %s", ses->rpt);
      break;

    case 403:
      if (sscanf(res->s, "WWW-Authenticate: UMA realm=\"%m[^\"]\" , host_id=\"%m[^\"]\", as_uri=\"%m[^\"]\", error=\"%m[^\"]\"",
		  &realm, &host_id, &as_uri, &error) != 4) {
	ERR("Failed to find WWW-Authenticate header or it is not correctly formatted for UMA. res(%s)", res->s);
	return res;
      }
      if (strcmp(error, "insufficient_scope")) {
	ERR("Expected error insufficient_scope, got(%s)", error);
	return res;
      }
      p = strstr(res->s, CRLF CRLF);  /* find where headers end */
      if (!p) {
	ERR("Failed to find empty line separating headers from the body(%s)", res->s);
	return res;
      }
      ticket = zx_json_extract_dup(cf->ctx, res->s, "\"ticket\"");
      
      // Call AS to get more perms
      zxid_oauth_call_az_endpoint(cf, ses, host_id, as_uri, ticket);
      azhdr = zx_alloc_sprintf(cf->ctx, 0, "Authorization: Bearer %s", ses->rpt);
      break;

    default:
      ERR("Unexpected HTTP response %ld", rc);
      return 0;
    }
  }
}

#ifndef zxumacall_main
#define zxumacall_main main
#endif

/*() Web Services Client tool */

/* Called by: */
int zxumacall_main(int argc, char** argv, char** env)
{
  int siz, got, n;
  char* p;
  struct zx_str* ss;
  zxid_ses* ses = 0;
  zxid_entity* idp_meta;
  zxid_epr* epr;

  strncpy(errmac_instance, CC_CYNY("\tzxuma"), sizeof(errmac_instance));
  cf = zxid_new_conf_to_cf(0);
  opt(&argc, &argv, &env);

  if (dynclireg) {
    ses = zxid_alloc_ses(cf);
    ss = zxid_oauth_dynclireg_client(cf, 0, ses, url);
    printf("%*s", ss->len, ss->s);
    return 0;
  }
    
  if (sid) {
    D("Existing session sesid(%s)", sid);
    ses = zxid_fetch_ses(cf, sid);
    if (!ses) {
      ERR("Session not found or error in session sesid(%s)", sid);
      return 1;
    }
  } else {
    D("Obtain session from authentication service(%s)", idp);
    idp_meta = zxid_get_ent(cf, idp);
    if (!idp_meta) {
      ERR("IdP metadata not found and could not be fetched. idp(%s)", idp);
      return 1;
    }
    if (user) {
      for (p = user; !ONE_OF_2(*p, ':', 0); ++p) ;
      if (*p)
	*p++ = 0;
      ses = zxid_as_call(cf, idp_meta, user, p);
    } else if (_uma_authn) {
      ses = zxid_alloc_ses(cf);
      zxid_oidc_as_call(cf, ses, idp_meta, _uma_authn);
    }
    if (!ses) {
      ERR("Login using Authentication Service failed idp(%s)", idp);
      return 1;
    }
    INFO("Logged in. Session in %s" ZXID_SES_DIR "%s\n%s", cf->cpath, STRNULLCHKD(ses->sid),STRNULLCHKD(ses->access_token));
  }

  if (rsrc_name) {
    if (!ses->client_secret) {
      if (!ses)
	ses = zxid_alloc_ses(cf);
      if (client_id) {
	ses->client_id = client_id;
	ses->client_secret = client_secret;
      } else
	zxid_oauth_dynclireg_client(cf, 0, ses, url);
    }
    zxid_oauth_rsrcreg_client(cf, 0, ses, url, rsrc_name, rsrc_icon_uri, rsrc_scope_url, rsrc_type);
    return 0;
  }

  if (listses)
    return zxid_print_session(cf, ses);   

  if (im_to) {
    D("ID-WSF Map to identity at eid(%s)", im_to);
    zxid_map_identity_token(cf, ses, im_to, 0);
    //printf("%.*s\n", ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
    return 0;
  }

  if (nidmap_to) {
    D("SAML Map to identity at eid(%s)", nidmap_to);
    zxid_nidmap_identity_token(cf, ses, nidmap_to, 0);
    //printf("%.*s\n", ZX_GET_CONTENT_LEN(nameid), ZX_GET_CONTENT_S(nameid));
    return 0;
  }

  if (di_only) {
    D("Discover only. svctype(%s), dindex=%d", STRNULLCHK(svc), din);
    epr = zxid_get_epr(cf, ses, svc, url, di, 0 /*action*/, din);
    if (!epr) {
      ERR("Discovery failed to find any epr of service type(%s)", STRNULLCHK(svc));
      return 3;
    }
    for (din = 1; ;++din) {
      epr = zxid_get_epr(cf, ses, svc, url, di, 0 /*action*/, din);
      if (!epr)
	break;
      printf("%d. Found epr for service type(%s)\n", din, STRNULLCHK(svc));
      ss = zxid_get_epr_desc(cf, epr);
      printf("   Description: %.*s\n", ss?ss->len:0, ss?ss->s:"");
      ss = zxid_get_epr_address(cf, epr);
      printf("   EPURL:       %.*s\n", ss?ss->len:0, ss?ss->s:"");
      ss = zxid_get_epr_entid(cf, epr);
      printf("   EntityID:    %.*s\n", ss?ss->len:0, ss?ss->s:"");
    }
    return 0;
  }
  
  if (svc) {
    D("Call service svctype(%s)", svc);
    if (!bdy) {
      if (verbose)
	fprintf(stderr, "Reading request body from stdin...\n");
      siz = 4096;
      p = bdy = ZX_ALLOC(cf->ctx, siz);
      while (1) {
	n = read_all_fd(fdstdin, p, siz+bdy-p-1, &got);
	if (n == -1) {
	  perror("reading SOAP req from stdin");
	  break;
	}
	p += got;
	if (got < siz+bdy-p-1) break;
	siz += 60*1024;
	REALLOCN(bdy, siz);
      }
      *p = 0;
    }
    if (dryrun) {
      if (verbose)
	fprintf(stderr, "Dryrun. Call aborted.\n");
      return 0;
    }
    if (verbose)
      fprintf(stderr, "Calling...\n");

#if 1
    ss = zxid_uma_call(cf, ses, svc, url, di, az, bdy);
    printf("%.*s", ss->len, ss->s);
#else
    ss = zxid_call(cf, ses, svc, url, di, az, bdy);
    if (!ss || !ss->s) {
      ERR("Call failed %p", ss);
      return 2;
    }
    if (verbose)
      fprintf(stderr, "Done. Call returned %d bytes.\n", ss->len);
    if (out_fmt) {
      p = zxid_extract_body(cf, ss->s);
      printf("%s", p);
    } else
      printf("%.*s", ss->len, ss->s);
#endif
  } else if (az) {
    D("Call Az(%s)", az);
    if (dryrun) {
      if (verbose)
	fprintf(stderr, "Dryrun. zxid_az() aborted.\n");
      return 0;
    }
    if (zxid_az_cf_ses(cf, az, ses)) {
      if (verbose)
	fprintf(stderr, "Permit.\n");
      return 0;
    } else {
      if (verbose)
	fprintf(stderr, "Deny.\n");
      return 1;
    }
  } else {
    D("Neither service type (-t) nor -az supplied. Performed only authentication. %d",0);
    if (verbose)
      fprintf(stderr, "Authentication only.\n");
  }
  return 0;
}

/* EOF  --  zxcall.c */
