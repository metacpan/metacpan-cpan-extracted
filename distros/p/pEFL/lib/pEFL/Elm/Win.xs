#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmWin;
typedef Evas_Object EvasObject;
typedef Evas_Object EvasObject;
typedef Elm_Icon ElmIcon;
typedef Elm_Menu ElmMenu;

MODULE = pEFL::Elm::Win		PACKAGE = pEFL::Elm::Win

ElmWin *
elm_win_add(parent,name,type)
	ElmWin *parent
	const char *name
	int type

ElmWin *
elm_win_util_standard_add(name,title)
	const char *name
	const char *title

ElmWin *
elm_win_util_dialog_add(parent,name,title)
	ElmWin *parent
	const char *name
	const char *title
	
MODULE = pEFL::Elm::Win		PACKAGE = pEFL::Elm::Win PREFIX = elm_win_
	
int
elm_win_xwindow_xid_get(obj)
    const ElmWin *obj
PREINIT:
    Ecore_X_Window xwin;
    int xid;
CODE:
    xwin = elm_win_xwindow_get(obj);
    xid = xwin;
    RETVAL = xid;
OUTPUT:
    RETVAL


MODULE = pEFL::Elm::Win		PACKAGE = ElmWinPtr     PREFIX = elm_win_


# ElmWin *
# elm_win_fake_add(ee)
#	Ecore_Evas *ee


void
elm_win_autodel_set(obj,autodel)
	ElmWin *obj
	Eina_Bool autodel


Eina_Bool
elm_win_autodel_get(obj)
	const ElmWin *obj


void
elm_win_floating_mode_set(obj,floating)
	ElmWin *obj
	Eina_Bool floating


Eina_Bool
elm_win_floating_mode_get(obj)
	const ElmWin *obj


void
elm_win_norender_push(obj)
	ElmWin *obj


void
elm_win_norender_pop(obj)
	ElmWin *obj


int
elm_win_norender_get(obj)
	const ElmWin *obj


void
elm_win_render(obj)
	ElmWin *obj


# _Window *
# elm_win_wl_window_get(obj)
#	const ElmWin *obj


void
elm_win_wm_rotation_preferred_rotation_set(obj,rotation)
	ElmWin *obj
	int rotation


void
elm_win_resize_object_add(obj,subobj)
	ElmWin *obj
	EvasObject *subobj


void
elm_win_resize_object_del(obj,subobj)
	ElmWin *obj
	EvasObject *subobj


# Ecore_X_Window
# elm_win_xwindow_get(obj)
#	const ElmWin *obj
    
# Ecore_Wl2_Window *
# elm_win_wl_window_get(obj)
#	const ElmWin *obj

# Ecore_Win32_Window *elm_win_win32_window_get(const Evas_Object *obj)

# Ecore_Cocoa_Window *
# elm_win_cocoa_window_get(obj)
#	const ElmWin *obj


void *
elm_win_trap_data_get(obj)
	const ElmWin *obj


void
elm_win_override_set(obj,override)
	ElmWin *obj
	Eina_Bool override


Eina_Bool
elm_win_override_get(obj)
	const ElmWin *obj


void
elm_win_lower(obj)
	ElmWin *obj


void
elm_win_quickpanel_set(obj,quickpanel)
	ElmWin *obj
	Eina_Bool quickpanel


Eina_Bool
elm_win_quickpanel_get(obj)
	const ElmWin *obj


void
elm_win_quickpanel_zone_set(obj,zone)
	ElmWin *obj
	int zone


int
elm_win_quickpanel_zone_get(obj)
	const ElmWin *obj


void
elm_win_quickpanel_priority_major_set(obj,priority)
	ElmWin *obj
	int priority


int
elm_win_quickpanel_priority_major_get(obj)
	const ElmWin *obj


void
elm_win_quickpanel_priority_minor_set(obj,priority)
	ElmWin *obj
	int priority


int
elm_win_quickpanel_priority_minor_get(obj)
	const ElmWin *obj


void
elm_win_indicator_mode_set(obj,mode)
	ElmWin *obj
	int mode


int
elm_win_indicator_mode_get(obj)
	const ElmWin *obj


void
elm_win_indicator_opacity_set(obj,mode)
	ElmWin *obj
	int mode


int
elm_win_indicator_opacity_get(obj)
	const ElmWin *obj


void
elm_win_keyboard_win_set(obj,is_keyboard)
	ElmWin *obj
	Eina_Bool is_keyboard


Eina_Bool
elm_win_keyboard_win_get(obj)
	const ElmWin *obj


void
elm_win_conformant_set(obj,conformant)
	ElmWin *obj
	Eina_Bool conformant


Eina_Bool
elm_win_conformant_get(obj)
	const ElmWin *obj


void
elm_win_wm_rotation_manual_rotation_done_set(obj,set)
	ElmWin *obj
	Eina_Bool set


Eina_Bool
elm_win_wm_rotation_manual_rotation_done_get(obj)
	const ElmWin *obj


void
elm_win_wm_rotation_manual_rotation_done(obj)
	ElmWin *obj


void
elm_win_rotation_set(obj,rotation)
	ElmWin *obj
	int rotation


int
elm_win_rotation_get(obj)
	const ElmWin *obj


void
elm_win_rotation_with_resize_set(obj,rotation)
	ElmWin *obj
	int rotation


Eina_Bool
elm_win_wm_rotation_supported_get(obj)
	const ElmWin *obj


int
elm_win_wm_rotation_preferred_rotation_get(obj)
	const ElmWin *obj


void
elm_win_screen_position_get(obj,OUTLIST x, OUTLIST y)
	const ElmWin *obj
	int x
	int y


void
elm_win_screen_size_get(obj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const ElmWin *obj
	int x
	int y
	int w
	int h


void
elm_win_screen_dpi_get(obj,OUTLIST xdpi,OUTLIST ydpi)
	const ElmWin *obj
	int xdpi
	int ydpi


void
elm_win_icon_name_set(obj,icon_name)
	ElmWin *obj
	const char *icon_name


char *
elm_win_icon_name_get(obj)
	const ElmWin *obj


void
elm_win_withdrawn_set(obj,withdrawn)
	ElmWin *obj
	Eina_Bool withdrawn


Eina_Bool
elm_win_withdrawn_get(obj)
	const ElmWin *obj


void
elm_win_urgent_set(obj,urgent)
	ElmWin *obj
	Eina_Bool urgent


Eina_Bool
elm_win_urgent_get(obj)
	const ElmWin *obj


void
elm_win_demand_attention_set(obj,demand_attention)
	ElmWin *obj
	Eina_Bool demand_attention


Eina_Bool
elm_win_demand_attention_get(obj)
	const ElmWin *obj


void
elm_win_modal_set(obj,modal)
	ElmWin *obj
	Eina_Bool modal


Eina_Bool
elm_win_modal_get(obj)
	const ElmWin *obj


void
elm_win_shaped_set(obj,shaped)
	ElmWin *obj
	Eina_Bool shaped


Eina_Bool
elm_win_shaped_get(obj)
	const ElmWin *obj


void
elm_win_title_set(obj,title)
	ElmWin *obj
	const char *title


char *
elm_win_title_get(obj)
	const ElmWin *obj


void
elm_win_size_base_set(obj,w,h)
	ElmWin *obj
	int w
	int h


void
elm_win_size_base_get(obj,OUTLIST w,OUTLIST h)
	const ElmWin *obj
	int w
	int h


void
elm_win_size_step_set(obj,w,h)
	ElmWin *obj
	int w
	int h


void
elm_win_size_step_get(obj,OUTLIST w,OUTLIST h)
	const ElmWin *obj
	int w
	int h


# void
# elm_win_illume_command_send(obj,command,params)
#	ElmWin *obj
#	Elm_Illume_Command command
#	void *params


void
elm_win_profile_set(obj,profile)
	ElmWin *obj
	const char *profile


char *
elm_win_profile_get(obj)
	const ElmWin *obj


void
elm_win_layer_set(obj,layer)
	ElmWin *obj
	int layer


int
elm_win_layer_get(obj)
	const ElmWin *obj


ElmWin *
elm_win_inlined_image_object_get(obj)
	const ElmWin *obj


# Ecore_Window
# elm_win_window_id_get(obj)
#	const ElmWin *obj


ElmMenu *
elm_win_main_menu_get(obj)
	ElmWin *obj


void
elm_win_keyboard_mode_set(obj,mode)
	ElmWin *obj
	int mode


int
elm_win_keyboard_mode_get(obj)
	const ElmWin *obj


void
elm_win_aspect_set(obj,aspect)
	ElmWin *obj
	double aspect


double
elm_win_aspect_get(obj)
	const ElmWin *obj


# Eina_Bool
# elm_win_keygrab_set(obj,key,modifiers,not_modifiers,priority,grab_mode)
#	ElmWin *obj
#	const char *key
#	Evas_Modifier_Mask modifiers
#	Evas_Modifier_Mask not_modifiers
#	int priority
#	int grab_mode


# Eina_Bool
# elm_win_keygrab_unset(obj,key,modifiers,not_modifiers)
#	ElmWin *obj
#	const char *key
#	Evas_Modifier_Mask modifiers
#	Evas_Modifier_Mask not_modifiers


ElmWin *
elm_win_get(obj)
	EvasObject *obj


Eina_Bool
elm_win_socket_listen(obj,svcname,svcnum,svcsys)
	ElmWin *obj
	const char *svcname
	int svcnum
	Eina_Bool svcsys


Eina_Bool
elm_win_focus_get(obj)
	const ElmWin *obj


void
elm_win_raise(obj)
	ElmWin *obj


# void
# elm_win_available_profiles_set(obj,*profiles,count)
#	ElmWin *obj
#	const char **profiles
#	unsigned int count


# Eina_Bool
# elm_win_available_profiles_get(obj,**profiles,count)
#	const ElmWin *obj
#	char ***profiles
#	unsigned int *count


# void
# elm_win_wm_rotation_available_rotations_set(obj,rotations,count)
#	ElmWin *obj
#	const int *rotations
#	unsigned int count


# Eina_Bool
# elm_win_wm_rotation_available_rotations_get(obj,*rotations,count)
#	const ElmWin *obj
#	int **rotations
#	unsigned int *count


void
elm_win_screen_constrain_set(obj,constrain)
	ElmWin *obj
	Eina_Bool constrain


Eina_Bool
elm_win_screen_constrain_get(obj)
	const ElmWin *obj


void
elm_win_prop_focus_skip_set(obj,skip)
	ElmWin *obj
	Eina_Bool skip


void
elm_win_autohide_set(obj,autohide)
	ElmWin *obj
	Eina_Bool autohide


Eina_Bool
elm_win_autohide_get(obj)
	const ElmWin *obj


void
elm_win_icon_object_set(obj,icon)
	ElmWin *obj
	ElmIcon *icon


ElmIcon *
elm_win_icon_object_get(obj)
	const ElmWin *obj


void
elm_win_iconified_set(obj,iconified)
	ElmWin *obj
	Eina_Bool iconified


Eina_Bool
elm_win_iconified_get(obj)
	const ElmWin *obj


void
elm_win_maximized_set(obj,maximized)
	ElmWin *obj
	Eina_Bool maximized


Eina_Bool
elm_win_maximized_get(obj)
	const ElmWin *obj


void
elm_win_fullscreen_set(obj,fullscreen)
	ElmWin *obj
	Eina_Bool fullscreen


Eina_Bool
elm_win_fullscreen_get(obj)
	const ElmWin *obj


void
elm_win_sticky_set(obj,sticky)
	ElmWin *obj
	Eina_Bool sticky


Eina_Bool
elm_win_sticky_get(obj)
	const ElmWin *obj


void
elm_win_noblank_set(obj,noblank)
	ElmWin *obj
	Eina_Bool noblank


Eina_Bool
elm_win_noblank_get(obj)
	const ElmWin *obj


void
elm_win_borderless_set(obj,borderless)
	ElmWin *obj
	Eina_Bool borderless


Eina_Bool
elm_win_borderless_get(obj)
	const ElmWin *obj


void
elm_win_role_set(obj,role)
	ElmWin *obj
	const char *role


char *
elm_win_role_get(obj)
	const ElmWin *obj


char *
elm_win_name_get(obj)
	const ElmWin *obj


int
elm_win_type_get(obj)
	const ElmWin *obj


char *
elm_win_accel_preference_get(obj)
	const ElmWin *obj


void
elm_win_alpha_set(obj,alpha)
	ElmWin *obj
	Eina_Bool alpha


Eina_Bool
elm_win_alpha_get(obj)
	const ElmWin *obj


void
elm_win_activate(obj)
	ElmWin *obj


void
elm_win_center(obj,h,v)
	ElmWin *obj
	Eina_Bool h
	Eina_Bool v


Eina_Bool
elm_win_move_resize_start(obj,mode)
	ElmWin *obj
	int mode


void
elm_win_focus_highlight_animate_set(obj,animate)
	ElmWin *obj
	Eina_Bool animate


Eina_Bool
elm_win_focus_highlight_animate_get(obj)
	const ElmWin *obj


void
elm_win_focus_highlight_enabled_set(obj,enabled)
	ElmWin *obj
	Eina_Bool enabled


Eina_Bool
elm_win_focus_highlight_enabled_get(obj)
	const ElmWin *obj


# Eina_Bool?
void
elm_win_focus_highlight_style_set(obj,style)
	ElmWin *obj
	const char *style


char *
elm_win_focus_highlight_style_get(obj)
	const ElmWin *obj
