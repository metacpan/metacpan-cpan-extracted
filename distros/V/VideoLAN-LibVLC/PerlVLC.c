#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <vlc/vlc.h>
#include <vlc/libvlc_version.h>
#include <stdint.h>
#include <stdarg.h>
#include <sys/socket.h>

#include "PerlVLC.h"

/*#define PERLVLC_TRACE(x...) PerlVLC_cb_log_error(x) */
#define PERLVLC_TRACE(...) ((void)0)

static void carp_croak_sv(SV* value) {
        dSP;
        PUSHMARK(SP);
        XPUSHs(value);
        PUTBACK;
        call_pv("Carp::croak", G_VOID | G_DISCARD);
}
#define carp_croak(format_args...) carp_croak_sv(sv_2mortal(newSVpvf(format_args)))
#define fetch_if_defined(hv, name) _fetch_if_defined(hv, name, (sizeof(name)-1))

static SV *_fetch_if_defined(HV *self, const char *field, int len) {
	SV **field_p= hv_fetch(self, field, len, 0);
	return (field_p && *field_p && SvOK(*field_p)) ? *field_p : NULL;
}

static void PerlVLC_cb_log_error(const char *fmt, ...);
static void* PerlVLC_video_lock_cb(void *data, void **planes);
static void PerlVLC_video_unlock_cb(void *data, void *picture, void * const *planes);
static void PerlVLC_video_display_cb(void *data, void *picture);

static SV* PerlVLC_set_mg(SV *obj, MGVTBL *mg_vtbl, void *ptr) {
	MAGIC *mg= NULL;
	
	if (!sv_isobject(obj))
		croak("Can't add magic to non-object");
	
	/* Search for existing Magic that would hold this pointer */
	for (mg = SvMAGIC(SvRV(obj)); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == mg_vtbl) {
			mg->mg_ptr= ptr;
			return obj;
		}
	}
	sv_magicext(SvRV(obj), NULL, PERL_MAGIC_ext, mg_vtbl, (const char *) ptr, 0);
	return obj;
}

void* PerlVLC_get_mg(SV *obj, MGVTBL *mg_vtbl) {
	MAGIC *mg= NULL;
	if (sv_isobject(obj)) {
		for (mg = SvMAGIC(SvRV(obj)); mg; mg = mg->mg_moremagic) {
			if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == mg_vtbl)
				return (void*) mg->mg_ptr;
		}
	}
	return NULL;
}

/* Given a VLC instance object, wrap it with a PerlVLC_vlc struct and then wrap that with
 * a blessed HV.  Return a ref to the HV.
 */
SV * PerlVLC_wrap_instance(libvlc_instance_t *instance) {
	SV *self;
	PerlVLC_vlc_t *vlc;
	PERLVLC_TRACE("PerlVLC_wrap_instance(%p)", instance);
	if (!instance) return &PL_sv_undef;
	self= newRV_noinc((SV*)newHV());
	sv_bless(self, gv_stashpv("VideoLAN::LibVLC", GV_ADD));
	Newxz(vlc, 1, PerlVLC_vlc_t);
	vlc->instance= instance;
	vlc->event_pipe[0]= -1;
	vlc->event_pipe[1]= -1;
	PerlVLC_set_instance_mg(self, vlc);
	return self;
}

int PerlVLC_instance_mg_free(pTHX_ SV *inst_sv, MAGIC *mg) {
	PerlVLC_vlc_t *vlc= (PerlVLC_vlc_t*) mg->mg_ptr;
	PERLVLC_TRACE("PerlVLC_instance_mg_free(%p)", vlc);
	if (!vlc) return 0;
	/* Then release the reference to the player, which may free it right now,
	 * or maybe not.  libvlc doesn't let us look at the reference count.
	 */
	PERLVLC_TRACE("libvlc_instance_release(%p)", vlc->instance);
	libvlc_release(vlc->instance);
	/* Now it should be safe to free mpinfo */
	PERLVLC_TRACE("free(vlc=%p)", vlc);
	Safefree(vlc);
	return 0;
}

/* Given a VLC media object, wrap it with a blessed HV.  Return a ref to the HV.
 */
SV * PerlVLC_wrap_media(libvlc_media_t *media) {
	PERLVLC_TRACE("PerlVLC_wrap_media(%p)", media);
    PerlVLC_set_media_mg(
		sv_bless(newRV_noinc((SV*)newHV()), gv_stashpv("VideoLAN::LibVLC::Media", GV_ADD)),
		media
	);
}

int PerlVLC_media_mg_free(pTHX_ SV *media_sv, MAGIC *mg) {
	libvlc_media_t *media= (libvlc_media_t*) mg->mg_ptr;
	PERLVLC_TRACE("libvlc_media_release(%p)", media);
	libvlc_media_release(media);
	return 0;
}

/* Given a VLC player object, wrap it with a PerlVLC_player struct and then wrap that with
 * a blessed HV.  Return a ref to the HV.
 */
SV * PerlVLC_wrap_media_player(libvlc_media_player_t *player) {
	PERLVLC_TRACE("PerlVLC_wrap_media_player(%p)", player);
	SV *self;
	PerlVLC_player_t *playerinfo;
	if (!player) return &PL_sv_undef;
	self= newRV_noinc((SV*)newHV());
	sv_bless(self, gv_stashpv("VideoLAN::LibVLC::MediaPlayer", GV_ADD));
	Newxz(playerinfo, 1, PerlVLC_player_t);
	playerinfo->player= player;
	playerinfo->event_pipe= -1;
	playerinfo->vbuf_pipe[0]= -1;
	playerinfo->vbuf_pipe[1]= -1;
	PerlVLC_set_media_player_mg(self, playerinfo);
	return self;
}

/* gets called with the blessed HV goes out of scope */
int PerlVLC_media_player_mg_free(pTHX_ SV *player_sv, MAGIC* mg) {
	PerlVLC_player_t *mpinfo= (PerlVLC_player_t*) mg->mg_ptr;
	libvlc_media_player_t *player;
	int i;
	PERLVLC_TRACE("PerlVLC_media_player_mg_free(%p)", mpinfo);
	if (!mpinfo) return 0;
	/* Make sure playback has stopped before releasing player.
	 * Also make sure the player isn't blocked inside a callback
	 * waiting for input from us.
	 */
	if (mpinfo->video_cb_installed) {
		/* inform the frame alloc callback that it won't be getting any more buffers */
		shutdown(mpinfo->vbuf_pipe[1], SHUT_WR);
		PERLVLC_TRACE("libvlc_media_player_stop(); # with vbuf_pipe shut down");
		libvlc_media_player_stop(mpinfo->player);
		/* Ensure the callback never uses mpinfo again by giving it NULL instead.
		 * I'm assuming that libvlc API has a mutex in there to ensure orderly behavior...
		 */
		libvlc_video_set_callbacks(mpinfo->player, PerlVLC_video_lock_cb, NULL, NULL, NULL);
	}
	/* Then release the reference to the player, which may free it right now,
	 * or maybe not.  libvlc doesn't let us look at the reference count.
	 */
	PERLVLC_TRACE("libvlc_media_player_release(%p)", mpinfo->player);
	libvlc_media_player_release(mpinfo->player);
	/* VLC shouldn't have any more picture objects at this point. */
	for (i= 0; i < mpinfo->picture_count; i++) {
		mpinfo->pictures[i]->held_by_vlc= 0;
		mpinfo->pictures[i]->trace_destruction= mpinfo->trace_pictures;
		sv_2mortal((SV*) mpinfo->pictures[i]->self_hv); /* release our hidden reference to the perl objects */
	}
	if (mpinfo->pictures) Safefree(mpinfo->pictures);
	/* Now it should be safe to free mpinfo */
	PERLVLC_TRACE("free(mpinfo=%p)", mpinfo);
	Safefree(mpinfo);
	return 0;
}

void PerlVLC_picture_format_init_from_hv(PerlVLC_picture_format_t *format, HV *hash) {
	SV **item, *field;
	AV *av;
	STRLEN len;
	int i;
	char *chroma;

	if (!(field= fetch_if_defined(hash, "chroma")))
		croak("chroma is required");
	chroma= SvPV(field, len);
	if (len != 4)
		croak("chroma must be 4 characters");
	*((int32_t*) format->chroma)= *((int32_t*)chroma);

	if (!(field= fetch_if_defined(hash, "width")))
		croak("width is required");
	format->width= SvIV(field);

	if (!(field= fetch_if_defined(hash, "height")))
		croak("height is required");
	format->height= SvIV(field);

	if ((field= fetch_if_defined(hash, "pitch"))) {
		if (SvROK(field) && SvTYPE(SvRV(field)) == SVt_PVAV) {
			av= (AV*) SvRV(field);
			for (i= 0; i < 3 && i <= av_len(av); i++) {
				item= av_fetch(av, i, 0);
				if (!item || !*item || !SvOK(*item))
					croak("Invalid %s->[%d]", "pitch", i);
				format->pitch[i]= SvIV(*item);
			}
		}
		else
			format->pitch[0]= SvIV(field);
		for (i= 0; i < 3; i++)
			if (format->pitch[i] & PERLVLC_PLANE_PITCH_MASK)
				warn("pitch[%d]=%d is not a multiple of %d as recommended by libvlc", i, format->pitch[i], PERLVLC_PLANE_PITCH_MUL);
	}
	if ((field= fetch_if_defined(hash, "lines"))) {
		if (SvROK(field) && SvTYPE(SvRV(field)) == SVt_PVAV) {
			av= (AV*) SvRV(field);
			for (i= 0; i < 3 && i <= av_len(av); i++) {
				item= av_fetch(av, i, 0);
				if (!item || !*item || !SvOK(*item))
					croak("Invalid %s->[%d]", "lines", i);
				format->lines[i]= SvIV(*item);
			}
		}
		else
			format->lines[0]= SvIV(field);
	}
}

/* This function constructs a PerlVLC_picture_t from a hashref that looks like:
 * {
 *   chroma => $c4,
 *   width => $w,
 *   height => $h,
 *   pitch => $v || [ $v0, $v1, $v2 ],
 *   lines => $v || [ $v0, $v1, $v2 ],
 *   plane => \$buffer || [ \$buf0, \$buf1, \$buf2 ]
 * }
 *
 * The plane buffer is optional.  If not specified, a buffer will be allocated.
 */
PerlVLC_picture_t* PerlVLC_picture_new_from_hash(SV *args) {
	PerlVLC_picture_t self, *ret;
	HV *hash, *plane_hash;
	SV **item, *field;
	AV *av;
	int i, pitch, lines;
	const char *chroma;
	STRLEN len;
	memset(&self, 0, sizeof(self));
	PERLVLC_TRACE("PerlVLC_picture_new_from_hash");

	if (!SvROK(args) || SvTYPE(SvRV(args)) != SVt_PVHV)
		croak("Expected hashref");
	hash= (HV*) SvRV(args);

	if ((field= fetch_if_defined(hash, "id")))
		self.id= SvIV(field);

	PerlVLC_picture_format_init_from_hv(&self.format, hash);

	if ((field= fetch_if_defined(hash, "plane"))) {
		av= (SvROK(field) && SvTYPE(SvRV(field)) == SVt_PVAV)? (AV*) SvRV(field) : NULL;
		for (i= 0; av? (i < 3 && i <= av_len(av)) : (i < 1); i++) {
			if (av) { item= av_fetch(av, i, 0); field= (item && *item && SvOK(*item))? *item : NULL; }
			if (!field || !SvPOK(SvRV(field)))
				croak("Invalid %s->[%d]", "plane", i);
			/* hold a reference to the scalar within the scalar-ref. Don't inc refcnt until below. */
			self.plane_buffer_sv[i]= SvRV(*item);
		}
	}
	/* If pitch and lines are not set on plane[0], come up with some defaults.
	 * If it is supposed to be a multi-plane image and those pitches/lines aren't
	 * set, the user gets to keep the pieces.
	 */
	if (!self.format.pitch[0] || !self.format.lines[0]) {
		if (self.plane_buffer_sv[0])
			croak("'pitch' and 'lines' must be set when using scalar ref as buffer");
		else {
			if (!self.format.pitch[0]) self.format.pitch[0]= (self.format.width + PERLVLC_PLANE_PITCH_MASK) & ~PERLVLC_PLANE_PITCH_MASK;
			if (!self.format.lines[0]) self.format.lines[0]= self.format.height;
		}
	}

	/* now make a copy into dynamic memory */
	Newx(ret, 1, PerlVLC_picture_t);
	memcpy(ret, &self, sizeof(PerlVLC_picture_t));
	/* and increment any ref counts to the buffers we are holding onto, and allocate
	 * the buffers that weren't supplied. */
	for (i= 0; i < PERLVLC_PICTURE_PLANES; i++) {
		if (ret->plane_buffer_sv[i])
			SvREFCNT_inc(ret->plane_buffer_sv[i]);
		else if (ret->format.pitch[i] && ret->format.lines[i])
			Newx(ret->plane[i], ret->format.pitch[i] * ret->format.lines[i]
				+ PERLVLC_PLANE_PITCH_MASK /* extra for alignment */, char);
	}
	PERLVLC_TRACE("plane pointers: %p %p %p", ret->plane[0], ret->plane[1], ret->plane[2]);
	return ret;
}

/* Pictures hold references to a blessed HV which in turn has the struct magically attached.
 * If not set up, initialize it.  Then return a new ref to the HV.
 */
SV * PerlVLC_wrap_picture(PerlVLC_picture_t *pic) {
	PERLVLC_TRACE("PerlVLC_wrap_picture(%p)", pic);
	SV *self;
	if (!pic) return &PL_sv_undef;
	if (!pic->self_hv) {
		self= newRV_noinc((SV*) (pic->self_hv= newHV()));
		sv_bless(self, gv_stashpv("VideoLAN::LibVLC::Picture", GV_ADD));
		/* after this, when the HV goes out of scope it calls the mg_free (our destructor) */
		PerlVLC_set_picture_mg(self, pic);
		PERLVLC_TRACE("added new SV (refcnt=%d) to new HV (refcnt=%d)", SvREFCNT(self), SvREFCNT((SV*)pic->self_hv));
	} else {
		self= newRV_inc((SV*) pic->self_hv);
		PERLVLC_TRACE("added new SV (refcnt=%d) to existing HV (refcnt=%d)", SvREFCNT(self), SvREFCNT((SV*)pic->self_hv));
	}
	return self;
}

/* This shouldn't get called until the self_hv goes out of scope */
int PerlVLC_picture_mg_free(pTHX_ SV *picture_sv, MAGIC *mg) {
	PerlVLC_picture_t *pic= (PerlVLC_picture_t*) mg->mg_ptr;
	PERLVLC_TRACE("PerlVLC_picture_mg_free(%p)", pic);
	if (pic) {
		pic->self_hv= NULL;
		PerlVLC_picture_destroy(pic);
	}
	return 0;
}

void PerlVLC_picture_destroy(PerlVLC_picture_t *pic) {
	int i;
	PERLVLC_TRACE("PerlVLC_picture_destroy(%p)", pic);
	if (pic->held_by_vlc)
		warn("BUG: Picture object destroyed while VLC still has access to it!");
	if (pic->self_hv)
		croak("BUG: Picture object destroyed while Perl still has access to it!");
	if (pic->trace_destruction)
		PerlVLC_cb_log_error("picture %d: free [%p,%p,%p] or release ref [%p,%p,%p]",
			pic->id, pic->plane[0], pic->plane[1], pic->plane[2],
			pic->plane_buffer_sv[0], pic->plane_buffer_sv[1], pic->plane_buffer_sv[2]);
		
	/* For each plane, the buffer either came from a perl scalar ref, or was allocated directly. */
	for (i= 0; i < PERLVLC_PICTURE_PLANES; i++) {
		if (pic->plane_buffer_sv[i])
			SvREFCNT_dec(pic->plane_buffer_sv[i]);
		else if (pic->plane[i])
			Safefree(pic->plane[i]);
	}
	Safefree(pic);
}

/*------------------------------------------------------------------------------------------------
 * Callback system.
 *
 * The callbacks work by writing messages to a pipe (socket actually, to avoid SIGPIPE issues)
 * which the main perl thread reads and dispatches to coderefs.
 *
 * All messages start with a little header struct that frames the messages for reliable transfer.
 */

/* changes here should be kept in sync with PERLVLC_MSG_BUFFER_SIZE in header */
#define PERLVLC_MSG_HEADER \
	uint32_t event_id; \
	uint32_t callback_id; \

typedef struct PerlVLC_Message {
	PERLVLC_MSG_HEADER
	char     payload[];
} PerlVLC_Message_t;

typedef struct PerlVLC_Message_LogMsg {
	PERLVLC_MSG_HEADER
	uint32_t level;
	uint32_t line;
	uint32_t objid;
	uint8_t module_strlen;
	uint8_t file_strlen;
	uint8_t name_strlen;
	uint8_t header_strlen;
	char stringdata[];
} PerlVLC_Message_LogMsg_t;

typedef struct PerlVLC_Message_TradePicture {
	PERLVLC_MSG_HEADER
	PerlVLC_picture_t *picture;
} PerlVLC_Message_TradePicture_t;

typedef struct PerlVLC_Message_ImgFmt {
	PERLVLC_MSG_HEADER
	PerlVLC_picture_format_t format;
	unsigned alloc_count;
} PerlVLC_Message_ImgFmt_t;

SV* PerlVLC_inflate_message(void *buffer, int msglen) {
	HV *obj, *ret= (HV*) sv_2mortal((SV*) newHV());
	AV *plane, *pitch, *lines;
	char *pos, *lim;
	int i;
	SV *sv;
	PerlVLC_Message_t *msg= (PerlVLC_Message_t*) buffer;
	PerlVLC_Message_LogMsg_t *logmsg;
	PerlVLC_Message_TradePicture_t *picmsg;
	PerlVLC_Message_ImgFmt_t *fmtmsg;

	if (msglen < sizeof(PerlVLC_Message_t))
		croak("Message too short (%d < %ld)", msglen, sizeof(PerlVLC_Message_t));
	switch (msg->event_id) {
	case PERLVLC_MSG_LOG:
		{
			if (msglen < sizeof(PerlVLC_Message_LogMsg_t)+1)
				croak("Message too short (%d < %ld)", msglen, sizeof(PerlVLC_Message_LogMsg_t));
			logmsg= (PerlVLC_Message_LogMsg_t *) msg;
			pos= logmsg->stringdata;
			lim= ((char*)buffer) + msglen;
			hv_stores(ret, "level", newSViv(logmsg->level));
			if (logmsg->line)
				hv_stores(ret, "line", newSViv(logmsg->line));
			if (logmsg->objid)
				hv_stores(ret, "objid", newSViv(logmsg->objid));
			if (logmsg->module_strlen) {
				if (pos + logmsg->module_strlen + 1 >= lim)
					croak("Message too short");
				hv_stores(ret, "module", newSVpvn(pos, logmsg->module_strlen));
				pos += logmsg->module_strlen+1;
			}
			if (logmsg->file_strlen) {
				if (pos + logmsg->file_strlen + 1 >= lim)
					croak("Message too short");
				hv_stores(ret, "file", newSVpvn(pos, logmsg->file_strlen));
				pos += logmsg->file_strlen+1;
			}
			if (logmsg->name_strlen) {
				if (pos + logmsg->name_strlen + 1 >= lim)
					croak("Message too short");
				hv_stores(ret, "name", newSVpvn(pos, logmsg->name_strlen));
				pos += logmsg->name_strlen+1;
			}
			if (logmsg->header_strlen) {
				if (pos + logmsg->header_strlen + 1 >= lim)
					croak("Message too short");
				hv_stores(ret, "header", newSVpvn(pos, logmsg->header_strlen));
				pos += logmsg->header_strlen+1;
			}
			lim[-1]= '\0'; /* for strlen safety */
			hv_stores(ret, "message", newSVpvn(pos, strlen(pos)));
		}
		if (0) {
	case PERLVLC_MSG_VIDEO_TRADE_PICTURE:
	case PERLVLC_MSG_VIDEO_UNLOCK_EVENT:
	case PERLVLC_MSG_VIDEO_DISPLAY_EVENT:
			if (msglen < sizeof(PerlVLC_Message_TradePicture_t))
				croak("Message too short (%d < %ld)", msglen, sizeof(PerlVLC_Message_TradePicture_t));
			picmsg= (PerlVLC_Message_TradePicture_t *) msg;
			/* The picture might have been freed.  Only way to check is if Player has it in
			 * the queued array still, and don't have access to the player here.  Until then,
			 * pass the picture pointer as an integer. */
			hv_stores(ret, "picture", newSVuv((intptr_t) picmsg->picture));
		}
		if (0) {
	case PERLVLC_MSG_VIDEO_FORMAT_EVENT:
			if (msglen < sizeof(PerlVLC_Message_ImgFmt_t))
				croak("Message too short (%d < %ld)", msglen, sizeof(PerlVLC_Message_TradePicture_t));
			fmtmsg= (PerlVLC_Message_ImgFmt_t *) msg;
			hv_stores(ret, "chroma", newSVpvn(fmtmsg->format.chroma, 4));
			hv_stores(ret, "width", newSViv(fmtmsg->format.width));
			hv_stores(ret, "height", newSViv(fmtmsg->format.height));
			hv_stores(ret, "pitch", newRV((SV*) (pitch= newAV())));
			hv_stores(ret, "lines", newRV((SV*) (lines= newAV())));
			for (i= 0; i < 3; i++) {
				av_push(pitch, newSViv(fmtmsg->format.pitch[i]));
				av_push(lines, newSViv(fmtmsg->format.lines[i]));
			}
		}
	default:
		hv_stores(ret, "callback_id", newSViv(msg->callback_id));
		hv_stores(ret, "event_id",  newSViv(msg->event_id));
	}
	return newRV_inc((SV*) ret);
}

/* Log an error from a callback.  The callback is likely in a different thread, so can't access
 * any Perl structures or even stdlib FILE handles, so just write to stderr and hope for the best.
 * Errors shouldn't happen except for bugs, anyway.
 */
static void PerlVLC_cb_log_error(const char *fmt, ...) {
	char buffer[256];
	va_list argp;
	va_start(argp, fmt);
	buffer[0]= '#'; buffer[1]= ' ';
	int len= 2+vsnprintf(buffer+2, sizeof(buffer)-2, fmt, argp);
	va_end(argp);
	if (len < sizeof(buffer)) { buffer[len++]= '\n'; }
	else { len= sizeof(buffer); buffer[len-1]= '\n'; }
	int wrote= write(2, buffer, len);
	(void) wrote; /* nothing we can do about errors, since we're in a callback */
}

/*------------------------------------------------------------------------------------------------
 * Logging Callback
 *
 * VLC provides a callback to receive log messages generated from other threads.
 * This implementation forwards those messages over the event pipe.
 */

#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20100)
void PerlVLC_log_cb(void *opaque, int level, const libvlc_log_t *ctx, const char *fmt, va_list args) {
	char *pos, *lim;
	const char *module, *file, *name, *header;
	int fd, minlev, wrote, line, avail, len;
	uintptr_t objid;
	char buffer[PERLVLC_MSG_BUFFER_SIZE];
	PerlVLC_Message_LogMsg_t *msg= (PerlVLC_Message_LogMsg_t*) buffer;
	PerlVLC_vlc_t *vlc= (PerlVLC_vlc_t*) opaque;
	PERLVLC_TRACE("PerlVLC_log_cb(%s, ...) @ %d", fmt, level);
	
	if (vlc->log_level > level) return;
	memset(msg, 0, sizeof(*msg));
	msg->level= level;
	pos= msg->stringdata;
	lim= buffer + sizeof(buffer);
	if (vlc->log_module || vlc->log_file || vlc->log_line) {
		libvlc_log_get_context(ctx, &module, &file, &line);
		if (module && vlc->log_module && pos + (len= strlen(module)) + 1 < lim) {
			memcpy(pos, module, len+1);
			pos += len+1;
			msg->module_strlen= len;
		}
		if (file && vlc->log_file && pos + (len= strlen(file)) + 1 < lim) {
			memcpy(pos, file, len+1);
			pos += len+1;
			msg->file_strlen= len;
		}
		msg->line= line;
	}
	if (vlc->log_name || vlc->log_header || vlc->log_objid) {
		libvlc_log_get_object(ctx, &name, &header, &objid);
		if (name && vlc->log_name && pos + (len= strlen(name)) + 1 < lim) {
			memcpy(pos, name, len+1);
			pos += len+1;
			msg->name_strlen= len;
		}
		if (header && vlc->log_header && pos + (len= strlen(header)) + 1 < lim) {
			memcpy(pos, header, len+1);
			pos += len+1;
			msg->header_strlen= len;
		}
		msg->objid= objid;
	}
	wrote= vsnprintf(pos, lim-pos, fmt, args);
/*	PERLVLC_TRACE("sprintf into %ld bytes = %d", lim-pos, wrote); */
	if (wrote > 0) { pos += wrote; if (pos >= lim) pos= lim-1; }
	*pos++ = 0;
	msg->event_id= PERLVLC_MSG_LOG;
	msg->callback_id= (uint16_t) vlc->log_callback_id;
	wrote= send(vlc->event_pipe[1], buffer, pos - buffer, 0);
/*	PERLVLC_TRACE("send(%d, %p, %d, 0): %d", vlc->event_pipe[1], buffer, pos - buffer, wrote); */
}
#endif

void PerlVLC_set_log_cb(PerlVLC_vlc_t *vlc, int callback_id) {
	PERLVLC_TRACE("PerlVLC_set_log_cb");
#if ((LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= 20100)
	vlc->log_callback_id= callback_id;
	libvlc_log_set(vlc->instance, &PerlVLC_log_cb, vlc);
#else
	croak("Log redirection not suppoted on this version of VLC");
#endif
}

/*------------------------------------------------------------------------------------------------
 * Video Callbacks
 *
 * VLC offers a callback system that lets the host application allocate the buffers for
 * the picture.  This is useful for things like copying to OpenGL textures, or just to
 * get at the raw data.
 *
 */

/* The VLC decoder calls this when it has a new frame of video to decode.
 * It asks us to fill in the values for planes[0..2], normally to a pre-allocated
 * buffer.  We have to wait for a round trip to the user (unless next buffer is
 * already in the pipe).  We then return a value for 'picture' which gets passed
 * back to us during unlock_cb and display_cb.
 */
static void* PerlVLC_video_lock_cb(void *opaque, void **planes) {
	PerlVLC_player_t *mpinfo= (PerlVLC_player_t*) opaque;
	PerlVLC_picture_t *picture;
	int i;
	PerlVLC_Message_t lock_msg;
	PerlVLC_Message_TradePicture_t pic_msg;

	if (!mpinfo) {
		/* If this happens, it is a bug, and probably going to kil the program.  Warn loudly. */
		PerlVLC_cb_log_error("BUG: Video callback received NULL opaque pointer\n");
	}
	else {
		/* Write message to LibVLC instance that the callback is ready and needs data */
		lock_msg.callback_id= mpinfo->callback_id;
		lock_msg.event_id= PERLVLC_MSG_VIDEO_LOCK_EVENT;
		if (send(mpinfo->event_pipe, &lock_msg, sizeof(lock_msg), 0) <= 0) {
			/* This also should never happen, unless event pipe was closed. */
			PerlVLC_cb_log_error("BUG: Video callback can't send event\n");
			/* Might still have a spare buffer to use in the other pipe, though, so continue. */
		}
		
		i= 0;
		if (mpinfo->trace_pictures)
			PerlVLC_cb_log_error("video thread wants picture");
		if (recv(mpinfo->vbuf_pipe[0], &pic_msg, sizeof(pic_msg), 0) <= 0) {
			/* Should never happen, but could if pipe was closed before video thread stopped. */
			PerlVLC_cb_log_error("BUG: Video callback can't receive picture\n");
		}
		else if (pic_msg.event_id != PERLVLC_MSG_VIDEO_TRADE_PICTURE) {
			/* Should never happen, but could if pipe was closed before video thread stopped. */
			PerlVLC_cb_log_error("BUG: Video callback received mesage ID %d but expected %d\n",
				pic_msg.event_id, PERLVLC_MSG_VIDEO_TRADE_PICTURE);
		}
		else {
			picture= pic_msg.picture;
			for (i= 0; i < 3; i++)
				planes[i]= picture->plane_buffer_sv[i]? SvPVX(picture->plane_buffer_sv[i])
					: PERLVLC_ALIGN_PLANE(picture->plane[i]); /* alignment to 32-bytes */
			if (mpinfo->trace_pictures)
				PerlVLC_cb_log_error("video thread got picture %d (%p,%p,%p)", picture->id, planes[0], planes[1], planes[2]);
			return picture;
		}
	}
	/* LibVLC seems to handle this as a graceful failure */
	planes[0]= NULL;
	planes[1]= NULL;
	planes[2]= NULL;
	return NULL;
}

/* The VLC decoder calls this when it has filled the locked buffer with data.
 * We forward this to the user and return immediately.
 */
static void PerlVLC_video_unlock_cb(void *opaque, void *picture, void * const *planes) {
	PerlVLC_player_t *mpinfo= (PerlVLC_player_t*) opaque;
	PerlVLC_Message_TradePicture_t pic_msg;
	int i;
	char buf[128];
	if (!mpinfo) {
		/* If this happens, it is a bug, and probably going to kil the program.  Warn loudly. */
		PerlVLC_cb_log_error("BUG: Video unlock callback received NULL opaque pointer");
		return;
	}
	pic_msg.callback_id= mpinfo->callback_id;
	pic_msg.event_id= PERLVLC_MSG_VIDEO_UNLOCK_EVENT;
	pic_msg.picture= (PerlVLC_picture_t *) picture;
	if (mpinfo->trace_pictures)
		PerlVLC_cb_log_error("video thread filled picture %d", pic_msg.picture->id);
	if (send(mpinfo->event_pipe, &pic_msg, sizeof(pic_msg), 0) <= 0)
		/* This also should never happen, unless event pipe was closed. */
		PerlVLC_cb_log_error("BUG: Video unlock callback can't send event");
}

/* The VLC decoder calls this when it is time to display one of the pictures.
 * The 'picture' argument is whatever we returned in video_lock_cb when this picture
 * was locked/filled, but display order might be different from fill order.
 */
static void PerlVLC_video_display_cb(void *opaque, void *picture) {
	PerlVLC_player_t *mpinfo= (PerlVLC_player_t*) opaque;
	PerlVLC_Message_TradePicture_t pic_msg;
	int i;
	char buf[128];
	if (!mpinfo) {
		/* If this happens, it is a bug, and probably going to kil the program.  Warn loudly. */
		PerlVLC_cb_log_error("BUG: Video unlock callback received NULL opaque pointer");
		return;
	}
	pic_msg.callback_id= mpinfo->callback_id;
	pic_msg.event_id= PERLVLC_MSG_VIDEO_DISPLAY_EVENT;
	pic_msg.picture= (PerlVLC_picture_t *) picture;
	if (mpinfo->trace_pictures)
		PerlVLC_cb_log_error("video thread says display picture %d", pic_msg.picture->id);
	if (send(mpinfo->event_pipe, &pic_msg, sizeof(pic_msg), 0) <= 0)
		/* This also should never happen, unless event pipe was closed. */
		PerlVLC_cb_log_error("BUG: Video unlock callback can't send event");
}

/* The VLC decoder calls this when it knows the format of the media.
 * We relay this to the main thread where the user may opt to change some of the parameters,
 * and where the user should prepare the rendering buffers.
 * The user sends back the count of buffers allocated (why do they need that?) and any modifications
 * to these arguments.
 */
static unsigned PerlVLC_video_format_cb(void **opaque_p, char *chroma_p, unsigned *width_p, unsigned *height_p, unsigned *pitch, unsigned *lines) {
	PerlVLC_player_t *mpinfo= (PerlVLC_player_t*) *opaque_p;
	union {
		PerlVLC_Message_t msg;
		PerlVLC_Message_ImgFmt_t fmt_msg;
		PerlVLC_Message_TradePicture_t pic_msg;
	} msg;
	int i, got;

	if (!mpinfo) {
		/* If this happens, it is a bug, and probably going to kil the program.  Warn loudly. */
		PerlVLC_cb_log_error("BUG: Video format callback received NULL opaque pointer");
		return 0;
	}
	if (mpinfo->trace_pictures)
		PerlVLC_cb_log_error("format_cb: vlc gave chroma=%.4s width=%d height=%d pitch=[%d,%d,%d] lines=[%d,%d,%d]",
			chroma_p, *width_p, *height_p, pitch[0], pitch[1], pitch[2], lines[0], lines[1], lines[2]);
	
	/* Pack up arguments */
	memset(&msg.fmt_msg, 0, sizeof(msg.fmt_msg));
	msg.fmt_msg.callback_id= mpinfo->callback_id;
	msg.fmt_msg.event_id= PERLVLC_MSG_VIDEO_FORMAT_EVENT;
	*(int32_t*)msg.fmt_msg.format.chroma = *(int32_t*) chroma_p;
	msg.fmt_msg.format.width= *width_p;
	msg.fmt_msg.format.height= *height_p;
	for (i= 0; i < 3; i++) {
		msg.fmt_msg.format.pitch[i]= pitch[i];
		msg.fmt_msg.format.lines[i]= lines[i];
	}

	/* Send event to main thread */
	if (send(mpinfo->event_pipe, &msg.fmt_msg, sizeof(msg.fmt_msg), 0) <= 0) {
		/* If user has closed the event pipe, return failure */
		return 0;
	}

	/* Wait for response */
	i= 0;
	while (1) {
		if ((got= recv(mpinfo->vbuf_pipe[0], (char*) &msg, sizeof(msg), 0)) <= 0) {
			PerlVLC_cb_log_error("BUG: Video format callback unable to read pipe");
			return 0;
		}
		else if (got == sizeof(msg.fmt_msg) && msg.msg.event_id == PERLVLC_MSG_VIDEO_FORMAT_EVENT)
			break;
		/* If the format callback happens mid-stream, there are probably other video
		 * picture messages in the queue that need returned to the player. */
		else if (got == sizeof(msg.pic_msg) && msg.msg.event_id == PERLVLC_MSG_VIDEO_TRADE_PICTURE) {
			if (mpinfo->trace_pictures)
				PerlVLC_cb_log_error("format_cb: returning picture %d unused", msg.pic_msg.picture->id);
			msg.pic_msg.picture->held_by_vlc= 0;
			if (send(mpinfo->event_pipe, &msg.pic_msg, sizeof(msg.pic_msg), 0) < sizeof(msg.pic_msg))
				PerlVLC_cb_log_error("BUG: format_callback: Can't return picture to player");
		}
		else {
			PerlVLC_cb_log_error("BUG: Video format callback got invalid message: size=%d type=%d",
				got, (got > sizeof(msg.msg)? msg.msg.event_id : 0));
		}
	}

	/* Apply values back to the arguments (which are read/write) */
	*(int32_t*)chroma_p= *(int32_t*) msg.fmt_msg.format.chroma;
	*width_p=  msg.fmt_msg.format.width;
	*height_p= msg.fmt_msg.format.height;
	for (i= 0; i < 3; i++) {
		pitch[i]= msg.fmt_msg.format.pitch[i];
		lines[i]= msg.fmt_msg.format.lines[i];
	}
	if (mpinfo->trace_pictures)
		PerlVLC_cb_log_error("format_cb: application gave chroma=%.4s width=%d height=%d pitch=[%d,%d,%d] lines=[%d,%d,%d] alloc_count=%d",
			chroma_p, *width_p, *height_p, pitch[0], pitch[1], pitch[2], lines[0], lines[1], lines[2], msg.fmt_msg.alloc_count);
	/* Return the number allocated */
	return msg.fmt_msg.alloc_count;
}

static void PerlVLC_video_cleanup_cb(void *opaque) {
	int i;
	char buf[128];
	/* forward message to user that they may clean up the buffers */
	PerlVLC_player_t *mpinfo= (PerlVLC_player_t*) opaque;
	PerlVLC_Message_t msg;
	if (!mpinfo) {
		/* If this happens, it is a bug, and probably going to kil the program.  Warn loudly. */
		PerlVLC_cb_log_error("BUG: Video cleanup callback received NULL opaque pointer");
		return;
	}
	msg.callback_id= mpinfo->callback_id;
	msg.event_id= PERLVLC_MSG_VIDEO_CLEANUP_EVENT;
	if (send(mpinfo->event_pipe, &msg, sizeof(msg), 0) <= 0)
		/* This also should never happen, unless event pipe was closed. */
		PerlVLC_cb_log_error("BUG: Video cleanup callback can't send event");
}

void PerlVLC_enable_video_callbacks(PerlVLC_player_t *mpinfo, int which) {
	/* currently, the only optional callbacks are unlock and cleanup, because
	 * the others need internal defaults in order to maintain a coherent API
	 */
#if (LIBVLC_VERSION_MAJOR < 2)
	if (which & (PERLVLC_VIDEO_CALLBACK_FORMAT|PERLVLC_VIDEO_CALLBACK_CLEANUP))
		carp_croak("Can't support set_format callback on LibVLC %d.%d", LIBVLC_VERSION_MAJOR, LIBVLC_VERSION_MINOR);
#endif
	if (mpinfo->vbuf_pipe[0] < 0)
		croak("Must set vbuf_pipe handles before enabling video callbacks");
	libvlc_video_set_callbacks(
		mpinfo->player,
		PerlVLC_video_lock_cb,
		which & PERLVLC_VIDEO_CALLBACK_UNLOCK? PerlVLC_video_unlock_cb : NULL,
		PerlVLC_video_display_cb,
		mpinfo
	);
	mpinfo->video_cb_installed= 1;
#if (LIBVLC_VERSION_MAJOR >= 2)
	if (which & (PERLVLC_VIDEO_CALLBACK_FORMAT|PERLVLC_VIDEO_CALLBACK_CLEANUP)) {
		libvlc_video_set_format_callbacks(
			mpinfo->player,
			PerlVLC_video_format_cb,
			which & PERLVLC_VIDEO_CALLBACK_CLEANUP? PerlVLC_video_cleanup_cb : NULL
		);
		mpinfo->video_format_cb_installed= 1;
	}
#endif
}

/* Send a reply to the video format callback, telling it what format parameters
 * the frames should be decoded as. */
void PerlVLC_video_reply_format(
	PerlVLC_player_t *player,
	PerlVLC_picture_format_t *format,
	int alloc_count
) {
	PerlVLC_Message_ImgFmt_t msg;
	int wrote;

	if (player->vbuf_pipe[1] < 0)
		croak("video buffer pipe not initialized yet");

	memset(&msg, 0, sizeof(msg));
	memcpy(&msg.format, format, sizeof(msg.format));
	msg.alloc_count= alloc_count;
	msg.event_id= PERLVLC_MSG_VIDEO_FORMAT_EVENT;
	wrote= send(player->vbuf_pipe[1], &msg, sizeof(msg), 0);
	if (player->trace_pictures)
		PerlVLC_cb_log_error("reply to data format callback");
	if (wrote < sizeof(msg))
		carp_croak("failed to write reply to format callback: %d", wrote);

	/* save a copy of the format, to validate pictures later */
	memcpy(&player->current_format, &msg.format, sizeof(msg.format));
}

/* Add a picture to the list held by this object.  The picture must have been
 * wrapped with a Perl hashref prior to this call.
 */
int PerlVLC_player_add_picture(PerlVLC_player_t *player, PerlVLC_picture_t *pic) {
	void *larger;
	int i;
	PERLVLC_TRACE("PerlVLC_player_add_picture(%p, %p)", player, pic);
	if (player->trace_pictures) {
		PerlVLC_cb_log_error("add picture %d to player %p", pic->id, player);
		pic->trace_destruction= player->trace_pictures;
	}

	if (!pic->self_hv) croak("BUG: picture lacks self_hv");
	/* make sure it isn't already in the list */
	for (i= 0; i < player->picture_count; i++)
		if (player->pictures[i] == pic) {
			PERLVLC_TRACE(" picture exists in list");
			return 0;
		}
	/* grow list if needed */
	if (player->picture_count >= player->picture_alloc) {
		PERLVLC_TRACE("grow list");
		if ((larger= realloc(player->pictures, sizeof(void*) * (player->picture_alloc + 8)))) {
			player->pictures= (PerlVLC_picture_t**) larger;
			player->picture_alloc += 8;
		}
		else croak("Can't grow picture array");
	}
	player->pictures[player->picture_count++]= pic;
	/* maintain a refcnt on the HV */
	SvREFCNT_inc(pic->self_hv);
	PERLVLC_TRACE("added ref to picture %d HV (refcnt=%d)", pic->id, SvREFCNT(pic->self_hv));
	return 1;
}

/* Remove a specific picture from the list held by this object.  Dies if the picture
 * doesn't belong to this object.
 */
int PerlVLC_player_remove_picture(PerlVLC_player_t *player, PerlVLC_picture_t *pic) {
	int i;
	if (player->trace_pictures) {
		PerlVLC_cb_log_error("remove picture %d from player %p", pic->id, player);
		pic->trace_destruction= 1;
	}
	for (i= 0; i < player->picture_count; i++)
		if (player->pictures[i] == pic) {
			sv_2mortal((SV*) pic->self_hv);
			PERLVLC_TRACE("mortalized ref to pic %d HV (refcnt=%d)", pic->id, SvREFCNT((SV*)pic->self_hv));
			player->pictures[i]= player->pictures[--player->picture_count];
			return 1;
		}
	return 0;
}

static void warn_format_details(const char *prefix, PerlVLC_picture_format_t *fmt) {
	warn("%s %.4s %dx%d [%d,%d,%d] [%d,%d,%d]", prefix, fmt->chroma, fmt->width, fmt->height,
		fmt->pitch[0], fmt->pitch[1], fmt->pitch[2], fmt->lines[0], fmt->lines[1], fmt->lines[2]);
}

/* Makes sure VLC thread has at least N pictures assigned for it to use.
 * Dies if pipe is not opened yet or if it fails to write to the pipe.
 * Returns the number of pictures assigned to VLC.
 */
void PerlVLC_player_send_picture(PerlVLC_player_t *player, PerlVLC_picture_t *pic) {
	PERLVLC_TRACE("PerlVLC_player_send_picture");
	PerlVLC_Message_TradePicture_t msg;
	int wrote;
	if (player->vbuf_pipe[1] < 0)
		carp_croak("Queue is not initialized");
	if (player->need_format_response)
		carp_croak("Can't queue picture until after format response");
	if (pic->held_by_vlc)
		carp_croak("Picture %d was already sent to video thread", pic->id);
	if (memcmp(&pic->format, &player->current_format, sizeof(PerlVLC_picture_format_t))) {
		warn_format_details("picture format", &pic->format);
		warn_format_details("v-codec format", &player->current_format);
		carp_croak("Picture %d does not match current video format", pic->id);
	}
	msg.event_id= PERLVLC_MSG_VIDEO_TRADE_PICTURE;
	msg.picture= pic;
	if (player->trace_pictures)
		PerlVLC_cb_log_error("give video thread picture %d", pic->id);
	wrote= send(player->vbuf_pipe[1], &msg, sizeof(msg), 0);
	if (wrote != sizeof(msg))
		carp_croak("Failed to send picture to VLC thread");
	pic->held_by_vlc= 1;
}

/*------------------------------------------------------------------------------------------------
 * Set up the vtable structs for applying magic
 */

static int PerlVLC_mg_nodup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
	croak("Can't share VLC objects across perl iThreads");
	return 0;
}
#ifdef MGf_LOCAL
static int PerlVLC_mg_nolocal(pTHX_ SV *var, MAGIC* mg) {
	croak("Can't share VLC objects across perl iThreads");
	return 0;
}
#endif

MGVTBL PerlVLC_instance_mg_vtbl= {
	0, /* get */ 0, /* write */ 0, /* length */ 0, /* clear */
	PerlVLC_instance_mg_free,
	0, PerlVLC_mg_nodup
#ifdef MGf_LOCAL
	, PerlVLC_mg_nolocal
#endif
};
MGVTBL PerlVLC_media_mg_vtbl= {
	0, /* get */ 0, /* write */ 0, /* length */ 0, /* clear */
	PerlVLC_media_mg_free,
	0, PerlVLC_mg_nodup
#ifdef MGf_LOCAL
	, PerlVLC_mg_nolocal
#endif
};
MGVTBL PerlVLC_media_player_mg_vtbl= {
	0, /* get */ 0, /* write */ 0, /* length */ 0, /* clear */
	PerlVLC_media_player_mg_free,
	0, PerlVLC_mg_nodup
#ifdef MGf_LOCAL
	, PerlVLC_mg_nolocal
#endif
};
MGVTBL PerlVLC_picture_mg_vtbl= {
	0, /* get */ 0, /* write */ 0, /* length */ 0, /* clear */
	PerlVLC_picture_mg_free,
	0, PerlVLC_mg_nodup
#ifdef MGf_LOCAL
	, PerlVLC_mg_nolocal
#endif
};
