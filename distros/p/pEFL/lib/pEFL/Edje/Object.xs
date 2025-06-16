#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

#include "PLSide.h"

typedef Eo EdjeObject;
typedef Evas_Object EvasObject;
typedef Edje_Message_Int_Set EdjeMessageIntSet;

MODULE = pEFL::Edje::Object 	PACKAGE = pEFL::Edje::Object

EdjeObject * 
edje_object_add(parent)
	EvasObject *parent

MODULE = pEFL::Edje::Object 	PACKAGE = EdjeObjectPtr 	PREFIX = edje_object_


Eina_Bool
edje_object_preload(obj,cancel)
	EvasObject *obj
	Eina_Bool cancel


# TODO: func is not needed here ! 
void
_edje_object_signal_callback_add(obj,emission,source,func,id)
	EvasObject *obj
	const char *emission
	const char *source
	SV *func
	int id
PREINIT:
	UV objaddr;
	_perl_signal_cb *data;
CODE:
	objaddr = PTR2IV(obj);
	data = perl_save_signal_cb(aTHX_ objaddr, id);
	edje_object_signal_callback_add(obj,emission,source,call_perl_signal_cb,data);
	


void
edje_object_signal_emit(obj,emission,source)
	EvasObject *obj
	const char *emission
	const char *source


void *
_edje_object_signal_callback_del(obj,emission,source,cstructaddr)
	EvasObject *obj
	const char *emission
	const char *source
	SV *cstructaddr
PREINIT:
	_perl_signal_cb *sc = NULL;
	_perl_signal_cb *del_sc = NULL;
	UV address;
	void *data;
CODE:
	address = SvUV(cstructaddr);
	sc = INT2PTR(_perl_signal_cb*,address);
	data = edje_object_signal_callback_del(obj, emission, source, call_perl_signal_cb);
	while (data != NULL) {
		del_sc = (_perl_signal_cb *) data;
		data = edje_object_signal_callback_del(obj, emission, source, call_perl_signal_cb);
		if (del_sc->signal_id == sc->signal_id) {
			Safefree(del_sc);
		}
		// If signal_ids are different reregister the signal callback
		else {
			edje_object_signal_callback_add(obj,emission,source,call_perl_signal_cb,del_sc);
		}
		
	}


# void *
# edje_object_signal_callback_del_full(obj,emission,source,func,data)
#	EvasObject *obj
#	const char *emission
#	const char *source
#	Edje_Signal_Cb func
#	void *data


int
edje_object_load_error_get(obj)
	const EvasObject *obj


Eina_Bool
edje_object_part_geometry_get(obj,part,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EvasObject *obj
	const char * part
	int x
	int y
	int w
	int h


char *
edje_object_part_state_get(obj,part,OUTLIST val_ret)
	const EvasObject *obj
	const char * part
	double val_ret


EvasObject *
edje_object_part_object_get(obj,part)
	const EvasObject *obj
	const char * part


void
edje_object_update_hints_set(obj,update)
	EvasObject *obj
	Eina_Bool update


Eina_Bool
edje_object_update_hints_get(obj)
	const EvasObject *obj


void
edje_object_size_min_calc(obj,OUTLIST minw,OUTLIST minh)
	EvasObject *obj
	int minw
	int minh


void
edje_object_size_min_restricted_calc(obj,OUTLIST minw,OUTLIST minh,restrictedw,restrictedh)
	EvasObject *obj
	int minw
	int minh
	int restrictedw
	int restrictedh


Eina_Bool
edje_object_parts_extends_calc(obj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	EvasObject *obj
	int x
	int y
	int w
	int h


void
edje_object_calc_force(obj)
	EvasObject *obj


int
edje_object_freeze(obj)
	EvasObject *obj


int
edje_object_thaw(obj)
	EvasObject *obj


# void
# edje_object_text_change_cb_set(obj,func,data)
#	EvasObject *obj
#	Edje_Text_Change_Cb func
#	void *data


void
_edje_object_message_handler_set(obj,func)
	EvasObject *obj
	SV *func
PREINIT:
        _perl_callback *sc = NULL;
        UV objaddr;
CODE:
	objaddr = PTR2IV(obj);
	sc = perl_save_callback(aTHX_ func, objaddr, "messageSent", "pEFL::PLSide::Callbacks");
	edje_object_message_handler_set(obj,call_perl_edje_message_handler,(void*) sc);

void
edje_object_message_send(obj,type,id,msg_sv)
	EvasObject *obj
	int type
	int id
	SV *msg_sv
PREINIT:
	void *msg;
	IV tmp;
CODE:
	tmp = SvIV((SV*)SvRV(msg_sv));
	msg = INT2PTR(void*,tmp);
	edje_object_message_send(obj,type,id,msg);


void
edje_object_message_signal_process(obj)
	EvasObject *obj


void
edje_object_message_signal_recursive_process(obj)
	EvasObject *obj


# Edje_External_Param_Type
# edje_object_part_external_param_type_get(obj,part,param)
#	const EvasObject *obj
#	const char *part
#	const char * param


# Eina_Bool
# edje_object_part_external_param_set(obj,part,param)
#	EvasObject *obj
#	const char *part
#	const Edje_External_Param *param


# Eina_Bool
# edje_object_part_external_param_get(obj,part,param)
#	const EvasObject *obj
#	const char *part
#	Edje_External_Param *param


EvasObject *
edje_object_part_external_object_get(obj,part)
	const EvasObject *obj
	const char * part


EvasObject *
edje_object_part_external_content_get(obj,part,content)
	const EvasObject *obj
	const char *part
	const char *content


Eina_Bool
edje_object_file_set(obj,file,group)
	EvasObject *obj
	const char *file
	const char *group


void
edje_object_file_get(obj,OUTLIST file,OUTLIST group)
	const EvasObject *obj
	const char *file
	const char *group


# Eina_Bool
# edje_object_mmap_set(obj,file,group)
#	EvasObject *obj
#	const Eina_File *file
#	const char *group


Eina_Bool
edje_object_part_swallow(obj,part,obj_swallow)
	EvasObject *obj
	const char *part
	EvasObject *obj_swallow


EvasObject *
edje_object_part_swallow_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_unswallow(obj,obj_swallow)
	EvasObject *obj
	EvasObject *obj_swallow


# Eina_List *
# edje_object_access_part_list_get(obj)
#	const EvasObject *obj


Eina_Bool
edje_object_part_box_append(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
edje_object_part_box_prepend(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
edje_object_part_box_insert_before(obj,part,child,reference)
	EvasObject *obj
	const char *part
	EvasObject *child
	const EvasObject *reference


Eina_Bool
edje_object_part_box_insert_after(obj,part,child,reference)
	EvasObject *obj
	const char *part
	EvasObject *child
	const EvasObject *reference


Eina_Bool
edje_object_part_box_insert_at(obj,part,child,pos)
	EvasObject *obj
	const char *part
	EvasObject *child
	unsigned int pos


EvasObject *
edje_object_part_box_remove_at(obj,part,pos)
	EvasObject *obj
	const char *part
	unsigned int pos


EvasObject *
edje_object_part_box_remove(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
edje_object_part_box_remove_all(obj,part,clear)
	EvasObject *obj
	const char *part
	Eina_Bool clear


Eina_Bool
edje_object_part_table_pack(obj,part,child_obj,col,row,colspan,rowspan)
	EvasObject *obj
	const char *part
	EvasObject *child_obj
	unsigned short col
	unsigned short row
	unsigned short colspan
	unsigned short rowspan


Eina_Bool
edje_object_part_table_unpack(obj,part,child_obj)
	EvasObject *obj
	const char *part
	EvasObject *child_obj


Eina_Bool
edje_object_part_table_col_row_size_get(obj,part,OUTLIST cols,OUTLIST rows)
	const EvasObject *obj
	const char *part
	int cols
	int rows


EvasObject *
edje_object_part_table_child_get(obj,part,col,row)
	const EvasObject *obj
	const char *part
	unsigned int col
	unsigned int row


Eina_Bool
edje_object_part_table_clear(obj,part,clear)
	EvasObject *obj
	const char *part
	Eina_Bool clear


Eina_Bool
edje_object_color_class_set(obj,color_class,r,g,b,a,r2,g2,b2,a2,r3,g3,b3,a3)
	EvasObject *obj
	const char * color_class
	int r
	int g
	int b
	int a
	int r2
	int g2
	int b2
	int a2
	int r3
	int g3
	int b3
	int a3


Eina_Bool
edje_object_color_class_get(obj,color_class,OUTLIST r,OUTLIST g,OUTLIST b,OUTLIST a,OUTLIST r2,OUTLIST g2,OUTLIST b2,OUTLIST a2,OUTLIST r3,OUTLIST g3,OUTLIST b3,OUTLIST a3)
	const EvasObject *obj
	const char * color_class
	int r
	int g
	int b
	int a
	int r2
	int g2
	int b2
	int a2
	int r3
	int g3
	int b3
	int a3


void
edje_object_color_class_del(obj,color_class)
	EvasObject *obj
	const char *color_class


Eina_Bool
edje_object_color_class_clear(obj)
	const EvasObject *obj


# size was Evas_Font_Size?
Eina_Bool
edje_object_text_class_set(obj,text_class,font,size)
	EvasObject *obj
	const char * text_class
	const char *font
	int size


# size was Evas_Font_Size?
Eina_Bool
edje_object_text_class_get(obj,text_class,OUTLIST font,OUTLIST size)
	const EvasObject *obj
	const char *text_class
	const char *font
	int size


void
edje_object_text_class_del(obj,text_class)
	EvasObject *obj
	const char *text_class


Eina_Bool
edje_object_size_class_set(obj,size_class,minw,minh,maxw,maxh)
	EvasObject *obj
	const char * size_class
	int minw
	int minh
	int maxw
	int maxh


Eina_Bool
edje_object_size_class_get(obj,size_class,OUTLIST minw,OUTLIST minh,OUTLIST maxw,OUTLIST maxh)
	const EvasObject *obj
	const char * size_class
	int minw
	int minh
	int maxw
	int maxh


void
edje_object_size_class_del(obj,size_class)
	EvasObject *obj
	const char *size_class


void
edje_object_part_text_select_allow_set(obj,part,allow)
	const EvasObject *obj
	const char *part
	Eina_Bool allow


void
edje_object_mirrored_set(obj,rtl)
	EvasObject *obj
	Eina_Bool rtl


Eina_Bool
edje_object_mirrored_get(obj)
	const EvasObject *obj


void
edje_object_language_set(obj,language)
	EvasObject *obj
	const char *language


char *
edje_object_language_get(obj)
	const EvasObject *obj


Eina_Bool
edje_object_scale_set(obj,scale)
	EvasObject *obj
	double scale


double
edje_object_scale_get(obj)
	const EvasObject *obj


double
edje_object_base_scale_get(obj)
	const EvasObject *obj


Eina_Bool
edje_object_part_drag_value_set(obj,part,dx,dy)
	EvasObject *obj
	const char * part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_value_get(obj,part,OUTLIST dx,OUTLIST dy)
	const EvasObject *obj
	const char * part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_size_set(obj,part,dw,dh)
	EvasObject *obj
	const char * part
	double dw
	double dh


Eina_Bool
edje_object_part_drag_size_get(obj,part,OUTLIST dw,OUTLIST dh)
	const EvasObject *obj
	const char * part
	double dw
	double dh


int
edje_object_part_drag_dir_get(obj,part)
	const EvasObject *obj
	const char * part


Eina_Bool
edje_object_part_drag_step_set(obj,part,dx,dy)
	EvasObject *obj
	const char * part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_step_get(obj,part,OUTLIST dx,OUTLIST dy)
	const EvasObject *obj
	const char * part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_step(obj,part,dx,dy)
	EvasObject *obj
	const char *part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_page_set(obj,part,dx,dy)
	EvasObject *obj
	const char * part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_page_get(obj,part,OUTLIST dx,OUTLIST dy)
	const EvasObject *obj
	const char * part
	double dx
	double dy


Eina_Bool
edje_object_part_drag_page(obj,part,dx,dy)
	EvasObject *obj
	const char *part
	double dx
	double dy


Eina_Bool
edje_object_part_text_set(obj,part,text)
	const EvasObject *obj
	const char *part
	const char *text


char *
edje_object_part_text_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_cursor_begin_set(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


void
edje_object_part_text_cursor_end_set(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


void
edje_object_part_text_cursor_pos_set(obj,part,cur,pos)
	EvasObject *obj
	const char * part
	int cur
	int pos


int
edje_object_part_text_cursor_pos_get(obj,part,cur)
	const EvasObject *obj
	const char * part
	int cur


Eina_Bool
edje_object_part_text_cursor_coord_set(obj,part,cur,x,y)
	EvasObject *obj
	const char *part
	int cur
	int x
	int y


void
edje_object_part_text_cursor_line_begin_set(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


void
edje_object_part_text_cursor_line_end_set(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


Eina_Bool
edje_object_part_text_cursor_prev(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


Eina_Bool
edje_object_part_text_cursor_next(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


Eina_Bool
edje_object_part_text_cursor_up(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


Eina_Bool
edje_object_part_text_cursor_down(obj,part,cur)
	EvasObject *obj
	const char *part
	int cur


void
edje_object_part_text_cursor_copy(obj,part,src,dst)
	EvasObject *obj
	const char *part
	int src
	int dst


char *
edje_object_part_text_cursor_content_get(obj,part,cur)
	const EvasObject *obj
	const char * part
	int cur


void
edje_object_part_text_cursor_geometry_get(obj,part,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EvasObject *obj
	const char * part
	int x
	int y
	int w
	int h


Eina_Bool
edje_object_part_text_hide_visible_password(obj,part)
	EvasObject *obj
	const char *part


Eina_Bool
edje_object_part_text_cursor_is_format_get(obj,part,cur)
	const EvasObject *obj
	const char * part
	int cur


Eina_Bool
edje_object_part_text_cursor_is_visible_format_get(obj,part,cur)
	const EvasObject *obj
	const char * part
	int cur


# Eina_List *
# edje_object_part_text_anchor_geometry_get(obj,part,anchor)
#	const EvasObject *obj
#	const char * part
#	const char * anchor


# Eina_List *
# edje_object_part_text_anchor_list_get(obj,part)
#	const EvasObject *obj
#	const char * part


char *
edje_object_part_text_style_user_peek(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_style_user_push(obj,part,style)
	EvasObject *obj
	const char *part
	const char *style


void
edje_object_part_text_style_user_pop(obj,part)
	EvasObject *obj
	const char *part


Eina_Bool
edje_object_part_text_item_geometry_get(obj,part,item,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasObject *obj
	const char * part
	const char * item
	int cx
	int cy
	int cw
	int ch


# Eina_List *
# edje_object_part_text_item_list_get(obj,part)
#	const EvasObject *obj
#	const char * part


# void *
# edje_object_text_insert_filter_callback_del(obj,part,func)
#	EvasObject *obj
#	const char *part
#	Edje_Text_Filter_Cb func


# void *
# edje_object_text_insert_filter_callback_del_full(obj,part,func,data)
#	EvasObject *obj
#	const char *part
#	Edje_Text_Filter_Cb func
#	void *data


# void
# edje_object_text_markup_filter_callback_add(obj,part,func,data)
#	EvasObject *obj
#	const char *part
#	Edje_Markup_Filter_Cb func
#	void *data


# void *
# edje_object_text_markup_filter_callback_del(obj,part,func)
#	EvasObject *obj
#	const char *part
#	Edje_Markup_Filter_Cb func


# void *
# edje_object_text_markup_filter_callback_del_full(obj,part,func,data)
#	EvasObject *obj
#	const char *part
#	Edje_Markup_Filter_Cb func
#	void *data


void
edje_object_part_text_user_insert(obj,part,text)
	const EvasObject *obj
	const char *part
	const char *text


void
edje_object_part_text_append(obj,part,text)
	EvasObject *obj
	const char *part
	const char *text


Eina_Bool
edje_object_part_text_escaped_set(obj,part,text)
	EvasObject *obj
	const char *part
	const char *text


Eina_Bool
edje_object_part_text_unescaped_set(obj,part,text_to_escape)
	EvasObject *obj
	const char * part
	const char *text_to_escape


char *
edje_object_part_text_unescaped_get(obj,part)
	const EvasObject *obj
	const char * part


void
edje_object_part_text_insert(obj,part,text)
	EvasObject *obj
	const char *part
	const char *text


void
edje_object_part_text_autocapital_type_set(obj,part,autocapital_type)
	EvasObject *obj
	const char *part
	int autocapital_type


int
edje_object_part_text_autocapital_type_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_prediction_allow_set(obj,part,prediction)
	EvasObject *obj
	const char *part
	Eina_Bool prediction


Eina_Bool
edje_object_part_text_prediction_allow_get(obj,part)
	const EvasObject *obj
	const char *part


# void *
# edje_object_part_text_imf_context_get(obj,part)
#	const EvasObject *obj
#	const char *part


void
edje_object_part_text_imf_context_reset(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_hint_set(obj,part,input_hints)
	EvasObject *obj
	const char *part
	int input_hints


int
edje_object_part_text_input_hint_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_show(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_hide(obj,part)
	const EvasObject *obj
	const char *part


# void
# edje_object_part_text_input_panel_imdata_set(obj,part,data,len)
#	EvasObject *obj
#	const char *part
#	const void *data
#	int len


# void
# edje_object_part_text_input_panel_imdata_get(obj,part,data,len)
#	const EvasObject *obj
#	const char *part
#	void *data
#	int *len


void
edje_object_part_text_input_panel_layout_set(obj,part,layout)
	EvasObject *obj
	const char *part
	int layout


int
edje_object_part_text_input_panel_layout_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_language_set(obj,part,lang)
	EvasObject *obj
	const char *part
	int lang


int
edje_object_part_text_input_panel_language_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_layout_variation_set(obj,part,variation)
	EvasObject *obj
	const char *part
	int variation


int
edje_object_part_text_input_panel_layout_variation_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_enabled_set(obj,part,enabled)
	EvasObject *obj
	const char *part
	Eina_Bool enabled


Eina_Bool
edje_object_part_text_input_panel_enabled_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_return_key_disabled_set(obj,part,disabled)
	EvasObject *obj
	const char *part
	Eina_Bool disabled


Eina_Bool
edje_object_part_text_input_panel_return_key_disabled_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_return_key_type_set(obj,part,return_key_type)
	EvasObject *obj
	const char *part
	int return_key_type


int
edje_object_part_text_input_panel_return_key_type_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_input_panel_show_on_demand_set(obj,part,ondemand)
	EvasObject *obj
	const char *part
	Eina_Bool ondemand


Eina_Bool
edje_object_part_text_input_panel_show_on_demand_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_prediction_hint_set(obj,part,prediction_hint)
	EvasObject *obj
	const char *part
	const char *prediction_hint


Eina_Bool
edje_object_part_text_prediction_hint_hash_set(obj,part,key,value)
	EvasObject *obj
	const char *part
	const char *key
	const char *value


Eina_Bool
edje_object_part_text_prediction_hint_hash_del(obj,part,key)
	EvasObject *obj
	const char *part
	const char *key


void
edje_object_part_text_select_begin(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_select_abort(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_select_extend(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_select_all(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_part_text_select_none(obj,part)
	const EvasObject *obj
	const char *part


char *
edje_object_part_text_selection_get(obj,part)
	const EvasObject *obj
	const char *part


void
edje_object_play_set(obj,play)
	EvasObject *obj
	Eina_Bool play


Eina_Bool
edje_object_play_get(obj)
	const EvasObject *obj


void
edje_object_transition_duration_factor_set(obj,scale)
	EvasObject *obj
	double scale


double
edje_object_transition_duration_factor_get(obj)
	const EvasObject *obj


void
edje_object_size_min_get(obj,OUTLIST minw,OUTLIST minh)
	const EvasObject *obj
	int minw
	int minh


void
edje_object_size_max_get(obj,OUTLIST maxw,OUTLIST maxh)
	const EvasObject *obj
	int maxw
	int maxh


Eina_Bool
edje_object_part_exists(obj,part)
	const EvasObject *obj
	const char *part


# void
# edje_object_item_provider_set(obj,func,data)
#	Edje_Object *obj
#	Edje_Item_Provider_Cb func
#	void *data


# char *
# edje_object_color_class_description_get(obj,color_class)
#	const Edje_Object *obj
#	const char * color_class


# Edje_Perspective *
# edje_evas_global_perspective_get(e)
#	const Evas *e


# void
# edje_object_perspective_set(obj,ps)
#	EvasObject *obj
#	Edje_Perspective *ps


# Edje_Perspective *
# edje_object_perspective_get(obj)
#	const EvasObject *obj


#######################
# From Edje_Common.h
######################

char *
edje_object_part_object_name_get(obj)
	const EvasObject *obj
	
#######################
# From elf_layout_group_eo.legacy.h
######################

const char *
edje_object_data_get(obj,key)
	const EvasObject *obj
	const char *key