#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Object EvasPolygon;


MODULE = pEFL::Evas::Polygon		PACKAGE = pEFL::Evas::Polygon

EvasPolygon *
evas_object_polygon_add(e)
	EvasCanvas *e

MODULE = pEFL::Evas::Polygon		PACKAGE = EvasPolygonPtr     PREFIX = evas_object_polygon_

void
evas_object_polygon_point_add(obj,x,y)
	EvasPolygon *obj
	Evas_Coord x
	Evas_Coord y


void
evas_object_polygon_points_clear(obj)
	EvasPolygon *obj
