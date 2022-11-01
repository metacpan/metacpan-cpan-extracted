#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Textblock_Style EvasTextblockStyle;


MODULE = pEFL::Evas::TextblockStyle		PACKAGE = pEFL::Evas::TextblockStyle

EvasTextblockStyle *
evas_textblock_style_new()

MODULE = pEFL::Evas::TextblockStyle		PACKAGE = EvasTextblockStylePtr     PREFIX = evas_textblock_style_


void
evas_textblock_style_free(ts)
	EvasTextblockStyle *ts


void
evas_textblock_style_set(ts,text)
	EvasTextblockStyle *ts
	const char *text


char *
evas_textblock_style_get(ts)
	const EvasTextblockStyle *ts
	
	

