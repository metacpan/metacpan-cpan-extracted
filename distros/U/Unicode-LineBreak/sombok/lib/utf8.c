/*
 * utf8.c - Handle UTF-8 sequence.
 * 
 * Copyright (C) 2012 by Hatuka*nezumi - IKEDA Soji.
 *
 * This file is part of the Sombok Package.  This program is free
 * software; you can redistribute it and/or modify it under the terms of
 * either the GNU General Public License or the Artistic License, as
 * specified in the README file.
 *
 */

#include "sombok.h"

/** @defgroup utf8 utf8
 * @brief Handle UTF-8 sequence.
 *
 * @note This module was introduced by release 2.1.0.
 *
 *@{*/

/** Decode UTF-8 string to Unicode string
 *
 * @param[out] unistr Unicode string, must not be NULL.
 * @param[in] maxchars maximum number of characters to be decoded.
 * 0 means infinite
 * @param[in] utf8 source UTF-8 string
 * @param[in] utf8len length of string
 * @param[in] check 0: no check; 1: check malformed sequence; 2: check
 * surrogate too; 3: check codes beyond Unicode too
 *
 * @returns Unicode string.
 * If unistr->str was NULL or maxchars was 0 (infinite), required buffer will
 * be (re-)allocated.
 * If error occurred, NULL is returned and errno is set.
 *
 * @note unistr->str must not point to static memory.
 */
unistr_t *sombok_decode_utf8(unistr_t *unistr, size_t maxchars,
			     const char *utf8, size_t utf8len, int check)
{
    size_t i, unilen;
    unichar_t unichar, *uni;
    int pass;

    if (unistr == NULL) {
	errno = EINVAL;
	return NULL;
    }
    uni = unistr->str;

    if (utf8 == NULL)
	utf8len = 0;

    for (pass = 1; pass <= 2; pass++) {
	for (i = 0, unilen = 0; i < utf8len; unilen++) {
	    if (maxchars != 0 && maxchars < unilen + 1)
		break;

	    if ((utf8[i] & 0x80) == 0) {
		if (pass == 2)
		    uni[unilen] = utf8[i];
		i++;
	    } else if (i + 1 < utf8len &&
		       (utf8[i] & 0xE0) == 0xC0 &&
		       (utf8[i + 1] & 0xC0) == 0x80) {
		if (pass == 2) {
		    unichar = utf8[i] & 0x1F;
		    unichar <<= 6;
		    unichar |= utf8[i + 1] & 0x3F;
		    uni[unilen] = unichar;
		}
		i += 2;
	    } else if (i + 2 < utf8len &&
		       (utf8[i] & 0xF0) == 0xE0 &&
		       (utf8[i + 1] & 0xC0) == 0x80 &&
		       (utf8[i + 2] & 0xC0) == 0x80) {
		if (SOMBOK_UTF8_CHECK_SURROGATE <= check &&
		    (utf8[i] & 0x0F) == 0x0D && (utf8[i + 1] & 0x20) == 0x20) {
		    errno = EPERM;
		    return NULL;
		}

		if (pass == 2) {
		    unichar = utf8[i] & 0x0F;
		    unichar <<= 6;
		    unichar |= utf8[i + 1] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 2] & 0x3F;
		    uni[unilen] = unichar;
		}
		i += 3;
	    } else if (i + 3 < utf8len &&
		       (utf8[i] & 0xF8) == 0xF0 &&
		       (utf8[i + 1] & 0xC0) == 0x80 &&
		       (utf8[i + 2] & 0xC0) == 0x80 &&
		       (utf8[i + 3] & 0xC0) == 0x80) {
		if (SOMBOK_UTF8_CHECK_NONUNICODE <= check &&
		    0x10 <
		    (((utf8[i] & 0x07) << 2) | ((utf8[i + 1] & 0x30) >> 4))) {
		    errno = EPERM;
		    return NULL;
		}

		if (pass == 2) {
		    unichar = utf8[i] & 0x07;
		    unichar <<= 6;
		    unichar |= utf8[i + 1] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 2] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 3] & 0x3F;
		    uni[unilen] = unichar;
		}
		i += 4;
	    } else if (SOMBOK_UTF8_CHECK_NONUNICODE <= check) {
		errno = EPERM;
		return NULL;
	    } else if (i + 4 < utf8len &&
		       (utf8[i] & 0xFC) == 0xF8 &&
		       (utf8[i + 1] & 0xC0) == 0x80 &&
		       (utf8[i + 2] & 0xC0) == 0x80 &&
		       (utf8[i + 3] & 0xC0) == 0x80 &&
		       (utf8[i + 4] & 0xC0) == 0x80) {
		if (pass == 2) {
		    unichar = utf8[i] & 0x03;
		    unichar <<= 6;
		    unichar |= utf8[i + 1] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 2] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 3] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 4] & 0x3F;
		    uni[unilen] = unichar;
		}
		i += 5;
	    } else if (i + 5 < utf8len &&
		       (utf8[i] & 0xFE) == 0xFC &&
		       (utf8[i + 1] & 0xC0) == 0x80 &&
		       (utf8[i + 2] & 0xC0) == 0x80 &&
		       (utf8[i + 3] & 0xC0) == 0x80 &&
		       (utf8[i + 4] & 0xC0) == 0x80 &&
		       (utf8[i + 5] & 0xC0) == 0x80) {
		if (pass == 2) {
		    unichar = utf8[i] & 0x01;
		    unichar <<= 6;
		    unichar |= utf8[i + 1] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 2] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 3] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 4] & 0x3F;
		    unichar <<= 6;
		    unichar |= utf8[i + 5] & 0x3F;
		    uni[unilen] = unichar;
		}
		i += 6;
	    } else {
		if (SOMBOK_UTF8_CHECK_MALFORMED <= check) {
		    errno = EPERM;
		    return NULL;
		}

		if (pass == 2)
		    uni[unilen] = utf8[i];
		i++;
	    }
	}

	if (pass == 1) {
	    if (uni == NULL) {
		if ((uni = malloc(sizeof(unichar_t) * (unilen + 1))) == NULL)
		    return NULL;
		uni[unilen] = 0;
	    } else if (maxchars == 0) {
		if ((uni = realloc(uni,
				   sizeof(unichar_t) * (unilen + 1))) == NULL)
		    return NULL;
		uni[unilen] = 0;
	    } else if (unilen < maxchars)
		uni[unilen] = 0;
	    unistr->str = uni;
	    unistr->len = unilen;
	}
    }

    return unistr;
}

/** Encode Unicode string to UTF-8 string
 *
 * @param[out] utf8 string buffer, may be NULL.
 * @param[out] utf8lenp pointer to length of buffer, may be NULL.
 * @param[in] maxbytes maximum number of bytes to be encoded.  0 means infinite
 * @param[in] unistr source Unicode string, must not be NULL.
 *
 * @returns string buffer.
 * If utf8 was NULL or maxbytes was 0 (infinite), required buffer will be
 * (re-)allocated.
 * If error occurred, NULL is returned and errno is set.
 *
 * @note utf8 must not point to static memory.
 */
char *sombok_encode_utf8(char *utf8, size_t *utf8lenp, size_t maxbytes,
			 unistr_t *unistr)
{
    size_t i, utf8len, unilen;
    unichar_t unichar;
    int pass;

    if (unistr == NULL) {
	errno = EINVAL;
	return NULL;
    }
    if (unistr->str == NULL)
	unilen = 0;
    else
	unilen = unistr->len;

    for (pass = 1; pass <= 2; pass++) {
	for (i = 0, utf8len = 0; i < unilen; i++) {
	    unichar = unistr->str[i];

	    if (unichar == (unichar & 0x007F)) {
		if (maxbytes != 0 && maxbytes < utf8len + 1)
		    break;
		if (pass == 2)
		    utf8[utf8len] = (char) unichar;
		utf8len++;
	    } else if (unichar == (unichar & 0x07FF)) {
		if (maxbytes != 0 && maxbytes < utf8len + 2)
		    break;
		if (pass == 2) {
		    utf8[utf8len + 1] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len] = (char) (unichar & 0x1F) | 0xC0;
		}
		utf8len += 2;
	    } else if (unichar == (unichar & 0x00FFFF)) {
		if (maxbytes != 0 && maxbytes < utf8len + 3)
		    break;
		if (pass == 2) {
		    utf8[utf8len + 2] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 1] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len] = (char) (unichar & 0x0F) | 0xE0;
		}
		utf8len += 3;
	    } else if (unichar == (unichar & 0x001FFFFF)) {
		if (maxbytes != 0 && maxbytes < utf8len + 4)
		    break;
		if (pass == 2) {
		    utf8[utf8len + 3] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 2] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 1] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len] = (char) (unichar & 0x07) | 0xF0;
		}
		utf8len += 4;
	    } else if (unichar == (unichar & 0x03FFFFFF)) {
		if (maxbytes != 0 && maxbytes < utf8len + 5)
		    break;
		if (pass == 2) {
		    utf8[utf8len + 4] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 3] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 2] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 1] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len] = (char) (unichar & 0x03) | 0xF8;
		}
		utf8len += 5;
	    } else if (unichar == (unichar & 0x7FFFFFFF)) {
		if (maxbytes != 0 && maxbytes < utf8len + 6)
		    break;
		if (pass == 2) {
		    utf8[utf8len + 5] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 4] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 3] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 2] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len + 1] = (char) (unichar & 0x3F) | 0x80;
		    unichar >>= 6;
		    utf8[utf8len] = (char) (unichar & 0x01) | 0xFC;
		}
		utf8len += 6;
	    } else {
		errno = EPERM;
		return NULL;
	    }
	}

	if (pass == 1) {
	    if (utf8 == NULL) {
		if ((utf8 = malloc(sizeof(char) * (utf8len + 1))) == NULL)
		    return NULL;
		utf8[utf8len] = '\0';
	    } else if (maxbytes == 0) {
		if ((utf8 = realloc(utf8,
				    sizeof(char) * (utf8len + 1))) == NULL)
		    return NULL;
		utf8[utf8len] = '\0';
	    } else if (utf8len < maxbytes)
		utf8[utf8len] = '\0';
	    if (utf8lenp != NULL)
		*utf8lenp = utf8len;
	}
    }

    return utf8;
}
