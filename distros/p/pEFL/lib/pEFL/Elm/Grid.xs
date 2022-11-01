#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Grid ElmGrid;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Grid		PACKAGE = pEFL::Elm::Grid

ElmGrid *
elm_grid_add(EvasObject *parent)

MODULE = pEFL::Elm::Grid		PACKAGE = ElmGridPtr     PREFIX = elm_grid_

void
elm_grid_pack_set(subobj,x,y,w,h)
	ElmGrid *subobj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
elm_grid_pack_get(subobj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	ElmGrid *subobj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h

void
elm_grid_size_set(obj,w,h)
	ElmGrid *obj
	int w
	int h


void
elm_grid_size_get(obj,OUTLIST w,OUTLIST h)
	const ElmGrid *obj
	int w
	int h


void
elm_grid_clear(obj,clear)
	ElmGrid *obj
	Eina_Bool clear


void
elm_grid_unpack(obj,subobj)
	ElmGrid *obj
	EvasObject *subobj


void
elm_grid_pack(obj,subobj,x,y,w,h)
	ElmGrid *obj
	EvasObject *subobj
	int x
	int y
	int w
	int h



