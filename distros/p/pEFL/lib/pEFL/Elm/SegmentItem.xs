#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Eo ElmSegmentItem;
typedef Evas_Object EvasObject;


MODULE = pEFL::Elm::SegmentItem		PACKAGE = ElmSegmentItemPtr     PREFIX = elm_segment_control_item_

int
elm_segment_control_item_index_get(obj)
	const ElmSegmentItem *obj


EvasObject *
elm_segment_control_item_object_get(obj)
	const ElmSegmentItem *obj


void
elm_segment_control_item_selected_set(obj,selected)
	ElmSegmentItem *obj
	Eina_Bool selected
