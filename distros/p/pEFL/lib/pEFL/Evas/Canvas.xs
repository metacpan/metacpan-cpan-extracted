#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

// TODO: What is the difference between Evas and EvasCanvas?
// both are a typedef to Eo, therefore we use Eo here direct ;-)
typedef Eo EvasCanvas;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Evas::Canvas		PACKAGE = pEFL::Evas::Canvas     

EvasCanvas *
evas_new()

MODULE = pEFL::Evas::Canvas		PACKAGE = EvasCanvasPtr     PREFIX = evas_

EvasObject *
evas_object_bottom_get(obj)
	const EvasCanvas *obj


int
evas_coord_screen_y_to_world(obj,y)
	const EvasCanvas *obj
	int y


int
evas_coord_screen_x_to_world(obj,x)
	const EvasCanvas *obj
	int x


int
evas_coord_world_y_to_screen(obj,y)
	const EvasCanvas *obj
	int y


int
evas_coord_world_x_to_screen(obj,x)
	const EvasCanvas *obj
	int x


void
evas_damage_rectangle_add(obj,x,y,w,h)
	EvasCanvas *obj
	int x
	int y
	int w
	int h


# Eina_Bool
# evas_engine_info_set(obj,info)
#	EvasCanvas *obj
#	Evas_Engine_Info *info


# Evas_Engine_Info *
# evas_engine_info_get(obj)
#	const EvasCanvas *obj


void
evas_event_freeze(e)
	EvasCanvas *e


void
evas_event_thaw(e)
	EvasCanvas *e


int
evas_event_freeze_get(e)
	const EvasCanvas *e


# void
# evas_event_feed_mouse_move(obj,x,y,timestamp,data)
#	EvasCanvas *obj
#	int x
#	int y
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_mouse_up(obj,b,flags,timestamp,data)
#	EvasCanvas *obj
#	int b
#	int flags
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_mouse_down(obj,b,flags,timestamp,data)
#	EvasCanvas *obj
#	int b
#	int flags
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_mouse_wheel(obj,direction,z,timestamp,data)
#	EvasCanvas *obj
#	int direction
#	int z
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_mouse_in(obj,timestamp,data)
#	EvasCanvas *obj
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_mouse_out(obj,timestamp,data)
#	EvasCanvas *obj
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_mouse_cancel(obj,timestamp,data)
#	EvasCanvas *obj
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_multi_down(obj,d,x,y,rad,radx,rady,pres,ang,fx,fy,flags,timestamp,data)
#	EvasCanvas *obj
#	int d
#	int x
#	int y
#	double rad
#	double radx
#	double rady
#	double pres
#	double ang
#	double fx
#	double fy
#	int flags
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_multi_move(obj,d,x,y,rad,radx,rady,pres,ang,fx,fy,timestamp,data)
#	EvasCanvas *obj
#	int d
#	int x
#	int y
#	double rad
#	double radx
#	double rady
#	double pres
#	double ang
#	double fx
#	double fy
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_multi_up(obj,d,x,y,rad,radx,rady,pres,ang,fx,fy,flags,timestamp,data)
#	EvasCanvas *obj
#	int d
#	int x
#	int y
#	double rad
#	double radx
#	double rady
#	double pres
#	double ang
#	double fx
#	double fy
#	int flags
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_key_down(obj,keyname,key,string,compose,timestamp,data)
#	EvasCanvas *obj
#	const char *keyname
#	const char *key
#	const char *string
#	const char *compose
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_key_up(obj,keyname,key,string,compose,timestamp,data)
#	EvasCanvas *obj
#	const char *keyname
#	const char *key
#	const char *string
#	const char *compose
#	unsigned int timestamp
#	const void *data


# void
# evas_event_feed_hold(obj,hold,timestamp,data)
#	EvasCanvas *obj
#	int hold
#	unsigned int timestamp
#	const void *data


EvasObject *
evas_focus_get(obj)
	const EvasCanvas *obj


EinaList *
evas_font_available_list(obj)
	const EvasCanvas *obj


void
evas_font_cache_flush(obj)
	EvasCanvas *obj


int
evas_font_cache_get(obj)
	const EvasCanvas *obj


void
evas_font_cache_set(obj,size)
	EvasCanvas *obj
	int size


Eina_Bool
evas_font_hinting_can_hint(e,hinting)
	const EvasCanvas *e
	int hinting


void
evas_font_hinting_set(e,hinting)
	EvasCanvas *e
	int hinting


int
evas_font_hinting_get(e)
	const EvasCanvas *e


void
evas_font_path_prepend(obj,path)
	EvasCanvas *obj
	const char *path

void
evas_font_path_append(obj,path)
	EvasCanvas *obj
	const char *path


void
evas_font_path_clear(obj)
	EvasCanvas *obj


EinaList *
evas_font_path_list(obj)
	const EvasCanvas *obj


void
evas_object_freeze_events_set(obj,freeze)
	EvasObject *obj
	Eina_Bool freeze


Eina_Bool
evas_object_freeze_events_get(obj)
	const EvasObject *obj


void
evas_image_cache_set(obj,size)
	EvasCanvas *obj
	int size


int
evas_image_cache_get(obj)
	const EvasCanvas *obj


void
evas_image_cache_reload(obj)
	EvasCanvas *obj


void
evas_image_cache_flush(obj)
	EvasCanvas *obj


void
evas_norender(obj)
	EvasCanvas *obj


EvasObject *
evas_object_name_find(obj,name)
	const EvasCanvas *obj
	const char *name


# Eina_List *
# evas_objects_in_rectangle_get(obj,x,y,w,h,include_pass_events_objects,include_hidden_objects)
#	const Eo *obj
#	int x
#	int y
#	int w
#	int h
#	Eina_Bool include_pass_events_objects
#	Eina_Bool include_hidden_objects


Eina_List *
evas_objects_at_xy_get(eo_e,x,y,include_pass_events_objects,include_hidden_objects)
#	Eo *eo_e
    EvasCanvas *eo_e
    int x
	int y
	Eina_Bool include_pass_events_objects
	Eina_Bool include_hidden_objects


void
evas_obscured_clear(obj)
	EvasCanvas *obj


void
evas_obscured_rectangle_add(obj,x,y,w,h)
	EvasCanvas *obj
	int x
	int y
	int w
	int h


void
evas_output_method_set(e,render_method)
	EvasCanvas *e
	int render_method


int
evas_output_method_get(e)
	const EvasCanvas *e


int
evas_pointer_button_down_mask_get(obj)
	const EvasCanvas *obj


void
evas_pointer_canvas_xy_get(obj,OUTLIST x,OUTLIST y)
	const EvasCanvas *obj
	int x
	int y


Eina_Bool
evas_object_pointer_inside_get(obj)
	const EvasObject *obj


void
evas_pointer_output_xy_get(obj,OUTLIST x,OUTLIST y)
	const EvasCanvas *obj
	int x
	int y


void
evas_render(obj)
	EvasCanvas *obj


Eina_List *
evas_render_updates(obj)
	EvasCanvas *obj


EvasObject *
evas_object_top_at_pointer_get(e)
	const EvasCanvas *e


EvasObject*
evas_object_top_at_xy_get(eo_e,x,y,include_pass_events_objects,include_hidden_objects)
#	Eo *eo_e
    EvasCanvas *eo_e
    Evas_Coord x
	Evas_Coord y
	Eina_Bool include_pass_events_objects
	Eina_Bool include_hidden_objects


EvasObject *
evas_object_top_get(obj)
	const EvasCanvas *obj


EvasObject *
evas_object_top_in_rectangle_get(obj,x,y,w,h,include_pass_events_objects,include_hidden_objects)
#	const Eo *obj
    EvasCanvas *obj
    int x
	int y
	int w
	int h
	Eina_Bool include_pass_events_objects
	Eina_Bool include_hidden_objects


void
evas_output_size_set(e,w,h)
	EvasCanvas *e
	int w
	int h


void
evas_output_size_get(e,OUTLIST w,OUTLIST h)
	const EvasCanvas *e
	int w
	int h


void
evas_output_viewport_set(e,x,y,w,h)
	EvasCanvas *e
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
evas_output_viewport_get(e,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EvasCanvas *e
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


