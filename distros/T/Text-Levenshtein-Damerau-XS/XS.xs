#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "damerau-int.c"

#define MAX(a,b) (((a)>(b))?(a):(b))

/* use the system malloc and free */
#undef malloc
#undef free

MODULE = Text::Levenshtein::Damerau::XS    PACKAGE = Text::Levenshtein::Damerau::XS

PROTOTYPES: ENABLE

int
cxs_edistance (arraySource, arrayTarget, maxDistance)
  AV *    arraySource
  AV *    arrayTarget
  SV *    maxDistance
PPCODE:
  {
  dXSTARG;
  PUSHs(TARG);
  PUTBACK;
  {
  unsigned int i;
  unsigned int lenSource = av_len(arraySource)+1;
  unsigned int lenTarget = av_len(arrayTarget)+1;
  int retval;
 
  if(lenSource > 0 && lenTarget > 0) {
    int matchBool;
    unsigned int srctgt_max = MAX(lenSource,lenTarget);
    if(lenSource != lenTarget)
      matchBool = 0;
    else matchBool = 1;

    {
    /* Convert Perl array to C array */
    unsigned int * arrTarget = malloc(sizeof(int) * lenTarget );
    unsigned int * arrSource = malloc(sizeof(int) * lenSource );

    for (i=0; i < srctgt_max; i++) {
      if(i < lenSource) {
          SV* elem = sv_2mortal(av_shift(arraySource));
          arrSource[ i ] = (int)SvIV((SV *)elem);
      }
      if(i < lenTarget) {
          SV* elem2 = sv_2mortal(av_shift(arrayTarget));
          arrTarget[ i ] = (int)SvIV((SV *)elem2);
  
          /* checks for match */
          if(matchBool && i < lenSource)
            if(arrSource[i] != arrTarget[i])
              matchBool = 0;
      }
    }

    if(matchBool == 1)
      retval = 0;
    else  
      retval = distance(arrSource,arrTarget,lenSource,lenTarget,SvIV(maxDistance));

    free(arrSource);
    free(arrTarget);
    }
  }
  else {
    /* handle a blank string */
    retval = (lenSource>lenTarget)?lenSource:lenTarget;
  }

  sv_setiv_mg(TARG, retval);
  return; /*we did a PUTBACK earlier, do not let xsubpp's PUTBACK run */
  }
  }