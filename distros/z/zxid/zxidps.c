/* zxidps.c  -  People Service
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2010 Risaris Ltd, All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxiddi.c,v 1.2 2009-11-24 23:53:40 sampo Exp $
 *
 * 16.9.2010, created --Sampo
 *
 * See also zxcall for client
 * - liberty-idwsf-overview-v2.0.pdf sec 2.3 and 2.4 (pp.15-31) for use cases
 * - liberty-idwsf-people-service-v1.0.pdf, sec 4.4 Elements Supporting Invitation (pp.53-57)
 *
 *  zxcot -e http://idp.tas3.pt:8081/zxididp?o=S 'People Svc' \
 *    http://idp.tas3.pt:8081/zxididp?o=B urn:liberty:ps:2006-08 \
 *  | zxcot -b /var/zxid/idpdimd
 */

#include "platform.h"  /* for dirent.h */
#include "errmac.h"
#include "zxid.h"
#include "zxidpriv.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "saml2.h"
#include "wsf.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

/* Called by:  zxid_psobj_dec, zxid_psobj_enc */
static int zxid_psobj_key_setup(zxid_conf* cf, struct zx_str* eid, char* symkey)
{
  if (!cf->psobj_symkey[0])
    zx_get_symkey(cf, "psobj-enc.key", cf->psobj_symkey);
  zx_raw_digest2(cf->ctx, symkey, "SHA1", strlen(cf->psobj_symkey), cf->psobj_symkey, eid->len, eid->s);
  return 20;
}

/*() Encrypt and safe_base64 encode psobj identifier for an entity.
 *
 * ObjectID (psobj) has particlar privacy threat in that several WSCs may
 * see them and be able to correlate about the user that the object refers
 * to (see brief discussion in sec 2.1.4 "<ObjectID> Element", ll.278-281,
 * of [PeopleSvc].
 *
 * We adopt solution where psobj issued towards an entity (SP, WSC) is
 * the psobj encrypted (AES-128-CBC) with key consisting of concatenation
 * of secret (/var/zxid/pem/psobj-enc.key) known to ps server (i.e. the
 * zxididp) and the Entity ID of the entity. */

/* Called by:  zxid_mk_an_stmt, zxid_ps_addent_invite */
struct zx_str* zxid_psobj_enc(zxid_conf* cf, struct zx_str* eid, const char* prefix, struct zx_str* psobj)
{
  char* lim;
  char symkey[20];
  struct zx_str key;
  struct zx_str* ss;
  struct zx_str* rr;
  int prefix_len = strlen(prefix);
  zxid_psobj_key_setup(cf, eid, symkey);
  key.len = 16;
  key.s = symkey;
  ss = zx_raw_cipher(cf->ctx, "AES-128-CBC", 1, &key, psobj->len, psobj->s, 16, 0);
  if (!ss) {
    ERR("Symmetric encryption failed %d", 0);
    return 0;
  }
  rr = zx_new_len_str(cf->ctx, prefix_len+SIMPLE_BASE64_LEN(ss->len)+1);
  strcpy(rr->s, prefix);
  lim = base64_fancy_raw(ss->s, ss->len, rr->s+prefix_len, safe_basis_64, 1<<31, 0, "", '=');
  *lim = 0;
  rr->len = lim - rr->s;
  zx_str_free(cf->ctx, ss);
  return rr;
}

/*() Decrypt psobj identifier from an entity. */

/* Called by:  zxid_idp_slo_do, zxid_ps_addent_invite */
struct zx_str* zxid_psobj_dec(zxid_conf* cf, struct zx_str* eid, const char* prefix, struct zx_str* psobj)
{
  char* lim;
  char symkey[20];
  struct zx_str key;
  struct zx_str* ss;
  struct zx_str* rr;
  int prefix_len = strlen(prefix);
  if (!eid || !psobj || psobj->len < prefix_len) {
    ERR("Null eid or psobj, or too short psobj %p", psobj);
    return 0;
  }
  if (memcmp(prefix, psobj->s, prefix_len)) {
    ERR("psobj(%.*s) does not match prefix(%s)", psobj->len, psobj->s, prefix);
    return 0;
  }
  zxid_psobj_key_setup(cf, eid, symkey);
  key.len = 16;
  key.s = symkey;
  rr = zx_new_len_str(cf->ctx, SIMPLE_BASE64_PESSIMISTIC_DECODE_LEN(psobj->len));
  lim = unbase64_raw(psobj->s+prefix_len, psobj->s+psobj->len, rr->s, zx_std_index_64);
  rr->len = lim - rr->s;
  ss = zx_raw_cipher(cf->ctx, "AES-128-CBC", 0, &key, rr->len-16, rr->s+16, 16, rr->s);
  zx_str_free(cf->ctx, rr);
  return ss;
}

/*() Render the linked list of delegated permissions to a string */

/* Called by:  zxid_put_invite, zxid_put_psobj */
char* zxid_render_perms(zxid_conf* cf, struct zxid_perm* perms)
{
  int n, len = 0;
  struct zxid_perm* perm;
  char* ret;
  char* p;
  
  /* Length computation phase */
  
  for (perm = perms; perm; perm = perm->n)
    len += sizeof("perm: ")-1 + (perm->eid?perm->eid->len:0) + 1 + (perm->qs?perm->qs->len:0) + 1;
  
  ret = p = ZX_ALLOC(cf->ctx, len+1);
  
  /* Rendering phase */
  
  for (perm = perms; perm; perm = perm->n) {
    n = sprintf(p, "perm: %.*s$%.*s\n",
		perm->eid?perm->eid->len:0, perm->eid?perm->eid->s:"",
		perm->qs?perm->qs->len:0,   perm->qs?perm->qs->s:"");
    p += n;
  }
  
  ASSERTOPI(p-ret, ==, len);
  *p = 0; /* nul terminate */
  return ret;
}

/*() Render the linked list of invitation IDs to a string */

/* Called by:  zxid_put_psobj x2 */
char* zxid_render_str_list(zxid_conf* cf, struct zx_str* strs, const char* attr_name)
{
  int n, len = 0, atn_len = strlen(attr_name);
  struct zx_str* str;
  char* ret;
  char* p;
  
  /* Length computation phase */
  
  for (str = strs; str; str = str->n)
    len += atn_len + sizeof(": ")-1 + str->len + 1;
  
  ret = p = ZX_ALLOC(cf->ctx, len+1);
  
  /* Rendering phase */
  
  for (str = strs; str; str = str->n) {
    n = sprintf(p, "%s: %.*s\n", attr_name, str->len, str->s);
    p += n;
  }
  
  ASSERTOPI(p-ret, ==, len);
  *p = 0; /* nul terminate */
  return ret;
}

/*() Create new invitation in file system. */

/* Called by:  zxid_ps_addent_invite */
int zxid_put_invite(zxid_conf* cf, struct zxid_invite* inv)
{
  char buf[ZXID_MAX_USER];
  char invid_c[ZXID_MAX_USER];
  char* perms = zxid_render_perms(cf, inv->perms);
  memcpy(invid_c, inv->invid->s, MIN(inv->invid->len, sizeof(invid_c)-1));
  invid_c[sizeof(invid_c)-1] = 0;

  write_all_path_fmt("put_inv", ZXID_MAX_USER, buf,
		     "%s" ZXID_INV_DIR "%s", cf->cpath, invid_c,
		     "dn: invid=%.*s\ninvid: %.*s\nuid: %s\ndesc: %.*s\npsobj: %.*s\nps2spredir: %.*s\nmaxusage: %d\nusage: %d\nstarts: %s\nexpires: %s\n%s\n\n",
		     inv->invid->len, inv->invid->s,
		     inv->invid->len, inv->invid->s,
		     inv->uid,
		     inv->desc?inv->desc->len:0, inv->desc?inv->desc->s:"",
		     inv->psobj?inv->psobj->len:0, inv->psobj?inv->psobj->s:"",
		     inv->ps2spredir?inv->ps2spredir->len:0, inv->ps2spredir?inv->ps2spredir->s:"",
		     inv->maxusage,
		     inv->usage,
		     zxid_date_time(cf, inv->starts),
		     zxid_date_time(cf, inv->expires),
		     STRNULLCHK(perms));
  D("PUT INVITATION invid(%s)", invid_c);
  return 1;
}

/*() Create new People Service Object in file system. */

/* Called by:  zxid_ps_addent_invite */
int zxid_put_psobj(zxid_conf* cf, struct zxid_psobj* obj)
{
  char* buf = ZX_ALLOC(cf->ctx, ZXID_MAX_USER);
  char* children = 0;  /* *** groups and children not supported yet. */
  char* tags = zxid_render_str_list(cf, obj->invids, "tag");
  char* invids = zxid_render_str_list(cf, obj->invids, "invid");
  char* perms = zxid_render_perms(cf, obj->perms);
  obj->mod_secs = time(0);
  
  write_all_path_fmt("put_psobj", ZXID_MAX_USER, buf,
		     "%s" ZXID_UID_DIR "%s", cf->cpath, obj->uid,
		     "dn: psobj=%.*s,uid=%s\npsobj: %.*s\nowner: %s\nidpnid: %.*s\ndispname: %.*s\nnodetype: %d\ncreated: %s\nmodified: %s\n%s%s%s%s\n\n",
		     obj->psobj->len, obj->psobj->s, obj->uid,
		     obj->psobj->len, obj->psobj->s, obj->uid,
		     obj->idpnid?obj->idpnid->len:0, obj->idpnid?obj->idpnid->s:"",
		     obj->dispname?obj->dispname->len:0, obj->dispname?obj->dispname->s:"",  /* *** Should really support multiple */
		     obj->nodetype,
		     zxid_date_time(cf, obj->create_secs),
		     zxid_date_time(cf, obj->mod_secs),
		     STRNULLCHK(children),
		     STRNULLCHK(tags),
		     STRNULLCHK(invids),
		     STRNULLCHK(perms));
  ZX_FREE(cf->ctx, buf);
  D("PUT PSOBJ(%.*s)", obj->psobj->len, obj->psobj->s);
  return 1;
}

/*() Populate psobj from LDIF. Parse LDIF format and insert attributes to struct.
 * The input is temporarily modified and then restored. Do not pass const string. */

/* Called by: */
int zxid_parse_psobj(zxid_conf* cf, struct zxid_psobj* obj, char* p, const char* lk)
{
  char* name;
  char* val;
  char* q;
  struct zx_str* ss;
  struct zxid_perm* perm;

  for (; p; ++p) {
    name = p;
    p = strstr(p, ": ");
    if (!p)
      break;
    *p = 0;
    val = p+2;
    p = strchr(val, '\n');  /* *** parsing LDIF is fragile if values are multiline */
    if (p)
      *p = 0;

    D("%s: ATTR(%s)=VAL(%s)", lk, name, val);

    switch (name[0]) {
    case 'd':
      if (!strcmp(name, "dn"))
	goto next;
      if (!strcmp(name, "dispname")) {
	obj->dispname = zx_dup_str(cf->ctx, val);
	goto next;
      }
      break;
    case 'i':
      if (!strcmp(name, "idpnid")) {
	obj->idpnid = zx_dup_str(cf->ctx, val);
	goto next;
      }
      if (!strcmp(name, "invid")) {
	ss = zx_dup_str(cf->ctx, val);
	ss->n = obj->invids;
	obj->invids = ss;
	goto next;
      }
      break;
    case 'p':
      if (!strcmp(name, "psobj")) {
	obj->psobj = zx_dup_str(cf->ctx, val);
	goto next;
      }
      if (!strcmp(name, "psobjref")) {
	ERR("%s: *** Child objects not yet supported (%s: %s)", lk, name, val);
	/*obj->child = zx_dup_str(cf->ctx, val); *** */
	goto next;
      }
      if (!strcmp(name, "perm")) {
	perm = ZX_ZALLOC(cf->ctx, struct zxid_perm);
	q = strchr(val, '$');
	if (q) {
	  perm->eid = zx_dup_len_str(cf->ctx, q-val, val);
	  perm->qs  = zx_dup_str(cf->ctx, q);
	} else
	  perm->eid = zx_dup_str(cf->ctx, val);
	perm->n = obj->perms;
	obj->perms = perm;
	goto next;
      }
      break;
    case 't':
      if (!strcmp(name, "tag")) {
	ss = zx_dup_str(cf->ctx, val);
	ss->n = obj->tags;
	obj->tags = ss;
	goto next;
      }
      break;
    case 'u':
      if (!strcmp(name, "uid")) {
	obj->uid = zx_dup_cstr(cf->ctx, val);
	goto next;
      }
      break;
    }
    ERR("%s: Unknown name(%s) val(%s) in psobj LDIF file. Ignored.", lk, name, val);

  next:
    val[-2] = ':'; /* restore */
    if (p)
      *p = '\n';
    else
      break;
  }
  return 1;
}

/*() Populate invitation from LDIF. Parse LDIF format and insert attributes to struct.
 * The input is temporarily modified and then restored. Do not pass const string. */

/* Called by:  zxid_ps_accept_invite, zxid_ps_finalize_invite */
int zxid_parse_invite(zxid_conf* cf, struct zxid_invite* inv, char* p, const char* lk)
{
  char* name;
  char* val;
  char* q;
  struct zxid_perm* perm;

  for (; p; ++p) {
    name = p;
    p = strstr(p, ": ");
    if (!p)
      break;
    *p = 0;
    val = p+2;
    p = strchr(val, '\n');  /* *** parsing LDIF is fragile if values are multiline */
    if (p)
      *p = 0;

    D("%s: ATTR(%s)=VAL(%s)", lk, name, val);

    switch (name[0]) {
    case 'd':
      if (!strcmp(name, "dn"))
	goto next;
      if (!strcmp(name, "desc")) {
	inv->desc = zx_dup_str(cf->ctx, val);
	goto next;
      }
      break;
    case 'e':
      if (!strcmp(name, "expires")) {
	inv->expires = zx_date_time_to_secs(val);
	goto next;
      }
      break;
    case 'i':
      if (!strcmp(name, "invid")) {
	inv->invid = zx_dup_str(cf->ctx, val);
	goto next;
      }
      break;
    case 'm':
      if (!strcmp(name, "maxusage")) {
	sscanf(val, "%i", &inv->maxusage);
	goto next;
      }
      break;
    case 'p':
      if (!strcmp(name, "psobj")) {
	inv->psobj = zx_dup_str(cf->ctx, val);
	goto next;
      }
      if (!strcmp(name, "ps2spredir")) {
	inv->ps2spredir = zx_dup_str(cf->ctx, val);
	goto next;
      }
      if (!strcmp(name, "perm")) {
	perm = ZX_ZALLOC(cf->ctx, struct zxid_perm);
	q = strchr(val, '$');
	if (q) {
	  perm->eid = zx_dup_len_str(cf->ctx, q-val, val);
	  perm->qs  = zx_dup_str(cf->ctx, q);
	} else
	  perm->eid = zx_dup_str(cf->ctx, val);
	perm->n = inv->perms;
	inv->perms = perm;
	goto next;
      }
      break;
    case 's':
      if (!strcmp(name, "starts")) {
	inv->starts = zx_date_time_to_secs(val);
	goto next;
      }
      break;
    case 'u':
      if (!strcmp(name, "uid")) {
	inv->uid = zx_dup_cstr(cf->ctx, val);
	goto next;
      }
      if (!strcmp(name, "usage")) {
	sscanf(val, "%i", &inv->usage);
	goto next;
      }
      break;
    }
    ERR("%s: Unknown name(%s) val(%s) in invite LDIF file. Ignored.", lk, name, val);

  next:
    val[-2] = ':'; /* restore */
    if (p)
      *p = '\n';
    else
      break;
  }
  return 1;
}

/*() Accept an invitation. Process a URL of form https://idp.tas3.pt/zxididp?o=D&inv=i123431
 * Both logged in and not yet logged in cases are possible. */

/* Called by:  zxid_simple_no_ses_cf, zxid_simple_ses_active_cf */
char* zxid_ps_accept_invite(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags)
{
  int now = time(0);
  struct zxid_invite inv;
  char buf[ZXID_MAX_BUF];
  int got = read_all(sizeof(buf), buf, "accept_invite", 1, "%s" ZXID_INV_DIR "%s",cf->cpath,cgi->inv);
  if (!got) {
    ERR("Invitation not found(%s)", cgi->inv);
    cgi->err = "Invitation not found.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  zxid_parse_invite(cf, &inv, buf, "accept_invite");
  if (inv.maxusage <= inv.usage) {
    ERR("Invitation(%s) has already been used (max_usage=%d, usage=%d)", cgi->inv, inv.maxusage, inv.usage);
    cgi->err = "Invitation has already been used.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  if (inv.starts > now) {
    ERR("Invitation(%s) is not active yet (starts=%d, now=%d)", cgi->inv, inv.starts, now);
    cgi->err = "Invitation is not active yet.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  if (inv.expires <= now) {
    ERR("Invitation(%s) has expired (expire=%d, now=%d)", cgi->inv, inv.expires, now);
    cgi->err = "Invitation has expired.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  
  cgi->msg = "This screen aims to complete the invitation process you started by clicking on the invitation link. Once completed, you will be redirected to the web site where the delegated resource is available. To complete invitation, People Service needs to authenticate you with your Identity Provider (IdP). Please choose your Identity Provider from popup menu (or enter the IdP URL in the space provided) and click Login.";
  
  cgi->rs = zx_alloc_sprintf(cf->ctx, 0, "o=G&inv=%s", cgi->inv);
  return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);
}

/*() Finalize an invitation. This function is invoked after zxid_ps_accept_invite() (o=D)
 * when user is returning from IdP, by way of o=G placed in RelayState. */

/* Called by:  zxid_simple_ses_active_cf */
char* zxid_ps_finalize_invite(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags)
{
  int now = time(0);
  struct zxid_invite inv;
  char buf[ZXID_MAX_BUF];
  int got = read_all(sizeof(buf), buf, "finalize_invite", 1, "%s" ZXID_INV_DIR "%s",cf->cpath,cgi->inv);
  if (!got) {
    ERR("Invitation not found(%s)", cgi->inv);
    cgi->err = "Invitation not found.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  zxid_parse_invite(cf, &inv, buf, "accept_invite");
  if (inv.maxusage <= inv.usage) {
    ERR("Invitation(%s) has already been used (max_usage=%d, usage=%d)", cgi->inv, inv.maxusage, inv.usage);
    cgi->err = "Invitation has already been used.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  if (inv.starts > now) {
    ERR("Invitation(%s) is not active yet (starts=%d, now=%d)", cgi->inv, inv.starts, now);
    cgi->err = "Invitation is not active yet.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  if (inv.expires <= now) {
    ERR("Invitation(%s) has expired (expire=%d, now=%d)", cgi->inv, inv.expires, now);
    cgi->err = "Invitation has expired.";
    return zxid_simple_show_err(cf, cgi, res_len, auto_flags);
  }
  
  cgi->msg = "This screen aims to complete the invitation process you started by clicking on the invitation link. Once completed, you will be redirected to the web site where the delegated resource is available. To complete invitation, People Service needs to authenticate you with your Identity Provider (IdP). Please choose your Identity Provider from popup menu (or enter the IdP URL in the space provided) and click Login.";
  
  cgi->rs = zx_alloc_sprintf(cf->ctx, 0, "o=G&inv=%s", cgi->inv);
  return zxid_simple_show_idp_sel(cf, cgi, res_len, auto_flags);
}

/*() Add an entity to buddy store and obtain an invitation token.
 * In fact this call just adds the invitation as we can not know
 * who will respond to the invitation. The actual object will be
 * created in zxid_ps_accept_invite(). If object repesenting the
 * user already exists, that will be reused. Otherwise new
 * object will be created.
 * The permissions are expected to be passed in as special
 * tag "perm". */

/* Called by:  zxid_sp_soap_dispatch */
struct zx_ps_AddEntityResponse_s* zxid_ps_addent_invite(zxid_conf* cf, zxid_ses* ses, struct zx_ps_AddEntityRequest_s* req)
{
  struct zx_str* tag;
  struct zx_ps_AddEntityResponse_s* resp = zx_NEW_ps_AddEntityResponse(cf->ctx,0);
  struct zxid_invite* inv;
  struct zxid_psobj* obj;
  char uid[ZXID_MAX_USER];
  D_INDENT("ps_inv: ");

  if (!req || !req->Object) {
    ERR("Malformed request (%p): Object missing.", req);
    resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "Fail", 0, 0, 0);
    D_DEDENT("ps_inv: ");
    return resp;
  }

  if (!zxid_idp_map_nid2uid(cf, sizeof(uid), uid, ses->tgtnameid, &resp->Status)) {
    D_DEDENT("ps_inv: ");
    return resp;
  }
  
  inv = ZX_ZALLOC(cf->ctx, struct zxid_invite);
  inv->invid = zxid_mk_id(cf, "i", 48);  /* What is secure and sufficient space? */
  inv->uid = uid;
  inv->maxusage = 1;
  inv->starts = time(0);
  inv->expires = time(0) + 86400 * 30;  /* *** make configurable (about a month) */
  inv->ps2spredir = ZX_GET_CONTENT(req->PStoSPRedirectURL);
  inv->perms = ZX_ZALLOC(cf->ctx, struct zxid_perm);
  inv->perms->eid = ses->issuer;

  obj = ZX_ZALLOC(cf->ctx, struct zxid_psobj);
#if 0
  obj->psobj = req->Object->ObjectID ? zxid_psobj_dec(cf, ses->issuer, "ZO", req->Object->ObjectID) : zxid_mk_id(cf, "o", 48);  /* What is secure and sufficient space? */
#else
  if (req->Object->ObjectID) {
    ERR("AddEntityRequest contained ObjectID(%.*s), but AddEntity is about creating new objects and the object IDs are assigned by People Service, not client. Ignoring ObjectID.", ZX_GET_CONTENT_LEN(req->Object->ObjectID), ZX_GET_CONTENT_S(req->Object->ObjectID));
  }
  obj->psobj = zxid_mk_id(cf, "o", 48);  /* What is secure and sufficient space? */
#endif
  obj->uid = uid;
  obj->dispname = ZX_GET_CONTENT(req->Object->DisplayName);
  obj->tags = ZX_GET_CONTENT(req->Object->Tag);
  obj->invids = inv->invid;
  obj->create_secs = time(0);

  inv->psobj = obj->psobj;
  zxid_put_invite(cf, inv);
  zxid_put_psobj(cf, obj);

  /* The invitation URL will be processed by zxid_ps_accept_invite(), see above. */
  resp->SPtoPSRedirectURL
    = zx_new_str_elem(cf->ctx, &resp->gg, zx_ps_SPtoPSRedirectURL_ELEM,
		      zx_strf(cf->ctx, "%s?o=D&inv=%.*s", cf->burl, inv->invid->len, inv->invid->s));
  resp->Object = zx_NEW_ps_Object(cf->ctx, &resp->gg);
  resp->Object->ObjectID = zx_new_str_elem(cf->ctx, &resp->Object->gg, zx_ps_ObjectID_ELEM, zxid_psobj_enc(cf, ses->issuer, "ZO", obj->psobj));
  resp->Object->DisplayName = zx_NEW_ps_DisplayName(cf->ctx, &resp->Object->gg);
  zx_add_content(cf->ctx, &resp->Object->DisplayName->gg, obj->dispname);
  resp->Object->DisplayName->Locale = zx_ref_attr(cf->ctx, &resp->Object->DisplayName->gg, zx_Locale_ATTR, "xx");  /* unknown locale */
  for (tag = obj->tags; tag; tag = tag->n) {
    resp->Object->Tag = zx_NEW_ps_Tag(cf->ctx, &resp->Object->gg);
    zx_add_content(cf->ctx, &resp->Object->Tag->gg, tag);
  }
  resp->Object->NodeType = zx_ref_attr(cf->ctx, &resp->Object->gg, zx_NodeType_ATTR, obj->nodetype?PS_COL:PS_ENT);
  resp->Object->CreatedDateTime = zxid_date_time_attr(cf, &resp->Object->gg, zx_CreatedDateTime_ATTR, obj->create_secs);
  resp->Object->ModifiedDateTime = zxid_date_time_attr(cf, &resp->Object->gg, zx_TimeStamp_ATTR, obj->mod_secs);
  resp->TimeStamp = resp->Object->CreatedDateTime;
  resp->id = zx_ref_len_attr(cf->ctx, &resp->gg, zx_id_ATTR, inv->invid->len, inv->invid->s);  /* *** why is ID requred by schema at all? */
  resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "OK", 0, 0, 0);
  zxlogwsp(cf, ses, "K", "PSINV", 0, "inv=%.*s", inv->invid->len, inv->invid->s);
  D_DEDENT("ps_inv: ");
  return resp;
}

/*() Resolve an invitation token to identity */

/* Called by:  zxid_sp_soap_dispatch */
struct zx_ps_ResolveIdentifierResponse_s* zxid_ps_resolv_id(zxid_conf* cf, zxid_ses* ses, struct zx_ps_ResolveIdentifierRequest_s* req)
{
  struct zx_ps_ResolveIdentifierResponse_s* resp = zx_NEW_ps_ResolveIdentifierResponse(cf->ctx,0);
  struct zx_ps_ResolveInput_s* inp;
  //struct zx_ps_ResolveOutput_s* out;
  int n_resolv = 0;
  char uid[ZXID_MAX_USER];
  D_INDENT("ps_resolv: ");
  
  //resp->ID = zxid_mk_id(cf, "DIR", ZXID_ID_BITS);
  
  if (!zxid_idp_map_nid2uid(cf, sizeof(uid), uid, ses->tgtnameid, &resp->Status)) {
    D_DEDENT("ps_resolv: ");
    return resp;
  }

  for (inp = req->ResolveInput;
       inp && inp->gg.g.tok == zx_ps_ResolveInput_ELEM;
       inp = (struct zx_ps_ResolveInput_s*)inp->gg.g.n) {
    // ***
  }

  resp->Status = zxid_mk_lu_Status(cf, &resp->gg, "OK", 0, 0, 0);
  zxlogwsp(cf, ses, "K", "PSRESOLVOK", 0, "n=%d", n_resolv);
  D_DEDENT("ps_resolv: ");
  return resp;
}

/* EOF  --  zxidps.c */
