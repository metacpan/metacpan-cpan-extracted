/*
 * ------------------------------------------------------------------------
 * @NAME       : util.c @INPUT      : @OUTPUT     : @RETURNS    :
 * @DESCRIPTION: Miscellaneous utility functions.  So far, just: strlwr
 * strupr @CREATED    : Summer 1996, Greg Ward @MODIFIED   : @VERSION    :
 * $Id$ @COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights
 * reserved.
 * 
 * This file is part of the btparse library.  This library is free software; you
 * can redistribute it and/or modify it under the terms of the GNU Library
 * General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 * --------------------------------------------------------------------------
 */

#include "bt_config.h"
#include <string.h>
#include <ctype.h>
#include "prototypes.h"
#include "my_dmalloc.h"

/*
 * ------------------------------------------------------------------------
 * @NAME       : strlwr() @INPUT      : @OUTPUT     : @RETURNS    :
 * @DESCRIPTION: Converts a string to lowercase in place. @GLOBALS    :
 * @CALLS      : @CREATED    : 1996/01/06, GPW @MODIFIED   : @COMMENTS   :
 * This should work the same as strlwr() in DOS compilers -- why this isn't
 * mandated by ANSI is a mystery to me...
 * --------------------------------------------------------------------------
 */
#if !HAVE_STRLWR
char           *
strlwr(char *s)
{
    int        len       , i;

    len = strlen(s);
    for (i = 0; i < len; i++)
        s[i] = tolower(s[i]);

    return s;
}
#endif



/*
 * ------------------------------------------------------------------------
 * @NAME       : strupr() @INPUT      : @OUTPUT     : @RETURNS    :
 * @DESCRIPTION: Converts a string to uppercase in place. @GLOBALS    :
 * @CALLS      : @CREATED    : 1996/01/06, GPW @MODIFIED   : @COMMENTS   :
 * This should work the same as strupr() in DOS compilers -- why this isn't
 * mandated by ANSI is a mystery to me...
 * --------------------------------------------------------------------------
 */
#if !HAVE_STRUPR
char           *
strupr(char *s)
{
    int        len       , i;

    len = strlen(s);
    for (i = 0; i < len; i++)
        s[i] = toupper(s[i]);

    return s;
}
#endif

/*
 * ------------------------------------------------------------------------
 * @NAME       : get_uchar() @INPUT      : string offset in string @OUTPUT
 * : number of bytes required to gobble the next unicode character, including
 * any combining marks @RETURNS    : @DESCRIPTION: In order to deal with
 * unicode chars when calculating abbreviations, we need to know how many
 * bytes the next character is. @CALLS      : @CALLERS    :
 * count_virtual_char() @CREATED    : 2010/03/14, PK @MODIFIED   :
 * --------------------------------------------------------------------------
 */
int
get_uchar(char *string, int offset)
{
    unsigned char  *bytes = (unsigned char *)string;
    int        init;
    unsigned int    c = 0;
    //Without unsigned, for some reason Solaris coredumps

    if              (!string)
                return    0;

    if ((//ASCII
         bytes[offset] == 0x09 ||
         bytes[offset] == 0x0A ||
         bytes[offset] == 0x0D ||
         (0x20 <= bytes[offset] && bytes[offset] <= 0x7E)
         )
        ) {
        init = 1;
    }
    if ((//non - overlong 2 - byte
         (0xC2 <= bytes[offset] && bytes[offset] <= 0xDF) &&
         (0x80 <= bytes[offset + 1] && bytes[offset + 1] <= 0xBF)
         )
        ) {
        init = 2;
    }
    if ((//excluding overlongs
         bytes[offset] == 0xE0 &&
         (0xA0 <= bytes[offset + 1] && bytes[offset + 1] <= 0xBF) &&
         (0x80 <= bytes[offset + 2] && bytes[offset + 2] <= 0xBF)
         ) ||
        (//straight 3 - byte
         ((0xE1 <= bytes[offset] && bytes[offset] <= 0xEC) ||
          bytes[offset] == 0xEE ||
          bytes[offset] == 0xEF) &&
         (0x80 <= bytes[offset + 1] && bytes[offset + 1] <= 0xBF) &&
         (0x80 <= bytes[offset + 2] && bytes[offset + 2] <= 0xBF)
         ) ||
        (//excluding surrogates
         bytes[offset] == 0xED &&
         (0x80 <= bytes[offset + 1] && bytes[offset + 1] <= 0x9F) &&
         (0x80 <= bytes[offset + 2] && bytes[offset + 2] <= 0xBF)
         )
        ) {
        init = 3;
    }
    if ((//planes 1 - 3
         bytes[offset] == 0xF0 &&
         (0x90 <= bytes[offset + 1] && bytes[offset + 1] <= 0xBF) &&
         (0x80 <= bytes[offset + 2] && bytes[offset + 2] <= 0xBF) &&
         (0x80 <= bytes[offset + 3] && bytes[offset + 3] <= 0xBF)
         ) ||
        (//planes 4 - 15
         (0xF1 <= bytes[offset] && bytes[offset] <= 0xF3) &&
         (0x80 <= bytes[offset + 1] && bytes[offset + 1] <= 0xBF) &&
         (0x80 <= bytes[offset + 2] && bytes[offset + 2] <= 0xBF) &&
         (0x80 <= bytes[offset + 3] && bytes[offset + 3] <= 0xBF)
         ) ||
        (//plane 16
         bytes[offset] == 0xF4 &&
         (0x80 <= bytes[offset + 1] && bytes[offset + 1] <= 0x8F) &&
         (0x80 <= bytes[offset + 2] && bytes[offset + 2] <= 0xBF) &&
         (0x80 <= bytes[offset + 3] && bytes[offset + 3] <= 0xBF)
         )
        ) {
        init = 4;
    }
    /* Now check for combining marks which are separate even in NFC */
    while (bytes[offset + init + c]) {
        /* 0300–036F - Combining Diacritical Marks */
        if (bytes[offset + init + c] == 0xCC &&
            (0x80 <= bytes[offset + init + 1 + c] && bytes[offset + init + 1 + c] <= 0xAF)
            ) {
            c = c + 2;    /* Skip to next possible combining
                     * mark */
        }
        /* 1DC0–1DFF - Combining Diacritical Marks Supplement */
        else if (bytes[offset + init + c] == 0xE1 &&
             bytes[offset + init + 1 + c] == 0xB7 &&
             (0x80 <= bytes[offset + init + 2 + c] && bytes[offset + init + 2 + c] <= 0xBF)
            ) {
            c = c + 3;    /* Skip to next possible combining
                     * mark */
        }
        /* FE20–FE2F - Combining Half Marks */
        else if (bytes[offset + init + c] == 0xEF &&
             bytes[offset + init + 1 + c] == 0xB8 &&
             (0xA0 <= bytes[offset + init + 2 + c] && bytes[offset + init + 2 + c] <= 0xAF)
            ) {
            c = c + 3;    /* Skip to next possible combining
                     * mark */
        } else {
            break;
        }
    }
    return init + c;
}

/*
 * ------------------------------------------------------------------------
 * @NAME       : isulower() @INPUT      : some bytes @OUTPUT     : @RETURNS
 * : boolean 1 or 0 @DESCRIPTION: Passed some bytes, returns 1 of the first
 * UTF-8 char is lowercase The code was autogenerated from a dump of perl's
 * fabulous unichars -a '\p{Ll}', massaged into bytes and printed. This list
 * of lowercased property glyphs is from Unicode 6.2.0 @CALLS      : @CALLERS
 * : find_lc_tokens() @CREATED    : 2014/02/27, PK @MODIFIED   :
 * --------------------------------------------------------------------------
 */
int
isulower(char *string)
{
    unsigned char  *bytes = (unsigned char *)string;

    if (!string)
        return 0;

    if (
        (0x61 <= bytes[0] && bytes[0] <= 0x7A)
        ) {
        return 1;
    }
    if (
        (
         bytes[0] == 0xC2 &&
         (
          bytes[1] == 0xB5
          )
         ) ||
        (
         bytes[0] == 0xC3 &&
         (
          (0x9F <= bytes[1] && bytes[1] <= 0xB6) ||
          (0xB8 <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xC4 &&
         (
          bytes[1] == 0x81 ||
          bytes[1] == 0x83 ||
          bytes[1] == 0x85 ||
          bytes[1] == 0x87 ||
          bytes[1] == 0x89 ||
          bytes[1] == 0x8B ||
          bytes[1] == 0x8D ||
          bytes[1] == 0x8F ||
          bytes[1] == 0x91 ||
          bytes[1] == 0x93 ||
          bytes[1] == 0x95 ||
          bytes[1] == 0x97 ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xAF ||
          bytes[1] == 0xB1 ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB5 ||
          (0xB7 <= bytes[1] && bytes[1] <= 0xB8) ||
          bytes[1] == 0xBA ||
          bytes[1] == 0xBC ||
          bytes[1] == 0xBE
          )
         ) ||
        (
         bytes[0] == 0xC5 &&
         (
          bytes[1] == 0x80 ||
          bytes[1] == 0x82 ||
          bytes[1] == 0x84 ||
          bytes[1] == 0x86 ||
          (0x88 <= bytes[1] && bytes[1] <= 0x89) ||
          bytes[1] == 0x8B ||
          bytes[1] == 0x8D ||
          bytes[1] == 0x8F ||
          bytes[1] == 0x91 ||
          bytes[1] == 0x93 ||
          bytes[1] == 0x95 ||
          bytes[1] == 0x97 ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xAF ||
          bytes[1] == 0xB1 ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB5 ||
          bytes[1] == 0xB7 ||
          bytes[1] == 0xBA ||
          bytes[1] == 0xBC ||
          (0xBE <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xC6 &&
         (
          bytes[1] == 0x80 ||
          bytes[1] == 0x83 ||
          bytes[1] == 0x85 ||
          bytes[1] == 0x88 ||
          (0x8C <= bytes[1] && bytes[1] <= 0x8D) ||
          bytes[1] == 0x92 ||
          bytes[1] == 0x95 ||
          (0x99 <= bytes[1] && bytes[1] <= 0x9B) ||
          bytes[1] == 0x9E ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA8 ||
          (0xAA <= bytes[1] && bytes[1] <= 0xAB) ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xB0 ||
          bytes[1] == 0xB4 ||
          bytes[1] == 0xB6 ||
          (0xB9 <= bytes[1] && bytes[1] <= 0xBA) ||
          (0xBD <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xC7 &&
         (
          bytes[1] == 0x86 ||
          bytes[1] == 0x89 ||
          bytes[1] == 0x8C ||
          bytes[1] == 0x8E ||
          bytes[1] == 0x90 ||
          bytes[1] == 0x92 ||
          bytes[1] == 0x94 ||
          bytes[1] == 0x96 ||
          bytes[1] == 0x98 ||
          bytes[1] == 0x9A ||
          (0x9C <= bytes[1] && bytes[1] <= 0x9D) ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          (0xAF <= bytes[1] && bytes[1] <= 0xB0) ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB5 ||
          bytes[1] == 0xB9 ||
          bytes[1] == 0xBB ||
          bytes[1] == 0xBD ||
          bytes[1] == 0xBF
          )
         ) ||
        (
         bytes[0] == 0xC8 &&
         (
          bytes[1] == 0x81 ||
          bytes[1] == 0x83 ||
          bytes[1] == 0x85 ||
          bytes[1] == 0x87 ||
          bytes[1] == 0x89 ||
          bytes[1] == 0x8B ||
          bytes[1] == 0x8D ||
          bytes[1] == 0x8F ||
          bytes[1] == 0x91 ||
          bytes[1] == 0x93 ||
          bytes[1] == 0x95 ||
          bytes[1] == 0x97 ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xAF ||
          bytes[1] == 0xB1 ||
          (0xB3 <= bytes[1] && bytes[1] <= 0xB9) ||
          bytes[1] == 0xBC ||
          bytes[1] == 0xBF
          )
         ) ||
        (
         bytes[0] == 0xC9 &&
         (
          bytes[1] == 0x80 ||
          bytes[1] == 0x82 ||
          bytes[1] == 0x87 ||
          bytes[1] == 0x89 ||
          bytes[1] == 0x8B ||
          bytes[1] == 0x8D ||
          (0x8F <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xCA &&
         (
          (0x80 <= bytes[1] && bytes[1] <= 0x93) ||
          (0x95 <= bytes[1] && bytes[1] <= 0xAF)
          )
         ) ||
        (
         bytes[0] == 0xCD &&
         (
          bytes[1] == 0xB1 ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB7 ||
          (0xBB <= bytes[1] && bytes[1] <= 0xBD)
          )
         ) ||
        (
         bytes[0] == 0xCE &&
         (
          bytes[1] == 0x90 ||
          (0xAC <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xCF &&
         (
          (0x80 <= bytes[1] && bytes[1] <= 0x8E) ||
          (0x90 <= bytes[1] && bytes[1] <= 0x91) ||
          (0x95 <= bytes[1] && bytes[1] <= 0x97) ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          (0xAF <= bytes[1] && bytes[1] <= 0xB3) ||
          bytes[1] == 0xB5 ||
          bytes[1] == 0xB8 ||
          (0xBB <= bytes[1] && bytes[1] <= 0xBC)
          )
         ) ||
        (
         bytes[0] == 0xD0 &&
         (
          (0xB0 <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xD1 &&
         (
          (0x80 <= bytes[1] && bytes[1] <= 0x9F) ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xAF ||
          bytes[1] == 0xB1 ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB5 ||
          bytes[1] == 0xB7 ||
          bytes[1] == 0xB9 ||
          bytes[1] == 0xBB ||
          bytes[1] == 0xBD ||
          bytes[1] == 0xBF
          )
         ) ||
        (
         bytes[0] == 0xD2 &&
         (
          bytes[1] == 0x81 ||
          bytes[1] == 0x8B ||
          bytes[1] == 0x8D ||
          bytes[1] == 0x8F ||
          bytes[1] == 0x91 ||
          bytes[1] == 0x93 ||
          bytes[1] == 0x95 ||
          bytes[1] == 0x97 ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xAF ||
          bytes[1] == 0xB1 ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB5 ||
          bytes[1] == 0xB7 ||
          bytes[1] == 0xB9 ||
          bytes[1] == 0xBB ||
          bytes[1] == 0xBD ||
          bytes[1] == 0xBF
          )
         ) ||
        (
         bytes[0] == 0xD3 &&
         (
          bytes[1] == 0x82 ||
          bytes[1] == 0x84 ||
          bytes[1] == 0x86 ||
          bytes[1] == 0x88 ||
          bytes[1] == 0x8A ||
          bytes[1] == 0x8C ||
          (0x8E <= bytes[1] && bytes[1] <= 0x8F) ||
          bytes[1] == 0x91 ||
          bytes[1] == 0x93 ||
          bytes[1] == 0x95 ||
          bytes[1] == 0x97 ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7 ||
          bytes[1] == 0xA9 ||
          bytes[1] == 0xAB ||
          bytes[1] == 0xAD ||
          bytes[1] == 0xAF ||
          bytes[1] == 0xB1 ||
          bytes[1] == 0xB3 ||
          bytes[1] == 0xB5 ||
          bytes[1] == 0xB7 ||
          bytes[1] == 0xB9 ||
          bytes[1] == 0xBB ||
          bytes[1] == 0xBD ||
          bytes[1] == 0xBF
          )
         ) ||
        (
         bytes[0] == 0xD4 &&
         (
          bytes[1] == 0x81 ||
          bytes[1] == 0x83 ||
          bytes[1] == 0x85 ||
          bytes[1] == 0x87 ||
          bytes[1] == 0x89 ||
          bytes[1] == 0x8B ||
          bytes[1] == 0x8D ||
          bytes[1] == 0x8F ||
          bytes[1] == 0x91 ||
          bytes[1] == 0x93 ||
          bytes[1] == 0x95 ||
          bytes[1] == 0x97 ||
          bytes[1] == 0x99 ||
          bytes[1] == 0x9B ||
          bytes[1] == 0x9D ||
          bytes[1] == 0x9F ||
          bytes[1] == 0xA1 ||
          bytes[1] == 0xA3 ||
          bytes[1] == 0xA5 ||
          bytes[1] == 0xA7
          )
         ) ||
        (
         bytes[0] == 0xD5 &&
         (
          (0xA1 <= bytes[1] && bytes[1] <= 0xBF)
          )
         ) ||
        (
         bytes[0] == 0xD6 &&
         (
          (0x80 <= bytes[1] && bytes[1] <= 0x87)
          )
         )
        ) {
        return 1;
    }
    if (
        (
         bytes[0] == 0xE1 && (
           (bytes[1] == 0xB4 && 0x80 <= bytes[2] && bytes[2] <= 0xAB) ||
                  (
                   bytes[1] == 0xB5 &&
                   (
                    (0xAB <= bytes[2] && bytes[2] <= 0xB7) ||
                    (0xB9 <= bytes[2] && bytes[2] <= 0xBF)
                    )
                   ) ||
                  (
                   bytes[1] == 0xB6 &&
                   (
                    (0x80 <= bytes[2] && bytes[2] <= 0x9A)
                    )
                   ) ||
                  (
                   bytes[1] == 0xB8 &&
                   (
                    bytes[2] == 0x81 ||
                    bytes[2] == 0x83 ||
                    bytes[2] == 0x85 ||
                    bytes[2] == 0x87 ||
                    bytes[2] == 0x89 ||
                    bytes[2] == 0x8B ||
                    bytes[2] == 0x8D ||
                    bytes[2] == 0x8F ||
                    bytes[2] == 0x91 ||
                    bytes[2] == 0x93 ||
                    bytes[2] == 0x95 ||
                    bytes[2] == 0x97 ||
                    bytes[2] == 0x99 ||
                    bytes[2] == 0x9B ||
                    bytes[2] == 0x9D ||
                    bytes[2] == 0x9F ||
                    bytes[2] == 0xA1 ||
                    bytes[2] == 0xA3 ||
                    bytes[2] == 0xA5 ||
                    bytes[2] == 0xA7 ||
                    bytes[2] == 0xA9 ||
                    bytes[2] == 0xAB ||
                    bytes[2] == 0xAD ||
                    bytes[2] == 0xAF ||
                    bytes[2] == 0xB1 ||
                    bytes[2] == 0xB3 ||
                    bytes[2] == 0xB5 ||
                    bytes[2] == 0xB7 ||
                    bytes[2] == 0xB9 ||
                    bytes[2] == 0xBB ||
                    bytes[2] == 0xBD ||
                    bytes[2] == 0xBF
                    )
                   ) ||
                  (
                   bytes[1] == 0xB9 &&
                   (
                    bytes[2] == 0x81 ||
                    bytes[2] == 0x83 ||
                    bytes[2] == 0x85 ||
                    bytes[2] == 0x87 ||
                    bytes[2] == 0x89 ||
                    bytes[2] == 0x8B ||
                    bytes[2] == 0x8D ||
                    bytes[2] == 0x8F ||
                    bytes[2] == 0x91 ||
                    bytes[2] == 0x93 ||
                    bytes[2] == 0x95 ||
                    bytes[2] == 0x97 ||
                    bytes[2] == 0x99 ||
                    bytes[2] == 0x9B ||
                    bytes[2] == 0x9D ||
                    bytes[2] == 0x9F ||
                    bytes[2] == 0xA1 ||
                    bytes[2] == 0xA3 ||
                    bytes[2] == 0xA5 ||
                    bytes[2] == 0xA7 ||
                    bytes[2] == 0xA9 ||
                    bytes[2] == 0xAB ||
                    bytes[2] == 0xAD ||
                    bytes[2] == 0xAF ||
                    bytes[2] == 0xB1 ||
                    bytes[2] == 0xB3 ||
                    bytes[2] == 0xB5 ||
                    bytes[2] == 0xB7 ||
                    bytes[2] == 0xB9 ||
                    bytes[2] == 0xBB ||
                    bytes[2] == 0xBD ||
                    bytes[2] == 0xBF
                    )
                   ) ||
                  (
                   bytes[1] == 0xBA &&
                   (
                    bytes[2] == 0x81 ||
                    bytes[2] == 0x83 ||
                    bytes[2] == 0x85 ||
                    bytes[2] == 0x87 ||
                    bytes[2] == 0x89 ||
                    bytes[2] == 0x8B ||
                    bytes[2] == 0x8D ||
                    bytes[2] == 0x8F ||
                    bytes[2] == 0x91 ||
                    bytes[2] == 0x93 ||
                    (0x95 <= bytes[2] && bytes[2] <= 0x9D) ||
                    bytes[2] == 0x9F ||
                    bytes[2] == 0xA1 ||
                    bytes[2] == 0xA3 ||
                    bytes[2] == 0xA5 ||
                    bytes[2] == 0xA7 ||
                    bytes[2] == 0xA9 ||
                    bytes[2] == 0xAB ||
                    bytes[2] == 0xAD ||
                    bytes[2] == 0xAF ||
                    bytes[2] == 0xB1 ||
                    bytes[2] == 0xB3 ||
                    bytes[2] == 0xB5 ||
                    bytes[2] == 0xB7 ||
                    bytes[2] == 0xB9 ||
                    bytes[2] == 0xBB ||
                    bytes[2] == 0xBD ||
                    bytes[2] == 0xBF
                    )
                   ) ||
                  (
                   bytes[1] == 0xBB &&
                   (
                    bytes[2] == 0x81 ||
                    bytes[2] == 0x83 ||
                    bytes[2] == 0x85 ||
                    bytes[2] == 0x87 ||
                    bytes[2] == 0x89 ||
                    bytes[2] == 0x8B ||
                    bytes[2] == 0x8D ||
                    bytes[2] == 0x8F ||
                    bytes[2] == 0x91 ||
                    bytes[2] == 0x93 ||
                    bytes[2] == 0x95 ||
                    bytes[2] == 0x97 ||
                    bytes[2] == 0x99 ||
                    bytes[2] == 0x9B ||
                    bytes[2] == 0x9D ||
                    bytes[2] == 0x9F ||
                    bytes[2] == 0xA1 ||
                    bytes[2] == 0xA3 ||
                    bytes[2] == 0xA5 ||
                    bytes[2] == 0xA7 ||
                    bytes[2] == 0xA9 ||
                    bytes[2] == 0xAB ||
                    bytes[2] == 0xAD ||
                    bytes[2] == 0xAF ||
                    bytes[2] == 0xB1 ||
                    bytes[2] == 0xB3 ||
                    bytes[2] == 0xB5 ||
                    bytes[2] == 0xB7 ||
                    bytes[2] == 0xB9 ||
                    bytes[2] == 0xBB ||
                    bytes[2] == 0xBD ||
                    bytes[2] == 0xBF
                    )
                   ) ||
                  (
                   bytes[1] == 0xBC &&
                   (
                    (0x80 <= bytes[2] && bytes[2] <= 0x87) ||
                    (0x90 <= bytes[2] && bytes[2] <= 0x95) ||
                    (0xA0 <= bytes[2] && bytes[2] <= 0xA7) ||
                    (0xB0 <= bytes[2] && bytes[2] <= 0xB7)
                    )
                   ) ||
                  (
                   bytes[1] == 0xBD &&
                   (
                    (0x80 <= bytes[2] && bytes[2] <= 0x85) ||
                    (0x90 <= bytes[2] && bytes[2] <= 0x97) ||
                    (0xA0 <= bytes[2] && bytes[2] <= 0xA7) ||
                    (0xB0 <= bytes[2] && bytes[2] <= 0xBD)
                    )
                   ) ||
                  (
                   bytes[1] == 0xBE &&
                   (
                    (0x80 <= bytes[2] && bytes[2] <= 0x87) ||
                    (0x90 <= bytes[2] && bytes[2] <= 0x97) ||
                    (0xA0 <= bytes[2] && bytes[2] <= 0xA7) ||
                    (0xB0 <= bytes[2] && bytes[2] <= 0xB4) ||
                    (0xB6 <= bytes[2] && bytes[2] <= 0xB7) ||
                    bytes[2] == 0xBE
                    )
                   ) ||
                  (
                   bytes[1] == 0xBF &&
                   (
                    (0x82 <= bytes[2] && bytes[2] <= 0x84) ||
                    (0x86 <= bytes[2] && bytes[2] <= 0x87) ||
                    (0x90 <= bytes[2] && bytes[2] <= 0x93) ||
                    (0x96 <= bytes[2] && bytes[2] <= 0x97) ||
                    (0xA0 <= bytes[2] && bytes[2] <= 0xA7) ||
                    (0xB2 <= bytes[2] && bytes[2] <= 0xB4) ||
                    (0xB6 <= bytes[2] && bytes[2] <= 0xB7)
                    )
                   )
                  )
         ) ||
        (
         bytes[0] == 0xE2 &&
         ((
           bytes[1] == 0x84 &&
           (
        bytes[2] == 0x8A ||
        (0x8E <= bytes[2] && bytes[2] <= 0x8F) ||
        bytes[2] == 0x93 ||
        bytes[2] == 0xAF ||
        bytes[2] == 0xB4 ||
        bytes[2] == 0xB9 ||
        (0xBC <= bytes[2] && bytes[2] <= 0xBD)
        )
           ) ||
          (
           bytes[1] == 0x85 &&
           (
        (0x86 <= bytes[2] && bytes[2] <= 0x89) ||
        bytes[2] == 0x8E
        )
           ) ||
          (
           bytes[1] == 0x86 &&
           (
        bytes[2] == 0x84
        )
           ) ||
          (
           bytes[1] == 0xB0 &&
           (
        (0xB0 <= bytes[2] && bytes[2] <= 0xBF)
        )
           ) ||
          (
           bytes[1] == 0xB1 &&
           (
        (0x80 <= bytes[2] && bytes[2] <= 0x9E) ||
        bytes[2] == 0xA1 ||
        (0xA5 <= bytes[2] && bytes[2] <= 0xA6) ||
        bytes[2] == 0xA8 ||
        bytes[2] == 0xAA ||
        bytes[2] == 0xAC ||
        bytes[2] == 0xB1 ||
        (0xB3 <= bytes[2] && bytes[2] <= 0xB4) ||
        (0xB6 <= bytes[2] && bytes[2] <= 0xBB)
        )
           ) ||
          (
           bytes[1] == 0xB2 &&
           (
        bytes[2] == 0x81 ||
        bytes[2] == 0x83 ||
        bytes[2] == 0x85 ||
        bytes[2] == 0x87 ||
        bytes[2] == 0x89 ||
        bytes[2] == 0x8B ||
        bytes[2] == 0x8D ||
        bytes[2] == 0x8F ||
        bytes[2] == 0x91 ||
        bytes[2] == 0x93 ||
        bytes[2] == 0x95 ||
        bytes[2] == 0x97 ||
        bytes[2] == 0x99 ||
        bytes[2] == 0x9B ||
        bytes[2] == 0x9D ||
        bytes[2] == 0x9F ||
        bytes[2] == 0xA1 ||
        bytes[2] == 0xA3 ||
        bytes[2] == 0xA5 ||
        bytes[2] == 0xA7 ||
        bytes[2] == 0xA9 ||
        bytes[2] == 0xAB ||
        bytes[2] == 0xAD ||
        bytes[2] == 0xAF ||
        bytes[2] == 0xB1 ||
        bytes[2] == 0xB3 ||
        bytes[2] == 0xB5 ||
        bytes[2] == 0xB7 ||
        bytes[2] == 0xB9 ||
        bytes[2] == 0xBB ||
        bytes[2] == 0xBD ||
        bytes[2] == 0xBF
        )
           ) ||
          (
           bytes[1] == 0xB3 &&
           (
        bytes[2] == 0x81 ||
        bytes[2] == 0x83 ||
        bytes[2] == 0x85 ||
        bytes[2] == 0x87 ||
        bytes[2] == 0x89 ||
        bytes[2] == 0x8B ||
        bytes[2] == 0x8D ||
        bytes[2] == 0x8F ||
        bytes[2] == 0x91 ||
        bytes[2] == 0x93 ||
        bytes[2] == 0x95 ||
        bytes[2] == 0x97 ||
        bytes[2] == 0x99 ||
        bytes[2] == 0x9B ||
        bytes[2] == 0x9D ||
        bytes[2] == 0x9F ||
        bytes[2] == 0xA1 ||
        (0xA3 <= bytes[2] && bytes[2] <= 0xA4) ||
        bytes[2] == 0xAC ||
        bytes[2] == 0xAE ||
        bytes[2] == 0xB3
        )
           ) ||
          (
           bytes[1] == 0xB4 &&
           (
        (0x80 <= bytes[2] && bytes[2] <= 0xA5) ||
        bytes[2] == 0xA7 ||
        bytes[2] == 0xAD
        )
           )
          )) ||
        (
         bytes[0] == 0xEA &&
         ((
           bytes[1] == 0x99 &&
           (
        bytes[2] == 0x81 ||
        bytes[2] == 0x83 ||
        bytes[2] == 0x85 ||
        bytes[2] == 0x87 ||
        bytes[2] == 0x89 ||
        bytes[2] == 0x8B ||
        bytes[2] == 0x8D ||
        bytes[2] == 0x8F ||
        bytes[2] == 0x91 ||
        bytes[2] == 0x93 ||
        bytes[2] == 0x95 ||
        bytes[2] == 0x97 ||
        bytes[2] == 0x99 ||
        bytes[2] == 0x9B ||
        bytes[2] == 0x9D ||
        bytes[2] == 0x9F ||
        bytes[2] == 0xA1 ||
        bytes[2] == 0xA3 ||
        bytes[2] == 0xA5 ||
        bytes[2] == 0xA7 ||
        bytes[2] == 0xA9 ||
        bytes[2] == 0xAB ||
        bytes[2] == 0xAD
        )
           ) ||
          (
           bytes[1] == 0x9A &&
           (
        bytes[2] == 0x81 ||
        bytes[2] == 0x83 ||
        bytes[2] == 0x85 ||
        bytes[2] == 0x87 ||
        bytes[2] == 0x89 ||
        bytes[2] == 0x8B ||
        bytes[2] == 0x8D ||
        bytes[2] == 0x8F ||
        bytes[2] == 0x91 ||
        bytes[2] == 0x93 ||
        bytes[2] == 0x95 ||
        bytes[2] == 0x97
        )
           ) ||
          (
           bytes[1] == 0x9C &&
           (
        bytes[2] == 0xA3 ||
        bytes[2] == 0xA5 ||
        bytes[2] == 0xA7 ||
        bytes[2] == 0xA9 ||
        bytes[2] == 0xAB ||
        bytes[2] == 0xAD ||
        (0xAF <= bytes[2] && bytes[2] <= 0xB1) ||
        bytes[2] == 0xB3 ||
        bytes[2] == 0xB5 ||
        bytes[2] == 0xB7 ||
        bytes[2] == 0xB9 ||
        bytes[2] == 0xBB ||
        bytes[2] == 0xBD ||
        bytes[2] == 0xBF
        )
           ) ||
          (
           bytes[1] == 0x9D &&
           (
        bytes[2] == 0x81 ||
        bytes[2] == 0x83 ||
        bytes[2] == 0x85 ||
        bytes[2] == 0x87 ||
        bytes[2] == 0x89 ||
        bytes[2] == 0x8B ||
        bytes[2] == 0x8D ||
        bytes[2] == 0x8F ||
        bytes[2] == 0x91 ||
        bytes[2] == 0x93 ||
        bytes[2] == 0x95 ||
        bytes[2] == 0x97 ||
        bytes[2] == 0x99 ||
        bytes[2] == 0x9B ||
        bytes[2] == 0x9D ||
        bytes[2] == 0x9F ||
        bytes[2] == 0xA1 ||
        bytes[2] == 0xA3 ||
        bytes[2] == 0xA5 ||
        bytes[2] == 0xA7 ||
        bytes[2] == 0xA9 ||
        bytes[2] == 0xAB ||
        bytes[2] == 0xAD ||
        bytes[2] == 0xAF ||
        (0xB1 <= bytes[2] && bytes[2] <= 0xB8) ||
        bytes[2] == 0xBA ||
        bytes[2] == 0xBC ||
        bytes[2] == 0xBF
        )
           ) ||
          (
           bytes[1] == 0x9E &&
           (
        bytes[2] == 0x81 ||
        bytes[2] == 0x83 ||
        bytes[2] == 0x85 ||
        bytes[2] == 0x87 ||
        bytes[2] == 0x8C ||
        bytes[2] == 0x8E ||
        bytes[2] == 0x91 ||
        bytes[2] == 0x93 ||
        bytes[2] == 0xA1 ||
        bytes[2] == 0xA3 ||
        bytes[2] == 0xA5 ||
        bytes[2] == 0xA7 ||
        bytes[2] == 0xA9
        )
           ) ||
          (
           bytes[1] == 0x9F &&
           (
        bytes[2] == 0xBA
        )
           )
          )) ||
        (
         bytes[0] == 0xEF &&
         ((
           bytes[1] == 0xAC &&
           (
        (0x80 <= bytes[2] && bytes[2] <= 0x86) ||
        (0x93 <= bytes[2] && bytes[2] <= 0x97)
        )
           ) ||
          (
           bytes[1] == 0xBD &&
           (
        (0x81 <= bytes[2] && bytes[2] <= 0x9A)
        )
           ))
         )) {
        return 1;
    }
    if (
        (
         bytes[0] == 0xF0
         &&
         (
          (
           bytes[1] == 0x90
           &&
           (
        (bytes[2] == 0x90 && 0xA8 <= bytes[3] && bytes[3] <= 0xBF)
        ||
        (bytes[2] == 0x91 && 0x80 <= bytes[3] && bytes[3] <= 0x8F)
        )
           )
          ||
          (
           bytes[1] == 0x9D
           && (
           (bytes[2] == 0x90 && 0x9A <= bytes[3] && bytes[3] <= 0xB3)
           ||
           (
            bytes[2] == 0x91 &&
            (
             (0x8E <= bytes[3] && bytes[3] <= 0x94)
             ||
             (0x96 <= bytes[3] && bytes[3] <= 0xA7)
             )
            )
           ||
           (
            bytes[2] == 0x92 &&
            (
             (0x82 <= bytes[3] && bytes[3] <= 0x9B)
             ||
             (0xB6 <= bytes[3] && bytes[3] <= 0xB9)
             ||
             bytes[3] == 0xBB
             ||
             (0xBD <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x93 &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x83) ||
             (0x85 <= bytes[3] && bytes[3] <= 0x8F) ||
             (0xAA <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x94 &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x83) ||
             (0x9E <= bytes[3] && bytes[3] <= 0xB7)
             )
            )
           ||
           (
            bytes[2] == 0x95 && 0x92 <= bytes[3] && bytes[3] <= 0xAB
            )
           ||
           (
            bytes[2] == 0x96 &&
            (
             (0x86 <= bytes[3] && bytes[3] <= 0x9F) ||
             (0xBA <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x97 &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x93) ||
             (0xAE <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x98 &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x87) ||
             (0xA2 <= bytes[3] && bytes[3] <= 0xBB)
             )
            )
           ||
           (bytes[2] == 0x99 && 0x96 <= bytes[3] && bytes[3] <= 0xAF)
           ||
           (bytes[2] == 0x9A && 0x8A <= bytes[3] && bytes[3] <= 0xA5)
           ||
           (
            bytes[2] == 0x9B &&
            (
             (0x82 <= bytes[3] && bytes[3] <= 0x9A) ||
             (0x9C <= bytes[3] && bytes[3] <= 0xA1) ||
             (0xBC <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x9C &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x94) ||
             (0x96 <= bytes[3] && bytes[3] <= 0x9B) ||
             (0xB6 <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x9D &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x8E) ||
             (0x90 <= bytes[3] && bytes[3] <= 0x95) ||
             (0xB0 <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x9E &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x88) ||
             (0x8A <= bytes[3] && bytes[3] <= 0x8F) ||
             (0xAA <= bytes[3] && bytes[3] <= 0xBF)
             )
            )
           ||
           (
            bytes[2] == 0x9F &&
            (
             (0x80 <= bytes[3] && bytes[3] <= 0x82) ||
             (0x84 <= bytes[3] && bytes[3] <= 0x89) ||
             bytes[3] == 0x8B
             )
            )
           )
           ))
         )
        ) {
        return 1;
    }
    return 0;
    //no lowercase character
}                /* isulower */
