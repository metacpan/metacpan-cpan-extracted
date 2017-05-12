/*
 * ExtractWords.xs
 * Last Modification: Mon Oct 13 14:12:37 WEST 2003
 *
 * Copyright (c) 2003 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
 * This module is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#ifdef OP_PROTOTYPE
#undef OP_PROTOTYPE
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <locale.h>
#include <string.h>

#define PERL_POLLUTE

#define MINLENWORD	1
#define MAXLENWORD	32
#define MINLENMULTIWORD	6
#define MINSPACELETTERS	2

char delimiters[] = "\xAB\xB4\xBB !?,;:|\\/@\t\b\f\n\r&=\"()<>{}[]+*~^`";
char chrsep[] = " _#.*-&/";
char chrend[] = " ,;.:\x0A\x0D\x09\"'?!+-*/()[]";

struct def_entity {
	unsigned char entity[9];
	unsigned int length;
	unsigned char character;
};

static struct def_entity entities[28] = {
	{"&agrave;", 8, 0xE0}, {"&aacute;", 8, 0xE1},
	{"&acirc;",  7, 0xE2}, {"&atilde;", 8, 0xE3},
	{"&auml;",   6, 0xE4}, {"&aring;",  7, 0xE5},
	{"&aelig;",  7, 0xE6}, {"&ccedil;", 8, 0xE7},
	{"&egrave;", 8, 0xE8}, {"&eacute;", 8, 0xE9},
	{"&ecirce;", 8, 0xEA}, {"&euml;",   6, 0xEB},
	{"&igrave;", 8, 0xEC}, {"&iacute;", 8, 0xED},
	{"&icirc;",  7, 0xEE}, {"&iuml;",   6, 0xEF},
	{"&ntilde;", 8, 0xF1}, {"&ograve;", 8, 0xF2},
	{"&oacute;", 8, 0xF3}, {"&ocirc;",  7, 0xF4},
	{"&otilde;", 8, 0xF5}, {"&ouml;",   6, 0xF6},
	{"&ugrave;", 8, 0xF9}, {"&uacute;", 8, 0xFA},
	{"&ucirc;",  7, 0xFB}, {"&uuml;",   6, 0xFC},
	{"&yacute;", 8, 0xFD}, {"&yuml;",   6, 0xFF} 
};

#ifdef HAVE_LOCALE_H
void set_locale(unsigned char *locale) {
	setlocale(LC_CTYPE, locale);
	setlocale(LC_COLLATE, locale);
	setlocale(LC_MESSAGES, "");
}
#endif

void unescape_str(unsigned char *s) {
	register int x,y;
	for(x=0, y=0; s[y]; ++x, ++y) {
		if((s[x] = s[y]) == '%') {
			int hex;
			if(isxdigit(s[y+1]) &&
				isxdigit(s[y+2]) &&
					sscanf(&s[y+1], "%02X", &hex)) {
				s[x] = hex;
				y+=2;
			} else if(x > 0 && isDIGIT(s[y-1]) && strchr(chrend, s[y+1])) {
				int j = 2;
				while(isDIGIT(s[x-j])) j++;
				if(!strchr(chrend, s[x-j])) s[x] = ' ';
			} else s[x] = ' ';
		}
	}
	s[x] = '\0';
}

bool entity2char(unsigned char **s, unsigned char *cstr,
				unsigned int len, unsigned char c) {
	if(strncmp(*s, cstr, len) == 0) {
		*s = *s+len-1;
		**s = c;
		return TRUE;
	}
	return FALSE;
}

void str2lower(unsigned char *s) {
	while(*s) {
		if(isalpha(*s)) *s = tolower(*s);
		s++;
	}
}

void clean_repeated_chars(unsigned char *s) {
	unsigned char *p = s;
	while(*s) {
		if(*s == '#' && isxdigit(*(s+1))) {
			while(*s == '#' || isxdigit(*s)) {
				*p = *s;
				s++;
				p++;
			}
		}
		if(isalpha(*s) && *s == *(s+1) && *s == *(s+2))
			while(*s == *(s+1)) s++;
		*p = *s;
		s++;
		p++;
	}
	*p = '\0';
}

bool extension(unsigned char *s, unsigned char *extension, int len) {
	return((!strncmp(s, extension, len) && !isalpha(*(s+len+1))) ? TRUE : FALSE);
}

bool check_extension(unsigned char *s) {
	return( extension(s, "asp",  3) ? TRUE :
		extension(s, "html", 4) ? TRUE :
		extension(s, "htm",  3) ? TRUE :
		extension(s, "gif",  3) ? TRUE :
		extension(s, "png",  3) ? TRUE :
		extension(s, "jpeg", 4) ? TRUE :
		extension(s, "jpg",  3) ? TRUE :
		extension(s, "js",   2) ? TRUE :
		extension(s, "swf",  3) ? TRUE :
		extension(s, "pl",   2) ? TRUE :
		extension(s, "php",  3) ? TRUE : FALSE);
}


bool space_words(unsigned char *s, unsigned char c) {
	unsigned char *p = s;
	int space = 1;
	int letter = 0;
	p++;
	while(*p) {
		if(*p == c) space++;
		else if(isalpha(*p)) letter++;
		else break;
		p++;
	}
	return((space > MINSPACELETTERS && space == letter) ? TRUE : FALSE);
}

bool hex_dec(unsigned char *s) {
	return((strchr(" \":", *(s-1)) &&
		isxdigit(*(s+1)) &&
		isxdigit(*(s+2)) &&
		isxdigit(*(s+3)) &&
		isxdigit(*(s+4)) &&
		isxdigit(*(s+5)) &&
		isxdigit(*(s+6)) &&
		!isalnum(*(s+7))) ? TRUE : FALSE);
}

bool multiword(unsigned char *s) {
	unsigned char *p = s;
	int c = 0;
	p--;
	while(*p) {
		if(isalnum(*p)) c++;
		else break;
		p--;
	}
	if(c <= MINLENMULTIWORD) return FALSE;
	c = 0;
	s++;
	while(*s) {
		if(isalnum(*s)) c++;
		else break;
		s++;
	}
	return((c > MINLENMULTIWORD) ? TRUE : FALSE);
}

void str_normalize(unsigned char *s) {
	unsigned char *p = s;

	while(*s && !isalnum(*s) && *s != '&' && *s != '(') s++;
	str2lower(s);
	while(*s) {
		if(*s == '&') {
			register int i;
			for(i=0; i<28; i++)
				if(entity2char(&s, entities[i].entity, entities[i].length, entities[i].character))
					break;
		}
		if(isalpha(*(s-1)) && strchr(chrsep, *s) && isalpha(*(s+1))) {
			if(space_words(s, *s)) {
				char c = *s;
				while(*s) {
					if(*s == c) s++;
					else if(!isalpha(*s)) break;
					*p = *s;
					s++;
					p++;
				}
			}
		}
		if((*s == '_' || *s == '-' || *s == '\'') && (!isalnum(*(s+1)) || !isalnum(*(s-1))))
			*s = ' ';
		else if(*s == '0' && isalpha(*(s+1)) && isalpha(*(s-1)))
			*s = 'o';
		else if(*s == '(' && *(s+1) == ')' && isalpha(*(s+2)) && isalpha(*(s-1))) {
			*(s+1) = 'o';
			s++;
		} else if(*s == '.') {
			if(!((isdigit(*(s-1)) && isdigit(*(s+1))) || check_extension(s+1)))
				*s = ' ';
		} else if(*s == '-') {
			if(multiword(s)) *s = ' ';
		} else if(*s == '#') {
			if(hex_dec(s)) {
				while(*s == '#' || isxdigit(*s)) {
					*p = *s;
					s++;
					p++;
				}
			} else
				*s = ' ';
		} else if(*s == '@' &&
				*(s-1) != 'a' && *(s-1) != 'A' && isalpha(*(s-1)) &&
				*(s+1) != 'a' && *(s+1) != 'A' && isalpha(*(s+1))) {
			unsigned int i = 2;
			while(*(s+i) && isalpha(*(s+i))) i++;
			if(!(*(s+i) == '.' && isalpha(*(s+i+1)))) *s = 'a';
		}
		*p = *s;
		s++;
		p++;
	}
	*p = '\0';
}

MODULE = Text::ExtractWords	PACKAGE = Text::ExtractWords	PREFIX = ew_

PROTOTYPES: DISABLE

void
ew_words_list(aref, source, ...)
		SV	*aref;
		char	*source;
	PREINIT:
		char *locale = NULL;
		char *t = NULL;
		I32 n = 0;
		I32 minlenword = MINLENWORD;
		I32 maxlenword = MAXLENWORD;
	PPCODE:
		if(items == 3) {SV *hconf = ST(2);
			if(SvROK(hconf) && SvTYPE(SvRV(hconf)) == SVt_PVHV) {
				HV *hv = (HV *)SvRV(hconf);
				if(hv_exists(hv, "minlen", 6)) {
					SV **svalue = hv_fetch(hv, "minlen", 6, 0);
					minlenword = SvIV(*svalue);
				}
				if(hv_exists(hv, "maxlen", 6)) {
					SV **svalue = hv_fetch(hv, "maxlen", 6, 0);
					maxlenword = SvIV(*svalue);
				}
				if(hv_exists(hv, "locale", 6)) {
					SV **svalue = hv_fetch(hv, "locale", 6, 0);
					locale = SvPV(*svalue, PL_na);
				}
			} else
				croak("not hash ref passed to Text::ExtractWords::words_list");
		}
#ifdef HAVE_LOCALE_H
		if(locale) set_locale(locale);
#endif
		if(SvROK(aref) && SvTYPE(SvRV(aref)) == SVt_PVAV) {
			unsigned long ls;
			if(ls = strlen(source)) {
				AV *av = (AV *)SvRV(aref);
				unescape_str(source);
				str_normalize(source);
				//fprintf(stdout, "-->%s<--\n", source);
				clean_repeated_chars(source);
				for(t = strtok(source, delimiters); t != NULL; t = strtok(NULL, delimiters)) {
					n = strlen(t);
					if(n >= minlenword && n <= maxlenword)
						av_push(av, newSVpv(t, n));
				}
			}
		} else
			croak("not array ref passed to Text::ExtractWords::words_list");



void
ew_words_count(href, source, ...)
		SV	*href;
		char	*source;
	PREINIT:
		char *locale = NULL;
		char *t = NULL;
		I32 n = 0;
		I32 minlenword = MINLENWORD;
		I32 maxlenword = MAXLENWORD;
		unsigned long count;
	PPCODE:
		if(items == 3) {
			SV *hconf = ST(2);
			if(SvROK(hconf) && SvTYPE(SvRV(hconf)) == SVt_PVHV) {
				HV *hv = (HV *)SvRV(hconf);
				if(hv_exists(hv, "minlen", 6)) {
					SV **svalue = hv_fetch(hv, "minlen", 6, 0);
					minlenword = SvIV(*svalue);
				}
				if(hv_exists(hv, "maxlen", 6)) {
					SV **svalue = hv_fetch(hv, "maxlen", 6, 0);
					maxlenword = SvIV(*svalue);
				}
				if(hv_exists(hv, "locale", 6)) {
					SV **svalue = hv_fetch(hv, "locale", 6, 0);
					locale = SvPV(*svalue, PL_na);
				}
			} else
				croak("not hash ref passed to Text::ExtractWords::words_count");
		}
#ifdef HAVE_LOCALE_H
		if(locale) set_locale(locale);
#endif
		if(SvROK(href) && SvTYPE(SvRV(href)) == SVt_PVHV) {
			unsigned long ls;
			if(ls = strlen(source)) {
				HV *hv = (HV *)SvRV(href);
				unescape_str(source);
				str_normalize(source);
				//fprintf(stdout, "-->%s<--\n", source);
				clean_repeated_chars(source);
				for(t = strtok(source, delimiters); t != NULL; t = strtok(NULL, delimiters)) {
					n = strlen(t);
					if(n >= minlenword && n <= maxlenword) {
						count = 1;
						if(hv_exists(hv, t, n)) {
							SV **svalue = hv_fetch(hv, t, n, 0);
							count = SvIV(*svalue) + 1;
						}
						hv_store(hv, t, n, newSViv(count), 0);
					}
				}
			}
		} else
			croak("not hash ref passed to Text::ExtractWords::words_count");
