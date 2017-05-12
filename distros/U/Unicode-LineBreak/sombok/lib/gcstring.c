/*
 * gcstring.c - implementation of grapheme cluster string.
 * 
 * Copyright (C) 2009-2012 by Hatuka*nezumi - IKEDA Soji.
 *
 * This file is part of the Sombok Package.  This program is free
 * software; you can redistribute it and/or modify it under the terms of
 * either the GNU General Public License or the Artistic License, as
 * specified in the README file.
 *
 */

#include "sombok_constants.h"
#include "sombok.h"

/** @defgroup gcstring gcstring
 * @brief Grapheme cluster string
 *@{*/

#define eaw2col(o, e) \
    ((e) == EA_A ? \
     (((o)->options & LINEBREAK_OPTION_EASTASIAN_CONTEXT) ? 2 : 1) : \
     (((e) == EA_F || (e) == EA_W)? 2: \
     (((e) == EA_Z || (e) == EA_ZA || (e) == EA_ZW)? 0: 1)))
#define IS_EXTENDER(g) \
    ((g) == GB_Extend || (g) == GB_SpacingMark || (g) == GB_Virama)

static
void _gcinfo(linebreak_t * obj, unistr_t * str, size_t pos, gcchar_t * gc)
{
    propval_t glbc = PROP_UNKNOWN, elbc = PROP_UNKNOWN;
    size_t glen, gcol, pcol, ecol;
    propval_t lbc, eaw, gcb, ngcb, scr;

    if (!str || !str->str || !str->len) {
	gc->len = 0;
	gc->col = 0;
	gc->lbc = PROP_UNKNOWN;
	gc->elbc = PROP_UNKNOWN;
	return;
    }

    linebreak_charprop(obj, str->str[pos], &lbc, &eaw, &gcb, &scr);
    pos++;
    glen = 1;

    if (gcb == GB_V || gcb == GB_T)
	/* isolated hangul jamo is wide, though part of them are
	 * neutral (N). */
	gcol = 2;
    else
	gcol = eaw2col(obj, eaw);

    if (lbc != LB_SA)
	glbc = lbc;
#ifdef USE_LIBTHAI
    else if (scr == SC_Thai)
	glbc = lbc;
#endif				/* USE_LIBTHAI */
    else if (IS_EXTENDER(gcb))
	glbc = LB_CM;
    else
	glbc = LB_AL;

    switch (gcb) {
    case GB_LF:		/* GB5 */
	break;			/* switch (gcb) */

    case GB_CR:		/* GB3, GB4, GB5 */
	if (pos < str->len) {
	    linebreak_charprop(obj, str->str[pos], NULL, &eaw, &gcb, NULL);
	    if (gcb == GB_LF) {
		pos++;
		glen++;
		gcol += eaw2col(obj, eaw);
	    }
	}
	break;			/* switch (gcb) */

    case GB_Control:		/* GB4 */
	break;			/* switch (gcb) */

    default:
	pcol = 0;
	ecol = 0;
	while (pos < str->len) {	/* GB2 */
	    linebreak_charprop(obj, str->str[pos], &lbc, &eaw, &ngcb,
			       &scr);

	    /* Legacy-CM: Treat SP CM+ as if it were ID.  cf. [UAX #14] 9.1. */
	    if (glbc == LB_SP) {
		if ((obj->options & LINEBREAK_OPTION_LEGACY_CM) &&
		    IS_EXTENDER(ngcb) &&
		    (lbc == LB_CM || lbc == LB_SA)) {
		    glbc = LB_ID;

		    /* isolated "wide" nonspacing marks will be wide. */
		    if (eaw == EA_ZW &&
			(obj->options &
			 LINEBREAK_OPTION_WIDE_NONSPACING_W)) {
			if (gcol < 2)
			    gcol = 2;
		    }
#if 0 /* XXX */
		    else if (eaw == EA_ZA &&
			     (obj->options &
			      LINEBREAK_OPTION_WIDE_NONSPACING_A)) {
			if (gcol < 2)
			    gcol = 2;
		    }
#endif /* 0 */
		    else
			ecol += eaw2col(obj, eaw);
		} else
		    /* prevent degenerate case. */
		    break;	/* while (pos < str->len) */
	    }
	    /* GB5 */
	    else if (ngcb == GB_Control || ngcb == GB_CR || ngcb == GB_LF)
		break;		/* while (pos < str->len) */
	    /* GB6 - GB8 */
	    /*
	     * Assume hangul syllable block is always wide, while most of
	     * isolated junseong (gcb:V) and jongseong (gcb:T) are neutral
	     * (eaw:N).
	     */
	    else if ((gcb == GB_L &&
		      (ngcb == GB_L || ngcb == GB_V || ngcb == GB_LV ||
		       ngcb == GB_LVT)) ||
		     ((gcb == GB_LV || gcb == GB_V) &&
		      (ngcb == GB_V || ngcb == GB_T)) ||
		     ((gcb == GB_LVT || gcb == GB_T) && ngcb == GB_T)) {
		gcol = 2;
		elbc = lbc;
	    }
	    /* GB8a */
	    else if (gcb == GB_Regional_Indicator &&
		     ngcb == GB_Regional_Indicator) {
		gcol += ecol + eaw2col(obj, eaw);
		ecol = 0;
		elbc = lbc;
	    }
	    /* GB9, GB9a */
	    else if (IS_EXTENDER(ngcb)) {
		ecol += eaw2col(obj, eaw);
		/* CM in grapheme extender is ignored.  Virama is CM. */
		/* SA in g. ext. is resolved to CM so it is ignored. */
		if (lbc != LB_CM && lbc != LB_SA)
		    elbc = lbc;
	    }
	    /* GB9b */
	    else if (gcb == GB_Prepend) {
		/* Here, next char shall grapheme base (or additional prepend
		 * character), since its GCB property is neither Control,
		 * Extend, SpacingMark, and Virama */
		if (lbc != LB_SA)
		    elbc = lbc;
#ifdef USE_LIBTHAI
		else if (scr == SC_Thai)
		    elbc = lbc;	/* SA char in g. base is not resolved... */
#endif				/* USE_LIBTHAI */
		else
		    elbc = LB_AL;	/* ...or resolved to AL. */
		pcol += gcol;
		if (ngcb == GB_V || ngcb == GB_T)
		    /* isolated hangul jamo with prepend character, though
		     * it may be degenerate case. */
		    gcol = 2;
		else
		    gcol = eaw2col(obj, eaw);
	    }
	    /* Virama rule: \p{ccc:Virama} × \p{gc:Letter} */
	    else if (gcb == GB_Virama && ngcb == GB_OtherLetter &&
		     obj->options & LINEBREAK_OPTION_VIRAMA_AS_JOINER) {
		/* OtherLetter is not grapheme extender. */
		gcol += ecol + eaw2col(obj, eaw);
		ecol = 0;
		if (lbc != LB_SA)
		    elbc = lbc;
#ifdef USE_LIBTHAI
		else if (scr == SC_Thai)
		    elbc = lbc;	/* SA char in g. base is not resolved... */
#endif				/* USE_LIBTHAI */
		else
		    elbc = LB_AL;	/* ...or resolved to AL. */
	    }
	    /* GB10 */
	    else
		break;		/* while (pos < str->len) */

	    pos++;
	    glen++;
	    gcb = ngcb;
	}			/* while (pos < str->len) */
	gcol += pcol + ecol;
	break;			/* switch (gcb) */
    }				/* switch (gcb) */

    gc->len = glen;
    gc->col = gcol;
    gc->lbc = glbc;
    gc->elbc = elbc;
}

/*
 * Exports
 */

/** Constructor
 *
 * Create new grapheme cluster string from Unicode string.
 * Use gcstring_newcopy() if you wish to copy buffer of Unicode string.
 * @param[in] unistr Unicode string.  NULL may be given as zero-length string.
 * @param[in] lbobj linebreak object.
 * @return New grapheme cluster string sharing str buffer with unistr.
 * If error occurred, errno is set then NULL is returned.
 *
 * option bits of lbobj:
 * - if LINEBREAK_OPTION_EASTASIAN_CONTEXT bit is set,
 *   LB_AI and EA_A are resolved to LB_ID and EA_F. Otherwise, LB_AL and EA_N,
 *   respectively.
 * - if LINEBREAK_OPTION_LEGACY_CM bit is set,
 *   combining mark lead by a SPACE is isolated combining mark (ID).
 *   Otherwise, such sequences are treated as degenerate cases.
 * - if LINEBREAK_OPTION_VIRAMA_AS_JOINER bit is set,
 *   virama and other letter are not broken.
 */
gcstring_t *gcstring_new(unistr_t * unistr, linebreak_t * lbobj)
{
    gcstring_t *gcstr;
    size_t len;

    if ((gcstr = malloc(sizeof(gcstring_t))) == NULL)
	return NULL;
    gcstr->str = NULL;
    gcstr->len = 0;
    gcstr->gcstr = NULL;
    gcstr->gclen = 0;
    gcstr->pos = 0;
    if (lbobj == NULL) {
	if ((gcstr->lbobj = linebreak_new(NULL)) == NULL) {
	    free(gcstr);
	    return NULL;
	}
    } else
	gcstr->lbobj = linebreak_incref(lbobj);

    if (unistr == NULL || unistr->str == NULL || unistr->len == 0)
	return gcstr;
    gcstr->str = unistr->str;
    gcstr->len = len = unistr->len;

    if (len) {
	size_t pos;
	gcchar_t *gc, *_g;

	if ((gcstr->gcstr = malloc(sizeof(gcchar_t) * len)) == NULL) {
	    gcstr->str = NULL;
	    gcstring_destroy(gcstr);
	    return NULL;
	}
	for (pos = 0, gc = gcstr->gcstr;
	     pos < len;
	     pos += gc->len, gcstr->gclen++, gc++) {
	    gc->flag = 0;
	    gc->idx = pos;
	    _gcinfo(gcstr->lbobj, unistr, pos, gc);
	}
	if ((_g = realloc(gcstr->gcstr, sizeof(gcchar_t) * gcstr->gclen))
	    == NULL) {
	    gcstr->str = NULL;
	    gcstring_destroy(gcstr);
	    return NULL;
	} else
	    gcstr->gcstr = _g;
    }

    return gcstr;
}

/** Constructor copying Unicode string.
 *
 * Create new grapheme cluster string from Unicode string.
 * Use gcstring_new() if you wish not to copy buffer of Unicode string.
 * @param[in] str Unicode string.  NULL may be given as zero-length string.
 * @param[in] lbobj linebreak object.
 * @return New grapheme cluster string.
 * If error occurred, errno is set then NULL is returned.
 */
gcstring_t *gcstring_newcopy(unistr_t * str, linebreak_t * lbobj)
{
    unistr_t unistr = { NULL, 0 };

    if (str->str && str->len) {
	if ((unistr.str = malloc(sizeof(unichar_t) * str->len)) == NULL)
	    return NULL;
	memcpy(unistr.str, str->str, sizeof(unichar_t) * str->len);
	unistr.len = str->len;
    }
    return gcstring_new(&unistr, lbobj);
}

/** Constructor from UTF-8 string
 *
 * Create new grapheme cluster string from UTF-8 string.
 * @param[in] str buffer of UTF-8 string, must not be NULL.
 * @param[in] len length of UTF-8 string.
 * @param[in] check check input.  See sombok_decode_utf8().
 * @param[in] lbobj linebreak object.
 * @return New grapheme cluster string.
 * If error occurred, errno is set then NULL is returned.
 * Source string buffer would not be modified.
 */
gcstring_t *gcstring_new_from_utf8(char *str, size_t len, int check,
				   linebreak_t * lbobj)
{
    unistr_t unistr = { NULL, 0 };

    if (str == NULL) {
	errno = EINVAL;
	return NULL;
    }
    if (sombok_decode_utf8(&unistr, 0, str, len, check) == NULL)
	return NULL;

    return gcstring_new(&unistr, lbobj);
}

/** Destructor
 *
 * Free memories allocated for grapheme cluster string.
 * @param[in] gcstr grapheme cluster string.
 * @return none.
 * If gcstr was NULL, do nothing.
 */
void gcstring_destroy(gcstring_t * gcstr)
{
    if (gcstr == NULL)
	return;
    free(gcstr->str);
    free(gcstr->gcstr);
    linebreak_destroy(gcstr->lbobj);
    free(gcstr);
}

/** Copy Constructor
 *
 * Create deep copy of grapheme cluster string.
 * @param[in] gcstr grapheme cluster string, must not be NULL.
 * @return deep copy of grapheme cluster string.
 * If error occurred, errno is set then NULL is returned.
 */
gcstring_t *gcstring_copy(gcstring_t * gcstr)
{
    gcstring_t *new;
    unichar_t *newstr = NULL;
    gcchar_t *newgcstr = NULL;

    if (gcstr == NULL)
	return (errno = EINVAL), NULL;

    if ((new = malloc(sizeof(gcstring_t))) == NULL)
	return NULL;
    memcpy(new, gcstr, sizeof(gcstring_t));

    if (gcstr->str && gcstr->len) {
	if ((newstr = malloc(sizeof(unichar_t) * gcstr->len)) == NULL) {
	    free(new);
	    return NULL;
	}
	memcpy(newstr, gcstr->str, sizeof(unichar_t) * gcstr->len);
    }
    new->str = newstr;
    if (gcstr->gcstr && gcstr->gclen) {
	if ((newgcstr = malloc(sizeof(gcchar_t) * gcstr->gclen)) == NULL) {
	    free(new->str);
	    free(new);
	    return NULL;
	}
	memcpy(newgcstr, gcstr->gcstr, sizeof(gcchar_t) * gcstr->gclen);
    }
    new->gcstr = newgcstr;
    if (gcstr->lbobj == NULL) {
	if ((new->lbobj = linebreak_new(NULL)) == NULL) {
	    gcstring_destroy(new);
	    return NULL;
	}
    } else
	new->lbobj = linebreak_incref(gcstr->lbobj);
    new->pos = 0;

    return new;
}

/** Append
 *
 * Modify grapheme cluster string by appending another string.
 * @param[in] gcstr target grapheme cluster string, must not be NULL.
 * @param[in] appe grapheme cluster string to be appended.
 * NULL means null string therefore gcstr won't be modified.
 * @return Modified grapheme cluster string gcstr itself (not a copy).
 * If error occurred, errno is set then NULL is returned.
 */
gcstring_t *gcstring_append(gcstring_t * gcstr, gcstring_t * appe)
{
    unistr_t ustr = { NULL, 0 };

    if (gcstr == NULL)
	return (errno = EINVAL), NULL;
    if (appe == NULL || appe->str == NULL || appe->len == 0)
	return gcstr;
    if (gcstr->gclen && appe->gclen) {
	size_t aidx, alen, blen, newlen, newgclen, i;
	unsigned char bflag;
	gcstring_t *cstr;
	unichar_t *_u;
	gcchar_t *_g;

	aidx = gcstr->gcstr[gcstr->gclen - 1].idx;
	alen = gcstr->gcstr[gcstr->gclen - 1].len;
	blen = appe->gcstr[0].len;
	bflag = appe->gcstr[0].flag;

	if ((ustr.str = malloc(sizeof(unichar_t) * (alen + blen))) == NULL)
	    return NULL;
	memcpy(ustr.str, gcstr->str + aidx, sizeof(unichar_t) * alen);
	memcpy(ustr.str + alen, appe->str, sizeof(unichar_t) * blen);
	ustr.len = alen + blen;
	if ((cstr = gcstring_new(&ustr, gcstr->lbobj)) == NULL) {
	    free(ustr.str);
	    return NULL;
	}

	newlen = gcstr->len + appe->len;
	newgclen = gcstr->gclen - 1 + cstr->gclen + appe->gclen - 1;
	if ((_u = realloc(gcstr->str, sizeof(unichar_t) * newlen)) == NULL) {
	    gcstring_destroy(cstr);
	    return NULL;
	} else
	    gcstr->str = _u;
	if ((_g = realloc(gcstr->gcstr,
			  sizeof(gcchar_t) * newgclen)) == NULL) {
	    gcstring_destroy(cstr);
	    return NULL;
	} else
	    gcstr->gcstr = _g;
	memcpy(gcstr->str + gcstr->len, appe->str,
	       sizeof(unichar_t) * appe->len);
	for (i = 0; i < cstr->gclen; i++) {
	    gcchar_t *gc = gcstr->gcstr + gcstr->gclen - 1 + i;

	    gc->idx = cstr->gcstr[i].idx + aidx;
	    gc->len = cstr->gcstr[i].len;
	    gc->col = cstr->gcstr[i].col;
	    gc->lbc = cstr->gcstr[i].lbc;
	    gc->elbc = cstr->gcstr[i].elbc;
	    if (aidx + alen == gc->idx)	/* Restore flag if possible */
		gc->flag = bflag;
	}
	for (i = 1; i < appe->gclen; i++) {
	    gcchar_t *gc =
		gcstr->gcstr + gcstr->gclen - 1 + cstr->gclen + i - 1;
	    gc->idx = appe->gcstr[i].idx - blen + aidx + cstr->len;
	    gc->len = appe->gcstr[i].len;
	    gc->col = appe->gcstr[i].col;
	    gc->lbc = appe->gcstr[i].lbc;
	    gc->elbc = appe->gcstr[i].elbc;
	    gc->flag = appe->gcstr[i].flag;
	}

	gcstr->len = newlen;
	gcstr->gclen = newgclen;
	gcstring_destroy(cstr);
    } else if (appe->gclen) {
	if ((gcstr->str = malloc(sizeof(unichar_t) * appe->len)) == NULL)
	    return NULL;
	if ((gcstr->gcstr =
	     malloc(sizeof(gcchar_t) * appe->gclen)) == NULL) {
	    free(gcstr->str);
	    return NULL;
	}
	memcpy(gcstr->str, appe->str, sizeof(unichar_t) * appe->len);
	gcstr->len = appe->len;
	memcpy(gcstr->gcstr, appe->gcstr, sizeof(gcchar_t) * appe->gclen);
	gcstr->gclen = appe->gclen;

	gcstr->pos = 0;
    }

    return gcstr;
}

/** Compare
 *
 * Compare grapheme cluster strings.
 * @param[in] a grapheme cluster string.
 * @param[in] b grapheme cluster string.
 * @return positive, zero or negative value when a is greater, equal to, lesser than b, respectively.
 */
int gcstring_cmp(gcstring_t * a, gcstring_t * b)
{
    size_t i;

    if (!a->len || !b->len)
	return (a->len ? 1 : 0) - (b->len ? 1 : 0);
    for (i = 0; i < a->len && i < b->len; i++)
	if (a->str[i] != b->str[i])
	    return a->str[i] - b->str[i];
    return a->len - b->len;
}

/** Number of Columns
 *
 * Returns number of columns of grapheme cluster strings determined by built-in character database according to UAX #11.
 * @param[in] gcstr grapheme cluster string. NULL may mean null string.
 * @return Number of columns.
 */
size_t gcstring_columns(gcstring_t * gcstr)
{
    size_t col, i;

    if (gcstr == NULL)
	return 0;
    for (col = 0, i = 0; i < gcstr->gclen; i++)
	col += gcstr->gcstr[i].col;
    return col;
}

/** Concatenate
 *
 * Create new grapheme cluster string which is concatination of two strings.
 * @param[in] gcstr grapheme cluster string, must not be NULL.
 * @param[in] appe grapheme cluster string to be appended.  NULL means null
 * string.
 * @return New grapheme cluster string.
 * If error occurred, errno is set then NULL is returned.
 */
gcstring_t *gcstring_concat(gcstring_t * gcstr, gcstring_t * appe)
{
    gcstring_t *new;
    size_t pos;

    if (gcstr == NULL)
	return (errno = EINVAL), NULL;
    pos = gcstr->pos;
    if ((new = gcstring_copy(gcstr)) == NULL)
	return NULL;
    new->pos = pos;
    return gcstring_append(new, appe);
}

/** Iterator
 *
 * Returns pointer to next grapheme cluster of grapheme cluster string.
 * Next position will be incremented.
 * @param[in] gcstr grapheme cluster string.
 * @return Pointer to grapheme cluster.
 * If pointer was already at end of the string, NULL will be returned.
 */
gcchar_t *gcstring_next(gcstring_t * gcstr)
{
    if (gcstr->gclen <= gcstr->pos)
	return NULL;
    return gcstr->gcstr + (gcstr->pos++);
}

/** Set Next Position
 *
 * Set next position of grapheme cluster string.
 * @param[in] gcstr grapheme cluster string.
 * @param[in] pos New position.
 * @return none.
 * If pos is out of range of string, position won't be updated.
 *
 * @todo On next major release, pos would be ssize_t, not int.
 */
void gcstring_setpos(gcstring_t * gcstr, int pos)
{
    if (pos < 0)
	pos += gcstr->gclen;
    if (pos < 0 || gcstr->gclen < pos)
	return;
    gcstr->pos = pos;
}

/** Shrink
 *
 * Modify grapheme cluster string to shrink its length.
 * Length is specified by number of grapheme clusters.
 * @param[in] gcstr grapheme cluster string.
 * @param[in] length New length.
 * @return none.
 * If gcstr was NULL, do nothing.
 *
 * @todo On next major release, length would be ssize_t, not int.
 */
void gcstring_shrink(gcstring_t * gcstr, int length)
{
    if (gcstr == NULL)
	return;

    if (length < 0)
	length += gcstr->gclen;

    if (length <= 0) {
	free(gcstr->str);
	gcstr->str = NULL;
	gcstr->len = 0;
	free(gcstr->gcstr);
	gcstr->gcstr = NULL;
	gcstr->gclen = 0;
    } else if (gcstr->gclen <= length)
	return;
    else {
	gcstr->len = gcstr->gcstr[length].idx;
	gcstr->gclen = length;
    }
}

/** Substring
 *
 * Returns substring of grapheme cluster string.
 * Offset and length are specified by number of grapheme clusters.
 * @param[in] gcstr grapheme cluster string.  Must not be NULL.
 * @param[in] offset Offset of substring.
 * @param[in] length Length of substring.
 * @return (newly allocated) substring.
 * If error occurred, errno is set to non-zero then NULL is returned.
 *
 * @todo On next major release, offset and length would be ssize_t, not int.
 */
gcstring_t *gcstring_substr(gcstring_t * gcstr, int offset, int length)
{
    gcstring_t *new;
    size_t ulength, i;

    if (gcstr == NULL)
	return (errno = EINVAL), NULL;

    /* adjust offset. */
    if (offset < 0)
	offset += gcstr->gclen;
    if (offset < 0) {
	length += offset;
	offset = 0;
    }
    if (length < 0)
	length += gcstr->gclen - offset;

    if (length < 0 || gcstr->gclen < offset)	/* out of range */
	return gcstring_new(NULL, gcstr->lbobj);

    if (gcstr->gclen == offset)
	length = 0;
    else if (gcstr->gclen <= offset + length)
	length = gcstr->gclen - offset;

    /* create substring. */

    if (gcstr->gclen == offset)
	ulength = 0;
    else if (gcstr->gclen <= offset + length)
	ulength = gcstr->len - gcstr->gcstr[offset].idx;
    else
	ulength =
	    gcstr->gcstr[offset + length].idx - gcstr->gcstr[offset].idx;

    if ((new = gcstring_new(NULL, gcstr->lbobj)) == NULL)
	return NULL;

    if (ulength == 0);
    else if ((new->str = malloc(sizeof(unichar_t) * ulength)) == NULL) {
	gcstring_destroy(new);
	return NULL;
    }
    if (length == 0);
    else if ((new->gcstr = malloc(sizeof(gcchar_t) * length)) == NULL) {
	free(new->str);
	gcstring_destroy(new);
	return NULL;
    }
    if (ulength != 0)
	memcpy(new->str, gcstr->str + gcstr->gcstr[offset].idx,
	       sizeof(unichar_t) * ulength);
    new->len = ulength;
    for (i = 0; i < length; i++) {
	memcpy(new->gcstr + i, gcstr->gcstr + offset + i,
	       sizeof(gcchar_t));
	new->gcstr[i].idx -= gcstr->gcstr[offset].idx;
    }
    new->gclen = length;

    return new;
}

/** Replace substring
 *
 * Replace substring og grapheme cluster string.
 * Offset and length are specified by number of grapheme clusters.
 * @param[in,out] gcstr grapheme cluster string.  Must not be NULL.
 * @param[in] offset Offset of substring.
 * @param[in] length Length of substring.
 * offset and length must not be out of range.
 * @param[in] replacement If this was not NULL, modify grapheme cluster string by replacing substring with it.
 * @return modified gcstr itself (not a copy of it).
 * If error occurred, errno is set to non-zero then NULL is returned.
 *
 * @todo On next major release, offset and length would be ssize_t, not int.
 */
gcstring_t *gcstring_replace(gcstring_t * gcstr, int offset, int length,
			     gcstring_t * replacement)
{
    gcstring_t *tail;

    if (gcstr == NULL)
	return (errno = EINVAL), NULL;

    /* without replacement: meaningless. return immedately. */
    if (replacement == NULL)
	return gcstr;

    /* adjust offset. */
    if (offset < 0)
	offset += gcstr->gclen;
    if (offset < 0) {
	length += offset;
	offset = 0;
    }
    if (length < 0)
	length += gcstr->gclen - offset;

    if (length < 0 || gcstr->gclen < offset)	/* out of range */
	return (errno = EINVAL), NULL;

    if (gcstr->gclen == offset)
	length = 0;
    else if (gcstr->gclen <= offset + length)
	length = gcstr->gclen - offset;

    /* returns modified gcstr itself. */

    if ((tail = gcstring_substr(gcstr, offset + length,
				gcstr->gclen - (offset + length))) == NULL)
	return NULL;
    gcstring_shrink(gcstr, offset);
    if (gcstring_append(gcstr, replacement) == NULL) {
	gcstring_destroy(tail);
	return NULL;
    }
    if (gcstring_append(gcstr, tail) == NULL) {
	gcstring_destroy(tail);
	return NULL;
    }
    gcstring_destroy(tail);
    return gcstr;
}

/** Get Line Breaking Class of grapheme base
 *
 * Get UAX #14 line breaking class of grapheme base.
 * @param[in] gcstr grapheme cluster string, must not be NULL.
 * @param[in] pos position.
 * @return line breaking class property value.
 *
 * @note Introduced by sombok 2.2.
 */
propval_t gcstring_lbclass(gcstring_t * gcstr, int pos)
{
    if (pos < 0)
	pos += gcstr->gclen;
    if (pos < 0 || gcstr->gclen == 0 || gcstr->gclen <= pos)
	return PROP_UNKNOWN;
    return gcstr->gcstr[pos].lbc;
}

/** Get Line Breaking Class of grapheme extender
 *
 * Get UAX #14 line breaking class of grapheme extender.
 * If it is CM, get one of grapheme base.
 * @param[in] gcstr grapheme cluster string, must not be NULL.
 * @param[in] pos position.
 * @return line breaking class property value.
 *
 * @note Introduced by sombok 2.2.
 */
propval_t gcstring_lbclass_ext(gcstring_t * gcstr, int pos)
{
    propval_t lbc;

    if (pos < 0)
	pos += gcstr->gclen;
    if (pos < 0 || gcstr->gclen == 0 || gcstr->gclen <= pos)
	return PROP_UNKNOWN;
    if ((lbc = gcstr->gcstr[pos].elbc) == PROP_UNKNOWN)
	lbc = gcstr->gcstr[pos].lbc;
    return lbc;
}
