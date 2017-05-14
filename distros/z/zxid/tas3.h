/* tas3.h  --  TAS3.eu API Implementation Using ZXID.org
 *
 * Copyright (c) 2009-2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidwsc.c,v 1.14 2009-08-30 15:09:26 sampo Exp $
 *
 * To use this API you will need to link against libzxid.a (-lzxid), libzxid.so,
 * or libzxid.dll Since the API implementation happens at compile time, the link
 * time symbols will be the zxid variants. If desired, the tas3 variants will be
 * provided in libtas3.a, .so, .dll, but this library is waiting for practical
 * demand before being supplied.
 *
 * See also: tas3-proto.pd for the official, but not exclusive, TAS3 API definition.
 *
 * 13.10.2009,  created --Sampo
 */

#ifndef _TAS3_H
#define _TAS3_H 0x20091224  /* TAS3 API version. 20091224 corresponds to first issue of D2.4 */

#include <zx/zxid.h>

/* Map data types to TAS3 equivalents */

#define tas3_conf          zxid_conf
#define tas3_ses           zxid_ses
#define tas3_str           struct zx_str
#define tas3_epr           zxid_epr
#define tas3_status        zxid_tas3_status
#define tas3_fault         zxid_fault

/* Map ZXID functions to TAS3 equivalents */

#define tas3_new_conf_to_cf zxid_new_conf_to_cf
#define tas3_new_ses       zxid_alloc_ses
#define tas3_sso_cf        zxid_simple_cf
#define tas3_sso_cf_ses    zxid_simple_cf_ses
#define tas3_az            zxid_az
#define tas3_az_cf         zxid_az_cf
#define tas3_az_cf_ses     zxid_az_cf_ses
#define tas3_call          zxid_call
#define tas3_callf         zxid_callf
#define tas3_wsc_prepare_call zxid_wsc_prepare_call
#define tas3_wsc_prepare_callf zxid_wsc_prepare_callf
#define tas3_wsc_valid_resp zxid_wsc_valid_resp
#define tas3_get_epr       zxid_get_epr
#define tas3_get_epr_url   zxid_get_epr_address
#define tas3_get_epr_entid zxid_get_epr_entid
#define tas3_get_epr_a7n   zxid_get_epr_a7n
#define tas3_epr2str       zxid_epr2str
#define tas3_wsp_validate  zxid_wsp_validate
#define tas3_wsp_decorate  zxid_wsp_decorate
#define tas3_wsp_decoratef zxid_wsp_decoratef
#define tas3_set_delegated_discovery_epr zxid_set_delegated_discovery_epr

/* TAS3 constants */

#define TAS3_AUTO_EXIT     ZXID_AUTO_EXIT
#define TAS3_AUTO_REDIR    ZXID_AUTO_REDIR
#define TAS3_AUTO_SOAPC    ZXID_AUTO_SOAPC
#define TAS3_AUTO_SOAPH    ZXID_AUTO_SOAPH
#define TAS3_AUTO_METAC    ZXID_AUTO_METAC
#define TAS3_AUTO_METAH    ZXID_AUTO_METAH
#define TAS3_AUTO_LOGINC   ZXID_AUTO_LOGINC
#define TAS3_AUTO_LOGINH   ZXID_AUTO_LOGINH
#define TAS3_AUTO_MGMTC    ZXID_AUTO_MGMTC
#define TAS3_AUTO_MGMTH    ZXID_AUTO_MGMTH
#define TAS3_AUTO_FORMF    ZXID_AUTO_FORMF
#define TAS3_AUTO_FORMT    ZXID_AUTO_FORMT
#define TAS3_AUTO_ALL      ZXID_AUTO_ALL
#define TAS3_AUTO_DEBUG    ZXID_AUTO_DEBUG
#define TAS3_AUTO_OFMTQ    ZXID_AUTO_OFMTQ
#define TAS3_AUTO_OFMTJ    ZXID_AUTO_OFMTJ

/* Special discovery options and attribute names for Trust PDP interface. */

#define TAS3_TRUST_INPUT_CTL1   "urn:tas3:trust:input:ctl1:"
#define TAS3_TRUST_RANKING_CTL1 "urn:tas3:trust:ranking:ctl1:"

#endif
