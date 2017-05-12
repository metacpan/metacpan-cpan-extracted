/*
 * @file scws.c (core segment functions)
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * @notice this is modified from source of jabberd2.0s10
 * $Id  $
 */

 
#include "scws.h"
#include "xdict.h"
#include "rule.h"
#include "charset.h"
#include "darray.h"
#include "xtree.h"
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

/* quick macro define for frequency usage */
#define	SCWS_IS_SPECIAL(x,l)	scws_rule_checkbit(s->r,x,l,SCWS_RULE_SPECIAL)
#define	SCWS_IS_NOSTATS(x,l)	scws_rule_checkbit(s->r,x,l,SCWS_RULE_NOSTATS)
#define	SCWS_CHARLEN(x)			s->mblen[(x)]
#define	SCWS_IS_ALNUM(x)		(((x)>=48&&(x)<=57)||((x)>=65&&(x)<=90)||((x)>=97&&(x)<=122))
#define	SCWS_IS_ALPHA(x)		(((x)>=65&&(x)<=90)||((x)>=97&&(x)<=122))
#define	SCWS_IS_DIGIT(x)		((x)>=48&&(x)<=57)
#define	SCWS_IS_WHEAD(x)		((x) & SCWS_ZFLAG_WHEAD)
#define	SCWS_IS_ECHAR(x)		((x) & SCWS_ZFLAG_ENGLISH)
#define	SCWS_NO_RULE1(x)		(((x) & SCWS_ZFLAG_ENGLISH)||(((x) & (SCWS_ZFLAG_WHEAD|SCWS_ZFLAG_NR2)) == SCWS_ZFLAG_WHEAD))
///#define	SCWS_NO_RULE2(x)		(((x) & SCWS_ZFLAG_ENGLISH)||(((x) & (SCWS_ZFLAG_WHEAD|SCWS_ZFLAG_N2)) == SCWS_ZFLAG_WHEAD))
#define	SCWS_NO_RULE2			SCWS_NO_RULE1

static const char *attr_en = "en";
static const char *attr_un = "un";
static const char *attr_nr = "nr";

/* create scws engine */
scws_t scws_new()
{
	scws_t s;
	s = (scws_t) malloc(sizeof(scws_st));
	memset(s, 0, sizeof(scws_st));
	s->mblen = charset_table_get(NULL);
	s->off = s->len = 0;

	return s;
}

/* close & free the engine */
void scws_free(scws_t s)
{
	if (s->d)
		xdict_close(s->d);

	if (s->r)
		scws_rule_free(s->r);

	free(s);
}

/* set the dict & open it */
void scws_set_dict(scws_t s, const char *fpath, int mode)
{
	if (s->d != NULL)
		xdict_close(s->d);
	
	if (mode == SCWS_XDICT_XDB)
		s->mode |= SCWS_XDB_USAGE;
	else
		s->mode &= ~SCWS_XDB_USAGE;

	s->d = xdict_open(fpath, mode);
}

void scws_set_charset(scws_t s, const char *cs)
{
	s->mblen = charset_table_get(cs);
}

void scws_set_rule(scws_t s, const char *fpath)
{
	if (s->r != NULL)
		scws_rule_free(s->r);

	s->r = scws_rule_new(fpath, s->mblen);	
}

/* set ignore symbol or multi segments */
void scws_set_ignore(scws_t s, int yes)
{
	if (yes == SCWS_YEA)
		s->mode |= SCWS_IGN_SYMBOL;

	if (yes == SCWS_NA)
		s->mode &= ~SCWS_IGN_SYMBOL;
}

void scws_set_multi(scws_t s, int yes)
{
	if (yes == SCWS_YEA)
		s->mode |= SCWS_SEG_MULTI;

	if (yes == SCWS_NA)
		s->mode &= ~SCWS_SEG_MULTI;
}

void scws_set_debug(scws_t s, int yes)
{
	if (yes == SCWS_YEA)
		s->mode |= SCWS_DEBUG;

	if (yes == SCWS_NA)
		s->mode &= ~SCWS_DEBUG;
}

/* send the text buffer & init some others */
void scws_send_text(scws_t s, const char *text, int len)
{
	s->txt = (unsigned char *) text;
	s->len = len;
	s->off = 0;
}

/* get some words, if these is not words, return NULL */
#define	SCWS_PUT_RES(o,i,l,a)									\
{																\
	scws_res_t res;												\
	res = (scws_res_t) malloc(sizeof(struct scws_result));		\
	res->off = o;												\
	res->idf = i;												\
	res->len = l;												\
	strncpy(res->attr, a, 2);									\
	res->attr[2] = '\0';										\
	res->next = NULL;											\
	if (s->res1 == NULL)										\
		s->res1 = s->res0 = res;								\
	else														\
	{															\
		s->res1->next = res;									\
		s->res1 = res;											\
	}															\
}

/* single bytes segment (纯单字节字符) */
#define	PFLAG_WITH_MB		0x01
#define	PFLAG_ALNUM			0x02
#define	PFLAG_VALID			0x04
#define	PFLAG_DIGIT			0x08
#define	PFLAG_ADDSYM		0x10

static void _str_toupper(char *src, char *dst)
{
	while (*src)
	{
		*dst++ = *src++;
		if (dst[-1] >= 'a' && dst[-1] <= 'z')
			dst[-1] ^= 0x20;
	}
}

static void _str_tolower(char *src, char *dst)
{
	while (*src)
	{
		*dst++ = *src++;
		if (dst[-1] >= 'A' && dst[-1] <= 'Z')
			dst[-1] ^= 0x20;
	}
}

#ifdef HAVE_STRNDUP
#define	_mem_ndup		strndup
#else
static inline void *_mem_ndup(const char *src, int len)
{
	char *dst;
	dst = malloc(len+1);
	memcpy(dst, src, len);
	dst[len] = '\0';
	return dst;
}
#endif

static void _scws_ssegment(scws_t s, int end)
{
	int start, wlen, ch, pflag;
	unsigned char *txt;
	float idf;

	start = s->off;
	wlen = end - start;

	/* check special words (need strtoupper) */
	if (wlen > 1)
	{	
		txt = (char *) _mem_ndup(s->txt + start, wlen);	
		_str_toupper(txt, txt);
		if (SCWS_IS_SPECIAL(txt, wlen))
		{
			SCWS_PUT_RES(start, 9.5, wlen, "nz")
			free(txt);
			return;
		}
		free(txt);
	}

	txt = s->txt;
	/* 取出单词及标点. 数字允许一个点且下一个为数字,不连续的. 字母允许一个不连续的' */
	while (start < end)
	{
		ch = txt[start++];
		if (SCWS_IS_ALNUM(ch))
		{
			pflag = SCWS_IS_DIGIT(ch) ? PFLAG_DIGIT : 0;
			wlen = 1;
			while (start < end)
			{
				ch = txt[start];
				if (pflag & PFLAG_DIGIT)
				{
					if (!SCWS_IS_DIGIT(ch))
					{
						// strict must add: !$this->_is_digit(ord($this->txt[$start+1])))
						if ((pflag & PFLAG_ADDSYM) || ch != 0x2e)
							break;
						pflag |= PFLAG_ADDSYM;												
					}
				}
				else
				{
					if (!SCWS_IS_ALPHA(ch))
					{
						if ((pflag & PFLAG_ADDSYM) || ch != 0x27)
							break;
						pflag |= PFLAG_ADDSYM;
					}
				}
				start++;
				wlen++;
			}

			idf = 2.5 * logf(wlen);
			SCWS_PUT_RES(start-wlen, idf, wlen, attr_en)
		}
		else if (!(s->mode & SCWS_IGN_SYMBOL))
		{
			SCWS_PUT_RES(start-1, 0.0, 1, attr_un)
		}
	}
}

/* multibyte segment */
static int _scws_mget_word(scws_t s, int i, int j, int quick)
{
	int r, k;
	word_t item;

	if (!(s->wmap[i][i]->flag & SCWS_ZFLAG_WHEAD))
		return i;

	for (r=i, k=i+1; k <= j; k++)
	{
		item = s->wmap[i][k];
		if (item && (item->flag & SCWS_WORD_FULL))
		{
			r = k;
			if (quick || !(item->flag & SCWS_WORD_PART))
				break;					
		}
	}
	return r;
}

static void _scws_mset_word(scws_t s, int i, int j)
{
	word_t item;	

	item = s->wmap[i][j];
	if ((s->mode & SCWS_IGN_SYMBOL) && !memcmp(item->attr, attr_un, 2))
		return;
		
	SCWS_PUT_RES(s->zmap[i].start, item->idf, (s->zmap[j].end - s->zmap[i].start), item->attr)
}

static void _scws_mseg_zone(scws_t s, int f, int t)
{
	unsigned char *mpath, *npath;
	word_t **wmap;
	int x,i,j,m,n;
	double weight, nweight;

	mpath = npath = NULL;
	weight = nweight = (double) 0.0;

	wmap = s->wmap;
	for (x = i = f; i <= t; i++)
	{
		j = _scws_mget_word(s, i, t, SCWS_NA);
		if (j == i || j <= x || (/*i > x && */(wmap[i][j]->flag & SCWS_WORD_USED)))
			continue;

		/* one word only */
		if (i == f && j == t)
		{
			mpath = (unsigned char *) malloc(2);
			mpath[0] = j - i;
			mpath[1] = 0xff;
			break;
		}
		
		if (i != f && (wmap[i][j]->flag & SCWS_WORD_RULE))
			continue;

		/* create the new path */
		wmap[i][j]->flag |= SCWS_WORD_USED;
		nweight = (double) wmap[i][j]->tf  * (j-i+1);
		if (i == f) nweight *= 1.4;
		else if (j == t) nweight *= 1.6;		

		if (npath == NULL)
		{
			npath = (unsigned char *) malloc(t-f+2);
			memset(npath, 0xff, t-f+2);
		}

		/* lookfor backward */
		x = 0;
		for (m = f; m < i; m = n+1)
		{
			n = _scws_mget_word(s, m, i-1, SCWS_NA);
			nweight *= wmap[m][n]->tf * (n-m+1);
			npath[x++] = n - m;
			if (n > m)
				wmap[m][n]->flag |= SCWS_WORD_USED;			
		}

		/* my self */
		npath[x++] = j - i;

		/* lookfor forward */
		for (m = j+1; m <= t; m = n+1)
		{
			n = _scws_mget_word(s, m, t, SCWS_NA);
			nweight *= wmap[m][n]->tf * (n-m+1);
			npath[x++] = n - m;
			if (n > m)
				wmap[m][n]->flag |= SCWS_WORD_USED;			
		}

		npath[x] = -1;
		nweight /= expf(x);

		/* draw the path for debug */
#ifndef LIBSCWS_QUIET
		if (s->mode & SCWS_DEBUG)
		{		
			fprintf(stderr, "PATH by keyword = %.*s, (weight=%.4f):\n",
				s->zmap[j].end - s->zmap[i].start, s->txt + s->zmap[i].start, nweight);	
			for (x = 0, m = f; (n = npath[x]) != 0xff; x++)
			{
				n += m;
				fprintf(stderr, "%.*s ", s->zmap[n].end - s->zmap[m].start, s->txt + s->zmap[m].start);
				m = n + 1;
			}
			fprintf(stderr, "\n--\n");
		}		
#endif

		x = j;		
		/* check better path */
		if (nweight > weight)
		{
			unsigned char *swap;

			weight = nweight;
			swap = mpath;
			mpath = npath;
			npath = swap;			
		}
	}

	/* set the result, mpath != NULL */
	if (mpath == NULL)
		return;
	
	for (x = 0, m = f; (n = mpath[x]) != 0xff; x++)
	{
		n += m;
		if ((s->mode & SCWS_SEG_MULTI) && (mpath[x] > 1))
		{
			for (i = m; i <= n; i = j + 1)
			{
				j = _scws_mget_word(s, i, n, SCWS_YEA);
				_scws_mset_word(s, i, j);

				if (i == m && j == n)
					goto next_path;								
			}
		}
		_scws_mset_word(s, m, n);

next_path:
		m = n + 1;
	}
}

/* quick define for zrule_checker in loop */
#define	___ZRULE_CHECKER1___														\
if (j >= zlen || SCWS_NO_RULE2(wmap[j][j]->flag))									\
	break;

#define	___ZRULE_CHECKER2___														\
if (j < 0 || SCWS_NO_RULE2(wmap[j][j]->flag))										\
	break;

#define	___ZRULE_CHECKER3___														\
if (!scws_rule_check(s->r, r1, txt + zmap[j].start, zmap[j].end - zmap[j].start))	\
	break;

static void _scws_msegment(scws_t s, int end, int zlen)
{
	word_t **wmap, query;
	struct scws_zchar *zmap;
	unsigned char *txt;
	rule_item_t r1;
	int i, j, k, ch, clen, start;
	pool_t p;

	/* pool used to management some dynamic memory */
	p = pool_new();

	/* create wmap & zmap */
	wmap = s->wmap = (word_t **) darray_new(zlen, zlen, sizeof(word_t));
	zmap = s->zmap = (struct scws_zchar *) pmalloc(p, zlen * sizeof(struct scws_zchar));
	txt = s->txt;
	start = s->off;

	for (i = 0; start < end; i++)
	{
		ch = txt[start];
		clen = SCWS_CHARLEN(ch);
		if (clen == 1)
		{
			while (start++ < end)
			{
				ch = txt[start];
				if (SCWS_CHARLEN(txt[start]) > 1)
					break;
				clen++;
			}
			wmap[i][i] = (word_t) pmalloc_z(p, sizeof(word_st));
			wmap[i][i]->tf = 0.5;
			wmap[i][i]->flag |= SCWS_ZFLAG_ENGLISH;
			strcpy(wmap[i][i]->attr, attr_un);
		}
		else
		{
			query = xdict_query(s->d, txt + start, clen);
			wmap[i][i] = (word_t) pmalloc(p, sizeof(word_st));
			if (query == NULL)
			{
				wmap[i][i]->tf = 0.5;
				wmap[i][i]->idf = 0.0;
				wmap[i][i]->flag = 0;
				strcpy(wmap[i][i]->attr, attr_un);
			}
			else
			{
				memcpy(wmap[i][i], query, sizeof(word_st));
#if 1
				if (s->mode & SCWS_XDB_USAGE)
					free(query);
#endif								
			}
			start += clen;
		}
		
		zmap[i].start = start - clen;
		zmap[i].end = start;
	}

	/* fixed real zlength */
	zlen = i;

	/* create word query table */
	for (i = 0; i < zlen; i++)
	{
		k = 0;
		for (j = i+1; j < zlen; j++)
		{
			query = xdict_query(s->d, txt + zmap[i].start, zmap[j].end - zmap[i].start);
			if (query == NULL)
				break;
			ch = query->flag;
			if (ch & SCWS_WORD_FULL)
			{
				wmap[i][j] = (word_t) pmalloc(p, sizeof(word_st));
				memcpy(wmap[i][j], query, sizeof(word_st));

				wmap[i][i]->flag |= SCWS_ZFLAG_WHEAD;

				for (k = i+1; k <= j; k++)
					wmap[k][k]->flag |= SCWS_ZFLAG_WPART;
			}
#if 1
			if (s->mode & SCWS_XDB_USAGE)
				free(query);
#endif
			if (!(ch & SCWS_WORD_PART))
				break;		
		}
		
		if (k--)
		{
			/* set nr2 to some short name */
			if ((k == (i+1)))
			{
				if (!memcmp(wmap[i][k]->attr, attr_nr, 2))
					wmap[i][i]->flag |= SCWS_ZFLAG_NR2;
				//if (wmap[i][k]->attr[0] == 'n')
					//wmap[i][i]->flag |= SCWS_ZFLAG_N2;
			}				

			/* clean the PART flag for the last word */
			if (k < j)
				wmap[i][k]->flag ^= SCWS_WORD_PART;
		}
	}

	if (s->r == NULL)
		goto do_segment;
	
	/* auto rule set for name & zone & chinese numeric */

	/* one word auto rule check */
	for (i = 0; i < zlen; i++)
	{
		if (SCWS_NO_RULE1(wmap[i][i]->flag))
			continue;

		r1 = scws_rule_get(s->r, txt + zmap[i].start, zmap[i].end - zmap[i].start);
		if (r1 == NULL)
			continue;

		clen = r1->zmin > 0 ? r1->zmin : 1;
		if ((r1->flag & SCWS_ZRULE_PREFIX) && (i < (zlen - clen)))
		{			
			/* prefix, check after (zmin~zmax) */
			// 先检查 zmin 字内是否全部符合要求
			// 再在 zmax 范围内取得符合要求的字
			// int i, j, k, ch, clen, start;
			for (ch = 1; ch <= clen; ch++)
			{
				j = i + ch;
				___ZRULE_CHECKER1___
				___ZRULE_CHECKER3___
			}

			if (ch <= clen)
				continue;

			/* no limit znum or limit to a range */
			j = i + ch;
			while (1)
			{
				if ((!r1->zmax && r1->zmin) || (r1->zmax && (clen >= r1->zmax)))
					break;
				___ZRULE_CHECKER1___
				___ZRULE_CHECKER3___
				clen++;
				j++;
			}

			// 注意原来2字人名,识别后仍为2字的情况
			if (wmap[i][i]->flag & SCWS_ZFLAG_NR2)
			{
				if (clen == 1)
					continue;
				wmap[i][i+1]->flag |= SCWS_WORD_PART;
			}
			
			/* ok, got: i & clen */
			k = i + clen;
			wmap[i][k] = (word_t) pmalloc(p, sizeof(word_st));
			wmap[i][k]->tf = r1->tf;
			wmap[i][k]->idf = r1->idf;
			wmap[i][k]->flag = (SCWS_WORD_RULE|SCWS_WORD_FULL);
			strncpy(wmap[i][k]->attr, r1->attr, 2);

			wmap[i][i]->flag |= SCWS_ZFLAG_WHEAD;
			for (j = i+1; j <= k; j++)			
				wmap[j][j]->flag |= SCWS_ZFLAG_WPART;

			if (!(wmap[i][i]->flag & SCWS_ZFLAG_WPART))
				i = k;

			continue;
		}
		
		if ((r1->flag & SCWS_ZRULE_SUFFIX) && (i > r1->zmin))
		{
			/* suffix, check before */
			for (ch = 1; ch <= clen; ch++)
			{
				j = i - ch;
				___ZRULE_CHECKER2___
				___ZRULE_CHECKER3___
			}
			
			if (ch <= clen)
				continue;

			/* no limit znum or limit to a range */
			j = i - ch;
			while (1)
			{
				if ((!r1->zmax && r1->zmin) || (r1->zmax && (clen >= r1->zmax)))
					break;
				___ZRULE_CHECKER2___
				___ZRULE_CHECKER3___
				clen++;
				j--;
			}

			/* ok, got: i & clen (maybe clen=1 & [k][i] isset) */
			k = i - clen;
			if (wmap[k][i] != NULL)
				continue;

			wmap[k][i] = (word_t) pmalloc(p, sizeof(word_st));
			wmap[k][i]->tf = r1->tf;
			wmap[k][i]->idf = r1->idf;
			wmap[k][i]->flag = SCWS_WORD_FULL;
			strncpy(wmap[k][i]->attr, r1->attr, 2);

			wmap[k][k]->flag |= SCWS_ZFLAG_WHEAD;
			for (j = k+1; j <= i; j++)
			{
				wmap[j][j]->flag |= SCWS_ZFLAG_WPART;
				if ((j != i) && (wmap[k][j] != NULL))
					wmap[k][j]->flag |= SCWS_WORD_PART;
			}
			continue;
		}
	}

	/* two words auto rule check (欧阳** , **西路) */
	for (i = zlen - 2; i >= 0; i--)
	{
		/* with value ==> must be have SCWS_WORD_FULL, so needn't check it ag. */
		if ((wmap[i][i+1] == NULL) || (wmap[i][i+1]->flag & SCWS_WORD_PART))
			continue;

		k = i+1;
		r1 = scws_rule_get(s->r, txt + zmap[i].start, zmap[k].end - zmap[i].start);
		if (r1 == NULL)
			continue;		

		clen = r1->zmin > 0 ? r1->zmin : 1;
		if ((r1->flag & SCWS_ZRULE_PREFIX) && (k < (zlen - clen)))
		{
			for (ch = 1; ch <= clen; ch++)
			{
				j = k + ch;
				___ZRULE_CHECKER1___
				___ZRULE_CHECKER3___
			}

			if (ch <= clen)
				continue;

			/* no limit znum or limit to a range */
			j = k + ch;
			while (1)
			{
				if ((!r1->zmax && r1->zmin) || (r1->zmax && (clen >= r1->zmax)))
					break;
				___ZRULE_CHECKER1___
				___ZRULE_CHECKER3___
				clen++;
				j++;
			}

			/* ok, got: i & clen */
			k = k + clen;
			wmap[i][k] = (word_t) pmalloc(p, sizeof(word_st));
			wmap[i][k]->tf = r1->tf;
			wmap[i][k]->idf = r1->idf;
			wmap[i][k]->flag = SCWS_WORD_FULL;
			strncpy(wmap[i][k]->attr, r1->attr, 2);

			wmap[i][i+1]->flag |= SCWS_WORD_PART;
			for (j = i+2; j <= k; j++)			
				wmap[j][j]->flag |= SCWS_ZFLAG_WPART;

			i--;
			continue;
		}

		if ((r1->flag & SCWS_ZRULE_SUFFIX) && (i >= clen))
		{
			/* suffix, check before */
			for (ch = 1; ch <= clen; ch++)
			{
				j = i - ch;
				___ZRULE_CHECKER2___
				___ZRULE_CHECKER3___
			}
			
			if (ch <= clen)
				continue;

			/* no limit znum or limit to a range */
			j = i - ch;
			while (1)
			{
				if ((!r1->zmax && r1->zmin) || (r1->zmax && (clen >= r1->zmax)))
					break;
				___ZRULE_CHECKER2___
				___ZRULE_CHECKER3___
				clen++;
				j--;
			}

			/* ok, got: i & clen (maybe clen=1 & [k][i] isset) */
			k = i - clen;
			i = i + 1;
			wmap[k][i] = (word_t) pmalloc(p, sizeof(word_st));
			wmap[k][i]->tf = r1->tf;
			wmap[k][i]->idf = r1->idf;
			wmap[k][i]->flag = SCWS_WORD_FULL;
			strncpy(wmap[k][i]->attr, r1->attr, 2);

			wmap[k][k]->flag |= SCWS_ZFLAG_WHEAD;
			for (j = k+1; j <= i; j++)
			{
				wmap[j][j]->flag |= SCWS_ZFLAG_WPART;
				if (wmap[k][j] != NULL)
					wmap[k][j]->flag |= SCWS_WORD_PART;
			}

			i -= (clen+1);
			continue;
		}
	}

	/* real do the segment */
do_segment:

	/* find the easy break point */
	for (i = 0, j = 0; i < zlen; i++)
	{
		if (wmap[i][i]->flag & SCWS_ZFLAG_WPART)
			continue;

		if (i > j)
			_scws_mseg_zone(s, j, i-1);

		j = i;
		if (!(wmap[i][i]->flag & SCWS_ZFLAG_WHEAD))
		{
			_scws_mset_word(s, i, i);
			j++;
		}
	}

	/* the lastest zone */
	if (i > j)
		_scws_mseg_zone(s, j, i-1);

	/* free the wmap & zmap */
	pool_free(p);
	darray_free((void **) wmap);
}

scws_res_t scws_get_result(scws_t s)
{
	int off, len, ch, clen, zlen, pflag;
	unsigned char *txt;

	off = s->off;
	len = s->len;
	txt = s->txt;
	s->res0 = s->res1 = NULL;
	while ((off < len) && (txt[off] <= 0x20))
	{
		if (txt[off] == 0x0a || txt[off] == 0x0d)
		{
			s->off = off + 1;
			SCWS_PUT_RES(off, 0.0, 1, "cc")
			return s->res0;
		}
		off++;
	}

	if (off >= len)
		return NULL;

	/* try to parse the sentence */
	s->off = off;
	ch = txt[off];
	clen = SCWS_CHARLEN(ch);
	zlen = 1;
	pflag = (clen > 1 ? PFLAG_WITH_MB : (SCWS_IS_ALNUM(ch) ? PFLAG_ALNUM : 0));
	while (off < len)
	{
		off += clen;
		ch = txt[off];

		if (ch <= 0x20) break;
		
		clen = SCWS_CHARLEN(ch);
		if (!(pflag & PFLAG_WITH_MB))
		{
			// pure single-byte -> multibyte (2bytes)
			if (clen == 1)
			{
				if ((pflag & PFLAG_ALNUM) && !SCWS_IS_ALNUM(ch))
					pflag ^= PFLAG_ALNUM;							
			}
			else
			{
				if (!(pflag & PFLAG_ALNUM) || zlen > 2)
					break;

				pflag |= PFLAG_WITH_MB;
				/* zlen = 1; */
			}
		}
		else if ((pflag & PFLAG_WITH_MB) && clen == 1)
		{
			int i;

			// mb + single-byte. allowd: alpha+num + 中文
			if (!SCWS_IS_ALNUM(ch))
				break;
			
			pflag &= ~PFLAG_VALID;
			for (i = off+1; i < (off+3); i++)
			{
				ch = txt[i];
				if ((i >= len) || (ch <= 0x20) || (SCWS_CHARLEN(ch) > 1))
				{
					pflag |= PFLAG_VALID;
					break;
				}

				if (!SCWS_IS_ALNUM(ch))
					break;
			}		
			
			if (!(pflag & PFLAG_VALID))
				break;

			clen += (i - off - 1);
		}
		zlen++;
	}

	/* do the real segment */
	if (pflag & PFLAG_WITH_MB)
		_scws_msegment(s, off, zlen);
	else if (!(pflag & PFLAG_ALNUM))
		_scws_ssegment(s, off);
	else
	{
		float idf;

		zlen = off - s->off;
		idf = 2.5 * logf(zlen);
		SCWS_PUT_RES(s->off, idf, zlen, attr_en)
	}

	/* reutrn the result */
	s->off = off;
	if (s->res0 == NULL)
		return scws_get_result(s);

	return s->res0;
}

/* free the result retunned by scws_get_result */
void scws_free_result(scws_res_t result)
{
	scws_res_t cur;

	while ((cur = result) != NULL)
	{
		result = cur->next;
		free(cur);
	}
}

/* top words count */
// xattr = ~v,p,c
// xattr = v,pn,c

static int _tops_cmp(a, b)
	scws_top_t *a,*b;
{
	if ((*b)->weight > (*a)->weight)
		return 1;
	return -1;
}

static void _tops_load_node(node_t node, scws_top_t *values, int *start)
{
	int i = *start;

	if (node == NULL)
		return;
	
	values[i] = node->value;
	values[i]->word = node->key;

	*start = ++i;
	_tops_load_node(node->left, values, start);
	_tops_load_node(node->right, values, start);
}

static void _tops_load_all(xtree_t xt, scws_top_t *values)
{
	int i, start;
	
	for (i = 0, start = 0; i < xt->prime; i++)	
		_tops_load_node(xt->trees[i], values, &start);
}

typedef char word_attr[4];
static inline int _attr_belong(const char *a, word_attr *at)
{
	while ((*at)[0])
	{
		if (!strcmp(a, *at))
			return 1;
		at++;
	}
	return 0;
}

scws_top_t scws_get_tops(scws_t s, int limit, char *xattr)
{
	int off, xmode, cnt;
	xtree_t xt;	
	scws_res_t res, cur;
	scws_top_t top, *list, tail, base;
	char *word;
	word_attr *at;

	if (!s || !s->txt || !(xt = xtree_new(0,1)))
		return NULL;

	xmode = SCWS_NA;
	at = NULL;
	if (xattr != NULL)
	{
		if (*xattr == '~')
		{
			xattr++;	
			xmode = SCWS_YEA;
		}
		cnt = (strlen(xattr)/2) + 1;
		at = (word_attr *) pmalloc_z(xt->p, cnt * sizeof(word_attr));
		cnt = 0;
		while ((word = strchr(xattr, ',')) != NULL)
		{
			*word = '\0';
			strncpy(at[cnt], xattr, 2);
			xattr = word + 1;		
			cnt++;
		}
		strncpy(at[cnt], xattr, 2);
	}

	// save the offset.
	off = s->off;
	s->off = cnt = 0;
	while ((cur = res = scws_get_result(s)) != NULL)
	{
		do
		{
			if (cur->idf < 0.2)
				continue;

			/* check attribute filter */
			if (at != NULL)
			{
				if ((xmode == SCWS_NA) && !_attr_belong(cur->attr, at))
					continue;

				if ((xmode == SCWS_YEA) && _attr_belong(cur->attr, at))
					continue;
			}

			/* check stopwords */
			if (!strncmp(cur->attr, attr_en, 2) && cur->len > 6)
			{
				word = _mem_ndup(s->txt + cur->off, cur->len);
				_str_tolower(word, word);
				if (SCWS_IS_NOSTATS(word, cur->len))
				{
					free(word);
					continue;
				}
				free(word);
			}

			/* put to the stats */
			if (!(top = xtree_nget(xt, s->txt + cur->off, cur->len, NULL)))
			{
				top = (scws_top_t) pmalloc_z(xt->p, sizeof(struct scws_topword));
				top->weight = cur->idf;
				top->times = 1;
				strncpy(top->attr, cur->attr, 2);
				xtree_nput(xt, top, sizeof(struct scws_topword), s->txt + cur->off, cur->len);
				cnt++;
			}
			else
			{
				top->weight += cur->idf;
				top->times++;
			}
		}
		while ((cur = cur->next) != NULL);
		scws_free_result(res);
	}

	top = NULL;
	if (cnt > 0)
	{
		/* sort the list */
		list = (scws_top_t *) malloc(sizeof(scws_top_t) * cnt);
		_tops_load_all(xt, list);
		qsort(list, cnt, sizeof(scws_top_t), _tops_cmp);

		/* save to return pointer */
		if (!limit || limit > cnt)
			limit = cnt;
		
		top = tail = (scws_top_t) malloc(sizeof(struct scws_topword));
		memcpy(top, list[0], sizeof(struct scws_topword));
		top->word = strdup(list[0]->word);
		top->next = NULL;

		for (cnt = 1; cnt < limit; cnt++)
		{
			base = (scws_top_t) malloc(sizeof(struct scws_topword));
			memcpy(base, list[cnt], sizeof(struct scws_topword));
			base->word = strdup(list[cnt]->word);
			base->next = NULL;
			tail->next = base;
			tail = base;
		}
		free(list);
	}

	// restore the offset
	s->off = off;
	xtree_free(xt);	
	return top;
}

void scws_free_tops(scws_top_t tops)
{
	scws_top_t cur;

	while ((cur = tops) != NULL)
	{
		tops = cur->next;
		if (cur->word)
			free(cur->word);			
		free(cur);
	}
}
