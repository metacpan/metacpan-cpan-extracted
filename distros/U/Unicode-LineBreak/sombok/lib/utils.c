/*
 * utls.c - Utility functions.
 * 
 * Copyright (C) 2009-2011 by Hatuka*nezumi - IKEDA Soji.
 *
 * This file is part of the Sombok Package.  This program is free
 * software; you can redistribute it and/or modify it under the terms of
 * either the GNU General Public License or the Artistic License, as
 * specified in the README file.
 *
 */

#include "sombok_constants.h"
#include "sombok.h"

/** @defgroup linebreak_utils utils
 * @brief Callback functions used by linebreak
 *@{*/

/** @name Preprocessing callback
 * gcstring_t *callback(linebreak_t *lbobj, void *data, unistr_t *str, unistr_t *text)
 *
 * Preprocessing behaviors specified by item of ``prep_func'' member of
 * linebreak_t.  Corresponding item of ``prep_data'' member can be used to
 * modify behavior.
 * @param[in] obj linebreak object.
 * @param[in] data an item of prep_data correspondig to callback.
 * @param[in,out] substr pointer to Unicode string.
 * @param[in] text whole text to be broken, or NULL.
 * @return This callback is past twice by each substring of text:
 *
 * On the first pass, when text is not NULL, it should return the first
 * occurrance in substr matching its criteria, update substr->str to be
 * matching position and substr->len to be length.  Otherwise, should set
 * NULL to substr->str.
 * Return value shall be discarded. 
 *
 * On the second pass, when text is NULL, it should return new grapheme
 * cluster string created from substr. Return value should not share
 * Unicode buffer with substr (i.e. use gcstring_newcopy()).
 *
 * If error occurred, callback must set lbobj->errnum nonzero then return NULL.
 */
/*@{*/

static
int startswith(unistr_t * unistr, size_t idx, char *str, size_t len,
	       int cs)
{
    size_t i;
    unichar_t uc, c;

    if (unistr->str == NULL)
	return 0;
    if (unistr->len - idx < len)
	return 0;
    for (i = 0; i < len; i++) {
	uc = unistr->str[idx + i];
	c = (unichar_t) str[i];
	if (!cs) {
	    if ((unichar_t) 'A' <= uc && uc <= (unichar_t) 'Z')
		uc += (unichar_t) ('a' - 'A');
	    if ((unichar_t) 'A' <= c && c <= (unichar_t) 'Z')
		c += (unichar_t) ('a' - 'A');
	}
	if (uc != c)
	    return 0;
    }
    return 1;
}

#define is(str, i, c)				\
    ((i) < (str)->len && (str)->str[i] == (c))

#define _is_alpha(s)						\
    (('a' <= (s) && (s) <= 'z') || ('A' <= (s) && (s) <= 'Z'))
#define is_alpha(str, i)				\
    ((i) < (str)->len && _is_alpha((str)->str[i]))

#define _is_digit(s)				\
    ('0' <= (s) && (s) <= '9')
#define is_digit(str, i)				\
    ((i) < (str)->len && _is_digit((str)->str[i]))

#define _is_hexdig(s)							\
    (_is_digit(s) || ('a' <= (s) && (s) <= 'f') || ('A' <= (s) && (s) <= 'F'))
#define is_hexdig(str, i)				\
    ((i) < (str)->len && _is_hexdig((str)->str[i]))

#define _is_sub_delim(s)						\
    ((s) == '!' || (s) == '$' || (s) == '&' || (s) == '\'' || (s) == '(' || \
     (s) == ')' || (s) == '*' || (s) == '+' || (s) == ',' || (s) == ';' || \
     (s) == '=')
#define is_sub_delim(str, i)				\
    ((i) < (str)->len && _is_sub_delim((str)->str[i]))

#define _is_unreserved(s)					\
    (_is_alpha(s) || _is_digit(s) ||				\
     (s) == '-' || (s) == '.' || (s) == '_' || (s) == '~')
#define is_unreserved(str, i)				\
    ((i) < (str)->len && _is_unreserved((str)->str[i]))

#define _is_pct_encoded(s)			\
    ((s) == '%' || _is_hexdig(s))
#define is_pct_encoded(str, i)					\
    ((i) < (str)->len && _is_pct_encoded((str)->str[i]))

#define _is_pchar(s)							\
    (_is_unreserved(s) || _is_pct_encoded(s) || _is_sub_delim(s) ||	\
     (s) == ':' || (s) == '@')
#define is_pchar(str, i)				\
     ((i) < (str)->len && _is_pchar((str)->str[i]))

/** Built-in preprocessing callback
 *
 * Built-in preprocessing callback to break or not to break URLs according to
 * some rules by Chicago Manual of Style 15th ed.
 * If data is NULL, prohibit break.
 * Otherwise, allow break by rule above.
 */
gcstring_t *linebreak_prep_URIBREAK(linebreak_t * lbobj, void *data,
				    unistr_t * str, unistr_t * text)
{
    gcstring_t *gcstr;
    size_t i;
    unichar_t *ptr;

    /* Pass I */

    if (text != NULL) {
	/*
	 * Search URL in str.
	 * Following code loosely refers RFC3986 but some practical
	 * assumptions are put:
	 *
	 * o Broken pct-encoded sequences (e.g. single "%") are allowed.
	 * o scheme names must end with alphanumeric, must be longer than
	 *   or equal to two octets, and must not contain more than one
	 *   non-alphanumeric ("+", "-" or ".").
	 * o URLs containing neither non-empty path, query part nor fragment
	 *   (e.g. "about:") are omitted: they are treated as ordinal words.
	 */
	for (ptr = NULL, i = 0; i < str->len; ptr = NULL, i++) {
	    int has_double_slash, has_authority, has_empty_path,
		has_no_query, has_no_fragment;
	    size_t alphadigit, nonalphadigit;

	    /* skip non-alpha. */
	    if (!is_alpha(str, i))
		continue;

	    ptr = str->str + i;

	    /* "url:" - case insensitive */
	    if (startswith(str, i, "url:", 4, 0))
		i += 4;

	    /* scheme */
	    if (is_alpha(str, i))
		i++;
	    else
		continue;

	    nonalphadigit = 0;
	    alphadigit = 1;
	    while (1) {
		if (is_alpha(str, i) || is_digit(str, i))
		    alphadigit++;
		else if (is(str, i, '+') || is(str, i, '-') || is(str, i, '.'))
		    nonalphadigit++;
		else
		    break;
		i++;
	    }
	    if (alphadigit < 2 || 1 < nonalphadigit ||
	        ! (is_digit(str, i - 1) || is_alpha(str, i - 1)))
		continue;

	    /* ":" */
	    if (is(str, i, ':'))
		i++;
	    else
		continue;

	    /* hier-part */
	    has_double_slash = 0;
	    has_authority = 0;
	    has_empty_path = 0;
	    has_no_query = 0;
	    has_no_fragment = 0;
	    if (startswith(str, i, "//", 2, 0)) {
		/* "//" */
		has_double_slash = 1;
		i += 2;

		/* authority - FIXME:syntax relaxed */
		if (is(str, i, '[') || is(str, i, ':') || is(str, i, '@') ||
		    is_unreserved(str, i) || is_pct_encoded(str, i) ||
		    is_sub_delim(str, i)) {
		    has_authority = 1;
		    i++;
		    while (is(str, i, '[') || is(str, i, ']') ||
			   is(str, i, ':') || is(str, i, '@') ||
			   is_unreserved(str, i) || is_pct_encoded(str, i) ||
			   is_sub_delim(str, i))
			i++;
		}
	    }

	    /* path */
	    if (has_double_slash) {
		if (has_authority)
		    goto path_abempty;
		else
		    goto path_absolute;
	    } /* else goto path_rootless; */

	    /* path_rootless: */
	    if (is_pchar(str, i)) { /* FIXME:path-noscheme not concerned */
		i++;
		while (is_pchar(str, i))
		    i++;
		goto path_abempty;
	    } else {
		has_empty_path = 1;
		goto path_empty;
	    }

	  path_absolute:
	    if (startswith(str, i, "//", 2, 0))
		continue;
	    else if (is(str, i, '/')) {
		i++;
		if (is_pchar(str, i)) {
		    i++;
		    while (is_pchar(str, i))
			i++;
		}
		goto path_abempty;
	    } else
		continue;

	  path_abempty:
	    if (is(str, i, '/')) {
		i++;
		while (is(str, i, '/') || is_pchar(str, i))
		    i++;
	    } /* else goto path_empty; */

	  path_empty:
	    ;

	    /* query */
	    if (is(str, i, '?')) {
		i++;
		while (is(str, i, '/') || is(str, i, '?') || is_pchar(str, i))
		    i++;
	    } else
		has_no_query = 1;

	    /* fragment */
	    if (is(str, i, '#')) {
		i++;
		while (is(str, i, '/') || is(str, i, '?') || is_pchar(str, i))
		    i++;
	    } else
		has_no_fragment = 1;

	    if (has_empty_path && has_no_query && has_no_fragment)
		continue;

	    break;
	}

	if (ptr != NULL)
	    str->len = i - (ptr - str->str);
	str->str = ptr;
	return NULL;
    }

    /* Pass II */

    if ((gcstr = gcstring_newcopy(str, lbobj)) == NULL) {
	lbobj->errnum = errno ? errno : ENOMEM;
	return NULL;
    }

    /* non-break URI. */
    if (data == NULL) {
	for (i = 1; i < gcstr->gclen; i++)
	    gcstr->gcstr[i].flag = LINEBREAK_FLAG_PROHIBIT_BEFORE;
	return gcstr;
    }

    /* break URI. */
    if (startswith((unistr_t *) gcstr, 0, "url:", 4, 0)) {
	gcstr->gcstr[4].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
	i = 5;
    } else
	i = 1;
    for (; i < gcstr->gclen; i++) {
	unichar_t u, v;
	u = gcstr->str[gcstr->gcstr[i - 1].idx];
	v = gcstr->str[gcstr->gcstr[i].idx];

	/*
	 * Some rules based on CMoS 15th ed.
	 * 17.11 1.1: [/] ÷ [^/]
	 * 17.11 2:   [-] ×
	 * 6.17 2:   [.] ×
	 * 17.11 1.2: ÷ [-~.,_?#%]
	 * 17.11 1.3: ÷ [=&]
	 * 17.11 1.3: [=&] ÷
	 * Default:  ALL × ALL
	 */
	if (u == '/' && v != '/')
	    gcstr->gcstr[i].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
	else if (u == '-' || u == '.')
	    gcstr->gcstr[i].flag = LINEBREAK_FLAG_PROHIBIT_BEFORE;
	else if (v == '-' || v == '~' || v == '.' || v == ',' ||
		 v == '_' || v == '?' || v == '#' || v == '%' ||
		 u == '=' || v == '=' || u == '&' || v == '&')
	    gcstr->gcstr[i].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
	else
	    gcstr->gcstr[i].flag = LINEBREAK_FLAG_PROHIBIT_BEFORE;
    }

    /* Won't break punctuations at end of matches. */
    for (i = gcstr->gclen - 1; 1 <= i; i--) {
	unichar_t u = gcstr->str[gcstr->gcstr[i].idx];
	if (gcstr->gcstr[i].flag == LINEBREAK_FLAG_ALLOW_BEFORE &&
	    (u == '"' || u == '.' || u == ':' || u == ';' || u == ',' ||
	     u == '>'))
	    gcstr->gcstr[i].flag = LINEBREAK_FLAG_PROHIBIT_BEFORE;
	else
	    break;
    }
    return gcstr;
}

/*@}*/

/** @name Sizing callback
 * double callback(linebreak_t *obj, double len, gcstring_t *pre, gcstring_t *spc, gcstring_t *str)
 *
 * Sizing behavior specified by ``sizing_func'' member of linebreak_t.
 * ``sizing_data'' member can be used to modify behavior.
 * @param[in] obj linebreak object.
 * @param[in] len Number of columns of preceding grapheme cluster string.
 * @param[in] pre Preceding grapheme cluster string.
 * @param[in] spc Trailing spaces of preceding string.
 * @param[in] str Appended grapheme cluster string.
 * @return number of columns of pre+spc+str.
 * If error occurred, callback must set lbobj->errnum nonzero then return NULL.
 */

/*@{*/

/** Built-in Sizing callback
 *
 * Built-in Sizing callback based on UAX #11.
 */
double linebreak_sizing_UAX11(linebreak_t * obj, double len,
			      gcstring_t * pre, gcstring_t * spc,
			      gcstring_t * str)
{
    gcstring_t *spcstr;

    if ((!spc || !spc->str || !spc->len) &&
	(!str || !str->str || !str->len))
	return len;

    if (!spc || !spc->str)
	spcstr = gcstring_copy(str);
    else if ((spcstr = gcstring_concat(spc, str)) == NULL)
	return -1.0;
    len += (double) gcstring_columns(spcstr);
    gcstring_destroy(spcstr);
    return len;
}

/*@}*/

/** @name Formatting callback
 * gcstring_t *callback(linebreak_t *lbobj, linebreak_state_t state, gcstring_t *gcstr)
 *
 * Formatting behaviors specified by ``format_func'' member of linebreak_t. 
 * ``formt_data'' member can be used to modify behavior.
 * @param[in] obj linebreak object.
 * @param[in] state state.
 * @param[in] gcstr text fragment.
 * @return new text fragment or, if no modification needed, NULL.
 * If error occurred, callback must set lbobj->errnum nonzero then return NULL.
 *
 * Following table describes behavior of built-in format callbacks.
 *
 * @verbatim
 * state| SIMPLE          | NEWLINE           | TRIM
 * -----+-----------------+-------------------+-------------------
 * SOT  |
 * SOP  |                       not modify
 * SOL  |
 * LINE |
 * EOL  | append newline  | replace by newline| replace by newline
 * EOP  | not modify      | replace by newline| remove SPACEs
 * EOT  | not modify      | replace by newline| remove SPACEs
 * ----------------------------------------------------------------
 * @endverbatim
 */

/*@{*/

/** Built-in formatting callback
 *
 */
gcstring_t *linebreak_format_SIMPLE(linebreak_t * lbobj,
				    linebreak_state_t state,
				    gcstring_t * gcstr)
{
    gcstring_t *t, *result;
    unistr_t unistr;

    switch (state) {
    case LINEBREAK_STATE_EOL:
	if ((result = gcstring_copy(gcstr)) == NULL)
	    return NULL;
	unistr.str = lbobj->newline.str;
	unistr.len = lbobj->newline.len;
	if ((t = gcstring_new(&unistr, lbobj)) == NULL)
	    return NULL;
	if (gcstring_append(result, t) == NULL) {
	    t->str = NULL;
	    gcstring_destroy(t);
	    return NULL;
	}
	t->str = NULL;
	gcstring_destroy(t);
	return result;

    default:
	errno = 0;
	return NULL;
    }
}

/** Built-in formatting callback
 *
 */
gcstring_t *linebreak_format_NEWLINE(linebreak_t * lbobj,
				     linebreak_state_t state,
				     gcstring_t * gcstr)
{
    gcstring_t *result;
    unistr_t unistr;

    switch (state) {
    case LINEBREAK_STATE_EOL:
    case LINEBREAK_STATE_EOP:
    case LINEBREAK_STATE_EOT:
	unistr.str = lbobj->newline.str;
	unistr.len = lbobj->newline.len;
	if ((result = gcstring_newcopy(&unistr, lbobj)) == NULL)
	    return NULL;
	return result;

    default:
	errno = 0;
	return NULL;
    }
}

/** Built-in formatting callback
 *
 */
gcstring_t *linebreak_format_TRIM(linebreak_t * lbobj,
				  linebreak_state_t state,
				  gcstring_t * gcstr)
{
    gcstring_t *result;
    unistr_t unistr = { NULL, 0 };
    size_t i;

    switch (state) {
    case LINEBREAK_STATE_EOL:
	unistr.str = lbobj->newline.str;
	unistr.len = lbobj->newline.len;
	if ((result = gcstring_newcopy(&unistr, lbobj)) == NULL)
	    return NULL;
	return result;

    case LINEBREAK_STATE_EOP:
    case LINEBREAK_STATE_EOT:
	if (gcstr->str == NULL || gcstr->len == 0) {
	    if ((result = gcstring_newcopy(&unistr, lbobj)) == NULL)
		return NULL;
	    return result;
	}
	for (i = 0; i < gcstr->gclen && gcstr->gcstr[i].lbc == LB_SP; i++);
	if ((result = gcstring_substr(gcstr, i, gcstr->gclen)) == NULL)
	    return NULL;
	return result;

    default:
	errno = 0;
	return NULL;
    }
}

/*@}*/

/** @name Urgent breaking callbacks
 * gcstring_t *callback(linebreak_t *lbobj, gcstring_t *str)
 *
 * Urgent breaking behaviors specified by ``urgent_func'' member of
 * linebreak_t. ``urgent_data'' member can be used to modify behavior.
 * @param[in] obj linebreak object.
 * @param[in] str text to be broken.
 * @return new text or, if no modification needed, NULL.
 * If error occurred, callback must set lbobj->errnum nonzero then return NULL.
 *
 * There are two built-in urgent breaking callbacks.
 */

/*@{*/

/** Built-in urgent brealing callback
 *
 * Abort processing.  lbobj->errnum is set to LINEBREAK_ELONG.
 */
gcstring_t *linebreak_urgent_ABORT(linebreak_t * lbobj, gcstring_t * str)
{
    lbobj->errnum = LINEBREAK_ELONG;
    return NULL;
}

/** Built-in urgent brealing callback
 *
 * Force breaking lines.
 */
gcstring_t *linebreak_urgent_FORCE(linebreak_t * lbobj, gcstring_t * str)
{
    gcstring_t *result, *s, empty = { NULL, 0, NULL, 0, 0, lbobj };

    if (!str || !str->len)
	return gcstring_new(NULL, lbobj);

    result = gcstring_new(NULL, lbobj);
    s = gcstring_copy(str);
    while (1) {
	size_t i;
	gcstring_t *t;
	double cols;

	for (i = 0; i < s->gclen; i++) {
	    t = gcstring_substr(s, 0, i + 1);
	    if (lbobj->sizing_func != NULL)
		cols =
		    (*(lbobj->sizing_func)) (lbobj, 0.0, &empty, &empty,
					     t);
	    else
		cols = (double) t->gclen;
	    gcstring_destroy(t);

	    if (lbobj->colmax < cols)
		break;
	}
	if (0 < i) {
	    t = gcstring_substr(s, 0, i);
	    if (t->gclen) {
		t->gcstr[0].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
		gcstring_append(result, t);
	    }
	    gcstring_destroy(t);
	    t = gcstring_substr(s, i, s->gclen - i);
	    gcstring_destroy(s);
	    s = t;

	    if (!s->gclen)
		break;
	} else {
	    if (s->gclen) {
		s->gcstr[0].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
		gcstring_append(result, s);
	    }
	    break;
	}
    }
    gcstring_destroy(s);
    return result;
}

/*@}*/

/** @name Preprocessing callbacks - obsoleted form
 * gcstring_t *callback(linebreak_t *lbobj, unistr_t *str)

 * Preprocessing behaviors specified by ``user_func'' member of linebreak_t. 
 * ``user_data'' member can be used to modify behavior.
 * @param[in] obj linebreak object.
 * @param[in] str Unicode string (not grapheme cluster string) to be processed.
 * @return new grapheme cluster string.  NULL means no data.
 * If error occurred, callback must set lbobj->errnum nonzero then return NULL.
 *
 * Currently no built-in preprocessing callbacks are defined.
 * NOTE: Feature of this callback described here is planned to be changed
 * by next release.
 */
