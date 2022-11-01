#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Entry ElmEntry;
typedef Elm_Entry_Anchor_Info ElmEntryAnchorInfo;
typedef Elm_Entry_Change_Info ElmEntryChangeInfo;
typedef Evas_Object EvasObject;
typedef Evas_Textblock EvasTextblock;

MODULE = pEFL::Elm::Entry		PACKAGE = pEFL::Elm::Entry

ElmEntry * 
elm_entry_add(parent)
    EvasObject *parent
    
MODULE = pEFL::Elm::Entry		PACKAGE = pEFL::Elm::Entry PREFIX = elm_entry_
    
SV*
elm_entry_markup_to_utf8(s)
    char *s
PREINIT:
    char *utfstring;
    SV *s_string;
CODE:
    utfstring = elm_entry_markup_to_utf8(s);
    s_string = newSVpv(utfstring,0);
    free(utfstring);
    RETVAL = s_string;
OUTPUT:
    RETVAL
    
SV*
elm_entry_utf8_to_markup(s)
    char *s
PREINIT:
    char *markup;
    SV *s_string;
CODE:
    markup = elm_entry_utf8_to_markup(s);
    s_string = newSVpv(markup,0);
    free(markup);
    RETVAL = s_string;
OUTPUT:
    RETVAL

MODULE = pEFL::Elm::Entry		PACKAGE = ElmEntryPtr     PREFIX = elm_entry_

void
elm_entry_scrollable_set(obj,scroll)
	ElmEntry *obj
	Eina_Bool scroll


Eina_Bool
elm_entry_scrollable_get(obj)
	const ElmEntry *obj
	
void
elm_entry_input_panel_show_on_demand_set(obj,ondemand)
	ElmEntry *obj
	Eina_Bool ondemand


Eina_Bool
elm_entry_input_panel_show_on_demand_get(obj)
	const ElmEntry *obj

void
elm_entry_context_menu_disabled_set(obj,disabled)
	ElmEntry *obj
	Eina_Bool disabled


Eina_Bool
elm_entry_context_menu_disabled_get(obj)
	const ElmEntry *obj


void
elm_entry_cnp_mode_set(obj,cnp_mode)
	ElmEntry *obj
	int cnp_mode


int
elm_entry_cnp_mode_get(obj)
	const ElmEntry *obj


void
elm_entry_file_text_format_set(obj,format)
	ElmEntry *obj
	int format


void
elm_entry_input_panel_language_set(obj,lang)
	ElmEntry *obj
	int lang


int
elm_entry_input_panel_language_get(obj)
	const ElmEntry *obj
	
	
void
elm_entry_entry_set(obj,entry)
	EvasObject *obj
	const char *entry
	
char *
elm_entry_entry_get(obj)
	EvasObject *obj
	

void
elm_entry_entry_append(obj,str)
	ElmEntry *obj
	const char *str
	

void
elm_entry_entry_insert(obj,entry)
	ElmEntry *obj
	const char *entry
	

Eina_Bool
elm_entry_is_empty(obj)
	ElmEntry *obj


void
elm_entry_password_set(obj,password)
	ElmEntry *obj
	Eina_Bool password
	

Eina_Bool
elm_entry_password_get(obj)
	ElmEntry *obj
	

void
elm_entry_single_line_set(obj,single_line)
	ElmEntry *obj
	Eina_Bool single_line


Eina_Bool
elm_entry_single_line_get(obj)
	ElmEntry *obj
	
	
void
elm_entry_line_wrap_set(obj,wrap)
	ElmEntry *obj
	int wrap


int
elm_entry_line_wrap_get(obj)
	ElmEntry *obj
	
	
void
elm_entry_select_all(obj)
	ElmEntry *obj
	
	
void
elm_entry_select_none(obj)
	ElmEntry *obj
	
	
void
elm_entry_select_region_set(obj,start,end)
	ElmEntry *obj
	int start
	int end
	
	
void
elm_entry_select_region_get(obj,OUTLIST start,OUTLIST end)
	const ElmEntry *obj
	int start
	int end
	
	
char *
elm_entry_selection_get(obj)
	ElmEntry *obj
	
	
void
elm_entry_selection_cut(obj)
	ElmEntry *obj
	
	
void
elm_entry_selection_paste(obj)
	ElmEntry *obj
	
	
void
elm_entry_cursor_begin_set(obj)
	ElmEntry *obj
	
	
void
elm_entry_cursor_end_set(obj)
	ElmEntry *obj
	
	
Eina_Bool
elm_entry_cursor_down(obj)
	ElmEntry *obj
	
	
Eina_Bool
elm_entry_cursor_up(obj)
	ElmEntry *obj
	
	
Eina_Bool
elm_entry_cursor_next(obj)
	ElmEntry *obj
	
	
Eina_Bool
elm_entry_cursor_prev(obj)
	ElmEntry *obj
	
	
void
elm_entry_cursor_pos_set(obj,pos)
	ElmEntry *obj
	int pos
	
	
int
elm_entry_cursor_pos_get(obj)
	ElmEntry *obj
	
	
void
elm_entry_cursor_selection_begin(obj)
	ElmEntry *obj
	
	
void
elm_entry_cursor_selection_end(obj)
	ElmEntry *obj
	
	
void
elm_entry_text_style_user_push(obj,style)
	ElmEntry *obj
	const char *style
	
	
void
elm_entry_text_style_user_pop(obj)
	ElmEntry *obj
	
	
Eina_Bool
elm_entry_file_set(obj,file,format)
	EvasObject *obj
	const char *file
	Elm_Text_Format format	

	
void
elm_entry_file_get(obj,OUTLIST file, OUTLIST format)
	EvasObject *obj
	const char *file
	Elm_Text_Format format	
	
	
void
elm_entry_file_save(obj)
	ElmEntry *obj
	
	
void
elm_entry_autosave_set(obj,auto_save)
	ElmEntry *obj
	Eina_Bool auto_save



Eina_Bool
elm_entry_autosave_get(obj)
	ElmEntry *obj
	
	
void
elm_entry_calc_force(obj)
	EvasObject *obj


void
elm_entry_selection_handler_disabled_set(obj,disabled)
	ElmEntry *obj
	Eina_Bool disabled


void
elm_entry_input_panel_layout_variation_set(obj,variation)
	ElmEntry *obj
	int variation


int
elm_entry_input_panel_layout_variation_get(obj)
	const ElmEntry *obj


void
elm_entry_autocapital_type_set(obj,autocapital_type)
	ElmEntry *obj
	int autocapital_type


int
elm_entry_autocapital_type_get(obj)
	const ElmEntry *obj


void
elm_entry_editable_set(obj,editable)
	ElmEntry *obj
	Eina_Bool editable


Eina_Bool
elm_entry_editable_get(obj)
	const ElmEntry *obj


void
elm_entry_anchor_hover_style_set(obj,style)
	ElmEntry *obj
	const char *style


char *
elm_entry_anchor_hover_style_get(obj)
	const ElmEntry *obj	
	

void
elm_entry_input_panel_return_key_disabled_set(obj,disabled)
	ElmEntry *obj
	Eina_Bool disabled


Eina_Bool
elm_entry_input_panel_return_key_disabled_get(obj)
	const ElmEntry *obj


void
elm_entry_anchor_hover_parent_set(obj,parent)
	ElmEntry *obj
	EvasObject *parent


EvasObject *
elm_entry_anchor_hover_parent_get(obj)
	const ElmEntry *obj


void
elm_entry_prediction_allow_set(obj,prediction)
	ElmEntry *obj
	Eina_Bool prediction


Eina_Bool
elm_entry_prediction_allow_get(obj)
	const ElmEntry *obj


void
elm_entry_input_hint_set(obj,hints)
	ElmEntry *obj
	int hints


int
elm_entry_input_hint_get(obj)
	const ElmEntry *obj


void
elm_entry_input_panel_layout_set(obj,layout)
	ElmEntry *obj
	int layout


int
elm_entry_input_panel_layout_get(obj)
	const ElmEntry *obj


void
elm_entry_input_panel_return_key_type_set(obj,return_key_type)
	ElmEntry *obj
	int return_key_type


int
elm_entry_input_panel_return_key_type_get(obj)
	const ElmEntry *obj


void
elm_entry_input_panel_enabled_set(obj,enabled)
	ElmEntry *obj
	Eina_Bool enabled


Eina_Bool
elm_entry_input_panel_enabled_get(obj)
	const ElmEntry *obj


void
elm_entry_icon_visible_set(obj,setting)
	ElmEntry *obj
	Eina_Bool setting


void
elm_entry_cursor_line_end_set(obj)
	ElmEntry *obj


void
elm_entry_input_panel_return_key_autoenabled_set(obj,enabled)
	ElmEntry *obj
	Eina_Bool enabled


void
elm_entry_end_visible_set(obj,setting)
	ElmEntry *obj
	Eina_Bool setting


void
elm_entry_cursor_line_begin_set(obj)
	ElmEntry *obj


EvasTextblock *
elm_entry_textblock_get(obj)
	const ElmEntry *obj


Eina_Bool
elm_entry_cursor_geometry_get(obj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const ElmEntry *obj
	int x
	int y
	int w
	int h


# void *
# elm_entry_imf_context_get(obj)
#	const ElmEntry *obj


Eina_Bool
elm_entry_cursor_is_format_get(obj)
	const ElmEntry *obj


Eina_Bool
elm_entry_cursor_is_visible_format_get(obj)
	const ElmEntry *obj


void
elm_entry_select_allow_set(obj,allow)
	ElmEntry *obj
	Eina_Bool allow


Eina_Bool
elm_entry_select_allow_get(obj)
	const ElmEntry *obj


# void
# elm_entry_item_provider_prepend(obj,func,data)
#	ElmEntry *obj
#	ElmEntry_Item_Provider_Cb func
#	void *data


void
elm_entry_input_panel_show(obj)
	ElmEntry *obj


void
elm_entry_imf_context_reset(obj)
	ElmEntry *obj


void
elm_entry_anchor_hover_end(obj)
	ElmEntry *obj


void
elm_entry_selection_copy(obj)
	ElmEntry *obj


# void
# elm_entry_item_provider_remove(obj,func,data)
#	ElmEntry *obj
#	ElmEntry_Item_Provider_Cb func
#	void *data


char *
elm_entry_text_style_user_peek(obj)
	const ElmEntry *obj


void
elm_entry_context_menu_clear(obj)
	ElmEntry *obj

	
# void
# elm_entry_input_panel_imdata_set(obj,data,len)
#	ElmEntry *obj
#	const void *data
#	int len


# void
# elm_entry_input_panel_imdata_get(obj,data,len)
#	const ElmEntry *obj
#	void *data
#	int *len

void
elm_entry_input_panel_hide(obj)
	ElmEntry *obj


void
_elm_entry_markup_filter_remove(obj,func,cstructaddr)
	ElmEntry *obj
	SV *func
	SV *cstructaddr
PREINIT:
    _perl_callback *sc = NULL;
    UV address;
    void *data;
CODE:
    address = SvUV(cstructaddr);
    printf("Delete cb CSTRUCTADDR %"UVuf,address);
    sc = INT2PTR(_perl_callback*,address);
    elm_entry_markup_filter_remove(obj, call_perl_markup_filter_cb,sc);
    Safefree(sc);
    


# void
# elm_entry_item_provider_append(obj,func,data)
#	ElmEntry *obj
#	ElmEntry_Item_Provider_Cb func
#	void *data


void
_elm_entry_markup_filter_append(obj,func)
	ElmEntry *obj
	SV *func
PREINIT:
    _perl_callback *sc = NULL;
    UV objaddr;
CODE:
    objaddr = PTR2IV(obj);
    sc = save_markup_filter_struct(aTHX_ func, objaddr);
    elm_entry_markup_filter_append(obj,call_perl_markup_filter_cb,sc);


void
_elm_entry_markup_filter_limit_size_append(obj,func,data)
	ElmEntry *obj
	SV *func
	HV *data
PREINIT:
    _perl_callback *sc = NULL;
    UV objaddr;
    static Elm_Entry_Filter_Limit_Size limit_size;
    int max_char_count;
    int max_byte_count;
CODE:
    max_char_count = SvIV( *(hv_fetch(data,"max_char_count",14,FALSE)) );
    max_byte_count = SvIV( *(hv_fetch(data,"max_byte_count",14,FALSE)) );
    limit_size.max_char_count = max_char_count;
    limit_size.max_byte_count = max_byte_count;
    objaddr = PTR2IV(obj);
    sc = save_markup_filter_struct(aTHX_ func, objaddr);
    elm_entry_markup_filter_append(obj,elm_entry_filter_limit_size,&limit_size);


void
_elm_entry_markup_filter_accept_set_append(obj,func,data)
	ElmEntry *obj
	SV *func
	HV *data
PREINIT:
    _perl_callback *sc = NULL;
    UV objaddr;
    static Elm_Entry_Filter_Accept_Set accept_set;
    SV *accepted;
    SV *rejected;
CODE:
     accepted = *(hv_fetch(data,"accepted",8,FALSE));
     if (SvTYPE(accepted) == SVt_NULL) {
        accept_set.accepted = NULL;
     }
     else {
        accept_set.accepted = SvPV_nolen(accepted);
     }
     
     rejected = *(hv_fetch(data,"rejected",8,FALSE));
     if (SvTYPE(rejected) == SVt_NULL) {
        accept_set.rejected = NULL;
     }
     else {
        accept_set.rejected = SvPV_nolen(rejected);
     }
     
    objaddr = PTR2IV(obj);
    sc = save_markup_filter_struct(aTHX_ func, objaddr);
    elm_entry_markup_filter_append(obj,elm_entry_filter_accept_set,&accept_set);

    
void
_elm_entry_context_menu_item_add(obj,label,icon_file,icon_type,id)
	ElmEntry *obj
	const char *label
	const char *icon_file
	int icon_type
	int id
PREINIT:
	_perl_gendata *data;
	UV objaddr;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
	// Save C struct with necessary infos to link to perl side
	data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
	elm_entry_context_menu_item_add(obj,label,icon_file,icon_type,call_perl_gen_item_selected,data);


void
_elm_entry_markup_filter_prepend(obj,func)
	ElmEntry *obj
	SV *func
PREINIT:
    _perl_callback *sc = NULL;
    UV objaddr;
CODE:
    objaddr = PTR2IV(obj);
    sc = save_markup_filter_struct(aTHX_ func, objaddr);
    elm_entry_markup_filter_prepend(obj,call_perl_markup_filter_cb,sc);

void
_elm_entry_markup_filter_limit_size_prepend(obj,func,data)
	ElmEntry *obj
	SV *func
	HV *data
PREINIT:
    _perl_callback *sc = NULL;
    UV objaddr;
    static Elm_Entry_Filter_Limit_Size limit_size;
    int max_char_count;
    int max_byte_count;
CODE:
    max_char_count = SvIV( *(hv_fetch(data,"max_char_count",14,FALSE)) );
    max_byte_count = SvIV( *(hv_fetch(data,"max_byte_count",14,FALSE)) );
    limit_size.max_char_count = max_char_count;
    limit_size.max_byte_count = max_byte_count;
    objaddr = PTR2IV(obj);
    sc = save_markup_filter_struct(aTHX_ func, objaddr);
    elm_entry_markup_filter_prepend(obj,elm_entry_filter_limit_size,&limit_size);


void
_elm_entry_markup_filter_accept_set_prepend(obj,func,data)
	ElmEntry *obj
	SV *func
	HV *data
PREINIT:
    _perl_callback *sc = NULL;
    UV objaddr;
    static Elm_Entry_Filter_Accept_Set accept_set;
    SV *accepted;
    SV *rejected;
CODE:
     accepted = *(hv_fetch(data,"accepted",8,FALSE));
     if (SvTYPE(accepted) == SVt_NULL) {
        accept_set.accepted = NULL;
     }
     else {
        accept_set.accepted = SvPV_nolen(accepted);
     }
     
     rejected = *(hv_fetch(data,"rejected",8,FALSE));
     if (SvTYPE(rejected) == SVt_NULL) {
        accept_set.rejected = NULL;
     }
     else {
        accept_set.rejected = SvPV_nolen(rejected);
     }
     
    objaddr = PTR2IV(obj);
    sc = save_markup_filter_struct(aTHX_ func, objaddr);
    elm_entry_markup_filter_prepend(obj,elm_entry_filter_accept_set,&accept_set);
    
    
void
elm_entry_prediction_hint_set(obj,prediction_hint)
	ElmEntry *obj
	const char *prediction_hint


Eina_Bool
elm_entry_prediction_hint_hash_set(obj,key,value)
	ElmEntry *obj
	const char *key
	const char *value


Eina_Bool
elm_entry_prediction_hint_hash_del(obj,key)
	ElmEntry *obj
	const char *key
	

# void
# elm_entry_filter_limit_size(data,entry,*text)
#	void *data
#	Evas_Object *entry
#	char **text


# void
# elm_entry_filter_accept_set(data,entry,*text)
#	void *data
#	Evas_Object *entry
#	char **text


# char *
# elm_entry_context_menu_item_label_get(item)
#	const ElmEntry_Context_Menu_Item *item


# void
# elm_entry_context_menu_item_icon_get(item,*icon_file,*icon_group,icon_type)
#	const ElmEntry_Context_Menu_Item *item
#	const char **icon_file
#	const char **icon_group
#	Elm_Icon_Type *icon_type


MODULE = pEFL::Elm::Entry		PACKAGE = ElmEntryAnchorInfoPtr

const char*
name(anchor_info)
    ElmEntryAnchorInfo *anchor_info
CODE:
    RETVAL = anchor_info->name;
OUTPUT:
    RETVAL
  
  
int
button(anchor_info)
    ElmEntryAnchorInfo *anchor_info
CODE:
    RETVAL = anchor_info->button;
OUTPUT:
    RETVAL
  
  
Evas_Coord
x(anchor_info)
    ElmEntryAnchorInfo *anchor_info
CODE:
    RETVAL = anchor_info->x;
OUTPUT:
    RETVAL
  
  
Evas_Coord
y(anchor_info)
    ElmEntryAnchorInfo *anchor_info
CODE:
    RETVAL = anchor_info->y;
OUTPUT:
    RETVAL
    

Evas_Coord
w(anchor_info)
    ElmEntryAnchorInfo *anchor_info
CODE:
    RETVAL = anchor_info->w;
OUTPUT:
    RETVAL
    
    
Evas_Coord
h(anchor_info)
    ElmEntryAnchorInfo *anchor_info
CODE:
    RETVAL = anchor_info->h;
OUTPUT:
    RETVAL

MODULE = pEFL::Elm::Entry		PACKAGE = ElmEntryChangeInfoPtr

Eina_Bool
insert(change_info)
    ElmEntryChangeInfo *change_info
CODE:
    RETVAL = change_info->insert;
OUTPUT:
    RETVAL
    
    
Eina_Bool
merge(change_info)
    ElmEntryChangeInfo *change_info
CODE:
    RETVAL = change_info->merge;
OUTPUT:
    RETVAL    

HV*
change(change_info)
    ElmEntryChangeInfo *change_info
PREINIT:
	HV *hash;
	HV *insert;
	size_t pos;
	size_t plain_length;
	const char *insert_content;
	HV *del;
	size_t start;
	size_t end;
	const char *del_content;
CODE:
    pos = change_info->change.insert.pos;
    plain_length = change_info->change.insert.plain_length;
    insert_content = change_info->change.insert.content;
    
    insert = newHV();
    hv_store(insert,"pos",3,newSViv(pos),0);
    hv_store(insert,"plain_length",12,newSViv(plain_length),0);
    hv_store(insert,"content",7,newSVpv(insert_content,0),0);
    
    
    start = change_info->change.del.start;
    end = change_info->change.del.end;
    del_content = change_info->change.del.content;
    
    del = newHV();
    hv_store(del,"start",5,newSViv(start),0);
    hv_store(del,"end",3,newSViv(end),0);
    hv_store(del,"content",7,newSVpv(del_content,0),0);
    
    hash = (HV*) sv_2mortal( (SV*) newHV() );
    hv_store(hash,"insert",6,newRV_noinc((SV*)insert),0);
    hv_store(hash,"del",3,newRV_noinc((SV*)del),0);
    
    RETVAL = hash;
OUTPUT:
    RETVAL
    
    
    
    