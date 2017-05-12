#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

MODULE = Text::Levenshtein::XS    PACKAGE = Text::Levenshtein::XS

PROTOTYPES: ENABLE

void *
xs_distance (arraySource, arrayTarget, maxDistance)
  AV *    arraySource
  AV *    arrayTarget
  SV *    maxDistance
INIT:
    unsigned int i,j,edits,*s,*t,*v0,*v1;
    unsigned int lenSource = av_len(arraySource)+1;
    unsigned int lenTarget = av_len(arrayTarget)+1;
    /* hold the user supplied argument for max distance */
    unsigned int md = SvUV(maxDistance);
    /* mdx contains a calculated max different (md) to use in the algorithm itself */
    unsigned int mdx = (md == 0) ? MAX(lenSource,lenTarget) : md;
    unsigned int diff = MAX(lenSource , lenTarget) - MIN(lenSource, lenTarget);
    unsigned int undef = 0;
    SV* elem;

    if(lenSource == 0 || lenTarget == 0) {
        if( md != 0 && MAX(lenSource, lenTarget) > md ) {
            XSRETURN_UNDEF;
        }
        else {
            XPUSHs(sv_2mortal(newSVuv( MAX(lenSource, lenTarget) )));
            XSRETURN(1);
        }
    }

    if (diff > mdx)
        XSRETURN_UNDEF;
PPCODE:
{
    Newx(s,  (lenSource + 1), unsigned int); // source
    Newx(t,  (lenTarget + 1), unsigned int); // target
    Newx(v0, (lenTarget + 1), unsigned int); // vector 0
    Newx(v1, (lenTarget + 1), unsigned int); // vector 1
    /* init first distance row with worst-case distance values */
    for (i=0; i < (lenTarget + 1); i++) {
        v0[i] = i;
    }

    for (i=0; i < lenSource; i++) {
        if( undef > 0 )
            break;

        elem = sv_2mortal(av_shift(arraySource));
        s[i] = SvUV((SV *)elem);

        v1[0] = i + 1;

        for (j = 0; j < lenTarget; j++) {
            if(i == 0) {
                elem = sv_2mortal(av_shift(arrayTarget));
                t[j] = SvUV((SV *)elem); 
            }

            v1[j + 1] = MIN(MIN(v1[j] + 1, v0[j + 1] + 1), (v0[j] + ((s[i] == t[j]) ? 0 : 1)));

            /* Check the current distance once we have reached the appropriate index         */
            /* v1[0] == index of current distance of v1 (i.e. v1[v1[0]] == current distance) */
            /* We also take diff into account so we can guess if current distance + length   */
            /* difference would push the total edit distance over the max distance           */
            if( v1[0] == j )
                if( mdx < ((diff > v1[j]) ? (diff - v1[j]) : (diff + v1[j])) )
                    if( mdx > v1[j] )
                        undef = 1;
        }


        /* copy v1 to v0. no need to copy the array on the last iteration */
        if( i < lenSource ) {
            for (j = 0; j < (lenTarget + 1); j++) 
                v0[j] = v1[j];
        }
    }

    if( md > 0 && md < v1[lenTarget] )
        undef = 1;

    /* don't check md here so that if something is wrong with the earlier short circuit the tests will catch it */
    XPUSHs(sv_2mortal( (undef == 1) ? &PL_sv_undef : newSVuv(v1[lenTarget]) ));

    Safefree(s);
    Safefree(t);
    Safefree(v0);
    Safefree(v1);
} /* PPCODE */

