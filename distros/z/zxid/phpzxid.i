/* phpzxid.i  -  SWIG interface file for PHP extension for libzxid
 * Copyright (c) 2006-2011 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: phpzxid.i,v 1.8 2009-11-29 12:23:06 sampo Exp $
 * 31.8.2006, created --Sampo
 * 31.1.2011, upgraded for php-5.3 support --Sampo
 */
%module "zxid"
%include "phppointers.i"
%include "typemaps.i"
%apply int *REF {int *res_len};

%wrapper %{
#define zend_error_noreturn zend_error
%}

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
  if ($1)
       ZVAL_STRINGL($result, $1->s, $1->len, 1);
  /* Do not free underlying zx_str because they are usually returned by reference. */
}

%include "zx.h"
%include "zxid.h"
%include "saml2.h"

/* EOF */
