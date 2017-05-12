
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

double  _strcmp95(char *ying, char *yang, long y_length, int *ind_c[]);

MODULE = Text::JaroWinkler		PACKAGE = Text::JaroWinkler

PROTOTYPES: ENABLE

double
do_strcmp95( ying, yang, y_length, high_prob = 0, toupper = 0)
  char * ying
  char * yang
  long y_length
  int high_prob
  int toupper
 PREINIT:
  int * ind_c[2];
 INIT:
  ind_c[0] = high_prob ? &high_prob : 0;
  ind_c[1] = toupper ? &toupper : 0;
 CODE:
  RETVAL = _strcmp95(ying, yang, y_length, ind_c);
 OUTPUT:
  RETVAL  

