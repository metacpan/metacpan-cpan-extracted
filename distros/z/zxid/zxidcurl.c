/* zxidcurl.c  -  libcurl interface for making SOAP calls and getting metadata
 * Copyright (c) 2013-2015 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidcurl.c,v 1.9 2009-11-24 23:53:40 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 4.10.2007,  fixed missing Content-length header found by Damien Laniel --Sampo
 * 4.10.2008,  added documentation --Sampo
 * 1.2.2010,   removed arbitrary limit on SOAP response size --Sampo
 * 11.12.2011, refactored HTTP GET client --Sampo
 * 26.10.2013, improved error reporting on credential expired case --Sampo
 * 12.3.2014,  added partial mime multipart support --Sampo
 * 27.5.2014,  Added feature to stop parsing after end of first top level tag has been seen --Sampo
 * 8.6.2015,   Fixed bug relating to unset action header --Sampo
 *
 * See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
 *           http://curl.haxx.se/libcurl/
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */
#include <string.h>

#ifdef USE_CURL
#include <curl/curl.h>

#if LIBCURL_VERSION_NUM < 0x070c00
#define CURL_EASY_STRERR(ec) "error-not-avail-in-curl-before-0x070c00"
#else
#define CURL_EASY_STRERR(ec) curl_easy_strerror(ec)
#endif

#endif

#include "errmac.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* ============== CURL callbacks ============== */

/*() Call back used by Curl to move received response data to application buffer.
 * Internal. Do not use directly. */

/* Called by: */
size_t zxid_curl_write_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
  int len = size * nmemb;
#if 1
  struct zxid_curl_ctx* rc = (struct zxid_curl_ctx*)userp;
  int old_len, new_len, in_buf = rc->p - rc->buf;
  if (rc->p + len > rc->lim) {
    old_len = rc->lim-rc->buf;
    new_len = MIN(MAX(old_len + old_len, in_buf + len), ZXID_MAX_CURL_BUF);
    if (new_len == ZXID_MAX_CURL_BUF) {
      ERR("Too large HTTP response. Response length at least %d. Maximum allowed length (ZXID_MAX_CURL_BUF): %d", in_buf + len, ZXID_MAX_CURL_BUF);
      return -1;  /* Signal error */
    }
    D("Reallocating curl buffer from %d to %d in_buf=%d len=%d", old_len, new_len, in_buf, len);
    REALLOCN(rc->buf, new_len+1);
    rc->p = rc->buf + in_buf;
    rc->lim = rc->buf + new_len;
  }
  memcpy(rc->p, buffer, len);
  rc->p += len;
  if (errmac_debug & CURL_INOUT) {
    INFO("RECV(%.*s) %d chars", len, (char*)buffer, len);
    D_XML_BLOB(0, "RECV", len, (char*)buffer);
  }
#else
  int fd = (int)userp;
  write_all_fd(fd, buffer, len);
#endif
  return len;
}

/*() Call back used by Curl to move request data from application buffer to Curl
 * internal send buffer, from which it will be sent to server. Internal. Do not use directly. */

/* Called by: */
size_t zxid_curl_read_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
  int len = size*nmemb;
  struct zxid_curl_ctx* wc = (struct zxid_curl_ctx*)userp;
  if (len > (wc->lim - wc->p))
    len = wc->lim - wc->p;
  memcpy(buffer, wc->p, len);
  wc->p += len;
  if (errmac_debug & CURL_INOUT) {
    INFO("SEND(%.*s) %d chars", len, (char*)buffer, len);
    D_XML_BLOB(0, "SEND", len, (char*)buffer);
  }
  return len;
}

/* ============== HTTP(S) GET and POST Client ============== */

/*() HTTP client for GET or POST method.
 * This method is just a wrapper around underlying libcurl HTTP client.
 *
 * cf1:: ZXID configuration object
 * url_len2:: Length of the URL. If -1 is passed, strlen(url) is used
 * url3:: URL for POST
 * len4:: Length of the data. If -1 is passed, strlen(data) is used
 * data5:: HTTP body for the POST. If NULL is passed, the method will be GET
 * content_type6:: Content-Type header for POST data. NULL means application/x-www-form-encoded
 * headers7:: A way to pass in additional header(s), typically SOAPaction or Authorization
 * flags8:: Bitmask of flags to control behaviour: 0x01 == return will have both headers and body
 * return:: HTTP body of the response or HTTP headers and body
 *
 * N.B. To use proxy, set environment variable all_proxy=proxyhost:port, see libcurl documentation.
 */

/* Called by:  zxid_soap_call_raw */
struct zx_str* zxid_http_cli(zxid_conf* cf, int url_len, const char* url, int len, const char* data, const char* content_type, const char* headers, int flags)
{
#ifdef USE_CURL
  struct zx_str* ret;
  CURLcode res;
  struct zxid_curl_ctx rc;
  struct zxid_curl_ctx wc;
  struct curl_slist content_type_curl;
  struct curl_slist headers_curl;
  char* urli;
  rc.buf = rc.p = ZX_ALLOC(cf->ctx, ZXID_INIT_SOAP_BUF+1);
  rc.lim = rc.buf + ZXID_INIT_SOAP_BUF;

  /* The underlying HTTP client is libcurl. While libcurl is documented to
   * be "entirely thread safe", one limitation is that curl handle can not
   * be shared between threads. Since we keep the curl handle as a part
   * of the configuration object, which may be shared between threads,
   * we need to take a lock for duration of the curl operation. Thus any
   * given configuration object can have only one HTTP request active
   * at a time. If you need more parallelism, you need more configuration
   * objects.
   */

#if 0
  cf->curl = curl_easy_init();
  curl_easy_reset(cf->curl);
  LOCK_INIT(cf->curl_mx);
  LOCK(cf->curl_mx, "curl-cli");
#else
  LOCK(cf->curl_mx, "curl-cli");
  curl_easy_reset(cf->curl);
#endif

  curl_easy_setopt(cf->curl, CURLOPT_WRITEDATA, &rc);
  curl_easy_setopt(cf->curl, CURLOPT_WRITEFUNCTION, zxid_curl_write_data);
  curl_easy_setopt(cf->curl, CURLOPT_NOPROGRESS, 1);
  curl_easy_setopt(cf->curl, CURLOPT_SSL_VERIFYPEER, 0);  /* *** arrange verification */
  curl_easy_setopt(cf->curl, CURLOPT_SSL_VERIFYHOST, 0);  /* *** arrange verification */
  //curl_easy_setopt(cf->curl, CURLOPT_CERTINFO, 1);

  if (!(flags & 0x02)) {
    curl_easy_setopt(cf->curl, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(cf->curl, CURLOPT_MAXREDIRS, 110);
  }
  
  if (flags & 0x01)
    curl_easy_setopt(cf->curl, CURLOPT_HEADER, 1); /* response shall have Heacers CRLF CRLF Body */

  if (url_len == -1)
    url_len = strlen(url);
  urli = ZX_ALLOC(cf->ctx, url_len+1);
  memcpy(urli, url, url_len);
  urli[url_len] = 0;
  DD("urli(%s) len=%d", urli, len);
  curl_easy_setopt(cf->curl, CURLOPT_URL, urli);
  
  if (data) {
    if (len == -1)
      len = strlen(data);
    wc.buf = wc.p = (char*)data;
    wc.lim = (char*)data + len;
  
    curl_easy_setopt(cf->curl, CURLOPT_POST, 1);
    curl_easy_setopt(cf->curl, CURLOPT_POSTFIELDSIZE, len);
    curl_easy_setopt(cf->curl, CURLOPT_READDATA, &wc);
    curl_easy_setopt(cf->curl, CURLOPT_READFUNCTION, zxid_curl_read_data);
  
    ZERO(&content_type_curl, sizeof(content_type_curl));
    content_type_curl.data = (char*)content_type;
    if (headers) {
      ZERO(&headers_curl, sizeof(headers_curl));
      headers_curl.data = (char*)headers;
      headers_curl.next = &content_type_curl;    //curl_slist_append(3)
      curl_easy_setopt(cf->curl, CURLOPT_HTTPHEADER, &headers_curl);
    } else {
      curl_easy_setopt(cf->curl, CURLOPT_HTTPHEADER, &content_type_curl);
    }
  } else {
    if (headers) {
      ZERO(&headers_curl, sizeof(headers_curl));
      headers_curl.data = (char*)headers;
      curl_easy_setopt(cf->curl, CURLOPT_HTTPHEADER, &headers_curl);
    }
  }
  
  INFO("----------- call(%s) -----------", urli);
  DD("HTTP_CLI post(%.*s) len=%d\n", len, STRNULLCHK(data), len);
  D_XML_BLOB(cf, "HTTP_CLI POST", len, STRNULLCHK(data));
  res = curl_easy_perform(cf->curl);  /* <========= Actual call, blocks. */
  switch (res) {
  case 0: break;
  case CURLE_SSL_CONNECT_ERROR:
    ERR("Is the URL(%s) really an https url? Check that certificate of the server is valid and that certification authority is known to the client. CURLcode(%d) CURLerr(%s)", urli, res, CURL_EASY_STRERR(res));
    DD("buf(%.*s)", rc.lim-rc.buf, rc.buf);
#if 0
    struct curl_certinfo* ci;
    res = curl_easy_getinfo(cf->curl, CURLINFO_CERTINFO, &ci);  /* CURLINFO_SSL_VERIFYRESULT */
    if (!res && ci) {
      int i;
      struct curl_slist *slist;
      D("%d certs", ci->num_of_certs);
      for (i = 0; i < ci->num_of_certs; ++i)
	for (slist = ci->certinfo[i]; slist; slist = slist->next)
	  D("%d: %s", i, slist->data);
    }
#endif
    break;
  default:
    ERR("Failed post to url(%s) CURLcode(%d) CURLerr(%s)", urli, res, CURL_EASY_STRERR(res));
    DD("buf(%.*s)", rc.lim-rc.buf, rc.buf);
  }

  /*curl_easy_getinfo(cf->curl, CURLINFO_CONTENT_TYPE, char*);*/

  UNLOCK(cf->curl_mx, "curl-cli");
  ZX_FREE(cf->ctx, urli);
  rc.lim = rc.p;
  rc.p[0] = 0;

  DD("HTTP_CLI got(%s)", rc.buf);
  DD_XML_BLOB(cf, "HTTP_CLI GOT", rc.lim - rc.buf, rc.buf);
  
  ret = zx_ref_len_str(cf->ctx, rc.lim - rc.buf, rc.buf);
  return ret;
#else
  ERR("This copy of zxid was compiled to NOT use libcurl. SOAP calls (such as Artifact profile and WSC) are not supported. Add -DUSE_CURL (make ENA_CURL=1) and recompile. %d", 0);
  return 0;
#endif
}

/* ============== CoT and Metadata of Others ============== */

/*() Send HTTP request for metadata using Well Known Location (WKL) method
 * and wait for response. Send the message to the server using Curl. Return
 * the metadata as parsed XML for the entity.
 * This call will block while the HTTP request-response is happening.
 *
 * cf::      ZXID configuration object, also used for memory allocation
 * url::     Where the request will be sent, i.e. the WKL
 * return::  XML data structure representing the entity, or 0 upon failure
 *
 * The underlying HTTP client is libcurl. While libcurl is documented to
 * be "entirely thread safe", one limitation is that chrl handle can not
 * be shared between threads. Since we keep the curl handle a part
 * of the configuration object, which may be shared between threads,
 * we need to take a lock for duration of the curl operation. Thus any
 * given configuration object can have only one HTTP request active
 * at a time. If you need more parallelism, you need more configuration
 * objects.
 */

/* Called by:  opt x3, zxid_addmd, zxid_get_meta_ss */
zxid_entity* zxid_get_meta(zxid_conf* cf, const char* url)
{
  char* buf;
  char* md;
  char* lim;
  zxid_entity* ent;
  struct zx_str* res;

  if (cf->log_level>1)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "GETMD", url, 0);
  res = zxid_http_cli(cf, -1, url, 0, 0, 0, 0, 0);
  if (!res) {
    ERR("Failed to get metadata response url(%s)", url);
    return 0;
  }
  buf = md = res->s;
  lim = res->s + res->len;
  ent = zxid_parse_meta(cf, &md, lim);
  if (!ent) {
    ERR("Failed to parse metadata response url(%s) buf(%.*s)",	url, ((int)(lim-buf)), buf);
    ZX_FREE(cf->ctx, buf);
    return 0;
  }
  if (cf->log_level>0)
    zxlog(cf, 0, 0, 0, 0, 0, 0, 0, "N", "W", "GOTMD", url, 0);
  return ent;
}

/*() Wrapper for zxid_get_meta() so you can provide the URL as ~zx_str~. */
/* Called by:  zxid_get_ent_ss */
zxid_entity* zxid_get_meta_ss(zxid_conf* cf, struct zx_str* url)
{
  return zxid_get_meta(cf, zx_str_to_c(cf->ctx, url));
}

/*() Locate first SOAP Envelope using simple heuristic
 * searching for string "Envelope" (and related namespace).
 * Typically this allows extraction of SOAP envelope from deep
 * inside MIME multipart message (MTOM+xop aka SOAP with attachments) */

const char* zxid_locate_soap_Envelope(const char* haystack)
{
  const char* q;
  const char* p = strstr(haystack, zx_xmlns_e);
  if (p) {
    for (q = p-1; q >= haystack; --q)
      if (*q == '<') break;
    if (q < haystack)
      return 0;
    p = zx_memmem(q, p-q, "Envelope", sizeof("Envelope")-1);
    if (p)
      return q;
  } else {
    D("Trying to detect namespaceless Envelope %d",0);
    p = strstr(haystack, "Envelope");
    if (p && p > haystack) {
      --p;
      switch (*p) {
      case '<': return p;
      case ':': /* Scan over namespace prefix */
	for (--p; p > haystack; --p)
	  if (!AZaz_09_dash(*p)) break;
	if (*p == '<')
	  return p;
	/* else fall through to error */
      default:
	return 0;
      }
    }
  }
  return 0;
}

/*() Return Content-Type header from last HTTP response.
 * This could be used to detect MIME multipart boundary, for example. */

const char* zxid_get_last_content_type(zxid_conf* cf)
{
  char* ct;
  curl_easy_getinfo(cf->curl, CURLINFO_CONTENT_TYPE, &ct);
  return ct;
}

/* ============== SOAP Call ============= */

/*(i) Send SOAP request and wait for response. Send the message to the
 * server using Curl. Return the parsed XML response data structure.
 * This call will block while the HTTP request-response is happening.
 *
 * cf:: ZXID configuration object, also used for memory allocation
 * url:: Where the request will be sent
 * env:: SOAP enevlope to be serialized and sent
 * ret_enve:: result parameter allows upper layers to see the message as string
 * return:: XML data structure representing the response, or 0 upon failure
 *
 * The underlying HTTP client is libcurl. While libcurl is documented to
 * be "entirely thread safe", one limitation is that curl handle can not
 * be shared between threads. Since we keep the curl handle as a part
 * of the configuration object, which may be shared between threads,
 * we need to take a lock for duration of the curl operation. Thus any
 * given configuration object can have only one HTTP request active
 * at a time. If you need more parallelism, you need more configuration
 * objects.
 */

/* Called by:  zxid_soap_call_hdr_body, zxid_wsc_call */
struct zx_root_s* zxid_soap_call_raw(zxid_conf* cf, struct zx_str* url, struct zx_e_Envelope_s* env, char** ret_enve)
{
#ifdef USE_CURL
  struct zx_root_s* r;
  struct zx_str* ret;
  struct zx_str* ss;
  char soap_action_buf[1024];
  char* soap_act = 0;
  const char* env_start;

  ss = zx_easy_enc_elem_opt(cf, &env->gg);
  DD("ss(%.*s) len=%d", ss->len, ss->s, ss->len);

  if (cf->soap_action_hdr && strcmp(cf->soap_action_hdr,"#inhibit")) {
    if (!strcmp(cf->soap_action_hdr,"#same")) {
      if (env->Header && env->Header->Action && ZX_GET_CONTENT_S(env->Header->Action)) {
	snprintf(soap_action_buf,sizeof(soap_action_buf), "SOAPAction: \"%.*s\"", ZX_GET_CONTENT_LEN(env->Header->Action), ZX_GET_CONTENT_S(env->Header->Action));
	soap_action_buf[sizeof(soap_action_buf)-1] = 0;
	soap_act = soap_action_buf;
	D("SOAPaction(%s)", soap_action_buf);
      } else {
	ERR("e:Envelope/e:Headers/a:Action SOAP header is malformed %p %p", env->Header, soap_act);
      }
    } else {
      snprintf(soap_action_buf,sizeof(soap_action_buf), "SOAPAction: \"%s\"", cf->soap_action_hdr);
      soap_action_buf[sizeof(soap_action_buf)-1] = 0;
      soap_act = soap_action_buf;
      D("SOAPaction(%s)", soap_action_buf);
    }
  }
  D("SOAPaction(%s) %p hdr(%s) %p", STRNULLCHK(soap_act), soap_act, STRNULLCHK(cf->soap_action_hdr), cf->soap_action_hdr);

  ret = zxid_http_cli(cf, url->len, url->s, ss->len, ss->s, cf->wsc_soap_content_type, soap_act, 0);
  zx_str_free(cf->ctx, ss);
  if (ret_enve)
    *ret_enve = ret?ret->s:0;
  if (!ret)
    return 0;
  
  env_start = zxid_locate_soap_Envelope(ret->s);
  if (!env_start) {
    ERR("SOAP response does not have Envelope element url(%.*s)", url->len, url->s);
    D_XML_BLOB(cf, "NO ENVELOPE SOAP RESPONSE", ret->len, ret->s);
    ZX_FREE(cf->ctx, ret);
    return 0;
  }

  cf->ctx->top1 = 1;  /* Stop parsing after first toplevel <e:Envelope> */
  r = zx_dec_zx_root(cf->ctx, ret->len - (env_start - ret->s), env_start, "soap_call");
  if (!r || !r->Envelope || !r->Envelope->Body) {
    ERR("Failed to parse SOAP response url(%.*s)", url->len, url->s);
    D_XML_BLOB(cf, "BAD SOAP RESPONSE", ret->len, ret->s);
    ZX_FREE(cf->ctx, ret);
    return 0;
  }
  return r;
#else
  ERR("This copy of zxid was compiled to NOT use libcurl. SOAP calls (such as Artifact profile and WSC) are not supported. Add -DUSE_CURL (make ENA_CURL=1) and recompile. %d", 0);
  return 0;
#endif
}

/*() Encode XML data structure representing SOAP envelope (request)
 * and send the message to the server using Curl. Return the parsed
 * XML response data structure.  This call will block while the HTTP
 * request-response is happening. To be called from SSO world.
 * Wrapper for zxid_soap_call_raw().
 *
 * cf::     ZXID configuration object, also used for memory allocation
 * url::    The endpoint where the request will be sent
 * hdr::    XML data structure representing the SOAP headers. Possibly 0 if no headers are desired
 * body::   XML data structure representing the SOAP body
 * return:: XML data structure representing the response  */

/* Called by:  zxid_as_call_ses, zxid_az_soap, zxid_idp_soap, zxid_soap_call_body, zxid_sp_deref_art, zxid_sp_soap */
struct zx_root_s* zxid_soap_call_hdr_body(zxid_conf* cf, struct zx_str* url, struct zx_e_Header_s* hdr, struct zx_e_Body_s* body)
{
  struct zx_root_s* r;
  struct zx_e_Envelope_s* env = zx_NEW_e_Envelope(cf->ctx,0);
  env->Header = hdr;
  env->Body = body;
  zx_add_kid(&env->gg, &body->gg);
  if (hdr)
    zx_add_kid(&env->gg, &hdr->gg);
  r = zxid_soap_call_raw(cf, url, env, 0);
  return r;
}

/*() Encode XML data structure representing SOAP envelope (request)
 * and send the message to the server using Curl. Return the parsed
 * XML response data structure.  This call will block while the HTTP
 * request-response is happening. To be called from SSO world.
 * Wrapper for zxid_soap_call_raw().
 *
 * cf::     ZXID configuration object, also used for memory allocation
 * url::    The endpoint where the request will be sent
 * body::   XML data structure representing the SOAP body
 * return:: XML data structure representing the response  */

/* Called by: */
struct zx_root_s* zxid_soap_call_body(zxid_conf* cf, struct zx_str* url, struct zx_e_Body_s* body)
{
  /*return zxid_soap_call_hdr_body(cf, url, zx_NEW_e_Header(cf->ctx,0), body);*/
  return zxid_soap_call_hdr_body(cf, url, 0, body);
}

/*() Emit to stdout XML data structure representing SOAP envelope (request).
 * Typically used in CGI environment, e.g. by the IdP and Discovery.
 * Optionally logs the issued message to local audit trail.
 *
 * cf::     ZXID configuration object, also used for memory allocation
 * body::   XML data structure representing the request
 * return:: 0 if fail, ZXID_REDIR_OK if success. */

/* Called by:  zxid_idp_soap_dispatch x2, zxid_sp_soap_dispatch x8 */
int zxid_soap_cgi_resp_body(zxid_conf* cf, zxid_ses* ses, struct zx_e_Body_s* body)
{
  struct zx_e_Envelope_s* env = zx_NEW_e_Envelope(cf->ctx,0);
  struct zx_str* ss;
  struct zx_str* logpath;
  env->Body = body;
  zx_add_kid(&env->gg, &body->gg);
  env->Header = zx_NEW_e_Header(cf->ctx, &env->gg);

  if (ses && ses->curflt) {
    D("Detected curflt, abandoning previous Body content. %d", 0);
    /* *** LEAK: Should free previous body content */
    env->Body = (struct zx_e_Body_s*)zx_replace_kid(&env->gg, (struct zx_elem_s*)zx_NEW_e_Body(cf->ctx, 0));
    ZX_ADD_KID(env->Body, Fault, ses->curflt);
  }
  
  zxid_wsf_decor(cf, ses, env, 1, 0);
  ss = zx_easy_enc_elem_opt(cf, &env->gg);

  if (cf->log_issue_msg) {
    logpath = zxlog_path(cf, ses->issuer, ss, ZXLOG_ISSUE_DIR, ZXLOG_WIR_KIND, 1);
    if (logpath) {
      if (zxlog_dup_check(cf, logpath, "cgi_resp")) {
	ERR("Duplicate wire msg(%.*s) (Simple Sign)", ss->len, ss->s);
#if 0
	if (cf->dup_msg_fatal) {
	  ERR("FATAL (by configuration): Duplicate wire msg(%.*s) (cgi_resp)", ss->len, ss->s);
	  zxlog_blob(cf, 1, logpath, ss, "cgi_resp dup");
	  zx_str_free(cf->ctx, logpath);
	  return 0;
	}
#endif
      }
      zxlog_blob(cf, 1, logpath, ss, "cgi_resp");
      zxlogwsp(cf, ses, "K", "CGIRESP", 0, "logpath(%.*s)", logpath->len, logpath->s);
      zx_str_free(cf->ctx, logpath);
    }
  }
  
  if (errmac_debug & ERRMAC_INOUT) INFO("SOAP_RESP(%.*s)", ss->len, ss->s);
  fprintf(stdout, "CONTENT-TYPE: text/xml" CRLF "CONTENT-LENGTH: %d" CRLF2 "%.*s", ss->len, ss->len, ss->s);
  fflush(stdout);
  D("^^^^^^^^^^^^^^ Done (%d chars returned) ^^^^^^^^^^^^^", ss->len);
  return ZXID_REDIR_OK;
}

/* EOF  --  zxidcurl.c */
