/* zxidpriv.h  -  Private API functions
 * Copyright (c) 2009-2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxid.h,v 1.94 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.8.2006,  created --Sampo
 * 31.5.2010,  eliminated many include dependencies from the public API --Sampo
 * 13.11.2010, added ZXID_DECL for benefit of the Windows port --Sampo
 * 12.12.2010, separate zxidpriv.h and zxidutil.h from zxid.h --Sampo
 */

#ifndef _zxidpriv_h
#define _zxidpriv_h

#include <memory.h>
#include <string.h>
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
#include <zx/c/zx-data.h>  /* Generated. If missing, run `make dep ENA_GEN=1' */
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
struct zx_a_Address_s;
struct zx_a_Metadata_s;
struct zx_sa_EncryptedAssertion_s;
struct zx_sa_Assertion_s;
struct zx_sa_NameID_s;
struct zx_sa_Issuer_s;
struct zx_sa_Attribute_s;
struct zx_sa_EncryptedID_s;
struct zx_sa_Subject_s;
struct zx_sa_AuthnStatement_s;
struct zx_sa_AttributeStatement_s;
struct zx_sec_Token_s;
struct zx_sp_Response_s;
struct zx_sp_Status_s;
struct zx_sp_NewEncryptedID_s;
struct zx_sp_AuthnRequest_s;
struct zx_sp_ArtifactResolve_s;
struct zx_sp_LogoutRequest_s;
struct zx_sp_LogoutResponse_s;
struct zx_sp_ManageNameIDRequest_s;
struct zx_sp_ManageNameIDResponse_s;
struct zx_sp_NameIDMappingRequest_s;
struct zx_sp_NameIDMappingResponse_s;
struct zx_sa11_Assertion_s;
struct zx_sa11_Assertion_s;
struct zx_ff12_Assertion_s;
struct zx_ff12_Assertion_s;
struct zx_ds_Signature_s;
struct zx_ds_Reference_s;
struct zx_ds_KeyInfo_s;
struct zx_xenc_EncryptedData_s;
struct zx_xenc_EncryptedKey_s;
struct zx_md_KeyDescriptor_s;
struct zx_md_ArtifactResolutionService_s;
struct zx_md_SingleSignOnService_s;
struct zx_md_SingleLogoutService_s;
struct zx_md_ManageNameIDService_s;
struct zx_md_AssertionConsumerService_s;
struct zx_md_IDPSSODescriptor_s;
struct zx_md_SPSSODescriptor_s;
struct zx_md_EntityDescriptor_s;
struct zx_xasa_XACMLAuthzDecisionStatement_s;
struct zx_xac_Response_s;
struct zx_xac_Attribute_s;
struct zx_xasp_XACMLAuthzDecisionQuery_s;
struct zx_xaspcd1_XACMLAuthzDecisionQuery_s;
struct zx_as_SASLRequest_s;
struct zx_di_Query_s;
struct zx_di_QueryResponse_s;
struct zx_im_IdentityMappingRequest_s;
struct zx_im_IdentityMappingResponse_s;
struct zx_ps_AddEntityRequest_s;
struct zx_ps_AddEntityResponse_s;
struct zx_ps_ResolveIdentifierRequest_s;
struct zx_ps_ResolveIdentifierResponse_s;
struct zx_lu_Status_s;
struct zx_wsu_Timestamp_s;
struct zx_wsse_Security_s;
struct zx_wsse_SecurityTokenReference_s;
struct zx_dap_Select_s;
struct zx_dap_QueryItem_s;
struct zx_dap_TestOp_s;
struct zx_dap_TestItem_s;
struct zx_dap_ResultQuery_s;
struct zx_dap_Subscription_s;
struct zx_dap_Query_s;
#endif

/* zxidsimp */

ZXID_DECL int zxid_decode_ssoreq(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL char* zxid_simple_show_page(zxid_conf* cf, struct zx_str* ss, int c_mask, int h_mask, char* rets, char* cont_type, int* res_len, int auto_flags, const char* status);
ZXID_DECL char* zxid_simple_show_json(zxid_conf* cf, const char* json, int* res_len, int auto_flags, const char* status);

/* zxidmeta */

#ifdef USE_OPENSSL
ZXID_DECL struct zx_ds_KeyInfo_s* zxid_key_info(zxid_conf* cf, struct zx_elem_s* father, X509* x);
ZXID_DECL struct zx_md_KeyDescriptor_s* zxid_key_desc(zxid_conf* cf, struct zx_elem_s* father, char* use, X509* cert);
#endif
ZXID_DECL struct zx_md_ArtifactResolutionService_s* zxid_ar_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc);
ZXID_DECL struct zx_md_SingleSignOnService_s* zxid_sso_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc);
ZXID_DECL struct zx_md_SingleLogoutService_s* zxid_slo_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc);
ZXID_DECL struct zx_md_ManageNameIDService_s* zxid_mni_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* resp_loc);
ZXID_DECL struct zx_md_AssertionConsumerService_s* zxid_ac_desc(zxid_conf* cf, struct zx_elem_s* father, char* binding, char* loc, char* index);
ZXID_DECL struct zx_md_IDPSSODescriptor_s* zxid_idp_sso_desc(zxid_conf* cf, struct zx_elem_s* father);
ZXID_DECL struct zx_md_SPSSODescriptor_s* zxid_sp_sso_desc(zxid_conf* cf, struct zx_elem_s* father);

/* zxidconf */

ZXID_DECL struct zxid_map*   zxid_load_map(zxid_conf* cf, struct zxid_map* map, char* v);
ZXID_DECL void zxid_free_map(struct zxid_conf *cf, struct zxid_map *map);
ZXID_DECL struct zxid_map*   zxid_load_unix_grp_az_map(zxid_conf* cf, struct zxid_map* map, char* v);
ZXID_DECL struct zxid_need*  zxid_is_needed(struct zxid_need* need, const char* name);
ZXID_DECL struct zxid_map*   zxid_find_map(struct zxid_map* map, const char* name);
ZXID_DECL int zxid_unix_grp_az_check(zxid_conf* cf, zxid_ses* ses, int gid);
ZXID_DECL struct zxid_cstr_list* zxid_load_cstr_list(zxid_conf* cf, struct zxid_cstr_list* l, char* p);
ZXID_DECL void zxid_free_cstr_list(struct zxid_conf *cf, struct zxid_cstr_list *l);
ZXID_DECL struct zxid_cstr_list* zxid_find_cstr_list(struct zxid_cstr_list* lst, const char* name);
ZXID_DECL struct zxid_cstr_list* zxid_find_at_multival_on_cstr_list(struct zxid_cstr_list* cs, struct zxid_attr* at);
ZXID_DECL struct zxid_attr*  zxid_find_at(struct zxid_attr* pool, const char* name);
ZXID_DECL struct zxid_attr*  zxid_new_at(zxid_conf* cf, struct zxid_attr* at, int name_len, char* name, int val_len, char* val, char* lk);
ZXID_DECL void zxid_free_at(struct zxid_conf *cf, struct zxid_attr *attr);
ZXID_DECL char* zxid_grab_domain_name(zxid_conf* cf, const char* url);
ZXID_DECL struct zxid_need* zxid_load_need(zxid_conf* cf, struct zxid_need* need, char* v);
ZXID_DECL void zxid_free_need(struct zxid_conf *cf, struct zxid_need *need);
ZXID_DECL struct zxid_atsrc* zxid_load_atsrc(zxid_conf* cf, struct zxid_atsrc* atsrc, char* v);
ZXID_DECL void zxid_free_atsrc(struct zxid_conf *cf, struct zxid_atsrc *src);
ZXID_DECL struct zxid_obl_list* zxid_load_obl_list(zxid_conf* cf, struct zxid_obl_list* ol, char* obl);
ZXID_DECL void zxid_free_obl_list(struct zxid_conf* cf, struct zxid_obl_list* ol);
ZXID_DECL struct zxid_obl_list* zxid_find_obl_list(struct zxid_obl_list* obl, const char* name);
ZXID_DECL char* zxid_mk_jwks(zxid_conf* cf);
ZXID_DECL char* zxid_read_cert_pem(zxid_conf* cf, char* name, int siz, char* buf);

/* zxiduser */

ZXID_DECL zxid_nid* zxid_parse_mni(zxid_conf* cf, char* buf, char** pmniptr);

/* zxidlib */

ZXID_DECL struct zx_str* zxid_lecp_check(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL struct zx_str* zxid_cdc_read(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL int zxid_cdc_check(zxid_conf* cf, zxid_cgi* cgi);

ZXID_DECL int zxid_chk_sig(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_elem_s* elem, struct zx_ds_Signature_s* sig, struct zx_sa_Issuer_s* issue_ent, struct zx_ns_s* pop_seen, const char* lk);

ZXID_DECL struct zx_str* zxid_map_val_ss(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, struct zxid_map* map, const char* atname, struct zx_str* val);
ZXID_DECL struct zx_str* zxid_map_val(zxid_conf* cf, zxid_ses* ses, zxid_entity* meta, struct zxid_map* map, const char* atname, const char* val);

ZXID_DECL struct zx_str* zxid_get_affil_and_sp_name_buf(zxid_conf* cf, zxid_entity* meta, char* sp_name_buf);
ZXID_DECL zxid_nid* zxid_get_fed_nameid(zxid_conf* cf, struct zx_str* prvid, struct zx_str* affil, const char* uid, const char* sp_name_buf, int allow_create, int want_transient, struct timeval* srcts, struct zx_str* id, char* logop);

/* zxidloc */

ZXID_DECL struct zx_str* zxid_idp_loc_raw(zxid_conf* cf, zxid_cgi* cgi, zxid_entity* idp_meta, int svc_type, char* binding, int req);
ZXID_DECL struct zx_str* zxid_idp_loc(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_entity* idp_meta, int svc_type, char* binding);

ZXID_DECL struct zx_str* zxid_sp_loc_by_index_raw(zxid_conf* cf, zxid_cgi* cgi, zxid_entity* sp_meta, int svc_type,struct zx_str* ix, int* binding);
ZXID_DECL struct zx_str* zxid_sp_loc_raw(zxid_conf* cf, zxid_cgi* cgi, zxid_entity* sp_meta, int svc_type, char* binding, int req);
ZXID_DECL struct zx_str* zxid_sp_loc(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_entity* sp_meta, int svc_type, char* binding);

/* zxidspx */

ZXID_DECL zxid_a7n* zxid_dec_a7n(zxid_conf* cf, zxid_a7n* a7n, struct zx_sa_EncryptedAssertion_s* enca7n);
ZXID_DECL struct zx_str* zxid_sp_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);
ZXID_DECL int zxid_sp_soap_parse(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int len, char* buf);
ZXID_DECL int zxid_sp_soap_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_root_s* r);

/* zxididpx */

ZXID_DECL struct zx_str* zxid_idp_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int chk_dup);

/* zxidpsso - IdP side of SSO: generating A7N */

ZXID_DECL void zxid_mk_transient_nid(zxid_conf* cf, zxid_nid* nameid, const char* sp_name_buf, const char* uid);
ZXID_DECL int zxid_anoint_a7n(zxid_conf* cf, int sign, zxid_a7n* a7n, struct zx_str* issued_to, const char* lk, const char* uid, struct zx_str** ret_logpath);
ZXID_DECL struct zx_str* zxid_anoint_sso_resp(zxid_conf* cf, int sign, struct zx_sp_Response_s* resp, struct zx_sp_AuthnRequest_s* ar);
ZXID_DECL zxid_a7n* zxid_sso_issue_a7n(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct timeval* srcts, zxid_entity* sp_meta, struct zx_str* acsurl, zxid_nid** nameid, char* logop, struct zx_sp_AuthnRequest_s* ar);
ZXID_DECL void zxid_gen_boots(zxid_conf* cf, zxid_ses* ses, struct zx_sa_AttributeStatement_s* father, char* path, int add_bs_lvl);
ZXID_DECL zxid_a7n* zxid_mk_usr_a7n_to_sp(zxid_conf* cf, zxid_ses* ses, zxid_nid* nameid, zxid_entity* sp_meta, const char* sp_name_buf, int add_bs_lvl);
ZXID_DECL zxid_nid* zxid_check_fed(zxid_conf* cf, struct zx_str* affil, const char* uid, char allow_create, struct timeval* srcts, struct zx_str* issuer, struct zx_str* req_id, const char* sp_name_buf);
ZXID_DECL int zxid_add_fed_tok2epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, int add_bs_lvl, char* logop);
ZXID_DECL struct zx_str* zxid_idp_sso(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_AuthnRequest_s* ar);
ZXID_DECL struct zx_as_SASLResponse_s* zxid_idp_as_do(zxid_conf* cf, struct zx_as_SASLRequest_s* req);

/* zxidsso - SP side of SSO: consuming A7N */

ZXID_DECL int zxid_pick_sso_profile(zxid_conf* cf, zxid_cgi* cgi, zxid_entity* idp_met);
ZXID_DECL void zxid_sso_set_relay_state_to_return_to_this_url(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL struct zx_str* zxid_start_sso_location(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL int zxid_sp_sso_finalize(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_a7n* a7n, struct zx_ns_s* pop_seen);
ZXID_DECL int zxid_sp_anon_finalize(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);

ZXID_DECL int zxid_validate_cond(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, zxid_a7n* a7n, struct zx_str* myentid, struct timeval* ourts, char** err);

/* zxidslo */

ZXID_DECL struct zx_str* zxid_slo_resp_redir(zxid_conf* cf, zxid_cgi* cgi, struct zx_sp_LogoutRequest_s* req);
ZXID_DECL int zxid_sp_slo_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_LogoutRequest_s* req);
ZXID_DECL int zxid_idp_slo_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_LogoutRequest_s* req);

/* zxidmni */

ZXID_DECL struct zx_sp_ManageNameIDResponse_s* zxid_mni_do(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_ManageNameIDRequest_s* mni);
ZXID_DECL struct zx_str* zxid_mni_do_ss(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, struct zx_sp_ManageNameIDRequest_s* mni, struct zx_str* loc);

/* zxidpep */

ZXID_DECL char* zxid_pep_az_soap_pepmap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url, struct zxid_map* pepmap, const char* lk);
ZXID_DECL char* zxid_pep_az_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url);

ZXID_DECL char* zxid_pep_az_base_soap_pepmap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url, struct zxid_map* pepmap);
ZXID_DECL char* zxid_pep_az_base_soap(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, const char* pdp_url);

/* zxidpdp */

ZXID_DECL int zxid_localpdp(zxid_conf* cf, zxid_ses* ses);
ZXID_DECL char* zxid_simple_ab_pep(zxid_conf* cf, zxid_ses* ses, int* res_len, int auto_flags);

/* zxidmk */

ZXID_DECL struct zx_sp_AuthnRequest_s* zxid_mk_authn_req(zxid_conf* cf, zxid_cgi* cgi);
ZXID_DECL struct zx_sp_ArtifactResolve_s* zxid_mk_art_deref(zxid_conf* cf, struct zx_elem_s* father, zxid_entity* idp_meta, const char* artifact);

ZXID_DECL struct zx_sa_EncryptedID_s* zxid_mk_enc_id(zxid_conf* cf, struct zx_elem_s* father, zxid_nid* nid, zxid_entity* meta);
ZXID_DECL struct zx_sa_EncryptedAssertion_s* zxid_mk_enc_a7n(zxid_conf* cf, struct zx_elem_s* father, zxid_a7n* a7n, zxid_entity* meta);

ZXID_DECL struct zx_sp_LogoutRequest_s* zxid_mk_logout(zxid_conf* cf, zxid_nid* nid, struct zx_str* ses_ix, zxid_entity* idp);
ZXID_DECL struct zx_sp_LogoutResponse_s* zxid_mk_logout_resp(zxid_conf* cf, struct zx_sp_Status_s* st, struct zx_str* req_id);
ZXID_DECL struct zx_sp_ManageNameIDRequest_s* zxid_mk_mni(zxid_conf* cf, zxid_nid* nid, struct zx_str* new_nym, zxid_entity* idp);
ZXID_DECL struct zx_sp_ManageNameIDResponse_s* zxid_mk_mni_resp(zxid_conf* cf, struct zx_sp_Status_s* st, struct zx_str* req_id);

ZXID_DECL zxid_a7n* zxid_mk_a7n(zxid_conf* cf, struct zx_str* audience, struct zx_sa_Subject_s* subj, struct zx_sa_AuthnStatement_s* an_stmt, struct zx_sa_AttributeStatement_s* at_stmt);
ZXID_DECL struct zx_sa_Subject_s* zxid_mk_subj(zxid_conf* cf, struct zx_elem_s* father, zxid_entity* sp_meta, zxid_nid* nid);
ZXID_DECL struct zx_sa_AuthnStatement_s* zxid_mk_an_stmt(zxid_conf* cf, zxid_ses* ses, struct zx_elem_s* father, const char* eid);
ZXID_DECL struct zx_sp_Response_s* zxid_mk_saml_resp(zxid_conf* cf, zxid_a7n* a7n, zxid_entity* enc_meta);
ZXID_DECL struct zx_xac_Response_s* zxid_mk_xacml_resp(zxid_conf* cf, char* decision);
ZXID_DECL struct zx_xac_Attribute_s* zxid_mk_xacml_simple_at(zxid_conf* cf, struct zx_elem_s* father, struct zx_str* atid, struct zx_str* attype, struct zx_str* atissuer, struct zx_str* atvalue);
ZXID_DECL struct zx_xac_Request_s* zxid_mk_xac_az(zxid_conf* cf, struct zx_elem_s* father, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* env);
ZXID_DECL struct zx_xasp_XACMLAuthzDecisionQuery_s* zxid_mk_az(zxid_conf* cf, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* env);
ZXID_DECL struct zx_xaspcd1_XACMLAuthzDecisionQuery_s* zxid_mk_az_cd1(zxid_conf* cf, struct zx_xac_Attribute_s* subj, struct zx_xac_Attribute_s* rsrc, struct zx_xac_Attribute_s* act, struct zx_xac_Attribute_s* env);
ZXID_DECL struct zx_sa_Attribute_s* zxid_mk_sa_attribute_ss(zxid_conf* cf, struct zx_elem_s* father, const char* name, const char* namfmt, struct zx_str* val);
ZXID_DECL struct zx_sa_Attribute_s* zxid_mk_sa_attribute(zxid_conf* cf, struct zx_elem_s* father, const char* name, const char* namfmt, const char* val);

/* zxidoauth */

ZXID_DECL struct zx_str* zxid_sp_oauth2_dispatch(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);
ZXID_DECL char* zxid_idp_oauth2_token_and_check_id(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses, int* res_len, int auto_flags);
ZXID_DECL struct zx_str* zxid_oauth2_az_server_sso(zxid_conf* cf, zxid_cgi* cgi, zxid_ses* ses);

/* zxidmkwsf */

ZXID_DECL struct zx_di_Query_s* zxid_mk_di_query(zxid_conf* cf, struct zx_elem_s* father, const char* svc_type, const char* url, const char* di_opt, const char* action);
ZXID_DECL struct zx_a_Address_s* zxid_mk_addr(zxid_conf* cf, struct zx_elem_s* father, struct zx_str* url);

ZXID_DECL struct zx_dap_Select_s* zxid_mk_dap_select(zxid_conf* cf, struct zx_elem_s* father, char* dn, char* filter, char* attributes, int deref_aliases, int scope, int sizelimit, int timelimit, int typesonly);
ZXID_DECL struct zx_dap_QueryItem_s* zxid_mk_dap_query_item(zxid_conf* cf, struct zx_elem_s* father, struct zx_dap_Select_s* sel, char* objtype, char* predef, char* sort, char* changed_since, int incl_common_attrs, int offset, int count, char* setreq, char* setid, char* contingent_itemidref);
ZXID_DECL struct zx_dap_TestOp_s* zxid_mk_dap_testop(zxid_conf* cf, struct zx_elem_s* father, char* dn, char* filter, char* attributes, int deref_aliases, int scope, int sizelimit, int timelimit, int typesonly);
ZXID_DECL struct zx_dap_TestItem_s* zxid_mk_dap_test_item(zxid_conf* cf, struct zx_elem_s* father, struct zx_dap_TestOp_s* top, char* objtype, char* predef);
ZXID_DECL struct zx_dap_ResultQuery_s* zxid_mk_dap_resquery(zxid_conf* cf, struct zx_elem_s* father, struct zx_dap_Select_s* sel, char* objtype, char* predef, char* sort, char* changed_since, int incl_common_attr, char* contingent_itemidref);
ZXID_DECL struct zx_dap_Subscription_s* zxid_mk_dap_subscription(zxid_conf* cf, struct zx_elem_s* father, char* subsID, char* itemidref, struct zx_dap_ResultQuery_s* rq, char* aggreg, char* trig, char* starts, char* expires, int incl_data, char* admin_notif, char* notify_ref);
ZXID_DECL struct zx_dap_Query_s* zxid_mk_dap_query(zxid_conf* cf, struct zx_elem_s* father, struct zx_dap_TestItem_s* tis, struct zx_dap_QueryItem_s* qis, struct zx_dap_Subscription_s* subs);

/* zxidwsf */

#define ZXID_N_WSF_SIGNED_HEADERS 40  /* Max number of signed SOAP headers. */

ZXID_DECL int zxid_hunt_sig_parts(zxid_conf* cf, int n_refs, struct zxsig_ref* refs, struct zx_ds_Reference_s* sref, struct zx_e_Header_s* hdr, struct zx_e_Body_s* bdy);
ZXID_DECL int zxid_add_header_refs(zxid_conf* cf, int n_refs, struct zxsig_ref* refs, struct zx_e_Header_s* hdr);
ZXID_DECL void zxid_wsf_sign(zxid_conf* cf, int sign_flags, struct zx_wsse_Security_s* sec, struct zx_wsse_SecurityTokenReference_s* str, struct zx_e_Header_s* hdr, struct zx_e_Body_s* bdy);
ZXID_DECL int zxid_timestamp_chk(zxid_conf* cf, zxid_ses* ses, struct zx_wsu_Timestamp_s* ts, struct timeval* ourts, struct timeval* srcts, const char* ctlpt, const char* faultactor);
ZXID_DECL void zxid_attach_sol1_usage_directive(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env, const char* attrid, const char* obl);
ZXID_DECL void zxid_add_action_from_body_child(zxid_conf* cf, zxid_ses* ses, struct zx_e_Envelope_s* env);
ZXID_DECL int zxid_query_ctlpt_pdp(zxid_conf* cf, zxid_ses* ses, const char* az_cred, struct zx_e_Envelope_s* env, const char* ctlpt, const char* faultparty, struct zxid_map* pepmap);
ZXID_DECL int zxid_eval_sol1(zxid_conf* cf, zxid_ses* ses, const char* obl, struct zxid_obl_list* req);

/* zxidwsc */

ZXID_DECL struct zx_e_Envelope_s* zxid_add_env_if_needed(zxid_conf* cf, const char* enve);
ZXID_DECL struct zx_e_Envelope_s* zxid_wsc_call(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, struct zx_e_Envelope_s* env, char** ret_enve);

/* zxidepr */

ZXID_DECL int  zxid_cache_epr(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr, int rank);
ZXID_DECL void zxid_snarf_eprs(zxid_conf* cf, zxid_ses* ses, zxid_epr* epr);
ZXID_DECL void zxid_snarf_eprs_from_ses(zxid_conf* cf, zxid_ses* ses);

/* zxiddi -  Discovery Service */

ZXID_DECL int zxid_idp_map_nid2uid(zxid_conf* cf, int len, char* uid, zxid_nid* nameid, struct zx_lu_Status_s** stp);

ZXID_DECL void zxid_di_set_rankKey_if_needed(zxid_conf* cf, struct zx_a_Metadata_s* md, int nth, struct dirent* de);

ZXID_DECL zxid_epr* zxid_di_sort_eprs(zxid_conf* cf, zxid_epr* epr);

ZXID_DECL struct zx_di_QueryResponse_s* zxid_di_query(zxid_conf* cf, zxid_ses* ses, struct zx_di_Query_s* req);

/* zxidim -  Identity Mapping Service, Single Sign-On Service (SSOS) */

ZXID_DECL struct zx_sp_Response_s* zxid_ssos_anreq(zxid_conf* cf, zxid_ses* ses, struct zx_sp_AuthnRequest_s* req);
ZXID_DECL struct zx_im_IdentityMappingResponse_s* zxid_imreq(zxid_conf* cf, zxid_ses* ses, struct zx_im_IdentityMappingRequest_s* req);

ZXID_DECL struct zx_sp_NameIDMappingResponse_s* zxid_nidmap_do(zxid_conf* cf, struct zx_sp_NameIDMappingRequest_s* req);

/* zxidps -  People Service (and delegation) */

ZXID_DECL struct zx_str* zxid_psobj_enc(zxid_conf* cf, struct zx_str* eid, const char* prefix, struct zx_str* psobj);
ZXID_DECL struct zx_str* zxid_psobj_dec(zxid_conf* cf, struct zx_str* eid, const char* prefix, struct zx_str* psobj);

ZXID_DECL struct zx_ps_AddEntityResponse_s* zxid_ps_addent_invite(zxid_conf* cf, zxid_ses* ses, struct zx_ps_AddEntityRequest_s* req);
ZXID_DECL struct zx_ps_ResolveIdentifierResponse_s* zxid_ps_resolv_id(zxid_conf* cf, zxid_ses* ses, struct zx_ps_ResolveIdentifierRequest_s* req);

/* zxidmda - Metadata authority */

ZXID_DECL char* zxid_simple_md_authority(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags);

/* zxidcurl */

ZXID_DECL const char* zxid_locate_soap_Envelope(const char* haystack);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* _zxidpriv_h */
