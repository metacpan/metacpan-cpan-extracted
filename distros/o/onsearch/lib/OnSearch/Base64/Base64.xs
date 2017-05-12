/* $Id: Base64.xs,v 1.3 2005/07/23 05:03:50 kiesling Exp $  */
/* Derived from the encdec.c program posted to              */
/* comp.mail.mime.                                          */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

char    vec[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = OnSearch::Base64		PACKAGE = OnSearch::Base64
PROTOTYPES: ENABLE


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

SV *encode_base64(s)
	char *s;
	CODE:
        int     c,
                n = 0,
                p,
                i,
                count = 0;
        long    val = 0;
        char    enc[4];
	int line = 1, idx = 0;
	char *t, *tp;
	t = (char *)safemalloc (77 * sizeof (char));

	while ((c = (*s++)) != 0)
        {
                if (n++ <= 2)
                {
                        val <<= 8;
                        val += c;
                        continue;
                }

                for (i = 0; i < 4; i++)
                {
                        enc[i] = val & 63;
                        val >>= 6;
                }

                for (i = 3; i >= 0; i--)
			t[idx++] = vec[enc[i]];
                	
                n = 1;
                count += 4;
                val = c;

                if (count >= 76)
                {
			t[idx++] = '\n';
			t[idx] = 0;
			tp = (char *)safemalloc (77 * line * sizeof (char));
			strncpy (tp, t, idx);
			safefree (t);
			++line;
			t = (char *)safemalloc (77 * line * sizeof (char));
			strncpy (t, tp, idx);
			safefree (tp);
                        count = 0;
                }
        }
        if (n == 1)
        {
                val <<= 16;
                for (i = 0; i < 4; i++)
                {
                        enc[i] = val & 63;
                        val >>= 6;
                }
                enc[0] = enc[1] = 64;
        }
        if (n == 2)
        {
                val <<= 8;
                for (i = 0; i < 4; i++)
                {
                        enc[i] = val & 63;
                        val >>= 6;
                }
                enc[0] = 64;
        }
        if (n == 3)
                for (i = 0; i < 4; i++)
                {
                        enc[i] = val & 63;
                        val >>= 6;
                }
        if (n)
        {
                for (i = 3; i >= 0; i--)
			t[idx++] = vec[enc[i]];
        }
	t[idx++] = '\n';
	t[idx++] = 0;
	RETVAL = newSVpv (t, strlen (t));
	OUTPUT:
		RETVAL


SV *decode_base64(s)
	char *s;
	CODE:
        int     i, num, len, j;
        long    d, val;
        char    nw[4], buf[81], *p, *c, *n = NULL, *n1 = NULL;
	char    *o = (char *)safemalloc (1024 * sizeof(char));
	int	idx = 0;

	for (n = s, n1 = strchr (s, '\n'); 
		n1;
		n = n1 + 1, n1 = strchr (n, '\n')) {
	    strncpy (buf, n, n1 - n);
                len = n1 - n;
                for (i = 0; i < len; i += 4)
                {
                        val = 0;
                        num = 3;
                        c = buf+i; 
                        if (c[2] == '=')
                                num = 1;
                        else if (c[3] == '=')
                                num = 2;

                        for (j = 0; j <= num; j++)
                        {
                                if (!(p = strchr(vec, c[j])))
                                {
                                 fprintf(stderr, 
				"Base64::decode_base64:\n%s\nnot in base64\n", 
					s);
			            XSRETURN_UNDEF;
                                }
                                d = p-vec;
                                d <<= (3-j)*6;
                                val += d;
                        }
                        for (j = 2; j >= 0; j--)
                        {
                                nw[j] = val & 255;
                                val >>= 8;
                        }
			for (j = 0; j <= 2; j++) 
			   o[idx++] = nw[j];
			o[idx] = 0;
                }
	}
		RETVAL = newSVpv (o, strlen (o));
	OUTPUT:
		RETVAL




        

