#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

#ifndef DEBUG
#define DEBUG 0
#endif

#include "PLSide.h"

typedef Evas_Object EvasObject;
typedef Evas_Canvas EvasCanvas;
typedef Eina_List EinaList;


MODULE = pEFL::Evas::Object		PACKAGE = EvasObjectPtr     PREFIX = evas_object_


void
evas_object_ref(obj)
    EvasObject *obj

void
evas_object_unref(obj)
    EvasObject *obj

int
evas_object_ref_get(obj)
    EvasObject *obj


void
evas_object_del(obj)
    EvasObject *obj


char*
evas_object_type_get(obj)
    EvasObject *obj

void
evas_object_name_set(obj,name)
    EvasObject *obj
    char *name

char *
evas_object_name_get(obj)
    EvasObject *obj

EvasObject *
evas_object_name_child_find(obj,name,recurse)
    EvasObject *obj
    char *name
    int recurse

void
evas_object_geometry_get(obj, OUTLIST x, OUTLIST y, OUTLIST w, OUTLIST h)
    EvasObject *obj
    Evas_Coord x
    Evas_Coord y
    Evas_Coord w
    Evas_Coord h

void
evas_object_geometry_set(obj,x,y,w,h)
    EvasObject *obj
    Evas_Coord x
    Evas_Coord y
    Evas_Coord w
    Evas_Coord h


void
evas_object_show(obj)
    EvasObject *obj

void
evas_object_hide(obj)
    EvasObject *obj


Eina_Bool
evas_object_visible_get(obj)
	const EvasObject *obj
    

void
evas_object_color_set(obj,r,g,b,a);
    EvasObject *obj
    int r
    int g
    int b
    int a


void
evas_object_color_get(obj, OUTLIST r, OUTLIST g, OUTLIST b, OUTLIST a);
    EvasObject *obj
    int r
    int g
    int b
    int a

void
evas_object_resize(obj,w,h)
    EvasObject *obj
    Evas_Coord w
    Evas_Coord h

void
evas_object_move(obj,x,y);
    EvasObject *obj
    Evas_Coord x
    Evas_Coord y

void
evas_object_size_hint_weight_set(obj,x,y)
    EvasObject *obj
    double x
    double y

void
evas_object_size_hint_weight_get(obj, OUTLIST x, OUTLIST y)
    EvasObject *obj
    double x
    double y



void
evas_object_size_hint_align_set(obj,x,y)
    EvasObject *obj
    double x
    double y

void
evas_object_size_hint_align_get(obj, OUTLIST x, OUTLIST y)
    EvasObject *obj
    double x
    double y
    

void
evas_object_size_hint_max_set(obj,w,h)
	EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_max_get(obj,OUTLIST w, OUTLIST h)
	const EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_request_set(obj,w,h)
	EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_request_get(obj,OUTLIST w,OUTLIST h)
	const EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_min_set(obj,w,h)
	EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
evas_object_clip_unset(obj)
	EvasObject *obj


void
evas_object_size_hint_min_get(obj,OUTLIST w,OUTLIST h)
	const EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_padding_set(obj,l,r,t,b)
	EvasObject *obj
	Evas_Coord l
	Evas_Coord r
	Evas_Coord t
	Evas_Coord b


void
evas_object_size_hint_padding_get(obj,OUTLIST l,OUTLIST r,OUTLIST t,OUTLIST b)
	const EvasObject *obj
	Evas_Coord l
	Evas_Coord r
	Evas_Coord t
	Evas_Coord b


void
evas_object_size_hint_aspect_set(obj,aspect,w,h)
	EvasObject *obj
	Evas_Aspect_Control aspect
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_aspect_get(obj,OUTLIST aspect,OUTLIST w,OUTLIST h)
	const EvasObject *obj
	Evas_Aspect_Control aspect
	Evas_Coord w
	Evas_Coord h


void
evas_object_size_hint_display_mode_set(obj,dispmode)
	EvasObject *obj
	int dispmode


int
evas_object_size_hint_display_mode_get(obj)
	const EvasObject *obj


void
evas_object_layer_set(obj,l)
	EvasObject *obj
	short l


short
evas_object_layer_get(obj)
	const EvasObject *obj


EvasObject *
evas_object_below_get(obj)
	const EvasObject *obj


EvasObject *
evas_object_above_get(obj)
	const EvasObject *obj


void
evas_object_stack_below(obj,below)
	EvasObject *obj
	EvasObject *below


void
evas_object_raise(obj)
	EvasObject *obj


void
evas_object_stack_above(obj,above)
	EvasObject *obj
	EvasObject *above


void
evas_object_lower(obj)
	EvasObject *obj


void
evas_object_static_clip_set(obj,is_static_clip)
    EvasObject *obj
    Eina_Bool is_static_clip
    

EinaList *
evas_object_clipees_get(obj)
	const EvasObject *obj


Eina_Bool
evas_object_clipees_has(obj)
	const EvasObject *obj


void
evas_object_render_op_set(obj,render_op)
	EvasObject *obj
	int render_op


int
evas_object_render_op_get(obj)
	const EvasObject *obj


Eina_Bool
evas_object_static_clip_get(obj)
	const EvasObject *obj


void
evas_object_scale_set(obj,scale)
	EvasObject *obj
	double scale


double
evas_object_scale_get(obj)
	const EvasObject *obj


# Eina_Bool
# evas_object_pointer_inside_by_device_get(obj,dev)
#	const EvasObject *obj
#	Efl_Input_Device * dev


Eina_Bool
evas_object_pointer_inside_get(obj)
	const EvasObject *obj


Eina_Bool
evas_object_pointer_coords_inside_get(eo_obj,x,y)
	const EvasObject *eo_obj
	int x
	int y


# Evas *
# evas_object_evas_get(obj)
#	const Eo *obj

EvasCanvas *
evas_object_evas_get(obj)
	const EvasObject *obj


# Eina_List *
# evas_objects_at_xy_get(eo_e,x,y,include_pass_events_objects,include_hidden_objects)
#	Eo *eo_e
#	int x
#	int y
#	Eina_Bool include_pass_events_objects
#	Eina_Bool include_hidden_objects


# EvasObject*
# evas_object_top_at_xy_get(eo_e,x,y,include_pass_events_objects,include_hidden_objects)
#	Eo *eo_e
#	Evas_Coord x
#	Evas_Coord y
#	Eina_Bool include_pass_events_objects
#	Eina_Bool include_hidden_objects


# Eina_List *
# evas_objects_in_rectangle_get(obj,x,y,w,h,include_pass_events_objects,include_hidden_objects)
#	const Eo *obj
#	int x
#	int y
#	int w
#	int h
#	Eina_Bool include_pass_events_objects
#	Eina_Bool include_hidden_objects


# EvasObject *
# evas_object_top_in_rectangle_get(obj,x,y,w,h,include_pass_events_objects,include_hidden_objects)
#	const Eo *obj
#	int x
#	int y
#	int w
#	int h
#	Eina_Bool include_pass_events_objects
#	Eina_Bool include_hidden_objects


#TODO: Implement enum Evas_Callback_Type
void
_evas_object_event_callback_add(obj,type,func,data)
	EvasObject *obj
	SV *type
	SV *func
	SV *data
PREINIT:
    _perl_callback *sc = NULL;
    char *event;
    int event_iv;
    UV objaddr;
CODE:
    objaddr = PTR2IV(obj);
    New(0,event,3,char);
    event_iv = SvIV(type);
    event = SvPV_nolen(type);
    
    // Save the data on the perl side
    sc = perl_save_callback(aTHX_ func, objaddr,event,"pEFL::PLSide::Callbacks");
    evas_object_event_callback_add(obj,event_iv,call_perl_evas_event_cb,sc);


# void
# evas_object_event_callback_priority_add(obj,type,priority,func,data)
#	EvasObject *obj
#	Evas_Callback_Type type
#	Evas_Callback_Priority priority
#	EvasObject_Event_Cb func
#	const void *data


# void *
# evas_object_event_callback_del(obj,type,func)
#	EvasObject *obj
#	int type
#	SV *func


void *
_evas_object_event_callback_del_full(obj,type,func,cstructaddr)
	EvasObject *obj
	int type
	SV *func
	SV* cstructaddr
PREINIT:
    _perl_callback *sc = NULL;
    UV address;
    void *data;
CODE:
    address = SvUV(cstructaddr);
    if (SvTRUE(get_sv("pEFL::Debug",0)))
    	fprintf(stderr,"Delete cstruct with adress %"UVuf"\n",address);
    sc = INT2PTR(_perl_callback*,address);
    data = evas_object_event_callback_del_full(obj, type, call_perl_evas_event_cb,sc);
    if (data == NULL) {
        croak("Could not delete evas callback\n");
    }
    else {
        Safefree(data);
    }

# Eina_Bool
# evas_object_key_grab(obj,keyname,modifiers,not_modifiers,exclusive)
#	EvasObject *obj
#	const char *keyname
#	Evas_Modifier_Mask modifiers
#	Evas_Modifier_Mask not_modifiers
#	Eina_Bool exclusive


# void
# evas_object_key_ungrab(obj,keyname,modifiers,not_modifiers)
#	EvasObject *obj
#	const char *keyname
#	Evas_Modifier_Mask modifiers
#	Evas_Modifier_Mask not_modifiers


Eina_Bool
evas_object_pointer_mode_set(obj,pointer_mode)
	EvasObject *obj
	int pointer_mode


int
evas_object_pointer_mode_get(obj)
	const EvasObject *obj


void
evas_object_repeat_events_set(obj,repeat)
	EvasObject *obj
	Eina_Bool repeat


Eina_Bool
evas_object_repeat_events_get(obj)
	const EvasObject *obj


void
evas_object_focus_set(obj,focus)
	EvasObject *obj
	Eina_Bool focus


Eina_Bool
evas_object_focus_get(obj)
	const EvasObject *obj


void
evas_object_precise_is_inside_set(obj,precise)
	EvasObject *obj
	Eina_Bool precise


Eina_Bool
evas_object_precise_is_inside_get(obj)
	const EvasObject *obj


void
evas_object_propagate_events_set(obj,propagate)
	EvasObject *obj
	Eina_Bool propagate


Eina_Bool
evas_object_propagate_events_get(obj)
	const EvasObject *obj


void
evas_object_pass_events_set(obj,pass)
	EvasObject *obj
	Eina_Bool pass


Eina_Bool
evas_object_pass_events_get(obj)
	const EvasObject *obj


void
evas_object_freeze_events_set(obj,freeze)
	EvasObject *obj
	Eina_Bool freeze

Eina_Bool
evas_object_freeze_events_get(obj)
	const EvasObject *obj
	

void
evas_object_anti_alias_set(obj,anti_alias)
	EvasObject *obj
	Eina_Bool anti_alias


Eina_Bool
evas_object_anti_alias_get(obj)
	const EvasObject *obj


EvasObject *
evas_object_smart_parent_get(obj)
	const EvasObject *obj


void
evas_object_paragraph_direction_set(obj,dir)
	EvasObject *obj
	int dir


int
evas_object_paragraph_direction_get(obj)
	const EvasObject *obj


# void
# evas_object_data_set(obj,key,data)
#	EvasObject *obj
#	const char *key
#	const void *data


# void *
# evas_object_data_get(obj,key)
#	const EvasObject *obj
#	const char *key


# void *
# evas_object_data_del(obj,key)
#	EvasObject *obj
#	const char *key


# EvasObject *
# evas_object_top_at_pointer_get(e)
#	const Evas *e


###########################
# SMART OBJECT FUNCTIONS
# ------------------------
###########################


void
_evas_object_smart_callback_add(obj, event, func, data)
    EvasObject *obj
    char *event
    SV *func
    SV *data
PREINIT:
        _perl_callback *sc = NULL;
        UV objaddr;
CODE:
    objaddr = PTR2IV(obj);
    sc = perl_save_callback(aTHX_ func, objaddr, event,"pEFL::PLSide::Callbacks");
    evas_object_smart_callback_add(obj, event, call_perl_sub, sc);
    

# void
# evas_object_smart_callback_priority_add(obj,event,priority,func,data)
#	EvasObject *obj
#	const char *event
#	Evas_Callback_Priority priority
#	Evas_Smart_Cb func
#	const void *data


void
_evas_object_smart_callback_del_full(obj, event, func, cstructaddr)
    EvasObject *obj
    char *event
    SV* func
    SV* cstructaddr
PREINIT:
    _perl_callback *sc = NULL;
    UV address;
    void *data;
CODE:
    address = SvUV(cstructaddr);
    if (SvTRUE(get_sv("pEFL::Debug",0)))
    	fprintf(stderr,"Delete cstruct with addr %"UVuf"\n",address);
    sc = INT2PTR(_perl_callback*,address);
    data = evas_object_smart_callback_del_full(obj, event, call_perl_sub,sc);
    if (data == NULL) {
        croak("Could not delete smart callback\n");
    }
    else {
        Safefree(data);
    }
    
    
void
evas_object_smart_callback_call(obj,event,event_info)
	EvasObject *obj
	const char *event
	void *event_info
CODE:
	if (event_info) {
        fprintf(stderr, "passing event info is not supported at the moment \n");
    }
	evas_object_smart_callback_call(obj, event, NULL);
	

void
_free_perl_callback(class, addr)
    SV* class
    SV* addr
PREINIT:
    UV address;
    void *data;
CODE:
    address = SvUV(addr);
    data = INT2PTR(_perl_callback*,address);
    if (data == NULL) {
        croak("Could not delete smart callback\n");
    }
    else {
        Safefree(data);
    }

    
void
evas_smart_objects_calculate(obj)
	EvasObject *obj


Eina_Bool
evas_smart_objects_calculating_get(obj)
	const EvasObject *obj


# EvasObject *
# evas_object_smart_add(e,s)
#	EvasCanvas *e
#	Evas_Smart *s


void
evas_object_smart_member_add(obj,smart_obj)
	EvasObject *obj
	EvasObject *smart_obj


void
evas_object_smart_member_del(obj)
	EvasObject *obj
	
	
# void *
# evas_object_smart_interface_get(obj,name)
#	const EvasObject *obj
#	const char *name


# void *
# evas_object_smart_interface_data_get(obj,iface)
#	const EvasObject *obj
#	const Evas_Smart_Interface *iface


Eina_Bool
evas_object_smart_type_check(obj,type)
	const EvasObject *obj
	const char *type


Eina_Bool
evas_object_smart_type_check_ptr(obj,type)
	const EvasObject *obj
	const char *type


# Eina_Bool
# evas_object_smart_callbacks_descriptions_set(obj,descriptions)
#	EvasObject *obj
#	const Evas_Smart_Cb_Description *descriptions


# void
# evas_object_smart_callbacks_descriptions_get(obj,**class_descriptions,class_count,**instance_descriptions,instance_count)
#	const EvasObject *obj
#	const Evas_Smart_Cb_Description ***class_descriptions
#	unsigned int *class_count
#	const Evas_Smart_Cb_Description ***instance_descriptions
#	unsigned int *instance_count


# void
# evas_object_smart_callback_description_find(obj,name,*class_description,*instance_description)
#	const EvasObject *obj
#	const char *name
#	const Evas_Smart_Cb_Description **class_description
#	const Evas_Smart_Cb_Description **instance_description


# Evas_Smart *
# evas_object_smart_smart_get(obj)
#	const EvasObject *obj


# void
# evas_object_smart_data_set(obj,data)
#	EvasObject *obj
#	void *data


# void *
# evas_object_smart_data_get(obj)
#	const EvasObject *obj


EvasObject *
evas_object_smart_clipped_clipper_get(obj)
	const EvasObject *obj


Eina_List *
evas_object_smart_members_get(obj)
	const EvasObject *obj


void
evas_object_smart_need_recalculate_set(obj,value)
	EvasObject *obj
	Eina_Bool value


Eina_Bool
evas_object_smart_need_recalculate_get(obj)
	const EvasObject *obj


# Eina_Iterator *
# evas_object_smart_iterator_new(obj)
#	const EvasObject *obj


void
evas_object_smart_calculate(obj)
	EvasObject *obj


void
evas_object_smart_changed(obj)
	EvasObject *obj


void
evas_object_smart_move_children_relative(obj,dx,dy)
	EvasObject *obj
	Evas_Coord dx
	Evas_Coord dy


# The following functions seem to be duplicate (see above)

# void
# evas_object_smart_changed(obj)
#	Efl_Canvas_Group *obj


# void
# evas_object_smart_calculate(obj)
#	Efl_Canvas_Group *obj


# Eina_Iterator *
# evas_object_smart_iterator_new(obj)
#	const Efl_Canvas_Group *obj

