/* ----------------------------------------------------------------------------
 * perlre_test.c
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2007 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id: /mirror/erlang/perlre/perlec/example/perlre_test.c 475 2007-06-11T07:46:50.513254Z hio  $
 * ------------------------------------------------------------------------- */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include "perlec.h"
#include <stdio.h>
#include <stdlib.h>

typedef struct
{
	int len;
	struct{
		int len;
		char* str;
	}data[1];
} my_array;

typedef struct
{
	int len;
	char str[1];
} my_scalar;

static void* array_new(perlec_t* perlec, int len, int guessed_size)
{
	my_array* a;
	a  = malloc(sizeof(*a)+(len-1)*sizeof(a->data[0]));
	a->len = len;
	return a;
}
static void  array_store(void* array, int idx, const void* value, int len)
{
	my_array* a = array;
	if( value!=NULL )
	{
		char* buf = malloc(len+1);
		memcpy(buf, value, len);
		buf[len] = '\0';
		a->data[idx].len = len;
		a->data[idx].str = buf;
	}else
	{
		a->data[idx].len = 0;
		a->data[idx].str = NULL;
	}
	return;
}
static void  array_delete(void* array)
{
	my_array* a = array;
	int i;
	for( i=0; i<a->len; ++i )
	{
		if( a->data[i].str!=NULL )
		{
			free(a->data[i].str);
		}
	}
	free(a);
	return;
}
static void array_dump(const void* array)
{
	const my_array* a = array;
	int i;
	printf("a = %p\n", a);
	if( a!=NULL )
	{
		printf("%d elem(s).\n", a->len);
		for( i=0; i<a->len; ++i )
		{
			int len = a->data[i].len;
			const char* s = a->data[i].str;
			printf("%d: [%.*s] (%d)\n", i, s!=NULL?len:6, s!=NULL?s:"(null)", len);
		}
	}else
	{
		printf("%d elem(s).\n", -1);
	}
}

static void* scalar_new(perlec_t* perlec, const void* str, int len)
{
	my_scalar* s;
	s  = malloc(sizeof(*s)+(len-1));
	s->len = len;
	memcpy(s->str, str, len);
	s->str[len] = '\0';
	return s;
}
static void scalar_delete(void* s)
{
	free(s);
	return;
}

#include <stdio.h>
#include <stdlib.h>
int perlec_test(int argc, char **argv)
{
	perlec_t* perlec;
	my_array* a;
	
	const char* str;
	const char* re;
	int str_len;
	int re_len;
	int f_compile;
	int n_bench;
	int i;
	
	perlec = malloc(sizeof(*perlec));
	perlec_init(perlec);
	perlec->array_new    = &array_new;
	perlec->array_store  = &array_store;
	perlec->array_delete = &array_delete;
	perlec->scalar_new    = &scalar_new;
	perlec->scalar_delete = &scalar_delete;
	
	/* parse args. */
	str = "123";
	re  = "(\\d+)";
	f_compile = 0;
	n_bench = 0;
	for( i=1; i<argc; ++i )
	{
		if( strcmp(argv[i], "--compile")==0 )
		{
			f_compile = 1;
			continue;
		}
		if( strcmp(argv[i], "--bench")==0 )
		{
			++i;
			if( i<argc )
			{
				n_bench = atoi(argv[i]);
			}else
			{
				n_bench = 1000*1000;
			}
			continue;
		}
		break;
	}
	if( i<argc )
	{
		str = argv[i++];
	}
	if( i<argc )
	{
		re = argv[i++];
	}
	str_len = strlen(str);
	re_len  = strlen(re);
	if( n_bench<1 )
	{
		n_bench = 1;
	}
	
	/* works. */
	if( n_bench>1 )
	{
		printf("iter = %d\n", n_bench);
	}
	printf("str  = [%s] (%d)\n", str, str_len);
	printf("re   = [%s] (%d)\n", re,  re_len);
	printf("compile  = %s\n", f_compile ? "yes" : "no");
	if( f_compile )
	{
		void* re_obj = perlec_compile(perlec, re, re_len, PERLEC_ROPT_NONE);
		printf("re_obj = %p\n", re_obj);
		if( re_obj==NULL )
		{
			my_scalar* e = perlec_errmsg(perlec);
			if( e!=NULL )
			{
				printf("error: %.*s\n", e->len, e->str);
				scalar_delete(e);
			}else
			{
				printf("no match\n");
			}
			return 1;
		}
		for( i=0; i<n_bench; ++i )
		{
			a = perlec_match_rx(perlec, str, str_len, re_obj, PERLEC_ROPT_NONE);
			if( i==0 )
			{
				printf("match\n");
				array_dump(a);
			}
			if( a!=NULL )
			{
				perlec->array_delete(a);
			}
		}
	}else
	{
		printf("re_obj = off\n");
		for( i=0; i<n_bench; ++i )
		{
			a = perlec_match(perlec, str, str_len, re, re_len, PERLEC_ROPT_NONE);
			if( a==NULL )
			{
				my_scalar* e = perlec_errmsg(perlec);
				if( e!=NULL )
				{
					printf("error: %.*s\n", e->len, e->str);
					scalar_delete(e);
				}else
				{
					printf("no match\n");
				}
				break;
			}
			if( i==0 )
			{
				printf("match\n");
				array_dump(a);
			}
			perlec->array_delete(a);
		}
	}
	
	perlec_discard(perlec);
	return 0;
}

int main(int argc, char **argv)
{
	return perlec_test(argc, argv);
}

/* ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
