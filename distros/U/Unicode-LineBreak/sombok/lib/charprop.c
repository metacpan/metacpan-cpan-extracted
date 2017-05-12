/*
 * charprop.c - character property handling.
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

extern const unsigned short linebreak_prop_index[];
extern const propval_t linebreak_prop_array[];

#define BLKLEN (5)

/* CJK Ideographs */
static propval_t PROPENT_HAN[] = { LB_ID, EA_W, GB_Other, SC_Han };

/* Tags */
static propval_t PROPENT_TAG[] = { LB_CM, EA_Z, GB_Control, SC_Common };

/* Variation Selectors */
static propval_t PROPENT_VSEL[] = { LB_CM, EA_ZA, GB_Extend, SC_Inherited };

/* Private use - XX */
static propval_t PROPENT_PRIVATE[] = { LB_AL, EA_A, GB_Other, SC_Unknown };

/* Reserved or noncharacter - XX */
static propval_t PROPENT_RESERVED[] = { LB_AL, EA_N, GB_Control, SC_Unknown };

static void
_search_props(linebreak_t * obj, unichar_t c, propval_t * lbcptr,
	      propval_t * eawptr, propval_t * gcbptr)
{
    mapent_t *top, *bot, *cur;

    if (obj->map == NULL || obj->mapsiz == 0)
	return;

    top = obj->map;
    bot = obj->map + obj->mapsiz - 1;
    while (top <= bot) {
	cur = top + (bot - top) / 2;
	if (c < cur->beg)
	    bot = cur - 1;
	else if (cur->end < c)
	    top = cur + 1;
	else {
	    if (lbcptr)
		*lbcptr = cur->lbc;
	    if (eawptr)
		*eawptr = cur->eaw;

	    /* Complement unknown Grapheme_Cluster_Break property. */
	    if (gcbptr == NULL)
		break;
	    if (cur->gcb != PROP_UNKNOWN) {
		*gcbptr = cur->gcb;
		break;
	    }
	    switch (cur->lbc) {
	    case PROP_UNKNOWN:
		*gcbptr = PROP_UNKNOWN;
		break;
	    case LB_CR:
		*gcbptr = GB_CR;
		break;
	    case LB_LF:
		*gcbptr = GB_LF;
		break;
	    case LB_BK:
	    case LB_NL:
	    case LB_WJ:
	    case LB_ZW:
		*gcbptr = GB_Control;
		break;
	    case LB_CM:
		*gcbptr = GB_Extend;
		break;
	    case LB_H2:
		*gcbptr = GB_LV;
		break;
	    case LB_H3:
		*gcbptr = GB_LVT;
		break;
	    case LB_JL:
		*gcbptr = GB_L;
		break;
	    case LB_JV:
		*gcbptr = GB_V;
		break;
	    case LB_JT:
		*gcbptr = GB_T;
		break;
	    case LB_RI:
		*gcbptr = GB_Regional_Indicator;
		break;
	    default:
		*gcbptr = GB_Other;
		break;
	    }
	    break;
	}
    }

}

/** Search for character properties.
 *
 * @note this function is for internal use.
 * 
 * Configuration parameters of linebreak object:
 *
 * * map, mapsiz: custom property map overriding built-in map.
 *
 * @param[in] obj linebreak object.
 * @param[in] c Unicode character.
 * @param[out] lbcptr UAX #14 line breaking class.
 * @param[out] eawptr UAX #11 East_Asian_Width property value.
 * @param[out] gcbptr UAX #29 Grapheme_Cluster_Break property value.
 * @param[out] scrptr Script (limited to several scripts).
 * @return none.
 *
 * @note As of 2.2.0, LINEBREAK_OPTION_EASTASIAN_CONTEXT and
 * LINEBREAK_OPTION_NONSTARTER_LOOSE are not affect.
 */
void
linebreak_charprop(linebreak_t * obj, unichar_t c,
		   propval_t * lbcptr, propval_t * eawptr,
		   propval_t * gcbptr, propval_t * scrptr)
{
    propval_t lbc = PROP_UNKNOWN, eaw = PROP_UNKNOWN, gcb = PROP_UNKNOWN,
	scr = PROP_UNKNOWN, *ent;

    /*
     * First, search custom map using binary search.
     */
    _search_props(obj, c, &lbc, &eaw, &gcb);

    /*
     * Otherwise, search built-in ``compact array''.
     * About compact array see:
     * Gillam, Richard (2003). "Unicode Demystified: A Practical
     *   Programmer's Guide to the Encoding Standard". pp. 514ff.
     */
    if ((lbcptr && lbc == PROP_UNKNOWN) ||
	(eawptr && eaw == PROP_UNKNOWN) ||
	(gcbptr && gcb == PROP_UNKNOWN)) {
	if (c < 0x20000)
	    ent =
		linebreak_prop_array + (linebreak_prop_index[c >> BLKLEN] +
					(c & ((1 << BLKLEN) - 1))) * 4;
	else if (c <= 0x2FFFD || (0x30000 <= c && c <= 0x3FFFD))
	    ent = PROPENT_HAN;
	else if (c == 0xE0001 || (0xE0020 <= c && c <= 0xE007E) ||
		 c == 0xE007F)
	    ent = PROPENT_TAG;
	else if (0xE0100 <= c && c <= 0xE01EF)
	    ent = PROPENT_VSEL;
	else if ((0xF0000 <= c && c <= 0xFFFFD) ||
		 (0x100000 <= c && c <= 0x10FFFD))
	    ent = PROPENT_PRIVATE;
	else
	    ent = PROPENT_RESERVED;

	if (lbcptr && lbc == PROP_UNKNOWN)
	    lbc = ent[0];
	if (eawptr && eaw == PROP_UNKNOWN)
	    eaw = ent[1];
	if (gcbptr && gcb == PROP_UNKNOWN)
	    gcb = ent[2];
	if (scrptr)
	    scr = ent[3];
    }

    if (lbcptr)
	*lbcptr = lbc;
    if (eawptr)
	*eawptr = eaw;
    if (gcbptr)
	*gcbptr = gcb;
    if (scrptr)
	*scrptr = scr;
}

/** Find property from custom line breaking class map.
 * @ingroup linebreak
 * @param[in] obj linebreak object.
 * @param[in] c Unicode character.
 * @return property value.  If not found, PROP_UNKNOWN.
 */
propval_t linebreak_search_lbclass(linebreak_t * obj, unichar_t c)
{
    propval_t p = PROP_UNKNOWN;
    _search_props(obj, c, &p, NULL, NULL);
    return p;
}

/** Find property from custom East_Asian_Width map.
 * @ingroup linebreak
 * @param[in] obj linebreak object.
 * @param[in] c Unicode character.
 * @return property value.  If not found, PROP_UNKNOWN.
 */
propval_t linebreak_search_eawidth(linebreak_t * obj, unichar_t c)
{
    propval_t p = PROP_UNKNOWN;
    _search_props(obj, c, NULL, &p, NULL);
    return p;
}


#define SET_PROP(pos, prop) \
    do { \
	if (idx == 0) \
	    (pos)->lbc = (prop); \
	else if (idx == 1) \
	    (pos)->eaw = (prop); \
	else if (idx == 2) \
	    (pos)->gcb = (prop); \
	else if (idx == 3) \
	    (pos)->scr = (prop); \
	else { \
	    obj->errnum = EINVAL; \
	    return; \
	} \
    } while (0)

#define INSERT_CUR(new) \
    do { \
	mapent_t *m; \
	if ((m = realloc(map, sizeof(mapent_t) * (mapsiz + 1))) \
	    == NULL) { \
	    obj->errnum = errno ? errno : ENOMEM; \
	    return; \
	} \
	cur = m + (cur - map); \
	map = m; \
	if (cur < map + mapsiz) \
	    memmove(cur + 1, cur, \
		    sizeof(mapent_t) * (mapsiz - (cur - map))); \
	if ((new) != cur) \
	    memcpy(cur, (new), sizeof(mapent_t)); \
	mapsiz++; \
    } while (0)

#define DELETE_CUR \
    do { \
	if (cur < map + mapsiz - 1) \
	    memmove(cur, cur + 1, \
		    sizeof(mapent_t) * (mapsiz - (cur - map) - 1)); \
	mapsiz--; \
    } while (0)

#define MAP_EQ(x, y) \
    ((x)->lbc == (y)->lbc && (x)->eaw == (y)->eaw && \
     (x)->gcb == (y)->gcb && (x)->scr == (y)->scr)

static void
_add_prop(linebreak_t * obj, unichar_t beg, unichar_t end,
	  propval_t p, int idx)
{
    mapent_t *map, *top, *bot, *cur = NULL;
    mapent_t newmap = { beg, end,
	PROP_UNKNOWN, PROP_UNKNOWN, PROP_UNKNOWN, PROP_UNKNOWN
    };
    size_t mapsiz;
    unichar_t beg_cont = (unichar_t) (-1), end_cont = (unichar_t) (-1);
#if 0
    unichar_t b = beg, e = end;
#endif

    /* assert(beg <= end); */
    /* assert(0 <= idx && idx < 4); */
    if (p == PROP_UNKNOWN) {
	obj->errnum = EINVAL;
	return;
    }

    SET_PROP(&newmap, p);

    /* no maps */
    if (obj->map == NULL || obj->mapsiz == 0) {
	if (obj->map == NULL &&
	    (obj->map = malloc(sizeof(mapent_t))) == NULL) {
	    obj->errnum = errno ? errno : ENOMEM;
	    return;
	}
	memcpy(obj->map, &newmap, sizeof(mapent_t));
	obj->mapsiz = 1;
	return;
    }

    map = obj->map;
    mapsiz = obj->mapsiz;

    /* first, seek map */
    top = map;
    bot = map + mapsiz - 1;
    while (top <= bot) {
	cur = top + (bot - top) / 2;
	if (beg < cur->beg)
	    bot = cur - 1;
	else if (cur->end < beg)
	    top = cur + 1;
	else
	    break;
    }

    while (1) {
	if (cur < map + mapsiz && cur->end < beg)
	    cur++;

	if (map + mapsiz <= cur) {	/* at tail of map */
	    cur = map + mapsiz;
	    if ((cur - 1)->end + 1 == beg && MAP_EQ((cur - 1), &newmap))
		(cur - 1)->end = end;
	    else
		INSERT_CUR(&newmap);
	    break;
	}

	if (beg < cur->beg) {	/* in gap of existing map */
	    if (cur->beg <= end) {
		beg_cont = cur->beg;
		end_cont = end;
		end = newmap.end = cur->beg - 1;
	    }

	    if (end + 1 == cur->beg && MAP_EQ(cur, &newmap))
		cur->beg = beg;
	    else
		INSERT_CUR(&newmap);
	} else {		/* otherwise */
	    if (cur->end < end) {
		beg_cont = cur->end + 1;
		end_cont = end;
		end = newmap.end = cur->end;
	    }

	    newmap.lbc = cur->lbc;
	    newmap.eaw = cur->eaw;
	    newmap.gcb = cur->gcb;
	    newmap.scr = cur->scr;
	    SET_PROP(&newmap, p);

	    if (MAP_EQ(cur, &newmap))
		/* noop */ ;
	    else if (beg == cur->beg && end == cur->end) {
		SET_PROP(cur, p);
		if (cur + 1 < map + mapsiz &&
		    cur->end + 1 == (cur + 1)->beg &&
		    MAP_EQ(cur, cur + 1)) {
		    (cur + 1)->beg = cur->beg;
		    DELETE_CUR;
		}
	    } else if (beg == cur->beg) {
		cur->beg = end + 1;
		INSERT_CUR(&newmap);
	    } else if (end == cur->end) {
		cur->end = beg - 1;
		cur++;
		INSERT_CUR(&newmap);
		cur++;
	    } else {
		INSERT_CUR(cur);
		cur->end = beg - 1;
		(cur + 1)->beg = end + 1;
		cur++;
		INSERT_CUR(&newmap);
	    }
	}

	if (map < cur && cur < map + mapsiz &&
	    (cur - 1)->end + 1 == cur->beg && MAP_EQ(cur - 1, cur)) {
	    (cur - 1)->end = cur->end;
	    DELETE_CUR;
	    cur--;
	}

	if (beg_cont == (unichar_t) (-1))
	    break;		/* while (1) */

	beg = newmap.beg = beg_cont;
	end = newmap.end = end_cont;
	beg_cont = (unichar_t) (-1);
	newmap.lbc = newmap.eaw = newmap.gcb = newmap.scr = PROP_UNKNOWN;
	SET_PROP(&newmap, p);
    }				/* while (1) */

    obj->map = map;
    obj->mapsiz = mapsiz;

#if 0
    {
	size_t i;
	mapent_t null_map =
	    { 0, 0, PROP_UNKNOWN, PROP_UNKNOWN, PROP_UNKNOWN,
	    PROP_UNKNOWN
	};
	unichar_t c;

	for (i = 0; i < mapsiz; i++) {
	    assert(!MAP_EQ(map + i, &null_map));
	    assert(map[i].beg <= map[i].end);
	    if (i == 0)
		continue;
	    assert(map[i - 1].end < map[i].beg);
	    if (MAP_EQ(map + i - 1, map + i)) {
		assert(map[i - 1].end < map[i].beg);
		assert(map[i - 1].end + 1 < map[i].beg);
	    }
	}
	for (c = b; c <= e; c++)
	    if (idx == 0)
		assert(linebreak_search_lbclass(obj, c) == p);
	    else
		assert(linebreak_search_eawidth(obj, c) == p);
    }
#endif
}

/** Update custom line breaking class map.
 * @ingroup linebreak
 * @param[in] obj linebreak object.
 * @param[in] c Unicode character.
 * @param[in] p New line breaking class propery value.
 * @return none.
 * Custom map will be updated.
 */
void linebreak_update_lbclass(linebreak_t * obj, unichar_t c, propval_t p)
{
    _add_prop(obj, c, c, p, 0);
}

/** Update custom East_Asian_Width propety map.
 * @ingroup linebreak
 * @param[in] obj linebreak object.
 * @param[in] c Unicode character.
 * @param[in] p New East_Asian_Width propery value.
 * @returns none.
 * custom map will be updated.
 */
void linebreak_update_eawidth(linebreak_t * obj, unichar_t c, propval_t p)
{
    _add_prop(obj, c, c, p, 1);
}

/** Update custom line breaking class map by another map.
 * @ingroup linebreak
 * @param[in] obj destination linebreak object.
 * @param[in] diff source linebreak object.
 * @returns none.
 * custom map will be updated.
 */
void linebreak_merge_lbclass(linebreak_t * obj, linebreak_t * diff)
{
    size_t i;

    if (obj == diff)
	return;
    if (diff->map == NULL || diff->mapsiz == 0)
	return;
    for (i = 0; i < diff->mapsiz; i++)
	if (diff->map[i].lbc != PROP_UNKNOWN) {
	    _add_prop(obj, diff->map[i].beg, diff->map[i].end,
		      diff->map[i].lbc, 0);
	    if (obj->errnum)
		return;
	}
}

/** Update custom East_Asian_Width map by another map.
 * @ingroup linebreak
 * @param[in] obj destination linebreak object.
 * @param[in] diff source linebreak object.
 * @returns none.
 * custom map will be updated.
 */
void linebreak_merge_eawidth(linebreak_t * obj, linebreak_t * diff)
{
    size_t i;

    if (obj == diff)
	return;
    if (diff->map == NULL || diff->mapsiz == 0)
	return;
    for (i = 0; i < diff->mapsiz; i++)
	if (diff->map[i].eaw != PROP_UNKNOWN) {
	    _add_prop(obj, diff->map[i].beg, diff->map[i].end,
		      diff->map[i].eaw, 1);
	    if (obj->errnum)
		return;
	}
}

static const mapent_t
    nullmap =
    { 0, 0, PROP_UNKNOWN, PROP_UNKNOWN, PROP_UNKNOWN, PROP_UNKNOWN };

static void _clear_prop(linebreak_t * obj, int idx)
{
    mapent_t *map = obj->map, *cur;
    size_t mapsiz = obj->mapsiz, i;

    if (mapsiz == 0)
	return;

    for (i = 0; i < mapsiz;) {
	cur = map + i;
	SET_PROP(cur, PROP_UNKNOWN);
	if (MAP_EQ(cur, &nullmap)) {
	    DELETE_CUR;
	} else
	    i++;
    }

    if (mapsiz == 0) {
	free(obj->map);
	obj->map = NULL;
	obj->mapsiz = 0;
    } else {
	obj->map = map;
	obj->mapsiz = mapsiz;
    }
}

/** Clear custom line breaking class map
 * @ingroup linebreak
 * @param[in] obj linebreak object.
 * @returns none.
 * All line breaking class values in custom map will be cleared.
 */
void linebreak_clear_lbclass(linebreak_t * obj)
{
    _clear_prop(obj, 0);
}

/** Clear custom East_Asian_Width property map
 * @ingroup linebreak
 * @param[in] obj linebreak object.
 * @returns none.
 * All East_Asian_Width values in custom map will be cleared.
 */
void linebreak_clear_eawidth(linebreak_t * obj)
{
    _clear_prop(obj, 1);
}
