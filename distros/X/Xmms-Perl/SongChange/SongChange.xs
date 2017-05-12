#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xmms/xmmsctrl.h"
#include "pthread.h"

typedef struct {
    pthread_t thread;
    pthread_mutex_t mutex;
    gint prev_song;
    gint prev_len;
    gint session;
    GHashTable *jtime;
    GHashTable *repeat;
    GHashTable *crop;
    //GHashTable *fade;
#ifdef PERL_SC_HANDLERS
    AV *handlers;
#endif
} sc;

typedef struct {
    gint pos;
    gint num;
    gint counter;
} sc_repeat;

typedef gint Xmms__Remote;
typedef sc * Xmms__SongChange;

#define sc_lock(obj) \
pthread_mutex_lock(&obj->mutex)

#define sc_unlock(obj) \
pthread_mutex_unlock(&obj->mutex)

static gint string_to_time(char *timestr)
{
    gint mm, ss;
    if (sscanf(timestr, "%d:%d", &mm, &ss) == 2) {
	return (mm * 60000) + (ss * 1000);
    }
    return 0;
}

static void time_to_string(gint length, char *timestr)
{
    sprintf(timestr, "%d:%-2.2d", length/60000, (length/1000) % 60);
}

static void sc_hash_store(sc *obj, GHashTable *tab, gpointer key, gpointer val)
{
    sc_lock(obj);
    g_hash_table_insert(tab, key, val);
    sc_unlock(obj);
}

static gpointer sc_hash_fetch(sc *obj, GHashTable *tab, gpointer key)
{
    gpointer retval;
    sc_lock(obj);
    retval = g_hash_table_lookup(tab, key);
    sc_unlock(obj);
    return retval;
}

#define sc_jtime_FETCH(obj, key) \
(gint)sc_hash_fetch(obj, obj->jtime, (gpointer)key)

#define sc_jtime_STORE(obj, key, val) \
sc_hash_store(obj, obj->jtime, (gpointer)key, \
              (gpointer)string_to_time(val))

#define sc_repeat_FETCH(obj, key) \
(sc_repeat *)sc_hash_fetch(obj, obj->repeat, (gpointer)key)

static void sc_repeat_STORE(sc *obj, gint key, gint val)
{
    sc_repeat *scr = sc_repeat_FETCH(obj, key);
    if (!scr) {
	scr = (sc_repeat *)malloc(sizeof(*scr));
    }
    scr->num = val;
    scr->counter = val;
    scr->pos = key - 1;
    sc_hash_store(obj, obj->repeat, (gpointer)key, (gpointer)scr);
}

#define sc_crop_FETCH(obj, key) \
(gint)sc_hash_fetch(obj, obj->crop, (gpointer)key)

#define sc_crop_STORE(obj, key, val) \
sc_hash_store(obj, obj->crop, (gpointer)key, \
              (gpointer)string_to_time(val))

#define xmms_remote_wait_for_output(session) \
while (!xmms_remote_get_output_time(session)) {}

static void sc_jtime_change(sc *obj, gint *pos)
{
    gint jtime;

    if ((jtime = sc_jtime_FETCH(obj, *pos+1))) {
	xmms_remote_wait_for_output(obj->session);
	xmms_remote_jump_to_time(obj->session, jtime);
    }
}

static void sc_repeat_change(sc *obj, gint *pos)
{
    sc_repeat *scr = sc_repeat_FETCH(obj, *pos);

    if (scr && scr->counter) {
	gint length = xmms_remote_get_playlist_time(obj->session, scr->pos);
	*pos = obj->prev_song = scr->pos;
	obj->prev_len = length;
	--scr->counter;
	xmms_remote_set_playlist_pos(obj->session, scr->pos);
    }

    scr = sc_repeat_FETCH(obj, *pos);
    if (scr && !scr->counter) {
	//scr->counter = scr->num; /* reset counter */
    }
}

static void sc_crop_change(sc *obj, gint *pos)
{
    gint crop;
    if ((crop = sc_crop_FETCH(obj, *pos+1))) {
	gint otime = xmms_remote_get_output_time(obj->session);
	if (otime > crop) {
	    gint len = xmms_remote_get_playlist_length(obj->session);
	    gint jump = (len-1) == *pos ? 0 : *pos+1;
	    xmms_remote_set_playlist_pos(obj->session, jump);
	}
    }
}

static void *sc_change_func(void *arg)
{
    sc *obj = (sc *)arg;

    while(1) {
	gint pos = xmms_remote_get_playlist_pos(obj->session);
	gint length = xmms_remote_get_playlist_time(obj->session, pos);

	pthread_testcancel();
	xmms_usleep(350);

	sc_crop_change(obj, &pos);

	if(pos != obj->prev_song || length != obj->prev_len) {
	    sc_lock(obj);
	    obj->prev_song = pos;
	    obj->prev_len = length;
	    sc_unlock(obj);

	    sc_repeat_change(obj, &pos);
	    sc_jtime_change(obj, &pos);
	}
    }
}

#ifdef PERL_SC_HANDLERS
/* XXX need perl-thread-safeness */
static void sc_perl_change(sc *obj, gint pos) {
    gint i;
    
    for (i=0; i<=AvFILL(obj->handlers); i++) {
	dSP;
	SV *sv_session = sv_newmortal();
	SV *sv_pos = sv_newmortal();
	sv_setiv(newSVrv(sv_session, "Xmms::Remote"), 
		 obj->session);
	sv_setiv(sv_pos, pos);

	ENTER;SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(sv_session);
	XPUSHs(sv_pos);
	PUTBACK;
	perl_call_sv(*av_fetch(obj->handlers, i, TRUE), G_DISCARD);
	FREETMPS;LEAVE;
    }
}

static void sc_add_handler(sc *obj, SV *handler)
{
    sc_lock(obj);
    av_push(obj->handlers, SvREFCNT_inc(handler));
    sc_unlock(obj);
}

#endif

static void sc_run(sc *obj)
{
    pthread_create(&obj->thread, NULL, sc_change_func, obj);
}

static void sc_stop(sc *obj)
{
    void *status;
    sc_lock(obj);
    pthread_cancel(obj->thread);
    pthread_join(obj->thread, &status);
#if 0
    if (status != PTHREAD_CANCELED) {
	/* uhhh */
    }
#endif
    sc_unlock(obj);
}

static sc *sc_new(SV *sv_class, gint session)
{
    sc *obj = (sc *)malloc(sizeof(*obj));

    obj->prev_song = -1;
    obj->prev_len = -2;
    obj->session = session;
    obj->jtime  = g_hash_table_new(NULL, NULL);
    obj->repeat = g_hash_table_new(NULL, NULL);
    obj->crop   = g_hash_table_new(NULL, NULL);
    //obj->fade   = g_hash_table_new(NULL, NULL);

#ifdef PERL_SC_HANDLERS
    obj->handlers = newAV();
#endif

    return obj;
}

static gboolean hash_rm_gint(gpointer key, gpointer val, gpointer data)
{
    return 1;
}

static gboolean hash_rm_alloc(gpointer key, gpointer val, gpointer data)
{
    free(val);
    return 1;
}

static void sc_clear(sc *obj)
{
    g_hash_table_foreach_remove(obj->jtime, hash_rm_gint, NULL);
    g_hash_table_foreach_remove(obj->repeat, hash_rm_alloc, NULL);
    g_hash_table_foreach_remove(obj->crop, hash_rm_gint, NULL);
}

static void sc_repeat_reset_func(gpointer key, gpointer val, gpointer data)
{
    ((sc_repeat *)val)->counter = ((sc_repeat *)val)->num;
}

static void sc_repeat_reset(sc *obj)
{
    sc_lock(obj);
    g_hash_table_foreach(obj->repeat, sc_repeat_reset_func, NULL);
    sc_unlock(obj);
}

static void sc_DESTROY(sc *obj)
{
#if 0
    /* hrm, core dumpage here
     * but we only ever have on Xmms::SongChange object alive
     * so nothing "leaks"
     */
    sc_stop(obj);
    g_hash_table_destroy(obj->jtime);
    g_hash_table_destroy(obj->repeat);
    g_hash_table_destroy(obj->crop);
    //g_hash_table_destroy(obj->fade);
#endif
#ifdef PERL_SC_HANDLERS
    SvREFCNT_dec(obj->handlers);
#endif
}

MODULE = Xmms::SongChange   PACKAGE = Xmms::SongChange   PREFIX = sc_

PROTOTYPES: disable

Xmms::SongChange
sc_new(sv_class, session=0)
    SV *sv_class
    Xmms::Remote session

void
sc_DESTROY(obj)
    Xmms::SongChange obj

void
sc_run(obj)
    Xmms::SongChange obj

void
sc_stop(obj)
    Xmms::SongChange obj

#void
#sc_add_handler(obj, handler)
#    Xmms::SongChange obj
#    SV *handler

#void
#sc_lock(obj)
#    Xmms::SongChange obj

#void
#sc_unlock(obj)
#    Xmms::SongChange obj

char *
sc_jtime_FETCH(obj, key)
    Xmms::SongChange obj
    gint key

    PREINIT:
    gint jtime;
    char buf[16];

    CODE:
    if (!(jtime = sc_jtime_FETCH(obj, key))) {
	XSRETURN_UNDEF;
    }
    time_to_string(jtime, buf);
    RETVAL = buf;

    OUTPUT:
    RETVAL

void
sc_jtime_STORE(obj, key, val)
    Xmms::SongChange obj
    gint key
    char *val

void
sc_repeat_STORE(obj, key, val)
    Xmms::SongChange obj
    gint key
    gint val

void
sc_repeat_FETCH(obj, key)
    Xmms::SongChange obj
    gint key

    PREINIT:
    sc_repeat *scr;

    PPCODE:
    if (!(scr = sc_repeat_FETCH(obj, key))) {
	XSRETURN_UNDEF;
    }
    XPUSHs(sv_2mortal(newSViv(scr->num)));
    if (GIMME == G_ARRAY) {
	XPUSHs(sv_2mortal(newSViv(scr->counter)));
    }

void
sc_crop_STORE(obj, key, val)
    Xmms::SongChange obj
    gint key
    char *val

char *
sc_crop_FETCH(obj, key)
    Xmms::SongChange obj
    gint key

    PREINIT:
    gint ctime;
    char buf[16];

    CODE:
    if (!(ctime = sc_crop_FETCH(obj, key))) {
	XSRETURN_UNDEF;
    }
    time_to_string(ctime, buf);
    RETVAL = buf;

    OUTPUT:
    RETVAL
    
void
sc_clear(obj)
    Xmms::SongChange obj

void
sc_repeat_reset(obj)
    Xmms::SongChange obj
