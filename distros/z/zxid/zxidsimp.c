/* zxidsimp.c  -  Handwritten zxid_simple() API
 * Copyright (c) 2012-2016 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidsimp.c,v 1.64 2010-01-08 02:10:09 sampo Exp $
 *
 * 17.1.2007, created --Sampo
 * 2.2.2007,  improved the LDIF return --Sampo
 * 9.3.2008,  refactored the logged in and need login cases to subroutines --Sampo
 * 7.10.2008, added documentation --Sampo
 * 4.9.2009,  added attribute broker and PEP functionality --Sampo
 * 31.5.2010, moved local PEP and attribute broker functionality to zxidpep.c --Sampo
 * 7.9.2010,  tweaked the az requests to separate ses az from resource az --Sampo
 * 22.9.2010, added People Service invitation resolution --Sampo
 * 10.12.2011, added OAuth2, OpenID Connect, and UMA support --Sampo
 * 30.9.2012, added PTM support --Sampo
 * 13.2.2013, added WD option --Sampo
 * 14.3.2013  added language/skin dependent templates --Sampo
 * 15.4.2013, added fflush(3) here and there to accommodate broken atexit() --Sampo
 * 17.11.2013, move redir_to_content feature to zxid_simple() --Sampo
 * 20.11.2013, move defaultqs feature feature to zxid_simple() --Sampo
 * 14.2.2014,  added redirafter feature for local IdP logins (e.g. zxidatsel.pl) --Sampo
 * 1.4.2015,   fixed skin based template path in case it does not have directory --Sampo
 *
 * Login button abbreviations
 * A2 = SAML 2.0 Artifact Profile
 * P2 = SAML 2.0 POST Profile
 * S2 = SAML 2.0 POST Simple Sign
 * A12 = Liberty ID-FF 1.2 Artifact Profile
 * P12 = Liberty ID-FF 1.2 POST Profile
 * A1 = Bare SAML 1.x Artifact Profile
 * P1 = Base SAML 1.x POST Profile
 * A0 = WS-Federation Artifact Profile
 * P0 = WS-Federation POST Profile
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include <memory.h>
#include <string.h>
#include <stdlib.h>

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "zxidpriv.h"
#include "wsf.h"
#include "c/zxidvers.h"
#include "c/zx-md-data.h"

/*#include "dietstdio.h"*/

/*() Convert configuration string ~conf~ to configuration object ~cf~.
 * cf:: Configuration object, already allocated
 * conf_len:: length of conf string, or -1 to use strlen(conf)
 * conf:: Configuration string in query string format
 * See also: zxid_conf_to_cf() */

/* Called by:  dirconf, main x2, zxid_az, zxid_az_base, zxid_fed_mgmt_len, zxid_idp_list_len, zxid_idp_select_len, zxid_new_conf_to_cf, zxid_simple_len */
int zxid_conf_to_cf_len(zxid_conf* cf, int conf_len, const char* conf)
{
#if 1
  if (!cf->ctx) {
    cf->ctx = zx_init_ctx();
    if (!cf->ctx) {
      ERR("Failed to alloc zx_ctx %d",0);
      exit(2);
    }
  }
  zxid_init_conf(cf, ZXID_PATH);   /* Hardwired conf from zxidconf.h, and /var/zxid/zxid.conf */
#ifdef USE_CURL
  //INFO("%lx == %lx? eq=%d sizeof(cf->curl_mx.thr)=%ld a=%lx sizeof(a)=%ld sizeof(pthread_t)=%ld sizeof(int)=%ld sizeof(long)=%ld sizeof(long long)=%ld sizeof(char*)=%ld", cf->curl_mx.thr, pthread_self(), (long)cf->curl_mx.thr == (long)pthread_self(), sizeof(cf->curl_mx.thr), a, sizeof(a), sizeof(pthread_t), sizeof(int), sizeof(long), sizeof(long long), sizeof(char*));
  LOCK(cf->curl_mx, "curl init");
  cf->curl = curl_easy_init();
  if (!cf->curl) {
    ERR("Failed to initialize libcurl %d",0);
    UNLOCK(cf->curl_mx, "curl init");
    exit(2);
  }
  UNLOCK(cf->curl_mx, "curl init");
#endif
#else
  zxid_init_conf_ctx(cf, ZXID_PATH /* N.B. Often this is overridden. */);
#endif
#if defined(ZXID_CONF_FILE_ENA) || defined(ZXID_CONF_FLAG)
  /* The usual case is that config file processing is compiled in, so this code happens. */
  {
    char* buf;
    char* cc;
    int len;
    if (conf_len == -1) {
      if (conf)
	conf_len = strlen(conf);
      else
	conf_len = 0;
    }

    if (!conf || conf_len < 5 || memcmp(conf, "PATH=", 5)) {
      /* No conf, or conf does not start by PATH: read from file default values */
      buf = read_all_alloc(cf->ctx, "-conf_to_cf", 1, &len, "%s" ZXID_CONF_FILE, cf->cpath);
      if (!buf || !len)
	buf = read_all_alloc(cf->ctx, "-conf_to_cf", 1, &len, "%szxid.conf", cf->cpath);
      if (buf && len)
	zxid_parse_conf_raw(cf, len, buf);
    }

    buf = getenv(ZXID_ENV_PREFIX "PRE_CONF");
    D("Check " ZXID_ENV_PREFIX "PRE_CONF(%s)", STRNULLCHKD(buf));
    if (buf) {
      /* Copy the conf string because we are going to modify it in place. */
      D("Applying " ZXID_ENV_PREFIX "PRE_CONF(%s)", buf);
      len = strlen(buf);
      cc = ZX_ALLOC(cf->ctx, len+1);
      memcpy(cc, buf, len);
      cc[len] = 0;
      zxid_parse_conf_raw(cf, len, cc);
    }
    
    if (conf && conf_len) {
      /* Copy the conf string because we are going to modify it in place. */
      cc = ZX_ALLOC(cf->ctx, conf_len+1);
      memcpy(cc, conf, conf_len);
      cc[conf_len] = 0;
      zxid_parse_conf_raw(cf, conf_len, cc);
    }

    buf = getenv(ZXID_ENV_PREFIX "CONF");
    if (buf) {
      /* Copy the conf string because we are going to modify it in place. */
      D("Applying " ZXID_ENV_PREFIX "CONF(%s)", buf);
      len = strlen(buf);
      cc = ZX_ALLOC(cf->ctx, len+1);
      memcpy(cc, buf, len);
      cc[len] = 0;
      zxid_parse_conf_raw(cf, len, cc);
    }
  }
#endif
  return 0;
}

/*() Create new ZXID configuration object given configuration string and
 * possibly configuration file.
 *
 * zxid_new_conf_to_cf() parses first the default config file, then the string (i.e. string
 * can override config file). However, if the string contains PATH specification,
 * then the config file is reread from (presumably new) location and overrides
 * eariler config.
 *
 * conf::   Configuration string
 * return:: Configuration object */

/* Called by:  a7n_test, handle_request, main x6, opt x2, test_receipt, ws_validations, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxidwspcgi_main x2 */
zxid_conf* zxid_new_conf_to_cf(const char* conf)
{
  zxid_conf* cf = malloc(sizeof(zxid_conf));  /* *** direct use of malloc */
  D("malloc %p size=%d", cf, (int)sizeof(zxid_conf));
  if (!cf) {
    ERR("out-of-memory %d", (int)sizeof(zxid_conf));
    exit(1); /* *** perhaps too severe! */
  }
  cf = ZERO(cf, sizeof(zxid_conf));
  zxid_conf_to_cf_len(cf, -1, conf);
  return cf;
}

/* ------------ zxid_fed_mgmt() ------------ */

/*(i) Generate Single Logout button and possibly other federation management
 * buttons for use in logged in state of the app HTML GUI.
 *
 * Either outputs the management screen to stdout or returns string of HTML (at specified
 * automation level). If res_len is supplied, the string length is returned in res_len.
 * Otherwise you can just run strlen() on return value.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_fed_mgmt_len, zxid_simple_ses_active_cf */
char* zxid_fed_mgmt_cf(zxid_conf* cf, int* res_len, int sid_len, char* sid, int auto_flags)
{
  char* res;
  struct zx_str* ss;
  struct zx_str* ss2;
  int slen = sid_len == -1 && sid ? strlen(sid) : sid_len;
  if (auto_flags & ZXID_AUTO_DEBUG) zxid_set_opt(cf, 1, 3);

  if (cf->log_level>1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "MGMT", 0, "sid(%.*s)", sid_len, STRNULLCHK(sid));
  
  if ((auto_flags & ZXID_AUTO_FORMT) && (auto_flags & ZXID_AUTO_FORMF))
    ss = zx_strf(cf->ctx,
		 "%s"
#ifdef ZXID_USE_POST
		 "<form method=post action=\"%s?o=P\">\n"
#else
		 "<form method=get action=\"%s\">\n"
#endif
		 "<input type=hidden name=s value=\"%.*s\">\n"
		 "%s%s\n"
		 "</form>%s%s%s%s",
		 cf->mgmt_start,
		 cf->burl,
		 slen, STRNULLCHK(sid),
		 cf->mgmt_logout, cf->mgmt_defed,
		 cf->mgmt_footer, zxid_version_str(), STRNULLCHK(cf->dbg), cf->mgmt_end);
  else if (auto_flags & ZXID_AUTO_FORMT)
    ss = zx_strf(cf->ctx,
#ifdef ZXID_USE_POST
		 "<form method=post action=\"%s?o=P\">\n"
#else
		 "<form method=get action=\"%s\">\n"
#endif
		 "<input type=hidden name=s value=\"%.*s\">"
		 "%s%s\n"
		 "</form>",
		 cf->burl,
		 slen, STRNULLCHK(sid),
		 cf->mgmt_logout, cf->mgmt_defed);
  else if (auto_flags & ZXID_AUTO_FORMF)
    ss = zx_strf(cf->ctx,
		 "<input type=hidden name=s value=\"%.*s\">"
		 "%s%s\n",
		 slen, STRNULLCHK(sid),
		 cf->mgmt_logout, cf->mgmt_defed);
  else
    ss = zx_dup_str(cf->ctx, "");

#if 0
  printf("COOKIE: foo\r\n");
  if (qs) printf("QS(%s)\n", qs);
  if (got>0) printf("GOT(%.*s)\n", got, buf);
  if (cgi->err) printf("<p><font color=red><i>%s</i></font></p>\n", cgi->err);
  if (cgi->msg) printf("<p><i>%s</i></p>\n", cgi->msg);
  printf("User:<input name=user> PW:<input name=pw type=password>");
  printf("<input name=login value=\" Login \" type=submit>");
  printf("<h3>Technical options (typically hidden fields on production site)</h3>\n");
  printf("sid(%s) nid(%s) <a href=\"zxid?s=%s\">Reload</a>", ses->sid, ses->nid, ses->sid);
  if (cgi->dbg) printf("<p><form><textarea cols=100 row=10>%s</textarea></form>\n", cgi->dbg);
#endif

  if (auto_flags & ZXID_AUTO_MGMTC && auto_flags & ZXID_AUTO_MGMTH) {  /* Both H&C: CGI */
    fprintf(stdout, "Content-Type: text/html" CRLF "Content-Length: %d" CRLF2 "%.*s",
	   ss->len, ss->len, ss->s);
    fflush(stdout);
    zx_str_free(cf->ctx, ss);
    return 0;
  }

  if (auto_flags & (ZXID_AUTO_MGMTC | ZXID_AUTO_MGMTH)) {
    if (auto_flags & ZXID_AUTO_MGMTH) {  /* H only: return both H and C */
      D("With headers 0x%x", auto_flags);
      ss2 = zx_strf(cf->ctx, "Content-Type: text/html" CRLF "Content-Length: %d" CRLF2 "%.*s",
		    ss->len, ss->len, ss->s);
      zx_str_free(cf->ctx, ss);
    } else {
      D("No headers 0x%x", auto_flags);
      ss2 = ss;       /* C only */
    }
    res = ss2->s;
    DD("res(%s)", res);
    if (res_len)
      *res_len = ss2->len;
    ZX_FREE(cf->ctx, ss2);
    return res;
  }
  D("m(%.*s)", ss->len, ss->s);
  zx_str_free(cf->ctx, ss);
  if (res_len)
    *res_len = 1;
  return zx_dup_cstr(cf->ctx, "m");   /* Neither H nor C */
}

/* Called by:  zxid_fed_mgmt */
char* zxid_fed_mgmt_len(int conf_len, char* conf, int* res_len, char* sid, int auto_flags) {
  zxid_conf cf;
  zxid_conf_to_cf_len(&cf, conf_len, conf);
  return zxid_fed_mgmt_cf(&cf, 0, -1, sid, auto_flags);
}

/* Called by: */
char* zxid_fed_mgmt(char* conf, char* sid, int auto_flags) {
  return zxid_fed_mgmt_len(-1, conf, 0, sid, auto_flags);
}

/* ------------ zxid_an_page() ------------ */

#define BBMATCH(k, key, lim) (sizeof(k)-1 == (lim)-(key) && !memcmp((k), (key), sizeof(k)-1))

/*() Bang-bang expansions (!!VAR) understood in the templates. */

/* Called by:  zxid_template_page_cf */
static const char* zxid_map_bangbang(zxid_conf* cf, zxid_cgi* cgi, const char* key, const char* lim, int auto_flags)
{
  switch (*key) {
  case 'A':
    if (BBMATCH("ACTION_URL", key, lim)) return cgi->action_url;
    break;
  case 'B':
    if (BBMATCH("BURL", key, lim)) return cf->burl;
    break;
  case 'D':
    if (BBMATCH("DBG", key, lim)) return cgi->dbg;
    break;
  case 'E':
    if (BBMATCH("EID", key, lim)) return zxid_my_ent_id_cstr(cf);
    if (BBMATCH("ERR", key, lim)) return cgi->err;
    break;
  case 'F':
    if (BBMATCH("FR", key, lim)) return zxid_unbase64_inflate(cf->ctx, -2, cgi->rs, 0);
    break;
  case 'I':
    if (BBMATCH("IDP_LIST", key, lim)) return zxid_idp_list_cf_cgi(cf, cgi, 0, auto_flags);
    if (BBMATCH("IDP_POPUP", key, lim)) {
      cf->idp_list_meth = ZXID_IDP_LIST_POPUP;
      return zxid_idp_list_cf_cgi(cf, cgi, 0, auto_flags);
    }
    if (BBMATCH("IDP_BUTTON", key, lim)) {
      cf->idp_list_meth = ZXID_IDP_LIST_BUTTON;
      return zxid_idp_list_cf_cgi(cf, cgi, 0, auto_flags);
    }
    if (BBMATCH("IDP_BRAND", key, lim)) {
      cf->idp_list_meth = ZXID_IDP_LIST_BRAND;
      return zxid_idp_list_cf_cgi(cf, cgi, 0, auto_flags);
    }
    break;
  case 'M':
    if (BBMATCH("MSG", key, lim)) return cgi->msg;
    break;
  case 'U':
    if (BBMATCH("URL", key, lim)) return cf->burl;
    break;
  case 'R':
    if (BBMATCH("RS", key, lim)) return cgi->rs;
    break;
  case 'S':
    if (BBMATCH("SKIN", key, lim)) return cgi->skin;
    if (BBMATCH("SIG", key, lim)) return cgi->sig;
    if (BBMATCH("SP_EID", key, lim)) return cgi->sp_eid;
    if (BBMATCH("SP_DPY_NAME", key, lim)) return cgi->sp_dpy_name;
    if (BBMATCH("SP_BUTTON_URL", key, lim)) return cgi->sp_button_url;
    if (BBMATCH("SSOREQ", key, lim)) return cgi->ssoreq;
    if (BBMATCH("SAML_ART", key, lim)) return cgi->saml_art;
    if (BBMATCH("SAML_RESP", key, lim)) return cgi->saml_resp;
    break;
  case 'V':
    if (BBMATCH("VERSION", key, lim)) return zxid_version_str();
    break;
  case 'Z':
    if (BBMATCH("ZXAPP", key, lim)) return cgi->zxapp;
    break;
  }
  D("Unmatched bangbang key(%.*s), taken as empty.", ((int)(lim-key)), key);
  return 0;
}

/*() Expand a template. Only selected !!VAR expansions supported. No IFs or loops. */

/* Called by:  zxid_idp_select_zxstr_cf_cgi, zxid_saml2_post_enc, zxid_simple_idp_show_an, zxid_simple_show_err */
struct zx_str* zxid_template_page_cf(zxid_conf* cf, zxid_cgi* cgi, const char* templ_path, const char* default_templ, int size_hint, int auto_flags)
{
  const char* templ = 0;
  const char* tp;
  const char* tq;
  const char* p;
  char* pp;
  struct zx_str* ss;
  int len;

  if (cgi->skin && *cgi->skin) {
    for (pp = cgi->skin; *pp; ++pp)
      if (*pp == '/') {  /* Squash to avoid accessing files beyond webroot */
	ERR("Illegal character 0x%x (%c) in skin CGI variable (possible attack or misconfiguration)", *pp, *pp);
	*pp = '_';
      }

    /* scan for end of path component, if any. */
    for (p = templ_path + strlen(templ_path)-1;
	 p >= templ_path && !ONE_OF_2(*p, '/', '\\');
	 --p);
    if (p < templ_path)  /* there was no directory component */
      templ = read_all_alloc(cf->ctx, "templ", 1, 0, "%s/%s", cgi->skin, templ_path);
    else
      templ = read_all_alloc(cf->ctx, "templ", 1, 0, "%.*s/%s%s",
			     p-templ_path, templ_path, cgi->skin, p);
    D("Tried to read from skin(%s) templ_path(%s) %p", cgi->skin, templ_path, templ);
  }
  
  if (!templ)
    templ = read_all_alloc(cf->ctx, "templ", 1, 0, "%s", templ_path);
  if (!templ) {
    D("Template at path(%s) not found. Using default template.", templ_path);
    templ = default_templ;
  }
  while (1) {  /* Try rendering, iterate if expansion is needed. */
    tp = templ;
    ss = zx_new_len_str(cf->ctx, strlen(tp) + size_hint);
    for (pp = ss->s; *tp && pp < ss->s + ss->len; ) {
      if (tp[0] == '!' && tp[1] == '!' && AZaz_(tp[2])) {
	for (tq = tp+=2; AZaz_(*tp); ++tp) ;
	tq = zxid_map_bangbang(cf, cgi, tq, tp, auto_flags);
	if (!tq || !*tq)
	  continue;
	len = strlen(tq);
	if (pp + len >= ss->s + ss->len) {
	  pp += len;
	  break;
	}
	memcpy(pp, tq, len);
	pp += len;
	continue;
      }
      *pp++ = *tp++;
    }
    if (pp >= ss->s + ss->len) {
      INFO("Expansion of template does not fit in %d. Enlarging buffer.", ss->len);
      size_hint += size_hint;  /* Double it */
      continue;
    }
    break;
  }
  if (templ && templ != default_templ)
    ZX_FREE(cf->ctx, (void*)templ);
  *pp = 0;
  ss->len = pp - ss->s;
  return ss;
}

/* ------------ zxid_idp_list() ------------ */

/*(i) Generate IdP selection buttons (Login buttons) for the IdPs that are
 * members of our Circle of Trust (CoT). This can be used as component for
 * developing your application specific (HTML) login screen.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_idp_list_cf, zxid_idp_select_zxstr_cf_cgi, zxid_map_bangbang x4 */
char* zxid_idp_list_cf_cgi(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  int i;
  char* s;
  char mark[32];
  struct zx_str* ss;
  struct zx_str* dd;
  zxid_entity* idp;
  zxid_entity* idp_cdc;
  if (auto_flags & ZXID_AUTO_DEBUG) zxid_set_opt(cf, 1, 3);
  idp = zxid_load_cot_cache(cf);
  if (!idp) {
    D("No IdP's found %p", res_len);
    if (res_len)
      *res_len = 0;
    return "";
  }

#if 0
  if ((auto_flags & ZXID_AUTO_FORMT) && (auto_flags & ZXID_AUTO_FORMF))
    ss = zx_dup_str(cf->ctx, "<h3>Login Using Known IdP</h3>\n");
  else
#endif
    ss = zx_dup_str(cf->ctx, "");

  if (cf->idp_list_meth == ZXID_IDP_LIST_POPUP) {
    dd = zx_strf(cf->ctx, "%.*s<select name=d>\n", ss->len, ss->s);
    zx_str_free(cf->ctx, ss);
    ss = dd;
  }

  D("Starting IdP list processing... %p", idp);
  for (; idp; idp = idp->n) {
    if (!idp->ed->IDPSSODescriptor)
      continue;
    
    mark[0] = 0;
    if (cgi) {    /* Was IdP recommended in IdP list supplied via CDC? See zxid_cdc_check() */
      for (idp_cdc = cgi->idp_list, i=1;
	   idp_cdc && idp_cdc != idp;
	   idp_cdc = idp_cdc->n_cdc, ++i);
      if (cf->cdc_choice == ZXID_CDC_CHOICE_UI_ONLY_CDC && cgi->idp_list && !idp_cdc)
	continue;
      if (idp_cdc) {
	snprintf(mark, sizeof(mark), " CDC %d", i);
	mark[sizeof(mark)-1] = 0;
      }
    }

    switch (cf->idp_list_meth) {
    default:
      ERR("Unsupported IDP_LIST_METH=%d, reverting to popup.", cf->idp_list_meth);
      cf->idp_list_meth = ZXID_IDP_LIST_POPUP;
      /* fall thru */
    case ZXID_IDP_LIST_POPUP:
      dd = zx_strf(cf->ctx, "%.*s"
		   "<option class=zxidplistopt value=\"%s\"> %s (%s) %s\n",
		   ss->len, ss->s, idp->eid, STRNULLCHK(idp->dpy_name), idp->eid, mark);
      break;
    case ZXID_IDP_LIST_BUTTON:
      if (cf->show_tech) {
	dd = zx_strf(cf->ctx, "%.*s"
		     "<input type=submit class=zxidplistbut name=\"l0%s\" value=\" Login with %s (%s)\">\n"
		     "<input type=submit class=zxidplistbut name=\"l1%s\" value=\" Login with %s (%s) (A2) \">\n"
		     "<input type=submit class=zxidplistbut name=\"l2%s\" value=\" Login with %s (%s) (P2) \">\n"
		     "<input type=submit class=zxidplistbut name=\"l5%s\" value=\" Login with %s (%s) (S2) \">\n"
		     "<input type=submit class=zxidplistbut name=\"l8%s\" value=\" Login with %s (%s) (O2C) \">"
		     "<input type=submit class=zxidplistbut name=\"l9%s\" value=\" Login with %s (%s) (O2I) \">"
		     "%s<br>\n",
		     ss->len, ss->s,
		     idp->eid, STRNULLCHK(idp->dpy_name), idp->eid,
		     idp->eid, STRNULLCHK(idp->dpy_name), idp->eid,
		     idp->eid, STRNULLCHK(idp->dpy_name), idp->eid,
		     idp->eid, STRNULLCHK(idp->dpy_name), idp->eid,
		     idp->eid, STRNULLCHK(idp->dpy_name), idp->eid,
		     idp->eid, STRNULLCHK(idp->dpy_name), idp->eid,
		     mark);
      } else {
	dd = zx_strf(cf->ctx, "%.*s"
		     "<input type=submit name=\"l0%s\" value=\" Login with %s (%s) \">%s<br>\n",
		     ss->len, ss->s, idp->eid, STRNULLCHK(idp->dpy_name), idp->eid, mark);
      }
      break;
    case ZXID_IDP_LIST_BRAND:
      if (idp->button_url) {  /* see symlabs-saml-displayname-2008.pdf */
	dd = zx_strf(cf->ctx, "%.*s"
		     "<input type=image name=\"l0%s\" src=\"%s\" title=\"%s (%s)\">%s<br>\n",
		     ss->len, ss->s, idp->eid, idp->button_url, STRNULLCHK(idp->dpy_name), idp->eid, mark);
      } else {
	dd = zx_strf(cf->ctx, "%.*s"
		     "<input type=submit name=\"l0%s\" value=\" %s (%s) \">%s<br>\n",
		     ss->len, ss->s, idp->eid, STRNULLCHK(idp->dpy_name), idp->eid, mark);
      }
      break;
    }
    zx_str_free(cf->ctx, ss);
    ss = dd;
  }
  if (cf->idp_list_meth == ZXID_IDP_LIST_POPUP) {
    if (cf->show_tech) {
      dd = zx_strf(cf->ctx, "%.*s</select>"
		   "<input type=submit class=zxidplistbut name=\"l0\" value=\" Login \">\n"
		   "<input type=submit class=zxidplistbut name=\"l1\" value=\" Login (A2) \">\n"
		   "<input type=submit class=zxidplistbut name=\"l2\" value=\" Login (P2) \">\n"
		   "<input type=submit class=zxidplistbut name=\"l5\" value=\" Login (S2) \">\n"
		   "<input type=submit class=zxidplistbut name=\"l8\" value=\" Login (O2C) \">\n"
		   "<input type=submit class=zxidplistbut name=\"l9\" value=\" Login (O2I) \"><br>\n",
		   ss->len, ss->s);
    } else {
      dd = zx_strf(cf->ctx, "%.*s</select>"
		   "<input type=submit id=zxidplistlogin class=zxidplistbut name=\"l0\" value=\" Login \"><br>\n",
		   ss->len, ss->s);
    }
    zx_str_free(cf->ctx, ss);
    ss = dd;
  }

  s = ss->s;
  D("IdP list(%s)", s);
  if (res_len)
    *res_len = ss->len;
  ZX_FREE(cf->ctx, ss);
  return s;
}

/* Called by:  zxid_idp_list_len */
char* zxid_idp_list_cf(zxid_conf* cf, int* res_len, int auto_flags) {
  return zxid_idp_list_cf_cgi(cf, 0, res_len, auto_flags);
}

/* Called by:  zxid_idp_list */
char* zxid_idp_list_len(int conf_len, char* conf, int* res_len, int auto_flags) {
  zxid_conf cf;
  zxid_conf_to_cf_len(&cf, conf_len, conf);
  return zxid_idp_list_cf(&cf, 0, auto_flags);
}

/* Called by: */
char* zxid_idp_list(char* conf, int auto_flags) {
  return zxid_idp_list_len(-1, conf, 0, auto_flags);
}

#define FLDCHK(x,y) (x && x->y ? x->y : "")

/*(i) Render entire IdP selection screen. You may use this code, possibly adjusted
 * by some configuration options (see zxidconf.h), or you may choose to develop
 * your own IdP selection screen from scratch.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_idp_select_zxstr_cf, zxid_simple_show_idp_sel */
struct zx_str* zxid_idp_select_zxstr_cf_cgi(zxid_conf* cf, zxid_cgi* cgi, int auto_flags)
{
  int please_free_tf = 0;
  struct zx_str* ss;
  char* tf;
  char* p;

  DD("HERE e(%s) m(%s) d(%s)", FLDCHK(cgi, err), FLDCHK(cgi, msg), FLDCHK(cgi, dbg));
  if (cf->log_level>1)
    zxlog(cf, 0,0,0,0,0,0,0, "N", "W", "IDPSEL", 0, 0);

#if 1
  if (cgi->templ && *cgi->templ) {
    /* Template supplied by cgi Query String. This is often used
     * to implement tabbed user interface. See also cgi->skin in zxid_template_page_cf()
     * Two problems:
     * 1. This could be an attack so we need to squash dangerous characters
     * 2. It is not very portable to give absolute paths in QS as filesystem
     *    layout and location should not be web developer's concern. Thus
     *    we make requirement that alternate template is in the same subdirectory
     *    as the original and we use the path prefix of the original. */
    D("HERE t(%s)", cgi->templ);
    for (p = cgi->templ; *p; ++p)
      if (*p == '/') {  /* Squash to avoid accessing files beyond webroot */
	ERR("Illegal character 0x%x (%c) in templ CGI variable (possible attack or misconfiguration)", *p, *p);
	*p = '_';
      }
    tf = cgi->templ;
    if (cf->idp_sel_templ_file && *cf->idp_sel_templ_file) {
      /* scan for end of path component, if any. */
      for (p = cf->idp_sel_templ_file + strlen(cf->idp_sel_templ_file)-1;
	   p >= cf->idp_sel_templ_file && !ONE_OF_2(*p, '/', '\\');
	   --p);
      if (p > cf->idp_sel_templ_file) {
	++p;
	D("making tf from old(%.*s) (%s) templ(%s)", (int)(p-cf->idp_sel_templ_file), cf->idp_sel_templ_file, p, cgi->templ);
	tf = ZX_ALLOC(cf->ctx, p-cf->idp_sel_templ_file+strlen(cgi->templ)+1);
	memcpy(tf, cf->idp_sel_templ_file, p-cf->idp_sel_templ_file);
	strcpy(tf + (p-cf->idp_sel_templ_file), cgi->templ);
	please_free_tf = 1;
      }
    }
  } else
    tf = cf->idp_sel_templ_file;
  D("HERE tf(%s) k(%s) t(%s) cgi=%p", STRNULLCHKNULL(tf), STRNULLCHKNULL(cgi->skin), STRNULLCHKNULL(cf->idp_sel_templ), cgi);
  ss = zxid_template_page_cf(cf, cgi, tf, cf->idp_sel_templ, 4096, auto_flags);
  if (please_free_tf)
    ZX_FREE(cf->ctx, tf);
#else
  char* eid=0;
  if (cf->idp_sel_our_eid && cf->idp_sel_our_eid[0])
    eid = zxid_my_ent_id_cstr(cf);
  char* idp_list = zxid_idp_list_cf_cgi(cf, cgi, 0, auto_flags);
  if ((auto_flags & ZXID_AUTO_FORMT) && (auto_flags & ZXID_AUTO_FORMF)) {
    DD("HERE %p", cgi->idp_list);
    ss = zx_strf(cf->ctx,
		 "%s"
#ifdef ZXID_USE_POST
		 "<form method=post action=\"%s?o=P\">\n"
#else
		 "<form method=get action=\"%s\">\n"
#endif
		 "<font color=red>%s</font><font color=green>%s</font><font color=white>%s</font>"
		 "%s"
		 "%s<a href=\"%s\">%s</a><br>"
		 "%s"    /* IdP List */
		 "%s%s"
		 "<input type=hidden name=fr value=\"%s\">\n"
		 "</form>%s%s%s",
		 cf->idp_sel_start,
		 cf->burl,
		 FLDCHK(cgi, err), FLDCHK(cgi, msg), FLDCHK(cgi, dbg),
		 cf->idp_sel_new_idp,
		 cf->idp_sel_our_eid, STRNULLCHK(eid), STRNULLCHK(eid),
		 idp_list,
		 cf->idp_sel_tech_user, cf->idp_sel_tech_site,
		 FLDCHK(cgi, rs),
		 cf->idp_sel_footer, zxid_version_str(), cf->idp_sel_end);
    DD("HERE(%d) ss(%.*s)", ss->len, ss->len, ss->s);
  } else if (auto_flags & ZXID_AUTO_FORMT) {
    ss = zx_strf(cf->ctx,
#ifdef ZXID_USE_POST
		 "<form method=post action=\"%s?o=P\">\n"
#else
		 "<form method=get action=\"%s\">\n"
#endif
		 "<font color=red>%s</font><font color=green>%s</font><font color=white>%s</font>"
		 "%s"
		 "%s<a href=\"%s\">%s</a><br>"
		 "%s"    /* IdP List */
		 "%s%s"
		 "<input type=hidden name=fr value=\"%s\">\n"
		 "</form>",
		 cf->burl,
		 FLDCHK(cgi, err), FLDCHK(cgi, msg), FLDCHK(cgi, dbg),
		 cf->idp_sel_new_idp,
		 cf->idp_sel_our_eid, STRNULLCHK(eid), STRNULLCHK(eid),
		 idp_list,
		 cf->idp_sel_tech_user, cf->idp_sel_tech_site,
		 FLDCHK(cgi, rs));
  } else if (auto_flags & ZXID_AUTO_FORMF) {
    ss = zx_strf(cf->ctx,
		 "<font color=red>%s</font><font color=green>%s</font><font color=white>%s</font>"
		 "%s"
		 "%s<a href=\"%s\">%s</a><br>"
		 "%s"    /* IdP List */
		 "%s%s"
		 "<input type=hidden name=fr value=\"%s\">\n",
		 FLDCHK(cgi, err), FLDCHK(cgi, msg), FLDCHK(cgi, dbg),
		 cf->idp_sel_new_idp,
		 cf->idp_sel_our_eid, STRNULLCHK(eid), STRNULLCHK(eid),
		 idp_list,
		 cf->idp_sel_tech_user, cf->idp_sel_tech_site,
		 FLDCHK(cgi, rs));
  } else
    ss = zx_dup_str(cf->ctx, "");
#endif
#if 0
  if (cgi.err) printf("<p><font color=red><i>%s</i></font></p>\n", cgi.err);
  if (cgi.msg) printf("<p><i>%s</i></p>\n", cgi.msg);
  printf("User:<input name=user> PW:<input name=pw type=password>");
  printf("<input name=login value=\" Login \" type=submit>");
  printf("<h3>Login Using IdP Discovered from Common Domain Cookie (CDC)</h3>\n");
  printf("RelayState: <input name=fr value=\"rs123\"><br>\n");
  if (cgi.dbg) printf("<p><form><textarea cols=100 row=10>%s</textarea></form>\n", cgi.dbg);
#endif
  return ss;
}

/* Called by:  zxid_idp_select_cf */
struct zx_str* zxid_idp_select_zxstr_cf(zxid_conf* cf, int auto_flags) {
  return zxid_idp_select_zxstr_cf_cgi(cf, 0, auto_flags);
}

/* Called by:  zxid_idp_select_len */
char* zxid_idp_select_cf(zxid_conf* cf, int* res_len, int auto_flags) {
  char* s;
  struct zx_str* ss = zxid_idp_select_zxstr_cf(cf, auto_flags);
  s = ss->s;
  if (res_len)
    *res_len = ss->len;
  ZX_FREE(cf->ctx, ss);
  return s;
}

/* Called by:  zxid_idp_select */
char* zxid_idp_select_len(int conf_len, char* conf, int* res_len, int auto_flags) {
  zxid_conf cf;
  zxid_conf_to_cf_len(&cf, conf_len, conf);
  return zxid_idp_select_cf(&cf, 0, auto_flags);
}

/* Called by: */
char* zxid_idp_select(char* conf, int auto_flags) {
  return zxid_idp_select_len(-1, conf, 0, auto_flags);
}

/* ------------ zxid_simple() ------------ */

/*() Deal with the various methods of shipping the page, including CGI stdout, or
 * as string with or without headers, as indicated by the auto_flag. The
 * page is in ss.
 *
 * cf:: ZXID configuration object
 * ss:: The page
 * c_mask:: auto_flags content mask
 * h_mask:: auto_flags headers mask
 * rets:: Return value in case content is output (not returned)
 * cont_type:: content-type header
 * res_len:: Response length, pass 0 if not needed
 * auto_flags:: flags to control if content is output or returned
 * status:: Additional CGI headers, such as Status: 201 Created
 * return:: Depends on autoflags and masks. Can be headers+data, data only, or rets (data
 *     was output to stdout, cgi style)
 */

/* Called by:  zxid_idp_oauth2_check_id, zxid_simple_idp_show_an, zxid_simple_show_carml, zxid_simple_show_conf, zxid_simple_show_err, zxid_simple_show_idp_sel, zxid_simple_show_meta */
char* zxid_simple_show_page(zxid_conf* cf, struct zx_str* ss, int c_mask, int h_mask, char* rets, char* cont_type, int* res_len, int auto_flags, const char* status)
{
  char* res;
  struct zx_str* ss2;
  if (auto_flags & c_mask && auto_flags & h_mask) {  /* Both H&C: CGI */
    int extralen = 0;
    D("CGI %x ss->len=%d ss->s=%p ss->s[0]=%x", auto_flags, ss->len, ss->s, ss->s[0]);
    /*hexdmp("ss->s: ", ss->s, ss->len, 40);*/
#ifdef MINGW
    /* It seems that Apache strips off the \n in this output when running as a CGI Script. 
     * This means the content length does not reflect reality, and we end up losing the 
     * last N bytes, where N is the number of newlines in the output
     */
    char *p = ss->s;
    while(*p != '\0') {
      if(*p == '\n')
	++extralen;
      p++;
    }
#endif
    fprintf(stdout, "%sContent-Type: %s" CRLF "Content-Length: %d" CRLF2 "%.*s",
	    STRNULLCHK(status), cont_type, ss->len+extralen, ss->len+extralen, ss->s);
    fflush(stdout);
    DD("__stdio_file fd=%d flags=%x bs=%d bm=%d buflen=%d buf=%p buf(%.4s) next=%p pok=%d unget=%x ungotten=%x", stdout->fd, stdout->flags, stdout->bs, stdout->bm, stdout->buflen, stdout->buf, stdout->buf, stdout->next, stdout->popen_kludge, stdout->ungetbuf, stdout->ungotten);
    if (auto_flags & ZXID_AUTO_EXIT)
      exit(0);
    zx_str_free(cf->ctx, ss);
    if (res_len)
      *res_len = 1;
    return zx_dup_cstr(cf->ctx, "n");
  }
  
  if (auto_flags & (c_mask | h_mask)) {
    if (auto_flags & h_mask) {  /* H only: return both H and C */
      if (errmac_debug & MOD_AUTH_SAML_INOUT) D("With headers %x (%s)", auto_flags, ss->s);
      ss2 = zx_strf(cf->ctx, "%sContent-Type: %s" CRLF "Content-Length: %d" CRLF2 "%.*s",
		    STRNULLCHK(status), cont_type, ss->len, ss->len, ss->s);
      zx_str_free(cf->ctx, ss);
    } else {
      D("No headers %x (%s)", auto_flags, ss->s);
      ss2 = ss;       /* C only */
    }
    res = ss2->s;
    DD("res(%s)", res);
    if (res_len)
      *res_len = ss2->len;
    ZX_FREE(cf->ctx, ss2);
    return res;
  }
  /* Do not output anything (both c and h 0). Effectively the generated page is thrown away. */
  D("e(%.*s) cm=%x hm=%x af=%x rets(%s)", ss?ss->len:-1, ss?ss->s:"", c_mask, h_mask, auto_flags, rets);
  if (ss)
    zx_str_free(cf->ctx, ss);
  if (res_len)
    *res_len = 1;
  return zx_dup_cstr(cf->ctx, rets);   /* Neither H nor C */
}

/*() Show JSON page, as often needed in OAUTH2 */

char* zxid_simple_show_json(zxid_conf* cf, const char* json, int* res_len, int auto_flags, const char* status)
{
  struct zx_str* ss = zx_ref_str(cf->ctx, json);
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_METAC, ZXID_AUTO_METAH, "J", "application/json", res_len, auto_flags, status);
}

/*() Helper function to redirect according to auto flags. */

/* Called by:  zxid_show_protected_content_setcookie, zxid_simple_idp_an_ok_do_rest, zxid_simple_idp_new_user, zxid_simple_idp_recover_password, zxid_simple_idp_show_an, zxid_simple_show_err, zxid_simple_show_idp_sel */
static char* zxid_simple_redir_page(zxid_conf* cf, char* redir, char* rs, int* res_len, int auto_flags)
{
  char* res;
  struct zx_str* ss;
  D("cf=%p redir(%s)", cf, redir);
  if (auto_flags & ZXID_AUTO_REDIR) {
    fprintf(stdout, "Location: %s%c%s" CRLF2, redir, rs?'?':0, STRNULLCHK(rs));
    fflush(stdout);
    if (auto_flags & ZXID_AUTO_EXIT)
      exit(0);
    if (res_len)
      *res_len = 1;
    return zx_dup_cstr(cf->ctx, "n");
  }
  ss = zx_strf(cf->ctx, "Location: %s%c%s" CRLF2, redir, rs?'?':0, STRNULLCHK(rs));
  if (res_len)
    *res_len = ss->len;
  res = ss->s;
  ZX_FREE(cf->ctx, ss);
  return res;
}

/*() Show IdP selection or login screen.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_ps_accept_invite, zxid_ps_finalize_invite, zxid_simple_no_ses_cf, zxid_simple_ses_active_cf x5 */
char* zxid_simple_show_idp_sel(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  struct zx_str* ss;  
  zxid_sso_set_relay_state_to_return_to_this_url(cf, cgi);

  D("cf=%p cgi=%p templ(%s)", cf, cgi, STRNULLCHKQ(cgi->templ));
  if (cf->idp_sel_page && cf->idp_sel_page[0]) {
    D("idp_sel_page(%s) rs(%s)", cf->idp_sel_page, STRNULLCHK(cgi->rs));
    return zxid_simple_redir_page(cf, cf->idp_sel_page, cgi->rs, res_len, auto_flags);
  }
  ss = auto_flags & (ZXID_AUTO_LOGINC | ZXID_AUTO_LOGINH)
    ? zxid_idp_select_zxstr_cf_cgi(cf, cgi, auto_flags)
    : 0;
  DD("idp_select: ret(%s)", ss?ss->len:1, ss?ss->s:"?");
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_LOGINC, ZXID_AUTO_LOGINH,
			       "e", "text/html", res_len, auto_flags, 0);
}


/*() Emit metadata. Corresponds to "o=B" query string.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_simple_no_ses_cf x2, zxid_simple_ses_active_cf x2 */
static char* zxid_simple_show_meta(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  struct zx_str* meta = zxid_sp_meta(cf, cgi);
  return zxid_simple_show_page(cf, meta, ZXID_AUTO_METAC, ZXID_AUTO_METAH,
			       "b", "text/xml", res_len, auto_flags, 0);
}

/*() Emit CARML declaration for SP. Corresponds to "o=c" query string. */

/* Called by:  zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
static char* zxid_simple_show_carml(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  struct zx_str* carml = zxid_sp_carml(cf);
  return zxid_simple_show_page(cf, carml, ZXID_AUTO_METAC, ZXID_AUTO_METAH,
			       "c", "text/xml", res_len, auto_flags, 0);
}

/*() Dump internal info and configuration. Corresponds to "o=d" query string. */

/* Called by:  zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
static char* zxid_simple_show_conf(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  struct zx_str* ss = zxid_show_conf(cf);
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_METAC, ZXID_AUTO_METAH,
			       "d", "text/html", res_len, auto_flags, 0);
}

/*() Emit Java Web Key Set. Corresponds to "o=j" query string. */

/* Called by:  zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
static char* zxid_simple_show_jwks(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  struct zx_str* ss = zx_ref_str(cf->ctx, zxid_mk_jwks(cf));
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_METAC, ZXID_AUTO_METAH,
			       "j",
			       //"text/json",
			       "application/jwk-set+json",
			       res_len, auto_flags, 0);
}

/*() Perform and reply to OAUTH2 Dynamic Client Registration. Corresponds to "o=J" query string. */

/* Called by:  zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
static char* zxid_simple_show_dynclireg(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  return zxid_simple_show_json(cf, zxid_mk_oauth2_dyn_cli_reg_res(cf, cgi),
			       res_len, auto_flags, "Status: 201 Created" CRLF);
}

/*() Perform and reply to OAUTH2 Resource Registration. Corresponds to "o=H" query string. */

/* Called by:  zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
static char* zxid_simple_show_rsrcreg(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  char rev[256];
  char status_etag[1024];
  char* json = zxid_mk_oauth2_rsrc_reg_res(cf, cgi, rev);
  snprintf(status_etag, sizeof(status_etag), "Status: 201 Created" CRLF "Etag: %s" CRLF, rev);
  return zxid_simple_show_json(cf, json, res_len, auto_flags, status_etag);
}

/*() Show Error screen. */

/* Called by:  zxid_ps_accept_invite x4, zxid_ps_finalize_invite x4 */
char* zxid_simple_show_err(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  char* p;
  struct zx_str* ss;
  
  if (cf->log_level>1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "ERR", 0, "");

  if (cf->err_page && cf->err_page[0]) {
    p = zx_alloc_sprintf(cf->ctx, 0, "zxrfr=F%s%s%s%s&zxidpurl=%s",
		 cgi->zxapp && cgi->zxapp[0] ? "&zxapp=" : "", cgi->zxapp ? cgi->zxapp : "",
		 cgi->err && cgi->err[0] ? "&err=" : "", cgi->err ? cgi->err : "",
		 cf->burl);
    D("err_page(%s) p(%s)", cf->err_page, p);
    return zxid_simple_redir_page(cf, cf->err_page, p, res_len, auto_flags);
  }
    
  ss = zxid_template_page_cf(cf, cgi, cf->err_templ_file, cf->err_templ, 4096, auto_flags);
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_LOGINC, ZXID_AUTO_LOGINH,
			       "g", "text/html", res_len, auto_flags, 0);
}

/* ----------- IdP Screens ----------- */

/*() Decode ssoreq (ar=), i.e. the preserved original AuthnReq */

/* Called by:  zxid_simple_idp_pw_authn, zxid_simple_idp_show_an, zxid_sp_sso_finalize */
int zxid_decode_ssoreq(zxid_conf* cf, zxid_cgi* cgi)
{
  int len;
  char* p;
  if (!cgi->ssoreq || !cgi->ssoreq[0])
    return 1;
  p = zxid_unbase64_inflate(cf->ctx, -2, cgi->ssoreq, &len);
  if (!p)
    return 0;
  cgi->op = 0;
  D("ar/ssoreq decoded(%s) len=%d", p, len);
  zxid_parse_cgi(cf, cgi, p);  /* cgi->op will be Q due to SAMLRequest inside ssoreq */
  cgi->op = 'F';
  return 1;
}

/*() Process IdP side after successful authentication. If IdP was
 * invoked with AuthnReq (in SAMLRequest) then op=='F' as set
 * in zxid_simple_idp_pw_authn() which will trigger the rest of the
 * SSO protocol in zxid_simple_ses_active_cf(). Otherwise just
 * show the IdP management screen. */

/* Called by:  zxid_simple_idp_pw_authn, zxid_simple_idp_show_an */
static char* zxid_simple_idp_an_ok_do_rest(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags)
{
  int len;
  char* p;
  DD("idp do_rest %p", ses);
  if (cf->atsel_page && cgi->atselafter) { /* *** More sophisticated criteria needed. */
    p = zx_alloc_sprintf(cf->ctx, 0, "ar=%s&s=%s&zxrfr=F%s%s%s%s&zxidpurl=%s",
		 cgi->ssoreq, cgi->sid,
		 cgi->zxapp && cgi->zxapp[0] ? "&zxapp=" : "", cgi->zxapp ? cgi->zxapp : "",
		 cgi->err && cgi->err[0] ? "&err=" : "", cgi->err ? cgi->err : "",
		 cf->burl);
    D("atsel_page(%s) redir(%s)", cf->atsel_page, p);
    return zxid_simple_redir_page(cf, cf->atsel_page, p, res_len, auto_flags);
  }
  if (cgi->redirafter && *cgi->redirafter) {
    len = strlen(cgi->redirafter);
    if (!strcmp(cgi->redirafter + len - sizeof("s=X") + 1, "s=X")) {
      p = zx_alloc_sprintf(cf->ctx, 0, "%.*s%s", len-1, cgi->redirafter, cgi->sid);
      D("redirafter(%s)", p);
      return zxid_simple_redir_page(cf, p, 0, res_len, auto_flags);
    } else {
      return zxid_simple_redir_page(cf, cgi->redirafter, 0, res_len, auto_flags);
    }
  }
  return zxid_simple_ses_active_cf(cf, cgi, ses, res_len, auto_flags); /* o=F variant */
}

/*() Show Authentication screen. Generally this will be in response to
 * the SP having sent user via redirect to o=F carrying AuthnRequest encoded
 * in SAMLRequest query string parameter, per SAML redirect binding
 * [SAML2bind].  We must preserve SAMLRequest as hidden field, ar, in the
 * page for later processing once the authentication step has been
 * taken care of. It will also be passed on the query string to
 * external authentication page if any was configured with AN_PAGE
 * directive.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_simple_idp_new_user, zxid_simple_idp_pw_authn, zxid_simple_idp_recover_password, zxid_simple_no_ses_cf */
static char* zxid_simple_idp_show_an(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  char* p;
  char* ar;
  struct zx_sa_Issuer_s* issuer;
  zxid_entity* meta;
  struct zx_root_s* root;
  struct zx_str* ss;
  zxid_ses sess;
  ZERO(&sess, sizeof(sess));
  D("cf=%p cgi=%p", cf, cgi);
  DD("z saml_req(%s) rs(%s) sigalg(%s) sig(%s)", cgi->saml_req, cgi->rs, cgi->sigalg, cgi->sig);  
  if ((cgi->uid || cgi->pcode) && zxid_pw_authn(cf, cgi, &sess)) {  /* Try login, just in case. */
    return zxid_simple_idp_an_ok_do_rest(cf, cgi, &sess, res_len, auto_flags);
  }
  if (cgi->redirafter) { /* Save next screen for local login (e.g. zxidatsel.pl */
    D("zz redirafter(%s) rs(%s)", cgi->redirafter, cgi->rs);  
    cgi->ssoreq = zxid_deflate_safe_b64(cf->ctx,
		    zx_strf(cf->ctx,
			    "redirafter=%s",
			    cgi->redirafter));
  }
  if (cgi->response_type) { /* Save incoming OAUTH2 / OpenID-Connect Az request as hidden field */
    DD("zz response_type(%s) rs(%s)", cgi->response_type, cgi->rs);  
    cgi->ssoreq = zxid_deflate_safe_b64(cf->ctx,
		    zx_strf(cf->ctx,
			    "response_type=%s"
			    "&client_id=%s"
			    "&scope=%s"
			    "&redirect_uri=%s"
			    "&nonce=%s"
			    "%s%s"           /* &state= */
			    "%s%s"           /* &display= */
			    "%s%s",          /* &prompt= */
			    cgi->response_type,
			    cgi->client_id,
			    cgi->scope,
			    cgi->redirect_uri,
			    cgi->nonce,
			    cgi->state?"&state=":"", STRNULLCHK(cgi->state),
			    cgi->display?"&display=":"", STRNULLCHK(cgi->display),
			    cgi->prompt?"&prompt=":"", STRNULLCHK(cgi->prompt)
			    ));
  }
  if (cgi->saml_req) {  /* Save incoming SAMLRequest as hidden form field ar */
    DD("zz saml_req(%s) rs(%s) sigalg(%s) sig(%s)", cgi->saml_req, cgi->rs, cgi->sigalg, cgi->sig);
    cgi->ssoreq = zxid_deflate_safe_b64(cf->ctx,
		    zx_strf(cf->ctx, "SAMLRequest=%s%s%s&SigAlg=%s&Signature=%s",
			    STRNULLCHK(cgi->saml_req),
			    cgi->rs && cgi->rs[0] ? "&RelayState=" : "", cgi->rs ? cgi->rs : "",
			    STRNULLCHK(cgi->sigalg),
			    STRNULLCHK(cgi->sig)));
  }
  
  if (cf->an_page && cf->an_page[0]) {  /* Redirect to sysadmin configured page */
    ar = zx_alloc_sprintf(cf->ctx, 0, "ar=%s&zxrfr=F%s%s%s%s&zxidpurl=%s",
		 cgi->ssoreq,
		 cgi->zxapp && cgi->zxapp[0] ? "&zxapp=" : "", cgi->zxapp ? cgi->zxapp : "",
		 cgi->err && cgi->err[0] ? "&err=" : "", cgi->err ? cgi->err : "",
		 cf->burl);
    if (cgi->ssoreq)
      ZX_FREE(cf->ctx, cgi->ssoreq);
    D("an_page(%s) ar(%s)", cf->an_page, ar);
    return zxid_simple_redir_page(cf, cf->an_page, ar, res_len, auto_flags);
  }
  
  if (cf->log_level>1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "AUTHN", 0, "");
  
  /* Attempt to provisorily decode the request and fetch metadata of the SP so we
   * can detect trouble early on and provide some assuring knowledge to the user. */
  
  if (!cgi->saml_req && !cgi->response_type && cgi->ssoreq) {
    zxid_decode_ssoreq(cf, cgi);
  }
  
  if (cgi->response_type) {  /* OAUTH2 AzReq redir (OpenID-Connect) */
    if (cgi->client_id) {
      meta = zxid_get_ent(cf, cgi->client_id);
      if (meta) {
	cgi->sp_eid = meta->eid;
	cgi->sp_dpy_name = meta->dpy_name;
	cgi->sp_button_url = meta->button_url;
      } else {
	ERR("Unable to find metadata for client_id(%s) in OAUTH2 AzReq Redir", cgi->client_id);
	cgi->err = "OAUTH2 client_id unknown - metadata exchange may be needed (AnReq).";
	cgi->sp_dpy_name = "--SP description unavailable--";
	cgi->sp_eid = zx_dup_cstr(cf->ctx, cgi->client_id);
      }
    } else {
      cgi->err = "OAUTH2 client_id missing.";
      cgi->sp_eid = "";
      cgi->sp_dpy_name = "--No SP could be determined--";
    }
  } else { /* Assume SAML2 */
    root = zxid_decode_redir_or_post(cf, cgi, &sess, 0x2);
    if (root) {
      issuer = zxid_extract_issuer(cf, cgi, &sess, root);
      if (ZX_SIMPLE_ELEM_CHK(issuer)) {
	meta = zxid_get_ent_ss(cf, ZX_GET_CONTENT(issuer));
	if (meta) {
	  cgi->sp_eid = meta->eid;
	  cgi->sp_dpy_name = meta->dpy_name;
	  cgi->sp_button_url = meta->button_url;
	} else {
	  ERR("Unable to find metadata for Issuer(%.*s) in AnReq Redir", ZX_GET_CONTENT_LEN(issuer), ZX_GET_CONTENT_S(issuer));
	  cgi->err = "Issuer unknown - metadata exchange may be needed (AnReq).";
	  cgi->sp_dpy_name = "--SP description unavailable--";
	  cgi->sp_eid = zx_str_to_c(cf->ctx, ZX_GET_CONTENT(issuer));
	}
      } else {
	cgi->err = "Issuer could not be determined from Authentication Request.";
	cgi->sp_eid = "";
	cgi->sp_dpy_name = "--No SP could be determined--";
      }
    } else {
      cgi->err = "Malformed or nonexistant Authentication Request";
      cgi->sp_eid = "";
      cgi->sp_dpy_name = "--No SP could be determined--";
    }
  }

  /* Render the authentication page */
  if (cgi->templ) {
    cf->an_templ_file = cgi->templ;
    for (p = cf->an_templ_file; *p; ++p)
      if (*p == '/') {  /* Squash to avoid accessing files beyond webroot */
	ERR("Illegal character 0x%x (%c) in templ CGI variable (possible attack or misconfiguration)", *p, *p);
	*p = '_';
      }
  }
#if 1
  /* Hack: Different page for mobile */
  if (cgi->mob) {
    D("Mobile detected TF(%s)", cf->an_templ_file);
    /* Replace final .html  with -mob.html */
    cf->an_templ_file = zx_alloc_sprintf(cf->ctx, 0, "%.*s-mob.html",
					 strlen(cf->an_templ_file)-sizeof(".html")+1,
					 cf->an_templ_file);
    D("New TF(%s)", cf->an_templ_file);
  }
#endif
  ss = zxid_template_page_cf(cf, cgi, cf->an_templ_file, cf->an_templ, 4096, auto_flags);
  /* if (cgi->ssoreq) ZX_FREE(cf->ctx, cgi->ssoreq); might not be malloc'd if tabs have CGI */
  DD("an_page: ret(%s)", ss?ss->len:1, ss?ss->s:"?");
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_LOGINC, ZXID_AUTO_LOGINH,
			       "a", "text/html", res_len, auto_flags, 0);
}

/*() Process password authentication form and, if ssoreq (ar=) is present
 * (see zxid_simple_idp_show_an() for how it is embedded to hidden
 * form field), proceed to federated SSO. If login fails, redisplay
 * the authentication page.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_simple_no_ses_cf */
static char* zxid_simple_idp_pw_authn(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  zxid_ses sess;
  D("cf=%p cgi=%p", cf, cgi);
 
  if (!zxid_decode_ssoreq(cf, cgi))
    goto err;

  ZERO(&sess, sizeof(sess));
  if (zxid_pw_authn(cf, cgi, &sess))
    return zxid_simple_idp_an_ok_do_rest(cf, cgi, &sess, res_len, auto_flags);

  D("PW Login failed uid(%s) pw(%s) err(%s)", STRNULLCHK(cgi->uid), STRNULLCHK(cgi->pw), STRNULLCHK(cgi->err));
 err:
  return zxid_simple_idp_show_an(cf, cgi, res_len, auto_flags);
}

/*() Redirect user to new user creation page. */

/* Called by:  zxid_simple_no_ses_cf */
static char* zxid_simple_idp_new_user(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  char* p;
  D("cf=%p cgi=%p", cf, cgi);

  // ***

  if (cf->new_user_page && cf->new_user_page[0]) {
    p = zx_alloc_sprintf(cf->ctx, 0, "ar=%s&zxrfr=F%s%s%s%s&zxidpurl=%s",
		 STRNULLCHK(cgi->ssoreq),
		 cgi->zxapp && cgi->zxapp[0] ? "&zxapp=" : "", cgi->zxapp ? cgi->zxapp : "",
		 cgi->err && cgi->err[0] ? "&err=" : "", cgi->err ? cgi->err : "",
		 cf->burl);
    D("new_user_page(%s) redir(%s)", cf->new_user_page, p);
    return zxid_simple_redir_page(cf, cf->new_user_page, p, res_len, auto_flags);
  }

  ERR("No new user page URL defined. (IdP config problem, or IdP intentionally does not support online new user creation. See NEW_USER_PAGE config option.) %d", 0);
  cgi->err = "No new user page URL defined. (IdP config problem, or IdP intentionally does not support online new user creation.)";
  
  return zxid_simple_idp_show_an(cf, cgi, res_len, auto_flags);
}

/*() Redirect user to recover password page. */

/* Called by:  zxid_simple_no_ses_cf */
static char* zxid_simple_idp_recover_password(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
  char* p;
  D("cf=%p cgi=%p", cf, cgi);

  // ***

  if (cf->recover_passwd && cf->recover_passwd[0]) {
    p = zx_alloc_sprintf(cf->ctx, 0, "ar=%s&zxrfr=F%s%s%s%s&zxidpurl=%s",
		 STRNULLCHK(cgi->ssoreq),
		 cgi->zxapp && cgi->zxapp[0] ? "&zxapp=" : "", cgi->zxapp ? cgi->zxapp : "",
		 cgi->err && cgi->err[0] ? "&err=" : "", cgi->err ? cgi->err : "",
		 cf->burl);
    D("recover_passwd(%s) redir(%s)", cf->recover_passwd, p);
    return zxid_simple_redir_page(cf, cf->recover_passwd, p, res_len, auto_flags);
  }

  ERR("No password recover page URL defined. (IdP config problem, or IdP intentionally does not support online password recovery. See RECOVER_PASSWD config option.) %d", 0);
  cgi->err = "No password recover page URL defined. (IdP config problem, or IdP intentionally does not support online password recovery.)";
  
  return zxid_simple_idp_show_an(cf, cgi, res_len, auto_flags);
}

/*() Final steps of SSO: set the cookies and check authorization
 * before returning the LDIF. */

/* Called by:  zxid_simple_no_ses_cf x2 */
static char* zxid_show_protected_content_setcookie(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags)
{
  struct zx_str* issuer;
  struct zx_str* url;
  zxid_epr* epr;
  char* rs;
  char* rs_qs;

  if (cf->ses_cookie_name && *cf->ses_cookie_name) {
    ses->setcookie = zx_alloc_sprintf(cf->ctx, 0, "%s=%s; path=/%s%s",
				      cf->ses_cookie_name, ses->sid,
				      cgi->mob?"; Max-Age=15481800":"",
				      ONE_OF_2(cf->burl[4], 's', 'S')?"; secure; HttpOnly":"; HttpOnly");
    ses->cookie = zx_alloc_sprintf(cf->ctx, 0, "$Version=1; %s=%s",
				   cf->ses_cookie_name, ses->sid);
    D("setcookie(%s)=(%s) ses=%p", cf->ses_cookie_name, ses->setcookie, ses);
  }
  if (cf->ptm_cookie_name && *cf->ptm_cookie_name) {
    D("ptm_cookie_name(%s) ses->a7n=%p", cf->ptm_cookie_name, ses->a7n);
    issuer = ses->a7n?ZX_GET_CONTENT(ses->a7n->Issuer):0;
    if (!issuer)
      ERR("Assertion does not have Issuer. %p", ses->a7n);
    
    if (epr = zxid_get_epr(cf, ses, TAS3_PTM, 0, 0, 0, 1)) {
      url = zxid_get_epr_address(cf, epr);
      if (!url)
	ERR("EPR does not have Address. %p", epr);
      ses->setptmcookie = zx_alloc_sprintf(cf->ctx, 0, "%s=%.*s?l0%.*s=1; path=/%s",
					   cf->ptm_cookie_name,
					   url?url->len:0, url?url->s:"",
					   issuer?issuer->len:0, issuer?issuer->s:"",
					   ONE_OF_2(cf->burl[4], 's', 'S')?"; secure":"");
      //ses->ptmcookie = zx_alloc_sprintf(cf->ctx,0,"$Version=1; %s=%s",cf->ptm_cookie_name,?);
      D("setptmcookie(%s)", ses->setptmcookie);
    } else {
      D("The PTM epr could not be discovered. Has it been registered at discovery service? Is there a discovery service? %p", epr);
    }
  }
  // *** check cf->redir_to_content here
  ses->rs = cgi->rs;
  if (cgi->rs && cgi->rs[0] && cgi->rs[0] != '-') {
    /* N.B. RelayState was set by chkuid() "some other page" section by setting cgi.rs
     * to deflated and safe base64 encoded value which was then sent to IdP as RelayState.
     * It then came back from IdP and was decoded as one of the SSO attributes.
     * The decoding is controlled by <<tt: rsrc$rs$unsb64-inf$$ >>  rule in OUTMAP. */
    cgi->redirect_uri = rs = zxid_unbase64_inflate(cf->ctx, -2, cgi->rs, 0);
    if (!rs) {
      ERR("Bad relaystate. Error in inflate. %d", 0);
      goto erro;
    }
    if (!*rs) {
      D("Empty rs %p", rs);
      goto erro;
    }
    if (cgi->uri_path) {
      rs_qs = strchr(rs, '?');
      if (rs_qs /* if there is query string, compare differently */
	  ?(memcmp(cgi->uri_path, rs, rs_qs-rs)||strcmp(cgi->qs?cgi->qs:"",rs_qs+1))
	  :strcmp(cgi->uri_path, rs)) {  /* Different, need external or internal redirect */
	D("redirect(%s) redir_to_content=%d", rs, cf->redir_to_content);
	if (cf->redir_to_content) {
	  return zxid_simple_redir_page(cf, rs, 0, res_len, auto_flags);
	} else {
	  D("*** internal redirect(%s)", rs);
	}
      }
    }
  }
 erro:
  return zxid_simple_ab_pep(cf, ses, res_len, auto_flags);
}

/* ===== Main Control Logic for Session Active and Session Inactive Cases ===== */

/*() Subroutine of zxid_simple_cf() for the session active case.
 * cgi->uri_path should have been set by the caller.
 *
 * NULL return means the "not logged in" processing is needed, see zxid_simple_no_ses_cf()
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  chkuid x2, zxid_mini_httpd_sso x2, zxid_simple_cf_ses, zxid_simple_idp_an_ok_do_rest, zxid_sp_dispatch, zxid_sp_oauth2_dispatch */
char* zxid_simple_ses_active_cf(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags)
{
  struct zx_str* accr;
  char* p;
  char* res = 0;
  struct zx_str* ss;
  
  if (!cf || !cgi || !ses) {
    ERR("FATAL: NULL pointer. You MUST supply configuration(%p), cgi(%p), and session(%p) objects (programming error)", cf, cgi, ses);
    NEVERNEVER("Bad args %p", cf);
  }
  if (cf->wd)
    chdir(cf->wd);
  
  /* OPs (the o= CGI field. Not to be confused with first letter of zxid_simple() return value)
   * l = local logout (form gl)
   * r = SLO redir    (form gr)
   * s = SLO soap     (form gs)
   * t = nireg redir  (form gt, gn=newnym)
   * u = nireg soap   (form gu, gn=newnym)
   * v = Az soap      (form gv)
   * c = CARML for the SP
   * d = Dump internal data, including config; debug screen
   * m = Show management screen
   * n = Just check session (used for checking session for protected content pages)
   * p = Password Login (IdP form submit alp= with au= and ap=)
   * P = POST response. HTTP POST in general
   * Q = POST request
   * R = POST request to IdP
   * S = SOAP (POST) request
   * Y = SOAP (POST) request for PDP and misc support services
   * Z = SOAP (POST) request for discovery
   * B = Metadata
   * b = Metadata Authority
   * j = jwks
   * J = OAUTH2 Dynamic client registration endpoint
   * H = OAUTH2 Resource Registration endpoint
   *
   * M = CDC redirect and LECP detect
   * C = CDC reader
   * E = Normal "Entry" page (e.g. after CDC read, idpsel)
   * L = Start SSO (submit of E)
   * A = Artifact processing
   * N = New User, during IdP Login (form an)
   * W = Recover password,  during IdP Login (form aw)
   * D = Delegation / Invitation acceptance user interface, the idp selection
   * G = Delegation / Invitation finalization after SSO (via RelayState)
   * O = OAuth2 redirect destination
   * T = OAuth2 Check ID / Token Endpoint
   *
   * I = used for IdP ???
   * K = used?
   * F = IdP: Return SSO A7N after successful An; no ses case, generate IdP ui
   * V = Proxy IdP return
   *
   * Still available: UWXacefghikqwxyz
   */
  
  if (cgi->enc_hint)
    cf->nameid_enc = cgi->enc_hint != '0';
  D("op(%c) sesid(%s) active", cgi->op?cgi->op:'-', STRNULLCHK(cgi->sid));
  DD("ses(%s) active op(%c) saml_req(%s)",cgi->sid,cgi->op?cgi->op:'-', STRNULLCHK(cgi->saml_req));
  switch (cgi->op) {
  case 'l':
    if (cf->log_level>0)
      zxlog(cf, 0,0,0,0,0,0, ZX_GET_CONTENT(ses->nameid), "N", "W", "LOCLO", ses->sid,0);
    zxid_del_ses(cf, ses);
    cgi->msg = "Local logout Ok. Session terminated.";
    return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);
  case 'r':
    ss = zxid_sp_slo_redir(cf, cgi, ses);
    zxid_del_ses(cf, ses);
    goto redir_ok;
  case 's':
    zxid_sp_slo_soap(cf, cgi, ses);
    zxid_del_ses(cf, ses);
    cgi->msg = "SP Initiated logout (SOAP). Session terminated.";
    return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);
  case 't':
    ss = zxid_sp_mni_redir(cf, cgi, ses, zx_ref_str(cf->ctx, cgi->newnym));
    goto redir_ok;
  case 'u':
    zxid_sp_mni_soap(cf, cgi, ses, zx_ref_str(cf->ctx, cgi->newnym));
    cgi->msg = "SP Initiated defederation (SOAP).";
    break;     /* Defederation does not have to mean SLO */
  case 'v':    /* N.B. This is just testing facility. The result is ignored. */
    zxid_pep_az_soap_pepmap(cf, cgi, ses, cf->pdp_call_url?cf->pdp_call_url:cf->pdp_url, cf->pepmap, "test (o=v)");
    cgi->msg = "PEP-to-PDP Authorization call (SOAP).";
    break;     /* Defederation does not have to mean SLO */
  case 'm':
    res = zxid_fed_mgmt_cf(cf, res_len, -1, cgi->sid, auto_flags);
    if (auto_flags & ZXID_AUTO_EXIT)
      exit(0);
    return res;
  case 'P':    /* POST Profile Responses */
  case 'I':
  case 'K':
  case 'Q':    /* POST Profile Requests */
    D("saml_req(%s) rs(%s) sigalg(%s) sig(%s)", STRNULLCHK(cgi->saml_req), STRNULLCHK(cgi->rs), STRNULLCHK(cgi->sigalg), STRNULLCHK(cgi->sig));
    ss = zxid_sp_dispatch(cf, cgi, ses);
    switch (ss->s[0]) {
    case 'K': return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);
    case 'L': goto redir_ok;
    case 'I': goto idp;
    }
    D("Q ss(%.*s) (fall thru)", ss->len, ss->s);
    break;

     /*  Delegation / Invitation URL clicked. */
  case 'D':  return zxid_ps_accept_invite(cf, cgi, ses, res_len, auto_flags);
  case 'G':  return zxid_ps_finalize_invite(cf, cgi, ses, res_len, auto_flags);

  case 'V':  /* (PXY) Middle IdP of Proxy IdP flow */
    ss = zxid_idp_dispatch(cf, cgi, ses, 0);  /* N.B. The original request is in cgi->saml_req */
    goto ret_idp_dispatch;
  case 'R':
    cgi->op = 'F';
    /* Fall thru */
  case 'F': /*  IdP: Return SSO A7N after successful An; no ses case, generate IdP ui */
  idp:
    ss = zxid_idp_dispatch(cf, cgi, ses, 1);  /* N.B. The original request is in cgi->saml_req */
  ret_idp_dispatch:
    switch (ss->s[0]) {
    case 'K': return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags); /* proxy IdP */
    case 'C': /* Content-type:  -- i.e. ship page or XML out */
    case 'L':
  redir_ok:
      if (auto_flags & ZXID_AUTO_REDIR) {
	fprintf(stdout, "%.*s", ss->len, ss->s);
	fflush(stdout);
	zx_str_free(cf->ctx, ss);
	goto cgi_exit;
      } else
	goto res_zx_str;
    }
    D("idp err(%.*s) (fall thru)", ss->len, ss->s);
    /* *** */
    break;
  case 'H': return zxid_simple_show_rsrcreg(cf, cgi, res_len, auto_flags);
  case 'J': return zxid_simple_show_dynclireg(cf, cgi, res_len, auto_flags);
  case 'j': return zxid_simple_show_jwks(cf, cgi, res_len, auto_flags);
  case 'c': return zxid_simple_show_carml(cf, cgi, res_len, auto_flags);
  case 'd': return zxid_simple_show_conf(cf, cgi, res_len, auto_flags);
  case 'B': return zxid_simple_show_meta(cf, cgi, res_len, auto_flags);
  case 'b': return zxid_simple_md_authority(cf, cgi, res_len, auto_flags);
  case 'n': break;
  case 'p': break;
  default:
    if (cf->bare_url_entityid)
      return zxid_simple_show_meta(cf, cgi, res_len, auto_flags);
  }
  if (cf->required_authnctx) {
    zxid_get_ses_sso_a7n(cf, ses);
    accr = ses->a7n&&ses->a7n->AuthnStatement&&ses->a7n->AuthnStatement->AuthnContext
      ?ZX_GET_CONTENT(ses->a7n->AuthnStatement->AuthnContext->AuthnContextClassRef):0;

    if (accr)
      for (p = cf->required_authnctx[0]; p; ++p)
	if (!memcmp(accr->s, p, accr->len) && !p[accr->len])
	  goto ok;
    
    /* *** arrange same session to be used after step-up authentication. */
    
    D("Required AuthnCtx not satisfied by (%.*s). Step-up authentication needed.", accr&&accr->len?accr->len:1, accr&&accr->len?accr->s:"-");
    cgi->msg = "Step-up authentication requested.";
    return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);
  ok:
    D("Required AuthnCtx satisfied(%s)", p);
  }

  /* Already successful Single Sign-On case starts here */
  ses->rs = cgi->rs;
  return zxid_simple_ab_pep(cf, ses, res_len, auto_flags);
  
cgi_exit:
  if (auto_flags & ZXID_AUTO_EXIT)
    exit(0);
  res = zx_dup_cstr(cf->ctx, "n");
  if (res_len)
    *res_len = 1;
  return res;

res_zx_str:
  res = ss->s;
  if (res_len)
    *res_len = ss->len;
  ZX_FREE(cf->ctx, ss);
  return res;
}

/*() Subroutine of zxid_simple_cf() for the no session detected/active case.
 * cgi->uri_path should have been set by the caller.
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  chkuid, zxid_mini_httpd_sso, zxid_simple_cf_ses */
char* zxid_simple_no_ses_cf(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags)
{
  char* res = 0;
  struct zx_str* ss;
  
  if (!cf || !cgi || !ses) {
    ERR("FATAL: NULL pointer. You MUST supply configuration(%p), cgi(%p), and session(%p) objects (programming error)", cf, cgi, ses);
    exit(1);
  }
  if (cf->wd && *cf->wd)
    chdir(cf->wd);

  D("op(%c) cf=%p cgi=%p ses=%p auto=%x wd(%s)", cgi->op?cgi->op:'-', cf, cgi, ses, auto_flags, STRNULLCHKD(cf->wd));
  if (!cgi->op && cf->defaultqs && cf->defaultqs[0]) {
    zxid_parse_cgi(cf, cgi, cf->defaultqs);
    INFO("DEFAULTQS(%s) op(%c)", cf->defaultqs, cgi->op?cgi->op:'-');
  }
  
  switch (cgi->op) {
  case 'M':  /* Invoke LECP or redirect to CDC reader. */
    ss = zxid_lecp_check(cf, cgi);
    D("LECP check: ss(%.*s)", ss?ss->len:1, ss?ss->s:"?");
    if (ss) {
      if (auto_flags & ZXID_AUTO_REDIR) {
	fprintf(stdout, "%.*s", ss->len, ss->s);
	fflush(stdout);
	zx_str_free(cf->ctx, ss);
	goto cgi_exit;
      } else
	goto res_zx_str;
    } else {
      if (auto_flags & ZXID_AUTO_REDIR) {
	fprintf(stdout, "Location: %s?o=C" CRLF2, cf->cdc_url);
	fflush(stdout);
	goto cgi_exit;
      } else {
	ss = zx_strf(cf->ctx, "Location: %s?o=C" CRLF2, cf->cdc_url);
	goto res_zx_str;
      }
    }
  case 'C':  /* CDC Read: Common Domain Cookie Reader */
    ss = zxid_cdc_read(cf, cgi);
    if (auto_flags & ZXID_AUTO_REDIR) {
      fprintf(stdout, "%.*s", ss->len, ss->s);
      fflush(stdout);
      zx_str_free(cf->ctx, ss);
      goto cgi_exit;
    } else
      goto res_zx_str;
  case 'E':  /* Return from CDC read, or start here to by-pass CDC read. */
    ss = zxid_lecp_check(cf, cgi);  /* use o=E&fc=1&fn=p  to set allow create true */
    D("LECP check: ss(%.*s)", ss?ss->len:1, ss?ss->s:"?");
    if (ss) {
      if (auto_flags & ZXID_AUTO_REDIR) {
	fprintf(stdout, "%.*s", ss->len, ss->s);
	fflush(stdout);
	zx_str_free(cf->ctx, ss);
	goto cgi_exit;
      } else
	goto res_zx_str;
    }
    if (zxid_cdc_check(cf, cgi))
      return 0;
    D("NOT CDC %d", 0);
    break;
  case 'L':
    if (ss = zxid_start_sso_location(cf, cgi)) {
      if (auto_flags & ZXID_AUTO_REDIR) {
	printf("%.*s", ss->len, ss->s);
	goto cgi_exit;
      } else {
	goto res_zx_str;
      }
    }
    break;
  case 'A':
    D("Process artifact(%s) pid=%d", cgi->saml_art, getpid());
    switch (zxid_sp_deref_art(cf, cgi, ses)) {
    case ZXID_REDIR_OK: ERR("*** Odd, redirect on artifact deref. %d", 0); break;
    case ZXID_SSO_OK:
      return zxid_show_protected_content_setcookie(cf, cgi, ses, res_len, auto_flags);
    }
    break;
  case 'O':
    D("Process OAUTH2 / OpenID-Connect1 pid=%d", getpid());
    ss = zxid_sp_oauth2_dispatch(cf, cgi, ses);
    goto post_dispatch;
  case 'T':
    D("Process OAUTH2 / OpenID-Connect1 check id pid=%d", getpid());
    return zxid_idp_oauth2_token_and_check_id(cf, cgi, ses, res_len, auto_flags);
  case 'P':    /* POST Profile Responses */
  case 'I':
  case 'K':
  case 'Q':    /* POST Profile Requests */
    DD("PRE saml_req(%s) saml_resp(%s) rs(%s) sigalg(%s) sig(%s)", STRNULLCHK(cgi->saml_req),  STRNULLCHK(cgi->saml_resp), cgi->rs, cgi->sigalg, cgi->sig);
    ss = zxid_sp_dispatch(cf, cgi, ses);
  post_dispatch:
    D("POST dispatch_loc(%s)", ss->s);
    switch (ss->s[0]) {
    case 'O': return zxid_show_protected_content_setcookie(cf, cgi, ses, res_len, auto_flags);
    case 'M': return zxid_simple_ab_pep(cf, ses, res_len, auto_flags); /* Mgmt screen case */
    case 'L':  /* Location */
      if (auto_flags & ZXID_AUTO_REDIR) {
	fprintf(stdout, "%.*s", ss->len, ss->s);
	fflush(stdout);
	zx_str_free(cf->ctx, ss);
	goto cgi_exit;
      } else
	goto res_zx_str;
    case 'I': goto idp;
    }
    D("Q err (fall thru) %d", 0);
    break;
  case 'H': return zxid_simple_show_rsrcreg(cf, cgi, res_len, auto_flags);
  case 'J': return zxid_simple_show_dynclireg(cf, cgi, res_len, auto_flags);
  case 'j': return zxid_simple_show_jwks(cf, cgi, res_len, auto_flags);
  case 'c': return zxid_simple_show_carml(cf, cgi, res_len, auto_flags);
  case 'd': return zxid_simple_show_conf(cf, cgi, res_len, auto_flags);
  case 'B': return zxid_simple_show_meta(cf, cgi, res_len, auto_flags);
  case 'b': return zxid_simple_md_authority(cf, cgi, res_len, auto_flags);
  case 'D': /*  Delegation / Invitation URL clicked. */
    return zxid_ps_accept_invite(cf, cgi, ses, res_len, auto_flags);
  case 'R':
    cgi->op = 'F';
    /* Fall thru */
  case 'F':
idp:           return zxid_simple_idp_show_an(cf, cgi, res_len, auto_flags);
  case 'p':    return zxid_simple_idp_pw_authn(cf, cgi, res_len, auto_flags);
  case 'N':    return zxid_simple_idp_new_user(cf, cgi, res_len, auto_flags);
  case 'W':    return zxid_simple_idp_recover_password(cf, cgi, res_len, auto_flags);
  default:
    if (cf->bare_url_entityid)
      return zxid_simple_show_meta(cf, cgi, res_len, auto_flags);
    D("unknown op(%c)", cgi->op);
  }
  return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);

cgi_exit:
  if (auto_flags & ZXID_AUTO_EXIT)
    exit(0);
  res = zx_dup_cstr(cf->ctx, "n");
  if (res_len)
    *res_len = 1;
  return res;

res_zx_str:
  res = ss->s;
  if (res_len)
    *res_len = ss->len;
  ZX_FREE(cf->ctx, ss);
  return res;
}

/*(i) Simple handler that assumes the configuration has already been read in.
 * The memory for result is grabbed from ZX_ALLOC(), usually malloc(3)
 * and is "given" away to the caller, i.e. caller must free it. The
 * return value is LDIF (or JSON or query string, if configured)
 * of attributes in success case.
 * res_len, if non-null, will receive the length of the response.
 *
 * The major advantage of zxid_simple_cf_ses() is that the session stays
 * as binary object and does not need to be recreated / reparsed from
 * filesystem representation. The object can be directly used for PEP
 * calls (but see inline PEP call enabled by PDPURL) and WSC.
 *
 * cf:: Configuration object
 * qs_len:: Length of the query string. -1 = use strlen()
 * qs:: Query string (or POST content)
 * ses:: Session object
 * res_len:: Result parameter. If non-null, will be set to the length of the returned string
 * auto_flags:: Automation flags, see zxid-simple.pd for documentation
 * return:: String representing protocol action or SSO attributes
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_simple_cf */
char* zxid_simple_cf_ses(zxid_conf* cf, int qs_len, char* qs, zxid_ses* ses, int* res_len, int auto_flags)
{
  int got, ret;
  char* remote_addr;
  char* cont_len;
  char* buf = 0;
  char* res = 0;
  zxid_cgi cgi;
  ZERO(&cgi, sizeof(cgi));
  
  if (!cf || !ses) {
    ERR("NULL pointer. You MUST supply configuration object %p and session object %p (programming error). auto_flags=%x", cf, ses, auto_flags);
    exit(1);
  }
  
  /*fprintf(stderr, "qs(%s) arg, autoflags=%x\n", qs, auto_flags);*/
  if (auto_flags & ZXID_AUTO_DEBUG) zxid_set_opt(cf, 1, 3);
  LOCK(cf->mx, "simple ipport");
  if (!cf->ipport) {
    remote_addr = getenv("REMOTE_ADDR");
    if (remote_addr) {
      ses->ipport = ZX_ALLOC(cf->ctx, strlen(remote_addr) + 6 + 1); /* :12345 */
      sprintf(ses->ipport, "%s:-", remote_addr);
      cf->ipport = ses->ipport;
    }
  }
  UNLOCK(cf->mx, "simple ipport");

  cgi.uri_path = getenv("SCRIPT_NAME");
  cgi.qs = qs;  /* save orig for use in zxid_sso_set_relay_state_to_return_to_this_url() */
  
  if (!qs) {
    cgi.qs = qs = getenv("QUERY_STRING");
    if (qs) {
      qs = zx_dup_cstr(cf->ctx, qs);
      D("QUERY_STRING(%s) %s %d", STRNULLCHK(qs), ZXID_REL, errmac_debug);
      zxid_parse_cgi(cf, &cgi, qs);
      if (ONE_OF_8(cgi.op, 'H', 'J', 'P', 'R', 'S', 'T', 'Y', 'Z')) {
	cont_len = getenv("CONTENT_LENGTH");
	if (cont_len) {
	  sscanf(cont_len, "%d", &got);
	  D("o=%c cont_len=%s got=%d rel=%s", cgi.op, cont_len, got, ZXID_REL);
	  cgi.post = buf = ZX_ALLOC(cf->ctx, got + 1 /* nul term */);
	  if (!buf) {
	    ERR("out of memory len=%d", got);
	    exit(1);
	  }
	  if (read_all_fd(fdstdin, buf, got, &got) == -1) {
	    perror("Trouble reading post content.");
	  } else {
	    buf[got] = 0;
	    DD("POST(%s) got=%d cont_len(%s)", buf, got, cont_len);
	    D_XML_BLOB(cf, "POST", got, buf);
	    if (buf[0] == '<') goto sp_soap;  /* No BOM and looks like XML */
	    if (buf[0] == '{') goto json;     /* No BOM and looks like JSON */
	    if (buf[2] == '<') {              /* UTF-16 BOM and looks like XML */
	      got-=2; buf+=2;
	      ERR("UTF-16 NOT SUPPORTED %x%x", buf[0], buf[1]);
	      goto sp_soap;
	    }
	    if (buf[2] == '{') {              /* UTF-16 BOM and looks like JSON */
	      got-=2; buf+=2;
	      ERR("UTF-16 NOT SUPPORTED %x%x", buf[0], buf[1]);
	      goto json;
	    }
	    if (buf[3] == '<') {              /* UTF-8 BOM and looks XML */
	      got-=3; buf+=3;
	    sp_soap:
	      /* *** TODO: SOAP response should not be sent internally unless there is auto */
	      ret = zxid_sp_soap_parse(cf, &cgi, ses, got, buf);
	      D("POST soap parse returned %d (0=fail, 1=ok, 2=redir, 3=sso ok)", ret);
	      if (ret == ZXID_SSO_OK)
		return zxid_simple_ab_pep(cf, ses, res_len, auto_flags);
	      if (auto_flags & ZXID_AUTO_SOAPC || auto_flags & ZXID_AUTO_SOAPH) {
		if (auto_flags & ZXID_AUTO_EXIT)
		  exit(0);
		res = zx_dup_cstr(cf->ctx, "n");
		if (res_len)
		  *res_len = 1;
		goto done;
	      }
	      res = zx_dup_cstr(cf->ctx, ret ? "n" : "*** SOAP error (enable debug if you want to see why)"); 
	      if (res_len)
		*res_len = strlen(res);
	      goto done;
	    }
	    if (buf[3] == '{') {              /* UTF-8 BOM and looks JSON */
	      got-=3; buf+=3;
	    json:
	      D("JSON detected %s", buf);
	      /* Do not parse yet, this will be handled later in zxid_simple code. */
	    } else
	      zxid_parse_cgi(cf, &cgi, buf);
	  }
	} else {
	  D("o=%c post, but no CONTENT_LENGTH rel=%s", cgi.op, ZXID_REL);
	}
      } else {
	D("o=%c other rel=%s", cgi.op, ZXID_REL);
      }
    }
  } else {
    if (qs_len == -1)
      qs_len = strlen(qs);
    if (qs[qs_len]) {   /* *** may read one past end of buffer in non-nulterm case */
      ERR("IMPLEMENTATION LIMIT: Query String MUST be nul terminated len=%d", qs_len);
      exit(1);
    }
    D("QUERY_STRING(%s) %s", STRNULLCHK(qs), ZXID_REL);
    if (qs)
      qs = zx_dup_cstr(cf->ctx, qs);
    zxid_parse_cgi(cf, &cgi, qs);
  }
  
  if (!cgi.op && !cf->bare_url_entityid)
    cgi.op = 'M';  /* By default, if no ses, check CDC and offer SSO */
  
  if (!cgi.sid && cf->ses_cookie_name && *cf->ses_cookie_name)
    zxid_get_sid_from_cookie(cf, &cgi, getenv("HTTP_COOKIE"));

  if (cgi.sid) {
      if (!zxid_get_ses(cf, ses, cgi.sid)) {
	D("No session(%s) active op(%c)", cgi.sid, cgi.op);
      } else
	if (res = zxid_simple_ses_active_cf(cf, &cgi, ses, res_len, auto_flags))
	  goto done;
  }

  ZERO(ses, sizeof(zxid_ses));   /* No session yet! Process login form */
  res = zxid_simple_no_ses_cf(cf, &cgi, ses, res_len, auto_flags);

done:
  if (qs)
    ZX_FREE(cf->ctx, qs);
  if (buf)
    ZX_FREE(cf->ctx, buf);
  return res;
}

/*() Allocate simple session and then call simple handler. Strings
 * are length + pointer (no C string nul termination needed).
 * A wrapper for zxid_simple_cf().
 *
 * cf:: Configuration object
 * qs_len:: Length of the query string. -1 = use strlen()
 * qs:: Query string (or POST content)
 * res_len:: Result parameter. If non-null, will be set to the length of the returned string
 * auto_flags:: Automation flags, see zxid-simple.pd for documentation
 * return:: String representing protocol action or SSO attributes
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  main x3, zxid_simple_len, zxidwspcgi_main */
char* zxid_simple_cf(zxid_conf* cf, int qs_len, char* qs, int* res_len, int auto_flags)
{
  zxid_ses ses;
  ZERO(&ses, sizeof(ses));
  return zxid_simple_cf_ses(cf, qs_len, qs, &ses, res_len, auto_flags);
}

/*() Process simple configuration and then call simple handler. Strings
 * are length + pointer (no C string nul termination needed).
 * a wrapper for zxid_simple_cf().
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  zxid_simple */
char* zxid_simple_len(int conf_len, char* conf, int qs_len, char* qs, int* res_len, int auto_flags)
{
  struct zx_ctx ctx;
  zxid_conf cf;
  zx_reset_ctx(&ctx);
  ZERO(&cf, sizeof(cf));
  cf.ctx = &ctx;
  zxid_conf_to_cf_len(&cf, conf_len, conf);
  return zxid_simple_cf(&cf, qs_len, qs, res_len, auto_flags);
}

/*() Main simple interface. C string nul termination is assumed. Really just
 * a wrapper for zxid_simple_cf().
 *
 * N.B. More complete documentation is available in <<link: zxid-simple.pd>> (*** fixme) */

/* Called by:  main x4 */
char* zxid_simple(char* conf, char* qs, int auto_flags)
{
  return zxid_simple_len(-1, conf, -1, qs, 0, auto_flags);
}

/* EOF  --  zxidsimp.c */
