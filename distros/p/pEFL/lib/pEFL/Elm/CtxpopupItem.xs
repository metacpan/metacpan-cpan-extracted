#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Ctxpopup_Item ElmCtxpopupItem;
typedef Elm_Widget_Item ElmWidgetItem;


MODULE = pEFL::Elm::CtxpopupItem		PACKAGE = ElmCtxpopupItemPtr     PREFIX = elm_ctxpopupItem_item_

ElmWidgetItem *
elm_ctxpopup_item_prev_get(obj)
	ElmCtxpopupItem *obj


ElmWidgetItem *
elm_ctxpopup_item_next_get(obj)
	ElmCtxpopupItem *obj


void
elm_ctxpopup_item_selected_set(obj,selected)
	ElmCtxpopupItem *obj
	Eina_Bool selected


Eina_Bool
elm_ctxpopup_item_selected_get(obj)
	ElmCtxpopupItem *obj


#void
#elm_ctxpopup_item_init(obj,func,data)
#	ElmCtxpopupItem *obj
#	Evas_Smart_Cb func
#	const void *data
