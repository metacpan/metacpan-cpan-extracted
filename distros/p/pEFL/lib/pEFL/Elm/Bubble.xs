#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmBubble;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Bubble		PACKAGE = pEFL::Elm::Bubble

ElmBubble *
elm_bubble_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Bubble		PACKAGE = ElmBubblePtr     PREFIX = elm_bubble_

void
elm_bubble_pos_set(obj,pos)
	ElmBubble *obj
	int pos


int
elm_bubble_pos_get(obj)
	const ElmBubble *obj
