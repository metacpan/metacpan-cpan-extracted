/* mod_auth_saml.c  -  Handwritten functions for Apache mod_auth_saml module
 * Copyright (c) 2012-2015 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
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
 * 17.11.2013, move redir_to_content feature to zxid_simple() --Sampo
 * 8.2.2014,  added OPTIONAL_LOGIN_PAT feature --Sampo
 * 5.3.2015,  improved Apache httpd-2.4 compatibility --Sampo
 * 9.3.2015,  refactored to isolate httpd version dependencies to httpdglue.c --Sampo
 * 20151218,  added special placeholder user "-anon-" for the 2.4 optional_login_pat case --Sampo
 *
 * To configure this module add to httpd.conf something like
 *
 *   LoadModule auth_saml_module modules/mod_auth_saml.so
 *   <Location /secret>
 *     Require valid-user
 *     AuthType "saml"
 *     ZXIDConf "URL=https://sp1.zxidsp.org:8443/secret/saml"
 *   </Location>
 *
 * http://httpd.apache.org/docs/2.2/developer/
 * http://modules.apache.org/doc/API.html
 *
 * Apache 2.4 Quirks
 *
 * [Mon Apr 13 23:04:07.291360 2015] [core:error] [pid 4841:tid 139900761208576] [client 127.0.0.1:60629] AH00027: No authentication done but request not allowed without authentication for /protected/index.html. Authentication not configured?
 *
 * See: httpd-2.4.12/server/request.c lines 250 and 287 (basically r->user needs to be set)
 */

#define _LARGEFILE64_SOURCE   /* So off64_t is found, see: man 3 lseek64 */

#include <zx/platform.h>
#include <zx/errmac.h>
#include <zx/zxid.h>
#include <zx/zxidpriv.h>
#include <zx/zxidconf.h>
#include <zx/zxidutil.h>
#include <zx/c/zxidvers.h>

#ifdef MINGW
/* apr.h defines these */
#undef uid_t
#undef gid_t
#endif

#include "ap_config.h"
#include "ap_compat.h"
#include "apr_strings.h"
#include "httpd.h"         /* request_rec et al. */
#include "http_config.h"
#include "http_core.h"
#include "http_log.h"
#include "http_protocol.h"
#include "http_request.h"  /* accessor methods for request_rec */

#include "HRR.h"  /* httpd glue */

/*#define srv_cf(s) (struct zxid_srv_cf*)ap_get_module_config((s)->module_config, &auth_saml_module)*/
#define dir_cf(r) (zxid_conf*)ap_get_module_config(HRR_per_dir_config(r), &auth_saml_module)

/* This extern variable is used as first argument to LoadModule in httpd.conf,
 * E.g: LoadModule auth_saml_module modules/mod_auth_saml.so */

extern module AP_MODULE_DECLARE_DATA auth_saml_module;

#if 0
/*(-) This function is run when each child process of apache starts. It does
 * initializations that do not survive fork(2). */
/* Called by: */
static void chldinit(apr_pool_t* p, server_rec* s)
{
  CURLcode res;
  D("server_rec=%p", m, s);
  res = curl_global_init(CURL_GLOBAL_ALL); /* vs. _SSL. Also OpenSSL vs. gnuTLS. */
  if(res != CURLE_OK) {
    ERR("Failed to initialize curl library: %u", res);
  }
}
#endif

/*(-) Set cookies apache style. Internal. */

static void set_cookies(zxid_conf* cf, request_rec* r, const char* setcookie, const char* setptmcookie)
{
  if (setcookie && setcookie[0] && setcookie[0] != '-') {
    /* http://dev.ariel-networks.com/apr/apr-tutorial/html/apr-tutorial-19.html */
    D("Set-Cookie(%s)", setcookie);
    apr_table_addn(HRR_headers_out(r), "Set-Cookie", setcookie);
    apr_table_addn(HRR_err_headers_out(r), "Set-Cookie", setcookie);  /* Only way to get redir to set header */
    apr_table_addn(HRR_headers_in(r),  "Set-Cookie", setcookie);  /* So subrequest can pick them up! */
  }
  if (setptmcookie && setptmcookie[0] && setptmcookie[0] != '-') {
    /* http://dev.ariel-networks.com/apr/apr-tutorial/html/apr-tutorial-19.html */
    D("PTM Set-Cookie(%s)", setptmcookie);
    apr_table_addn(HRR_headers_out(r), "Set-Cookie", setptmcookie);
    apr_table_addn(HRR_err_headers_out(r), "Set-Cookie", setptmcookie);  /* Only way to get redir to set header */
    apr_table_addn(HRR_headers_in(r),  "Set-Cookie", setptmcookie);  /* So subrequest can pick them up! */
  }
}

/* ------------------------ Run time action -------------------------- */

/*() Convert session attribute pool into Apache execution environment
 * that will be passed to CGI, mod_php, mod_perl, and other Apache modules.
 *
 * OUTMAP will be applied to decide which attributes to pass to the environment
 * and to rename them.
 *
 * This is considered internal function to mod_auth_saml, called by chkuid().
 * You should not call this directly, unless you know what you are doing.
 *
 * return:: Apache error code, typically OK, which allows Apache continue
 *     processing the request. */

/* Called by:  chkuid x2 */
static int pool2apache(zxid_conf* cf, request_rec* r, struct zxid_attr* pool)
{
  int ret = OK;
  char* name;
  //char* rs = 0;
  //char* rs_qs;
  char* setcookie = 0;
  char* setptmcookie = 0;
  char* cookie = 0;
  char* idpnid = 0;
  struct zxid_map* map;
  struct zxid_attr* at;
  struct zxid_attr* av;
  void* r_pool = HRR_pool(r);
  void* sbe = HRR_subprocess_env(r);

  /* Length computation pass */

  for (at = pool; at; at = at->n) {
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

      name = apr_psprintf(r_pool, "%s%s", cf->mod_saml_attr_prefix, name);
      apr_table_set(sbe, name, at->val);
      for (av = at->nv; av; av = av->n) {
	av->map_val = zxid_map_val(cf, 0, 0, map, at->name, av->val);
	apr_table_set(sbe, name, av->map_val->s);
      }
    } else {
      if ((errmac_debug & ERRMAC_DEBUG_MASK)>1)
	D("ATTR(%s)=VAL(%s)", at->name, STRNULLCHKNULL(at->val));
      else
	D("ATTR(%s)=VAL(%.*s)", at->name, at->val?(int)MIN(35,strlen(at->val)):6, at->val?at->val:"(null)");
      /* *** handling of multivalued attributes (right now only last is preserved) */
      name = apr_psprintf(r_pool, "%s%s", cf->mod_saml_attr_prefix, at->name);
      apr_table_set(sbe, name, at->val);
      for (av = at->nv; av; av = av->n)
	apr_table_set(sbe, name, av->val);
    }
    if      (!strcmp(at->name, "idpnid"))       idpnid = at->val;      /* Capture special */
    else if (!strcmp(at->name, "setcookie"))    setcookie = at->val;
    else if (!strcmp(at->name, "setptmcookie")) setptmcookie = at->val;
    else if (!strcmp(at->name, "cookie"))       cookie = at->val;
    //else if (!strcmp(at->name, "rs"))         rs = at->val;
  }
#if 0
  /* This code moved to zxidsimp.c: zxid_show_protected_content_setcookie() */
  if (rs && rs[0] && rs[0] != '-') {
    /* N.B. RelayState was set by chkuid() "some other page" section by setting cgi.rs
     * to deflated and safe base64 encoded value which was then sent to IdP as RelayState.
     * It then came back from IdP and was decoded as one of the SSO attributes.
     * The decoding is controlled by <<tt: rsrc$rs$unsb64-inf$$ >>  rule in OUTMAP. */
    rs = zxid_unbase64_inflate(cf->ctx, -2, rs, 0);
    if (!rs) {
      ERR("Bad relaystate. Error in inflate. %d", 0);
      return HTTP_BAD_REQUEST;
    }
    rs_qs = strchr(rs, '?');
    if (rs_qs
	?(memcmp(HRR_uri(r), rs, rs_qs-rs)||strcmp(HRR_args(r)?HRR_args(r):"",rs_qs+1))
	:strcmp(HRR_uri(r), rs)) {  /* Different, need external or internal redirect */
      D("redirect(%s) redir_to_content=%d", rs, cf->redir_to_content);
      //r->uri = apr_pstrdup(r->pool, val);
      if (cf->redir_to_content) {
	apr_table_setn(HRR_headers_out(r), "Location", rs);
	ret = HTTP_SEE_OTHER;
      } else {
	/* *** any attributes after this point may not appear in subrequest */
	ap_internal_redirect_handler(rs, r);
      }
    }
  }
#endif

  set_cookies(cf, r, setcookie, setptmcookie);  
  if (cookie && cookie[0] != '-') {
    D("Cookie(%s) 2", cookie);
    apr_table_addn(HRR_headers_in(r), "Cookie", cookie);  /* so internal redirect sees it */
  }
  if (idpnid && idpnid[0] != '-') {
    D("REMOTE_USER(%s)", idpnid);
    apr_table_set(sbe, "REMOTE_USER", idpnid);
    HRR_set_user(r, idpnid);  /* httpd-2.4 anz framework requires this, 2.2 does not care */
  }
  
  //apr_table_setn(r->subprocess_env,
  //		 apr_psprintf(r->pool, "%sLDIF", cf->mod_saml_attr_prefix), ldif);
  D("SSO OK ret(%d) uri(%s) filename(%s) path_info(%s) user(%s)=%p", ret, (char*)HRR_uri(r), (char*)HRR_filename(r), (char*)HRR_path_info(r), STRNULLCHKD((char*)HRR_user(r)), HRR_user(r));
  return ret;
}

/*() Send Apache response.
 *
 * This is considered internal function to mod_auth_saml, called by chkuid().
 * You should not call this directly, unless you know what you are doing. */

/* Called by:  chkuid */
static int send_res(zxid_conf* cf, request_rec* r, char* res)
{
  int len;
  char* p;
#if 0
  apr_table_setn(HRR_headers_out(r),     "Cache-Control", "no-cache");
  apr_table_setn(HRR_err_headers_out(r), "Cache-Control", "no-cache");
  apr_table_setn(HRR_headers_out(r),     "Pragma", "no-cache");
  apr_table_setn(HRR_err_headers_out(r), "Pragma", "no-cache");
#endif
  res += 14;  /* skip "Content-Type:" (14 chars) */
  DD("RES(%s)", res);
  p = strchr(res, '\r');
  *p = 0;
  //apr_table_setn(HRR_headers_out(r), "Content-Type", res);
  DD("CONTENT-TYPE(%s)", res);
  ap_set_content_type(r, res);
  res = p+2 + 16;  /* skip "Content-Length:" (16 chars) */
  sscanf(res, "%d", &len);
  res = strchr(res, '\r') + 4; /* skip CRFL pair before body */
  DD("CONTENT-LENGTH(%d)", len);
  ap_set_content_length(r, len);
  
  if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("LEN(%d) strlen(%d) RES(%s)", len, (int)strlen(res), res);
  
  //register_timeout("send", r);
  ap_send_http_header(r);
  if (!HRR_header_only(r))
    ap_rprintf(r, "%s", res);  //send_fd(f, r);  rprintf(); ap_rwrite()
  return DONE;   /* Prevent further hooks from processing the request. */
}

/*(-) Read POST input, Apache style
 *
 * This is considered internal function to mod_auth_saml, called by chkuid().
 * You should not call this directly, unless you know what you are doing. */

/* Called by:  chkuid x2 */
static char* read_post(zxid_conf* cf, request_rec* r)
{
  int len, ret;
  char* res;
  char* p;
  /*len = apr_table_get(r->headers_in, "Content-Length");*/
  
  /* Ask Apache to dechunk data if it is chunked. */
  ret = ap_setup_client_block(r, REQUEST_CHUNKED_DECHUNK);
  if (ret != OK) {
    ERR("ap_setup_client_block(r, REQUEST_CHUNKED_DECHUNK): %d", ret);
    return 0;
  }
  
  /* This function will send a 100 Continue response if the client is
   * waiting for that. If the client isn't going to send data, then this
   * function will return 0. */
  if (!ap_should_client_block(r)) {
    len = 0;
  } else {
    len = HRR_remaining(r);
  }
  res = p = apr_palloc(HRR_pool(r), len + 1);
  res[len] = 0;
  D("remaining=%d", len);
  
  while (len > 0) {
    /* Read data from the client. Returns 0 on EOF or error, the
     * number of bytes otherwise.   */
    ret = ap_get_client_block(r, p, len);
    if (!ret) {
      ERR("Failed to read POST data from client. len=%d",len);
      return 0;  /* HTTP_INTERNAL_SERVER_ERROR */
    }
    
    p += ret;
    len -= ret;
  }
  if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("POST(%s)", res);
  return res;
}

/* 0x6000 outf QS + JSON = no output on successful sso, the attrubutes are in session
 * 0x1000 debug
 * 0x0e00 11 + 10 = Generate all HTML + Mgmt w/headers as string
 * 0x00a0 10 + 10 = Login w/headers as string + Meta w/headers as string
 * 0x0008 10 + 00 = SOAP w/headers as string + no auto redir, no exit(2) */
#define AUTO_FLAGS 0x6ea8

/*() Apache hook. Internal function of mod_auth_saml. Do not try to call.
 *
 * Called from httpd-2.2.8/server/request.c: ap_process_request_internal()
 * ap_run_check_user_id(). Return value is processed in modules/http/http_request.c
 * and redirect is in ap_die(), http_protocol.c: ap_send_error_response()
 *
 * It seems this function will in effect be called twice by Apache internals: once
 * to see if it would succeed and second time to actually do the work. This is rather
 * wasteful, but we do not know any easy way to avoid it.
 *
 * Originally this was just for SSO, but nowdays we also support WSP mode.  */

/* Called by: */
static int chkuid(request_rec* r)
{
  int ret, len, uri_len, url_len, args_len;
  char* cp;
  char* res;
  char buf[256];
  const char* cookie_hdr=0;
  const char* set_cookie_hdr;
  const char* cur_auth;
  request_rec* main_req;
  char* uri = r?HRR_uri(r):0;
  zxid_conf* cf = dir_cf(r);
  zxid_cgi cgi;
  zxid_ses ses;
  ZERO(&cgi, sizeof(zxid_cgi));
  ZERO(&ses, sizeof(zxid_ses));
  cgi.uri_path = uri;
  cgi.qs = r?HRR_args(r):0;

  //D("request_rec sizeof=%d offset(r->uri)=%d offset(r->user)=%d", sizeof(request_rec), (void*)(uri)-(void*)r, (void*)(&(r->user))-(void*)r);
  D("===== START %s req=%p uri(%s) args(%s) pid=%d cwd(%s)", ZXID_REL, r, r?STRNULLCHKNULL(uri):"(r null)", r?STRNULLCHKNULL(HRR_args(r)):"(r null)", getpid(), getcwd(buf,sizeof(buf)));
  if (cf->wd && *cf->wd)
    chdir(cf->wd);  /* Ensure the working dir is not / (sometimes Apache httpd changes dir) */
  D_INDENT("chkuid: ");

  if (main_req = HRR_main(r)) {  /* subreq can't come from net: always auth OK. */
    D("sub ok user(%s)=%p", STRNULLCHKD((char*)HRR_user(r)), HRR_user(r));
    HRR_set_user(r, HRR_user(main_req));
    D("sub from main user(%s)=%p", STRNULLCHKD((char*)HRR_user(r)), HRR_user(r));
    D_DEDENT("chkuid: ");
    return OK;
  }
  
  cur_auth = ap_auth_type(r);   /* From directive: AuthType "saml" */
  if (!cur_auth || strcasecmp(cur_auth, "saml")) {
    D("not saml auth (%s) %d", STRNULLCHKD(cur_auth), DECLINED);
    D_DEDENT("chkuid: ");
    return DECLINED;
  }
  //r->ap_auth_type = "saml";  *** This is already verified to be the case?!?
  
  /* Probe for Session ID in cookie. Also propagate the cookie to subrequests. */

  if (cf->ses_cookie_name && *cf->ses_cookie_name) {
    cookie_hdr = apr_table_get(HRR_headers_in(r), "Cookie");
    if (cookie_hdr) {
      D("found cookie(%s) 3", STRNULLCHK(cookie_hdr));
      zxid_get_sid_from_cookie(cf, &cgi, cookie_hdr);
      apr_table_addn(HRR_headers_out(r), "Cookie", cookie_hdr);       /* Pass cookies to subreq */
      DD("found cookie(%s) 5", STRNULLCHK(cookie_hdr));
      /* Kludge to get subrequest to set-cookie, i.e. on return path */
      set_cookie_hdr = apr_table_get(HRR_headers_in(r), "Set-Cookie");
      if (set_cookie_hdr) {
	D("subrequest set-cookie(%s) 2", set_cookie_hdr);
	apr_table_addn(HRR_headers_out(r), "Set-Cookie", set_cookie_hdr);
      }
    }
  }

  /* Redirect hack: deal with externally imposed ACS url that does not follow zxid convention. */
  
  args_len = HRR_args(r)?strlen(HRR_args(r)):0;
  if (cf->redirect_hack_imposed_url && !strcmp(uri, cf->redirect_hack_imposed_url)) {
    D("Redirect hack: mapping(%s) imposed to zxid(%s)", uri, cf->redirect_hack_zxid_url);
    HRR_set_uri(r, cf->redirect_hack_zxid_url);
    uri = cf->redirect_hack_zxid_url;
    if (cf->redirect_hack_zxid_qs && *cf->redirect_hack_zxid_qs) {
      if (args_len) {
	/* concatenate redirect_hack_zxid_qs with existing qs */
	len = strlen(cf->redirect_hack_zxid_qs);
	cp = apr_palloc(HRR_pool(r), len+1+args_len+1);
	strcpy(cp, cf->redirect_hack_zxid_qs);
	cp[len] = '&';
	strcpy(cp+len+1, HRR_args(r));
	cgi.qs = cp;
	HRR_set_args(r, cp);
      } else {
	cgi.qs = cf->redirect_hack_zxid_qs;
	HRR_set_args(r, cgi.qs);
      }
      args_len = strlen(HRR_args(r));
    }
    D("After hack uri(%s) args(%s)", STRNULLCHK(uri), STRNULLCHK(HRR_args(r)));
  }
  
  DD("HERE1 args_len=%d cgi=%p k(%s) args(%s)", args_len, &cgi, STRNULLCHKNULL(cgi.skin), STRNULLCHKNULL(HRR_args(r)));
  if (args_len) {
    /* leak the dup str: the cgi structure will take references to this and change &s to nuls */
    cp = apr_palloc(HRR_pool(r), args_len + 1);
    strcpy(cp, HRR_args(r));
    zxid_parse_cgi(cf, &cgi, cp);
    DD("HERE2 args_len=%d cgi=%p k(%s) args(%s)", args_len, &cgi, STRNULLCHKNULL(cgi.skin), STRNULLCHKNULL(HRR_args(r)));
  }
  /* Check if we are supposed to enter zxid due to URL suffix - to
   * process protocol messages rather than ordinary pages. To do this
   * correctly we need to ignore the query string part. We are looking
   * here at exact match, like /protected/saml, rather than any of
   * the other documents under /protected/ (which are handled in the
   * else clause). Both then and else -clause URLs are defined as requiring
   * SSO by virtue of the web server configuration. */

  uri_len = strlen(uri);
  url_len = strlen(cf->burl);
  for (cp = cf->burl + url_len - 1; cp > cf->burl; --cp)
    if (*cp == '?')
      break;
  if (cp == cf->burl)
    cp = cf->burl + url_len;
  
  if (url_len >= uri_len && !memcmp(cp - uri_len, uri, uri_len)) {  /* Suffix match */
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("matched uri(%s) cf->burl(%s) qs(%s) rs(%s) op(%c)", uri, cf->burl, STRNULLCHKNULL(HRR_args(r)), STRNULLCHKNULL(cgi.rs), cgi.op);
    if (HRR_method_number(r) == M_POST) {
      res = read_post(cf, r);   /* Will print some debug output */
      if (res) {
	if (cgi.op == 'S') {
	  ret = zxid_sp_soap_parse(cf, &cgi, &ses, strlen(res), res);
	  D("POST soap parse returned %d", ret);
#if 0
	  /* *** TODO: SOAP response should not be sent internally unless there is auto */
	  if (ret == ZXID_SSO_OK) {
	    ret = zxid_simple_ab_pep(cf, &ses, res_len, auto_flags);
	    D_DEDENT("chkuid: ");
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
	  zxid_parse_cgi(cf, &cgi, res);
	  D("POST CGI parsed. rs(%s)", STRNULLCHKQ(cgi.rs));
	}
      }
    }
    if (ONE_OF_2(cgi.op, 'L', 'A')) /* SSO (Login, Artifact) activity overrides current session. */
      goto step_up;
    if (!cgi.sid || !zxid_get_ses(cf, &ses, cgi.sid)) {
      D("No session(%s) active op(%c)", STRNULLCHK(cgi.sid), cgi.op);
    } else {
      res = zxid_simple_ses_active_cf(cf, &cgi, &ses, 0, AUTO_FLAGS);
      if (res)
	goto process_zxid_simple_outcome;
    }
    /* not logged in, fall thru */
  } else if (zx_match(cf->wsp_pat, uri)) {
    /* WSP case */
    if (HRR_method_number(r) == M_POST) {
      res = read_post(cf, r);   /* Will print some debug output */
      if (zxid_wsp_validate(cf, &ses, 0, res)) {
	D("WSP(%s) request valid", uri);
	D("WSP CALL uri(%s) filename(%s) path_info(%s)", uri, (char*)HRR_filename(r), (char*)HRR_path_info(r));
	ret = pool2apache(cf, r, ses.at);
	D_DEDENT("chkuid: ");
	return ret;
	/* Essentially we fall through and let CGI processing happen.
	 * *** how to decorate the CGI return value?!? New hook needed? --Sampo */
      } else {
	ERR("WSP(%s) request validation failed", uri);
	D_DEDENT("chkuid: ");
	return HTTP_FORBIDDEN;
      }
    } else {
      ERR("WSP(%s) must be called with POST method %d", uri, HRR_method_number(r));
      D_DEDENT("chkuid: ");
      return HTTP_METHOD_NOT_ALLOWED;
    }
  } else if (zx_match(cf->uma_pat, uri)) {
    /* UMA case */
    if (HRR_method_number(r) == M_POST) {
      res = read_post(cf, r);   /* Will print some debug output */
#if 0
      // *** add UMA Resource Server stuff here
      if (zxid_wsp_validate(cf, &ses, 0, res)) {
	D("WSP(%s) request valid", uri);
	D("WSP CALL uri(%s) filename(%s) path_info(%s)", uri, HRR_filename(r), HRR_path_info(r));
	ret = pool2apache(cf, r, ses.at);
	D_DEDENT("chkuid: ");
	return ret;
	/* Essentially we fall through and let CGI processing happen.
	 * *** how to decorate the CGI return value?!? New hook needed? --Sampo */
      } else {
	ERR("WSP(%s) request validation failed", uri);
	D_DEDENT("chkuid: ");
	return HTTP_FORBIDDEN;
      }
#endif
    } else {
      ERR("WSP(%s) must be called with POST method %d", uri, HRR_method_number(r));
      D_DEDENT("chkuid: ");
      return HTTP_METHOD_NOT_ALLOWED;
    }
  } else {
    /* Some other page. Just check for session. */
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("other page uri(%s) qs(%s) cf->burl(%s) uri_len=%d url_len=%d", uri, STRNULLCHKNULL(HRR_args(r)), cf->burl, uri_len, url_len);
    if (cgi.sid && cgi.sid[0] && zxid_get_ses(cf, &ses, cgi.sid)) {
      res = zxid_simple_ses_active_cf(cf, &cgi, &ses, 0, AUTO_FLAGS);
      if (res)
	goto process_zxid_simple_outcome;
    } else {
      D("No active session(%s) op(%c)", STRNULLCHK(cgi.sid), cgi.op?cgi.op:'-');
      if (cf->optional_login_pat && zx_match(cf->optional_login_pat, uri)) {
	D("optional_login_pat matches %d", OK);
	HRR_set_user(r, "-anon-");  /* httpd-2.4 anz framework requires this, 2.2 does not care */
	D_DEDENT("chkuid: ");
	return OK;
      }
    }
    if (HRR_args(r) && ((char*)HRR_args(r))[0] == 'l') {
      D("Detect login(%s)", (char*)HRR_args(r));
    } else
      cgi.op = 'E';   /* Trigger IdP selection screen */
    D("other page: no_ses uri(%s) templ(%s) tf(%s) k(%s)", uri, STRNULLCHKNULL(cgi.templ), STRNULLCHKNULL(cf->idp_sel_templ_file), STRNULLCHKNULL(cgi.skin));
  }
step_up:
  res = zxid_simple_no_ses_cf(cf, &cgi, &ses, 0, AUTO_FLAGS);

process_zxid_simple_outcome:
  if (cookie_hdr && cookie_hdr[0]) {
    D("Passing previous cookie(%s) to environment", cookie_hdr);
    zxid_add_attr_to_ses(cf, &ses, "cookie", zx_dup_str(cf->ctx, cookie_hdr));
  }

  switch (res[0]) {
  case 'L':
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("REDIR(%s)", res);
    apr_table_setn(HRR_headers_out(r), "Location", res+10);
    set_cookies(cf, r, ses.setcookie, ses.setptmcookie);  
    D_DEDENT("chkuid: ");
    return HTTP_SEE_OTHER;
  case 'C':
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("CONTENT(%s)", res);
    set_cookies(cf, r, ses.setcookie, ses.setptmcookie);  
    ret = send_res(cf, r, res);
    D_DEDENT("chkuid: ");
    return ret;
  case 'z':
    INFO("User not authorized %d", 0);
    D_DEDENT("chkuid: ");
    return HTTP_FORBIDDEN;
  case 0: /* Logged in case */
    D("SSO OK pre uri(%s) filename(%s) path_info(%s)", uri, (char*)HRR_filename(r), (char*)HRR_path_info(r));
    ret = pool2apache(cf, r, ses.at);
    D_DEDENT("chkuid: ");
    return ret;
#if 0
  case 'd': /* Logged in case */
    if (errmac_debug & MOD_AUTH_SAML_INOUT) INFO("SSO OK LDIF(%s)", res);
    D("SSO OK pre uri(%s) filename(%s) path_info(%s)", uri, (char*)HRR_filename(r), (char*)HRR_path_info(r));
    ret = ldif2apache(cf, r, res);
    D_DEDENT("chkuid: ");
    return ret;
#endif
  default:
    ERR("Unknown zxid_simple response(%s)", res);
    D_DEDENT("chkuid: ");
    return HTTP_INTERNAL_SERVER_ERROR;
  }

  D("final ok %d", OK);
  D_DEDENT("chkuid: ");
  return OK;
}

/* ------------------------ CONF -------------------------- */

/*(-) Process ZXIDDebug directive in Apache configuration file.
 *
 * This is considered internal function to mod_auth_saml. Do not call directly. */

/* Called by: */
static const char* set_debug(cmd_parms* cmd, void* st, const char* arg) {
  char buf[256];
  D("old debug=%x, new debug(%s)", errmac_debug, arg);
  sscanf(arg, "%i", &errmac_debug);
  INFO("debug=0x%x now arg(%s) cwd(%s)", errmac_debug, arg, getcwd(buf, sizeof(buf)));
  {
    struct rlimit rlim;
    getrlimit(RLIMIT_CORE, &rlim);
    D("MALLOC_CHECK_(%s) core_rlimit=%d,%d", getenv("MALLOC_CHECK_"), (int)rlim.rlim_cur, (int)rlim.rlim_max);
  }
  return 0;
}

/*(-) Process ZXIDConf directive in Apache configuration file.
 * Can be called any number of times to set additional parameters.
 *
 * This is considered internal function to mod_auth_saml. Do not call directly. */

/* Called by: */
static const char* set_zxid_conf(cmd_parms* cmd, void* st, const char* arg) {
  int len;
  char* buf;
  zxid_conf* cf = (zxid_conf*)st;
  D("arg(%s) cf=%p", arg, cf);
  len = strlen(arg);
  buf = ZX_ALLOC(cf->ctx, len+1);
  memcpy(buf, arg, len+1);
  zxid_parse_conf(cf, buf);
  return 0;
}

const command_rec zxid_apache_commands[] = {
  AP_INIT_TAKE1("ZXIDDebug", set_debug, 0, OR_AUTHCFG,
		"Enable debugging output to stderr. 0 to disable."),
  AP_INIT_TAKE1("ZXIDConf", set_zxid_conf, 0, OR_AUTHCFG,
		"Supply ZXID CONF string. May be supplied multiple times."),
  {0}
};


#define ZXID_APACHE_DEFAULT_CONF ""  /* defaults will reign, including cpath /var/zxid */

/*(-) Create default configuration in response for Apache <Location> or <Directory>
 * directives. This is then augmented by ZXIDConf directives.
 * This code may run twice: once for syntax check, and then again for
 * production use. Currently we just redo the work. Apache stores the
 * return value of this function and it can be read in chkuid() hook using
 *    ap_get_module_config((r)->per_dir_config, &auth_saml_module)
 *
 * This is considered internal function to mod_auth_saml. Do not call directly. */

/* Called by: */
static void* dirconf(apr_pool_t* p, char* d)
{
  zxid_conf* cf;
  strncpy(errmac_instance, "\tmas", sizeof(errmac_instance));
  cf = apr_palloc(p, sizeof(zxid_conf));
  ZERO(cf, sizeof(zxid_conf));
  cf->ctx = apr_palloc(p, sizeof(struct zx_ctx));
  zx_reset_ctx(cf->ctx);
  D("cf=%p ctx=%p d(%s)", cf, cf->ctx, STRNULLCHKD(d));
  /* *** set malloc func ptr in ctx to use apr_palloc() */
  zxid_conf_to_cf_len(cf, -1, ZXID_APACHE_DEFAULT_CONF);
  cf->cpath_supplied = 0;
  return cf;
}

/* ------------------------ Hooks -------------------------- */

/*(-) Register Apache hook for mod_auth_saml
 *
 * This is considered internal function to mod_auth_saml. Do not call directly. */

/* Called by: */
static void reghk(apr_pool_t* p) {
  D("pool=%p", p);
  //ap_hook_access_checker(authusr,  0, 0, APR_HOOK_MIDDLE);
  ap_hook_check_user_id( chkuid,   0, 0, APR_HOOK_MIDDLE);
  //ap_hook_post_config(   postconf, 0, 0, APR_HOOK_MIDDLE);
  /*ap_hook_child_init(    chldinit, 0, 0, APR_HOOK_MIDDLE);*/
}

/* This extern variable is used as first argument to LoadModule in httpd.conf,
 * E.g: LoadModule auth_saml_module modules/mod_auth_saml.so
 * See httpd-2.2/include/http_config.h for module_struct.
 * Lucky for 2.2 vs. 2.4 compat, m->module_index and other fields up to
 * m->magic are on sample places on both. */

module AP_MODULE_DECLARE_DATA auth_saml_module = {
  STANDARD20_MODULE_STUFF,
  dirconf,
  0, //dirmerge,
  0, //srvconf,
  0, //srvmerge,
  zxid_apache_commands,
  reghk
};

/* EOF - mod_auth_saml.c */
