#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Emotion.h>

// We need this typedef to bless the created object into the class ElmWinPtr
// This class is a child class of pEFL::Elm::Win, which inherits from EvasObjectPtr
// see the @ISA's in Elm/Win.pm
// By this trick we get a wonderful perlish oo-interface :-)
typedef Evas_Object EmotionObject;
typedef Evas_Object EvasObject;
typedef Eo EvasCanvas;

MODULE = pEFL::Emotion::Object		PACKAGE = pEFL::Emotion::Object

EmotionObject * 
emotion_object_add(evas)
	EvasCanvas *evas


MODULE = pEFL::Emotion::Object		PACKAGE = pEFL::Emotion::Object    PREFIX = emotion_object_
 
 
Eina_Bool
emotion_object_extension_may_play_fast_get(file)
	const char *file


Eina_Bool
emotion_object_extension_may_play_get(file)
	const char *file


MODULE = pEFL::Emotion::Object		PACKAGE = EmotionObjectPtr     PREFIX = emotion_object_


Eina_Bool
emotion_object_file_set(obj,filename)
	EmotionObject *obj
	const char *filename

	
char *
emotion_object_file_get(obj)
	EmotionObject *obj
	
	
void
emotion_object_border_set(obj,l,r,t,b)
	EmotionObject *obj
	int l
	int r
	int t
	int b


void
emotion_object_border_get(obj, OUTLIST l, OUTLIST r, OUTLIST t, OUTLIST b)
	const EmotionObject *obj
	int l
	int r
	int t
	int b


void
emotion_object_bg_color_set(obj,r,g,b,a)
	EmotionObject *obj
	int r
	int g
	int b
	int a


void
emotion_object_bg_color_get(obj, OUTLIST r, OUTLIST g, OUTLIST b, OUTLIST a)
	const EmotionObject *obj
	int r
	int g
	int b
	int a


void
emotion_object_keep_aspect_set(obj,a)
	EmotionObject *obj
	int a


int
emotion_object_keep_aspect_get(obj)
	const EmotionObject *obj

###########
# Video control functions
###########

double
emotion_object_ratio_get(obj)
	const EmotionObject *obj


void
emotion_object_size_get(obj, OUTLIST iw, OUTLIST ih)
	const EmotionObject *obj
	int iw
	int ih


void
emotion_object_smooth_scale_set(obj, smooth_scale)
	EmotionObject *obj
	Eina_Bool smooth_scale

	
Eina_Bool
emotion_object_smooth_scale_get(obj)
	const EmotionObject *obj
	

void
emotion_object_video_mute_set(obj, mute)
	EmotionObject *obj
	Eina_Bool mute


Eina_Bool
emotion_object_video_mute_get(obj)
	const EmotionObject *obj


void
emotion_object_video_subtitle_file_set(obj, file)
	EmotionObject *obj
	char *file


char*
emotion_object_video_subtitle_file_get(obj)
	const EmotionObject *obj			

	
int
emotion_object_video_channel_count(obj)
	const EmotionObject *obj

		
char *
emotion_object_video_channel_name_get(obj,channel)
	const EmotionObject *obj
	int channel

void
emotion_object_video_channel_set(obj,channel)
	EmotionObject *obj
	int channel

	
int
emotion_object_video_channel_get(obj)
	EmotionObject *obj	
	
#############
# Audio control functions
#############

void
emotion_object_audio_volume_set(obj, vol)
	EmotionObject *obj
	double vol

double
emotion_object_audio_volume_get(obj)
	EmotionObject *obj


void
emotion_object_audio_mute_set(obj, mute)
	EmotionObject *obj
	Eina_Bool mute


Eina_Bool
emotion_object_audio_mute_get(obj)
	const EmotionObject *obj

	
#####################
# Play control functions
#####################	

void
emotion_object_play_set(obj,play)
	EmotionObject *obj
	Eina_Bool play


Eina_Bool
emotion_object_play_get(obj)
	const EmotionObject *obj


void
emotion_object_position_set(obj,sec)
	EmotionObject *obj
	double sec


double
emotion_object_position_get(obj)
	const EmotionObject *obj


double
emotion_object_buffer_size_get(obj)
	const EmotionObject *obj


Eina_Bool
emotion_object_seekable_get(obj)
	const EmotionObject *obj


double
emotion_object_play_length_get(obj)
	const EmotionObject *obj


void
emotion_object_play_speed_set(obj,speed)
	EmotionObject *obj
	double speed


double
emotion_object_play_speed_get(obj)
	const EmotionObject *obj	
	
const char *
emotion_object_progress_info_get(obj)
	const EmotionObject *obj
	

double
emotion_object_progress_status_get(obj)
	const EmotionObject *obj

#############
# Emotion Visialization
#############	

void
emotion_object_vis_set(obj,vis)
	EmotionObject *obj
	int vis

int
emotion_object_vis_get(obj)
	const EmotionObject *obj


Eina_Bool
emotion_object_vis_supported(obj,vis)
	const EmotionObject *obj
	int vis


################
# Information retrieval functions
#################

const char *
emotion_object_title_get(obj)
	EmotionObject *obj


const char *
emotion_object_meta_info_get(obj, meta)
	EmotionObject *obj
	int meta


void
emotion_object_last_position_load(obj)
	EmotionObject *obj


void
emotion_object_last_position_save(obj)
	EmotionObject *obj


##################
# Video ressource management
##################

void
emotion_object_priority_set(obj,priority)
	EmotionObject *obj
	Eina_Bool priority


Eina_Bool
emotion_object_priority_get(obj)
	const EmotionObject *obj


void
emotion_object_suspend_set(obj,state)
	EmotionObject *obj
	int state


int
emotion_object_suspend_get(obj)
	EmotionObject *obj


################
# Other functions
################


Eina_Bool
emotion_object_video_handled_get(obj)
	const EmotionObject *obj


Eina_Bool
emotion_object_audio_handled_get(obj)
	const EmotionObject *obj


void
emotion_object_event_simple_send(obj,ev)
	EmotionObject *obj
	int ev


int
emotion_object_audio_channel_count(obj)
	const EmotionObject *obj


const char*
emotion_object_audio_channel_name_get(obj, channel)
	const EmotionObject *obj
	int channel


void
emotion_object_audio_channel_set(obj, channel)
	EmotionObject *obj
	int channel
	
	
int
emotion_object_audio_channel_get(obj)
	const EmotionObject *obj


void
emotion_object_spu_mute_set(obj, mute)
	EmotionObject *obj
	Eina_Bool mute	


Eina_Bool
emotion_object_spu_mute_get(obj)
	const EmotionObject *obj

int
emotion_object_spu_channel_count(obj)
	const EmotionObject *obj


const char*
emotion_object_spu_channel_name_get(obj, channel)
	const EmotionObject *obj
	int channel


void
emotion_object_spu_channel_set(obj, channel)
	EmotionObject *obj
	int channel
	
	
int
emotion_object_spu_channel_get(obj)
	const EmotionObject *obj


int
emotion_object_chapter_count(obj)
	const EmotionObject *obj


const char*
emotion_object_chapter_name_get(obj, chapter)
	const EmotionObject *obj
	int chapter


void
emotion_object_chapter_set(obj, chapter)
	EmotionObject *obj
	int chapter
	
	
int
emotion_object_chapter_get(obj)
	const EmotionObject *obj


void
emotion_object_eject(obj)
	EmotionObject *obj


const char *
emotion_object_ref_file_get(obj)
	const EmotionObject *obj


int
emotion_object_ref_num_get(obj)
	const EmotionObject *obj


int
emotion_object_spu_button_count_get(obj)
	const EmotionObject *obj


int
emotion_object_spu_button_get(obj)
	const EmotionObject *obj


# Which type has EvasObject?
EvasObject *
emotion_object_image_get(obj)
	const EmotionObject *obj


EvasObject *
emotion_file_meta_artwork_get(obj,path,type)
	const EmotionObject *obj
	const char *path
	int type
	

#EinaList *
#emotion_webcams_get()
	 

# TODO: EmotionWebcam
#char *
#emotion_webcam_name_get(ew)
#	const EmotionWebcam *ew


#char *
#emotion_webcam_device_get(ew)
#	const EmotionWebcam *ew




##################
# efl_canvas_video_eo.legacy.h
# ob is of type Efl_Canvas_Video * in the following methods
##################
void 
emotion_object_module_option_set(obj, opt, val)
	EmotionObject *obj
	const char *opt
	const char *val
	

Eina_Bool 
emotion_object_init(obj, module_filename)
	EmotionObject *obj 
	const char *module_filename