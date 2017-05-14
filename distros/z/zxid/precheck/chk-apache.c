/* precheck/chk-apache.c  -  Check that Apache and APR include files and libraries are available
 * Copyright (c) 2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: chk-apache.c,v 1.3 2008-09-18 20:27:23 sampo Exp $
 *
 * 16.9.2008, created --Sampo
 *
 * sudo apt-get install libapr1-dev
 * sudo apt-get install apache2-dev
 */

/* In apr.h off64_t is used, but getting it properly defined seems
 * to be difficult, hence the kludges below. Note that zxid itself
 * does not use any functionality tainted by this problem so we
 * consider it to be ok to ignore the problem. We only need to
 * include those files to get the version information. */

#if 1
#include <sys/types.h>
#if !defined(__off64_t_defined) && !defined(off64_t)
/*typedef long long off64_t;*/
#define off64_t long long
#endif
#else
#define _LARGE_FILES 1
#define __USE_LARGEFILE64 1
#include <sys/types.h>
#endif

#include "ap_config.h"
#include "ap_release.h"
#include "apr_strings.h"
#include "apr_version.h"

#include <stdio.h>

/* Called by: */
int main(int argc, char** argv)
{
  printf("  -- Apache release from header: %d.%d.%d%s\n", AP_SERVER_MAJORVERSION_NUMBER,
	 AP_SERVER_MINORVERSION_NUMBER, AP_SERVER_PATCHLEVEL_NUMBER, AP_SERVER_ADD_STRING);
  printf("  -- APR version from header: %s\n", APR_VERSION_STRING);
  return 0;
}

/* EOF  --  chk-apache.c */
