/* zxid.h  -  Definitions for zxid CGI
 * Copyright (c) 2012-2013 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxid.h,v 1.94 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 18.11.2006, log signing support --Sampo
 * 12.10.2007, new conf options --Sampo
 * 22.2.2008,  added path_supplied feature --Sampo
 * 4.10.2008,  added documentation --Sampo
 * 29.9.2009,  added PDP_URL --Sampo
 * 7.1.2010,   added WSC and WSP signing options --Sampo
 * 26.5.2010,  reworked typedefs --Sampo
 * 31.5.2010,  eliminated many include dependencies from the public API --Sampo
 * 13.11.2010, added ZXID_DECL for benefit of the Windows port --Sampo
 * 12.12.2010, separate zxidpriv.h and zxidutil.h from zxid.h --Sampo
 * 17.8.2012,  added audit bus configuration --Sampo
 * 16.2.2013,  added WD option --Sampo
 * 14.3.2013   added language/skin dependent templates --Sampo
 * 21.6.2013,  added wsp_pat --Sampo
 * 18.12.2015, applied patch from soconnor, perceptyx --Sampo
 */

#ifndef _zxid_h
#define _zxid_h

#include <memory.h>
#include <string.h>
#include <sys/time.h>  /* for struct timeval */
#ifdef USE_CURL
#include <curl/curl.h>
#endif
#ifdef USE_OPENSSL
#include <openssl/ssl.h>
#endif

/*(c) ZXID configuration and working directory path
 * Where metadata cache and session files are created. Note that the directory
 * is not hashed: you should use a file system that scales easily to oodles
 * of small files in one directory. Say `zxcot -dirs' (or `make dir') to create
 * the directory with proper layout. If you change it here, also edit Makefile. */
#ifndef ZXID_PATH
#ifdef MINGW
#define ZXID_PATH  "c:/var/zxid/"
#else
#define ZXID_PATH  "/var/zxid/"
#endif
#endif

#ifndef ZXID_CONF_FILE
#define ZXID_CONF_FILE "zxid.conf"
#endif

#ifndef ZXID_CONF_PATH
#define ZXID_CONF_PATH ZXID_PATH ZXID_CONF_FILE
#endif

#ifndef ZXID_PATH_OPT
#define ZXID_PATH_OPT "ZXPATH"
#endif

#ifndef ZXID_ENV_PREFIX
#define ZXID_ENV_PREFIX "ZXID_"
#endif

#include <zx/zx.h>

/* ZXID_DECL allows all API functions to be qualified with a declatation, such
 * as relating to the calling convention (e.g. c-decl). Such qualification
 * is very important in the Windows environment. In such environment ZXID_DECL
 * will be defined in Makefile to cause the desired effect. */

#ifndef ZXID_DECL
#define ZXID_DECL
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifdef ZXID_FULL_HEADERS
#include "c/zx-data.h"  /* Generated. If missing, run `make dep ENA_GEN=1' */
#else
/* Since we only need pointers to these generated structures, we do not
 * really need to include (or ship) c/zx-data.h. Just forward declare
 * them here. */
struct zx_root_s;
struct zx_e_Envelope_s;
struct zx_e_Header_s;
struct zx_e_Body_s;
struct zx_e_Fault_s;
struct zx_tas3_Status_s;
struct zx_a_EndpointReference_s;
struct zx_sa_EncryptedAssertion_s;
struct zx_sa_Assertion_s;
struct zx_sa_NameID_s;
struct zx_sa_EncryptedID_s;
struct zx_sa_Issuer_s;
struct zx_sa_Attribute_s;
struct zx_sec_Token_s;
struct zx_lu_Status_s;
struct zx_sp_Status_s;
struct zx_sp_NewEncryptedID_s;
struct zx_sa11_Assertion_s;
struct zx_sa11_Assertion_s;
struct zx_ff12_Assertion_s;
struct zx_ff12_Assertion_s;
struct zx_ds_Signature_s;
struct zx_ds_Reference_s;
struct zx_ds_KeyInfo_s;
struct zx_xenc_EncryptedData_s;
struct zx_xenc_EncryptedKey_s;
#endif

#define ZXID_CONF_MAGIC 0x900dc07f
#define ZXID_CGI_MAGIC  0x900d0c91
#define ZXID_SES_MAGIC  0x900d05e5

/*(s) Entity or Provider, as identified by an Entity ID or Provider ID. */

struct zxid_entity_s {
  struct zxid_entity_s* n;
  struct zxid_entity_s* n_cdc;  /* *** not thread safe */
  char* eid;            /* Entity ID. Always nul terminated. */
  char* dpy_name;       /* OrganizationDisplayName. Always nul terminated. */
  char* button_url;     /* OrganizationURL. Used for branding buttons in IdP sel screen, etc. */
  char  sha1_name[28];  /* 27 chars (+1 that is overwritten with nul) */
  struct zx_md_EntityDescriptor_s* ed;  /* Metadata */
  struct zxid_map* aamap;  /* Optional. Read from /var/zxid/idpuid/.all/sp_name_buf/.cf */
#ifdef USE_OPENSSL
  X509* tls_cert;
  X509* sign_cert;
  X509* enc_cert;
#endif
};

typedef struct zxid_entity_s     zxid_entity;
typedef struct zx_sa_NameID_s    zxid_nid;
typedef struct zx_sa_Assertion_s zxid_a7n;
typedef struct zx_sec_Token_s    zxid_tok;
typedef struct zx_a_EndpointReference_s zxid_epr; /* Nice name for EPR. May eventually evolve to struct */
typedef struct zx_tas3_Status_s zxid_tas3_status; /* Nice name for TAS3 status */
typedef struct zx_e_Fault_s zxid_fault;           /* Nice name for SOAP faults */
typedef struct zxid_conf    zxid_conf;
typedef struct zxid_cgi     zxid_cgi;
typedef struct zxid_ses     zxid_ses;

/*(s) The zxid_conf structure is passed, as cf argument, to nearly every
 * function in zxid API. It is effectively used as "global" storage
 * for ZXID, facilitating thread safe operation.  In particular, it
 * contains the ZX context that is used for thread safe memory
 * allocation.  However, ZXID itself does not perform any locking
 * around zxid_conf. If you write multithreaded program and your
 * design allows same configuration to be accessed from multiple
 * threads (sometimes you can design your program so that this simply
 * does not happen - each one has its own configuration),
 * then you must perform locking. Often this would
 * mean bracketing every call to zxid API function with lock-unlock.
 *
 * zxid_conf also contains "cache" of the entity's own certificates
 * and private keys. If your program handles multiple entities, you
 * should have one zxid_conf object for each entity.
 *
 * Most of the other fields of zxid_conf are simply configuration
 * options. See <<see: zxidconf.h>> for their documentation. */

struct zxid_conf {
  unsigned int magic;
  struct zx_ctx* ctx; /* ZX parsing context. Usually used for memory allocation. */
  zxid_entity* cot;   /* Linked list of metadata for CoT partners (in-memory CoT cache) */
  int cpath_supplied; /* FLAG: If config variable PATH is supplied, it may trigger reading config file from the supplied location. */
  int cpath_len;
  char* cpath;        /* Config PATH */
  char* burl;         /* Base URL */
  char* non_standard_entityid;
  char* redirect_hack_imposed_url;
  char* redirect_hack_zxid_url;
  char* redirect_hack_zxid_qs;
  char* cdc_url;
  char* md_authority;

  char  cdc_choice;
  char  md_fetch;            /* Auto-CoT */
  char  md_populate_cache;
  char  md_cache_first;
  char  md_cache_last;
  char  auto_cert;
  char  idp_ena;
  char  imps_ena;

  char  as_ena;
  char  pdp_ena;
  char  authn_req_sign;
  char  want_authn_req_signed;
  char  want_sso_a7n_signed;
  char  sso_soap_sign;
  char  sso_soap_resp_sign;
  char  sso_sign;            /* Which components should be signed in SSO Response and Assertion */

  char  wsc_sign;            /* Which parts of a web service request to sign */
  char  wsp_sign;            /* Which parts of a web service response to sig */
  char  nameid_enc;          /* Should NameID be encrypted in SLO and MNI requests. */
  char  post_a7n_enc;
  char  di_allow_create;
  char  di_nid_fmt;
  char  di_a7n_enc;
  char  show_conf;

  char  sig_fatal;
  char  nosig_fatal;
  char  msg_sig_ok;
  char  timeout_fatal;
  char  audience_fatal;
  char  dup_a7n_fatal;
  char  dup_msg_fatal;
  char  relto_fatal;

  char  wsp_nosig_fatal;
  char  notimestamp_fatal;
  char  canon_inopt;
  char  enc_tail_opt;
  char  enckey_opt;
  char  idpatopt;
  char  idp_list_meth;
  char  cpn_ena;
  
  char* affiliation;
  char* nice_name;           /* Human readable "nice" name. Used in AuthnReq->ProviderName */
  char* button_url;          /* OrganizationURL. Used for branding buttons. */
  char* pref_button_size;    /* Preferred branding button size (thers are ignored). */
  char* org_name;
  /*char* org_url;           renamed as button_url and given new semantics */
  char* locality;            /* Used for CSR locality (L) field. */
  char* state;               /* Used for CSR state (ST) field. */
  char* country;             /* Used for CSR country (C) field. */
  char* contact_org;
  char* contact_name;
  char* contact_email;
  char* contact_tel;
  char* fedusername_suffix;  /* Default is computed from url domain name part when url is set. */
  char* ses_arch_dir;        /* Place where dead sessions go. 0=rm */
  char* ses_cookie_name;
  char* ptm_cookie_name;
  char* ipport;              /* Source IP and port for logging, e.g: "1.2.3.4:5" */
    
  char* load_cot_cache;
  char* wspcgicmd;
  char* anon_ok;
  char* optional_login_pat;
  char** required_authnctx;  /* Array of acceptable authentication context class refs */
  struct zxid_cstr_list* issue_authnctx;  /* What authentication context IdP issues for for different authentication methods. */
  char* idp_pref_acs_binding;
  char* mandatory_attr;
  int   before_slop;
  int   after_slop;
  int   timeskew;
  int   a7nttl;
  char* pdp_url;             /* If non-NULL, the inline PEP is enabled and PDP at URL is called. */
  char* pdp_call_url;        /* PDP URL for zxid_az() API */
  char* xasp_vers;
  char* trustpdp_url;
  char* defaultqs;
  char* wsp_pat;
  char* uma_pat;
  char* sso_pat;
  char* mod_saml_attr_prefix;  /* Prefix for req variables in mod_auth_saml */
  char* wsc_to_hdr;
  char* wsc_replyto_hdr;
  char* wsc_action_hdr;
  char* soap_action_hdr;
  char* wsc_soap_content_type;

  struct zxid_need*  need;
  struct zxid_need*  want;
  struct zxid_atsrc* attrsrc;
  struct zxid_map*   aamap;  /* Read from /var/zxid/idpuid/.all/.bs/.cf */
  struct zxid_map*   inmap;
  struct zxid_map*   outmap;
  struct zxid_map*   pepmap;
  struct zxid_map*   pepmap_rqout;
  struct zxid_map*   pepmap_rqin;
  struct zxid_map*   pepmap_rsout;
  struct zxid_map*   pepmap_rsin;

  struct zxid_cstr_list* localpdp_role_permit;
  struct zxid_cstr_list* localpdp_role_deny;
  struct zxid_cstr_list* localpdp_idpnid_permit;
  struct zxid_cstr_list* localpdp_idpnid_deny;

  char* wsc_localpdp_obl_pledge;
  struct zxid_obl_list* wsp_localpdp_obl_req;
  char* wsp_localpdp_obl_emit;
  struct zxid_obl_list* wsc_localpdp_obl_accept;

  struct zxid_map*   unix_grp_az_map;
  
  int   bootstrap_level;     /* How many layers of bootstraps are generated. */
  int   max_soap_retry;      /* How many times a ID-WSF SOAP call can be retried (update EPR) */

  char* idp_sel_start;       /* HTML headers, start of page, side bars */
  char* idp_sel_new_idp;     /* Auto-CoT fields */
  char* idp_sel_our_eid;     /* Our EID advice */
  char* idp_sel_tech_user;   /* Technical options user might choose */
  char* idp_sel_tech_site;   /* Technical options site admin sets (hidden) */
  char* idp_sel_footer;      /* End of page stuff, after form */
  char* idp_sel_end;         /* End of page, after version string */
  char* idp_sel_page;        /* URL for IdP selection Page. */
  char* idp_sel_templ_file;  /* Path to template, e.g. idp-sel.html */
  char* idp_sel_templ;       /* Default template used in case template at path can not be found. */

  char* an_page;         /* URL for Authentication Page. */
  char* an_templ_file;   /* Path to template, e.g. an-main.html */
  char* an_templ;        /* Default template used in case template at path can not be found. */

  char* post_templ_file; /* Path to template, e.g. post.html */
  char* post_templ;      /* Default template used in case template at path can not be found. */

  char* err_page;        /* URL for Error Message Page. */
  char* err_templ_file;  /* Path to template, e.g. err.html */
  char* err_templ;       /* Default template used in case template at path can not be found. */

  char* new_user_page;   /* URL to redirect to for new user creation */
  char* recover_passwd;
  char* atsel_page;

  char* mgmt_start;    /* HTML headers, start of page, side bars */
  char* mgmt_logout;   /* Logout buttons */
  char* mgmt_defed;    /* Defederation buttons */
  char* mgmt_footer;   /* End of page stuff, after form */
  char* mgmt_end;      /* End of page, after version string */

  char* dbg;           /* Debug message that may be shown. */
  char* wd;            /* Forced working directory. */

  struct zxid_bus_url* bus_url;  /* Audit bus URLs to contact. */
  char*  bus_pw;             /* Audit bus password if not using ClientTLS */

  char  log_err;             /* Log enables and signing and encryption flags (if USE_OPENSSL) */
  char  log_act;
  char  log_issue_a7n;
  char  log_issue_msg;
  char  log_rely_a7n;
  char  log_rely_msg;
  char  log_err_in_act;      /* Log errors to action log flag (may also log to error log) */
  char  log_act_in_err;      /* Log actions to error log flag (may also log to action log) */

  char  log_sigfail_is_err;  /* Log signature failures to error log */
  char  log_level;           /* act log level: 0=audit, 1=audit+extio, 2=audit+extio+events */
  char  user_local;          /* Whether local user accounts should be maintained. */
  char  redir_to_content;    /* Should explicit redirect to content be used (vs. internal redir) */
  char  remote_user_ena;
  char  show_tech;
  char  bare_url_entityid;
  char  loguser;

  char  az_opt;        /* Kludgy options for AZ debugging and to work-around bugs of others */
  char  valid_opt;     /* Kludgy options for AZ debugging and to work-around bugs of others */
  char  idp_pxy_ena;
  char  oaz_jwt_sigenc_alg;  /* What signature and encryption to apply to issued JWT (OAUTH2) */
  char  bus_rcpt;            /* Audit Bus receipt enable and signing flags */
  char  az_fail_mode;        /* What to do when authorization can not be done */
  char  md_authority_ena;
  char  backwards_compat_ena; /* Enable CBC (instead of GCM) and PKCS#1 v1.5 padding, both of which are vulnearable and can compromise modern crypto through Backwards Compatibility Attacks. */

  char* xmldsig_sig_meth;
  char* xmldsig_digest_algo;
  char* samlsig_digest_algo;
  char* blobsig_digest_algo;

#ifdef USE_CURL
  CURL* curl;
#endif
#ifdef USE_PTHREAD
  struct zx_lock mx;
  struct zx_lock curl_mx;   /* Avoid holding the main lock for duration of HTTP request */
#endif
#ifdef USE_OPENSSL
  EVP_PKEY*  sign_pkey;
  X509* sign_cert;
  EVP_PKEY*  enc_pkey;
  X509* enc_cert;

  char  psobj_symkey[20];    /* sha1 hash of key data */
  char  log_symkey[20];      /* sha1 hash of key data */
  char  hmac_key[20];        /* sha1 hash of key data */
  EVP_PKEY*  log_sign_pkey;
  X509* log_enc_cert;
  SSL_CTX* ssl_ctx;
#endif
};

/*(s) Query string, or post, is parsed into the following structure. If a variable
 * is not present, it will be left as NULL. Note that this structure
 * mixes fields from all forms that ZXID might display or process. ZXID ignores
 * any field that is not explicitly foreseen here and in zxidcgi.c, i.e.
 * there is no generic hash structure. */

struct zxid_cgi {
  unsigned int magic;
  char  op;            /* o=  What should be done now. */
  char  pr_ix;         /* i=  Index to protocol profile (typically for login) */
  char  allow_create;  /* fc= Is federation permitted (allow creation of new federation) */
  char  ispassive;     /* fp= Whether IdP is allowed to seize user interface (e.g. ask password) */
  char  force_authn;   /* ff= Whether IdP SHOULD authenticate the user anew. */
  char  enc_hint;      /* Hint: Should NID be encrypted in SLO and MNI, see also cf->nameid_enc */
  char  atselafter;    /* at= Attribute selection requested checkbox. */
  char  mob;           /* Mobile device flag, detected from HTTP_USER_AGENT */
  char* sid;           /* If session is already active, the session ID. */
  char* nid;           /* NameID of the user. */
  char* uid;           /* au= Form field for user. */
  char* pw;            /* ap= Form field for password. */
  char* pin;           /* aq= Form field for pin code (second password, used in 2 factor Yubikey. */
  char* ssoreq;        /* ar= Used for conveying original AuthnReq through authn phase. */
  char* cdc;           /* c=  Common Domain Cookie, returned by the CDC reader, also succinctID */
  char* eid;           /* e=, d= Entity ID of an IdP (typically for login) */
  char* nid_fmt;       /* fn= Name ID format */
  char* affil;         /* fq= SP NameQualifier (such as in affiliation of SPs) */
  char* consent;       /* fy= Whether user consented to the operation and how. */
  char* matching_rule; /* fm= How authn_ctx is to be matched by IdP. */
  char* authn_ctx;     /* fa= What kind of authentication the IdP should assert towards SP. */
  char* pxy_count;     /* ProxyCount for triggering IdP proxying */
  char* get_complete;  /* GetComplete URL for IdP proxying */
  char* idppxylist;    /* IDPList for IdP proxying */
  char* rs;            /* RelayState in redirect profile. mod_auth_saml, SSO servlet: def-sb64 armored uri to access after SSO */
  char* newnym;        /* New NameID for MNI/nireg. Empty for federation termination. */
  char* saml_art;      /* SAMLart=... artifact, as in artifact consumer URL. */
  char* saml_resp;     /* SAMLResponse=... in redirect profile */
  char* saml_req;      /* SAMLRequest=... in redirect profile */
  char* sigalg;        /* SigAlg=... in redirect profile */
  char* sig;           /* Signature=... in redirect profile */
  char* sigval;        /* Signature validation code (as logged, VVV in zxid-log.pd, section "Log Line Format") */
  char* sigmsg;        /* Signature validation message */
  char* err;           /* When rendering screens: used to put error message to screen. */
  char* msg;           /* When rendering screens: used to put info message to screen. */
  char* dbg;           /* When rendering screens: used to put debug message to screen. */
  char* zxapp;         /* Deployment specific application parameter passed in some querystrings. */
  char* zxrfr;         /* ZX Referer. Indicates to some external pages why user was redirected. */
  char* redirafter;    /* On IdP, if local login is desired, the next page */
  char* ok;            /* Ok button in some forms */
  char* templ;         /* Template name in some forms (used to implement tabs, e.g. in idpsel) */
  char* sp_eid;        /* IdP An for to generate page */
  char* sp_dpy_name;
  char* sp_button_url;
  char* rest;          /* OAUTH2 Resource Set Registration: RESTful part of the URI */
  char* response_type; /* OAuth2 / OpenID-Connect (OIDC1), used to detect An/Az req */
  char* client_id;     /* OAuth2 */
  char* scope;         /* OAuth2 */
  char* redirect_uri;  /* OAuth2, also decoded RelayState in SAML */
  char* nonce;         /* OAuth2 */
  char* state;         /* OAuth2 (like SAML RelayState) */
  char* display;       /* OAuth2 */
  char* prompt;        /* OAuth2 */
  char* access_token;  /* OAuth2 */
  char* refresh_token; /* OAuth2 */
  char* token_type;    /* OAuth2 */
  char* grant_type;    /* OAuth2 */
  char* code;          /* OAuth2 */
  char* id_token;      /* OAuth2 */
  int   expires_in;    /* OAuth2 */
  char* iss;           /* OAuth2 */
  char* user_id;       /* OAuth2 */
  char* aud;           /* OAuth2 */
  char* exp;           /* OAuth2 */
  char* iso29115;      /* OAuth2 */
  char* schema;        /* OAuth2 */
  char* id;            /* OAuth2 */
#if 0
  char* name;          /* OAuth2 */
  char* given_name;    /* OAuth2 */
  char* family_name;   /* OAuth2 */
  char* middle_name;   /* OAuth2 */
  char* nickname;      /* OAuth2 */
  char* profile;       /* OAuth2 */
  char* picture;       /* OAuth2 */
  char* website;       /* OAuth2 */
  char* email;         /* OAuth2 */
  char* verified;      /* OAuth2 */
  char* gender;        /* OAuth2 */
  char* birthday;      /* OAuth2 */
  char* zoneinfo;      /* OAuth2 */
  char* locale;        /* OAuth2 */
  char* phone_number;  /* OAuth2 */
  char* address;       /* OAuth2 */
  char* updated_time;  /* OAuth2 */
#endif
  char* inv;           /* Invitation ID */
  char* pcode;         /* Mobile pairing code */
  char* skin;
  char* action_url;    /* <form action=URL> in some forms, such as post.html */
  char* uri_path;      /* SCRIPT_NAME or other URI path */
  char* qs;            /* QUERY_STRING */
  char* post;          /* Unparsed body of a POST */
  zxid_entity* idp_list;   /* IdPs from CDC */
};

/*(s) Session is parsed into following structure. */

struct zxid_ses {
  unsigned int magic;
  char* sid;           /* Session ID. Same as in cookie, same as file name */
  char* uid;           /* Local uid (only if local login, like in IdP) */
  char* nid;           /* String representation of Subject NameID. See also nameid. */
  char* tgt;           /* String representation of Target NameID. See also nameid. */
  char* sesix;         /* SessionIndex */
  char* ipport;        /* Source IP and port for logging, e.g: "1.2.3.4:5" */
  char* wsc_msgid;     /* Request MessageID, to facilitate Response RelatesTo validation at WSC. */
  struct zx_str* wsp_msgid; /* Request MessageID, to facilitate Response RelatesTo generation at WSP. */
  char* an_ctx;        /* Authentication Context (esp in IdP. On SP look inside a7n). */
  char  nidfmt;        /* Subject nameid format: 0=tmp NameID, 1=persistent */
  char  tgtfmt;        /* Target nameid format: 0=tmp NameID, 1=persistent */
  char  sigres;        /* Signature validation code */
  char  ssores;        /* Overall success of SSO 0==OK */
  char* sso_a7n_path;  /* Reference to the SSO assertion (needed for SLO) */
  char* tgt_a7n_path;  /* Reference to target identity assertion */
  char* setcookie;     /* If set, the content rendering should include set-cookie header. */
  char* setptmcookie;  /* For PTM related set-cookie header. */
  char* cookie;        /* Cookie seen by downstream internal requests after SSO. */
  char* rs;            /* RelayState at SSO. mod_auth_saml uses this as URI after SSO. */
  char* rcvd_usagedir; /* Received Usage Directives. Populated by zxid_wsc_validate_resp_env() */
  long an_instant;     /* IdP: Unix seconds when authentication was performed. Used in an_stmt */
  zxid_nid* nameid;    /* From a7n or EncryptedID */
  zxid_nid* tgtnameid; /* From a7n or EncryptedID */
  zxid_a7n* a7n;       /* SAML 2.0 for Subject */
  zxid_a7n* tgta7n;    /* SAML 2.0 for Target */
  char* jwt;           /* Javascript Web Token for Subject */
  char* tgtjwt;        /* Javascript Web Token for Target */
  struct zx_sa11_Assertion_s* a7n11;
  struct zx_sa11_Assertion_s* tgta7n11;
  struct zx_ff12_Assertion_s* a7n12;
  struct zx_ff12_Assertion_s* tgta7n12;
  zxid_tok* call_invoktok; /* If set, see zxid_map_identity_token(), use as wsse */
  zxid_tok* call_tgttok;   /* If set, use as TargetIdentity token */
  zxid_epr* deleg_di_epr;  /* If set, see zxid_set_delegated_discovery_epr(), used for disco. */
  zxid_fault* curflt;      /* SOAP fault, if any, reported by zxid_wsp_validate() */
  zxid_tas3_status* curstatus;  /* TAS3 status header, if any. */
  struct zx_str* issuer; /* WSP processing: the content of Sender header of request */
  struct timeval srcts;  /* WSP processing: the timestamp of the request */
  char* sesbuf;
  char* sso_a7n_buf;
  struct zxid_attr* at; /* Attributes extracted from a7n and translated using inmap. Linked list */
  char* access_token;  /* OAuth2 */
  char* refresh_token; /* OAuth2 */
  char* token_type;    /* OAuth2 */
  char* id_token;      /* OAuth2 */
  int   expires_in;    /* OAuth2 */
  char* client_id;     /* OAuth2 */
  char* client_secret; /* OAuth2 */
  char* rpt;           /* UMA */
#ifdef USE_PTHREAD
  struct zx_lock mx;
#endif
};

/*(s) Attribute node */

struct zxid_attr {
  struct zxid_attr* n;  /* Next attribute */
  struct zxid_attr* nv; /* Next value, if multivalued */
  char* name;
  char* val;
  struct zx_str* map_val;          /* Value after outmap (cached from length compute to render) */
  struct zx_sa_Attribute_s* orig;  /* Pointer to original attribute, if any */
  struct zx_str* issuer;           /* Issuer EntityID, if any */
};

/*(s) The need nodes are used for storing parsed NEED and WANT directives. */

struct zxid_need {
  struct zxid_need* n;
  struct zxid_attr* at; /* List of needed/wanted attributes (with value fields empty) */
  char* usage;          /* How do we promise to use attribute */
  char* retent;         /* How long will we retain it */
  char* oblig;          /* Obligations we are willing or able to honour */
  char* ext;
};

/*(s) Attribute mapping used in INMAP, PEPMAP, and OUTMAP directives. */

struct zxid_map {
  struct zxid_map* n;
  int   rule;
  char* ns;   /* Namespace of the source attribute */
  char* src;  /* Source attribute */
  char* dst;  /* Destination attribute */
  char* ext;
};

/*(s) Used for maintaining whitelists and blacklists as well as obligation values */

struct zxid_cstr_list {
  struct zxid_cstr_list* n;
  char* s;
};

/*(s) Obligations list with multiple values per obligation. */

struct zxid_obl_list {
  struct zxid_obl_list* n;
  char* name;
  struct zxid_cstr_list* vals;
};

#define ZXID_MAP_RULE_RENAME     0x00
#define ZXID_MAP_RULE_DEL        0x01  /* Filter attribute out */
#define ZXID_MAP_RULE_RESET      0x02  /* Reset the map, dropping previous config. */
#define ZXID_MAP_RULE_FEIDEDEC   0x03  /* Norway */
#define ZXID_MAP_RULE_FEIDEENC   0x04  /* Norway */
#define ZXID_MAP_RULE_UNSB64_INF 0x05  /* Decode safebase64-inflate ([RFC3548], [RFC1951]) */
#define ZXID_MAP_RULE_DEF_SB64   0x06  /* Encode deflate-safebase64 ([RFC1951], [RFC3548]) */
#define ZXID_MAP_RULE_UNSB64     0x07  /* NZ: Decode safebase64 ([RFC3548]) */
#define ZXID_MAP_RULE_SB64       0x08  /* NZ: Encode safebase64 ([RFC3548]) */
#define ZXID_MAP_RULE_ENC_MASK   0x0f
#define ZXID_MAP_RULE_WRAP_A7N   0x10  /* Wrap the attribute in SAML2 assertion */
#define ZXID_MAP_RULE_WRAP_X509  0x20  /* Wrap the attribute in X509 attribute certificate */
#define ZXID_MAP_RULE_WRAP_FILE  0x30  /* Get attribute value from file specified in ext */
#define ZXID_MAP_RULE_WRAP_MASK  0x30

/*(s) Parsed STOMP 1.1 headers */

struct stomp_hdr {
  int len;              /* Populated from content-length header, if one is supplied. */
  char* body;           /* Body of the message */
  char* host;           /* also receipt and receipt_id */
  char* vers;           /* version, also accept-version, tx_id */
  char* login;          /* also session, subs_id, subsc */
  char* pw;             /* also server, ack, msg_id */
  char* dest;           /* destination, also heart_bt */
  char* end_of_pdu;     /* One past end of frame data. Helps in cleaning buffer for next PDU. */
};

/*(s) Used for maintaining audit bus URL and connections */

struct zxid_bus_url {
  struct zxid_bus_url* n;
  char* s;              /* The config URL */
  char* eid;            /* EntityID of the auditbus node (for metadata and zx-rcpt-sig validate) */
  fdtype fd;            /* Remember already open connection to zxbusd instance. */
  char* m;              /* I/O buffer */
  char* ap;             /* How far the buffer is filled */
  int   cur_rcpt;       /* Rolling receipt ID */
  char  scalingpart;    /* Scaling partition number. */
  char  pad1,pad2,pad3;
#ifdef USE_OPENSSL
  SSL*  ssl;
#endif
};

/*(s) Attribute source definition */

struct zxid_atsrc {
  struct zxid_atsrc* n;
  struct zxid_attr* at; /* List of available attributes (with value fields empty) */
  char* ns;             /* Namespace, typically Entity ID of the source. */
  char* weight;
  char* url;            /* URL or other access parameters */
  char* aapml;
  char* otherlim;
  char* ext;
};

/*(s) Permission object (for PS and DI) */

struct zxid_perm {
  struct zxid_perm* n;
  struct zx_str* eid;
  struct zx_str* qs;
};

/*(s) People Service Object */

struct zxid_psobj {
  struct zx_str*  psobj;     /* ObjectID */
  char*           uid;       /* uid of the owner of the object */
  struct zx_str*  idpnid;    /* NameID of the buddy */
  struct zx_str*  dispname;
  struct zx_str*  tags;
  struct zx_str*  invids;
  struct zxid_perm* perms;   /* List of permissions associated with the buddy */
  struct zxid_psobj* child; /* In case of colletion, the members of the group, e.g. ObjectRefs. */
  int nodetype;  /* 0=buddy, 1=collection */
  int create_secs;
  int mod_secs;
};

#define ZXID_PSOBJ_BUDDY 0
#define ZXID_PSOBJ_COLLECTION 1

/*(s) Invitation object */

struct zxid_invite {
  struct zx_str*  invid;
  char*           uid;      /* Invitation by */
  struct zx_str*  desc;
  struct zx_str*  psobj;
  struct zx_str*  ps2spredir;
  struct zxid_psobj* obj;
  struct zxid_perm* perms;  /* List of permissions associated with the invitation */
  int maxusage;
  int usage;
  int starts;     /* Unix seconds since epoch */
  int expires;    /* Unix seconds since epoch */
};

#define ZXID_SES_DIR  "ses/"
#define ZXID_USER_DIR "user/"
#define ZXID_UID_DIR  "uid/"
#define ZXID_NID_DIR  "nid/"
#define ZXID_PEM_DIR  "pem/"
#define ZXID_COT_DIR  "cot/"
#define ZXID_DIMD_DIR "dimd/"
#define ZXID_INV_DIR  "inv/"
#define ZXID_LOG_DIR  "log/"
#define ZXID_PCODE_DIR  "pcode/"  /* Mobile pairing codes */
#define ZXID_DCR_DIR  "dcr/"  /* OAUTH2 Dynamic Client Registrations */
#define ZXID_RSR_DIR  "rsr/"  /* OAUTH2 Resource Set Registrations */
#define ZXID_MAX_USER (256)   /* Maximum size of .mni or user file */
#define ZXID_INIT_MD_BUF   (8*1024-1)  /* Initial size, will automatically reallocate. */
#define ZXID_INIT_SOAP_BUF (8*1024-1)  /* Initial size, will automatically reallocate. */
#define ZXID_MAX_CURL_BUF  (10*1024*1024-1)  /* Buffer reallocation will not grow beyond this. */
#define ZXID_MAX_EID  (1024)
#define ZXID_MAX_DIR  (4*1024)
#define ZXID_MAX_SP_NAME_BUF (1024)

/* --------------- zxid_simple() API (see zxidsimp.c) --------------- */

#define ZXID_AUTO_EXIT    0x01 /* Do not call exit(2), return "n" instead */
#define ZXID_AUTO_REDIR   0x02 /* Autoredirs, assume CGI, calls exit(2) */
#define ZXID_AUTO_SOAPC   0x04 /* SOAP resp content */
#define ZXID_AUTO_SOAPH   0x08 /* SOAP resp headers */
#define ZXID_AUTO_METAC   0x10 /* metadata content */
#define ZXID_AUTO_METAH   0x20 /* metadata headers*/
#define ZXID_AUTO_LOGINC  0x40 /* login page content */
#define ZXID_AUTO_LOGINH  0x80 /* login page headers */
#define ZXID_AUTO_MGMTC  0x100 /* mgmt page content */
#define ZXID_AUTO_MGMTH  0x200 /* mgmt page headers */
#define ZXID_AUTO_FORMF  0x400 /* Wrap the output in <form> tag. Full page HTML. */
#define ZXID_AUTO_FORMT  0x800 /* Wrap the output in <form> tag. */
#define ZXID_AUTO_ALL    0xfff /* Enable all automatic behaviour. (4095) */
#define ZXID_AUTO_DEBUG 0x1000 /* Enable debugging output to stderr. */
#define ZXID_AUTO_FMTQ  0x2000 /* Output Format Query String */
#define ZXID_AUTO_FMTJ  0x4000 /* Output Format JSON */

ZXID_DECL char* zxid_simple(char* conf, char* qs, int auto_flags);
ZXID_DECL char* zxid_idp_list(char* conf, int auto_flags);
ZXID_DECL char* zxid_idp_select(char* conf, int auto_flags);
ZXID_DECL char* zxid_fed_mgmt(char* conf, char* sid, int auto_flags);

ZXID_DECL zxid_conf* zxid_new_conf_to_cf(const char* conf);
ZXID_DECL char* zxid_simple_cf(zxid_conf* cf, int qs_len, char* qs, int* res_len, int auto_flags);
ZXID_DECL char* zxid_idp_list_cf(zxid_conf* cf, int* res_len, int auto_flags);
ZXID_DECL char* zxid_idp_select_cf(zxid_conf* cf, int* res_len, int auto_flags);
ZXID_DECL char* zxid_fed_mgmt_cf(zxid_conf* cf, int* res_len, int sid_len, char* sid, int auto_flags);

ZXID_DECL int zxid_conf_to_cf_len(zxid_conf* cf, int conf_len, const char* conf);
ZXID_DECL char* zxid_simple_len(int conf_len, char* conf, int qs_len, char* qs, int* res_len, int auto_flags);
ZXID_DECL char* zxid_simple_show_idp_sel(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags);
ZXID_DECL char* zxid_idp_list_len(int conf_len, char* conf, int* res_len, int auto_flags);
ZXID_DECL char* zxid_idp_list_cf_cgi(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags);
ZXID_DECL char* zxid_idp_select_len(int conf_len, char* conf, int* res_len, int auto_flags);
ZXID_DECL char* zxid_fed_mgmt_len(int conf_len, char* conf, int* res_len, char* sid, int auto_flags);
ZXID_DECL struct zx_str* zxid_idp_select_zxstr_cf(zxid_conf* cf, int auto_flags);

ZXID_DECL char* zxid_simple_show_err(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags);

ZXID_DECL char* zxid_simple_ses_active_cf(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags);
ZXID_DECL char* zxid_simple_no_ses_cf(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags);
ZXID_DECL char* zxid_simple_cf_ses(zxid_conf* cf, int qs_len, char* qs, zxid_ses* ses, int* res_len, int auto_flags);
ZXID_DECL struct zx_str* zxid_template_page_cf(zxid_conf* cf, zxid_cgi* cgi, const char* templ_path, const char* default_templ, int size_hint, int auto_flags);

/* --------------- Full API --------------- */

/* Signatures */

#define ZXID_SSO_SIGN_A7N  0x01
#define ZXID_SSO_SIGN_RESP 0x02
#define ZXID_SSO_SIGN_A7N_SIMPLE  0x04  /* N.B. Usually not as Simple Sig message sig is enough. */

#define ZXID_SIGN_HDR  0x01  /* Sign ID-WSF relevant SOAP Headers */
#define ZXID_SIGN_BDY  0x02  /* Sign SOAP Body */

struct zxsig_ref {
  struct zx_ds_Reference_s* sref;  /* Reference for validation */
  struct zx_elem_s* blob;          /* XML data structure for validation */
  struct zx_str* id;               /* ID attribute of element to sign */
  struct zx_str* canon;            /* String representing canonicalization for signing */
  struct zx_ns_s* pop_seen;        /* Namespaces from outer layers for inc_ns processing */
};

#define ZXSIG_OK         0
#define ZXSIG_BAD_DALGO  1  /* A Unsupported digest algorithm. */
#define ZXSIG_DIGEST_LEN 2  /* G Wrong digest length. */
#define ZXSIG_BAD_DIGEST 3  /* G Digest value does not match. */
#define ZXSIG_BAD_SALGO  4  /* A Unsupported signature algorithm. */
#define ZXSIG_BAD_CERT   5  /* I Extraction of public key from certificate failed. */
#define ZXSIG_VFY_FAIL   6  /* R Verification of signature failed. */
#define ZXSIG_NO_SIG     7  /* N No signature found. */
#define ZXSIG_TIMEOUT    8  /* V Validity time has expired. */
#define ZXSIG_AUDIENCE   9  /* V Assertion has wrong audience. */

#ifdef USE_OPENSSL
ZXID_DECL struct zx_ds_Signature_s* zxsig_sign(struct zx_ctx* c, int n, struct zxsig_ref* sref, X509* cert, EVP_PKEY* priv_key, const char* sig_meth_spec, const char* digest_spec);
ZXID_DECL int zxsig_validate(struct zx_ctx* c, X509* cert, struct zx_ds_Signature_s* sig, int n, struct zxsig_ref* refs);
ZXID_DECL int zxsig_data(struct zx_ctx* c, int len, const char* d, char** sig, EVP_PKEY* priv_key, const char* lk, const char* md_alg);
ZXID_DECL int zxsig_verify_data(int len, char* data, int siglen, char* sig, X509* cert, const char* lk, const char* mdalg);
ZXID_DECL struct zx_xenc_EncryptedData_s* zxenc_pubkey_enc(zxid_conf* cf, struct zx_str* data, struct zx_xenc_EncryptedKey_s** ekp, X509* cert, char* idsuffix, zxid_entity* meta);
#endif
ZXID_DECL struct zx_str* zxenc_privkey_dec(zxid_conf* cf, struct zx_xenc_EncryptedData_s* ed, struct zx_xenc_EncryptedKey_s* ek);
ZXID_DECL struct zx_xenc_EncryptedData_s* zxenc_symkey_enc(zxid_conf* cf, struct zx_str* data, struct zx_str* ed_id, struct zx_str* symkey, struct zx_xenc_EncryptedKey_s* ek);
ZXID_DECL struct zx_str* zxenc_symkey_dec(zxid_conf* cf, struct zx_xenc_EncryptedData_s* ed, struct zx_str* symkey);

/* zxlog (see logging chapter in README.zxid) */

/*  /var/zxid/log/rely/ISSUER-SHA1-NAME/a7n/A7N-ID-AS-SHA1 */
#define ZXBUS_CH_DIR    "ch/"
#define ZXLOG_RELY_DIR  "rely/"
#define ZXLOG_ISSUE_DIR "issue/"
#define ZXLOG_A7N_KIND  "/a7n/"
#define ZXLOG_JWT_KIND  "/jwt/"
#define ZXLOG_AZC_KIND  "/azc/"
#define ZXLOG_MSG_KIND  "/msg/"
#define ZXLOG_WIR_KIND  "/wir/"

ZXID_DECL void zxlog_write_line(zxid_conf* cf, char* c_path, int encflags, int n, const char* logbuf);
ZXID_DECL int zxlog_dup_check(zxid_conf* cf, struct zx_str* path, const char* logkey);
ZXID_DECL int zxlog_blob(zxid_conf* cf, int logflag, struct zx_str* path, struct zx_str* blob, const char* lk);
ZXID_DECL int zxlog(zxid_conf* cf, struct timeval* ourts, struct timeval* srcts, const char* ipport, struct zx_str* entid, struct zx_str* msgid, struct zx_str* a7nid, struct zx_str* nid, const char* sigval, const char* res, const char* op, const char* arg, const char* fmt, ...);
ZXID_DECL int zxlogwsp(zxid_conf* cf, zxid_ses* ses, const char* res, const char* op, const char* arg, const char* fmt, ...);
ZXID_DECL int zxlogusr(zxid_conf* cf, const char* uid, struct timeval* ourts, struct timeval* srcts, const char* ipport, struct zx_str* entid, struct zx_str* msgid, struct zx_str* a7nid, struct zx_str* nid, const char* sigval, const char* res, const char* op, const char* arg, const char* fmt, ...);
ZXID_DECL void errmac_debug_xml_blob(zxid_conf* cf, const char* file, int line, const char* func, const char* lk, int len, const char* xml);
ZXID_DECL char* zxbus_mint_receipt(zxid_conf* cf, int sigbuf_len, char* sigbuf, int mid_len, const char* mid, int dest_len, const char* dest, int eid_len, const char* eid, int body_len, const char* body);
ZXID_DECL int zxbus_verify_receipt(zxid_conf* cf, const char* eid, int sigbuf_len, char* sigbuf, int mid_len, const char* mid, int dest_len, const char* dest, int deid_len, const char* deid, int body_len, const char* body);
ZXID_DECL int zxbus_persist_msg(zxid_conf* cf, int c_path_len, char* c_path, int dest_len, const char* dest, int data_len, const char* data);

/* zxbusprod */

ZXID_DECL int zxbus_open_bus_url(zxid_conf* cf, struct zxid_bus_url* bu);
ZXID_DECL int zxbus_close(zxid_conf* cf, struct zxid_bus_url* bu);
ZXID_DECL void zxbus_close_all(zxid_conf* cf);
ZXID_DECL int zxbus_send_cmdf(zxid_conf* cf, struct zxid_bus_url* bu, int body_len, const char* body, const char* fmt, ...);
ZXID_DECL int zxbus_send_cmd(zxid_conf* cf, const char* cmd, const char* dest, int body_len, const char* body);
ZXID_DECL int zxbus_send(zxid_conf* cf, const char* dest, int body_len, const char* body);
ZXID_DECL int zxbus_read_stomp(zxid_conf* cf, struct zxid_bus_url* bu, struct stomp_hdr* stomp);
ZXID_DECL int zxbus_ack_msg(zxid_conf* cf, struct zxid_bus_url* bu, struct stomp_hdr* stompp);
ZXID_DECL char* zxbus_listen_msg(zxid_conf* cf, struct zxid_bus_url* bu);

/* zxidmeta */

ZXID_DECL zxid_entity* zxid_get_ent_file(zxid_conf* cf, const char* sha1_name, const char* logkey);
ZXID_DECL zxid_entity* zxid_get_ent_cache(zxid_conf* cf, struct zx_str* eid);
ZXID_DECL int zxid_write_ent_to_cache(zxid_conf* cf, zxid_entity* ent);
ZXID_DECL zxid_entity* zxid_parse_meta(zxid_conf* cf, char** md, char* lim);
ZXID_DECL zxid_entity* zxid_get_meta_ss(zxid_conf* cf, struct zx_str* url);
ZXID_DECL zxid_entity* zxid_get_meta(zxid_conf* cf, const char* url);
ZXID_DECL zxid_entity* zxid_get_ent_ss(zxid_conf* cf, struct zx_str* eid);
ZXID_DECL zxid_entity* zxid_get_ent(zxid_conf* cf, const char* eid);
ZXID_DECL zxid_entity* zxid_get_ent_by_succinct_id(zxid_conf* cf, char* raw_succinct_id);
ZXID_DECL zxid_entity* zxid_get_ent_by_sha1_name(zxid_conf* cf, char* sha1_name);
ZXID_DECL zxid_entity* zxid_load_cot_cache(zxid_conf* cf);

ZXID_DECL struct zx_str* zxid_sp_meta(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL int zxid_send_sp_meta(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL struct zx_str* zxid_sp_carml(zxid_conf* cf);
ZXID_DECL struct zx_str* zxid_my_ent_id(zxid_conf* cf);
ZXID_DECL char* zxid_my_ent_id_cstr(zxid_conf* cf);
ZXID_DECL struct zx_attr_s* zxid_my_ent_id_attr(zxid_conf* cf, struct zx_elem_s* father, int tok);
ZXID_DECL struct zx_str* zxid_my_cdc_url(zxid_conf* cf);
ZXID_DECL struct zx_sa_Issuer_s* zxid_my_issuer(zxid_conf* cf, struct zx_elem_s* father);
ZXID_DECL struct zx_sa_Issuer_s* zxid_issuer(zxid_conf* cf, struct zx_elem_s* father, struct zx_str* nameid, char* affiliation);

/* zxidconf */

#ifdef USE_OPENSSL
ZXID_DECL X509* zxid_extract_cert(char* buf, char* name);
ZXID_DECL EVP_PKEY*  zxid_extract_private_key(char* buf, char* name);
ZXID_DECL X509* zxid_read_cert(zxid_conf* cf, char* name);
ZXID_DECL EVP_PKEY*  zxid_read_private_key(zxid_conf* cf, char* name);
ZXID_DECL int zxid_lazy_load_sign_cert_and_pkey(zxid_conf* cf, X509** cert, EVP_PKEY** pkey, const char* logkey);
ZXID_DECL const char* zxid_get_cert_signature_algo(X509* cert);
ZXID_DECL const char* zxsig_choose_xmldsig_sig_meth_url(EVP_PKEY* priv_key, const char* dig_alg);
ZXID_DECL const char* zxsig_choose_xmldsig_sig_meth_urlenc(EVP_PKEY* priv_key, const char* dig_alg);
  //ZXID_DECL const char* zxid_get_cert_signature_algo_url(X509* cert);
  //ZXID_DECL const char* zxid_get_cert_signature_algo_urlenc(X509* cert);
  //ZXID_DECL const char* zxid_get_cert_digest_url(X509* cert);
#endif
ZXID_DECL int   zxid_set_opt(zxid_conf* cf, int which, int val);
ZXID_DECL char* zxid_set_opt_cstr(zxid_conf* cf, int which, char* val);
ZXID_DECL void  zxid_url_set(zxid_conf* cf, const char* url);
ZXID_DECL int   zxid_init_conf(zxid_conf* cf, const char* conf_dir);
ZXID_DECL void zxid_free_conf(zxid_conf *cf);
ZXID_DECL zxid_conf* zxid_init_conf_ctx(zxid_conf* cf, const char* zxid_path);
ZXID_DECL zxid_conf* zxid_new_conf(const char* zxid_path);
ZXID_DECL int   zxid_parse_conf_raw(zxid_conf* cf, int qs_len, char* qs);
ZXID_DECL int   zxid_parse_conf(zxid_conf* cf, char* qs);
ZXID_DECL int   zxid_mk_self_sig_cert(zxid_conf* cf, int buflen, char* buf, const char* lk, const char* name);
ZXID_DECL int   zxid_mk_at_cert(zxid_conf* cf, int buflen, char* buf, const char* lk, zxid_nid* nameid, const char* name, struct zx_str* val);
ZXID_DECL struct zx_str* zxid_show_conf(zxid_conf* cf);

/* zxidcgi */

ZXID_DECL int zxid_parse_cgi(zxid_conf* cf, zxid_cgi* cgi, char* qs);
ZXID_DECL zxid_cgi* zxid_new_cgi(zxid_conf* cf, char* qs);
ZXID_DECL void zxid_get_sid_from_cookie(zxid_conf* cf, zxid_cgi* cgi, const char* cookie);

/* zxidses */

ZXID_DECL zxid_ses* zxid_alloc_ses(zxid_conf* cf);
ZXID_DECL zxid_ses* zxid_fetch_ses(zxid_conf* cf, const char* sid);
ZXID_DECL int zxid_get_ses(zxid_conf* cf, zxid_ses* ses, const char* sid);
ZXID_DECL int zxid_put_ses(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL int zxid_del_ses(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL int zxid_get_ses_sso_a7n(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL zxid_entity* zxid_get_ses_idp(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL int zxid_find_ses(zxid_conf* cf, zxid_ses* ses, struct zx_str* ses_ix, struct zx_str* nid);

/* zxidpool */

ZXID_DECL struct zx_str* zxid_ses_to_ldif(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL struct zx_str* zxid_ses_to_json(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL struct zx_str* zxid_ses_to_qs(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_ses_to_pool(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_add_attr_to_ses(zxid_conf* cf, zxid_ses* ses, char* at_name, struct zx_str* val);
ZXID_DECL int zxid_add_qs2ses(zxid_conf* cf, zxid_ses* ses, char* qs, int apply_map);

/* zxiduser */

ZXID_DECL void zxid_user_sha1_name(zxid_conf* cf, struct zx_str* qualif, struct zx_str* nid, char* sha1_name);
ZXID_DECL int zxid_put_user(zxid_conf* cf, struct zx_str* nidfmt, struct zx_str* idpent, struct zx_str* spqual, struct zx_str* idpnid, char* mniptr);
ZXID_DECL zxid_nid* zxid_get_user_nameid(zxid_conf* cf, zxid_nid* oldnid);
ZXID_DECL void zxid_user_change_nameid(zxid_conf* cf, zxid_nid* oldnid, struct zx_str* newnym);
ZXID_DECL int zxid_pw_authn(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);

/* zxidcurl */

ZXID_DECL struct zx_str* zxid_http_cli(zxid_conf* cf, int url_len, const char* url, int len, const char* data, const char* content_type, const char* headers, int flags);
ZXID_DECL struct zx_root_s* zxid_soap_call_raw(zxid_conf* cf, struct zx_str* url, struct zx_e_Envelope_s* env, char** ret_enve);
ZXID_DECL struct zx_root_s* zxid_soap_call_hdr_body(zxid_conf* cf, struct zx_str* url, struct zx_e_Header_s* hdr, struct zx_e_Body_s* body);
ZXID_DECL int zxid_soap_cgi_resp_body(zxid_conf* cf, zxid_ses* ses, struct zx_e_Body_s* body);
ZXID_DECL const char* zxid_get_last_content_type(zxid_conf* cf);

/* zxidlib */

ZXID_DECL int zxid_version();
ZXID_DECL const char* zxid_version_str();

ZXID_DECL struct zx_str* zx_easy_enc_elem_opt(zxid_conf* cf, struct zx_elem_s* x);
ZXID_DECL struct zx_str* zx_easy_enc_elem_sig(zxid_conf* cf, struct zx_elem_s* x);

ZXID_DECL struct zx_str* zxid_date_time(zxid_conf* cf, time_t secs);
ZXID_DECL struct zx_str* zxid_mk_id(zxid_conf* cf, char* prefix, int bits); /* pseudo random ident. */

ZXID_DECL struct zx_attr_s* zxid_date_time_attr(zxid_conf* cf, struct zx_elem_s* father, int tok, time_t secs);
ZXID_DECL struct zx_attr_s* zxid_mk_id_attr(zxid_conf* cf, struct zx_elem_s* father, int tok, char* prefix, int bits);

ZXID_DECL struct zx_str* zxid_saml2_post_enc(zxid_conf* cf, char* field, struct zx_str* payload, char* relay_state, int sign, struct zx_str* action_url);
ZXID_DECL struct zx_str* zxid_saml2_redir_enc(zxid_conf* cf, char* cgivar, struct zx_str* pay_load, char* relay_state);
ZXID_DECL struct zx_str* zxid_saml2_redir_url(zxid_conf* cf, struct zx_str* loc, struct zx_str* pay_load, char* relay_state);
ZXID_DECL struct zx_str* zxid_saml2_redir(zxid_conf* cf, struct zx_str* loc, struct zx_str* pay_load, char* relay_state);
ZXID_DECL struct zx_str* zxid_saml2_resp_redir(zxid_conf* cf, struct zx_str* loc, struct zx_str* pay_load, char* relay_state);

ZXID_DECL int zxid_saml_ok(zxid_conf* cf, zxid_cgi* cgi, struct zx_sp_Status_s* st, char* what);
ZXID_DECL zxid_nid* zxid_decrypt_nameid(zxid_conf* cf, zxid_nid* nid, struct zx_sa_EncryptedID_s* encid);
ZXID_DECL struct zx_str* zxid_decrypt_newnym(zxid_conf* cf, struct zx_str* newnym, struct zx_sp_NewEncryptedID_s* encid);

ZXID_DECL char* zxid_extract_body(zxid_conf* cf, char* enve);

ZXID_DECL char* zx_get_symkey(zxid_conf* cf, const char* keyname, char* symkey);

/* zxidloc */

ZXID_DECL struct zx_root_s* zxid_idp_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_entity* idp_meta, int svc_type, struct zx_e_Body_s* body);

ZXID_DECL struct zx_root_s* zxid_sp_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_entity* sp_meta, int svc_type, struct zx_e_Body_s* body);

/* zxiddec */

ZXID_DECL struct zx_sa_Issuer_s* zxid_extract_issuer(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_root_s* r);
ZXID_DECL struct zx_root_s* zxid_decode_redir_or_post(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int chk_dup);

/* zxidspx */

ZXID_DECL zxid_a7n* zxid_dec_a7n(zxid_conf* cf, zxid_a7n* a7n, struct zx_sa_EncryptedAssertion_s* enca7n);

/* zxidsso - SP side of SSO: consuming A7N */

ZXID_DECL int zxid_sp_deref_art(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);
ZXID_DECL int zxid_as_call_ses(zxid_conf* cf, zxid_entity* idp_meta, zxid_cgi* cgi, zxid_ses* ses);
ZXID_DECL zxid_ses* zxid_as_call(zxid_conf* cf, zxid_entity* idp_meta, const char* user, const char* pw);
ZXID_DECL struct zx_str* zxid_start_sso_url(zxid_conf* cf, zxid_cgi* cgi);

/* zxidslo */

ZXID_DECL int zxid_sp_slo_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);
ZXID_DECL struct zx_str* zxid_sp_slo_redir(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);

/* zxidmni */

ZXID_DECL int zxid_sp_mni_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_str* new_nym);
ZXID_DECL struct zx_str* zxid_sp_mni_redir(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_str* new_nym);

/* zxidpep */

ZXID_DECL char* zxid_az_cf_ses(zxid_conf* cf, const char* qs, zxid_ses* ses);
ZXID_DECL char* zxid_az_cf(zxid_conf* cf, const char* qs, const char* sid);
ZXID_DECL char* zxid_az(const char* conf, const char* qs, const char* sid);

ZXID_DECL char* zxid_az_base_cf_ses(zxid_conf* cf, const char* qs, zxid_ses* ses);
ZXID_DECL char* zxid_az_base_cf(zxid_conf* cf, const char* qs, const char* sid);
ZXID_DECL char* zxid_az_base(const char* conf, const char* qs, const char* sid);

/* zxida7n */

ZXID_DECL struct zx_sa_Attribute_s* zxid_find_attribute(zxid_a7n* a7n, int nfmt_len, char* nfmt, int name_len, char* name, int friendly_len, char* friendly, int n);

/* zxidmk */

ZXID_DECL struct zx_sp_Status_s* zxid_mk_Status(zxid_conf* cf, struct zx_elem_s* father, const char* sc1, const char* sc2, const char* msg);
ZXID_DECL struct zx_sp_Status_s* zxid_OK(zxid_conf* cf, struct zx_elem_s* father);

/* zxidoauth */

ZXID_DECL struct zx_str* zxid_mk_oauth_az_req(zxid_conf* cf, zxid_cgi* cgi, struct zx_str* loc, char* relay_state);
ZXID_DECL char* zxid_mk_jwks(zxid_conf* cf);
ZXID_DECL char* zxid_mk_oauth2_dyn_cli_reg_req(zxid_conf* cf);
ZXID_DECL char* zxid_mk_oauth2_dyn_cli_reg_res(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL char* zxid_mk_oauth2_rsrc_reg_req(zxid_conf* cf, const char* rsrc_name, const char* rsrc_icon_uri, const char* rsrc_scope_url, const char* rsrc_type);
ZXID_DECL char* zxid_mk_oauth2_rsrc_reg_res(zxid_conf* cf, zxid_cgi* cgi, char* rev);
ZXID_DECL char* zxid_oauth_get_well_known_item(zxid_conf* cf, const char* base_uri, const char* key);
ZXID_DECL struct zx_str* zxid_oauth_dynclireg_client(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* as_uri);
ZXID_DECL void zxid_oauth_rsrcreg_client(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* as_uri, const char* rsrc_name, const char* rsrc_icon_uri, const char* rsrc_scope_url, const char* rsrc_type);
ZXID_DECL char* zxid_oauth_call_rpt_endpoint(zxid_conf* cf, zxid_ses* ses, const char* host_id, const char* as_uri);
ZXID_DECL char* zxid_oauth_call_az_endpoint(zxid_conf* cf, zxid_ses* ses, const char* host_id, const char* as_uri, const char* ticket);
ZXID_DECL int zxid_oidc_as_call(zxid_conf* cf, zxid_ses* ses, zxid_entity* idp_meta, const char* _uma_authn);

/* zxidmkwsf */

ZXID_DECL struct zx_lu_Status_s* zxid_mk_lu_Status(zxid_conf* cf, struct zx_elem_s* father, const char* sc1, const char* sc2, const char* msg, const char* ref);
ZXID_DECL zxid_tas3_status* zxid_mk_tas3_status(zxid_conf* cf, struct zx_elem_s* father, const char* ctlpt,  const char* sc1, const char* sc2, const char* msg, const char* ref);
ZXID_DECL zxid_fault* zxid_mk_fault(zxid_conf* cf, struct zx_elem_s* father, const char* fa, const char* fc, const char* fs, const char* sc1, const char* sc2, const char* msg, const char* ref);
ZXID_DECL zxid_fault* zxid_mk_fault_zx_str(zxid_conf* cf, struct zx_elem_s* father, struct zx_str* fa, struct zx_str* fc, struct zx_str* fs);

ZXID_DECL void zxid_set_fault(zxid_conf* cf, zxid_ses* ses, zxid_fault* flt);
ZXID_DECL zxid_fault*  zxid_get_fault(zxid_conf* cf, zxid_ses* ses);

ZXID_DECL char* zxid_get_tas3_fault_sc1(zxid_conf* cf, zxid_fault* flt);
ZXID_DECL char* zxid_get_tas3_fault_sc2(zxid_conf* cf, zxid_fault* flt);
ZXID_DECL char* zxid_get_tas3_fault_comment(zxid_conf* cf, zxid_fault* flt);
ZXID_DECL char* zxid_get_tas3_fault_ref(zxid_conf* cf, zxid_fault* flt);
ZXID_DECL char* zxid_get_tas3_fault_actor(zxid_conf* cf, zxid_fault* flt);

ZXID_DECL zxid_tas3_status* zxid_get_fault_status(zxid_conf* cf, zxid_fault* flt);

ZXID_DECL void zxid_set_tas3_status(zxid_conf* cf, zxid_ses* ses, zxid_tas3_status* status);
ZXID_DECL zxid_tas3_status* zxid_get_tas3_status(zxid_conf* cf, zxid_ses* ses);

ZXID_DECL char* zxid_get_tas3_status_sc1(zxid_conf* cf, zxid_tas3_status* st);
ZXID_DECL char* zxid_get_tas3_status_sc2(zxid_conf* cf, zxid_tas3_status* st);
ZXID_DECL char* zxid_get_tas3_status_comment(zxid_conf* cf, zxid_tas3_status* st);
ZXID_DECL char* zxid_get_tas3_status_ref(zxid_conf* cf, zxid_tas3_status* st);
ZXID_DECL char* zxid_get_tas3_status_ctlpt(zxid_conf* cf, zxid_tas3_status* st);

/* zxidwsp */

ZXID_DECL char* zxid_wsp_validate_env(zxid_conf* cf, zxid_ses* ses, const char* az_cred, struct zx_e_Envelope_s* env);
ZXID_DECL char* zxid_wsp_validate(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* enve);
ZXID_DECL struct zx_str* zxid_wsp_decorate(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* enve);
ZXID_DECL struct zx_str* zxid_wsp_decoratef(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* env_f, ...);
ZXID_DECL int zxid_wsf_decor(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env, int is_resp, zxid_epr* epri);

/* zxidwsc */

ZXID_DECL struct zx_str* zxid_call(zxid_conf* cf, zxid_ses* ses, const char* svctype, const char* url, const char* di_opt, const char* az_cred, const char* enve);
ZXID_DECL struct zx_str* zxid_callf(zxid_conf* cf, zxid_ses* ses, const char* svctype, const char* url, const char* di_opt, const char* az_cred, const char* env_f, ...);
ZXID_DECL struct zx_str* zxid_call_epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, const char* az_cred, const char* enve);
ZXID_DECL struct zx_str* zxid_callf_epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, const char* az_cred, const char* env_f, ...);
ZXID_DECL struct zx_str* zxid_wsc_prepare_call(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, const char* az_cred, const char* enve);
ZXID_DECL struct zx_str* zxid_wsc_prepare_callf(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, const char* az_cred, const char* env_f, ...);
ZXID_DECL int zxid_wsc_valid_resp(zxid_conf* cf, zxid_ses* ses, const char* az_cred, const char* enve);

#define ZXID_RESP_ENV(cf, tag, status_code, status_comment) zxid_new_envf((cf), "<%s><lu:Status code=\"%s\" comment=\"%s\"></lu:Status></%s>", (tag), (status_code), (status_comment), (tag))

/*() Most SOAP messages (at least in Liberty based web services) have
 * the status field in same place, but they all have different data
 * types. Given the similarity it is desireable to have common
 * "function" for checking status, but due to the type problem it has
 * to be done with a macro (dynamically typed language would make this easy). */

#define ZXID_CHK_STATUS(env, field, abort_action) MB struct zx_str* ss; if (!(env)) abort_action; \
  if (!env->Body->field) { ERR("Body is missing " #field " element. %p", env); abort_action; } \
  if (!env->Body->field->Status) { ERR( #field " is missing Status. %p", env); abort_action; } \
  if (!env->Body->field->Status->code) { ERR( #field "->Status is missing code. %p", env); abort_action; } \
  if (!env->Body->field->Status->code->s) { ERR( #field "->Status->code empty. %p", env); abort_action; } \
  if (!memcmp(env->Body->field->Status->code->s, "OK", 2)) { \
       ss = env->Body->field->Status->comment; \
       D(#field ": Status OK (%.*s)", ss?ss->len:0, ss?ss->s:""); \
    } else { \
       ss = env->Body->field->Status->comment; \
       ERR("FAIL: " #field ": Status %.*s (%.*s)", \
         env->Body->field->Status->code->len, env->Body->field->Status->code->s, \
         ss?ss->len:0, ss?ss->s:""); \
      abort_action; \
    } \
  ME

/* zxidepr */

ZXID_DECL zxid_epr* zxid_get_epr(zxid_conf* cf, zxid_ses* ses, const char* svc, const char* url, const char* di_opt, const char* action, int n);
ZXID_DECL zxid_epr* zxid_find_epr(zxid_conf* cf, zxid_ses* ses, const char* svc, const char* url, const char* di_opt, const char* action, int n);

ZXID_DECL struct zx_str* zxid_get_epr_address(zxid_conf* cf, zxid_epr* epr);
ZXID_DECL struct zx_str* zxid_get_epr_entid(zxid_conf* cf, zxid_epr* epr);
ZXID_DECL struct zx_str* zxid_get_epr_desc(zxid_conf* cf, zxid_epr* epr);
ZXID_DECL struct zx_str* zxid_get_epr_tas3_trust(zxid_conf* cf, zxid_epr* epr);
ZXID_DECL struct zx_str* zxid_get_epr_secmech(zxid_conf* cf, zxid_epr* epr);

ZXID_DECL void zxid_set_epr_secmech(zxid_conf* cf, zxid_epr* epr, const char* secmec);
ZXID_DECL zxid_tok* zxid_get_epr_token(zxid_conf* cf, zxid_epr* epr);
ZXID_DECL void zxid_set_epr_token(zxid_conf* cf, zxid_epr* epr, zxid_tok* tok);
ZXID_DECL zxid_epr* zxid_new_epr(zxid_conf* cf, char* address, char* desc, char* entid, char* svctype);

ZXID_DECL zxid_epr* zxid_get_delegated_discovery_epr(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_delegated_discovery_epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr);

ZXID_DECL zxid_tok* zxid_get_call_invoktok(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_call_invoktok(zxid_conf* cf, zxid_ses* ses, zxid_tok* tok);
ZXID_DECL zxid_tok* zxid_get_call_tgttok(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_call_tgttok(zxid_conf* cf, zxid_ses* ses, zxid_tok* tok);

ZXID_DECL struct zx_str* zxid_epr2str(zxid_conf* cf, zxid_epr* epr);
ZXID_DECL struct zx_str* zxid_token2str(zxid_conf* cf, zxid_tok* tok);
ZXID_DECL zxid_tok* zxid_str2token(zxid_conf* cf, struct zx_str* ss);
ZXID_DECL struct zx_str* zxid_a7n2str(zxid_conf* cf, zxid_a7n* a7n);
ZXID_DECL zxid_a7n* zxid_str2a7n(zxid_conf* cf, struct zx_str* ss);
ZXID_DECL struct zx_str* zxid_nid2str(zxid_conf* cf, zxid_nid* nid);
ZXID_DECL zxid_nid* zxid_str2nid(zxid_conf* cf, struct zx_str* ss);

ZXID_DECL zxid_nid* zxid_get_nameid(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_nameid(zxid_conf* cf, zxid_ses* ses, zxid_nid* nid);
ZXID_DECL zxid_nid* zxid_get_tgtnameid(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_tgtnameid(zxid_conf* cf, zxid_ses* ses, zxid_nid* nid);

ZXID_DECL zxid_a7n* zxid_get_a7n(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_a7n(zxid_conf* cf, zxid_ses* ses, zxid_a7n* a7n);
ZXID_DECL zxid_a7n* zxid_get_tgta7n(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL void zxid_set_tgta7n(zxid_conf* cf, zxid_ses* ses, zxid_a7n* a7n);

/* zxidim -  Identity Mapping Service, Single Sign-On Service (SSOS) */

ZXID_DECL zxid_tok* zxid_map_identity_token(zxid_conf* cf, zxid_ses* ses, const char* at_eid, int how);

ZXID_DECL zxid_tok* zxid_nidmap_identity_token(zxid_conf* cf, zxid_ses* ses, const char* at_eid, int how);

/* zxidps -  People Service (and delegation) */

ZXID_DECL char* zxid_ps_accept_invite(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags);
ZXID_DECL char* zxid_ps_finalize_invite(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags);

/* zxidpsso */

ZXID_DECL char* zxid_get_idpnid_at_eid(zxid_conf* cf, const char* uid, const char* eid, int allow_create);

/* DAP scope constants are same as for LDAP, see RFC2251 */

#define ZXID_DAP_SCOPE_BASE    0  /* Only what is pointed to by DN, e.g. one entry. The default. */
#define ZXID_DAP_SCOPE_SINGLE  1  /* Single level of directory right under DN. */
#define ZXID_DAP_SCOPE_SUBTREE 2  /* Full subtree search under the DN. */

/* If CDC is not present, the user interface is always offered. */

#define ZXID_CDC_CHOICE_ALWAYS_FIRST 1  /* Do not offer UI, always pick first on CDC list. */
#define ZXID_CDC_CHOICE_ALWAYS_LAST  2  /* Do not offer UI, always pick last on CDC list. */
#define ZXID_CDC_CHOICE_ALWAYS_ONLY  3  /* If CDC has only one IdP, always pick it. */
#define ZXID_CDC_CHOICE_UI_PREF      4  /* Offer UI with the CDC designated IdPs first. */
#define ZXID_CDC_CHOICE_UI_NOPREF    5  /* Offer UI. Do not give preference to CDC IdPs. */
#define ZXID_CDC_CHOICE_UI_ONLY_CDC  6  /* Offer UI. If CDC was set, only show IdPs from CDC. Otherwise show all IdPs. */

/* index values for selecting different bindings. These appear as index XML
 * attribute in metadata and also in Web GUI formfield names, e.g. "l1" means
 * HTTP-Artifact and "l6" means OpenID-Connect 1.0 (OIDC1).
 * See also: zxid_pick_sso_profile(), cgi->pr_ix */

#define ZXID_DEFAULT_PR_IX 0
#define ZXID_SAML2_ART 1
#define ZXID_SAML2_POST 2
#define ZXID_SAML2_SOAP 3
#define ZXID_SAML2_PAOS 4
#define ZXID_SAML2_POST_SIMPLE_SIGN 5
#define ZXID_SAML2_REDIR 6
#define ZXID_SAML2_URI 7
#define ZXID_OIDC1_CODE 8
#define ZXID_OIDC1_ID_TOK_TOK 9

/* Service enumerators */

#define ZXID_SLO_SVC 1
#define ZXID_MNI_SVC 2
#define ZXID_ACS_SVC 3

/* Broad categories of secmechs. Specific secmechs are mapped to these to abstract similarity. */

#define ZXID_SEC_MECH_NULL   1
#define ZXID_SEC_MECH_BEARER 2
#define ZXID_SEC_MECH_SAML   3
#define ZXID_SEC_MECH_X509   4
#define ZXID_SEC_MECH_PEERS  5

/* Common status codes: usually tested without comparison to constant, i.e.
 * return value of functions (which can only fail or succeed) is directly
 * used in conditional test. You will see base 0's and 1's in code.
 * Usually 1 means event was fully handled and no fall thru behaviour
 * is desired. 0 usually means the fall thru default should happen. */
#define ZXID_FAIL     0  /* Fall thru to default behaviour. */
#define ZXID_OK       1  /* Don't fall thru, event fully handled. */
#define ZXID_REDIR_OK 2  /* Don't fall thru, event fully handled. */
#define ZXID_SSO_OK   3  /* Special case for SSO completed situation. Use as switch case. */
#define ZXID_IDP_REQ  4  /* Used by SP dispatch to punt the message to IdP processing. */

#define COPYVAL(to,what,lim) MB (to) = ZX_ALLOC(cf->ctx, (lim)-(what)+1); memcpy((to), (what),  (lim)-(what)); (to)[(lim)-(what)] = 0; ME

ZXID_DECL char* sha1_safe_base64(char* out_buf, int len, const char* data);
ZXID_DECL char* zx_url_encode(struct zx_ctx* c, int in_len, const char* in, int* out_len);

#ifdef __cplusplus
} // extern "C"
#endif

#endif
