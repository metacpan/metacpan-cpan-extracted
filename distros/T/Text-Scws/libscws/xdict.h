/**
 * @file xdict (dictionary)
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * $Id: xdict.h,v 1.5 2007/06/05 18:53:38 hightman Exp $
 */

#ifndef	_SCWS_XDICT_20070528_H_
#define	_SCWS_XDICT_20070528_H_

#ifdef HAVE_CONFIG_H
#	include "config.h"
#endif

/* constant var define */
#define	SCWS_WORD_FULL		0x01	// 多字: 整词
#define	SCWS_WORD_PART		0x02	// 多字: 前词段
#define	SCWS_WORD_USED		0x04	// 多字: 已使用
#define	SCWS_WORD_RULE		0x08	// 多字: 自动识别的

#define	SCWS_ZFLAG_N2		0x04	// 单字: 双字名词头
#define	SCWS_ZFLAG_NR2		0x08	// 单字: 词头且为双字人名
#define	SCWS_ZFLAG_WHEAD	0x10	// 单字: 词头
#define	SCWS_ZFLAG_WPART	0x20	// 单字: 词尾或词中
#define	SCWS_ZFLAG_ENGLISH	0x40	// 单字: 夹在中间的英文
#define	SCWS_XDICT_PRIME	0x3ffd	// 词典结构树数：16381

/* xdict open mode */
#define	SCWS_XDICT_XDB		1
#define	SCWS_XDICT_MEM		2

/* data structure for word(12bytes) */
typedef struct scws_word
{
	float tf;
	float idf;
	unsigned char flag;
	char attr[3];
}	word_st, *word_t;

typedef struct scws_xdict
{
	void *xdict;
	int xmode;
#if 0
	word_st qword;
#endif
}	xdict_st, *xdict_t;

/* pub function (api) */
xdict_t xdict_open(const char *fpath, int mode);
void xdict_close(xdict_t xd);

/* return pointer to static data, DO NOT use two or more times in one line, Non-ThreadSafe */
word_t xdict_query(xdict_t xd, const char *key, int len);

#endif
