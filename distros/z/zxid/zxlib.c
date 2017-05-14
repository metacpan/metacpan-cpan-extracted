/* zxlib.c  -  Utility functions for generated (and other) code
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxlib.c,v 1.41 2009-11-24 23:53:40 sampo Exp $
 *
 * 28.5.2006, created --Sampo
 * 8.8.2006,  moved lookup functions to generated code --Sampo
 * 12.8.2006, added special scanning of xmlns to avoid backtracking elem recognition --Sampo
 * 26.8.2006, significant Common Subexpression Elimination (CSE) --Sampo
 * 30.9.2007, more CSE --Sampo
 * 7.10.2008, added documentation --Sampo
 * 26.5.2010, added XML parse error reporting --Sampo
 * 27.10.2010, re-engineered namespace handling --Sampo
 */

#include "platform.h"  /* needed on Win32 for snprintf(), va_copy() et al. */

//#include <pthread.h>
#include <memory.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

#include "errmac.h"
#include "zx.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/*(-) ZX implementation of memmem(3) for platforms that do not have this. */

/* Called by: */
char* zx_memmem(const char* haystack, int haystack_len, const char* needle, int needle_len)
{
  const char* lim = haystack + haystack_len - needle_len;
  for (; haystack < lim; ++haystack)
    if (!memcmp(haystack, needle, needle_len))
      return (char*)haystack; /* discards const qualifier, but is right if haystack was modifiable, as often is the case. */
  return 0;
}

#ifdef MINGW
/*(-) On windows the errno is not set. */
/* Called by: */
HANDLE zx_CreateFile(LPCTSTR lpFileName, 
		     DWORD dwDesiredAccess, DWORD dwShareMode, 
		     LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, 
		     DWORD dwFlagsAndAttributes, HANDLE hTemplateFile) 
{
  D("CreateFile(%s)", lpFileName);
  HANDLE res = CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes,
			  dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
  errno = GetLastError();
  return res;
}
#endif

#ifdef MINGW
#ifdef stat
#undef stat 
#endif
#endif

/*(-) ZX implmentation of stat for mingw which is dumb */
/* Called by: */
int zx_stat( const char *path, struct stat *buffer )
{
    int rv = 0;
    char *p = (char*)malloc( strlen( path ) + 1 );
    strcpy( p, path );

    if( p[ strlen(p) - 1 ] == '/' )
        p[ strlen(p) - 1 ] = '\0';

    rv = stat( p, buffer );
    free( p );
    return rv;
}

/*() ZX memory allocator that does not zero the buffer. Allocation is
 * potentially done relative to ZX context <<italic: c>>, though
 * actual (2008) implementation simply uses malloc(3). See also zx_reset_ctx().
 *
 * Rather than reference this function directly, you should
 * use the ZX_ALLOC() macro as much as possible.
 *
 * Some implementations may take c->mx mutex lock. However, they will
 * do so such that no deadlock will result even if already taken. */

/* Called by:  zx_zalloc */
void* zx_alloc(struct zx_ctx* c, int size) {
  char* p;
  p = (c&&c->malloc_func)?c->malloc_func(size):malloc(size);
  DD("malloc %p size=%d", p, size);
  if (!p) {
    ERR("Out-of-memory(%d)", size);
    if (size < 0)
      DIE_ACTION(1);
    exit(1);
  }
  return p;
}

/*() ZX memory allocator that zeroes the buffer. Allocation is
 * potentially done relative to ZX context <<italic: c>>, though
 * actual (2008) implementation simply uses malloc(3).
 *
 * Rather than reference this function directly, you should
 * use the ZX_ALLOC() macro as much as possible. */

/* Called by:  zxid_parse_conf_raw */
void* zx_zalloc(struct zx_ctx* c, int size) {
  char* p = zx_alloc(c, size);
  ZERO(p, size);
  return p;
}


/*() ZX memory free'er. Freeing is
 * potentially done relative to ZX context <<italic: c>>, though
 * actual (2008) implementation simply uses free(3).
 *
 * Rather than reference this function directly, you should
 * use the ZX_FREE() macro as much as possible. */

/* Called by: */
void* zx_free(struct zx_ctx* c, void* p) {
  if (!p)
    return 0;
  if (c && c->free_func)
    c->free_func(p);
  else
    free(p);
  return 0;
}

/*() Convert zx_str to C string. The ZX context will provide the memory. */

/* Called by: */
char* zx_str_to_c(struct zx_ctx* c, struct zx_str* ss) {
  char* p = ZX_ALLOC(c, ss->len+1);
  memcpy(p, ss->s, ss->len);
  p[ss->len] = 0;
  return p;
}

/*() zx_str_conv() helps SWIG typemaps to achieve natural conversion
 * to native length + data representations of scripting languages.
 * Should not need to use directly. */

/* Called by:  covimp_test */
void zx_str_conv(struct zx_str* ss, int* out_len, char** out_s)  /* SWIG typemap friendly */
{
  *out_s = 0;
  *out_len = 0;
  if (!ss)
    return;
  *out_s = ss->s;
  *out_len = ss->len;
}

/*() Free both the zx_str node and the underlying string data */

/* Called by:  main, zx_free_elem, zx_prefix_seen_whine, zxbus_send_cmdf, zxenc_privkey_dec, zxenc_pubkey_enc, zxenc_symkey_enc, zxid_addmd x3, zxid_anoint_a7n x5, zxid_anoint_sso_resp x4, zxid_az_soap x3, zxid_cache_epr, zxid_decode_redir_or_post, zxid_deflate_safe_b64, zxid_fed_mgmt_cf x3, zxid_idp_dispatch x2, zxid_idp_list_cf_cgi x3, zxid_idp_soap, zxid_idp_soap_dispatch x2, zxid_idp_sso x4, zxid_lecp_check, zxid_mgmt x3, zxid_mk_art_deref, zxid_mk_enc_a7n, zxid_mk_enc_id, zxid_mk_mni, zxid_mk_oauth_az_req x2, zxid_psobj_dec, zxid_psobj_enc, zxid_reg_svc x3, zxid_saml2_post_enc x2, zxid_saml2_redir, zxid_saml2_redir_enc x2, zxid_saml2_redir_url, zxid_saml2_resp_redir, zxid_send_sp_meta, zxid_simple_no_ses_cf x4, zxid_simple_ses_active_cf, zxid_simple_show_idp_sel, zxid_simple_show_page x3, zxid_slo_resp_redir, zxid_snarf_eprs_from_ses, zxid_soap_call_raw, zxid_soap_cgi_resp_body x2, zxid_sp_dispatch x2, zxid_sp_mni_soap, zxid_sp_slo_soap, zxid_sp_soap, zxid_sp_soap_dispatch x7, zxid_sp_sso_finalize, zxid_sso_issue_jwt x2, zxid_ssos_anreq, zxid_start_sso_location, zxid_user_sha1_name, zxid_write_ent_to_cache, zxid_wsf_validate_a7n, zxsig_sign */
void zx_str_free(struct zx_ctx* c, struct zx_str* ss) {
  if (ss->s)
    ZX_FREE(c, ss->s);
  ZX_FREE(c, ss);
}

/*() Construct zx_str from length and raw string data, which will be referenced, not copied. */

/* Called by: */
struct zx_str* zx_ref_len_str(struct zx_ctx* c, int len, const char* s) {
  struct zx_str* ss = ZX_ZALLOC(c, struct zx_str);
  ss->s = (char*)s;  /* ref points to underlying data */
  ss->len = len;
  return ss;
}

/*() Construct zx_str from C string, which will be referenced, not copied. */

/* Called by: */
struct zx_str* zx_ref_str(struct zx_ctx* c, const char* s) {
  if (!s)
    return 0;
  return zx_ref_len_str(c, strlen(s), s);
}

/*() Newly allocated string (node and data) of specified length, but uninitialized */

/* Called by: */
struct zx_str* zx_new_len_str(struct zx_ctx* c, int len) {
  struct zx_str* ss = ZX_ZALLOC(c, struct zx_str);
  ss->s = ZX_ALLOC(c, len+1);
  ss->s[len] = 0;
  ss->len = len;
  return ss;
}

/*() Construct zx_str by duplication of raw string data of given length. */

/* Called by: */
struct zx_str* zx_dup_len_str(struct zx_ctx* c, int len, const char* s) {
  struct zx_str* ss = zx_new_len_str(c, len);
  memcpy(ss->s, s, len);
  return ss;
}

/*() Construct zx_str by duplication of C string. */

/* Called by: */
struct zx_str* zx_dup_str(struct zx_ctx* c, const char* s) {
  return zx_dup_len_str(c, strlen(s), s);
}

/*() Create an allocated cstr (nul terminated) from len and ptr. */

/* Called by: */
char* zx_dup_len_cstr(struct zx_ctx* c, int len, const char* str) {
  char* s = ZX_ALLOC(c, len+1);
  memcpy(s, str, len);
  s[len] = 0; /* nul termination */
  return s;
}

/*() ZX version of strdup(). */

/* Called by: */
char* zx_dup_cstr(struct zx_ctx* c, const char* str) {
  int len = strlen(str);
  return zx_dup_len_cstr(c, len, str);
}

/* Called by:  zxid_call_trustpdp x3, zxid_wsp_validate_env x2 */
struct zx_str* zx_dup_zx_str(struct zx_ctx* c, struct zx_str* ss) {
  return zx_dup_len_str(c, ss->len, ss->s);
}

/* ------------------ ATTR ------------------ */

/*() Construct zx_attr_s from length and raw string data, which will be referenced, not copied. */

/* Called by: */
struct zx_attr_s* zx_ref_len_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s)
{
  struct zx_attr_s* ss = ZX_ZALLOC(c, struct zx_attr_s);
  ss->g.s = (char*)s;  /* ref points to underlying data */
  ss->g.len = len;
  ss->g.tok = tok;
  if (father) {
    ss->g.n = &father->attr->g;
    father->attr = ss;
  }
  return ss;
}

/*() Construct zx_attr_s from C string, which will be referenced, not copied. */

/* Called by: */
struct zx_attr_s* zx_ref_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s) {
  if (!s)
    return 0;
  return zx_ref_len_attr(c, father, tok, strlen(s), s);
}

/*() Newly allocated attribute (node and data) of specified length, but uninitialized */

/* Called by:  zx_dup_len_attr */
struct zx_attr_s* zx_new_len_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len)
{
  struct zx_attr_s* ss = ZX_ZALLOC(c, struct zx_attr_s);
  ss->g.s = ZX_ALLOC(c, len+1);
  ss->g.s[len] = 0;
  ss->g.len = len;
  ss->g.tok = tok;
  if (father) {
    ss->g.n = &father->attr->g;
    father->attr = ss;
  }
  return ss;
}

/*() Construct zx_str by duplication of raw string data of given length. */

/* Called by: */
struct zx_attr_s* zx_dup_len_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s) {
  struct zx_attr_s* ss = zx_new_len_attr(c, father, tok, len);
  memcpy(ss->g.s, s, len);
  return ss;
}

/*() Construct zx_str by duplication of C string. */

/* Called by: */
struct zx_attr_s* zx_dup_attr(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s) {
  return zx_dup_len_attr(c, father, tok, strlen(s), s);
}

/*() vasprintf(3) implementation that will grab its memory from ZX memory allocator.
 * String will be nul terminated. Optional retlen result paremeter allows the
 * length to be returned. Specify 0 if this is not needed. */

/* Called by:  zx_alloc_sprintf, zx_attrf, zx_strf, zxid_callf, zxid_callf_epr, zxid_wsc_prepare_callf, zxid_wsp_decoratef */
char* zx_alloc_vasprintf(struct zx_ctx* c, int* retlen, const char* f, va_list ap) /* data is new memory */
{
  va_list ap2;
  int len;
  char* s;
  char buf[2]; 
  va_copy(ap2, ap);
  /* Windows _vsnprintf() is quite different (and broken IMHO) wrt return value of vsnprintf()
   * http://msdn.microsoft.com/en-us/library/2ts7cx93.aspx
   * However, while undocumented, passing NULL buffer and zero size (instead of
   * the traditional buffer of size 1) seems to produce desired result - at least
   * on recent Windows releases (2013, Win7?). */
#if MINGW
  len = vsnprintf(0, 0, f, ap2);
#else
  len = vsnprintf(buf, 1, f, ap2);
#endif
  va_end(ap2);
  if (len < 0) {
    platform_broken_snprintf(len, __FUNCTION__, 1, f);
    if (retlen)
      *retlen = 0;
    s = ZX_ALLOC(c, 1);
    s[0] = 0;
    return s;
  }
  s = ZX_ALLOC(c, len+1);
  vsnprintf(s, len+1, f, ap);
  s[len] = 0; /* must terminate manually as on win32 nul termination is not guaranteed */
  if (retlen)
    *retlen = len;
  return s;
}

/*() sprintf(3) implementation that will grab its memory from ZX memory allocator.
 * String will be nul terminated. Optional retlen result paremeter allows the
 * length to be returned. Specify 0 if this is not needed. */

/* Called by:  zxid_add_env_if_needed, zxid_pool2env x4, zxid_ps_accept_invite, zxid_ps_finalize_invite, zxid_pw_authn x2, zxid_query_ctlpt_pdp, zxid_saml2_post_enc x2, zxid_show_protected_content_setcookie x4, zxid_simple_idp_an_ok_do_rest, zxid_simple_idp_new_user, zxid_simple_idp_recover_password, zxid_simple_idp_show_an, zxid_simple_show_err, zxid_sso_issue_jwt */
char* zx_alloc_sprintf(struct zx_ctx* c, int* retlen, const char* f, ...)  /* data is new memory */
{
  char* ret;
  va_list ap;
  va_start(ap, f);
  ret = zx_alloc_vasprintf(c, retlen, f, ap);
  va_end(ap);
  return ret;
}

/*(i) Construct zx_str given sprintf(3) format and grabbing memory from ZX memory allocator. */

/* Called by: */
struct zx_str* zx_strf(struct zx_ctx* c, const char* f, ...)  /* data is new memory */
{
  va_list ap;
  int len;
  char* s;
  va_start(ap, f);
  s = zx_alloc_vasprintf(c, &len, f, ap);
  va_end(ap);
  return zx_ref_len_str(c, len, s);
}

/* Called by: */
struct zx_attr_s* zx_attrf(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* f, ...)  /* data is new memory */
{
  va_list ap;
  int len;
  char* s;
  va_start(ap, f);
  s = zx_alloc_vasprintf(c, &len, f, ap);
  va_end(ap);
  return zx_ref_len_attr(c, father, tok, len, s);
}

/*() Check if string ends in suffix */

/* Called by: */
int zx_str_ends_in(struct zx_str* ss, int len, const char* suffix)
{
  return !memcmp(ss->s + ss->len - len, suffix, len);
}

/*() Compare two zx_strs; return -1 if a<b; 0 if a==b; 1 if a>b. */

int zx_str_cmp(struct zx_str* a, struct zx_str* b)
{
  int r;
  if (!a || !a->s || !a->len)
    return 1;  /* missing parts: sort to end of list */
  if (!b || !b->s || !b->len)
    return -1;
  r = memcmp(a->s, b->s, MIN(a->len, b->len));
  if (r)
    return r;  /* decided by differing characters */
  if (a->len == b->len)
    return 0;  /* equal in characters and length */
  if (a->len < b->len)
    return -1;
  return 1;
}

/*() Add non-XML content to the kids list. These essentially appear as DATA items. */

/* Called by:  test_ibm_cert_problem_enc_dec, x509_test, zx_new_str_elem, zxid_attach_sol1_usage_directive, zxid_az_soap x5, zxid_check_fed, zxid_issuer, zxid_mk_addr, zxid_mk_sa_attribute_ss x2, zxid_mk_subj, zxid_mk_transient_nid, zxid_new_epr, zxid_org_desc x4, zxid_parse_mni, zxid_ps_addent_invite x2, zxid_wsc_prep, zxid_wsc_prep_secmech x3, zxid_wsf_decor x4, zxsig_sign */
void zx_add_content(struct zx_ctx* c, struct zx_elem_s* x, struct zx_str* cont)
{
  if (!cont || !x) {
    ERR("Call to zx_add_content(c,%p,%p) with null values", x, cont);
    return;
  }
  cont->tok = ZX_TOK_DATA;
  cont->n = &x->kids->g;
  x->kids = (struct zx_elem_s*)cont;
}

/*() Add kid to head of kids list. Usually you should add in schema order
 * and in the end call zx_reverse_elem_lists() to make the list right order. */

/* Called by:  zx_add_kid_after_sa_Issuer, zxid_add_fed_tok2epr, zxid_az_soap, zxid_di_query, zxid_idp_as_do, zxid_imreq, zxid_mk_a7n x3, zxid_mk_logout_resp, zxid_mk_mni_resp, zxid_mk_saml_resp, zxid_soap_call_hdr_body x2, zxid_soap_cgi_resp_body, zxid_sp_soap_dispatch, zxid_wsf_sign */
struct zx_elem_s* zx_add_kid(struct zx_elem_s* father, struct zx_elem_s* kid)
{
  if (!kid) {
    ERR("kid argument missing father=%p", father);
    return 0;
  }
  if (father) {
    kid->g.n = &father->kids->g;
    father->kids = kid;
  }
  return kid;
}

/*() Add kid before another elem. This assumes father is already in
 * forward order, i.e. zx_reverse_elem_lists() was already called. */

/* Called by:  zxid_add_fed_tok2epr, zxid_choose_sectok x2, zxid_ins_xacml_az_cd1_stmt x2, zxid_ins_xacml_az_stmt x2, zxid_sso_issue_a7n, zxid_wsc_prep_secmech */
struct zx_elem_s* zx_add_kid_before(struct zx_elem_s* father, int before, struct zx_elem_s* kid)
{
  if (!father->kids) {
    father->kids = kid;
    return kid;
  }
  if (father->kids->g.tok == before) {
    kid->g.n = &father->kids->g;
    father->kids = kid;
    return kid;
  }
  for (father = father->kids;
       father->g.n && father->g.n->tok != before;
       father = (struct zx_elem_s*)father->g.n) ;

  kid->g.n = father->g.n;
  father->g.n = &kid->g;
  return kid;
}

/*() Add Signature right after sa:Issuer. This assumes father is
 * already in forward order (i.e. zx_reverse_elem_lists() was already
 * called. */

/* Called by:  zxid_anoint_a7n, zxid_anoint_sso_resp, zxid_az_soap x2, zxid_idp_soap_dispatch x2, zxid_idp_sso, zxid_mk_art_deref, zxid_sp_mni_soap, zxid_sp_slo_soap, zxid_sp_soap_dispatch x6, zxid_ssos_anreq */
struct zx_elem_s* zx_add_kid_after_sa_Issuer(struct zx_elem_s* father, struct zx_elem_s* kid)
{
  if (father->kids->g.tok == zx_sa_Issuer_ELEM) {
    father = father->kids;
    kid->g.n = father->g.n;
    father->g.n = &kid->g;
    return kid;
  }
  ERR("No <sa:Issuer> found. Adding signature at list head. %d", father->kids->g.tok);
  return zx_add_kid(father, kid);
}

/*() Replace kid element. */

/* Called by:  zxid_soap_cgi_resp_body, zxid_wsp_decorate */
struct zx_elem_s* zx_replace_kid(struct zx_elem_s* father, struct zx_elem_s* kid)
{
  if (!father->kids) {
    father->kids = kid;
    return kid;
  }
  if (father->kids->g.tok == kid->g.tok) {
    kid->g.n = father->kids->g.n;
    father->kids = kid;
    return kid;
  }
  for (father = father->kids;
       father->g.n && father->g.n->tok != kid->g.tok;
       father = (struct zx_elem_s*)father->g.n) ;

  kid->g.n = father->g.n->n;
  father->g.n = &kid->g;
  return kid;
}

/*() Construct new simple element from zx_str by referencing, not copying, it. */

/* Called by: */
struct zx_elem_s* zx_new_str_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, struct zx_str* ss)
{
  struct zx_elem_s* el;
  el = ZX_ZALLOC(c, struct zx_elem_s);
  el->g.tok = tok;
  if (father) {
    el->g.n = &father->kids->g;
    father->kids = el;
  }
  zx_add_content(c, el, ss);
  return el;
}

/*() Helper function for the zx_NEW_*() macros */

/* Called by:  zxid_mk_xacml_simple_at */
struct zx_elem_s* zx_new_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok)
{
  const struct zx_el_desc* ed;
  struct zx_elem_s* el;
  ed = zx_el_desc_lookup(tok);
  if (ed) {
    el = ZX_ALLOC(c, ed->siz);
    ZERO(el, ed->siz);
  } else {
    INFO("Unknown element tok=%06x in tok=%06x", tok, father?father->g.tok:0);
    el = ZX_ZALLOC(c, struct zx_elem_s);
    tok = ZX_TOK_NOT_FOUND;
  }
  el->g.tok = tok;
  if (father) {
    el->g.n = &father->kids->g;
    father->kids = el;
  }
  return el;
}

/*() Construct new simple element by referencing, not copying, raw string data of given length. */

/* Called by: */
struct zx_elem_s* zx_ref_len_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s)
{
  return zx_new_str_elem(c, father, tok, zx_ref_len_str(c, len, s));
}

/*() Construct new simple element by referencing, not copying, C string. */

/* Called by: */
struct zx_elem_s* zx_ref_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s)
{
  return zx_ref_len_elem(c, father, tok, strlen(s), s);
}

/* Called by:  zx_dup_elem, zxid_mk_fault_zx_str x3 */
struct zx_elem_s* zx_dup_len_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, int len, const char* s)
{
  return zx_new_str_elem(c, father, tok, zx_dup_len_str(c, len, s));
}

/* Called by:  zxid_add_fed_tok2epr, zxid_mk_an_stmt, zxid_mk_fault x3, zxid_new_epr x3, zxid_set_epr_secmech x2 */
struct zx_elem_s* zx_dup_elem(struct zx_ctx* c, struct zx_elem_s* father, int tok, const char* s)
{
  return zx_dup_len_elem(c, father, tok, strlen(s), s);
}

/* ----------- F r e e ----------- */

/* Called by:  zx_free_elem */
void zx_free_attr(struct zx_ctx* c, struct zx_attr_s* aa, int free_strs)
{
  struct zx_attr_s* aan;
  for (; aa; aa = aan) {      /* attributes */
    aan = (struct zx_attr_s*)aa->g.n;
    if (free_strs && aa->name)
      ZX_FREE(c, aa->name);
    if (free_strs && aa->g.s)
      ZX_FREE(c, aa->g.s);
    ZX_FREE(c, aa);
  }
}

/*() Free element and its attributes, child elements, and content.
 * Depth first traversal of data structure to free it and its subelements. Simple
 * strings are handled as a special case according to the free_strs flag. This
 * is useful if the strings point to underlying data from the wire that was
 * allocated differently. */

/* Called by:  main, zx_free_elem, zxid_mk_mni, zxid_parse_meta, zxid_set_fault, zxid_set_tas3_status */
void zx_free_elem(struct zx_ctx* c, struct zx_elem_s* x, int free_strs)
{
  struct zx_elem_s* ae;
  struct zx_elem_s* aen;
  
  if (x->g.tok == ZX_TOK_NOT_FOUND && free_strs) {
    ae = x;
    if (ae->g.s)
      ZX_FREE(c, ae->g.s);
  }
  zx_free_attr(c, x->attr, free_strs);

  for (ae = x->kids; ae; ae = aen) {      /* elements */
    aen = (struct zx_elem_s*)ae->g.n;
    switch (ae->g.tok) {
    case ZX_TOK_DATA:
      if (free_strs)
	zx_str_free(c, &ae->g);
      else
	ZX_FREE(c, ae);
      break;
    default:
      zx_free_elem(c, ae, free_strs);
      //zx_FREE_elem(c, ae, free_strs);
    }
  }
  ZX_FREE(c, x);
}

#ifdef ZX_ENA_AUX

/* *** clone code has not been updated since great namespace reform */

/* Called by: */
void zx_dup_attr(struct zx_ctx* c, struct zx_str* attr)
{
  char* p;
  for (; attr; attr = (struct zx_str*)attr->g.n)
    if (attr->s) {
      p = ZX_ALLOC(c, attr->len);
      memcpy(p, attr->s, attr->len);
      attr->s = p;
    }
}

/* Called by: */
struct zx_str* zx_clone_attr(struct zx_ctx* c, struct zx_str* attr)
{
  struct zx_str* ret;
  struct zx_str* attrnn;
  struct zx_str* attrn;
  char* p;
  for (attrnn = 0; attr; attr = (struct zx_str*)attr->g.n) {
    ZX_DUPALLOC(c, struct zx_str, attrn, attr);
    if (!attrnn)
      ret = attrn;
    else
      attrnn->g.n = &attrn->g;
    attrnn = attrn;
    if (attrn->s) {
      p = ZX_ALLOC(c, attrn->len);
      memcpy(p, attrn->s, attrn->len);
      attrn->s = p;
    }
  }
  return ret;
}

/* Called by:  TXDEEP_CLONE_ELNAME */
struct zx_elem_s* zx_clone_elem_common(struct zx_ctx* c, struct zx_elem_s* x, int size, int dup_strs)
{
  struct zx_attr_s* aa;
  struct zx_elem_s* ae;
  struct zx_attr_s* aan;
  struct zx_elem_s* aen;
  struct zx_attr_s* aann;
  struct zx_elem_s* aenn;
  char* p;

  if (x->g.tok == ZX_TOK_NOT_FOUND) {
    ae = (struct zx_elem_s*)x;
    ZX_DUPALLOC(c, struct zx_elem_s, aen, ae);
    if (dup_strs) {
      aen->name = ZX_ALLOC(c, ae->name_len);
      memcpy(aen->name, ae->name, ae->name_len);
    }
    x = &aen->gg;
  } else {
    struct zx_elem_s* xx = (struct zx_elem_s*)ZX_ALLOC(c, size);
    memcpy(xx, x, size);
    x = xx;
  }
  
  /* *** deal with xmlns specifications in exc c14n way */
  
  for (aann = 0, aa = x->attr; aa; aa = (struct zx_attr_s*)aa->ss.g.n) {  /* unknown attributes */
    ZX_DUPALLOC(c, struct zx_attr_s, aan, aa);
    if (!aann)
      x->any_attr = aan;
    else
      aann->ss.g.n = &aan->ss.g;
    aann = aan;
    
    if (dup_strs && aan->name) {
      p = ZX_ALLOC(c, aan->name_len);
      memcpy(p, aan->name, aan->name_len);
      aan->name = p;
    }
    if (dup_strs && aan->ss.s) {
      p = ZX_ALLOC(c, aan->ss.len);
      memcpy(p, aan->ss.s, aan->ss.len);
      aan->ss.s = p;
    }
  }
  
  for (aenn = 0, ae = x->kids; ae; ae = (struct zx_elem_s*)ae->gg.g.n) {  /* unknown elements */
    switch (ae->g.tok) {
    case ZX_TOK_DATA:
      ZX_DUPALLOC(c, struct zx_str, aen, ae);
      if (aen->g.s) {
	p = ZX_ALLOC(c, aen->g.len);
	memcpy(p, aen->g.s, aen->g.len);
	aen->s = p;
      }
      break;
    default:
      aen = (struct zx_elem_s*)zx_DEEP_CLONE_elem(c, &ae->gg, dup_strs);
    }
    if (!aenn)
      x->kids = aen;
    else
      aenn->gg.g.n = &aen->gg.g;
    aenn = aen;
  }
  return x;
}

/* Called by:  TXDUP_STRS_ELNAME */
void zx_dup_strs_common(struct zx_ctx* c, struct zx_elem_s* x)
{
  struct zx_attr_s* aa;
  struct zx_elem_s* ae;
  char* p;
  
  if (x->g.tok == ZX_TOK_NOT_FOUND) {
    ae = (struct zx_elem_s*)x;
    p = ZX_ALLOC(c, ae->name_len);
    memcpy(p, ae->name, ae->name_len);
    ae->name = p;
  }
  
  /* *** deal with xmlns specifications in exc c14n way */

  for (aa = x->attr; aa; aa = (struct zx_attr_s*)aa->ss.g.n) {  /* unknown attributes */
    if (aa->name) {
      p = ZX_ALLOC(c, aa->name_len);
      memcpy(p, aa->name, aa->name_len);
      aa->name = p;
    }
    if (aa->ss.s) {
      p = ZX_ALLOC(c, aa->ss.len);
      memcpy(p, aa->ss.s, aa->ss.len);
      aa->ss.s = p;
    }
  }

  for (ae = x->kids; ae; ae = (struct zx_elem_s*)ae->gg.g.n)   /* unknown elements */
    switch (ae->g.tok) {
    case ZX_TOK_DATA:
      if (ae->g.s) {
	p = ZX_ALLOC(c, ae->g.len);
	memcpy(p, ae->g.s, ae->g.len);
	ss->s = p;
      }
      break;
    default:
      zx_DUP_STRS_elem(c, &ae->gg);
    }
}

int zx_walk_so_unknown_attributes(struct zx_ctx* c, struct zx_elem_s* x, void* ctx, int (*callback)(struct zx_node_s* node, void* ctx))
{
  struct zx_attr_s* aa;
  int ret;
  
  for (aa = x->attr; aa; aa = (struct zx_attr_s*)aa->ss.g.n) {  /* unknown attributes */
    ret = callback(&aa->ss.g, ctx);
    if (ret)
      return ret;
  }
  return 0;
}

int zx_walk_so_unknown_elems_and_content(struct zx_ctx* c, struct zx_elem_s* x, void* ctx, int (*callback)(struct zx_node_s* node, void* ctx))
{
  struct zx_elem_s* ae;
  int ret;
  
  for (ae = x->kids; ae; ae = (struct zx_elem_s*)ae->gg.g.n) {  /* unknown elements */
    switch (ae->g.tok) {
    case ZX_TOK_DATA:
      ret = callback(ae, ctx);
      break;
    default:
      ret = zx_WALK_SO_elem(c, ae, ctx, callback);
    }
    if (ret)
      return ret;
  }
  return 0;
}

/* Called by: */
struct zx_elem_s* zx_deep_clone_elems(struct zx_ctx* c, struct zx_elem_s* x, int dup_strs)
{
  struct zx_elem_s* se;
  struct zx_elem_s* sen;
  struct zx_elem_s* senn;
  
  for (senn = 0, se = x; se; se = (struct zx_elem_s*)se->g.n) {
    sen = zx_DEEP_CLONE_elem(c, se, dup_strs);
    if (!senn)
      x = sen;
    else
      senn->g.n = &sen->g;
    senn = sen;
  }
  return x;
}

int zx_walk_so_elems(struct zx_ctx* c, struct zx_elem_s* se, void* ctx, int (*callback)(struct zx_node_s* node, void* ctx))
{
  int ret;

  for (; se; se = (struct zx_elem_s*)se->g.n) {
    ret = zx_WALK_SO_elem(c, se, ctx, callback);
    if (ret)
      return ret;
  }
  return 0;
}

/* Called by: */
void zx_dup_strs_elems(struct zx_ctx* c, struct zx_elem_s* se)
{
  for (; se; se = (struct zx_elem_s*)se->g.n)
    zx_DUP_STRS_elem(c, se);
}

#endif  /* end ZX_ENA_AUX */

/* EOF -- zxlib.c */
