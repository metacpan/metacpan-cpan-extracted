#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Scroller ElmScroller;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Scroller		PACKAGE = pEFL::Elm::Scroller

ElmScroller *
elm_scroller_add(EvasObject *parent)

MODULE = pEFL::Elm::Scroller		PACKAGE = ElmScrollerPtr     PREFIX = elm_scroller_


void
elm_scroller_content_min_limit(obj,w,h)
	ElmScroller *obj
	Eina_Bool w
	Eina_Bool h


void
elm_scroller_region_show(obj,x,y,w,h)
	ElmScroller *obj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
elm_scroller_policy_set(obj,policy_h,policy_v)
	ElmScroller *obj
	Elm_Scroller_Policy policy_h
	Elm_Scroller_Policy policy_v


void
elm_scroller_policy_get(obj,OUTLIST policy_h,OUTLIST policy_v)
	const ElmScroller *obj
	Elm_Scroller_Policy policy_h
	Elm_Scroller_Policy policy_v


void
elm_scroller_single_direction_set(obj,single_dir)
	ElmScroller *obj
	int single_dir


int
elm_scroller_single_direction_get(obj)
	const ElmScroller *obj


void
elm_scroller_region_get(obj,OUTLIST x, OUTLIST y,OUTLIST w,OUTLIST h)
	const ElmScroller *obj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
elm_scroller_child_size_get(obj,OUTLIST w,OUTLIST h)
	const ElmScroller *obj
	Evas_Coord w
	Evas_Coord h


void
elm_scroller_page_snap_set(obj,page_h_snap,page_v_snap)
	ElmScroller *obj
	Eina_Bool page_h_snap
	Eina_Bool page_v_snap


void
elm_scroller_page_snap_get(obj,OUTLIST page_h_snap,OUTLIST page_v_snap)
	const ElmScroller *obj
	Eina_Bool page_h_snap
	Eina_Bool page_v_snap


void
elm_scroller_bounce_set(obj,h_bounce,v_bounce)
	ElmScroller *obj
	Eina_Bool h_bounce
	Eina_Bool v_bounce


void
elm_scroller_bounce_get(obj,OUTLIST h_bounce,OUTLIST v_bounce)
	const ElmScroller *obj
	Eina_Bool h_bounce
	Eina_Bool v_bounce


void
elm_scroller_page_relative_set(obj,h_pagerel,v_pagerel)
	ElmScroller *obj
	double h_pagerel
	double v_pagerel


void
elm_scroller_page_relative_get(obj,OUTLIST h_pagerel,OUTLIST v_pagerel)
	const ElmScroller *obj
	double h_pagerel
	double v_pagerel


void
elm_scroller_page_size_set(obj,h_pagesize,v_pagesize)
	ElmScroller *obj
	Evas_Coord h_pagesize
	Evas_Coord v_pagesize


void
elm_scroller_page_size_get(obj,OUTLIST h_pagesize,OUTLIST v_pagesize)
	const ElmScroller *obj
	Evas_Coord h_pagesize
	Evas_Coord v_pagesize


void
elm_scroller_current_page_get(obj,OUTLIST h_pagenumber,OUTLIST v_pagenumber)
	const ElmScroller *obj
	int h_pagenumber
	int v_pagenumber


void
elm_scroller_last_page_get(obj,OUTLIST h_pagenumber,OUTLIST v_pagenumber)
	const ElmScroller *obj
	int h_pagenumber
	int v_pagenumber


void
elm_scroller_page_show(obj,h_pagenumber,v_pagenumber)
	ElmScroller *obj
	int h_pagenumber
	int v_pagenumber


void
elm_scroller_page_bring_in(obj,h_pagenumber,v_pagenumber)
	ElmScroller *obj
	int h_pagenumber
	int v_pagenumber


void
elm_scroller_region_bring_in(obj,x,y,w,h)
	ElmScroller *obj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
elm_scroller_gravity_set(obj,x,y)
	ElmScroller *obj
	double x
	double y


void
elm_scroller_gravity_get(obj,OUTLIST x,OUTLIST y)
	const ElmScroller *obj
	double x
	double y


void
elm_scroller_movement_block_set(obj,block)
	ElmScroller *obj
	int block


int
elm_scroller_movement_block_get(obj)
	const ElmScroller *obj


void
elm_scroller_step_size_set(obj,x,y)
	ElmScroller *obj
	Evas_Coord x
	Evas_Coord y


void
elm_scroller_step_size_get(obj,OUTLIST x,OUTLIST y)
	const ElmScroller *obj
	Evas_Coord x
	Evas_Coord y


void
elm_scroller_loop_set(obj,loop_h,loop_v)
	ElmScroller *obj
	Eina_Bool loop_h
	Eina_Bool loop_v


void
elm_scroller_loop_get(obj,OUTLIST loop_h,OUTLIST loop_v)
	const ElmScroller *obj
	Eina_Bool loop_h
	Eina_Bool loop_v


void
elm_scroller_wheel_disabled_set(obj,disabled)
	ElmScroller *obj
	Eina_Bool disabled


Eina_Bool
elm_scroller_wheel_disabled_get(obj)
	const ElmScroller *obj


void
elm_scroller_propagate_events_set(obj,propagation)
	ElmScroller *obj
	Eina_Bool propagation


Eina_Bool
elm_scroller_propagate_events_get(obj)
	const ElmScroller *obj

	
# DEPRECATED
# void
# elm_scroller_custom_widget_base_theme_set(obj,klass,group)
#	ElmScroller *obj
#	const char *klass
#	const char *group


void
elm_scroller_page_scroll_limit_set(obj,page_limit_h,page_limit_v)
	const ElmScroller *obj
	int page_limit_h
	int page_limit_v


void
elm_scroller_page_scroll_limit_get(obj,OUTLIST page_limit_h,OUTLIST page_limit_v)
	const ElmScroller *obj
	int page_limit_h
	int page_limit_v
