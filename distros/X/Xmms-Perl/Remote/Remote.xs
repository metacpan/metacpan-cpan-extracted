#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fcntl.h"

#undef list

#include "xmms/xmmsctrl.h"

typedef gint Xmms__Remote;

#define PUSHgint(g) PUSHs(sv_2mortal(newSViv(g)))

#define CURRENT_POS \
xmms_remote_get_playlist_pos(session)

static gint xmms_session = 0;

#define xmms_remote_prefs_win_toggle(session, show) \
xmms_remote_show_prefs_box(session)

#ifndef HAS_ADD_URL
#define xmms_remote_playlist_add_url_string(session, string) \
        croak("playlist_add_url not available")
#endif

#define xmms_remote_playlist_add_url \
        xmms_remote_playlist_add_url_string

#ifndef HAS_DELETE
#define xmms_remote_playlist_delete(session, pos) \
        croak("playlist_delete not available")
#endif

static AV *svrv_2av(SV *avrv)
{
    if (!(SvROK(avrv) && SvTYPE(SvRV(avrv)) == SVt_PVAV)) {
	croak("not an ARRAY reference");
    }
    return (AV*)SvRV(avrv);
}

static GList *avrv_2glist(SV *avrv)
{
    AV *av = svrv_2av(avrv);
    STRLEN n_a;
    I32 i;
    GList *list = 0;

    for (i=0; i<=AvFILL(av); i++) {
	list = g_list_append(list, SvPV(*av_fetch(av, i, FALSE), n_a));
    }

    return list;
}

static gchar **avrv_2gchar_list(SV *avrv, gint *num)
{
    AV *av = svrv_2av(avrv);
    STRLEN n_a;
    I32 i;
    gchar **list;

    *num = (gint)AvFILL(av)+1;
    list = (gchar **)g_malloc0(*num * sizeof(gchar *));

    for (i=0; i<=AvFILL(av); i++) {
	list[i] = (gchar *)SvPV(*av_fetch(av, i, FALSE), n_a);
    }
    
    return list;
}

typedef gchar * (*playlist_do_func)(gint, gint);

static AV *playlist_do(gint session, playlist_do_func func)
{
    gint i;
    AV *av = newAV();

    for (i=0; i < xmms_remote_get_playlist_length(session); i++) {
	gchar *title = (*func)(session, i);
	av_push(av, newSVpv(title, 0));
        g_free(title);
    }

    return av;
}

static AV *bands_2av(gfloat *bands)
{
    AV *av = newAV();
    int i;
    for (i=0; i<10; i++) {
        av_push(av, newSVnv(bands[i]));
    }
    return av;
}

static gfloat *av_2bands(SV *avrv)
{
    AV *av = svrv_2av(avrv);
    gfloat *bands = (gfloat *)safemalloc(sizeof(gfloat) * 10);
    I32 i;
    if (AvFILL(av)+1 != 10) {
        croak("wrong number of bands %d, should be 10", (int)AvFILL(av)+1);
    }
    for (i=0; i<10; i++) {
        SV *sv = *av_fetch(av, i, FALSE);
        bands[i] = (gfloat)SvNV(sv);
    }
    return bands;
}

static SV *size_string(size_t size)
{
    SV *sv = newSVpv("    -", 5);
    if (size == (size_t)-1) {
	/**/
    }
    else if (!size) {
	sv_setpv(sv, "   0k");
    }
    else if (size < 1024) {
	sv_setpv(sv, "   1k");
    }
    else if (size < 1048576) {
	sv_setpvf(sv, "%4dk", (size + 512) / 1024);
    }
    else if (size < 103809024) {
	sv_setpvf(sv, "%4.1fM", size / 1048576.0);
    }
    else {
	sv_setpvf(sv, "%4dM", (size + 524288) / 1048576);
    }

    return sv;
}

static int waitfor_audio(gint usec)
{
    for (;;) {
	int fd;
	if ((fd = open("/dev/dsp", O_WRONLY)) > 0) {
	    close(fd);
	    return 1;
	}
	xmms_usleep(usec);
    }
    return 0;
}

MODULE = Xmms::Remote   PACKAGE = Xmms::Remote   PREFIX = xmms_remote_

PROTOTYPES: disable

Xmms::Remote
new(classname, session=xmms_session)
    char *classname
    gint session

    CODE:
    ST(0) = sv_newmortal();
    sv_setiv(newSVrv(ST(0),classname), session);

void
xmms_remote_play(session)
    Xmms::Remote session

void
xmms_remote_pause(session)
    Xmms::Remote session

void
xmms_remote_stop(session)
    Xmms::Remote session

void
xmms_remote_quit(session)
    Xmms::Remote session

void
xmms_remote_playlist(session, list, enqueue=0)
    Xmms::Remote session
    GList *list
    gboolean enqueue

    CODE:
    if (!enqueue) {
        xmms_remote_playlist_clear(session);
    }

    xmms_remote_playlist_add(session, list);

    if (!enqueue) {
        xmms_remote_play(session);
    }

    CLEANUP:
    g_list_free(list);

gint
xmms_remote_get_version(session)
    Xmms::Remote session

void 
xmms_remote_playlist_add(session, list)
    Xmms::Remote session
    GList *list

    CLEANUP:
    g_list_free(list);

void 
xmms_remote_playlist_delete(session, pos)
    Xmms::Remote session
    gint pos

void
xmms_remote_playlist_add_url(session, string)
    Xmms::Remote session
    gchar *string

gboolean
xmms_remote_is_playing(session)
    Xmms::Remote session

gboolean
xmms_remote_is_paused(session)
    Xmms::Remote session

gint
xmms_remote_get_playlist_pos(session)
    Xmms::Remote session

void
xmms_remote_set_playlist_pos(session, pos)
    Xmms::Remote session
    gint pos

gint
xmms_remote_get_playlist_length(session)
    Xmms::Remote session

void 
xmms_remote_playlist_clear(session)
    Xmms::Remote session

gint 
xmms_remote_get_output_time(session)
    Xmms::Remote session

SV *
xmms_remote_get_output_timestr(session)
    Xmms::Remote session

    PREINIT:
    gint otime, ptime;

    CODE:
    otime = xmms_remote_get_output_time(session)/1000;
    ptime = xmms_remote_get_playlist_time(session,CURRENT_POS)/1000;
    RETVAL = newSV(0);
    if (ptime) {
	sv_setpvf(RETVAL, "%d:%-2.2d/%d:%-2.2d (%d%%)",
		  otime/60, otime%60, ptime/60, ptime%60, 
		  (otime != 0) ? ((otime*100)/ptime) : 0);
    }
    else {
	sv_setpv(RETVAL, "?");
    }

    OUTPUT:
    RETVAL

void 
xmms_remote_jump_to_time(session, pos)
    Xmms::Remote session
    gint pos

void 
xmms_remote_jump_to_timestr(session, str)
    Xmms::Remote session
    char *str

    PREINIT:
    gint mm, ss;

    CODE:
    if (sscanf(str, "%d:%d", &mm, &ss) == 2) {
	xmms_remote_jump_to_time(session, (mm * 60000) + (ss * 1000));
    }

void 
xmms_remote_get_volume(session)
    Xmms::Remote session

    PREINIT:
    gint vl, vr;

    PPCODE:
    xmms_remote_get_volume(session, &vl, &vr);
    EXTEND(sp, 2);
    PUSHgint(vl);
    PUSHgint(vr);

gint 
xmms_remote_get_main_volume(session)
    Xmms::Remote session

gint 
xmms_remote_get_balance(session)
    Xmms::Remote session

SV *
xmms_remote_get_balancestr(session)
    Xmms::Remote session

    PREINIT:
    gint bal;

    CODE:
    RETVAL = newSV(0);
    if ((bal = xmms_remote_get_balance(session)) == 0) {
	sv_setpv(RETVAL, "center");
    }
    else {
	sv_setpvf(RETVAL, "%d%% %s", 
		  abs(bal), bal > 0 ? "right" : "left");
    }

    OUTPUT:
    RETVAL
    
void 
xmms_remote_set_volume(session, vl, vr=vl)
    Xmms::Remote session
    gint vl
    gint vr

void 
xmms_remote_set_main_volume(session, v)
    Xmms::Remote session
    gint v

void 
xmms_remote_set_balance(session, b)
    Xmms::Remote session
    gint b

gchar *
xmms_remote_get_skin(session)
    Xmms::Remote session

    CLEANUP:
    g_free(RETVAL);

void 
xmms_remote_set_skin(session, skinfile)
    Xmms::Remote session
    gchar *skinfile

gchar *
xmms_remote_get_playlist_file(session, pos=CURRENT_POS)
    Xmms::Remote session
    gint pos

    CLEANUP:
    g_free(RETVAL);

AV *
xmms_remote_get_playlist_files(session)
    Xmms::Remote session

    CODE:
    RETVAL = playlist_do(session, xmms_remote_get_playlist_file);

    OUTPUT:
    RETVAL

gchar *
xmms_remote_get_playlist_title(session, pos=CURRENT_POS)
    Xmms::Remote session
    gint pos

    CLEANUP:
    g_free(RETVAL);

AV *
xmms_remote_get_playlist_titles(session)
    Xmms::Remote session

    CODE:
    RETVAL = playlist_do(session, xmms_remote_get_playlist_title);

    OUTPUT:
    RETVAL

gint 
xmms_remote_get_playlist_time(session, pos=CURRENT_POS)
    Xmms::Remote session
    gint pos

SV *
xmms_remote_get_playlist_timestr(session, pos=CURRENT_POS)
    Xmms::Remote session
    gint pos

    PREINIT:
    gint length;

    CODE:
    length = xmms_remote_get_playlist_time(session, pos);
    RETVAL = newSV(5);
    sv_setpvf(RETVAL, "%d:%-2.2d", length/60000, (length/1000) % 60);

    OUTPUT:
    RETVAL

void 
xmms_remote_get_info(session)
    Xmms::Remote session

    PREINIT:
    gint rate, freq, nch;

    PPCODE:
    xmms_remote_get_info(session, &rate, &freq, &nch);
    EXTEND(sp, 3);
    PUSHgint(rate);
    PUSHgint(freq);
    PUSHgint(nch);

void 
xmms_remote_main_win_toggle(session, show)
    Xmms::Remote session
    gboolean show

void 
xmms_remote_pl_win_toggle(session, show)
    Xmms::Remote session
    gboolean show

void 
xmms_remote_eq_win_toggle(session, show)
    Xmms::Remote session
    gboolean show

void 
xmms_remote_prefs_win_toggle(session, show)
    Xmms::Remote session
    gboolean show

void 
xmms_remote_show_prefs_box(session)
    Xmms::Remote session

void 
xmms_remote_toggle_aot(session, ontop)
    Xmms::Remote session
    gboolean ontop

gboolean
xmms_remote_is_main_win(session)
    Xmms::Remote session

gboolean
xmms_remote_is_pl_win(session)
    Xmms::Remote session

gboolean
xmms_remote_is_eq_win(session)
    Xmms::Remote session

void 
xmms_remote_eject(session)
    Xmms::Remote session

void 
xmms_remote_playlist_prev(session)
    Xmms::Remote session

void 
xmms_remote_playlist_next(session)
    Xmms::Remote session

gboolean 
xmms_remote_is_running(session)
    Xmms::Remote session

void 
xmms_remote_toggle_repeat(session)
    Xmms::Remote session

void 
xmms_remote_toggle_shuffle(session)
    Xmms::Remote session

gint
xmms_remote_is_repeat(session)
    Xmms::Remote session

gint
xmms_remote_is_shuffle(session)
    Xmms::Remote session

void
xmms_remote_get_eq(session)
    Xmms::Remote session

    PREINIT:
    gfloat preamp;
    gfloat *bands;

    PPCODE:
    xmms_remote_get_eq(session, &preamp, &bands);
    if (GIMME_V == G_ARRAY) {
        XPUSHs(sv_2mortal(newSVnv(preamp)));
    }
    XPUSHs(sv_2mortal(newRV_noinc((SV*)bands_2av(bands))));
    g_free(bands);

void
xmms_remote_set_eq(session, preamp, bandsav)
    Xmms::Remote session
    gfloat preamp
    SV *bandsav

    PREINIT:
    gfloat *bands;

    CODE:
    bands = av_2bands(bandsav);
    xmms_remote_set_eq(session, preamp, bands);

    CLEANUP:
    g_free(bands);

gfloat
xmms_remote_get_eq_preamp(session)
    Xmms::Remote session

gfloat
xmms_remote_get_eq_band(session, band)
    Xmms::Remote session
    gint band

void
xmms_remote_set_eq_preamp(session, preamp)
    Xmms::Remote session
    gfloat preamp

void
xmms_remote_set_eq_band(session, band, value)
    Xmms::Remote session
    gint band
    gfloat value

MODULE = Xmms::Remote   PACKAGE = Xmms    PREFIX = xmms_

SV *
size_string(size)
    size_t size

void
xmms_usleep(usec)
    gint usec

void
waitfor_audio(usec=350)
    gint usec
