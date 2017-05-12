/*
Copyright(c) 1998-2000 NOKUBI Takatsugu <knok@daionet.gr.jp>
Copyright(c) 1997 Nara Institute of Science and Technorogy.
All Rights Reserved.

$Id: ChaSen.xs,v 1.6 2000/04/07 02:39:02 knok Exp $
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* for old version of perl (< 5.004_04?) */
#if !defined(PL_na) && defined(na)
#define PL_na na
#endif
#if !defined(PL_sv_undef) && defined(sv_undef)
#define PL_sv_undef sv_undef
#endif

extern int Cha_optind;
int chasen_getopt_argv(char **, FILE *);

/* FILE * could be set NULL */
/* return: 0 (1: wrong option) */

int chasen_fparse(FILE *, FILE *);
int chasen_sparse(char *, FILE *);
/* return: 0 (1: end) */
char *chasen_fparse_tostr(FILE *);
char *chasen_sparse_tostr(char *);
/* return: pointer to parsed string (NULL: end) */

#define INNER_BUFSIZE   8192
#define CHA_INPUT_SIZE      8192

static unsigned char *pos;

/*PROTOTYPES: DISABLE*/

MODULE = Text::ChaSen		PACKAGE = Text::ChaSen

int
getopt_argv(sv,...)
	SV* sv

	PREINIT:
	char **cargs;
	int i;

	CODE:
	cargs = (char **) malloc(sizeof(char *) * items + 1);
	for (i = 0; i < items; i ++) {
		cargs[i] = SvPV(ST(i), PL_na);
	}
	cargs[items] = NULL;
	RETVAL = chasen_getopt_argv(cargs, NULL);
	free(cargs);

	OUTPUT:
	RETVAL

SV*
sparse_tostr(sv)
	SV* sv

	PREINIT:
	char *r, *s;

	CODE:
	s = SvPV(sv, PL_na);
	r = chasen_sparse_tostr(s);
	RETVAL = newSVpv(r, 0);

	OUTPUT:
	RETVAL

SV*
fparse_tostr(sv)
	SV* sv

	PREINIT:
	char *fname, *out;
	FILE *fp;

	CODE:
	fname = SvPV(sv, PL_na);
	fp = fopen(fname, "r");
	if (fp == NULL) {
		RETVAL = &PL_sv_undef;
	} else {
		RETVAL = newSVpv("", 0);
		while ((out = chasen_fparse_tostr(fp)) != NULL) {
			sv_catpv(RETVAL, out);
		}
		fclose(fp);
	}

	OUTPUT:
	RETVAL

SV*
sparse_tostr_long(sv)
	SV* sv

	PREINIT:
	char *r, *s;

	CODE:
	s = SvPV(sv, PL_na);
	r = chasen_sparse_tostr(s);
	RETVAL = newSVpv(r, 0);

	OUTPUT:
	RETVAL
