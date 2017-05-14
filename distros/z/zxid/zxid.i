/* zxid.i  -  SWIG interface file
 * Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxid.i,v 1.9 2009-08-30 15:09:26 sampo Exp $
 * 31.8.2006, created --Sampo
 */
%module "Net::SAML"
%{

#define USE_OPENSSL
#define USE_CURL

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "saml2.h"

#include "c/zx-const.h"
#include "c/zx-data.h"
#include "c/zx-ns.h"
#include "c/zxidvers.h"

//#include <stdbool.h>  *** how to solve problems with bool on perl 5.20?

%}

%typemap (in) (int len, char* s) {
  $2 = SvPV($input, $1);
}

//%typemap (in) struct zx_str* {
//  int len;
//  char* s;
//  s = SvPV($input, len);
//  $1 = zx_str_dup_len_str(c/* *** where from ctx? */, len, s);
//}

%typemap (out) struct zx_str* {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  $result = $1?newSVpv($1->s, $1->len):&PL_sv_undef;  /* newSV(0) */
  /* Do not free underlying zx_str because they are usually returned by reference. */
  ++argvi;
}

%include "zx.h"
%include "zxid.h"
%include "saml2.h"

/* EOF */
