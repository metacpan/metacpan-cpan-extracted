#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Genlist_Item ElmGenlistItem;
typedef Elm_Genlist_Item_Class ElmGenlistItemClass;
typedef Elm_Object_Item ElmObjectItem;
typedef Elm_Genlist_Item ElmGenlistItem;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::GenlistItem		PACKAGE = ElmGenlistItemPtr     PREFIX = elm_genlist_item_

void
elm_genlist_item_tooltip_text_set(it,text)
	ElmObjectItem *it
	const char *text


# void
# elm_genlist_item_tooltip_content_cb_set(it,func,data,del_cb)
#	ElmObjectItem *it
#	SV* func
#	void *data
#	SV* del_cb


void
elm_genlist_item_tooltip_unset(it)
	ElmObjectItem *it


void
elm_genlist_item_tooltip_style_set(it,style)
	ElmObjectItem *it
	const char *style


char *
elm_genlist_item_tooltip_style_get(it)
	const ElmObjectItem *it


Eina_Bool
elm_genlist_item_tooltip_window_mode_set(it,disable)
	ElmObjectItem *it
	Eina_Bool disable


Eina_Bool
elm_genlist_item_tooltip_window_mode_get(it)
	const ElmObjectItem *it


void
elm_genlist_item_cursor_set(it,cursor)
	ElmObjectItem *it
	const char *cursor


char *
elm_genlist_item_cursor_get(it)
	const ElmObjectItem *it


void
elm_genlist_item_cursor_unset(it)
	ElmObjectItem *it


void
elm_genlist_item_cursor_style_set(it,style)
	ElmObjectItem *it
	const char *style


char *
elm_genlist_item_cursor_style_get(it)
	const ElmObjectItem *it


void
elm_genlist_item_cursor_engine_only_set(it,engine_only)
	ElmObjectItem *it
	Eina_Bool engine_only


Eina_Bool
elm_genlist_item_cursor_engine_only_get(it)
	const ElmObjectItem *it


ElmGenlistItem *
elm_genlist_item_prev_get(obj)
	const ElmGenlistItem *obj


ElmGenlistItem *
elm_genlist_item_next_get(obj)
	const ElmGenlistItem *obj


ElmGenlistItem *
elm_genlist_item_parent_get(obj)
	const ElmGenlistItem *obj


EinaList *
elm_genlist_item_subitems_get(obj)
	const ElmGenlistItem *obj


void
elm_genlist_item_selected_set(obj,selected)
	ElmGenlistItem *obj
	Eina_Bool selected


Eina_Bool
elm_genlist_item_selected_get(obj)
	const ElmGenlistItem *obj


void
elm_genlist_item_expanded_set(obj,expanded)
	ElmGenlistItem *obj
	Eina_Bool expanded


Eina_Bool
elm_genlist_item_expanded_get(obj)
	const ElmGenlistItem *obj


int
elm_genlist_item_expanded_depth_get(obj)
	const ElmGenlistItem *obj


ElmGenlistItemClass *
elm_genlist_item_item_class_get(obj)
	const ElmGenlistItem *obj


int
elm_genlist_item_index_get(obj)
	const ElmGenlistItem *obj


char *
elm_genlist_item_decorate_mode_get(obj)
	const ElmGenlistItem *obj


void
elm_genlist_item_flip_set(obj,flip)
	ElmGenlistItem *obj
	Eina_Bool flip


Eina_Bool
elm_genlist_item_flip_get(obj)
	const ElmGenlistItem *obj


void
elm_genlist_item_select_mode_set(obj,mode)
	ElmGenlistItem *obj
	int mode


int
elm_genlist_item_select_mode_get(obj)
	const ElmGenlistItem *obj


int
elm_genlist_item_type_get(obj)
	const ElmGenlistItem *obj


void
elm_genlist_item_pin_set(obj,pin)
	ElmGenlistItem *obj
	Eina_Bool pin


Eina_Bool
elm_genlist_item_pin_get(obj)
	const ElmGenlistItem *obj


int
elm_genlist_item_subitems_count(obj)
	ElmGenlistItem *obj


void
elm_genlist_item_subitems_clear(obj)
	ElmGenlistItem *obj


void
elm_genlist_item_promote(obj)
	ElmGenlistItem *obj


void
elm_genlist_item_demote(obj)
	ElmGenlistItem *obj


void
elm_genlist_item_show(obj,type)
	ElmGenlistItem *obj
	int type


void
elm_genlist_item_bring_in(obj,type)
	ElmGenlistItem *obj
	int type


void
elm_genlist_item_all_contents_unset(obj,OUTLIST l)
	ElmGenlistItem *obj
	EinaList *l


void
elm_genlist_item_update(obj)
	ElmGenlistItem *obj


void
elm_genlist_item_fields_update(obj,parts,itf)
	ElmGenlistItem *obj
	const char *parts
	int itf


void
elm_genlist_item_item_class_update(obj,itc)
	ElmGenlistItem *obj
	const ElmGenlistItemClass *itc


void
elm_genlist_item_decorate_mode_set(obj,decorate_it_type,decorate_it_set)
	ElmGenlistItem *obj
	const char *decorate_it_type
	Eina_Bool decorate_it_set
