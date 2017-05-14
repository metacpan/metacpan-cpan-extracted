/* mini_httpd_filter.c  -  Emulate mod_auth_saml for mini_httpd
 * Copyright (c) 2012-2015 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2008-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing or as licensed below.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: mod_auth_saml.c,v 1.17 2010-01-08 02:10:09 sampo Exp $
 *
 * 1.2.2008,  created --Sampo
 * 22.2.2008, distilled to much more compact version --Sampo
 * 25.8.2009, add attribute passing and pep call --Sampo
 * 11.1.2010, refactoring and review --Sampo
 * 15.7.2010, consider passing to simple layer more data about the request --Sampo
 * 28.9.2012, changed zx_instance string to "mas", fixed parsing CGI for other page --Sampo
 * 13.2.2013, added WD option --Sampo
 * 21.6.2013, added SOAP WSP capability --Sampo
 * 22.6.2013, created, based on mod_auth_saml.c and zxidwspcgi.c --Sampo
 * 10.11.2013, many bugs fixed, much improved --Sampo
 *
 * See also: zxidwspcgi.c, mod_auth_saml.c
 */

#define _LARGEFILE64_SOURCE   /* So off64_t is found, see: man 3 lseek64 */

#include <zx/platform.h>
#include <zx/errmac.h>
#include <zx/zx.h>
#include <zx/zxid.h>
#include <zx/zxidpriv.h>
#include <zx/zxidconf.h>
#include <zx/zxidutil.h>
#include <zx/c/zxidvers.h>

#include <errno.h>
#include <unistd.h>

/* declare stuff from mini_httpd.c */
void send_error_and_exit(int s, char* title, char* extra_header, char* text);
ssize_t conn_read(char* buf, size_t size);
ssize_t conn_write(char* buf, size_t size);
void add_to_buf(char** bufP, size_t* bufsizeP, size_t* buflenP, char* str, size_t len);
void add_to_request(char* str, size_t len);
void add_headers(int s, char* title, char* extra_header, char* me, char* mt, off_t b, time_t mod);
void add_to_response(char* str, size_t len);
void send_response(void);
extern char* remoteuser;
extern char* path;
extern char* request;
extern size_t request_size, request_len, request_idx;
extern size_t content_length;
extern int zxid_is_proto;             /* Flag to indicate protocol URL like /protected/saml. */
extern int zxid_is_wsp;               /* Flag to trigger WSP response decoration. */
extern zxid_ses* zxid_session;

/*() Convert session attribute pool into mini_httpd CGI execution environment.
 *
 * OUTMAP will be applied to decide which attributes to pass to the environment
 * and to rename them.
 *
 * This is considered internal function to mini_httpd_zxid, called by make_envp() in do_cgi().
 * You should not call this directly, unless you know what you are doing. */

/* Called by:  make_envp */
int zxid_pool2env(zxid_conf* cf, zxid_ses* ses, char** envp, int envn, int max_envn, const char* uri_path, const char* qs)
{
  char* name;
  struct zxid_map* map;
  struct zxid_attr* at;
  struct zxid_attr* av;
  
  for (at = ses->at; at; at = at->n) {
    DD("HERE name(%s)", at->name);
    map = zxid_find_map(cf->outmap, at->name);
    if (map) {
      if (map->rule == ZXID_MAP_RULE_DEL) {
	D("attribute(%s) filtered out by del rule in OUTMAP", at->name);
	continue;
      }
      at->map_val = zxid_map_val(cf, 0, 0, map, at->name, at->val);
      if (map->dst && *map->dst && map->src && map->src[0] != '*') {
	name = map->dst;
      } else {
	name = at->name;
      }

      if (envn >= max_envn) goto enverr;
      envp[envn++] = zx_alloc_sprintf(cf->ctx, 0, "%s%s=%s",
				      cf->mod_saml_attr_prefix, name, at->map_val->s);
      for (av = at->nv; av; av = av->n) {
	/* Multivalued */
	av->map_val = zxid_map_val(cf, 0, 0, map, at->name, av->val);
	if (envn >= max_envn) goto enverr;
	envp[envn++] = zx_alloc_sprintf(cf->ctx, 0, "%s%s=%s",
					cf->mod_saml_attr_prefix, name, av->map_val->s);
      }
    } else {
      if ((errmac_debug & ERRMAC_DEBUG_MASK)>1)
	D("ATTR(%s)=VAL(%s)", at->name, STRNULLCHKNULL(at->val));
      else
	D("ATTR(%s)=VAL(%.*s)", at->name, at->val?(int)MIN(35,strlen(at->val)):6, at->val?at->val:"(null)");

      if (envn >= max_envn) goto enverr;
      envp[envn++] = zx_alloc_sprintf(cf->ctx, 0, "%s%s=%s",
				      cf->mod_saml_attr_prefix, at->name, at->val);
      for (av = at->nv; av; av = av->n) {
	/* Multivalued */
	av->map_val = zxid_map_val(cf, 0, 0, map, at->name, av->val);
	if (envn >= max_envn) goto enverr;
	envp[envn++] = zx_alloc_sprintf(cf->ctx, 0, "%s%s=%s",
					cf->mod_saml_attr_prefix, at->name, av->val);
      }
    }
    if (!strcmp(at->name, "idpnid") && at->val && at->val[0] != '-') {
      D("REMOTE_USER(%s)", at->val);
      remoteuser = at->val;
    }
  }
  
  D("CGI SSO OK uri(%s)", uri_path);
  return envn;
 enverr:
  ERR("Statically allocated CGI environment array too small. max_envn=%d", max_envn);
  return envn;
}

/*() Read POST input
 *
 * This is considered internal function to mini_httpd_filter().
 * It works by accessing certain request related global variables from mini_httpd.
 * You should not call this directly, unless you know what you are doing. */

/* Called by:  zxid_mini_httpd_sso, zxid_mini_httpd_wsp */
static char* zxid_mini_httpd_read_post(zxid_conf* cf)
{
  char* res;

  for (;;) {
    char buf[32*1024];
    int already_read = request_len-request_idx;
    int len = MIN(sizeof(buf), content_length - already_read);
    D("Read post already_read=%d/%d buf_siz=%d len=%d", already_read, (int)content_length, (int)sizeof(buf), len);
    DD("uri(%s)=%p buf=%p request(%.*s)=%p request_size=%d request_len=%d", path, path, buf, (int)request_size, request, request, (int)request_size, (int)request_len);
    if (!len)
      break;  /* nothing further to read */
    len = conn_read(buf, len);
    if (len < 0 && ONE_OF_2(errno, EINTR, EAGAIN))
      continue;
    if (len <= 0)
      break;
    DD("uri(%s)=%p buf=%p request(%.*s)=%p request_size=%d request_len=%d", path, path, buf, (int)request_size, request, request, (int)request_size, (int)request_len);
    add_to_request(buf, len);
    DD("uri(%s)=%p buf=%p request(%.*s)=%p request_size=%d request_len=%d", path, path, buf, (int)request_size, request, request, (int)request_size, (int)request_len);
  }
  res = request + request_idx;
  if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("POST(%s)", res);
  return res;
}

#if 0
static void zxid_mini_httpd_metadata_get_special_case(zxid_conf* cf, const char* uri_path)
{
  struct zx_str* ss;
  char* eid;
  eid = zxid_my_ent_id_cstr(cf);
  D("metadata for eid(%s)?", eid);
  if (!strcmp(uri_path, eid)) {
    ss = zxid_sp_meta(cf, 0);
    if (!ss)
      send_error_and_exit(500, "Internal Server Error", "", "Generating SP metadata failed.");
    
    add_headers(200, "OK", "", "", "text/xml; charset=%s", ss->len, (time_t)-1);
    add_to_response(ss->s, ss->len);
    send_response();
    exit(0);  /* This function is called in mini_httpd handle_request() subprocess. */
  }
  ZX_FREE(cf->ctx, eid);
}
#endif

/* Called by:  zxid_mini_httpd_filter */
static zxid_ses* zxid_mini_httpd_wsp(zxid_conf* cf, zxid_ses* ses, const char* method, const char* uri_path, const char* qs)
{  
  char* res;

  if (*method == 'P') {
    res = zxid_mini_httpd_read_post(cf);
    if (zxid_wsp_validate(cf, ses, 0, res)) {
      D("WSP(%s) request valid", uri_path);
      /* Essentially we fall through and let CGI processing happen.
       * zxid_wsp_decorate() will be called in cgi_interpose_output() */
    } else {
      INFO("WSP(%s) call not authorized", uri_path);
      send_error_and_exit(403, "Forbidden", "", "Authorization denied.");
    }
  } else {
    //zxid_mini_httpd_metadata_get_special_case(cf, uri_path);
    ERR("WSP(%s) must be called with POST method (%s)", uri_path, method);
    send_error_and_exit(405, "Method Not Allowed", "", "WSP only accepts POST method.");
  }
  return ses;
}

/*() Handle the WSP case of cgi_interpose_output(). Read in entire response,
 * apply decoration, and send it on its way. */

/* Called by:  cgi_interpose_output */
void zxid_mini_httpd_wsp_response(zxid_conf* cf, zxid_ses* ses, int rfd, char** response, size_t* response_size, size_t* response_len, int br_ix)
{  
  struct zx_str* res;
  
  D_INDENT("wsp_resp");
  D("DECOR START response_size=%d response_len=%d br_ix=%d response(%.*s)", (int)*response_size, (int)*response_len, br_ix, (int)*response_len, *response);

  /* Read until EOF */
  for (;;) {
    char buf[10*1024];
    int len = read(rfd, buf, sizeof(buf));
    if (len < 0 && ONE_OF_2(errno, EINTR, EAGAIN)) {
      sleep(1);
      continue;
    }
    if (len <= 0)
      break;
    add_to_buf(response, response_size, response_len, buf, len);
  }
  
  D("DECOR2 response_size=%d response_len=%d br_ix=%d response(%.*s)", (int)*response_size, (int)*response_len, br_ix, (int)*response_len, *response);

  /* Write the saved headers (and any beginning of payload). */
  if ((*response)[br_ix] == '\015') ++br_ix;
  if ((*response)[br_ix] == '\012') ++br_ix;
  if ((*response)[br_ix] == '\015') ++br_ix;
  if ((*response)[br_ix] == '\012') ++br_ix;

  D("DECOR3 response_len=%d br_ix=%d header(%.*s)", (int)*response_len, br_ix, br_ix, *response);
  (void) conn_write(*response, br_ix);

  res = zxid_wsp_decorate(cf, ses, 0, *response+br_ix);
  (void) conn_write(res->s, res->len);
  D_DEDENT("wsp_resp");
}

extern char* authorization;

/* Called by:  zxid_mini_httpd_filter */
static zxid_ses* zxid_mini_httpd_uma(zxid_conf* cf, zxid_ses* ses, const char* method, const char* uri_path, const char* qs)
{  
  char* res;

  if (!authorization || memcmp(authorization, "Bearer ", sizeof("Bearer ")-1)) {
      INFO("UMA(%s) Missing Authorization header", uri_path);
      send_error_and_exit(401, "Unauthorized", "WWW-Authenticate: UMA realm=\"uma testing\" host_id=\"https://zxidp.org/rs.uma\" as_uri=\"https://zxidp.org/idpuma\"", "Authorization header with UMA Bearer token required");
  }

  // *** POST to token interospection endpoint on AS
  // *** add UMA Resource Server stuff here
  
  if (*method == 'P') {
    res = zxid_mini_httpd_read_post(cf);
    if (zxid_wsp_validate(cf, ses, 0, res)) {
      D("WSP(%s) request valid", uri_path);
      /* Essentially we fall through and let CGI processing happen.
       * zxid_wsp_decorate() will be called in cgi_interpose_output() */
    } else {
      INFO("WSP(%s) call not authorized", uri_path);
      send_error_and_exit(403, "Forbidden", "", "Authorization denied.");
    }
  } else {
    //zxid_mini_httpd_metadata_get_special_case(cf, uri_path);
    ERR("WSP(%s) must be called with POST method (%s)", uri_path, method);
    send_error_and_exit(405, "Method Not Allowed", "", "WSP only accepts POST method.");
  }
  return ses;
}

/* 0x6000 outf QS + JSON = no output on successful sso, the attrubutes are in session
 * 0x1000 debug
 * 0x0e00 11 + 10 = Generate all HTML + Mgmt w/headers as string
 * 0x00a0 10 + 10 = Login w/headers as string + Meta w/headers as string
 * 0x0008 10 + 00 = SOAP w/headers as string + no auto redir, no exit(2) */
#define AUTO_FLAGS 0x6ea8

static zxid_ses* zxid_mini_httpd_process_zxid_simple_outcome(zxid_conf* cf, zxid_ses* ses, const char* uri_path, const char* cookie_hdr, char* res)
{
  int len;
  char* p;
  char* mt;
  
  if (cookie_hdr && cookie_hdr[0]) {
    D("Passing previous cookie(%s) to environment", cookie_hdr);
    zxid_add_attr_to_ses(cf, ses, "cookie", zx_dup_str(cf->ctx, cookie_hdr));
  }
  D("res(%s) uri(%s)",res,uri_path);
  switch (res[0]) {
  case 'L':
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("REDIR(%s)", res);
    zxid_session = ses; /* Set the session so that the mini_httpd add_headers() can set cookies */
    send_error_and_exit(302, "Found", res, "SAML Redirect");
  case 'C':
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("CONTENT(%s)", res);
    res += 14;  /* skip "Content-Type:" (14 chars) */
    DD("RES(%s)", res);
    p = strchr(res, '\r');
    *p = 0;
    mt = res;
    DD("CONTENT-TYPE(%s)", res);
    res = p+2 + 16;  /* skip "Content-Length:" (16 chars) */
    sscanf(res, "%d", &len);
    res = strchr(res, '\r') + 4; /* skip CRFL pair before body */
    DD("CONTENT-LENGTH(%d)", len);
    zxid_session = ses; /* Set the session so that the mini_httpd add_headers() can set cookies */
    add_headers(200, "OK", "", "", mt?mt:"text/html; charset=%s", len, (time_t)-1);
    add_to_response(res, len);
    send_response();
    exit(0);  /* This function is called in mini_httpd handle_request() subprocess. */
  case 'z':
    INFO("User not authorized %d", 0);
    send_error_and_exit(403, "Forbidden", "", "Authorization denied.");
  case 0: /* Logged in case */
    D("SSO OK uri(%s)", uri_path);
    /*ret = pool2apache(cf, r, ses.at); // will be done in do_cgi() */
    break;
#if 0
  case 'd': /* Logged in case */
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("SSO OK LDIF(%s)", res);
    D("SSO OK uri(%s)", uri_path);
    ret = ldif2apache(cf, r, res);
    return ret;
#endif
  default:
    ERR("Unknown zxid_simple response(%s)", res);
    send_error_and_exit(501, "Internal Server Error", "", "Unknown zxid_simple response." );
  }
  return ses;
}

zxid_ses* zxid_mini_httpd_step_up(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* uri_path, const char* cookie_hdr)
{
  char* res;
  DD("before uri(%s)=%p", uri_path, uri_path);
  if (!ses)
    ses = zxid_alloc_ses(cf);
  res = zxid_simple_no_ses_cf(cf, cgi, ses, 0, AUTO_FLAGS);
  DD("after uri(%s)", uri_path);
  return zxid_mini_httpd_process_zxid_simple_outcome(cf, ses, uri_path, cookie_hdr, res);
}

/* Called by:  zxid_mini_httpd_filter */
static zxid_ses* zxid_mini_httpd_sso(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* method, const char* uri_path, const char* qs, const char* cookie_hdr)
{  
  int uri_len;
  char* res;
  //const char* set_cookie_hdr;
  //const char* cur_auth;
  
  uri_len = strlen(uri_path);
  if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("other page uri(%s) qs(%s) cf->burl(%s) uri_len=%d", uri_path, STRNULLCHKNULL(qs), cf->burl, uri_len);
  if (qs && qs[0] == 'l') {
    D("Detect login(%s)", qs);
  } else
    cgi->op = 'E';   /* Trigger IdP selection screen */
#if 0
  p = ZX_ALLOC(cf->ctx, uri_len+1+qs_len+1);
  strcpy(p, uri_path);
  if (qs_len) {
    p[uri_len] = '?';
    strcpy(p+uri_len+1, qs);
  }
  D("HERE3 qs_len=%d cgi=%p k(%s) uri(%s) qs(%s) rs(%s)", qs_len, cgi, STRNULLCHKNULL(cgi->skin), uri_path, STRNULLCHKNULL(qs), p);
  // *** p never used. Should there be cgi->rs =p; ?
#endif
  if (cgi->sid && cgi->sid[0] && zxid_get_ses(cf, ses, cgi->sid)) {
    res = zxid_simple_ses_active_cf(cf, cgi, ses, 0, AUTO_FLAGS);
    if (res)
      return zxid_mini_httpd_process_zxid_simple_outcome(cf, ses, uri_path, cookie_hdr, res);
  } else {
    D("No session(%s) active op(%c)", STRNULLCHK(cgi->sid), cgi->op);
  }
  D("other page: no_ses uri(%s) templ(%s) tf(%s) k(%s) cgi=%p rs(%s)", uri_path, STRNULLCHKNULL(cgi->templ), STRNULLCHKNULL(cf->idp_sel_templ_file), cgi->skin, cgi, cgi->rs);
  if (cf->optional_login_pat && zx_match(cf->optional_login_pat, uri_path)) {
    D("optional_login_pat matches ok %s", cf->optional_login_pat);
    return ses;
  }
  return zxid_mini_httpd_step_up(cf, cgi, ses, uri_path, cookie_hdr);
}

/*() Special case handling for protocol URLs like /protected/saml (configurable)
 * This special case is checked before any other processing. Thus the protocol
 * URL does not have to match SSO_PAT to be effective.
 * Any exceptional outcome is handled internally and terminates in exit(2),
 * hence the void return. */

static void zxid_mini_httpd_check_protocol_url(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* method, const char* uri_path, const char* cookie_hdr)
{
  int ret, uri_len, url_len;
  char* local_url;
  char* p;
  char* res;

  uri_len = strlen(uri_path);
  for (local_url = cf->burl; *local_url && *local_url != ':' && *local_url != '/'; ++local_url);
  if (local_url[0] == ':' && local_url[1] == '/' && local_url[2] == '/') {
    for (local_url += 3; *local_url && *local_url != '/'; ++local_url);
  }
  
  url_len = strlen(local_url);
  for (p = local_url + url_len - 1; p > local_url; --p)
    if (*p == '?')
      break;
  if (p == local_url)
    p = local_url + url_len;
  url_len = p-local_url;

  /* Check if we are supposed to enter zxid due to URL suffix - to
   * process protocol messages rather than ordinary pages. To do this
   * correctly we need to ignore the query string part. We are looking
   * here at an exact match, like /protected/saml, rather than any of
   * the other documents under /protected/ (which are handled in the
   * else clause). Both then and else -clause URLs are defined as requiring
   * SSO by virtue of the web server configuration (SSO_PAT in mini_httpd_zxid). */

  D("match? uri(%s)=%p cf->burl(%s) qs(%s) rs(%s) op(%c)", uri_path, uri_path, cf->burl, STRNULLCHKNULL(cgi->qs), STRNULLCHKNULL(cgi->rs), cgi->op);

  if (url_len != uri_len || memcmp(local_url, uri_path, uri_len))
    return; /* Not an Exact match */

  if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("matched uri(%s)=%p cf->burl(%s) qs(%s) rs(%s) op(%c)", uri_path, uri_path, cf->burl, STRNULLCHKNULL(cgi->qs), STRNULLCHKNULL(cgi->rs), cgi->op);
  if (*method == 'P') {
    res = zxid_mini_httpd_read_post(cf);   /* Will print some debug output */  // ***
    if (res) {
      DD("uri(%s)=%p", uri_path, uri_path);
      if (cgi->op == 'S') {
	ret = zxid_sp_soap_parse(cf, cgi, ses, strlen(res), res);
	D("POST soap parse returned %d", ret);
#if 0
	/* *** TODO: SOAP response should not be sent internally unless there is auto */
	if (ret == ZXID_SSO_OK) {
	  ret = zxid_simple_ab_pep(cf, ses, res_len, auto_flags);
	  D_DEDENT("minizx: ");
	  return ret;
	}
	if (auto_flags & ZXID_AUTO_SOAPC || auto_flags & ZXID_AUTO_SOAPH) {
	  res = zx_dup_cstr(cf->ctx, "n");
	  if (res_len)
	    *res_len = 1;
	  goto done;
	}
	res = zx_dup_cstr(cf->ctx, ret ? "n" : "*** SOAP error (enable debug to see why)"); 
	if (res_len)
	  *res_len = strlen(res);
	goto done;
#endif
      } else {
	zxid_parse_cgi(cf, cgi, res);
	D("POST CGI parsed. rs(%s)", STRNULLCHKQ(cgi->rs));
	DD("uri(%s)=%p", uri_path, uri_path);
      }
    }
  }
  D("HERE2.1 urls_len=%d local_url(%.*s) url(%s)", url_len, url_len, local_url, cf->burl);
  if (ONE_OF_2(cgi->op, 'L', 'A')) /* SSO (Login, Artifact) activity overrides current session. */
    goto step_up;
  if (!cgi->sid || !zxid_get_ses(cf, ses, cgi->sid)) {
    D("No session(%s) active op(%c) uri(%s)=%p", STRNULLCHK(cgi->sid), cgi->op, uri_path,uri_path);
  } else {
    D("HERE2.2 %d",0);
    res = zxid_simple_ses_active_cf(cf, cgi, ses, 0, AUTO_FLAGS);
    if (res) {
      zxid_mini_httpd_process_zxid_simple_outcome(cf, ses, uri_path, cookie_hdr, res);
      exit(0);  /* This function is called in mini_httpd handle_request() subprocess. */
    }
  }
  /* not logged in, fall thru to step_up */
step_up:
  zxid_mini_httpd_step_up(cf, cgi, ses, uri_path, cookie_hdr);
  exit(0);  /* This function is called in mini_httpd handle_request() subprocess. */
}

/*(-)  Redirect hack: deal with externally imposed ACS url that does not follow zxid convention.
 * If the hack is active, returns the new qs and via pointer the new uri_path. */

static char* zxid_mini_httpd_check_redirect_hack(zxid_conf* cf, zxid_cgi* cgi, char** uri_path, const char* qs)
{
  int len, qs_len = qs?strlen(qs):0;
  char* p;
  cgi->uri_path = (char*)*uri_path;
  cgi->qs = (char*)qs;

  if (cf->redirect_hack_imposed_url && !strcmp(*uri_path, cf->redirect_hack_imposed_url)) {
    D("mapping(%s) imposed to zxid(%s)", *uri_path, cf->redirect_hack_zxid_url);
    *uri_path = cf->redirect_hack_zxid_url;
    cgi->uri_path = *uri_path;
    if (cf->redirect_hack_zxid_qs && *cf->redirect_hack_zxid_qs) {
      if (qs_len) {
	/* concatenate redirect_hack_zxid_qs with existing qs */
	len = strlen(cf->redirect_hack_zxid_qs);
	p = ZX_ALLOC(cf->ctx, len+1+qs_len+1);
	strcpy(p, cf->redirect_hack_zxid_qs);
	p[len] = '&';
	strcpy(p+len+1, qs);
	cgi->qs = p;
      } else {
	cgi->qs = cf->redirect_hack_zxid_qs;
      }
    }
  }
  return cgi->qs;
}

/*() Handle SSO or ID-WSF SSO
 * Called from mini_httpd handle_request() if zxid is configured.
 * In many cases entire situation is handled in this function
 * and exit is called. In successful SSO or WSP call function
 * may return and the regular mini_httpd processing continues.
 * In that case docgi() contains further zxid related steps to
 * pass the SSO attributes to the CGI environment. */

/* Called by:  handle_request */
zxid_ses* zxid_mini_httpd_filter(zxid_conf* cf, const char* method, const char* uri_path, const char* qs, const char* cookie_hdr)
{
  zxid_ses* ses = zxid_alloc_ses(cf);
  char buf[256];
  char* p;
  zxid_cgi cgi;
  ZERO(&cgi, sizeof(zxid_cgi));

  D(CC_GREENY("===== START %s uri(%s) qs(%s) uid=%d pid=%d gid=%d cwd(%s)"), ZXID_REL, uri_path, STRNULLCHKNULL(qs), getpid(), geteuid(), getegid(), getcwd(buf,sizeof(buf)));
  if (cf->wd && *cf->wd)
    chdir(cf->wd);

  qs = zxid_mini_httpd_check_redirect_hack(cf, &cgi, (char**)&uri_path, qs);
  if (qs && *qs) {
    /* leak the dup str: the cgi structure will take references to this and change &s to nuls */
    p = zx_dup_cstr(cf->ctx, qs);
    zxid_parse_cgi(cf, &cgi, p);
  }

  /* Probe for Session ID in cookie. */

  if (cf->ses_cookie_name && *cf->ses_cookie_name) {
    if (cookie_hdr) {
      D("found cookie(%s) 3", STRNULLCHK(cookie_hdr));
      zxid_get_sid_from_cookie(cf, &cgi, cookie_hdr);
    }
  }
  
  zxid_mini_httpd_check_protocol_url(cf, &cgi, ses, method, uri_path, cookie_hdr);
  
  zxid_is_wsp = 0;
  if (zx_match(cf->wsp_pat, uri_path)) {
    zxid_is_wsp = 1;
    ses = zxid_mini_httpd_wsp(cf, ses, method, uri_path, qs);
    return ses;
  } else if (zx_match(cf->uma_pat, uri_path)) {
    zxid_is_wsp = 1;
    ses = zxid_mini_httpd_uma(cf, ses, method, uri_path, qs);
    return ses;
  } else if (zx_match(cf->sso_pat, uri_path)) {
    ses = zxid_mini_httpd_sso(cf, &cgi, ses, method, uri_path, qs, cookie_hdr);
    return ses;
  } else {
    D("No SSO or WSP match(%s) wsp_pat(%s) uma_pat(%s) sso_pat(%s)", uri_path, STRNULLCHK(cf->wsp_pat), STRNULLCHK(cf->uma_pat), STRNULLCHK(cf->sso_pat));
    return 0;
  }
}

/* EOF - mini_httpd_filter.c */
