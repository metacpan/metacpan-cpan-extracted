/* precheck/chk-zlib.c  -  Check that Zlib include files and libraries are available
 * Copyright (c) 2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: chk-zlib.c,v 1.1 2008-09-17 03:41:11 sampo Exp $
 *
 * 16.9.2008, created --Sampo
 */

#include <zlib.h>

#include <stdio.h>

/* Called by: */
int main(int argc, char** argv)
{
  printf("  -- zlib version from header: %s\n", ZLIB_VERSION);
  printf("  -- from zlibVersion(): %s\n", zlibVersion());
  return 0;
}

/* EOF  --  chk-zlib.c */
