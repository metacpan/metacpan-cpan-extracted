#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object EvasObject;
typedef Eina_List EinaList;
typedef Elm_Text_Class ElmTextClass;
typedef Elm_Font_Overlay ElmFontOverlay;
typedef Elm_Color_Class ElmColorClass;
typedef Elm_Palette ElmPalette;

MODULE = pEFL::Elm::Config		PACKAGE = pEFL::Elm::Config	PREFIX = elm_config_

Eina_Bool
elm_config_save()


void
elm_config_reload()


void
elm_config_all_flush()	 


char *
elm_config_profile_get()


char *
elm_config_profile_dir_get(profile,is_user)
	const char *profile
	Eina_Bool is_user


void
elm_config_profile_dir_free(p_dir)
	const char *p_dir
	
EinaList *
elm_config_profile_list_get()
	 

EinaList *
elm_config_profile_list_full_get()
	 

void
elm_config_profile_list_free(l)
	EinaList *l


Eina_Bool
elm_config_profile_exists(profile)
	const char *profile


void
elm_config_profile_set(profile)
	const char *profile


void
elm_config_profile_save(profile)
	const char *profile


void
elm_config_profile_derived_add(profile,derive_options)
	const char *profile
	const char *derive_options


void
elm_config_profile_derived_del(profile)
	const char *profile


Eina_Bool
elm_config_scroll_bounce_enabled_get()
	 


void
elm_config_scroll_bounce_enabled_set(enabled)
	Eina_Bool enabled


double
elm_config_scroll_bounce_friction_get()
	 


void
elm_config_scroll_bounce_friction_set(friction)
	double friction


double
elm_config_scroll_page_scroll_friction_get()
	 


void
elm_config_scroll_page_scroll_friction_set(friction)
	double friction


Eina_Bool
elm_config_context_menu_disabled_get()
	 


void
elm_config_context_menu_disabled_set(disabled)
	Eina_Bool disabled


double
elm_config_scroll_bring_in_scroll_friction_get()
	 


void
elm_config_scroll_bring_in_scroll_friction_set(friction)
	double friction


double
elm_config_scroll_zoom_friction_get()
	 


void
elm_config_scroll_zoom_friction_set(friction)
	double friction


Eina_Bool
elm_config_scroll_thumbscroll_enabled_get()
	 


void
elm_config_scroll_thumbscroll_enabled_set(enabled)
	Eina_Bool enabled


int
elm_config_scroll_thumbscroll_threshold_get()
	 


void
elm_config_scroll_thumbscroll_threshold_set(threshold)
	unsigned int threshold


int
elm_config_scroll_thumbscroll_hold_threshold_get()
	 


void
elm_config_scroll_thumbscroll_hold_threshold_set(threshold)
	unsigned int threshold


double
elm_config_scroll_thumbscroll_momentum_threshold_get()
	 


void
elm_config_scroll_thumbscroll_momentum_threshold_set(threshold)
	double threshold


int
elm_config_scroll_thumbscroll_momentum_distance_max_get()
	 


void
elm_config_scroll_thumbscroll_momentum_distance_max_set(distance)
	unsigned int distance


double
elm_config_scroll_thumbscroll_momentum_friction_get()
	 


void
elm_config_scroll_thumbscroll_momentum_friction_set(friction)
	double friction


double
elm_config_scroll_thumbscroll_border_friction_get()
	 


void
elm_config_scroll_thumbscroll_border_friction_set(friction)
	double friction


double
elm_config_scroll_thumbscroll_sensitivity_friction_get()
	 


void
elm_config_scroll_thumbscroll_sensitivity_friction_set(friction)
	double friction


Eina_Bool
elm_config_scroll_thumbscroll_smooth_start_get()
	 


void
elm_config_scroll_thumbscroll_smooth_start_set(enable)
	Eina_Bool enable


Eina_Bool
elm_config_scroll_animation_disabled_get()
	 


void
elm_config_scroll_animation_disabled_set(disable)
	Eina_Bool disable


double
elm_config_scroll_accel_factor_get()
	 


void
elm_config_scroll_accel_factor_set(factor)
	double factor


double
elm_config_scroll_thumbscroll_smooth_amount_get()
	 


void
elm_config_scroll_thumbscroll_smooth_amount_set(amount)
	double amount


double
elm_config_scroll_thumbscroll_smooth_time_window_get()
	 


void
elm_config_scroll_thumbscroll_smooth_time_window_set(amount)
	double amount


double
elm_config_scroll_thumbscroll_acceleration_threshold_get()
	 


void
elm_config_scroll_thumbscroll_acceleration_threshold_set(threshold)
	double threshold


double
elm_config_scroll_thumbscroll_acceleration_time_limit_get()
	 


void
elm_config_scroll_thumbscroll_acceleration_time_limit_set(time_limit)
	double time_limit


double
elm_config_scroll_thumbscroll_acceleration_weight_get()
	 


void
elm_config_scroll_thumbscroll_acceleration_weight_set(weight)
	double weight


double
elm_config_scroll_thumbscroll_momentum_animation_duration_min_limit_get()
	 


void
elm_config_scroll_thumbscroll_momentum_animation_duration_min_limit_set(min)
	double min


double
elm_config_scroll_thumbscroll_momentum_animation_duration_max_limit_get()
	 


void
elm_config_scroll_thumbscroll_momentum_animation_duration_max_limit_set(max)
	double max


double
elm_config_scroll_thumbscroll_min_friction_get()
	 


void
elm_config_scroll_thumbscroll_min_friction_set(friction)
	double friction


double
elm_config_scroll_thumbscroll_friction_standard_get()
	 


void
elm_config_scroll_thumbscroll_friction_standard_set(standard)
	double standard


int
elm_config_scroll_thumbscroll_flick_distance_tolerance_get()
	 


void
elm_config_scroll_thumbscroll_flick_distance_tolerance_set(distance)
	unsigned int distance


double
elm_config_scroll_thumbscroll_friction_get()
	 


void
elm_config_scroll_thumbscroll_friction_set(friction)
	double friction


#Elm_Focus_Autoscroll_Mode
int
elm_config_focus_autoscroll_mode_get()


void
elm_config_focus_autoscroll_mode_set(mode)
	int mode


void
elm_config_slider_indicator_visible_mode_set(mode)
	int mode


#Elm_Slider_Indicator_Visible_Mode
int
elm_config_slider_indicator_visible_mode_get()


double
elm_config_longpress_timeout_get()	 


void
elm_config_longpress_timeout_set(longpress_timeout)
	double longpress_timeout


void
elm_config_softcursor_mode_set(mode)
	int mode


int
elm_config_softcursor_mode_get()


double
elm_config_tooltip_delay_get()
	 


void
elm_config_tooltip_delay_set(delay)
	double delay


Eina_Bool
elm_config_cursor_engine_only_get()
	 


void
elm_config_cursor_engine_only_set(engine_only)
	Eina_Bool engine_only


double
elm_config_scale_get()
	 


void
elm_config_scale_set(scale)
	double scale


char *
elm_config_icon_theme_get()
	 


void
elm_config_icon_theme_set(theme)
	const char *theme

#################
# the palette code is marked in elm_config.h as not surely final yet
################

char *
elm_config_palette_get()	 


void
elm_config_palette_set(palette)
	const char *palette


ElmPalette *
elm_config_palette_load(palette)
	const char *palette


void
elm_config_palette_color_set(pal,name,r,g,b,a)
	ElmPalette *pal
	const char *name
	int r
	int g
	int b
	int a

void
elm_config_palette_color_unset(pal,name)
	ElmPalette *pal
	const char *name

void
elm_config_palette_save(pal,palette)
	ElmPalette *pal
	const char *palette


void
elm_config_palette_free(pal)
	ElmPalette *pal

void
elm_config_palette_delete(palette)
	const char *palette


Eina_Bool
elm_config_palette_system_has(palette)
	const char *palette


EinaList *
elm_config_palette_list()	 


void
elm_config_palette_list_free(list)
	EinaList *list


Eina_Bool
elm_config_password_show_last_get()	 


void
elm_config_password_show_last_set(password_show_last)
	Eina_Bool password_show_last


double
elm_config_password_show_last_timeout_get()


void
elm_config_password_show_last_timeout_set(password_show_last_timeout)
	double password_show_last_timeout


# DEPRECATED
#char *
#elm_config_engine_get()
	 

# DEPRECATED
#void
#elm_config_engine_set(engine)
#	const char *engine


char *
elm_config_preferred_engine_get()
	 


void
elm_config_preferred_engine_set(engine)
	const char *engine


char *
elm_config_accel_preference_get()
	 


void
elm_config_accel_preference_set(pref)
	const char *pref


EinaList *
elm_config_text_classes_list_get()
	 

void
elm_config_text_classes_list_free(list)
	EinaList *list

EinaList *
elm_config_font_overlay_list_get()	 

void
elm_config_font_overlay_set(text_class,font,size)
	const char *text_class
	const char *font
	int size

Eina_Bool
elm_config_access_get()
	 


void
elm_config_access_set(is_access)
	Eina_Bool is_access


Eina_Bool
elm_config_selection_unfocused_clear_get()
	 


void
elm_config_selection_unfocused_clear_set(enabled)
	Eina_Bool enabled


void
elm_config_font_overlay_unset(text_class)
	const char *text_class


void
elm_config_font_overlay_apply()
	 


void
elm_config_font_hint_type_set(type)
	int type


Evas_Coord
elm_config_finger_size_get()
	 


void
elm_config_finger_size_set(size)
	Evas_Coord size


int
elm_config_cache_flush_interval_get()
	 


void
elm_config_cache_flush_interval_set(size)
	int size


Eina_Bool
elm_config_cache_flush_enabled_get()
	 


void
elm_config_cache_flush_enabled_set(enabled)
	Eina_Bool enabled


int
elm_config_cache_font_cache_size_get()
	 


void
elm_config_cache_font_cache_size_set(size)
	int size


int
elm_config_cache_image_cache_size_get()
	 


void
elm_config_cache_image_cache_size_set(size)
	int size


int
elm_config_cache_edje_file_cache_size_get()
	 


void
elm_config_cache_edje_file_cache_size_set(size)
	int size


int
elm_config_cache_edje_collection_cache_size_get()
	 


void
elm_config_cache_edje_collection_cache_size_set(size)
	int size


Eina_Bool
elm_config_vsync_get()
	 


void
elm_config_vsync_set(enabled)
	Eina_Bool enabled


Eina_Bool
elm_config_agressive_withdrawn_get()
	 


void
elm_config_agressive_withdrawn_set(enabled)
	Eina_Bool enabled


Eina_Bool
elm_config_accel_preference_override_get()
	 


void
elm_config_accel_preference_override_set(enabled)
	Eina_Bool enabled


Eina_Bool
elm_config_focus_highlight_enabled_get()
	 


void
elm_config_focus_highlight_enabled_set(enable)
	Eina_Bool enable


Eina_Bool
elm_config_focus_highlight_animate_get()
	 


void
elm_config_focus_highlight_animate_set(animate)
	Eina_Bool animate


Eina_Bool
elm_config_focus_highlight_clip_disabled_get()
	 


void
elm_config_focus_highlight_clip_disabled_set(disable)
	Eina_Bool disable
	
	
int
elm_config_focus_move_policy_get()	 


void
elm_config_focus_move_policy_set(policy)
	int policy

Eina_Bool
elm_config_item_select_on_focus_disabled_get()
	 


void
elm_config_item_select_on_focus_disabled_set(disabled)
	Eina_Bool disabled


Eina_Bool
elm_config_first_item_focus_on_first_focusin_get()
	 


void
elm_config_first_item_focus_on_first_focusin_set(enabled)
	Eina_Bool enabled


Eina_Bool
elm_config_mirrored_get()
	 


void
elm_config_mirrored_set(mirrored)
	Eina_Bool mirrored


Eina_Bool
elm_config_clouseau_enabled_get()
	 


void
elm_config_clouseau_enabled_set(enabled)
	Eina_Bool enabled


char *
elm_config_indicator_service_get(rotation)
	int rotation


double
elm_config_glayer_long_tap_start_timeout_get()
	 


void
elm_config_glayer_long_tap_start_timeout_set(long_tap_timeout)
	double long_tap_timeout


double
elm_config_glayer_double_tap_timeout_get()
	 


void
elm_config_glayer_double_tap_timeout_set(double_tap_timeout)
	double double_tap_timeout


EinaList *
elm_config_color_classes_list_get()
	 

void
elm_config_color_classes_list_free(list)
	EinaList *list


#EinaList *
#elm_config_color_overlay_list_get()


void
elm_config_color_overlay_set(const char *color_class,int r, int g, int b, int a, int r2, int g2, int b2, int a2, int r3, int g3, int b3, int a3);


void
elm_config_color_overlay_unset(color_class)
	const char *color_class


void
elm_config_color_overlay_apply()
	 


Eina_Bool
elm_config_desktop_entry_get()
	 


void
elm_config_desktop_entry_set(enable)
	Eina_Bool enable


Eina_Bool
elm_config_magnifier_enable_get()
	 


void
elm_config_magnifier_enable_set(enable)
	Eina_Bool enable


double
elm_config_magnifier_scale_get()
	 


void
elm_config_magnifier_scale_set(scale)
	double scale


#Eina_Bool
#elm_config_audio_mute_get(channel)
#	Edje_Channel channel


#void
#elm_config_audio_mute_set(channel,mute)
#	Edje_Channel channel
#	Eina_Bool mute


Eina_Bool
elm_config_window_auto_focus_enable_get()
	 


void
elm_config_window_auto_focus_enable_set(enable)
	Eina_Bool enable


Eina_Bool
elm_config_window_auto_focus_animate_get()
	 


void
elm_config_window_auto_focus_animate_set(enable)
	Eina_Bool enable


Eina_Bool
elm_config_popup_scrollable_get()
	 


void
elm_config_popup_scrollable_set(scrollable)
	Eina_Bool scrollable


Eina_Bool
elm_config_atspi_mode_get()
	 


void
elm_config_atspi_mode_set(is_atspi)
	Eina_Bool is_atspi


void
elm_config_transition_duration_factor_set(factor)
	double factor


double
elm_config_transition_duration_factor_get()
	 


void
elm_config_web_backend_set(backend)
	const char *backend


char *
elm_config_web_backend_get()
	 


Eina_Bool
elm_config_offline_get()
	 


void
elm_config_offline_set(set)
	Eina_Bool set


int
elm_config_powersave_get()
	 


void
elm_config_powersave_set(set)
	int set


double
elm_config_drag_anim_duration_get()
	 


void
elm_config_drag_anim_duration_set(set)
	double set


MODULE = pEFL::Elm::Config		PACKAGE = ElmTextClassPtr

const char*
name(text_class)
    ElmTextClass *text_class
CODE:
    RETVAL = text_class->name;
OUTPUT:
    RETVAL


const char*
desc(text_class)
    ElmTextClass *text_class
CODE:
    RETVAL = text_class->desc;
OUTPUT:
    RETVAL
    
    
MODULE = pEFL::Elm::Config		PACKAGE = ElmFontOverlayPtr

const char*
text_class(font_overlay)
    ElmFontOverlay *font_overlay
CODE:
    RETVAL = font_overlay->text_class;
OUTPUT:
    RETVAL


const char*
font(font_overlay)
    ElmFontOverlay *font_overlay
CODE:
    RETVAL = font_overlay->font;
OUTPUT:
    RETVAL
    
    
int
size(font_overlay)
    ElmFontOverlay *font_overlay
CODE:
    RETVAL = font_overlay->size;
OUTPUT:
    RETVAL


MODULE = pEFL::Elm::Config		PACKAGE = ElmColorClassPtr

const char*
name(color_class)
    ElmColorClass *color_class
CODE:
    RETVAL = color_class->name;
OUTPUT:
    RETVAL


const char*
desc(color_class)
    ElmColorClass *color_class
CODE:
    RETVAL = color_class->desc;
OUTPUT:
    RETVAL
    
MODULE = pEFL::Elm::Config		PACKAGE = ElmPalettePtr

int
version(pal)
    ElmPalette *pal
CODE:
    RETVAL = pal->version;
OUTPUT:
    RETVAL
    
    
EinaList *
colors(pal)
	ElmPalette *pal
CODE:
    RETVAL = pal->colors;
OUTPUT:
    RETVAL