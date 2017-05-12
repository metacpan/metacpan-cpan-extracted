#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <xine.h>

typedef void Display;
typedef unsigned long Window;

typedef struct {
  int width;
  int height;
  double aspect;
} user_data_t;

static void unscaled_dest_size_cb (void *user_data,
			int video_width, 
			int video_height,
			double video_pixel_aspect,
			int *dest_width, int *dest_height,
			double *dest_pixel_aspect) 
{
	user_data_t* ud;
	ud = (user_data_t *) user_data;
	*dest_width = ud->width;
	*dest_height = ud->height;
	*dest_pixel_aspect = ud->aspect;

}

static void unscaled_frame_output_cb (void *user_data,
			   int video_width, int video_height,
			   double video_pixel_aspect,
			   int *dest_x, int *dest_y,
			   int *dest_width, int *dest_height,
			   double *dest_pixel_aspect,
			   int *win_x, int *win_y) {
	user_data_t* ud;

	*dest_x = 0;
	*dest_y = 0;
	*win_x = 0;
	*win_y = 0;
	ud = (user_data_t *) user_data;
	*dest_width = ud->width;
	*dest_height = ud->height;
	*dest_pixel_aspect = ud->aspect;

	
	
}





MODULE = Video::Xine		PACKAGE = Video::Xine

#
# Get the version for Xine
#
void
xine_get_version(major, minor, sub)
	int &major = NO_INIT
	int &minor = NO_INIT
	int &sub = NO_INIT
    OUTPUT:
	major
	minor
	sub

#
# Return 1 if the xine version is compatible
#
int
xine_check_version (major, minor, sub)
	int major
	int minor
	int sub

#
# Pre-init the xine engine. Need to call xine_init()
# afterwards.
#
xine_t *
xine_new()
    CODE:
	{
	  RETVAL = xine_new();
          if (RETVAL == NULL) {
             XSRETURN_UNDEF;
          }
        }
    OUTPUT:
	RETVAL


#
# Post-init the xine engine. Call after xine_new() and configuration.
# 
void
xine_init(self)
	xine_t *self

#
# Shut down and clean up xine.
#
void
xine_exit(self)
	xine_t *self

#
# Set a parameter on the Xine engine.
#
void
xine_engine_set_param(self,param,value)
	xine_t *self
	int param
	int value


#
# Load a file into the config system
#
void
xine_config_load(self, cfg_filename)
	xine_t *self
	const char *cfg_filename


MODULE = Video::Xine		PACKAGE = Video::Xine::Stream

#
# Create a new Xine stream.
#
xine_stream_t *
xine_stream_new(xine,ao,vo)
	xine_t *xine
	xine_audio_port_t *ao
	xine_video_port_t *vo
    CODE:
	RETVAL = xine_stream_new(xine,ao,vo);
        if (RETVAL == NULL) {
           XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

##
## Establish a master-slave relationship
##
int xine_stream_master_slave(self, slave, affection)
	xine_stream_t *self
	xine_stream_t *slave
    int affection


##
## Opens a xine mrl on an existing stream.
##
int
xine_open(stream,mrl)
	xine_stream_t *stream
	const char *mrl

##
## Play the stream
##
int
xine_play(stream, ...)
	xine_stream_t *stream
    PREINIT:
	int start_pos;
	int start_time;

    CODE:
	if (items >= 2 && SvOK(ST(1)) ) {
	   start_pos = SvIV(ST(1));
	}
        else {
           start_pos = 0;
        }
        if (items >= 3 && SvOK(ST(2)) ) {
           start_time = SvIV(ST(2));
        }
        else {
           start_time = 0;
        }
        RETVAL = xine_play(stream, start_pos, start_time);
	if (RETVAL == 0) {
	    XSRETURN_UNDEF;
	}

    OUTPUT:
        RETVAL

##
## Stop playing
##
void
xine_stop(self)
	xine_stream_t *self

##
## Close MRL; stream can be reused
##
void
xine_close(self)
	xine_stream_t *self


#
# Eject
#
int  xine_eject (self) 
	xine_stream_t *self

#
# Get the stream position and length
#
int
xine_get_pos_length(self, pos_stream, pos_time, length_time)
	xine_stream_t* self
	int &pos_stream
	int &pos_time
	int &length_time
	OUTPUT:
		RETVAL
		pos_stream
		pos_time
		length_time


#
# Get the playback status
#
int
xine_get_status(self)
	xine_stream_t *self


#
# Get error code for the stream
#
int
xine_get_error(self)
	xine_stream_t *self

#
# Get a stream param
#
int
xine_get_param(self, param)
	xine_stream_t *self
        int param;


#
# Set a stream param
#
void
xine_set_param(self, param, value)
	xine_stream_t *self
        int param;
        int value;

#
# Get stream information
#
U32
xine_get_stream_info(stream,info)
	xine_stream_t *stream
	int info

#
# Get stream metainformation
#
const char *
xine_get_meta_info(stream,info)
	xine_stream_t *stream
	int info


# Destroy all monsters
void
xine_dispose(self)
	xine_stream_t *self




MODULE = Video::Xine		PACKAGE = Video::Xine::Driver::Audio

##
## Open an audio driver for this Xine player.
##
xine_audio_port_t *
xine_open_audio_driver(self,id=NULL,data=NULL)
	xine_t *self
	const char *id
	void *data

##
## Close an opened audio driver
##
void
xine_close_audio_driver(xine,driver)
	xine_t *xine
	xine_audio_port_t *driver

MODULE = Video::Xine        PACKAGE = Video::Xine::Driver::Video

##
## Open a video driver for this Xine player.
##
xine_video_port_t *
xine_open_video_driver(self,id=NULL,visual=XINE_VISUAL_TYPE_NONE,data=NULL)
	xine_t *self
	const char *id
	int visual
	x11_visual_t *data


##
## Close a video driver
##
void
xine_close_video_driver(xine,driver)
	xine_t *xine
	xine_video_port_t *driver

##
## Send a GUI event to the video port
##
int
xine_port_send_gui_data (vo,type,data)
	xine_video_port_t *vo
	int type
	void *data


MODULE = Video::Xine        PACKAGE = Video::Xine::Util

##
## Create an X11 visual
##
x11_visual_t *
make_x11_visual(display,screen,window,width,height,aspect)
	Display *display
	int screen
	Window window
	int width
	int height
	double aspect
	PREINIT:
		user_data_t * userdata;
	CODE:
		userdata = (user_data_t*) safemalloc( sizeof(user_data_t) );
		userdata->width = width;
		userdata->height = height;
		userdata->aspect = aspect;
		RETVAL = (x11_visual_t*) safemalloc( sizeof(x11_visual_t) );
		RETVAL->user_data = (void*) userdata;
		RETVAL->display = display;
		RETVAL->screen = screen;
		RETVAL->d = window;
		RETVAL->frame_output_cb = unscaled_frame_output_cb;
		RETVAL->dest_size_cb = unscaled_dest_size_cb;
	OUTPUT:
		RETVAL

##
## Get the display from the struct
##
Display *
get_display(visual)
	x11_visual_t *visual
	CODE:
		RETVAL = visual->display;
	OUTPUT:
		RETVAL


MODULE = Video::Xine	PACKAGE = Video::Xine::Event

int
xine_event_get_type(event)
	xine_event_t *event
	CODE:
		RETVAL = event->type;
	OUTPUT:
		RETVAL

void
xine_event_free(event)
	xine_event_t *event


MODULE = Video::Xine	PACKAGE = Video::Xine::Event::Queue

xine_event_queue_t *
xine_event_new_queue(stream)
	xine_stream_t *stream
	POSTCALL:
		if (RETVAL == NULL) {
			XSRETURN_UNDEF;
		}
	
xine_event_t *
xine_event_get(queue)
	xine_event_queue_t *queue
	POSTCALL:
		if (! RETVAL) {
			XSRETURN_UNDEF;
		}

xine_event_t *
xine_event_wait(queue)
	xine_event_queue_t *queue

void
xine_event_dispose_queue(queue)
	xine_event_queue_t *queue
	

MODULE = Video::Xine  PACKAGE = Video::Xine::OSD

xine_osd_t *
xine_osd_new(xine,x,y,width,height)
	xine_stream_t *xine
	int x
	int y
	int width
	int height

void
xine_osd_free(osd)
	xine_osd_t *osd

void
xine_osd_draw_text(osd,x1,y1,text,color_base)
	xine_osd_t *osd
	int x1
	int y1
	const char *text
	int color_base

void
xine_osd_show(osd,vpts)
	xine_osd_t *osd
	int vpts

void
xine_osd_hide(osd,vpts)
	xine_osd_t *osd
	int vpts

int
xine_osd_set_font(osd,fontname,size)
	xine_osd_t *osd
	const char *fontname
	int size

void
xine_osd_clear(osd)
	xine_osd_t *osd

U32
xine_osd_get_capabilities(osd)
	xine_osd_t *osd
