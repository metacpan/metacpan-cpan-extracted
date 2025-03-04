/**
 * @file rule.h
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * $Id: rule.h,v 1.2 2007/06/05 06:19:38 hightman Exp $
 */

#ifndef	_SCWS_RULE_20070525_H_
#define	_SCWS_RULE_20070525_H_

#ifdef HAVE_CONFIG_H
#	include "config.h"
#endif

/* xtree required */
#include "xtree.h"

#define	SCWS_RULE_MAX			32
#define	SCWS_RULE_SPECIAL		0x80000000
#define	SCWS_RULE_NOSTATS		0x40000000

/* flag: 0x00 ~ 0x4000 */
#define	SCWS_ZRULE_NONE			0x00
#define	SCWS_ZRULE_PREFIX		0x01
#define	SCWS_ZRULE_SUFFIX		0x02
#define	SCWS_ZRULE_INCLUDE		0x04	/* with include */
#define	SCWS_ZRULE_EXCLUDE		0x08	/* with exclude */
#define	SCWS_ZRULE_RANGE		0x10	/* with znum range */

/* data structure */
typedef struct scws_rule_item
{
	short flag;
	char zmin;
	char zmax;
	char name[17];
	char attr[3];
	float tf;
	float idf;
	unsigned int bit;	/* my bit  */
	unsigned int inc;	/* include */
	unsigned int exc;	/* exclude */
}	*rule_item_t;

typedef struct scws_rule
{
	xtree_t tree;
	struct scws_rule_item items[SCWS_RULE_MAX];
}	rule_st, *rule_t;

/* scws ruleset: api */

/* create & load ruleset, by fpath & charset */
rule_t scws_rule_new(const char *fpath, unsigned char *mblen);

/* free the memory & resource for ruleset */
void scws_rule_free(rule_t r);

/* get the rule tree record by str */
rule_item_t scws_rule_get(rule_t r, const char *str, int len);

/* check bit */
int scws_rule_checkbit(rule_t r, const char *str, int len, unsigned int bit);

/* check exclude or include */
int scws_rule_check(rule_t r, rule_item_t cr, const char *str, int len);

#endif
