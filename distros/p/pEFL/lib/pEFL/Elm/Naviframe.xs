#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Naviframe ElmNaviframe;
typedef Elm_Naviframe_Item ElmNaviframeItem;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Naviframe		PACKAGE = pEFL::Elm::Naviframe

ElmNaviframe * 
elm_naviframe_add(EvasObject *parent)

MODULE = pEFL::Elm::Naviframe		PACKAGE = ElmNaviframePtr     PREFIX = elm_naviframe_


ElmNaviframeItem *
elm_naviframe_item_push(obj,title_label,prev_btn,next_btn,content,item_style)
	ElmNaviframe *obj
	const char *title_label
	EvasObject *prev_btn
	EvasObject *next_btn
	EvasObject *content
	const char *item_style
	

void
elm_naviframe_event_enabled_set(obj,enabled)
	ElmNaviframe *obj
	Eina_Bool enabled


Eina_Bool
elm_naviframe_event_enabled_get(obj)
	const ElmNaviframe *obj


void
elm_naviframe_content_preserve_on_pop_set(obj,preserve)
	ElmNaviframe *obj
	Eina_Bool preserve


Eina_Bool
elm_naviframe_content_preserve_on_pop_get(obj)
	const ElmNaviframe *obj


void
elm_naviframe_prev_btn_auto_pushed_set(obj,auto_pushed)
	ElmNaviframe *obj
	Eina_Bool auto_pushed


Eina_Bool
elm_naviframe_prev_btn_auto_pushed_get(obj)
	const ElmNaviframe *obj


ElmNaviframeItem *
elm_naviframe_top_item_get(obj)
	const ElmNaviframe *obj


ElmNaviframeItem *
elm_naviframe_bottom_item_get(obj)
	const ElmNaviframe *obj


EvasObject *
elm_naviframe_item_pop(obj)
	ElmNaviframe *obj


ElmNaviframeItem *
elm_naviframe_item_insert_before(obj,before,title_label,prev_btn,next_btn,content,item_style)
	ElmNaviframe *obj
	ElmNaviframeItem *before
	const char *title_label
	EvasObject *prev_btn
	EvasObject *next_btn
	EvasObject *content
	const char *item_style


void
elm_naviframe_item_simple_promote(obj,content)
	ElmNaviframe *obj
	EvasObject *content


ElmNaviframeItem *
elm_naviframe_item_insert_after(obj,after,title_label,prev_btn,next_btn,content,item_style)
	ElmNaviframe *obj
	ElmNaviframeItem *after
	const char *title_label
	EvasObject *prev_btn
	EvasObject *next_btn
	EvasObject *content
	const char *item_style


