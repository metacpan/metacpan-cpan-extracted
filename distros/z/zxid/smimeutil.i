/* smimeutil.i  -  SWIG (http://www.swig.org/) interface definition to
 *                 produce perl module for smime tool.
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 *
 * 7.10.1999, created --Sampo
 * 17.10.1999, renamed from SMIME to SMIMEUtil --Sampo
 */

%module SMIMEUtil

%{
#include <stdio.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/evp.h>
#include <openssl/pkcs12.h>
%}

/*%include typemaps.i
  %apply unsigned char *REFERENCE { char** };*/

%typemap(perl5,ignore) char** (char* junk) {
	$target = &junk;
}
%typemap(perl5,argout) char** {
   	$target = sv_newmortal();
	sv_setpv($target, *$source);
	argvi++;
}

%include "smimeutil.h"

/* We need ability to get rid of following objects */

void X509_free(X509 *x509);
void X509_REQ_free(X509_REQ *req);
void EVP_PKEY_free(EVP_PKEY *pkey);
void PKCS12_free(PKCS12* p12);

/* EOF */