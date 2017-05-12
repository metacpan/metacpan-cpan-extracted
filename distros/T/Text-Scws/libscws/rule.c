/**
 * @file rule.c (auto surame & areaname & special group)
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * $Id: rule.c,v 1.1.1.1 2007/06/05 04:19:45 hightman Exp $
 */


#include "rule.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static inline int _rule_index_get(rule_t r, const char *name)
{
	int i;
	for (i = 0; i < SCWS_RULE_MAX; i++)
	{
		if (r->items[i].name[0] == '\0')
			break;

		if (!strcasecmp(r->items[i].name, name))
			return i;
	}
	return -1;
}

rule_t scws_rule_new(const char *fpath, unsigned char *mblen)
{
	FILE *fp;
	rule_t r;
	rule_item_t cr;
	int i, j, rbl;
	unsigned char buf[512], *str, *ptr, *qtr;

	/* loaded or open file failed */	
	if ((fp = fopen(fpath, "r")) == NULL)
		return NULL;

	/* alloc the memory */
	r = (rule_t) malloc(sizeof(rule_st));
	memset(r, 0, sizeof(rule_st));

	/* quick scan to add the name to list */
	i = j = rbl = 0;
	while (fgets(buf, sizeof(buf)-1, fp))
	{
		if (buf[0] != '[' || !(ptr = strchr(buf, ']')))
			continue;

		str = buf + 1;
		*ptr = '\0';
		if (ptr == str || (ptr-str) > 15)
			continue;

		if (_rule_index_get(r, str) >= 0)
			continue;

		strcpy(r->items[i].name, str);
		r->items[i].tf = 5.0;
		r->items[i].idf = 3.5;
		strncpy(r->items[i].attr, "un", 2);
		if (!strcasecmp(str, "special"))
			r->items[i].bit = SCWS_RULE_SPECIAL;
		else if (!strcasecmp(str, "nostats"))
			r->items[i].bit = SCWS_RULE_NOSTATS;
		else
		{
			r->items[i].bit = (1<<j);
			j++;
		}

		if (++i >= SCWS_RULE_MAX)
			break;
	}
	rewind(fp);

	/* load the tree data */
	if ((r->tree = xtree_new(0, 1)) == NULL)
	{
		free(r);
		return NULL;
	}
	cr = NULL;
	while (fgets(buf, sizeof(buf)-1, fp))
	{
		if (buf[0] == ';')
			continue;

		if (buf[0] == '[')
		{
			cr = NULL;
			str = buf + 1;
			if ((ptr = strchr(str, ']')) != NULL)
			{
				*ptr = '\0';			
				if ((i = _rule_index_get(r, str)) >= 0)
				{
					rbl = 1;	/* default read by line = yes */
					cr = &r->items[i];
				}
			}
			continue;
		}
		
		if (cr == NULL)
			continue;
		
		/* param set: line|znum|include|exclude|type|tf|idf|attr */
		if (buf[0] == ':')
		{			
			str = buf + 1;
			if (!(ptr = strchr(str, '=')))
				continue;			
			while (*str == ' ' || *str == '\t') str++;			
			
			qtr = ptr + 1;
			while (ptr > str && (ptr[-1] == ' ' || ptr[-1] == '\t')) ptr--;
			*ptr = '\0';				
			ptr = str;
			str = qtr;
			while (*str == ' ' || *str == '\t') str++;	
			
			if (!strcmp(ptr, "line"))				
				rbl =  (*str == 'N' || *str == 'n') ? 0 : 1;
			else if (!strcmp(ptr, "tf"))			
				cr->tf = (float) atof(str); 
			else if (!strcmp(ptr, "idf"))
				cr->idf = (float) atof(str);
			else if (!strcmp(ptr, "attr"))
				strncpy(cr->attr, str, 2);
			else if (!strcmp(ptr, "znum"))
			{			
				if ((ptr = strchr(str, ',')) != NULL)
				{
					*ptr++ = '\0';						
					while (*ptr == ' ' || *ptr == '\t') ptr++;
					cr->zmax = atoi(ptr);
					cr->flag |= SCWS_ZRULE_RANGE;
				}
				cr->zmin = atoi(str);
			}
			else if (!strcmp(ptr, "type"))
			{
				if (!strncmp(str, "prefix", 6))
					cr->flag |= SCWS_ZRULE_PREFIX;
				else if (!strncmp(str, "suffix", 6))
					cr->flag |= SCWS_ZRULE_SUFFIX;
			}
			else if (!strcmp(ptr, "include") || !strcmp(ptr, "exclude"))
			{
				unsigned int *clude;

				if (!strcmp(ptr, "include"))
				{
					clude = &cr->inc;
					cr->flag |= SCWS_ZRULE_INCLUDE;
				}
				else
				{
					clude = &cr->exc;
					cr->flag |= SCWS_ZRULE_EXCLUDE;
				}
				
				while ((ptr = strchr(str, ',')) != NULL)
				{						
					while (ptr > str && (ptr[-1] == '\t' || ptr[-1] == ' ')) ptr--;
					*ptr = '\0';
					if ((i = _rule_index_get(r, str)) >= 0)
						*clude |= r->items[i].bit;
					
					str = ptr + 1;
					while (*str == ' ' || *str == '\t' || *str == ',') str++;
				}
				
				ptr = strlen(str) + str;
				while (ptr > str && strchr(" \t\r\n", ptr[-1])) ptr--;
				*ptr = '\0';
				if (ptr > str && (i = _rule_index_get(r, str)))
					*clude |= r->items[i].bit;
			}	
			continue;
		}

		/* read the entries */
		str = buf;
		while (*str == ' ' || *str == '\t') str++;
		ptr = str + strlen(str);
		while (ptr > str && strchr(" \t\r\n", ptr[-1])) ptr--;
		*ptr = '\0';

		/* emptry line */
		if (ptr == str)
			continue;

		if (rbl)
			xtree_nput(r->tree, cr, sizeof(struct scws_rule_item), str, ptr - str);
		else
		{
			while (str < ptr)
			{
				j = mblen[(*str)];

#ifndef LIBSCWS_QUIET
				/* try to check repeat */
				if ((i = (int) xtree_nget(r->tree, str, j, NULL)) != 0)
					fprintf(stderr, "Reapeat word on %s|%s: %.*s\n", cr->name, ((rule_item_t) i)->name, j, str);
#endif

				xtree_nput(r->tree, cr, sizeof(struct scws_rule_item), str, j);
				str += j;
			}
		}	
	}
	fclose(fp);

	/* optimize the tree */
	xtree_optimize(r->tree);
	return r;
}

void scws_rule_free(rule_t r)
{
	if (r)
	{
		xtree_free(r->tree);
		free(r);
	}
}

/* get the rule */
rule_item_t scws_rule_get(rule_t r, const char *str, int len)
{
	if (!r)
		return NULL;
	
	return ((rule_item_t) xtree_nget(r->tree, str, len, NULL));
}

/* check the bit with str */
int scws_rule_checkbit(rule_t r, const char *str, int len, unsigned int bit)
{
	rule_item_t ri;

	if (!r)
		return 0;

	ri = (rule_item_t) xtree_nget(r->tree, str, len, NULL);
	if ((ri != NULL) && (ri->bit & bit))
		return 1;

	return 0;
}

/* check the rule */
int scws_rule_check(rule_t r, rule_item_t cr, const char *str, int len)
{
	if (!r)
		return 0;

	if ((cr->flag & SCWS_ZRULE_INCLUDE) && !scws_rule_checkbit(r, str, len, cr->inc))
		return 0;

	if ((cr->flag & SCWS_ZRULE_EXCLUDE) && scws_rule_checkbit(r, str, len, cr->exc))
		return 0;

	return 1;
}
