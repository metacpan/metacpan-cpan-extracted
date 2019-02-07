#include <vlc/vlc.h>

/* Wrapper around VLC instance.  It also holds the event pipe handles, and details about
 * logging and anything else of instance-wide nature.
 */
typedef struct PerlVLC_vlc {
	libvlc_instance_t *instance;
	int event_pipe[2];
	int log_level, log_callback_id;
	int log_module:1, log_file:1, log_line:1, log_name:1, log_header:1, log_objid:1;
} PerlVLC_vlc_t;

#define PerlVLC_set_instance_mg(obj, ptr)     PerlVLC_set_mg(obj, &PerlVLC_instance_mg_vtbl, (void*) ptr)
#define PerlVLC_get_instance_mg(obj)          ((PerlVLC_vlc_t*) PerlVLC_get_mg(obj, &PerlVLC_instance_mg_vtbl))
extern SV * PerlVLC_wrap_instance(libvlc_instance_t *inst);
extern void PerlVLC_set_log_cb(PerlVLC_vlc_t *vlc, int callback_id);

/* PerlVLC passes message structures through a pipe (datagram socket, actually)
 * and these identify the messages.  However, the message structs are private
 * for now.
 */
struct PerlVLC_Message;
typedef struct PerlVLC_Message PerlVLC_Message_t;
#define PERLVLC_MSG_BUFFER_SIZE 512
#define PERLVLC_MSG_LOG                 1
#define PERLVLC_MSG_VIDEO_LOCK_EVENT    2
#define PERLVLC_MSG_VIDEO_TRADE_PICTURE 3
#define PERLVLC_MSG_VIDEO_UNLOCK_EVENT  4
#define PERLVLC_MSG_VIDEO_DISPLAY_EVENT 5
#define PERLVLC_MSG_VIDEO_FORMAT_EVENT  6
#define PERLVLC_MSG_VIDEO_CLEANUP_EVENT 7
#define PERLVLC_MSG_EVENT_MAX           7
SV* PerlVLC_inflate_message(void *buffer, int msglen);

/* These are exposed so that PerlVLC_get_mg and PerlVLC_set_mg can be generic and not need
 * a pair of functions for each type of object.
 */
extern MGVTBL PerlVLC_instance_mg_vtbl;
extern MGVTBL PerlVLC_media_mg_vtbl;
extern MGVTBL PerlVLC_media_player_mg_vtbl;
extern MGVTBL PerlVLC_picture_mg_vtbl;
extern void* PerlVLC_get_mg(SV *obj, MGVTBL *mg_vtbl);

#define PERLVLC_PICTURE_PLANES 3
typedef struct PerlVLC_picture_format {
	char chroma[4];                         // four CC code of image format used by VLC
	unsigned width, height;                 // in pixels
	unsigned lines[PERLVLC_PICTURE_PLANES]; // number of rows of pixel data per plane
	unsigned pitch[PERLVLC_PICTURE_PLANES]; // distance in bytes from one line to the next
} PerlVLC_picture_format_t;

extern void PerlVLC_picture_format_init_from_hv(PerlVLC_picture_format_t *format, HV *hv);

typedef struct PerlVLC_picture {
	int id;                 // user-supplied ID to help track picture
	HV *self_hv;            // Picture objects are paired with an HV
	int held_by_vlc;        // whether this picture has been assigned to VLC
	int trace_destruction;  // whether to log the destruction of this object
	PerlVLC_picture_format_t format; // to identify layout of picture
	
	// Plane data is either a scalar-ref, or a directly allocated buffer.  The scalar-refs are
	// hopefully aligned, but we don't adjust the pointers.  The plane[] pointers are direct
	// result of allocation, and we *do* align those before giving to VLC.
	// Either plane[i] OR plane_buffer_sv[i] should be set, and not all planes need to be set.
	// likewise, pitch and lines for unused planes can be 0.
	void *plane[PERLVLC_PICTURE_PLANES];
	SV *plane_buffer_sv[PERLVLC_PICTURE_PLANES];
} PerlVLC_picture_t;

/* Picture planes are most efficient when aligned.  VLC docs recommend 32 bytes,
 * but I saw one codec say "plane 1: pitch not aligned (160%64): disabling direct rendering"
 * so I guess we're up to 64 bytes these days...
 */
#define PERLVLC_PLANE_PITCH_MUL 64
#define PERLVLC_PLANE_PITCH_MASK (PERLVLC_PLANE_PITCH_MUL-1)
#define PERLVLC_ALIGN_PLANE(x) ((void*)( (((intptr_t)(x)) + PERLVLC_PLANE_PITCH_MASK) & ~(intptr_t)PERLVLC_PLANE_PITCH_MASK ))

/* Constructor and destructor for pictures.
 * The picture struct above gets magically attached to a hashref object.
 * Each is reachable from the other.
 */
#define PerlVLC_set_picture_mg(obj, ptr)     PerlVLC_set_mg(obj, &PerlVLC_picture_mg_vtbl, (void*) ptr)
#define PerlVLC_get_picture_mg(obj)          ((PerlVLC_picture_t*) PerlVLC_get_mg(obj, &PerlVLC_picture_mg_vtbl))
extern PerlVLC_picture_t* PerlVLC_picture_new_from_hash(SV *args);
extern SV* PerlVLC_wrap_picture(PerlVLC_picture_t *pic);
extern void PerlVLC_picture_destroy(PerlVLC_picture_t *pic);

/* The player struct holds a reference to a vlc mediaplayer object,
 * and tracks the state of things the perl library is doing to it.
 */
typedef struct PerlVLC_player {
	libvlc_media_player_t *player;
	bool video_cb_installed;
	bool video_format_cb_installed;
	bool trace_pictures; // enables logging of movement of pictures
	int event_pipe;      // write handle of event pipe to VLC instance
	int callback_id;     // id marking this object's events among others on the event_pipe
	int vbuf_pipe[2];    // read,write handle of socket from this object to video thread
	int need_format_response; // whether the format_cb is waiting for a response
	PerlVLC_picture_format_t current_format; // current format needed by vlc decoder
	// array that keeps track of which pictures have been sent to VLC.
	PerlVLC_picture_t **pictures;
	int picture_alloc, picture_count;
} PerlVLC_player_t;

/* Constructor/destructor of player.  The player struct is magically attached to a blessed
 * hashref, and each is reachable form the other.
 */
#define PerlVLC_set_media_player_mg(obj, ptr) PerlVLC_set_mg(obj, &PerlVLC_media_player_mg_vtbl, (void*) ptr)
#define PerlVLC_get_media_player_mg(obj)      ((PerlVLC_player_t*) PerlVLC_get_mg(obj, &PerlVLC_media_player_mg_vtbl))
extern SV * PerlVLC_wrap_media_player(libvlc_media_player_t *player);

/* Video capturing callback API
 * VLC provides an API where callbacks can receive the video frames.  These callbacks can't be
 * handed directly to perl because they run from secondary threads, so need to pass all
 * callback events through a pipe.
 */
#define PERLVLC_VIDEO_CALLBACK_LOCK     1
#define PERLVLC_VIDEO_CALLBACK_UNLOCK   2
#define PERLVLC_VIDEO_CALLBACK_DISPLAY  4
#define PERLVLC_VIDEO_CALLBACK_FORMAT   8
#define PERLVLC_VIDEO_CALLBACK_CLEANUP 16
extern void PerlVLC_enable_video_callbacks(PerlVLC_player_t *mpinfo, int which);
extern int  PerlVLC_player_add_picture(PerlVLC_player_t *player, PerlVLC_picture_t *pic);
extern int  PerlVLC_player_remove_picture(PerlVLC_player_t *player, PerlVLC_picture_t *pic);
extern void PerlVLC_video_reply_format(PerlVLC_player_t *player, PerlVLC_picture_format_t *format, int alloc_count);
extern void PerlVLC_player_send_picture(PerlVLC_player_t *player, PerlVLC_picture_t *pic);

/* VLC media objects aremagically attached directly to blessed hashrefs.
 * I didn't have enough reason to give them a wrapper struct, yet.
 */
#define PerlVLC_set_media_mg(obj, ptr)        PerlVLC_set_mg(obj, &PerlVLC_media_mg_vtbl, (void*) ptr)
#define PerlVLC_get_media_mg(obj)             ((libvlc_media_t*) PerlVLC_get_mg(obj, &PerlVLC_media_mg_vtbl))
extern SV * PerlVLC_wrap_media(libvlc_media_t *player);

/* Include the API for exposing C buffers as perl scalars. */
#include "buffer_scalar.c"
