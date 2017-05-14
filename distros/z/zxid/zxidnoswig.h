/* zxidnoswig.h  -  Prototypes that give indigestion to SWIG
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidnoswig.h,v 1.2 2007-10-12 13:51:47 sampo Exp $
 *
 * 3.10.2007, created --Sampo
 *
 * At least on Redhat (unknown version, but current as of 2007) there
 * is mysterious problem that causes compilation error in SWIG generated
 * code. The problem appears to be related to the way Redhat has configured
 * their gcc or header files to implement va_list. SWIG assumes va_list is
 * a pointer, but this is strictly speaking not a valid assumption according
 * to K&R and the assumption seems to break on Redhat. Symptom is
 * "incompatibe types in assignment" error message in SAML_wrap.c
 *
 * Since there is little, if any, value on providing the va_list APIs to
 * scripting languages, we sidestep the problem by segregating these
 * problematic APIs here.
 */

#ifndef _zxidnoswig_h
#define _zxidnoswig_h

extern const char std_basis_64[64];
extern const char safe_basis_64[64];
extern const unsigned char zx_std_index_64[256];
extern const unsigned char const * hex_trans;
extern const unsigned char const * ykmodhex_trans;

int vname_from_path(char* buf, int buf_len, const char* name_fmt, va_list ap);
char* zx_alloc_vasprintf(struct zx_ctx* c, int *retlen, const char* f, va_list ap);

#endif
