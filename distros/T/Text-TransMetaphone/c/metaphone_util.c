#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>
#include "metaphone_util.h"

/*
* * If META_USE_PERL_MALLOC is defined we use Perl's memory routines.
* */
#ifdef META_USE_PERL_MALLOC
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define META_MALLOC(v,n,t) New(1,v,n,t)
#define META_REALLOC(v,n,t) Renew(v,n,t)
#define META_FREE(x) Safefree((x))
 
#else
 
#define META_MALLOC(v,n,t) \
          (v = (t*)malloc(((n)*sizeof(t))))
#define META_REALLOC(v,n,t) \
	                  (v = (t*)realloc((v),((n)*sizeof(t))))
#define META_FREE(x) free((x))
	 
#endif /* META_USE_PERL_MALLOC */


metastring *
NewMetaString(unsigned char *init_str)
{
    metastring *s;
    unsigned char empty_string[] = "";

    META_MALLOC(s, 1, metastring);
    assert( s != NULL );

    if (init_str == NULL)
	init_str = empty_string;
    s->length  = utf8_length(init_str, init_str+strlen((char*)init_str));
    /* preallocate a bit more for potential growth */
    s->bufsize = s->length + 7;

    META_MALLOC(s->str, s->bufsize, unsigned char);
    assert( s->str != NULL );
    
    strncpy((char*)s->str, (char*)init_str, s->length + 1);
    s->free_string_on_destroy = 1;

    return s;
}


void
DestroyMetaString(metastring * s)
{
    if (s == NULL)
	return;

    if (s->free_string_on_destroy && (s->str != NULL))
	META_FREE(s->str);

    META_FREE(s);
}


void
IncreaseBuffer(metastring * s, int chars_needed)
{
    META_REALLOC(s->str, (s->bufsize + chars_needed + 10), unsigned char);
    assert( s->str != NULL );
    s->bufsize = s->bufsize + chars_needed + 10;
}


void
MakeUpper(metastring * s)
{
    unsigned char *i;

    for (i = s->str; *i; i++)
      {
	  *i = toupper(*i);
      }
}


int
GetLength(metastring * s)
{
    return s->length;
}


unsigned char
GetAt(metastring * s, int pos)
{
    if ((pos < 0) || (pos >= s->length))
	return '\0';

    return ((unsigned char) *(s->str + pos));
}


void
SetAt(metastring * s, int pos, unsigned char c)
{
    if ((pos < 0) || (pos >= s->length))
	return;

    *(s->str + pos) = c;
}


/* 
   Caveats: the START value is 0 based
*/
int
StringAt(metastring * s, int start, int length, ...)
{
    unsigned char *test;
    unsigned char *pos;
    va_list ap;

    if ((start < 0) || (start >= s->length))
        return 0;

    pos = (s->str + start);
    va_start(ap, length);

    do
      {
	  test = (unsigned char*)va_arg(ap, char *);
	  if (*test && (strncmp((char*)pos, (char*)test, length) == 0))
	      return 1;
      }
    while (strcmp((char*)test, ""));

    va_end(ap);

    return 0;
}


void
MetaphAdd(metastring * s, unsigned char *new_str)
{
    int add_length;

    // fprintf (stderr, "Adding: %s\n", new_str );
    if (new_str == NULL)
	return;

    // add_length = strlen(new_str);
    add_length = utf8_length(new_str, new_str+strlen((char*)new_str));
    if ((s->length + add_length) > (s->bufsize - 1))
      {
	  IncreaseBuffer(s, add_length);
      }

    strcat((char*)s->str, (char*)new_str);
    s->length += add_length;
    // fprintf (stderr, "  Now: %s\n", s->str);
}
