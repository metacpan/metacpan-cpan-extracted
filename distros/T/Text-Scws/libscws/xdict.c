/**
 * @file xdict.c (dictionary query)
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * $Id: xdict.c,v 1.1.1.1 2007/06/05 04:19:45 hightman Exp $
 */

#include "xdict.h"
#include "xtree.h"
#include "xdb.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* setup & open the dict */
xdict_t xdict_open(const char *fpath, int mode)
{
	xdict_t xd;
	xdb_t x;

	if (!(x = xdb_open(fpath, 'r')))
		return NULL;

	xd = (xdict_t) malloc(sizeof(xdict_st));
	memset(xd, 0, sizeof(xdict_st));

	xd->xmode = mode;
	if (mode == SCWS_XDICT_MEM)
	{
		xtree_t xt;

		/* convert the xdb(disk) -> xtree(memory) */
		if ((xt = xdb_to_xtree(x, NULL)) != NULL)
		{
			xdb_close(x);
			xd->xdict = (void *) xt;
			return xd;
		}
	}
	
	xd->xmode = SCWS_XDICT_XDB;
	xd->xdict = (void *) x;	
	return xd;
}

/* close the dict */
void xdict_close(xdict_t xd)
{
	if (xd)
	{
		if (xd->xmode == SCWS_XDICT_MEM)
		{
			xtree_free((xtree_t) xd->xdict);
		}
		else
		{
			xdb_close((xdb_t) xd->xdict);
		}
		free(xd);
	}
}

/* query the word */
word_t xdict_query(xdict_t xd, const char *key, int len)
{
	word_t value;

	if (xd == NULL)
		return NULL;

	if (xd->xmode == SCWS_XDICT_MEM)
	{
		/* this is ThreadSafe, recommend. */
		value = (word_t) xtree_nget((xtree_t) xd->xdict, key, len, NULL);
	}
	else
	{
		/* this is non-ThreadSafe, DO NOT used many times in one sentence. */
#if 0
		if ((value = (word_t) xdb_nget((xdb_t) xd->xdict, key, len, NULL)) != NULL)
		{
			memcpy(&xd->qword, value, sizeof(word_st));
			free(value);
			value = &xd->qword;
		}
#endif
		value = (word_t) xdb_nget((xdb_t) xd->xdict, key, len, NULL);
	}
	return value;
}

