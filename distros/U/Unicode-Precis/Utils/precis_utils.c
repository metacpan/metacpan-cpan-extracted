/*
 * Unicode-Precis
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

/* Begin auto-generated maps */

/* End of auto-generated maps */

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

static STRLEN _map(U8 **newptr, U8 * buf, const size_t buflen, int ix)
{
    U8 *new;
    U8 *p, *q;
    U8 *end = buf + buflen;
    U8 *end4 = end - 4;

    STRLEN len, i, mappedlen;
    U32 vec;
    char *mapped;
    void **mapent;
    U8 folded[UTF8_MAXBYTES_CASE + 1];

    if (newptr == NULL)
	return 0;
    new = *newptr;

  redo:
    p = buf;
    q = new;
    while (p < end4) {
      check:
	len = utf8_sequence_len[*p];

	switch (len) {
	case 0:
	    goto garbage;

	case 1:
	    break;

	case 2:
	    /* 110xxxxx 10xxxxxx */
	    if ((p[1] & 0xC0) != 0x80)
		goto garbage;
	    break;

	case 3:
	    vec = ((U32) p[0] << 16)
		| ((U32) p[1] << 8)
		| ((U32) p[2]);
	    /* 1110xxxx 10xxxxxx 10xxxxxx *//* Non-shortest form */
	    if ((vec & 0x00F0C0C0) != 0x00E08080 || vec < 0x00E0A080)
		goto garbage;
	    break;

	case 4:
	    vec = ((U32) p[0] << 24)
		| ((U32) p[1] << 16)
		| ((U32) p[2] << 8)
		| ((U32) p[3]);
	    /* 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx *//* Non-shortest form */
	    if ((vec & 0xF8C0C0C0) != 0xF0808080 || vec < 0xF0908080)
		goto garbage;
	    break;

	  garbage:
	    if (new == NULL)
		q++, p++;
	    else
		*q++ = *p++;
	    continue;		/* while (p < end4) */
	}

	switch (ix) {
	case 1:			/* foldCase */
	    to_utf8_fold(p, folded, &mappedlen);
	    if (mappedlen <= 0)
		goto nomap;
	    mapped = (char *)folded;
	    break;

	case 2:			/* mapSpace */
	    if (len == 1)
		goto nomap;

	    mapent = space_map;
	    for (i = 0; i < len; i++) {
		mapent = mapent[p[i] & 0x3F];
		if (mapent == NULL)
		    break;
	    }
	    if (mapent == NULL)
		goto nomap;
	    mapped = "\x20";
	    mappedlen = 1;
	    break;

	case 3:			/* mapWidth */
	    if (len == 1)
		goto nomap;

	    mapent = widthdecomp_map;
	    for (i = 0; i < len; i++) {
		mapent = mapent[p[i] & 0x3F];
		if (mapent == NULL)
		    break;
	    }
	    if (mapent == NULL)
		goto nomap;
	    mapped = (char *)mapent;
	    for (mappedlen = 0; mapped[mappedlen] != '\0'; mappedlen++);
	    break;

	default:
	  nomap:
	    mapped = (char *)p;
	    mappedlen = len;
	    break;
	}			/* switch (ix) */

	if (new == NULL)
	    q += mappedlen;
	else
	    for (i = 0; i < mappedlen; i++)
		*q++ = *mapped++;
	p += len;
    }				/* while (p < end4) */
    if (p < end) {
	if (p + utf8_sequence_len[*p] <= end)
	    goto check;

	if (new == NULL)
	    q += end - p;
	else
	    while (p < end)
		*q++ = *p++;
    }

    if (new == NULL) {
	new = malloc(q - new + 1);
	if (new == NULL)
	    return 0;
	goto redo;
    }

    *q = '\0';
    *newptr = new;
    return q - new;
}

