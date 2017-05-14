/* rubyzxid.i  -  SWIG interface file for Ruby extension for libzxid
 * Copyright (c) 2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: rubyzxid.i,v 1.1 2008-05-08 02:02:40 sampo Exp $
 * 7.5.2008, created --Sampo
 */
%module "zxid"
%{

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "saml2.h"

#include "c/zx-const.h"
#include "c/zx-data.h"
#include "c/zx-ns.h"
#include "c/zxidvers.h"

%}

%typemap (in) (int len, char* s) {
  $1 = Z_STRLEN_PP($input);
  $2 = Z_STRVAL_PP($input);
}

//%typemap (in) struct zx_str* {
//  $1 = zx_str_dup_len_str(c/* *** where from ctx? */, Z_STRLEN_PP($input), Z_STRVAL_PP($input));
//}

%typemap (out) struct zx_str* {
  ZVAL_STRINGL($result, $1->s, $1->len, 1);
  /* Do not free underlying zx_str because they are usually returned by reference. */
}

%include "zx.h"
%include "zxid.h"
%include "saml2.h"

/* EOF */
