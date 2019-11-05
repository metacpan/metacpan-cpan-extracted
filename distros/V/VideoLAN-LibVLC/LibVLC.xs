#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include <vlc/vlc.h>
#include <vlc/libvlc_version.h>

#include "PerlVLC.h"

MODULE = VideoLAN::LibVLC              PACKAGE = VideoLAN::LibVLC

libvlc_instance_t*
libvlc_new(args)
	AV* args
	INIT:
		int argc, i;
		SV **ep;
		const char **argv;
	CODE:
		argc= av_len(args)+1;
		argv= alloca(sizeof(char*) * (argc + 1));
		if (!argv) croak("alloca failed");
		for (i= 0; i < argc; i++) {
			ep= av_fetch(args, i, 0);
			argv[i]= (ep && *ep && SvOK(*ep))? SvPV_nolen(*ep) : "";
		}
		argv[argc]= NULL;
		RETVAL= libvlc_new(argc, argv);
		if (!RETVAL)
			croak("libvlc_new failed");
	OUTPUT:
		RETVAL

const char*
libvlc_get_changeset()

const char*
libvlc_get_compiler()

const char*
libvlc_get_version()

void
libvlc_set_app_id(vlc, id, version, icon)
	libvlc_instance_t *vlc
	const char *id
	const char *version
	const char *icon

void
libvlc_set_user_agent(vlc, name, http)
	libvlc_instance_t *vlc
	const char *name
	const char *http

void
libvlc_audio_filter_list_get(vlc)
	libvlc_instance_t *vlc
	INIT:
		libvlc_module_description_t *mlist, *mcur;
		HV *elem;
	PPCODE:
		for (mcur= mlist= libvlc_audio_filter_list_get(vlc); mcur; mcur= mcur->p_next) {
			elem= newHV();
			hv_store(elem, "name",      4, newSVpv(mcur->psz_name, 0), 0);
			hv_store(elem, "shortname", 9, newSVpv(mcur->psz_shortname, 0), 0);
			hv_store(elem, "longname",  8, newSVpv(mcur->psz_longname, 0), 0);
			hv_store(elem, "help",      4, newSVpv(mcur->psz_help, 0), 0);
			PUSHs(newRV_noinc((SV*)elem));
		}
		libvlc_module_description_list_release(mlist);

void
libvlc_video_filter_list_get(vlc)
	libvlc_instance_t *vlc
	INIT:
		libvlc_module_description_t *mlist, *mcur;
		HV *elem;
	PPCODE:
		for (mcur= mlist= libvlc_video_filter_list_get(vlc); mcur; mcur= mcur->p_next) {
			elem= newHV();
			hv_store(elem, "name",      4, newSVpv(mcur->psz_name, 0), 0);
			hv_store(elem, "shortname", 9, newSVpv(mcur->psz_shortname, 0), 0);
			hv_store(elem, "longname",  8, newSVpv(mcur->psz_longname, 0), 0);
			hv_store(elem, "help",      4, newSVpv(mcur->psz_help, 0), 0);
			PUSHs(newRV_noinc((SV*)elem));
		}
		libvlc_module_description_list_release(mlist);

void
_set_event_pipe(vlc, read_fd, write_fd)
	PerlVLC_vlc_t *vlc
	int read_fd
	int write_fd
	PPCODE:
		vlc->event_pipe[0]= read_fd;
		vlc->event_pipe[1]= write_fd;

SV *
_recv_event(vlc)
	PerlVLC_vlc_t *vlc
	INIT:
		int got;
		char buf[PERLVLC_MSG_BUFFER_SIZE];
	CODE:
		got= recv(vlc->event_pipe[0], buf, sizeof(buf), 0);
		RETVAL= (got > 0)? PerlVLC_inflate_message(buf, got) : &PL_sv_undef;
	OUTPUT:
		RETVAL

SV *
_inflate_message(vlc, buffer)
	PerlVLC_vlc_t *vlc
	SV *buffer;
	INIT:
		STRLEN len;
		char *buf;
	CODE:
		buf= SvPV(buffer, len);
		RETVAL= PerlVLC_inflate_message(buffer, len);
	OUTPUT:
		RETVAL

#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20100)

void
_libvlc_log_set(vlc, callback_id, level, fields)
	PerlVLC_vlc_t *vlc
	int callback_id
	int level
	AV *fields
	INIT:
		int i;
		char *s;
		SV **item;
	PPCODE:
		if (vlc->event_pipe[1] < 0)
			croak("Event pipe must be initialized first");
		vlc->log_level= level;
		vlc->log_module= vlc->log_file= vlc->log_line= vlc->log_name= vlc->log_header= vlc->log_objid= 0;
		for (i= 0; i < 1+av_len(fields); i++) {
			if (!(item= av_fetch(fields, i, 0)) || !*item || !SvOK(*item))
				croak("Invalid field spec at [%d]", i);
			s= SvPV_nolen(*item);
			if (*s == '*' && !s[1]) {
				vlc->log_module= vlc->log_file= vlc->log_line= vlc->log_name= vlc->log_header= vlc->log_objid= 1;
			}
			else if (0 == strcmp(s, "module")) vlc->log_module= 1;
			else if (0 == strcmp(s, "file")) vlc->log_file= 1;
			else if (0 == strcmp(s, "line")) vlc->log_line= 1;
			else if (0 == strcmp(s, "name")) vlc->log_name= 1;
			else if (0 == strcmp(s, "header")) vlc->log_header= 1;
			else if (0 == strcmp(s, "objid")) vlc->log_objid= 1;
			else warn("No such logging field %s", s);
		}
		PerlVLC_set_log_cb(vlc, callback_id);

void
libvlc_log_unset(vlc)
	libvlc_instance_t *vlc

#endif

libvlc_media_t *
libvlc_media_new_location(vlc, mrl)
	libvlc_instance_t *vlc
	const char *mrl

libvlc_media_t *
libvlc_media_new_path(vlc, path)
	libvlc_instance_t *vlc
	const char *path

libvlc_media_t *
libvlc_media_new_fd(vlc, fd)
	libvlc_instance_t *vlc
	int fd

long
libvlc_media_get_duration(media)
	libvlc_media_t *media

char *
libvlc_media_get_meta(media, field_id)
	libvlc_media_t *media
	int field_id

void
libvlc_media_parse(media)
	libvlc_media_t *media

#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 30000)

int
libvlc_media_parse_with_options(media, parse_flag, timeout)
	libvlc_media_t *media
	int parse_flag
	int timeout

#endif

libvlc_media_player_t*
libvlc_media_player_new(vlc)
	libvlc_instance_t *vlc

libvlc_media_player_t*
libvlc_media_player_new_from_media(media)
	libvlc_media_t *media

void
libvlc_media_player_set_media(player, media)
	libvlc_media_player_t *player
	libvlc_media_t *media

int
libvlc_media_player_will_play(player)
	libvlc_media_player_t *player

int
libvlc_media_player_is_playing(player)
	libvlc_media_player_t *player

int
libvlc_media_player_is_seekable(player)
	libvlc_media_player_t *player

int
libvlc_media_player_can_pause(player)
	libvlc_media_player_t *player

int
libvlc_media_player_play(player)
	libvlc_media_player_t *player

void
libvlc_media_player_pause(player)
	libvlc_media_player_t *player

#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 10101)

void
libvlc_media_player_set_pause(player, do_pause)
	libvlc_media_player_t *player
	bool do_pause

#endif

void
libvlc_media_player_stop(player)
	libvlc_media_player_t *player

float
libvlc_media_player_get_rate(player)
	libvlc_media_player_t *player

int
libvlc_media_player_set_rate(player, rate)
	libvlc_media_player_t *player
	float rate

libvlc_time_t
libvlc_media_player_get_length(player)
	libvlc_media_player_t *player

libvlc_time_t
libvlc_media_player_get_time(player)
	libvlc_media_player_t *player

void
libvlc_media_player_set_time(player, i_time)
	libvlc_media_player_t *player
	libvlc_time_t i_time

float
libvlc_media_player_get_position(player)
	libvlc_media_player_t *player

void
libvlc_media_player_set_position(player, pos)
	libvlc_media_player_t *player
	float pos

int
libvlc_media_player_get_chapter_count(player)
	libvlc_media_player_t *player

int
libvlc_media_player_get_chapter(player)
	libvlc_media_player_t *player

void
libvlc_media_player_set_chapter(player, chapter)
	libvlc_media_player_t *player
	int chapter

void
libvlc_media_player_next_chapter(player)
	libvlc_media_player_t *player

void
libvlc_media_player_previous_chapter(player)
	libvlc_media_player_t *player

int
libvlc_media_player_get_title_count(player)
	libvlc_media_player_t *player

int
libvlc_media_player_get_title(player)
	libvlc_media_player_t *player

void
libvlc_media_player_set_title(player, title)
	libvlc_media_player_t *player
	int title

#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20100)

void
libvlc_media_player_set_video_title_display(player, position, timeout)
	libvlc_media_player_t *player
	libvlc_position_t position
	unsigned int timeout

#endif

void
libvlc_video_set_format(player, chroma, width, height, pitch)
	libvlc_media_player_t *player
	char *chroma
	unsigned width
	unsigned height
	unsigned pitch

void
_const_unavailable()
	PPCODE:
		croak("Symbol not available on this version of LibVLC");

MODULE = VideoLAN::LibVLC              PACKAGE = VideoLAN::LibVLC::Media

void
_build_metadata(media)
	libvlc_media_t *media
	INIT:
		HV *meta;
		SV *ref;
		const char* val;
		struct { int code; const char *name; } *attr, attrlist[]= {
			{ libvlc_meta_Title       , "Title"       },
			{ libvlc_meta_Artist      , "Artist"      },
			{ libvlc_meta_Genre       , "Genre"       },
			{ libvlc_meta_Copyright   , "Copyright"   },
			{ libvlc_meta_Album       , "Album"       },
			{ libvlc_meta_TrackNumber , "TrackNumber" },
			{ libvlc_meta_Description , "Description" },
			{ libvlc_meta_Rating      , "Rating"      },
			{ libvlc_meta_Date        , "Date"        },
			{ libvlc_meta_Setting     , "Setting"     },
			{ libvlc_meta_URL         , "URL"         },
			{ libvlc_meta_Language    , "Language"    },
			{ libvlc_meta_NowPlaying  , "NowPlaying"  },
			{ libvlc_meta_Publisher   , "Publisher"   },
			{ libvlc_meta_EncodedBy   , "EncodedBy"   },
			{ libvlc_meta_ArtworkURL  , "ArtworkURL"  },
			{ libvlc_meta_TrackID     , "TrackID"     },
#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20200)
			{ libvlc_meta_TrackTotal  , "TrackTotal"  },
			{ libvlc_meta_Director    , "Director"    },
			{ libvlc_meta_Season      , "Season"      },
			{ libvlc_meta_Episode     , "Episode"     },
			{ libvlc_meta_ShowName    , "ShowName"    },
			{ libvlc_meta_Actors      , "Actors"      },
#endif
#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 30000)
			{ libvlc_meta_AlbumArtist , "AlbumArtist" },
			{ libvlc_meta_DiscNumber  , "DiscNumber"  },
			{ libvlc_meta_DiscTotal   , "DiscTotal"   },
#endif
			{ 0, NULL }
		};
	PPCODE:
		ref= sv_2mortal(newRV_noinc((SV*) (meta= newHV())));
		for (attr= attrlist; attr->name; attr++) {
			val= libvlc_media_get_meta(media, attr->code);
			if (val) hv_store(meta, attr->name, strlen(attr->name), newSVpv(val, 0), 0);
		}
		PUSHs(ref);

MODULE = VideoLAN::LibVLC              PACKAGE = VideoLAN::LibVLC::MediaPlayer

void
_set_vbuf_pipe(player, read_fd, write_fd)
	PerlVLC_player_t *player
	int read_fd
	int write_fd
	PPCODE:
		player->vbuf_pipe[0]= read_fd;
		player->vbuf_pipe[1]= write_fd;

void
_enable_video_callbacks(player, event_fd, cb_id, which_list)
	PerlVLC_player_t *player
	int event_fd
	int cb_id
	AV *which_list
	INIT:
		int i, which= 0;
		SV **item;
		char *s;
	PPCODE:
		player->callback_id= cb_id;
		player->event_pipe= event_fd;
		for (i= 0; i <= av_len(which_list); i++)
			if ((item= av_fetch(which_list, i, 0)) && *item && SvOK(*item)) {
				s= SvPV_nolen(*item);
				if      (0 == strcmp(s, "lock"))    which |= PERLVLC_VIDEO_CALLBACK_LOCK;
				else if (0 == strcmp(s, "unlock"))  which |= PERLVLC_VIDEO_CALLBACK_UNLOCK;
				else if (0 == strcmp(s, "display")) which |= PERLVLC_VIDEO_CALLBACK_DISPLAY;
				else if (0 == strcmp(s, "format"))  which |= PERLVLC_VIDEO_CALLBACK_FORMAT;
				else if (0 == strcmp(s, "cleanup")) which |= PERLVLC_VIDEO_CALLBACK_CLEANUP;
				else warn("No such callback %s", s);
			}
		PerlVLC_enable_video_callbacks(player, which);

void
_set_video_format(player, format_hv)
	PerlVLC_player_t *player
	HV *format_hv
	INIT:
		PerlVLC_picture_format_t format;
		SV **item;
	PPCODE:
		memset(&format, 0, sizeof(format));
		PerlVLC_picture_format_init_from_hv(&format, format_hv);
		if (!format.lines[0]) croak("lines[0] must be set");
		if (!format.pitch[0]) croak("pitch[0] must be set");
		if (player->need_format_response) {
			if (!(item= hv_fetchs(format_hv, "alloc_count", 0)) || !*item || !SvOK(*item))
				croak("alloc_count is required when replying to callback");
			PerlVLC_video_reply_format(player, &format, SvIV(*item));
			player->need_format_response= 0;
		}
		else {
			warn("Setting libvlc_video_set_format(%p, %.4s, %d, %d, %d)",
				player->player, format.chroma, format.width, format.height, format.pitch[0]);
			libvlc_video_set_format(player->player, format.chroma, format.width, format.height, format.pitch[0]);
		}
		memcpy(&player->current_format, &format, sizeof(format));

int
_need_format_response(player, assign=NULL)
	PerlVLC_player_t *player
	SV *assign
	CODE:
		if (assign)
			player->need_format_response= SvIV(assign);
		RETVAL= player->need_format_response;
	OUTPUT:
		RETVAL

void
queue_picture(player, pic)
	PerlVLC_player_t *player
	PerlVLC_picture_t *pic
	PPCODE:
		if (player->need_format_response)
			croak("Can't queue pictures until format response is sent");
		PerlVLC_player_send_picture(player, pic);
		PerlVLC_player_add_picture(player, pic);

PerlVLC_picture_t *
_dequeue_picture(player, pic_address)
	PerlVLC_player_t *player
	IV pic_address;
	INIT:
		PerlVLC_picture_t *pic;
		int i;
	CODE:
		RETVAL= NULL;
		for (i= 0; i < player->picture_count; i++)
			if (((intptr_t)player->pictures[i]) == pic_address) {
				RETVAL= (PerlVLC_picture_t*) pic_address;
				break;
			}
		if (!RETVAL)
			croak("Picture does not belong to this player");
		pic= (PerlVLC_picture_t*) pic_address;
		PerlVLC_player_remove_picture(player, pic);
		pic->held_by_vlc= 0;
	OUTPUT:
		RETVAL

PerlVLC_picture_t *
_inflate_picture(player, pic_address)
	PerlVLC_player_t *player
	IV pic_address;
	INIT:
		int i;
	CODE:
		RETVAL= NULL;
		for (i= 0; i < player->picture_count; i++)
			if (((intptr_t)player->pictures[i]) == pic_address) {
				RETVAL= (PerlVLC_picture_t*) pic_address;
				break;
			}
		if (!RETVAL)
			croak("Picture does not belong to this player");
	OUTPUT:
		RETVAL

int
queued_picture_count(player)
	PerlVLC_player_t *player
	CODE:
		RETVAL= player->picture_count;
	OUTPUT:
		RETVAL

int
trace_pictures(player, ...)
	PerlVLC_player_t *player;
	CODE:
		if (items > 1)
			player->trace_pictures= SvIV(ST(1));
		RETVAL= player->trace_pictures;
	OUTPUT:
		RETVAL

MODULE = VideoLAN::LibVLC              PACKAGE = VideoLAN::LibVLC::Picture

PerlVLC_picture_t *
new(classname, args)
	SV *classname
	SV *args
	CODE:
		RETVAL= PerlVLC_picture_new_from_hash(args);
	OUTPUT:
		RETVAL

int
id(pic, ...)
	PerlVLC_picture_t *pic;
	CODE:
		if (items > 1)
			pic->id= SvIV(ST(1));
		RETVAL= pic->id;
	OUTPUT:
		RETVAL

SV *
chroma(pic)
	PerlVLC_picture_t *pic;
	CODE:
		RETVAL= newSVpvn(pic->format.chroma, 4);
	OUTPUT:
		RETVAL

int
width(pic)
	PerlVLC_picture_t *pic;
	CODE:
		RETVAL= pic->format.width;
	OUTPUT:
		RETVAL

int
height(pic)
	PerlVLC_picture_t *pic;
	CODE:
		RETVAL= pic->format.height;
	OUTPUT:
		RETVAL

SV *
plane(pic, idx)
	PerlVLC_picture_t *pic;
	int idx;
	CODE:
		if (pic->held_by_vlc)
			croak("Can't access planes while Picture object is held by VLC decoder thread");
		RETVAL= (idx < 0 || idx > 3)? &PL_sv_undef
			: pic->plane_buffer_sv[idx]? newSVsv(pic->plane_buffer_sv[idx])
			: pic->plane[idx]? newRV_noinc(buffer_scalar_wrap(aTHX_ newSV(0),
					PERLVLC_ALIGN_PLANE(pic->plane[idx]),
					pic->format.pitch[idx] * pic->format.lines[idx], 0, NULL, NULL))
			: &PL_sv_undef;
	OUTPUT:
		RETVAL

SV *
pitch(pic, idx)
	PerlVLC_picture_t *pic;
	int idx;
	CODE:
		RETVAL= (idx < 0 || idx > 3 || !(pic->format.pitch[idx] || pic->plane_buffer_sv[idx]))? &PL_sv_undef
			: newSViv(pic->format.pitch[idx]);
	OUTPUT:
		RETVAL

SV *
lines(pic, idx)
	PerlVLC_picture_t *pic;
	int idx;
	CODE:
		RETVAL= (idx < 0 || idx > 3 || !(pic->format.lines[idx] || pic->plane_buffer_sv[idx]))? &PL_sv_undef
			: newSViv(pic->format.lines[idx]);
	OUTPUT:
		RETVAL

int
held_by_vlc(pic)
	PerlVLC_picture_t *pic;
	CODE:
		RETVAL= pic->held_by_vlc;
	OUTPUT:
		RETVAL

BOOT:
# BEGIN GENERATED BOOT CONSTANTS
  HV* stash= gv_stashpv("VideoLAN::LibVLC", GV_ADD);
  newCONSTSUB(stash, "STATE_OPENING", newSViv(libvlc_Opening));
  newCONSTSUB(stash, "STATE_PAUSED", newSViv(libvlc_Paused));
  newCONSTSUB(stash, "STATE_PLAYING", newSViv(libvlc_Playing));
  newCONSTSUB(stash, "STATE_ENDED", newSViv(libvlc_Ended));
  newCONSTSUB(stash, "STATE_ERROR", newSViv(libvlc_Error));
  newCONSTSUB(stash, "STATE_NOTHINGSPECIAL", newSViv(libvlc_NothingSpecial));
  newCONSTSUB(stash, "STATE_BUFFERING", newSViv(libvlc_Buffering));
  newCONSTSUB(stash, "STATE_STOPPED", newSViv(libvlc_Stopped));
  newCONSTSUB(stash, "TRACK_AUDIO", newSViv(libvlc_track_audio));
  newCONSTSUB(stash, "TRACK_TEXT", newSViv(libvlc_track_text));
  newCONSTSUB(stash, "TRACK_UNKNOWN", newSViv(libvlc_track_unknown));
  newCONSTSUB(stash, "TRACK_VIDEO", newSViv(libvlc_track_video));
  newCONSTSUB(stash, "META_ALBUM", newSViv(libvlc_meta_Album));
  newCONSTSUB(stash, "META_ARTIST", newSViv(libvlc_meta_Artist));
  newCONSTSUB(stash, "META_ARTWORKURL", newSViv(libvlc_meta_ArtworkURL));
  newCONSTSUB(stash, "META_COPYRIGHT", newSViv(libvlc_meta_Copyright));
  newCONSTSUB(stash, "META_DATE", newSViv(libvlc_meta_Date));
  newCONSTSUB(stash, "META_DESCRIPTION", newSViv(libvlc_meta_Description));
  newCONSTSUB(stash, "META_ENCODEDBY", newSViv(libvlc_meta_EncodedBy));
  newCONSTSUB(stash, "META_GENRE", newSViv(libvlc_meta_Genre));
  newCONSTSUB(stash, "META_LANGUAGE", newSViv(libvlc_meta_Language));
  newCONSTSUB(stash, "META_NOWPLAYING", newSViv(libvlc_meta_NowPlaying));
  newCONSTSUB(stash, "META_PUBLISHER", newSViv(libvlc_meta_Publisher));
  newCONSTSUB(stash, "META_RATING", newSViv(libvlc_meta_Rating));
  newCONSTSUB(stash, "META_SETTING", newSViv(libvlc_meta_Setting));
  newCONSTSUB(stash, "META_TITLE", newSViv(libvlc_meta_Title));
  newCONSTSUB(stash, "META_TRACKID", newSViv(libvlc_meta_TrackID));
  newCONSTSUB(stash, "META_TRACKNUMBER", newSViv(libvlc_meta_TrackNumber));
  newCONSTSUB(stash, "META_URL", newSViv(libvlc_meta_URL));
#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20100)
  newCONSTSUB(stash, "LOG_LEVEL_DEBUG", newSViv(LIBVLC_DEBUG));
  newCONSTSUB(stash, "LOG_LEVEL_NOTICE", newSViv(LIBVLC_NOTICE));
  newCONSTSUB(stash, "LOG_LEVEL_WARNING", newSViv(LIBVLC_WARNING));
  newCONSTSUB(stash, "LOG_LEVEL_ERROR", newSViv(LIBVLC_ERROR));
#else
  newXS("VideoLAN::LibVLC::LOG_LEVEL_DEBUG", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::LOG_LEVEL_NOTICE", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::LOG_LEVEL_WARNING", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::LOG_LEVEL_ERROR", XS_VideoLAN__LibVLC__const_unavailable, file);
#endif
#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20200)
  newCONSTSUB(stash, "META_ACTORS", newSViv(libvlc_meta_Actors));
  newCONSTSUB(stash, "META_DIRECTOR", newSViv(libvlc_meta_Director));
  newCONSTSUB(stash, "META_EPISODE", newSViv(libvlc_meta_Episode));
  newCONSTSUB(stash, "META_SEASON", newSViv(libvlc_meta_Season));
  newCONSTSUB(stash, "META_SHOWNAME", newSViv(libvlc_meta_ShowName));
  newCONSTSUB(stash, "META_TRACKTOTAL", newSViv(libvlc_meta_TrackTotal));
  newCONSTSUB(stash, "POSITION_DISABLE", newSViv(libvlc_position_disable));
  newCONSTSUB(stash, "POSITION_CENTER", newSViv(libvlc_position_center));
  newCONSTSUB(stash, "POSITION_LEFT", newSViv(libvlc_position_left));
  newCONSTSUB(stash, "POSITION_RIGHT", newSViv(libvlc_position_right));
  newCONSTSUB(stash, "POSITION_TOP", newSViv(libvlc_position_top));
  newCONSTSUB(stash, "POSITION_TOP_LEFT", newSViv(libvlc_position_top_left));
  newCONSTSUB(stash, "POSITION_TOP_RIGHT", newSViv(libvlc_position_top_right));
  newCONSTSUB(stash, "POSITION_BOTTOM", newSViv(libvlc_position_bottom));
  newCONSTSUB(stash, "POSITION_BOTTOM_LEFT", newSViv(libvlc_position_bottom_left));
  newCONSTSUB(stash, "POSITION_BOTTOM_RIGHT", newSViv(libvlc_position_bottom_right));
#else
  newXS("VideoLAN::LibVLC::META_ACTORS", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_DIRECTOR", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_EPISODE", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_SEASON", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_SHOWNAME", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_TRACKTOTAL", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_DISABLE", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_CENTER", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_LEFT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_RIGHT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_TOP", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_TOP_LEFT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_TOP_RIGHT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_BOTTOM", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_BOTTOM_LEFT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::POSITION_BOTTOM_RIGHT", XS_VideoLAN__LibVLC__const_unavailable, file);
#endif
#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 30000)
  newCONSTSUB(stash, "VIDEO_ORIENT_TOP_LEFT", newSViv(libvlc_video_orient_top_left));
  newCONSTSUB(stash, "VIDEO_ORIENT_TOP_RIGHT", newSViv(libvlc_video_orient_top_right));
  newCONSTSUB(stash, "VIDEO_ORIENT_BOTTOM_LEFT", newSViv(libvlc_video_orient_bottom_left));
  newCONSTSUB(stash, "VIDEO_ORIENT_BOTTOM_RIGHT", newSViv(libvlc_video_orient_bottom_right));
  newCONSTSUB(stash, "VIDEO_ORIENT_LEFT_TOP", newSViv(libvlc_video_orient_left_top));
  newCONSTSUB(stash, "VIDEO_ORIENT_LEFT_BOTTOM", newSViv(libvlc_video_orient_left_bottom));
  newCONSTSUB(stash, "VIDEO_ORIENT_RIGHT_TOP", newSViv(libvlc_video_orient_right_top));
  newCONSTSUB(stash, "VIDEO_ORIENT_RIGHT_BOTTOM", newSViv(libvlc_video_orient_right_bottom));
  newCONSTSUB(stash, "VIDEO_PROJECTION_RECTANGULAR", newSViv(libvlc_video_projection_rectangular));
  newCONSTSUB(stash, "VIDEO_PROJECTION_EQUIRECTANGULAR", newSViv(libvlc_video_projection_equirectangular));
  newCONSTSUB(stash, "VIDEO_PROJECTION_CUBEMAP_LAYOUT_STANDARD", newSViv(libvlc_video_projection_cubemap_layout_standard));
  newCONSTSUB(stash, "MEDIA_TYPE_UNKNOWN", newSViv(libvlc_media_type_unknown));
  newCONSTSUB(stash, "MEDIA_TYPE_FILE", newSViv(libvlc_media_type_file));
  newCONSTSUB(stash, "MEDIA_TYPE_DIRECTORY", newSViv(libvlc_media_type_directory));
  newCONSTSUB(stash, "MEDIA_TYPE_DISC", newSViv(libvlc_media_type_disc));
  newCONSTSUB(stash, "MEDIA_TYPE_STREAM", newSViv(libvlc_media_type_stream));
  newCONSTSUB(stash, "MEDIA_TYPE_PLAYLIST", newSViv(libvlc_media_type_playlist));
  newCONSTSUB(stash, "MEDIA_PARSE_LOCAL", newSViv(libvlc_media_parse_local));
  newCONSTSUB(stash, "MEDIA_PARSE_NETWORK", newSViv(libvlc_media_parse_network));
  newCONSTSUB(stash, "MEDIA_FETCH_LOCAL", newSViv(libvlc_media_fetch_local));
  newCONSTSUB(stash, "MEDIA_FETCH_NETWORK", newSViv(libvlc_media_fetch_network));
  newCONSTSUB(stash, "MEDIA_DO_INTERACT", newSViv(libvlc_media_do_interact));
  newCONSTSUB(stash, "MEDIA_PARSED_STATUS_SKIPPED", newSViv(libvlc_media_parsed_status_skipped));
  newCONSTSUB(stash, "MEDIA_PARSED_STATUS_FAILED", newSViv(libvlc_media_parsed_status_failed));
  newCONSTSUB(stash, "MEDIA_PARSED_STATUS_TIMEOUT", newSViv(libvlc_media_parsed_status_timeout));
  newCONSTSUB(stash, "MEDIA_PARSED_STATUS_DONE", newSViv(libvlc_media_parsed_status_done));
  newCONSTSUB(stash, "MEDIA_SLAVE_TYPE_SUBTITLE", newSViv(libvlc_media_slave_type_subtitle));
  newCONSTSUB(stash, "MEDIA_SLAVE_TYPE_AUDIO", newSViv(libvlc_media_slave_type_audio));
  newCONSTSUB(stash, "META_ALBUMARTIST", newSViv(libvlc_meta_AlbumArtist));
  newCONSTSUB(stash, "META_DISCNUMBER", newSViv(libvlc_meta_DiscNumber));
  newCONSTSUB(stash, "META_DISCTOTAL", newSViv(libvlc_meta_DiscTotal));
#else
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_TOP_LEFT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_TOP_RIGHT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_BOTTOM_LEFT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_BOTTOM_RIGHT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_LEFT_TOP", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_LEFT_BOTTOM", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_RIGHT_TOP", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_ORIENT_RIGHT_BOTTOM", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_PROJECTION_RECTANGULAR", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_PROJECTION_EQUIRECTANGULAR", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::VIDEO_PROJECTION_CUBEMAP_LAYOUT_STANDARD", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_TYPE_UNKNOWN", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_TYPE_FILE", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_TYPE_DIRECTORY", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_TYPE_DISC", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_TYPE_STREAM", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_TYPE_PLAYLIST", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_PARSE_LOCAL", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_PARSE_NETWORK", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_FETCH_LOCAL", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_FETCH_NETWORK", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_DO_INTERACT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_PARSED_STATUS_SKIPPED", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_PARSED_STATUS_FAILED", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_PARSED_STATUS_TIMEOUT", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_PARSED_STATUS_DONE", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_SLAVE_TYPE_SUBTITLE", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::MEDIA_SLAVE_TYPE_AUDIO", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_ALBUMARTIST", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_DISCNUMBER", XS_VideoLAN__LibVLC__const_unavailable, file);
  newXS("VideoLAN::LibVLC::META_DISCTOTAL", XS_VideoLAN__LibVLC__const_unavailable, file);
#endif
# END GENERATED BOOT CONSTANTS
  newCONSTSUB(stash, "PERLVLC_MSG_LOG"                 , newSViv(PERLVLC_MSG_LOG                ));
  newCONSTSUB(stash, "PERLVLC_MSG_VIDEO_LOCK_EVENT"    , newSViv(PERLVLC_MSG_VIDEO_LOCK_EVENT   ));
  newCONSTSUB(stash, "PERLVLC_MSG_VIDEO_TRADE_PICTURE" , newSViv(PERLVLC_MSG_VIDEO_TRADE_PICTURE));
  newCONSTSUB(stash, "PERLVLC_MSG_VIDEO_UNLOCK_EVENT"  , newSViv(PERLVLC_MSG_VIDEO_UNLOCK_EVENT ));
  newCONSTSUB(stash, "PERLVLC_MSG_VIDEO_DISPLAY_EVENT" , newSViv(PERLVLC_MSG_VIDEO_DISPLAY_EVENT));
  newCONSTSUB(stash, "PERLVLC_MSG_VIDEO_FORMAT_EVENT"  , newSViv(PERLVLC_MSG_VIDEO_FORMAT_EVENT ));
  newCONSTSUB(stash, "PERLVLC_MSG_VIDEO_CLEANUP_EVENT" , newSViv(PERLVLC_MSG_VIDEO_CLEANUP_EVENT));
  newCONSTSUB(stash, "PERLVLC_PLANE_PITCH_MUL"         , newSViv(PERLVLC_PLANE_PITCH_MUL        ));
  newCONSTSUB(stash, "PERLVLC_PLANE_PITCH_MASK"        , newSViv(PERLVLC_PLANE_PITCH_MASK       ));
  newCONSTSUB(stash, "PERLVLC_PICTURE_PLANES"          , newSViv(PERLVLC_PICTURE_PLANES         ));
#
