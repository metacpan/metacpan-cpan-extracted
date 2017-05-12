/*
 * linebreak.c - implementation of Linebreak object.
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

/** @defgroup linebreak linebreak
 * @brief Handle linebreak object.
 *
 *@{*/

/** Constructor
 *
 * Creates new linebreak object.
 * Reference count of it will be set to 1.
 * @param[in] ref_func function to handle reference count of external objects,
 * or NULL.
 * @return New linebreak object.
 * If error occurred, errno is set then NULL is returned.
 */
linebreak_t *linebreak_new(linebreak_ref_func_t ref_func)
{
    linebreak_t *obj;
    if ((obj = malloc(sizeof(linebreak_t))) == NULL)
	return NULL;
    memset(obj, 0, sizeof(linebreak_t));

#ifdef USE_LIBTHAI
    obj->options = LINEBREAK_OPTION_COMPLEX_BREAKING;
#endif				/* USE_LIBTHAI */
    obj->ref_func = ref_func;
    obj->refcount = 1UL;
    return obj;
}

/** Increase Reference Count
 *
 * Increse reference count of linebreak object.
 * @param[in] obj linebreak object, must not be NULL.
 * @return linebreak object itself.
 * If error occurred, errno is set then NULL is returned.
 */
linebreak_t *linebreak_incref(linebreak_t * obj)
{
    obj->refcount += 1UL;
    return obj;
}

/** Copy Constructor
 *
 * Create deep copy of linebreak object.
 * Reference count of new object will be set to 1.
 * If ref_func member of object is not NULL, it will be executed to increase
 * reference count of prep_data, format_data, sizing_data, urgent_data and
 * stash members.
 * @param[in] obj linebreak object, must not be NULL.
 * @return New linebreak object.
 * If error occurred, errno is set then NULL is returned.
 */
linebreak_t *linebreak_copy(linebreak_t * obj)
{
    linebreak_t *newobj;
    mapent_t *newmap;
    unichar_t *newstr;

    if (obj == NULL)
	return (errno = EINVAL), NULL;
    if ((newobj = malloc(sizeof(linebreak_t))) == NULL)
	return NULL;
    memcpy(newobj, obj, sizeof(linebreak_t));

    if (obj->map != NULL && obj->mapsiz) {
	if ((newmap = malloc(sizeof(mapent_t) * obj->mapsiz)) == NULL) {
	    free(newobj);
	    return NULL;
	}
	memcpy(newmap, obj->map, sizeof(mapent_t) * obj->mapsiz);
	newobj->map = newmap;
    } else
	newobj->map = NULL;

    if (obj->newline.str != NULL && obj->newline.len) {
	if ((newstr =
	     malloc(sizeof(unichar_t) * obj->newline.len)) == NULL) {
	    free(newobj->map);
	    free(newobj);
	    return NULL;
	}
	memcpy(newstr, obj->newline.str,
	       sizeof(unichar_t) * obj->newline.len);
	newobj->newline.str = newstr;
    } else
	newobj->newline.str = NULL;

    if (obj->bufstr.str != NULL && obj->bufstr.len) {
	if ((newstr = malloc(sizeof(unichar_t) * obj->bufstr.len)) == NULL) {
	    free(newobj->map);
	    free(newobj->newline.str);
	    free(newobj);
	    return NULL;
	}
	memcpy(newstr, obj->bufstr.str,
	       sizeof(unichar_t) * obj->bufstr.len);
	newobj->bufstr.str = newstr;
    } else
	newobj->bufstr.str = NULL;

    if (obj->bufspc.str != NULL && obj->bufspc.len) {
	if ((newstr = malloc(sizeof(unichar_t) * obj->bufspc.len)) == NULL) {
	    free(newobj->map);
	    free(newobj->newline.str);
	    free(newobj->bufstr.str);
	    free(newobj);
	    return NULL;
	}
	memcpy(newstr, obj->bufspc.str,
	       sizeof(unichar_t) * obj->bufspc.len);
	newobj->bufspc.str = newstr;
    } else
	newobj->bufspc.str = NULL;

    if (obj->unread.str != NULL && obj->unread.len) {
	if ((newstr = malloc(sizeof(unichar_t) * obj->unread.len)) == NULL) {
	    free(newobj->map);
	    free(newobj->newline.str);
	    free(newobj->bufstr.str);
	    free(newobj->bufspc.str);
	    free(newobj);
	    return NULL;
	}
	memcpy(newstr, obj->unread.str,
	       sizeof(unichar_t) * obj->unread.len);
	newobj->unread.str = newstr;
    } else
	newobj->unread.str = NULL;

    if (obj->prep_func != NULL) {
	size_t i;
	for (i = 0; obj->prep_func[i] != NULL; i++);
	if ((newobj->prep_func =
	     malloc(sizeof(linebreak_prep_func_t) * (i + 1)))
	    == NULL) {
	    free(newobj->map);
	    free(newobj->newline.str);
	    free(newobj->bufstr.str);
	    free(newobj->bufspc.str);
	    free(newobj->unread.str);
	    free(newobj);
	    return NULL;
	}
	memcpy(newobj->prep_func, obj->prep_func,
	       sizeof(linebreak_prep_func_t) * (i + 1));
	if ((newobj->prep_data = malloc(sizeof(void *) * (i + 1))) == NULL) {
	    free(newobj->map);
	    free(newobj->newline.str);
	    free(newobj->bufstr.str);
	    free(newobj->bufspc.str);
	    free(newobj->unread.str);
	    free(newobj->prep_func);
	    free(newobj);
	    return NULL;
	}
	if (obj->prep_data == NULL)
	    memset(newobj->prep_data, 0, sizeof(void *) * (i + 1));
	else
	    memcpy(newobj->prep_data, obj->prep_data,
		   sizeof(void *) * (i + 1));
    }

    if (newobj->ref_func != NULL) {
	if (newobj->stash != NULL)
	    (*newobj->ref_func) (newobj->stash, LINEBREAK_REF_STASH, +1);
	if (newobj->format_data != NULL)
	    (*newobj->ref_func) (newobj->format_data, LINEBREAK_REF_FORMAT,
				 +1);
	if (newobj->prep_data != NULL) {
	    size_t i;
	    for (i = 0; newobj->prep_func[i] != NULL; i++)
		if (newobj->prep_data[i] != NULL)
		    (*newobj->ref_func) (newobj->prep_data[i],
					 LINEBREAK_REF_PREP, +1);
	}
	if (newobj->sizing_data != NULL)
	    (*newobj->ref_func) (newobj->sizing_data, LINEBREAK_REF_SIZING,
				 +1);
	if (newobj->urgent_data != NULL)
	    (*newobj->ref_func) (newobj->urgent_data, LINEBREAK_REF_URGENT,
				 +1);
	if (newobj->user_data != NULL)
	    (*newobj->ref_func) (newobj->user_data, LINEBREAK_REF_USER,
				 +1);
    }

    newobj->refcount = 1UL;
    return newobj;
}

/** Decrease Reference Count; Destructor
 *
 * Decrement reference count of linebreak object.
 * When reference count becomes zero, free memories allocated for
 * object and then, if ref_func member of object was not NULL,
 * it will be executed to decrease reference count of prep_data, format_data,
 * sizing_data, urgent_data and stash members.
 * @param[in] obj linebreak object.
 * @return none.
 * If obj was NULL, do nothing.
 */
void linebreak_destroy(linebreak_t * obj)
{
    if (obj == NULL)
	return;
    if ((obj->refcount -= 1UL))
	return;
    free(obj->map);
    free(obj->newline.str);
    free(obj->bufstr.str);
    free(obj->bufspc.str);
    free(obj->unread.str);
    if (obj->ref_func != NULL) {
	if (obj->stash != NULL)
	    (*obj->ref_func) (obj->stash, LINEBREAK_REF_STASH, -1);
	if (obj->format_data != NULL)
	    (*obj->ref_func) (obj->format_data, LINEBREAK_REF_FORMAT, -1);
	if (obj->prep_func != NULL) {
	    size_t i;
	    for (i = 0; obj->prep_func[i] != NULL; i++)
		if (obj->prep_data[i] != NULL)
		    (*obj->ref_func) (obj->prep_data[i],
				      LINEBREAK_REF_PREP, -1);
	}
	if (obj->sizing_data != NULL)
	    (*obj->ref_func) (obj->sizing_data, LINEBREAK_REF_SIZING, -1);
	if (obj->urgent_data != NULL)
	    (*obj->ref_func) (obj->urgent_data, LINEBREAK_REF_URGENT, -1);
	if (obj->user_data != NULL)
	    (*obj->ref_func) (obj->user_data, LINEBREAK_REF_USER, -1);
    }
    free(obj->prep_func);
    free(obj->prep_data);
    free(obj);
}

/** Setter: Update newline member
 *
 * @param[in] lbobj target linebreak object, must not be NULL.
 * @param[in] newline pointer to Unicode string.
 * @return none.
 * Copy of newline is set.
 * If error occurred, lbobj->errnum is set.
 */
void linebreak_set_newline(linebreak_t * lbobj, unistr_t * newline)
{
    unichar_t *str;
    size_t len;

    if (newline != NULL && newline->str != NULL && newline->len != 0) {
	if ((str = malloc(sizeof(unichar_t) * newline->len)) == NULL) {
	    lbobj->errnum = errno ? errno : ENOMEM;
	    return;
	}
	memcpy(str, newline->str, sizeof(unichar_t) * newline->len);
	len = newline->len;
    } else {
	str = NULL;
	len = 0;
    }
    free(lbobj->newline.str);
    lbobj->newline.str = str;
    lbobj->newline.len = len;
}

/** Setter: Update stash Member
 *
 * @param[in] lbobj target linebreak object, must not be NULL.
 * @param[in] stash new stash value or NULL.
 * @return none.
 * New stash value is set.
 * Reference count of stash member will be handled appropriately.
 */
void linebreak_set_stash(linebreak_t * lbobj, void *stash)
{
    if (lbobj->ref_func != NULL) {
	if (stash != NULL)
	    (*(lbobj->ref_func)) (stash, LINEBREAK_REF_STASH, +1);
	if (lbobj->stash != NULL)
	    (*(lbobj->ref_func)) (lbobj->stash, LINEBREAK_REF_STASH, -1);
    }
    lbobj->stash = stash;
}

/** Setter: Update format_func/format_data Member
 *
 * @param[in] lbobj target linebreak object.
 * @param[in] format_func format callback function or NULL.
 * @param[in] format_data new format_data value.
 * @return none.
 * New format callback is set.
 * Reference count of format_data member will be handled appropriately.
 */
void linebreak_set_format(linebreak_t * lbobj,
			  linebreak_format_func_t format_func,
			  void *format_data)
{
    if (lbobj->ref_func != NULL) {
	if (format_data != NULL)
	    (*(lbobj->ref_func)) (format_data, LINEBREAK_REF_FORMAT, +1);
	if (lbobj->format_data != NULL)
	    (*(lbobj->ref_func)) (lbobj->format_data, LINEBREAK_REF_FORMAT,
				  -1);
    }
    lbobj->format_func = format_func;
    lbobj->format_data = format_data;
}

/** Setter: Add/clear prep_func/prep_data Member
 *
 * @param[in] lbobj target linebreak object.
 * @param[in] prep_func preprocessing callback function or NULL.
 * @param[in] prep_data new prep_data value.
 * @return none.
 * New preprocessing callback is added.
 * Reference count of prep_data item will be handled appropriately.
 * if prep_func was NULL, all data are cleared.
 */
void linebreak_add_prep(linebreak_t * lbobj,
			linebreak_prep_func_t prep_func, void *prep_data)
{
    size_t i;
    linebreak_prep_func_t *p;
    void **q;

    if (prep_func == NULL) {
	if (lbobj->prep_data != NULL) {
	    for (i = 0; lbobj->prep_func[i] != NULL; i++)
		if (lbobj->prep_data[i] != NULL)
		    (*lbobj->ref_func) (lbobj->prep_data[i],
					LINEBREAK_REF_PREP, -1);
	    free(lbobj->prep_data);
	    lbobj->prep_data = NULL;
	}
	free(lbobj->prep_func);
	lbobj->prep_func = NULL;
	return;
    }

    if (lbobj->prep_func == NULL)
	i = 0;
    else
	for (i = 0; lbobj->prep_func[i] != NULL; i++);

    if ((p =
	 realloc(lbobj->prep_func,
		 sizeof(linebreak_prep_func_t) * (i + 2)))
	== NULL) {
	lbobj->errnum = errno;
	return;
    }
    p[i] = NULL;
    lbobj->prep_func = p;

    if ((q = realloc(lbobj->prep_data, sizeof(void *) * (i + 2))) == NULL) {
	lbobj->errnum = errno;
	return;
    }
    lbobj->prep_data = q;

    if (lbobj->ref_func != NULL && prep_data != NULL)
	(*(lbobj->ref_func)) (prep_data, LINEBREAK_REF_PREP, +1);
    p[i] = prep_func;
    p[i + 1] = NULL;
    q[i] = prep_data;
    q[i + 1] = NULL;
}

/** Setter: Update sizing_func/sizing_data Member
 *
 * @param[in] lbobj target linebreak object.
 * @param[in] sizing_func sizing callback function or NULL.
 * @param[in] sizing_data new sizing_data value.
 * @return none.
 * New sizing callback is set.
 * Reference count of sizing_data member will be handled appropriately.
 */
void linebreak_set_sizing(linebreak_t * lbobj,
			  linebreak_sizing_func_t sizing_func,
			  void *sizing_data)
{
    if (lbobj->ref_func != NULL) {
	if (sizing_data != NULL)
	    (*(lbobj->ref_func)) (sizing_data, LINEBREAK_REF_SIZING, +1);
	if (lbobj->sizing_data != NULL)
	    (*(lbobj->ref_func)) (lbobj->sizing_data, LINEBREAK_REF_SIZING,
				  -1);
    }
    lbobj->sizing_func = sizing_func;
    lbobj->sizing_data = sizing_data;
}

/** Setter: Update urgent_func/urgent_data Member
 *
 * @param[in] lbobj target linebreak object.
 * @param[in] urgent_func urgent breaking callback function or NULL.
 * @param[in] urgent_data new urgent_data value.
 * @return none.
 * New urgent breaking callback is set.
 * Reference count of urgent_data member will be handled appropriately.
 */
void linebreak_set_urgent(linebreak_t * lbobj,
			  linebreak_urgent_func_t urgent_func,
			  void *urgent_data)
{
    if (lbobj->ref_func != NULL) {
	if (urgent_data != NULL)
	    (*(lbobj->ref_func)) (urgent_data, LINEBREAK_REF_URGENT, +1);
	if (lbobj->urgent_data != NULL)
	    (*(lbobj->ref_func)) (lbobj->urgent_data, LINEBREAK_REF_URGENT,
				  -1);
    }
    lbobj->urgent_func = urgent_func;
    lbobj->urgent_data = urgent_data;
}

/** Setter: Update user_func/user_data Member
 * @deprecated Use linebreak_add_prep() instead.
 *
 * @param[in] lbobj target linebreak object.
 * @param[in] user_func preprocessing callback function or NULL.
 * @param[in] user_data new user_data value.
 * @return none.
 * New preprocessing callback is set.
 * Reference count of user_data member will be handled appropriately.
 */
void linebreak_set_user(linebreak_t * lbobj,
			linebreak_obs_prep_func_t user_func,
			void *user_data)
{
    if (lbobj->ref_func != NULL) {
	if (user_data != NULL)
	    (*(lbobj->ref_func)) (user_data, LINEBREAK_REF_USER, +1);
	if (lbobj->user_data != NULL)
	    (*(lbobj->ref_func)) (lbobj->user_data, LINEBREAK_REF_USER,
				  -1);
    }
    lbobj->user_func = user_func;
    lbobj->user_data = user_data;
}

/** Reset State
 *
 * Reset internal state of linebreak object.
 * Internal state is set by linebreak_break_partial() function.
 * @param[in] lbobj linebreak object.
 * @return none.
 * If lbobj was NULL, do nothing.
 */
void linebreak_reset(linebreak_t * lbobj)
{
    if (lbobj == NULL)
	return;
    free(lbobj->unread.str);
    lbobj->unread.str = NULL;
    lbobj->unread.len = 0;
    free(lbobj->bufstr.str);
    lbobj->bufstr.str = NULL;
    lbobj->bufstr.len = 0;
    free(lbobj->bufspc.str);
    lbobj->bufspc.str = NULL;
    lbobj->bufspc.len = 0;
    lbobj->bufcols = 0.0;
    lbobj->state = LINEBREAK_STATE_NONE;
    lbobj->errnum = 0;
}

/** Get breaking rule between two classes
 *
 * From given two line breaking classes, get breaking rule determined by
 * internal data.
 * @param[in] obj linebreak object, must not be NULL.
 * @param[in] albc line breaking class.
 * @param[in] blbc line breaking class.
 * @return line breaking action: MANDATORY, DIRECT, INDIRECT or PROHIBITED.
 * If action was not determined, returns DIRECT.
 *
 * @note This method gives just approximate description of line breaking
 * behavior.  Class AI and CJ will be resolved to approppriate classes.
 * See also linebreak_lbrule().
 *
 * @note This method was introduced by Sombok 2.0.6. 
 * @note LEGACY_CM and HANGUL_AS_AL options are concerned as of Sombok 2.1.2.
 * @note Only HANGUL_AS_AL is concerned as of Sombok 2.2.
 *
 */
propval_t linebreak_get_lbrule(linebreak_t * obj, propval_t blbc,
			       propval_t albc)
{
    switch (blbc) {
    case LB_AI:
	blbc = (obj->options & LINEBREAK_OPTION_EASTASIAN_CONTEXT) ?
	    LB_ID : LB_AL;
	break;
    case LB_CJ:
	blbc = (obj->options & LINEBREAK_OPTION_NONSTARTER_LOOSE) ?
	    LB_ID : LB_NS;
	break;
    /* Optionally, treat hangul syllable as if it were AL. */
    case LB_H2:
    case LB_H3:
    case LB_JL:
    case LB_JV:
    case LB_JT:
	if ((albc == LB_H2 || albc == LB_H3 || albc == LB_JL ||
	     albc == LB_JV || albc == LB_JT) &&
	    obj->options & LINEBREAK_OPTION_HANGUL_AS_AL)
	    return LINEBREAK_ACTION_INDIRECT;
	break;
    }

    switch (albc) {
    case LB_AI:
	albc = (obj->options & LINEBREAK_OPTION_EASTASIAN_CONTEXT) ?
	    LB_ID : LB_AL;
	break;
    case LB_CJ:
	albc = (obj->options & LINEBREAK_OPTION_NONSTARTER_LOOSE) ?
	    LB_ID : LB_NS;
	break;
    }

    return linebreak_lbrule(blbc, albc);
}

/** Get Line Breaking Class
 * @deprecated Use gcstring_lbclass() or gcstring_lbclass_ext() instead.
 *
 * Get UAX #14 line breaking class of Unicode character.
 * Classes XX and SG will be resolved to AL.
 * @param[in] obj linebreak object, must not be NULL.
 * @param[in] c Unicode character.
 * @return line breaking class property value.
 */
propval_t linebreak_lbclass(linebreak_t * obj, unichar_t c)
{
    propval_t lbc, gcb, scr;

    linebreak_charprop(obj, c, &lbc, NULL, &gcb, &scr);
    if (lbc == LB_AI)
	lbc = (obj->options & LINEBREAK_OPTION_EASTASIAN_CONTEXT) ?
	    LB_ID : LB_AL;
    else if (lbc == LB_CJ)
	lbc = (obj->options & LINEBREAK_OPTION_NONSTARTER_LOOSE) ?
	    LB_ID : LB_NS;
    else if (lbc == LB_SA) {
#ifdef USE_LIBTHAI
	if (scr != SC_Thai)
#endif				/* USE_LIBTHAI */
	    lbc = (gcb == GB_Extend || gcb == GB_SpacingMark
		   || gcb == GB_Virama) ? LB_CM : LB_AL;
    }
    return lbc;
}

/** Get East_Asian_Width Property
 * @deprecated Use gcstring_columns() instead.
 *
 * Get UAX #11 East_Asian_Width property value of Unicode character.
 * Class A will be resolved to appropriate property F or N.
 * @param[in] obj linebreak object, must not be NULL.
 * @param[in] c Unicode character.
 * @return East_Asian_Width property value.
 */
propval_t linebreak_eawidth(linebreak_t * obj, unichar_t c)
{
    propval_t eaw;

    linebreak_charprop(obj, c, NULL, &eaw, NULL, NULL);
    if (eaw == EA_A)
	eaw = (obj->options & LINEBREAK_OPTION_EASTASIAN_CONTEXT) ?
	    EA_F : EA_N;

    return eaw;
}
