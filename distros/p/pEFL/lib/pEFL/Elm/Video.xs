#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmVideo;
typedef Evas_Object EvasObject;
typedef Evas_Object EmotionObject;

MODULE = pEFL::Elm::Video		PACKAGE = pEFL::Elm::Video

ElmVideo * 
elm_video_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Video		PACKAGE = ElmVideoPtr     PREFIX = elm_video_


Eina_Bool
elm_video_file_set(obj,filename)
	ElmVideo *obj
	const char *filename


void
elm_video_file_get(obj,OUTLIST filename)
	ElmVideo *obj
	const char *filename


void
elm_video_audio_level_set(obj,volume)
	ElmVideo *obj
	double volume


double
elm_video_audio_level_get(obj)
	const ElmVideo *obj


void
elm_video_audio_mute_set(obj,mute)
	ElmVideo *obj
	Eina_Bool mute


Eina_Bool
elm_video_audio_mute_get(obj)
	const ElmVideo *obj


double
elm_video_play_length_get(obj)
	const ElmVideo *obj


Eina_Bool
elm_video_is_seekable_get(obj)
	const ElmVideo *obj


void
elm_video_play_position_set(obj,position)
	ElmVideo *obj
	double position


double
elm_video_play_position_get(obj)
	const ElmVideo *obj


Eina_Bool
elm_video_is_playing_get(obj)
	ElmVideo *obj


void
elm_video_play(obj)
	ElmVideo *obj


void
elm_video_stop(obj)
	ElmVideo *obj


void
elm_video_pause(obj)
	ElmVideo *obj


void
elm_video_remember_position_set(obj,remember)
	ElmVideo *obj
	Eina_Bool remember


Eina_Bool
elm_video_remember_position_get(obj)
	const ElmVideo *obj


EmotionObject *
elm_video_emotion_get(obj)
	const ElmVideo *obj


char *
elm_video_title_get(obj)
	const ElmVideo *obj