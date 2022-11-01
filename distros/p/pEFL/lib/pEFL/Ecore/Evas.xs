#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore_Evas.h>
#include <Evas.h>

#include "PLSide.h"

typedef Ecore_Evas EcoreEvas;
typedef Evas_Canvas EvasCanvas;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Ecore::Evas		PACKAGE = pEFL::Ecore::Evas 


EcoreEvas *
ecore_evas_new(engine_name,x,y,w,h,extra_options)
	const char *engine_name
	int x
	int y
	int w
	int h
	const char *extra_options


EcoreEvas *
ecore_evas_sdl_new(name,w,h,fullscreen,hwsurface,noframe,alpha)
    const char* name
    int w
    int h
    int fullscreen
    int hwsurface
    int noframe
    int alpha	


EcoreEvas *
ecore_evas_gl_sdl_new(name,w,h,fullscreen,noframe)
	const char* name
	int w
	int h
	int fullscreen
	int noframe


EcoreEvas *
ecore_evas_fb_new(disp_name,rotation,w,h)
	const char *disp_name
	int rotation
	int w
	int h	


EcoreEvas *
ecore_evas_wayland_shm_new(disp_name,parent,x,y,w,h,frame)
	const char *disp_name
	unsigned int parent
	int x
	int y
	int w
	int h
	Eina_Bool frame


EcoreEvas *
ecore_evas_wayland_egl_new(disp_name,parent,x,y,w,h,frame)
	const char *disp_name
	unsigned int parent
	int x
	int y
	int w
	int h
	Eina_Bool frame


EcoreEvas *
ecore_evas_drm_new(device,parent,x,y,w,h)
	const char *device
	unsigned int parent
	int x
	int y
	int w
	int h


EcoreEvas *
ecore_evas_gl_drm_new(device,parent,x,y,w,h)
	const char *device
	unsigned int parent
	int x
	int y
	int w
	int h
	
	
EcoreEvas *
ecore_evas_buffer_new(w,h)
	int w
	int h


EcoreEvas *
ecore_evas_ews_new(x,y,w,h)
	int x
	int y
	int w
	int h


EcoreEvas *
ecore_evas_extn_socket_new(w,h)
	int w
	int h
	
		
MODULE = pEFL::Ecore::Evas		PACKAGE = pEFL::Ecore::Evas   PREFIX = ecore_evas_


EvasObject *
ecore_evas_extn_plug_new(ee_target)
	EcoreEvas *ee_target


int
ecore_evas_engine_type_supported_get(engine)
	int engine
	
	
int
ecore_evas_init()


void
ecore_evas_app_comp_sync_set(do_sync)
	Eina_Bool do_sync


Eina_Bool
ecore_evas_app_comp_sync_get()
	 


EinaList *
ecore_evas_engines_get()
	 

void
ecore_evas_engines_free(engines)
	EinaList *engines
	 

int
ecore_evas_shutdown()

MODULE = pEFL::Ecore::Evas		PACKAGE = EcoreEvasPtr     PREFIX = ecore_evas_


void
ecore_evas_alpha_set(ee,alpha)
	EcoreEvas *ee
	Eina_Bool alpha


Eina_Bool
ecore_evas_alpha_get(ee)
	const EcoreEvas *ee


void
ecore_evas_transparent_set(ee,transparent)
	EcoreEvas *ee
	Eina_Bool transparent


Eina_Bool
ecore_evas_transparent_get(ee)
	const EcoreEvas *ee


void
ecore_evas_geometry_get(ee,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int x
	int y
	int w
	int h


void
ecore_evas_request_geometry_get(ee,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int x
	int y
	int w
	int h


void
ecore_evas_focus_set(ee,on)
	EcoreEvas *ee
	Eina_Bool on


Eina_Bool
ecore_evas_focus_get(ee)
	const EcoreEvas *ee


# seat is Efl_Input_Device!!
# Eina_Bool
# ecore_evas_focus_device_get(ee,seat)
#	const EcoreEvas *ee
#	Eo *seat


void
ecore_evas_iconified_set(ee,on)
	EcoreEvas *ee
	Eina_Bool on


Eina_Bool
ecore_evas_iconified_get(ee)
	const EcoreEvas *ee


void
ecore_evas_borderless_set(ee,on)
	EcoreEvas *ee
	Eina_Bool on


Eina_Bool
ecore_evas_borderless_get(ee)
	const EcoreEvas *ee


void
ecore_evas_fullscreen_set(ee,on)
	EcoreEvas *ee
	Eina_Bool on


Eina_Bool
ecore_evas_fullscreen_get(ee)
	const EcoreEvas *ee


void
ecore_evas_window_group_set(ee,ee_group)
	EcoreEvas *ee
	const EcoreEvas *ee_group


EcoreEvas *
ecore_evas_window_group_get(ee)
	const EcoreEvas *ee


void
ecore_evas_aspect_set(ee,aspect)
	EcoreEvas *ee
	double aspect


double
ecore_evas_aspect_get(ee)
	const EcoreEvas *ee


void
ecore_evas_urgent_set(ee,urgent)
	EcoreEvas *ee
	Eina_Bool urgent


Eina_Bool
ecore_evas_urgent_get(ee)
	const EcoreEvas *ee


void
ecore_evas_modal_set(ee,modal)
	EcoreEvas *ee
	Eina_Bool modal


Eina_Bool
ecore_evas_modal_get(ee)
	const EcoreEvas *ee


void
ecore_evas_demand_attention_set(ee,demand)
	EcoreEvas *ee
	Eina_Bool demand


Eina_Bool
ecore_evas_demand_attention_get(ee)
	const EcoreEvas *ee


void
ecore_evas_focus_skip_set(ee,skip)
	EcoreEvas *ee
	Eina_Bool skip


Eina_Bool
ecore_evas_focus_skip_get(ee)
	const EcoreEvas *ee


void
ecore_evas_ignore_events_set(ee,ignore)
	EcoreEvas *ee
	Eina_Bool ignore


Eina_Bool
ecore_evas_ignore_events_get(ee)
	const EcoreEvas *ee


int
ecore_evas_visibility_get(ee)
	const EcoreEvas *ee


void
ecore_evas_layer_set(ee,layer)
	EcoreEvas *ee
	int layer


int
ecore_evas_layer_get(ee)
	const EcoreEvas *ee


void
ecore_evas_maximized_set(ee,on)
	EcoreEvas *ee
	Eina_Bool on


Eina_Bool
ecore_evas_maximized_get(ee)
	const EcoreEvas *ee


Eina_Bool
ecore_evas_window_profile_supported_get(ee)
	const EcoreEvas *ee


void
ecore_evas_window_profile_set(ee,profile)
	EcoreEvas *ee
	const char *profile


char *
ecore_evas_window_profile_get(ee)
	const EcoreEvas *ee


# void
# ecore_evas_window_available_profiles_set(ee,*profiles,count)
#	EcoreEvas *ee
#	const char **profiles
#	const unsigned int count


# Eina_Bool
# ecore_evas_window_available_profiles_get(ee,**profiles,count)
#	EcoreEvas *ee
#	char ***profiles
#	unsigned int *count


Eina_Bool
ecore_evas_wm_rotation_supported_get(ee)
	const EcoreEvas *ee


void
ecore_evas_wm_rotation_preferred_rotation_set(ee,rotation)
	EcoreEvas *ee
	int rotation


int
ecore_evas_wm_rotation_preferred_rotation_get(ee)
	const EcoreEvas *ee


# void
# ecore_evas_wm_rotation_available_rotations_set(ee,rotations,count)
#	EcoreEvas *ee
#	int *rotations
#	unsigned int count


# Eina_Bool
# ecore_evas_wm_rotation_available_rotations_get(ee,*rotations,count)
#	const EcoreEvas *ee
#	int **rotations
#	unsigned int *count


void
ecore_evas_wm_rotation_manual_rotation_done_set(ee,set)
	EcoreEvas *ee
	Eina_Bool set


Eina_Bool
ecore_evas_wm_rotation_manual_rotation_done_get(ee)
	const EcoreEvas *ee


void
ecore_evas_wm_rotation_manual_rotation_done(ee)
	EcoreEvas *ee


EinaList *
ecore_evas_aux_hints_supported_get(ee)
	const EcoreEvas *ee


EinaList *
ecore_evas_aux_hints_allowed_get(ee)
	const EcoreEvas *ee


int
ecore_evas_aux_hint_add(ee,hint,val)
	EcoreEvas *ee
	const char *hint
	const char *val


Eina_Bool
ecore_evas_aux_hint_del(ee,id)
	EcoreEvas *ee
	int id


Eina_Bool
ecore_evas_aux_hint_val_set(ee,id,val)
	EcoreEvas *ee
	int id
	const char *val


char *
ecore_evas_aux_hint_val_get(ee,id)
	const EcoreEvas *ee
	int id


int
ecore_evas_aux_hint_id_get(ee,hint)
	const EcoreEvas *ee
	const char *hint


# void
# ecore_evas_msg_parent_send(ee,msg_domain,msg_id,data,size)
#	EcoreEvas *ee
#	int msg_domain
#	int msg_id
#	void *data
#	int size


# void
# ecore_evas_msg_send(ee,msg_domain,msg_id,data,size)
#	EcoreEvas *ee
#	int msg_domain
#	int msg_id
#	void *data
#	int size


# void
# ecore_evas_callback_msg_parent_handle_set(ee,ee,msg_domain,msg_id,data,size))
#	EcoreEvas *ee
#	void (*func_parent_handle)(EcoreEvas *ee
#	int msg_domain
#	int msg_id
#	void *data
#	int size)


# void
# ecore_evas_callback_msg_handle_set(ee,ee,msg_domain,msg_id,data,size))
#	EcoreEvas *ee
#	void (*func_handle)(EcoreEvas *ee
#	int msg_domain
#	int msg_id
#	void *data
#	int size)


void
ecore_evas_move(ee,x,y)
	EcoreEvas *ee
	int x
	int y


void
ecore_evas_resize(ee,w,h)
	EcoreEvas *ee
	int w
	int h


void
ecore_evas_move_resize(ee,x,y,w,h)
	EcoreEvas *ee
	int x
	int y
	int w
	int h


void
ecore_evas_rotation_set(ee,rot)
	EcoreEvas *ee
	int rot


void
ecore_evas_rotation_with_resize_set(ee,rot)
	EcoreEvas *ee
	int rot


int
ecore_evas_rotation_get(ee)
	const EcoreEvas *ee


void
ecore_evas_raise(ee)
	EcoreEvas *ee


void
ecore_evas_lower(ee)
	EcoreEvas *ee


void
ecore_evas_title_set(ee,t)
	EcoreEvas *ee
	const char *t


char *
ecore_evas_title_get(ee)
	const EcoreEvas *ee


void
ecore_evas_name_class_set(ee,n,c)
	EcoreEvas *ee
	const char *n
	const char *c


void
ecore_evas_name_class_get(ee,OUTLIST n,OUTLIST c)
	const EcoreEvas *ee
	const char *n
	const char *c


# Ecore_Window
# ecore_evas_window_get(ee)
#	const EcoreEvas *ee



void
ecore_evas_wayland_resize(ee,location)
	EcoreEvas *ee
	int location


void
ecore_evas_wayland_move(ee,x,y)
	EcoreEvas *ee
	int x
	int y


void
ecore_evas_wayland_pointer_set(ee,hot_x,hot_y)
	EcoreEvas *ee
	int hot_x
	int hot_y


void
ecore_evas_wayland_type_set(ee,type)
	EcoreEvas *ee
	int type


# Ecore_Wl_Window *
# ecore_evas_wayland_window_get(ee)
#	const EcoreEvas *ee


# Ecore_Cocoa_Window *
# ecore_evas_cocoa_window_get(ee)
#	const EcoreEvas *ee


# EcoreEvas *
# ecore_evas_buffer_allocfunc_new(w,h,data,size),data,pix),data)
#	int w
#	int h
#	void *(*alloc_func) (void *data
#	int size)
#	void (*free_func) (void *data
#	void *pix)
#	const void *data


# void *
# ecore_evas_buffer_pixels_get(ee)
#	EcoreEvas *ee


EcoreEvas *
ecore_evas_buffer_ecore_evas_parent_get(ee)
	EcoreEvas *ee


EvasObject *
ecore_evas_ews_backing_store_get(ee)
	const EcoreEvas *ee


void
ecore_evas_ews_delete_request(ee)
	EcoreEvas *ee


EvasObject *
ecore_evas_object_image_new(ee_target)
	EcoreEvas *ee_target


EcoreEvas *
ecore_evas_object_ecore_evas_get(obj)
	EvasObject *obj


EvasCanvas *
ecore_evas_object_evas_get(obj)
	EvasObject *obj


char *
ecore_evas_engine_name_get(ee)
	const EcoreEvas *ee


EcoreEvas *
ecore_evas_ecore_evas_get(e)
	const EvasCanvas *e


void
ecore_evas_free(ee)
	EcoreEvas *ee


# void *
# ecore_evas_data_get(ee,key)
#	const EcoreEvas *ee
#	const char *key


# void
# ecore_evas_data_set(ee,key,data)
#	EcoreEvas *ee
#	const char *key
#	const void *data


void
_ecore_evas_callback_resize_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_resize_set(ee,call_perl_ecore_evas_resize);

void
_ecore_evas_callback_move_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_move_set(ee,call_perl_ecore_evas_move);

void
_ecore_evas_callback_show_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_show_set(ee,call_perl_ecore_evas_show);

void
_ecore_evas_callback_hide_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_hide_set(ee,call_perl_ecore_evas_hide);

void
_ecore_evas_callback_delete_request_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_delete_request_set(ee,call_perl_ecore_evas_delete_request);
    

void
_ecore_evas_callback_destroy_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_destroy_set(ee,call_perl_ecore_evas_destroy);

void
_ecore_evas_callback_focus_in_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_focus_in_set(ee,call_perl_ecore_evas_focus_in);

void
_ecore_evas_callback_focus_out_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_focus_out_set(ee,call_perl_ecore_evas_focus_out);

# void
# ecore_evas_callback_focus_device_in_set(ee,func)
#	EcoreEvas *ee
#	EcoreEvas_Focus_Device_Event_Cb func


# void
# ecore_evas_callback_focus_device_out_set(ee,func)
#	EcoreEvas *ee
#	EcoreEvas_Focus_Device_Event_Cb func


void
_ecore_evas_callback_sticky_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_sticky_set(ee,call_perl_ecore_evas_sticky);

void
_ecore_evas_callback_unsticky_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_unsticky_set(ee,call_perl_ecore_evas_unsticky);
	

# void
# ecore_evas_callback_device_mouse_in_set(ee,func)
#	EcoreEvas *ee
#	EcoreEvas_Mouse_IO_Cb func


# void
# ecore_evas_callback_device_mouse_out_set(ee,func)
#	EcoreEvas *ee
#	EcoreEvas_Mouse_IO_Cb func


void
_ecore_evas_callback_mouse_in_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_mouse_in_set(ee,call_perl_ecore_evas_mouse_in);

void
_ecore_evas_callback_mouse_out_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_mouse_out_set(ee,call_perl_ecore_evas_mouse_out);

void
_ecore_evas_callback_pre_render_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_pre_render_set(ee,call_perl_ecore_evas_pre_render);

void
_ecore_evas_callback_post_render_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_post_render_set(ee,call_perl_ecore_evas_post_render);

void
_ecore_evas_callback_pre_free_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_pre_free_set(ee,call_perl_ecore_evas_pre_free);

void
_ecore_evas_callback_state_change_set(ee,func)
	EcoreEvas *ee
	SV *func
CODE:
    ecore_evas_callback_state_change_set(ee,call_perl_ecore_evas_state_change);

EvasCanvas *
ecore_evas_evas_get(ee)
	const EcoreEvas *ee
CODE:
    RETVAL = ecore_evas_get(ee);
OUTPUT:
    RETVAL

void
ecore_evas_managed_move(ee,x,y)
	EcoreEvas *ee
	int x
	int y


void
ecore_evas_shaped_set(ee,shaped)
	EcoreEvas *ee
	Eina_Bool shaped


Eina_Bool
ecore_evas_shaped_get(ee)
	const EcoreEvas *ee


void
ecore_evas_show(ee)
	EcoreEvas *ee


void
ecore_evas_hide(ee)
	EcoreEvas *ee


void
ecore_evas_activate(ee)
	EcoreEvas *ee


void
ecore_evas_size_min_set(ee,w,h)
	EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_min_get(ee,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_max_set(ee,w,h)
	EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_max_get(ee,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_base_set(ee,w,h)
	EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_base_get(ee,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_step_set(ee,w,h)
	EcoreEvas *ee
	int w
	int h


void
ecore_evas_size_step_get(ee,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int w
	int h


void
ecore_evas_cursor_set(ee,file,layer,hot_x,hot_y)
	EcoreEvas *ee
	const char *file
	int layer
	int hot_x
	int hot_y


void
ecore_evas_cursor_get(ee,OUTLIST obj,OUTLIST layer,OUTLIST hot_x,OUTLIST hot_y)
	const EcoreEvas *ee
	EvasObject *obj
	int layer
	int hot_x
	int hot_y


void
ecore_evas_object_cursor_set(ee,obj,layer,hot_x,hot_y)
	EcoreEvas *ee
	EvasObject *obj
	int layer
	int hot_x
	int hot_y


EvasObject*
ecore_evas_cursor_unset(ee)
	EcoreEvas *ee


# EvasObject *
# ecore_evas_cursor_device_unset(ee,pointer)
#	EcoreEvas *ee
#	Efl_Input_Device *pointer


void
ecore_evas_override_set(ee,on)
	EcoreEvas *ee
	Eina_Bool on


Eina_Bool
ecore_evas_override_get(ee)
	const EcoreEvas *ee


void
ecore_evas_avoid_damage_set(ee,on)
	EcoreEvas *ee
	int on


int
ecore_evas_avoid_damage_get(ee)
	const EcoreEvas *ee


void
ecore_evas_withdrawn_set(ee,withdrawn)
	EcoreEvas *ee
	Eina_Bool withdrawn


Eina_Bool
ecore_evas_withdrawn_get(ee)
	const EcoreEvas *ee


void
ecore_evas_sticky_set(ee,sticky)
	EcoreEvas *ee
	Eina_Bool sticky


Eina_Bool
ecore_evas_sticky_get(ee)
	const EcoreEvas *ee


void
ecore_evas_manual_render_set(ee,manual_render)
	EcoreEvas *ee
	Eina_Bool manual_render


Eina_Bool
ecore_evas_manual_render_get(ee)
	const EcoreEvas *ee


void
ecore_evas_input_event_register(ee)
	EcoreEvas *ee


void
ecore_evas_input_event_unregister(ee)
	EcoreEvas *ee


void
ecore_evas_manual_render(ee)
	EcoreEvas *ee


void
ecore_evas_comp_sync_set(ee,do_sync)
	EcoreEvas *ee
	Eina_Bool do_sync


Eina_Bool
ecore_evas_comp_sync_get(ee)
	const EcoreEvas *ee


void
ecore_evas_screen_geometry_get(ee,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int x
	int y
	int w
	int h


void
ecore_evas_screen_dpi_get(ee,OUTLIST xdpi,OUTLIST ydpi)
	const EcoreEvas *ee
	int xdpi
	int ydpi


void
ecore_evas_shadow_geometry_set(ee,x,y,w,h)
	EcoreEvas *ee
	int x
	int y
	int w
	int h


void
ecore_evas_shadow_geometry_get(ee,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EcoreEvas *ee
	int x
	int y
	int w
	int h


Eina_Bool
ecore_evas_object_associate(ee,obj,flags)
	EcoreEvas *ee
	EvasObject *obj
	int flags


Eina_Bool
ecore_evas_object_dissociate(ee,obj)
	EcoreEvas *ee
	EvasObject *obj


EvasObject *
ecore_evas_object_associate_get(ee)
	const EcoreEvas *ee


# char
# ecore_getopt_callback_ecore_evas_list_engines(parser,desc,str,data,storage)
#	const Ecore_Getopt *parser
#	const Ecore_Getopt_Desc *desc
#	const char *str
#	void *data
#	Ecore_Getopt_Value *storage


EinaList *
ecore_evas_ecore_evas_list_get()
	 


EinaList *
ecore_evas_sub_ecore_evas_list_get(ee)
	const EcoreEvas *ee


# void
# ecore_evas_callback_new_set(w,h))
#	Evas *(*func)(int w
#	int h)


Eina_Bool
ecore_evas_ews_engine_set(engine,options)
	const char *engine
	const char *options


Eina_Bool
ecore_evas_ews_setup(x,y,w,h)
	int x
	int y
	int w
	int h


EcoreEvas *
ecore_evas_ews_ecore_evas_get()
	 


EvasCanvas *
ecore_evas_ews_evas_get()
	 


EvasObject *
ecore_evas_ews_background_get()
	 


void
ecore_evas_ews_background_set(o)
	EvasObject *o


EinaList *
ecore_evas_ews_children_get()
	 


# void
# ecore_evas_ews_manager_set(manager)
#	const void *manager


# void *
#ecore_evas_ews_manager_get()


Eina_Bool
ecore_evas_extn_socket_listen(ee,svcname,svcnum,svcsys)
	EcoreEvas *ee
	const char *svcname
	int svcnum
	Eina_Bool svcsys


void
ecore_evas_extn_socket_events_block_set(ee,events_block)
	EcoreEvas *ee
	Eina_Bool events_block


Eina_Bool
ecore_evas_extn_socket_events_block_get(ee)
	EcoreEvas *ee


void
ecore_evas_extn_plug_object_data_lock(obj)
	EvasObject *obj


void
ecore_evas_extn_plug_object_data_unlock(obj)
	EvasObject *obj


Eina_Bool
ecore_evas_extn_plug_connect(obj,svcname,svcnum,svcsys)
	EvasObject *obj
	const char *svcname
	int svcnum
	Eina_Bool svcsys


void
ecore_evas_pointer_xy_get(ee,OUTLIST x,OUTLIST y)
	const EcoreEvas *ee
	Evas_Coord x
	Evas_Coord y


Eina_Bool
ecore_evas_pointer_warp(ee,x,y)
	const EcoreEvas *ee
	Evas_Coord x
	Evas_Coord y


# void
# ecore_evas_pointer_device_xy_get(ee,pointer,OUTLIST x,OUTLIST y)
#	const EcoreEvas *ee
#	const Efl_Input_Device *pointer
#	Evas_Coord x
#	Evas_Coord y


# void *
# ecore_evas_pixmap_visual_get(ee)
#	const EcoreEvas *ee


long
ecore_evas_pixmap_colormap_get(ee)
	const EcoreEvas *ee


int
ecore_evas_pixmap_depth_get(ee)
	const EcoreEvas *ee


# void
# ecore_evas_callback_selection_changed_set(ee,cb)
#	EcoreEvas *ee
#	EcoreEvas_Selection_Changed_Cb cb


# Eina_Bool
# ecore_evas_selection_set(ee,seat,buffer,content)
#	EcoreEvas *ee
#	unsigned int seat
#	EcoreEvas_Selection_Buffer buffer
#	Eina_Content *content


# Eina_Bool
# ecore_evas_selection_exists(ee,seat,buffer)
#	EcoreEvas *ee
#	unsigned int seat
#	EcoreEvas_Selection_Buffer buffer


# Eina_Future*
# ecore_evas_selection_get(ee,seat,buffer,acceptable_types)
#	EcoreEvas *ee
#	unsigned int seat
#	EcoreEvas_Selection_Buffer buffer
#	Eina_Iterator *acceptable_types


# Eina_Bool
# ecore_evas_drag_cancel(ee,seat)
#	EcoreEvas *ee
#	unsigned int seat


# void
# ecore_evas_callback_drop_state_changed_set(ee,cb)
#	EcoreEvas *ee
#	EcoreEvas_Drag_State_Changed_Cb cb


# void
# ecore_evas_callback_drop_motion_set(ee,cb)
#	EcoreEvas *ee
#	EcoreEvas_Drag_Motion_Cb cb


# void
# ecore_evas_callback_drop_drop_set(ee,cb)
#	EcoreEvas *ee
#	EcoreEvas_Drop_Cb cb


# Eina_Accessor*
# ecore_evas_drop_available_types_get(ee,seat)
#	EcoreEvas *ee
#	unsigned int seat
