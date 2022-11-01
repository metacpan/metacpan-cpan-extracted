#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Object EvasRectangle;


MODULE = pEFL::Evas::Rectangle		PACKAGE = pEFL::Evas::Rectangle

EvasRectangle *
evas_object_rectangle_add(e)
	EvasCanvas *e

MODULE = pEFL::Evas::Rectangle		PACKAGE = EvasRectanglePtr     PREFIX = evas_object_rectangle_

