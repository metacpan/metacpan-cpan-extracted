/*
 * Unicode-BiDiRule
 *
 * Copyright (C) 2015 by Hatuka*nezumi - IKEDA Soji
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the same terms as Perl itself. For more details, see the full text of
 * the licenses at <http://dev.perl.org/licenses/>.
 *
 * This program is distributed in the hope that it will be
 * useful, but without any warranty; without even the implied
 * warranty of merchantability or fitness for a particular purpose.
 */

typedef enum {
    BDR_LTR = 1,
    BDR_RTL,			/* R, AL */
    BDR_AN,
    BDR_EN,
    BDR_VALID,			/* ES, CS, ET, ON, BN */
    BDR_NSM,
    BDR_AVOIDED,		/* Explicit formatting: LRE etc. */
    BDR_INVALID			/* B, S, WS  */
} bidirule_prop_t;

/* Line below is automatically generated.  Don't edit it manually. */
#define BIDIRULE_UNICODE_VERSION

/* Line below is automatically generated.  Don't edit it manually. */
#define BIDIRULE_BLKWIDTH

/* Lines below are automatically generated.  Don't edit them manually. */
static U16 bidirule_prop_index[] = {

};

/* Lines below are automatically generated.  Don't edit them manually. */
static U8 bidirule_prop_array[] = {

};

static U8 bidirule_prop_lookup(U32 cp)
{
    if ((0x0E0000 <= cp && cp <= 0x0E0FFF) || (cp & 0x00FFFE) == 0x00FFFE)
	return BDR_VALID;	/* BN */
    else if (0x10FFFF < cp)
	return BDR_INVALID;
    else if (0x020000 <= cp)
	return BDR_LTR;		/* L */

    return bidirule_prop_array[bidirule_prop_index[cp >> BIDIRULE_BLKWIDTH]
			       + (cp & ((1 << BIDIRULE_BLKWIDTH) - 1))
	];
}

static const U8 utf8_sequence_len[0x100] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x00-0x0F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x10-0x1F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x20-0x2F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x30-0x3F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x40-0x4F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x50-0x5F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x60-0x6F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x70-0x7F */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0x80-0x8F */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0x90-0x9F */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0xA0-0xAF */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0xB0-0xBF */
    0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,	/* 0xC0-0xCF */
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,	/* 0xD0-0xDF */
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,	/* 0xE0-0xEF */
    4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0xF0-0xFF */
};

static STRLEN bidirule_check(U8 * buf, const STRLEN buflen,
			     U8 ** pptr, STRLEN * lenptr, STRLEN * ulenptr,
			     STRLEN * idxptr, U32 * cpptr, int strict)
{
    U8 *p = buf;
    const U8 *end = buf + buflen;
    const U8 *end4 = end - 4;

    STRLEN len = 0, idx = 0;
    U32 cp = 0;
    U8 direction = 0, prop = 0, prop_before = 0;
    U8 has_an = 0, has_en = 0;

    struct {
	U8 *p;
	STRLEN len;
	STRLEN ulen;
	STRLEN idx;
	U32 cp;
    } ctx = {
    NULL, 0, 0, 0, 0};

    U32 vec;

    while (p < end4) {
      check:
	/* Check if string consists of well-formed UTF-8 sequences. */

	len = utf8_sequence_len[*p];

	switch (len) {
	case 0:
	    goto illseq;

	case 1:
	    /* 0xxxxxxx */
	    cp = (U32) p[0];
	    break;

	case 2:
	    /* 110xxxxx 10xxxxxx */
	    if ((p[1] & 0xC0) != 0x80)
		goto illseq;
	    cp = ((U32) (p[0] & 0x1F) << 6) | ((U32) (p[1] & 0x3F));
	    break;

	case 3:
	    vec = ((U32) p[0] << 16) | ((U32) p[1] << 8) | ((U32) p[2]);
	    /* 1110xxxx 10xxxxxx 10xxxxxx *//* Shortest form */
	    if ((vec & 0x00F0C0C0) != 0x00E08080 || vec < 0x00E0A080)
		goto illseq;
	    cp = ((U32) (p[0] & 0x0F) << 12)
		| ((U32) (p[1] & 0x3F) << 6) | ((U32) (p[2] & 0x3F));
	    break;

	case 4:
	    vec = ((U32) p[0] << 24)
		| ((U32) p[1] << 16) | ((U32) p[2] << 8) | ((U32) p[3]);
	    /* 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx *//* Shortest form */
	    if ((vec & 0xF8C0C0C0) != 0xF0808080 || vec < 0xF0908080)
		goto illseq;
	    cp = ((U32) (p[0] & 0x07) << 18)
		| ((U32) (p[1] & 0x3F) << 12)
		| ((U32) (p[2] & 0x3F) << 6) | ((U32) (p[3] & 0x3F));
	    break;

	  illseq:
	    if (pptr != NULL)
		*pptr = p;
	    if (lenptr != NULL)
		*lenptr = 0;
	    if (ulenptr != NULL)
		*ulenptr = 0;
	    if (idxptr != NULL)
		*idxptr = idx;
	    if (cpptr != NULL)
		*cpptr = 0;
	    return BDR_INVALID;
	}			/* switch (len) */

	/* Checking by BiDi Rule. */

	prop = bidirule_prop_lookup(cp);

	if (prop_before == 0) {
	    ctx.p = p;
	    ctx.len = len;
	    ctx.ulen = 1;
	    ctx.idx = idx;
	    ctx.cp = cp;

	    /* 1. */
	    switch (prop) {
	    case BDR_RTL:
		direction = BDR_RTL;
		break;

	    case BDR_AN:
		goto invalid;

	    case BDR_EN:
	    case BDR_VALID:
		/* Unknown direction. */
		break;

	    case BDR_LTR:
		direction = BDR_LTR;
		break;

	    default:		/* NSM, AVOIDED or INVALID */
		if (strict)
		    goto invalid;
		/* Unknown direction. */
		break;
	    }
	} else if (prop == BDR_NSM) {
	    prop = prop_before;
	    ctx.len += len;
	    ctx.ulen++;
	} else {
	    ctx.p = p;
	    ctx.len = len;
	    ctx.ulen = 1;
	    ctx.idx = idx;
	    ctx.cp = cp;

	    switch (prop) {
	    case BDR_RTL:
		/* 2. */
		if (direction != BDR_RTL)
		    goto invalid;
		break;

	    case BDR_AN:
		/* 2., 4. */
		if (has_en)
		    goto invalid;
		else if (direction != BDR_RTL)
		    goto invalid;
		else
		    has_an = 1;
		break;

	    case BDR_EN:
		/* 2., 4., 5. */
		if (has_an)
		    goto invalid;
		else
		    has_en = 1;
		break;

	    case BDR_VALID:
		/* 2., 5. */
		break;

	    case BDR_LTR:
		/* 2., 5. */
		if (direction == BDR_RTL)
		    goto invalid;
		break;

	    default:		/* AVOIDED or INVALID */
		if (direction == BDR_RTL)
		    goto invalid;
		else if (strict)
		    goto invalid;
		else
		    direction = 0;
		break;
	    }			/* switch (prop) */
	}			/* if (prop_before == 0) */

	prop_before = prop;

	p += len;
	idx++;
    }				/* while (p < end4) */
    if (p < end) {
	if (p + utf8_sequence_len[*p] <= end)
	    goto check;
	else
	    goto illseq;
    }

    switch (direction) {
    case BDR_RTL:
	/* 3. */
	switch (prop) {
	case BDR_RTL:
	case BDR_EN:
	case BDR_AN:
	    break;
	default:
	    goto invalid;
	}
	break;

    case BDR_LTR:
	/* 6. */
	switch (prop) {
	case BDR_LTR:
	case BDR_EN:
	    break;
	default:
	    direction = 0;
	    break;
	}
	break;
    }
    if (pptr != NULL)
	*pptr = p;
    if (idxptr != NULL)
	*idxptr = idx;
    return direction;

  invalid:
    if (pptr != NULL)
	*pptr = ctx.p;
    if (lenptr != NULL)
	*lenptr = ctx.len;
    if (ulenptr != NULL)
	*ulenptr = ctx.ulen;
    if (idxptr != NULL)
	*idxptr = ctx.idx;
    if (cpptr != NULL)
	*cpptr = ctx.cp;

    switch (prop) {
    case BDR_AVOIDED:
	return prop;
    default:
	return BDR_INVALID;
    }
}
