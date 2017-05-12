/*
 * southeastasian.c - interfaces for South East Asian complex breaking.
 * 
 * Copyright (C) 2009-2012 by Hatuka*nezumi - IKEDA Soji.
 *
 * This file is part of the Sombok Package.  This program is free
 * software; you can redistribute it and/or modify it under the terms of
 * either the GNU General Public License or the Artistic License, as
 * specified in the README file.
 *
 */

#include <assert.h>
#include "sombok_constants.h"
#include "sombok.h"
#ifdef USE_LIBTHAI
#    include "thai/thwchar.h"
#    include "thai/thwbrk.h"
#endif /* USE_LIBTHAI */

/** @defgroup linebreak_southeastasian southeastasian
 * @brief Supports for breaking in South East Asian complex context.
 *
 *@{*/

/** Flag to determin whether South East Asian word segmentation is supported.
 */
const char *linebreak_southeastasian_supported =
#ifdef USE_LIBTHAI
    "Thai:" USE_LIBTHAI " "
#else /* USE_LIBTHAI */
    NULL
#endif /* USE_LIBTHAI */
    ;

void linebreak_southeastasian_flagbreak(gcstring_t * gcstr)
{
#ifdef USE_LIBTHAI
    wchar_t *buf;
    size_t i, j, len;
    int brk, sa;

    if (gcstr == NULL || gcstr->gclen == 0)
	return;
    if (!(((linebreak_t *) gcstr->lbobj)->options &
	  LINEBREAK_OPTION_COMPLEX_BREAKING))
	return;

    len = gcstr->len;

    /* Copy string to temp buffer so that abuse of external module avoided. */
    if ((buf = malloc(sizeof(wchar_t) * (len + 1))) == NULL)
	return;
#ifdef SOMBOK_UNICHAR_T_IS_WCHAR_T
    memcpy(buf, gcstr->str, sizeof(wchar_t) * len);
#else /* SOMBOK_UNICHAR_T_IS_WCHAR_T */
    for (i = 0; i < len; i++)
	buf[i] = (wchar_t) (gcstr->str[i]);
#endif /* SOMBOK_UNICHAR_T_IS_WCHAR_T */
    buf[len] = (wchar_t) 0;

    /*
     * Flag breaking points.
     * Note: th_wbrk() sometimes returns -1 when breaking positions weren't
     * found.
     */
    sa = 0;
    for (i = 0, j = 0; j < len && th_wbrk(buf + j, &brk, 1) == 1; j += brk) {
	/* check if external module is broken. */
	assert(0 <= brk);
	assert(brk < len);

	if (brk == 0) /* This should not cause but is caused by older libthai */
	    break;
	for (; i < gcstr->gclen && gcstr->gcstr[i].idx <= j + brk; i++) {
	    /* check if external module broke temp buffer. */
	    assert(buf[i] == (wchar_t) (gcstr->str[i]));

	    if (gcstr->gcstr[i].lbc == LB_SA) {
		if (!sa)
		    /* skip the first grapheme of each SA block. */
		    sa = 1;
		else if (gcstr->gcstr[i].flag)
		    /* already flagged by _prep(). */
		    ;
		else if (gcstr->gcstr[i].idx != j + brk)
		    /* not grapheme cluster boundary. */
		    ;
		else {
		    propval_t p = PROP_UNKNOWN;

		    linebreak_charprop(gcstr->lbobj,
			gcstr->str[gcstr->gcstr[i].idx - 1],
			&p, NULL, NULL, NULL);
		    /* bogus breaking by libthai on non-SA grapheme extender
		     * (e.g. CM SA). */
		    if (p == LB_SA)
			gcstr->gcstr[i].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
		}
	    } else
		sa = 0;
	}
    }

    free(buf);
#endif /* USE_LIBTHAI */
}
