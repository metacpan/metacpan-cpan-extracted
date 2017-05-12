#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "double_metaphone.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Text::DoubleMetaphone		PACKAGE = Text::DoubleMetaphone		


double
constant(name,arg)
	char *		name
	int		arg


void
double_metaphone(str)
	char *	str
        PREINIT:
        char *codes[2];
        PPCODE:
        DoubleMetaphone(str, codes);

        XPUSHs(sv_2mortal(newSVpv(codes[0], 0)));
        if ((GIMME == G_ARRAY) && strcmp(codes[0], codes[1])) 
          {
            XPUSHs(sv_2mortal(newSVpv(codes[1], 0)));
          } 
        Safefree(codes[0]);
        Safefree(codes[1]);
