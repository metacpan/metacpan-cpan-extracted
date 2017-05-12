#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

#include "asciiTeX.h"

/* prevents collision of free() with Perl's free() in XS */
#include "MyFree.h"

AV* c_render (char* eq, int ll) {
  int i, cols, rows;
  char **screen;
  AV* ret = newAV();
  sv_2mortal((SV*)ret);

  screen = asciiTeX(eq, ll, &cols, &rows);

  for (i = 0; i < rows; i++)
  {
	if (cols<0)
		warn("%s\n", screen[i]);
	else
		av_push(ret, newSVpvf("%s", screen[i]));
	MyFree(screen[i]);
  }
  MyFree(screen);

  return ret;
}

MODULE = Text::AsciiTeX		PACKAGE = Text::AsciiTeX	

PROTOTYPES: DISABLE

AV *
c_render (eq, ll)
	char*	eq
	int	ll

