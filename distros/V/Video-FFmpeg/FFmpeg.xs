#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <avformat.h>
#include <pthread.h> 
pthread_mutex_t AVFormatCtxMP; 

typedef struct AVFormatContext Video_FFmpeg_AVFormat;
typedef struct AVStream Video_FFmpeg_AVStream;
typedef struct AVStream Video_FFmpeg_AVStream_Audio;
typedef struct AVStream Video_FFmpeg_AVStream_Subtitle;
typedef struct AVStream Video_FFmpeg_AVStream_Video;

char* get_metadata(AVStream *st, const char* tag){
#if (LIBAVFORMAT_VERSION_MINOR > 44) || (LIBAVFORMAT_VERSION_MAJOR > 52)
    AVMetadataTag *tagdata = av_metadata_get(st->metadata, tag, NULL, 0);
    return tagdata->value;
#else
	croak("Metadata requires libavformat 52.44 or greater\n");
#endif
}

char* get_lang(AVStream *st){
#if (LIBAVFORMAT_VERSION_MINOR > 44) || (LIBAVFORMAT_VERSION_MAJOR > 52)
    AVMetadataTag *lang = av_metadata_get(st->metadata, "language", NULL, 0);
    return lang->value;
#else
	return st->language;
#endif
}


MODULE = Video::FFmpeg		PACKAGE = Video::FFmpeg

BOOT:
	av_register_all();
	pthread_mutex_init(&AVFormatCtxMP, NULL);

MODULE = Video::FFmpeg		PACKAGE = Video::FFmpeg::AVFormat

Video_FFmpeg_AVFormat *
open(char *file);
    CODE:
        Video_FFmpeg_AVFormat *pFormatCtx;
		int lock;
	
		lock = pthread_mutex_lock(&AVFormatCtxMP);
		if(lock != 0){
			croak("Unable to lock mutex AVFormatCtxMP while opening %s",file);
		};

        if(av_open_input_file(&pFormatCtx, file, NULL, 0, NULL)!=0)
            RETVAL = NULL; // Couldn't open file
        if(av_find_stream_info(pFormatCtx)<0)
            RETVAL = NULL; // Couldn't find stream information

		lock = pthread_mutex_unlock(&AVFormatCtxMP);
		if(lock != 0){
			croak("Unable to unlock mutex AVFormatCtxMP while opening %s",file);
		};

        RETVAL = pFormatCtx;
    OUTPUT:
        RETVAL

void
DESTROY(Video_FFmpeg_AVFormat *ctx);
	CODE:
		av_close_input_file(ctx);

char *
filename(Video_FFmpeg_AVFormat *self);
	CODE:
		RETVAL = self->filename;
	OUTPUT:
		RETVAL

int
nb_streams(Video_FFmpeg_AVFormat *self)
	CODE:
		RETVAL = self->nb_streams;
	OUTPUT:
		RETVAL

Video_FFmpeg_AVStream_Video *
get_video_stream(Video_FFmpeg_AVFormat *self, int id)
	CODE:
		if(CODEC_TYPE_VIDEO == self->streams[id]->codec->codec_type)
			RETVAL = self->streams[id];
		else
			RETVAL = NULL;
	OUTPUT: RETVAL

Video_FFmpeg_AVStream_Audio *
get_audio_stream(Video_FFmpeg_AVFormat *self, int id)
	CODE:
		if(CODEC_TYPE_AUDIO == self->streams[id]->codec->codec_type)
			RETVAL = self->streams[id];
		else
			RETVAL = NULL;
	OUTPUT: RETVAL

Video_FFmpeg_AVStream *
get_stream(Video_FFmpeg_AVFormat *self, int id)
	CODE:
		RETVAL = self->streams[id];
	OUTPUT: RETVAL

SV *
duration_us(Video_FFmpeg_AVFormat *self)
	CODE:
		RETVAL = newSVpvf("%i",(self->duration*1000000)/AV_TIME_BASE);
	OUTPUT:
		RETVAL

SV *
duration(Video_FFmpeg_AVFormat *self)
	CODE:
		int hours, mins, secs, us;
		secs = self->duration / AV_TIME_BASE;
		us = self->duration % AV_TIME_BASE;
		mins = secs / 60;
		secs %= 60;
		hours = mins / 60;
		mins %= 60;
		RETVAL = newSVpvf("%02d:%02d:%02d.%03d", hours, mins, secs, (1000 * us)/AV_TIME_BASE);
	OUTPUT:
		RETVAL

SV *
start_time(Video_FFmpeg_AVFormat *self)
	CODE:
		RETVAL = newSVpvf("%i",self->start_time);
	OUTPUT:
		RETVAL

int
bit_rate(Video_FFmpeg_AVFormat *self)
	CODE:
		RETVAL = self->bit_rate;
	OUTPUT:
		RETVAL

MODULE = Video::FFmpeg		PACKAGE = Video::FFmpeg::AVStream

char *
codec(Video_FFmpeg_AVStream *st);
	CODE:
		AVCodec *p;
		char buf[16];
		p = avcodec_find_decoder(st->codec->codec_id);

		if (p) {
			RETVAL = p->name;
		} else if (st->codec->codec_id == CODEC_ID_MPEG2TS) {
			/* fake mpeg2 transport stream codec (currently not
				registered) */
			RETVAL = "mpeg2ts";
		} else if (st->codec->codec_name[0] != '\0') {
			RETVAL = st->codec->codec_name;
		} else {
			/* output avi tags */
			snprintf(buf, sizeof(buf), "0x%04x", st->codec->codec_tag);
			RETVAL = buf;
		}

	OUTPUT:
		RETVAL


char *
codec_type(Video_FFmpeg_AVStream *st);
	CODE:
		switch(st->codec->codec_type){
			case CODEC_TYPE_VIDEO:
				RETVAL = "video";
				break;
			case CODEC_TYPE_AUDIO:
				RETVAL = "audio";
				break;
			case CODEC_TYPE_SUBTITLE:
				RETVAL = "subtitle";
				break;
			case CODEC_TYPE_DATA:
				RETVAL = "data";
				break;
			case CODEC_TYPE_ATTACHMENT:
				RETVAL = "attachment";
				break;
			default:
				RETVAL = "unknown";
				break;
		}
	OUTPUT:
		RETVAL

char *
lang(Video_FFmpeg_AVStream *st);
	CODE:
		//Requires libavformat 
		RETVAL = get_lang(st);
	OUTPUT:
		RETVAL


MODULE = Video::FFmpeg		PACKAGE = Video::FFmpeg::AVStream::Audio

int
bit_rate(Video_FFmpeg_AVStream_Audio *st);
	CODE:
		int bits_per_sample;
			bits_per_sample = av_get_bits_per_sample(st->codec->codec_id);
		if(bits_per_sample)
			RETVAL = st->codec->sample_rate*st->codec->channels*bits_per_sample;
		else
			RETVAL = st->codec->bit_rate;
	OUTPUT:
		RETVAL

int
sample_rate(Video_FFmpeg_AVStream_Audio *st);
	CODE:
		RETVAL = st->codec->sample_rate;
	OUTPUT:
		RETVAL

int
channels(Video_FFmpeg_AVStream_Audio *st);
	CODE:
		RETVAL = st->codec->channels;
	OUTPUT:
		RETVAL

MODULE = Video::FFmpeg		PACKAGE = Video::FFmpeg::AVStream::Video

int
width(Video_FFmpeg_AVStream_Video *st);
	CODE:
		RETVAL = st->codec->width;
	OUTPUT:
		RETVAL

int
height(Video_FFmpeg_AVStream_Video *st);
	CODE:
		RETVAL = st->codec->height;
	OUTPUT:
		RETVAL

float
fps(Video_FFmpeg_AVStream_Video *st);
	CODE:
		RETVAL = st->r_frame_rate.num/(float)st->r_frame_rate.den;

	OUTPUT:
		RETVAL

char *
display_aspect(Video_FFmpeg_AVStream_Video *st);
	CODE:
		AVRational display_aspect_ratio;
		char buf[10];
		
		if(st->codec->sample_aspect_ratio.num){
			av_reduce(&display_aspect_ratio.num, &display_aspect_ratio.den,
				st->codec->width*st->codec->sample_aspect_ratio.num,
				st->codec->height*st->codec->sample_aspect_ratio.den,
				1024*1024);
		} else {
			av_reduce(&display_aspect_ratio.num, &display_aspect_ratio.den,
				st->codec->width,
				st->codec->height,
				1024*1024);
		}
			
		snprintf(buf, 10, "%i:%i",
			display_aspect_ratio.num,
			display_aspect_ratio.den);
		RETVAL = buf;

	OUTPUT:
		RETVAL

SV *
pixel_aspect(Video_FFmpeg_AVStream_Video *st);
	CODE:
		if(st->codec->sample_aspect_ratio.num){
			RETVAL = newSVpvf("%i:%i",
				st->codec->sample_aspect_ratio.num,
				st->codec->sample_aspect_ratio.den);
		} else {
			RETVAL = &PL_sv_undef;
		}

	OUTPUT:
		RETVAL


#INCLUDE: ./version_check.sh Metadata 52.44 |
