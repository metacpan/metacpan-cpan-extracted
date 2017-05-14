/* javazxid.i  -  SWIG interface file for Java JNI extension for libzxid
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: javazxid.i,v 1.10 2009-11-29 12:23:06 sampo Exp $
 * 7.1.2007, created --Sampo
 * 27.11.2009, tweaked zx_str typemap --Sampo
 *
 * See: http://java.sun.com/docs/books/jni/html/objtypes.html
 *      http://www.swig.org/Doc1.3/Java.html
 */
%module "zxidjni"
%{

#include "platform.h"
#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "saml2.h"

#include "c/zx-const.h"
#include "c/zx-data.h"
#include "c/zx-ns.h"
#include "c/zxidvers.h"

%}

/* N.B. Contrary to the documentation the type field in all of the following four maps
 * must match the original, i.e. struct zx_str*, rather than one of the intermediary
 * types (errornously documented in SWIG documentation that way). */
%typemap (jni)     struct zx_str* "jstring"             // Affects zxid_wrap.c
%typemap (jtype)   struct zx_str* "String"              // Affects zxidjniJNI.java
%typemap (jstype)  struct zx_str* "String"              // Affects zxidjni.java
%typemap (javaout) struct zx_str* { return $jnicall; }  // Affects zxidjni.java body
%typemap (javain)  struct zx_str* "$javainput"          // Affects setter body

%typemap (out) struct zx_str* {
  // Unfortunately Java does not provide NewStringUTF() that would explicitly
  // take length field - they insist on nul termination instead. Sigh.
  if ($1 && $1->s) {
    char* tmp = malloc($1->len + 1);
    if (!tmp) { ERR("Out of memory len=%d", $1->len); return $null; }
    memcpy(tmp, $1->s, $1->len);
    tmp[$1->len] = 0;
    $result = (*jenv)->NewStringUTF(jenv, tmp);
    free(tmp);
    // Do not free underlying zx_str because they are usually returned by reference.
  } else {
    $result = 0;
  }
}

%typemap (in) (int len, char* s) %{
  // The following jstring casts could probably be avoided with proper use of typemaps
  $1 = (*jenv)->GetStringUTFLength(jenv, (jstring)$input);
  $2 = (char*)(*jenv)->GetStringUTFChars(jenv, (jstring)$input, 0);
  // *** Whether we can free, or not, the obtained string depends
  //     on whether the zxid API will take reference to the string.
%}
%typemap (freearg) (int len, char* s) "(*jenv)->ReleaseStringUTFChars(jenv, (jstring)$input, $2);"

%typemap (in) (int len, const char* s) %{
  // The following jstring casts could probably be avoided with proper use of typemaps
  $1 = (*jenv)->GetStringUTFLength(jenv, (jstring)$input);
  $2 = (char*)(*jenv)->GetStringUTFChars(jenv, (jstring)$input, 0);
  // *** Whether we can free, or not, the obtained string depends
  //     on whether the zxid API will take reference to the const string.
%}
%typemap (freearg) (int len, const char* s) "(*jenv)->ReleaseStringUTFChars(jenv, (jstring)$input, $2);"

//#define ZXID_FIX_SWIGJAVA 1

%include "zx.h"
%include "zxid.h"
%include "saml2.h"
%include "wsf.h"
%include "c/zxidvers.h"
%include "c/zx-ns.h"

/*

Trying to process all of the below hits a Java class file format limitation
"too many constants", manifesting as error message like

/apps/java/j2sdk1.4.2/bin/javac -J-Xmx128m -g zxid.java zxidjava/*.java
zxidjava/zxidjni.java:11: too many constants
public class zxidjni implements zxidjniConstants {
       ^
Note: zxid.java uses or overrides a deprecated API.
Note: Recompile with -deprecation for details.
1 error
make: *** [zxid.class] Error 1

If you know how to get around that, please let me know.

%include "c/zx-a-data.h"
%include "c/zx-ac-data.h"
%include "c/zx-b-data.h"
%include "c/zx-b12-data.h"
%include "c/zx-const.h"
%include "c/zx-data.h"
%include "c/zx-di-data.h"
%include "c/zx-di12-data.h"
%include "c/zx-ds-data.h"
%include "c/zx-e-data.h"
%include "c/zx-ff12-data.h"
%include "c/zx-is-data.h"
%include "c/zx-is12-data.h"
%include "c/zx-lu-data.h"
%include "c/zx-m20-data.h"
%include "c/zx-md-data.h"
%include "c/zx-sa-data.h"
%include "c/zx-sa11-data.h"
%include "c/zx-sbf-data.h"
%include "c/zx-sec-data.h"
%include "c/zx-sec12-data.h"
%include "c/zx-sp-data.h"
%include "c/zx-sp11-data.h"
%include "c/zx-wsse-data.h"
%include "c/zx-wsu-data.h"
%include "c/zx-xenc-data.h"
%include "c/zx-xml-data.h"
%include "c/zx-xs-data.h"
%include "c/zx-paos-data.h"
%include "c/zx-ecp-data.h"
%include "c/zx-dap-data.h"
%include "c/zx-ps-data.h"
%include "c/zx-im-data.h"
%include "c/zx-as-data.h"
%include "c/zx-dst-data.h"
%include "c/zx-subs-data.h"
*/

/* EOF */
