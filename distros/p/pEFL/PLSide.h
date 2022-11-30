#ifndef H_PLSIDE

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>
#include <Elementary.h>

typedef struct __perl_callback _perl_callback;

struct __perl_callback {
    UV objaddr;
    char event[50];
    SV* funcname;
    UV funcaddr;
};

//
// used by Smart_Cbs, Evas_Events, Tooltip::Content_Cbs
// perl_save_callback is used by ElmSlider and ElmProgressbar, too (but they call call_perl_format_cb)
// used also by edje_object_message_handler_set (but this calls call_perl_edje_message_handler)
//
_perl_callback *perl_save_callback(pTHX_ SV *func, UV objaddr, char *event, char *hashName);
void call_perl_sub(void *data, Evas_Object *obj, void *event_info);
void del_free(void *data);

void call_perl_evas_event_cb(void *data, Evas *e, Evas_Object *obj, void *event_info);

Evas_Object* call_perl_tooltip_content_cb(void *data, Evas_Object *obj, Evas_Object *tooltip);
void del_tooltip(void *data, Evas_Object *obj, void *event_info);

void call_perl_edje_message_handler(void *data, Evas_Object *obj, int type, int id, void *msg);

//
// used by ElmSlider and ElmProgressbar (and in the future hopefully ElmCalendar)
//
HV* _get_format_cb_hash(pTHX_ UV objaddr);
char* call_perl_format_cb(double value, void *data);
void free_buf(char *buf);

//
//	used by ElmEntry
//
HV* _get_markup_filter_cb(pTHX_ UV objaddr,SV* funcname);
_perl_callback *save_markup_filter_struct(pTHX_ SV *func, UV addr);
void call_perl_markup_filter_cb(void *data, Elm_Entry *entry, char **text);


//
// Used by Elm::Ctxpopup, Elm::Genlist, Elm::Hoversel, Elm::Index, Elm::List, Elm::Menu,  
// Elm::Popup, Elm::Toolbar, Elm::Entry(::context_menu_item_add!), ElmNaviframe (item_pop_cb!!!) etc.pp.
//

typedef struct __perl_gendata _perl_gendata;

struct __perl_gendata {
    UV itcaddr;
    UV objaddr;
    int item_id;
};

_perl_gendata *perl_save_gen_cb(pTHX_ UV objaddr, UV itcaddr, int id);
char* call_perl_gen_text_get(void *data, Evas_Object *obj, const char *part);
Evas_Object* call_perl_gen_content_get(void *data, Evas_Object *obj, const char *part);
Eina_Bool call_perl_gen_state_get(void *data, Evas_Object *obj, const char *part);
void call_perl_gen_del(void *data, Evas_Object *obj, void *event_info);
void call_perl_genitc_del(void *data, Evas_Object *obj);
void call_perl_gen_item_selected(void *data, Evas_Object *obj, void *event_info);
// Callback for NaviframeItem
Eina_Bool call_perl_item_pop_cb(void*data,Elm_Naviframe_Item *it);

//
// used by Elm::Layout, Elm::Object, Elm::WidgetItem (signal_callback_add|del)
//

typedef struct __perl_signal_cb _perl_signal_cb;

struct __perl_signal_cb {
    UV objaddr;
    int signal_id;
};

_perl_signal_cb *perl_save_signal_cb(pTHX_ UV objaddr, int id);
_perl_signal_cb *perl_save_item_signal_cb(pTHX_ UV objaddr, int id);
void call_perl_signal_cb(void *data, Evas_Object *layout, const char *emission, const char *source);
void call_perl_item_signal_cb(void *data, Elm_Object_Item *it, const char *emission, const char *source);

//
// Ecore_Evas_Events
// 

void call_perl_ecore_evas_resize(Ecore_Evas *ee);
void call_perl_ecore_evas_move(Ecore_Evas *ee);
void call_perl_ecore_evas_show(Ecore_Evas *ee);
void call_perl_ecore_evas_hide(Ecore_Evas *ee);
void call_perl_ecore_evas_delete_request(Ecore_Evas *ee);
void call_perl_ecore_evas_destroy(Ecore_Evas *ee);
void call_perl_ecore_evas_focus_in(Ecore_Evas *ee);
void call_perl_ecore_evas_focus_out(Ecore_Evas *ee);
void call_perl_ecore_evas_sticky(Ecore_Evas *ee);
void call_perl_ecore_evas_unsticky(Ecore_Evas *ee);
void call_perl_ecore_evas_mouse_in(Ecore_Evas *ee);
void call_perl_ecore_evas_mouse_out(Ecore_Evas *ee);
void call_perl_ecore_evas_pre_render(Ecore_Evas *ee);
void call_perl_ecore_evas_post_render(Ecore_Evas *ee);
void call_perl_ecore_evas_pre_free(Ecore_Evas *ee);
void call_perl_ecore_evas_state_change(Ecore_Evas *ee);

// Ecore Task Cbs
Eina_Bool call_perl_task_cb(void *data);

// Ecore Event Handler
Eina_Bool call_perl_ecore_event_handler_cb(void *data, int type, void *event);

#define H_PLSIDE
#endif
