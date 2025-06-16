#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Coord_Rectangle EvasCoordRectangle;


MODULE = pEFL::Evas::Coord::Rectangle		PACKAGE = EvasCoordRectanglePtr

Evas_Coord
x(rect)
    EvasCoordRectangle *rect
CODE:
    RETVAL = rect->x;
OUTPUT:
    RETVAL
  
  
Evas_Coord
y(rect)
    EvasCoordRectangle *rect
CODE:
    RETVAL = rect->y;
OUTPUT:
    RETVAL
    

Evas_Coord
w(rect)
    EvasCoordRectangle *rect
CODE:
    RETVAL = rect->w;
OUTPUT:
    RETVAL
    
    
Evas_Coord
h(rect)
    EvasCoordRectangle *rect
CODE:
    RETVAL = rect->h;
OUTPUT:
    RETVAL
