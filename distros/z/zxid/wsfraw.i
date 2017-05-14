/* wsfraw.i  -  SWIG interface file for WSF low level functions
 * Copyright (c) 2006 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: wsfraw.i,v 1.5 2009-08-30 15:09:26 sampo Exp $
 * 14.9.2006, created --Sampo
 */
%module "Net::WSF::Raw"
%{

#define USE_OPENSSL
#define USE_CURL

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "saml2.h"

#include "c/wsf-const.h"
#include "c/wsf-data.h"
#include "c/wsf-ns.h"

char* instance = "zxwsfraw module";
char* assert_msg = "An assert happened in zxwsfraw module.";
int assert_nonfatal = 0;
int debug = 0;
int trace = 0;

%}

%rename(use_is_perl_keyword) use;

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
  $result = newSVpv($1->s, $1->len);
  /* Do not free underlying zx_str because they are usually returned by reference. */
  ++argvi;
}

%include "c/wsf-const.h"
%include "c/wsf-data.h"
%include "c/wsf-ns.h"

/* EOF */
