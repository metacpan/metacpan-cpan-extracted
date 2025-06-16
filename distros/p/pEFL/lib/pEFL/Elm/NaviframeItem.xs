#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Naviframe_Item ElmNaviframeItem;
typedef Elm_Naviframe ElmNaviframe;
typedef Evas_Object EvasObject;


MODULE = pEFL::Elm::NaviframeItem		PACKAGE = ElmNaviframeItemPtr     PREFIX = elm_naviframe_item_

void
elm_naviframe_item_pop_to(obj)
	ElmNaviframeItem *obj


Eina_Bool
elm_naviframe_item_title_enabled_get(obj)
	const ElmNaviframeItem *obj


void
elm_naviframe_item_title_enabled_set(obj,enable,transition)
	ElmNaviframeItem *obj
	Eina_Bool enable
	Eina_Bool transition


void
elm_naviframe_item_promote(obj)
	ElmNaviframeItem *obj


void
_elm_naviframe_item_pop_cb_set(item,parent,id)
	ElmNaviframeItem *item
	ElmNaviframe *parent
	int id
PREINIT:
	_perl_gendata *data = NULL;
	UV paddr;
CODE:
	paddr = PTR2IV(parent);
	// Save C struct with necessary infos to link to perl side
	data = perl_save_gen_cb(aTHX_ paddr, 0, id);
	elm_naviframe_item_pop_cb_set(item,call_perl_item_pop_cb,data);
	//
	// This doesn't work, because data of item_pop_cb_set seems not to be
	// passed to elm_object_item_del_cb
	//elm_object_item_del_cb_set(item,call_perl_gen_del);
	

void
elm_naviframe_item_style_set(obj,style)
	ElmNaviframeItem *obj
	const char *style


char *
elm_naviframe_item_style_get(obj)
	const ElmNaviframeItem *obj
