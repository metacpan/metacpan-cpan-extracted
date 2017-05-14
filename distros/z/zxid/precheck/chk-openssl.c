/* precheck/chk-openssl.c  -  Check that OpenSSL include files and libraries are available
 * Copyright (c) 2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: chk-openssl.c,v 1.3 2009-10-18 12:39:10 sampo Exp $
 *
 * 16.9.2008, created --Sampo
 */

#include <openssl/x509.h>
#include <openssl/ssl.h>
#include <openssl/opensslv.h>
#include <openssl/crypto.h>
#include <openssl/err.h>

#include <stdio.h>

/* Called by: */
int main(int argc, char** argv)
{
  SSL_library_init();  /* in -lssl */
  ERR_clear_error();   /* in -lcrypto */
  printf("  -- OpenSSL version from opensslv.h: %s, crypto.h: %x\n",
	 OPENSSL_VERSION_TEXT, (unsigned int)SSLEAY_VERSION_NUMBER);
  printf("  -- from SSLeay_version(): %s\n", SSLeay_version(SSLEAY_VERSION));
  return 0;
}

/* EOF  --  chk-openssl.c */
