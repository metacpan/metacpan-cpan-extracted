#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Flip ElmFlip;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Flip		PACKAGE = pEFL::Elm::Flip

ElmFlip *
elm_flip_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Flip		PACKAGE = ElmFlipPtr     PREFIX = elm_flip_

void
elm_flip_interaction_direction_hitsize_set(obj,dir,hitsize)
	ElmFlip *obj
	int dir
	double hitsize


double
elm_flip_interaction_direction_hitsize_get(obj,dir)
	ElmFlip *obj
	int dir


void
elm_flip_interaction_direction_enabled_set(obj,dir,enabled)
	ElmFlip *obj
	int dir
	Eina_Bool enabled


Eina_Bool
elm_flip_interaction_direction_enabled_get(obj,dir)
	ElmFlip *obj
	int dir


void
elm_flip_perspective_set(obj,foc,x,y)
	EvasObject *obj
	int foc
	int x
	int y
