#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Image EvasImage;


MODULE = pEFL::Evas::Image		PACKAGE = pEFL::Evas::Image

EvasImage *
evas_object_image_add(e)
	EvasCanvas *e
	

EvasImage *
evas_object_image_filled_add(e)
	EvasCanvas *e
	

MODULE = pEFL::Evas::Image		PACKAGE = EvasImagePtr     PREFIX = evas_object_image_


# void
# evas_object_image_memfile_set(obj,data,size,format,key)
#	EvasImage *obj
#	void *data
#	int size
#	char *format
#	char *key


# void
# evas_object_image_native_surface_set(obj,surf)
#	EvasImage *obj
#	Evas_Native_Surface *surf


# Evas_Native_Surface *
# evas_object_image_native_surface_get(obj)
#	const EvasImage *obj


void
evas_object_image_preload(obj,cancel)
	EvasImage *obj
	Eina_Bool cancel


Eina_Bool
evas_object_image_source_unset(obj)
	EvasImage *obj


void
evas_object_image_file_set(obj,file,key)
#	Eo *obj
    EvasImage *obj
	const char *file
	const char *key


void
evas_object_image_file_get(obj,OUTLIST file,OUTLIST key)
#	Eo *obj
    EvasImage *obj
	const char *file
	const char *key


# void
# evas_object_image_mmap_set(obj,f,key)
#	Eo *obj
#	const Eina_File *f
#	const char *key


# void
# evas_object_image_mmap_get(obj,*f,*key)
#	const Eo *obj
#	const Eina_File **f
#	const char **key


Eina_Bool
evas_object_image_save(obj,file,key,flags)
#	const Eo *obj
    const EvasImage *obj
	const char *file
	const char *key
	const char *flags


Eina_Bool
evas_object_image_animated_get(obj)
#	const Eo *obj
    const EvasImage *obj


void
evas_object_image_animated_frame_set(obj,frame_index)
	EvasImage *obj
	int frame_index


int
evas_object_image_animated_frame_get(obj)
	EvasImage *obj


int
evas_object_image_animated_frame_count_get(obj)
	const EvasImage *obj


# Evas_Image_Animated_Loop_Hint
# evas_object_image_animated_loop_type_get(obj)
#	const EvasImage *obj


int
evas_object_image_animated_loop_count_get(obj)
	const EvasImage *obj


double
evas_object_image_animated_frame_duration_get(obj,start_frame,frame_num)
	const EvasImage *obj
	int start_frame
	int frame_num


void
evas_object_image_load_dpi_set(obj,dpi)
	EvasImage *obj
	double dpi


double
evas_object_image_load_dpi_get(obj)
	const EvasImage *obj


void
evas_object_image_load_size_set(obj,w,h)
#	Eo *obj
    EvasImage *obj
	int w
	int h


void
evas_object_image_load_size_get(obj,OUTLIST w,OUTLIST h)
#	const Eo *obj
    const EvasImage *obj
	int w
	int h


void
evas_object_image_load_region_set(obj,x,y,w,h)
	EvasImage *obj
	int x
	int y
	int w
	int h


void
evas_object_image_load_region_get(obj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EvasImage *obj
	int x
	int y
	int w
	int h


Eina_Bool
evas_object_image_region_support_get(obj)
	const EvasImage *obj


void
evas_object_image_load_orientation_set(obj,enable)
	EvasImage *obj
	Eina_Bool enable


Eina_Bool
evas_object_image_load_orientation_get(obj)
	const EvasImage *obj


void
evas_object_image_load_scale_down_set(obj,scale_down)
	EvasImage *obj
	int scale_down


int
evas_object_image_load_scale_down_get(obj)
	const EvasImage *obj


void
evas_object_image_load_head_skip_set(obj,skip)
	EvasImage *obj
	Eina_Bool skip


Eina_Bool
evas_object_image_load_head_skip_get(obj)
	const EvasImage *obj


int
evas_object_image_load_error_get(obj)
	const EvasImage *obj


void
evas_object_image_smooth_scale_set(obj,smooth_scale)
#	Eo *obj
    EvasImage *obj
	Eina_Bool smooth_scale


Eina_Bool
evas_object_image_smooth_scale_get(obj)
#	const Eo *obj
    const EvasImage *obj


void
evas_object_image_fill_set(obj,x,y,w,h)
	EvasImage *obj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
evas_object_image_fill_get(obj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const EvasImage *obj
	Evas_Coord x
	Evas_Coord y
	Evas_Coord w
	Evas_Coord h


void
evas_object_image_filled_set(obj,filled)
	EvasImage *obj
	Eina_Bool filled


Eina_Bool
evas_object_image_filled_get(obj)
	const EvasImage *obj


Eina_Bool
evas_object_image_alpha_get(obj)
	const EvasImage *obj


void
evas_object_image_alpha_set(obj,alpha)
	EvasImage *obj
	Eina_Bool alpha


void
evas_object_image_border_set(obj,l,r,t,b)
	EvasImage *obj
	int l
	int r
	int t
	int b


void
evas_object_image_border_get(obj,OUTLIST l,OUTLIST r,OUTLIST t,OUTLIST b)
	const EvasImage *obj
	int l
	int r
	int t
	int b


void
evas_object_image_border_scale_set(obj,scale)
	EvasImage *obj
	double scale


double
evas_object_image_border_scale_get(obj)
	const EvasImage *obj


void
evas_object_image_border_center_fill_set(obj,fill)
	EvasImage *obj
	int fill


int
evas_object_image_border_center_fill_get(obj)
	const EvasImage *obj


void
evas_object_image_orient_set(obj,orient)
	EvasImage *obj
	int orient


int
evas_object_image_orient_get(obj)
	const EvasImage *obj


void
evas_object_image_content_hint_set(obj,hint)
	EvasImage *obj
	int hint


int
evas_object_image_content_hint_get(obj)
	const EvasImage *obj


void
evas_object_image_scale_hint_set(obj,hint)
	EvasImage *obj
	int hint


int
evas_object_image_scale_hint_get(obj)
	const EvasImage *obj


void
evas_object_image_size_set(obj,w,h)
	EvasImage *obj
	int w
	int h


void
evas_object_image_size_get(obj,OUTLIST w,OUTLIST h)
	const EvasImage *obj
	int w
	int h


void
evas_object_image_colorspace_set(obj,cspace)
	EvasImage *obj
	int cspace


int
evas_object_image_colorspace_get(obj)
	const EvasImage *obj


int
evas_object_image_stride_get(obj)
	const EvasImage *obj


# void
# evas_object_image_data_copy_set(obj,data)
#	EvasImage *obj
#	void *data


# void
# evas_object_image_data_set(obj,data)
#	EvasImage *obj
#	void *data


# void *
# evas_object_image_data_get(obj,for_writing)
#	const EvasImage *obj
#	Eina_Bool for_writing


void
evas_object_image_data_update_add(obj,x,y,w,h)
	EvasImage *obj
	int x
	int y
	int w
	int h


void
evas_object_image_snapshot_set(obj,s)
	EvasImage *obj
	Eina_Bool s


Eina_Bool
evas_object_image_snapshot_get(obj)
	const EvasImage *obj


Eina_Bool
evas_object_image_source_set(obj,src)
	EvasImage *obj
	EvasImage *src


EvasImage *
evas_object_image_source_get(obj)
	const EvasImage *obj


void
evas_object_image_source_clip_set(obj,source_clip)
	EvasImage *obj
	Eina_Bool source_clip


Eina_Bool
evas_object_image_source_clip_get(obj)
	const EvasImage *obj


void
evas_object_image_source_events_set(obj,repeat)
	EvasImage *obj
	Eina_Bool repeat


Eina_Bool
evas_object_image_source_events_get(obj)
	const EvasImage *obj


void
evas_object_image_source_visible_set(obj,visible)
	EvasImage *obj
	Eina_Bool visible


Eina_Bool
evas_object_image_source_visible_get(obj)
	const EvasImage *obj


void
evas_object_image_pixels_dirty_set(obj,dirty)
	EvasImage *obj
	Eina_Bool dirty


Eina_Bool
evas_object_image_pixels_dirty_get(obj)
	const EvasImage *obj


# void
# evas_object_image_pixels_get_callback_set(obj,func,data)
#	EvasImage *obj
#	EvasImage_Image_Pixels_Get_Cb func
#	void *data


# void
# evas_object_image_video_surface_set(obj,surf)
#	EvasImage *obj
#	Evas_Video_Surface *surf


# Evas_Video_Surface *
# evas_object_image_video_surface_get(obj)
#	const EvasImage *obj


void
evas_object_image_video_surface_caps_set(obj,caps)
	EvasImage *obj
	unsigned int caps


int
evas_object_image_video_surface_caps_get(obj)
	const EvasImage *obj


