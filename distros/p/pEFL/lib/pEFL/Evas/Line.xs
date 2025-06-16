#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Line EvasLine;


MODULE = pEFL::Evas::Line		PACKAGE = pEFL::Evas::Line

EvasLine *
evas_object_line_add(e)
	EvasCanvas *e

MODULE = pEFL::Evas::Line		PACKAGE = EvasLinePtr     PREFIX = evas_object_line_


void
evas_object_line_xy_set(obj,x1,y1,x2,y2)
	EvasLine *obj
	int x1
	int y1
	int x2
	int y2


void
evas_object_line_xy_get(obj,OUTLIST x1,OUTLIST y1,OUTLIST x2,OUTLIST y2)
	const EvasLine *obj
	int x1
	int y1
	int x2
	int y2
