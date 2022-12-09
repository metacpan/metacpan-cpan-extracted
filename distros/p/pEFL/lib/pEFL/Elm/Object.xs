#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Evas_Object ElmObject;
typedef Elm_Object_Item ElmObjectItem;
typedef Evas_Object EvasObject;
typedef Elm_Theme ElmTheme;

MODULE = pEFL::Elm::Object		PACKAGE = ElmObjectPtr	   PREFIX = elm_object_

void 
elm_object_text_set(object,text)
	EvasObject *object
	char *text


char *
elm_object_text_get(obj)
	const EvasObject *obj
	

void
elm_object_part_text_set(obj,part,text)
	EvasObject *obj
	const char *part
	const char *text


char *
elm_object_part_text_get(obj,part)
	const EvasObject *obj
	const char *part


void
elm_object_focus_allow_set(obj,focus)
	EvasObject *obj
	Eina_Bool focus


Eina_Bool
elm_object_focus_allow_get(obj)
	const EvasObject *obj


void
elm_object_focus_set(obj,focus)
	EvasObject *obj
	Eina_Bool focus


Eina_Bool
elm_object_focus_get(obj)
	const EvasObject *obj


void
elm_object_domain_translatable_part_text_set(obj,part,domain,text)
	EvasObject *obj
	const char *part
	const char *domain
	const char *text
	

void
elm_object_domain_translatable_text_set(obj,domain,text)
	EvasObject *obj
	const char *domain
	const char *text


void
elm_object_translatable_text_set(obj,text)
	EvasObject *obj
	const char *text
	

void
elm_object_translatable_part_text_set(obj,part,text)
	EvasObject *obj
	const char *part
	const char *text


char *
elm_object_translatable_part_text_get(obj,part)
	const EvasObject *obj
	const char *part


char *
elm_object_translatable_text_get(obj)
	const EvasObject *obj
	

void
elm_object_domain_part_text_translatable_set(obj,part,domain,translatable)
	EvasObject *obj
	const char *part
	const char *domain
	Eina_Bool translatable


void
elm_object_part_text_translatable_set(obj,part,translatable)
	EvasObject *obj
	const char *part
	Eina_Bool translatable

void
elm_object_domain_text_translatable_set(obj,domain,translatable)
	EvasObject *obj
	const char *domain
	Eina_Bool translatable


void
elm_object_part_content_set(obj,part,content)
	EvasObject *obj
	const char *part
	EvasObject *content


void
elm_object_content_set(obj,content)
	EvasObject *obj
	EvasObject *content


EvasObject *
elm_object_part_content_get(obj,part)
	const EvasObject *obj
	const char *part

	
EvasObject *
elm_object_content_get(obj)
	const EvasObject *obj


EvasObject *
elm_object_part_content_unset(obj,part)
	EvasObject *obj
	const char *part


EvasObject *
elm_object_content_unset(obj)
	EvasObject *obj


void
elm_object_access_info_set(obj,txt)
	EvasObject *obj
	const char *txt


char *
elm_object_access_info_get(obj)
	EvasObject *obj


EvasObject *
elm_object_name_find(obj,name,recurse)
	const EvasObject *obj
	const char *name
	int recurse


Eina_Bool
elm_object_style_set(obj,style)
	EvasObject *obj
	const char *style


char *
elm_object_style_get(obj)
	const EvasObject *obj


void
elm_object_disabled_set(obj,disabled)
	EvasObject *obj
	Eina_Bool disabled


Eina_Bool
elm_object_disabled_get(obj)
	const EvasObject *obj


Eina_Bool
elm_object_widget_check(obj)
	const EvasObject *obj


EvasObject *
elm_object_parent_widget_get(obj)
	const EvasObject *obj


EvasObject *
elm_object_top_widget_get(obj)
	const EvasObject *obj


char *
elm_object_widget_type_get(obj)
	const EvasObject *obj


void
elm_object_signal_emit(obj,emission,source)
	EvasObject *obj
	const char *emission
	const char *source


# TODO: func is not needed here !
void
_elm_object_signal_callback_add(obj,emission,source,func,id)
	EvasObject *obj
	const char *emission
	const char *source
	SV* func
	int id
PREINIT:
	UV objaddr;
	_perl_signal_cb *data;
CODE:
	objaddr = PTR2IV(obj);
	data = perl_save_signal_cb(aTHX_ objaddr, id);
	elm_object_signal_callback_add(obj,emission,source,call_perl_signal_cb,data);

	

void *
_elm_object_signal_callback_del(obj,emission,source,cstructaddr)
	EvasObject *obj
	const char *emission
	const char *source
	SV* cstructaddr
PREINIT:
	_perl_signal_cb *sc = NULL;
	_perl_signal_cb *del_sc = NULL;
	UV address;
	void *data;
CODE:
	address = SvUV(cstructaddr);
	sc = INT2PTR(_perl_signal_cb*,address);
	data = elm_object_signal_callback_del(obj, emission, source, call_perl_signal_cb);
	while (data != NULL) {
		del_sc = (_perl_signal_cb *) data;
		data = elm_object_signal_callback_del(obj, emission, source, call_perl_signal_cb);
		if (del_sc->signal_id == sc->signal_id) {
			Safefree(del_sc);
		}
		// If signal_ids are different reregister the signal callback
		else {
			elm_object_signal_callback_add(obj,emission,source,call_perl_signal_cb,del_sc);
		}
		
	}

# func = Elm_Event_Cb
# void
# elm_object_event_callback_add(obj,func,data)
#	EvasObject *obj
#	SV* func
#	SV *data


# void *
# elm_object_event_callback_del(obj,func,data)
#	EvasObject *obj
#	SV* func
#	const SV *data


void
elm_object_orientation_mode_disabled_set(obj,disabled)
	EvasObject *obj
	Eina_Bool disabled


Eina_Bool
elm_object_orientation_mode_disabled_get(obj)
	const EvasObject *obj
	
	
#######################
# Tooltip Stuff (see elm_tooltip.h)
#######################


void
elm_object_tooltip_move_freeze_push(obj)
	EvasObject *obj


void
elm_object_tooltip_move_freeze_pop(obj)
	EvasObject *obj


int
elm_object_tooltip_move_freeze_get(obj)
	const EvasObject *obj


void
elm_object_tooltip_orient_set(obj,orient)
	EvasObject *obj
	int orient


int
elm_object_tooltip_orient_get(obj)
	const EvasObject *obj


void
elm_object_tooltip_show(obj)
	EvasObject *obj


void
elm_object_tooltip_hide(obj)
	EvasObject *obj


void
elm_object_tooltip_text_set(obj,text)
	EvasObject *obj
	const char *text


void
elm_object_tooltip_domain_translatable_text_set(obj,domain,text)
	EvasObject *obj
	const char *domain
	const char *text


void
elm_object_tooltip_content_cb_set(obj,func,data,del_cb)
	EvasObject *obj
	SV *func
	SV *data
PREINIT:
		_perl_callback *sc = NULL;
		IV tmp;
		UV objaddr;
CODE:
	objaddr = PTR2IV(obj);
	sc = perl_save_callback(aTHX_ func, objaddr,"tooltip-content","pEFL::PLSide::Callbacks");
	elm_object_tooltip_content_cb_set(obj,call_perl_tooltip_content_cb,(void *) sc,del_tooltip);

void
elm_object_tooltip_unset(obj)
	EvasObject *obj


void
elm_object_tooltip_style_set(obj,style)
	EvasObject *obj
	const char *style


char *
elm_object_tooltip_style_get(obj)
	const EvasObject *obj


Eina_Bool
elm_object_tooltip_window_mode_set(obj,disable)
	EvasObject *obj
	Eina_Bool disable


Eina_Bool
elm_object_tooltip_window_mode_get(obj)
	const EvasObject *obj

void
elm_object_scroll_hold_push(obj)
	EvasObject *obj

void
elm_object_scroll_hold_pop(obj)
	EvasObject *obj

int
elm_object_scroll_hold_get(obj)
	const EvasObject *obj

void
elm_object_scroll_freeze_push(obj)
	EvasObject *obj

void
elm_object_scroll_freeze_pop(obj)
	EvasObject *obj

int
elm_object_scroll_freeze_get(obj)
	const EvasObject *obj

void
elm_object_scroll_lock_x_set(obj,lock)
	EvasObject *obj
	Eina_Bool lock

void
elm_object_scroll_lock_y_set(obj,lock)
	EvasObject *obj
	Eina_Bool lock

Eina_Bool
elm_object_scroll_lock_x_get(obj)
	const EvasObject *obj

Eina_Bool
elm_object_scroll_lock_y_get(obj)
	const EvasObject *obj

void
elm_object_scroll_item_loop_enabled_set(obj,enable)
	EvasObject *obj
	Eina_Bool enable

Eina_Bool
elm_object_scroll_item_loop_enabled_get(obj)
	const EvasObject *obj
	
###############
# from elm_theme.h
##############

void
elm_object_theme_set(obj,th)
	EvasObject *obj
	ElmTheme *th


ElmTheme *
elm_object_theme_get(obj)
	const EvasObject *obj