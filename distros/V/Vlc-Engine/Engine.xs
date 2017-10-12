#define PERL_nO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <vlc/vlc.h>
#include <string.h>

/*
 *m => media
  mp => mplaye player
  ml => media list
  mlp => media list player
*/

libvlc_media_player_t *mp = NULL;
libvlc_media_t *m;

libvlc_media_list_t *ml;
libvlc_media_list_player_t *mlp;

static SV * perl_sub_event_manager_function;

void f_callback(const libvlc_event_t * event, void* opaque)
{
    dSP;
    PUSHMARK(SP);
    //XPUSHs(sv_2mortal(newSVnv(event->type)));
    if (event->type == libvlc_MediaPlayerPlaying)
        PUSHs(sv_2mortal(newSVpv("media_player_playing", 0)));
    else if (event->type == libvlc_MediaPlayerStopped)
        PUSHs(sv_2mortal(newSVpv("media_player_stopped", 0)));
    else if (event->type == libvlc_MediaMetaChanged)
        PUSHs(sv_2mortal(newSVpv("media_meta_changed", 0)));
    
    else if (event->type == libvlc_MediaSubItemAdded)
        PUSHs(sv_2mortal(newSVpv("media_sub_item_added", 0)));

    else if (event->type == libvlc_MediaDurationChanged)
        PUSHs(sv_2mortal(newSVpv("media_duration_changed", 0)));

    else if (event->type == libvlc_MediaParsedChanged)
        PUSHs(sv_2mortal(newSVpv("media_parsed_changed", 0)));

    else if (event->type == libvlc_MediaFreed)
        PUSHs(sv_2mortal(newSVpv("media_freed", 0)));

    else if (event->type == libvlc_MediaStateChanged)
        PUSHs(sv_2mortal(newSVpv("media_state_changed", 0)));

    else if (event->type == libvlc_MediaSubItemTreeAdded)
        PUSHs(sv_2mortal(newSVpv("media_subItem_tree_added", 0)));

    else if (event->type == libvlc_MediaPlayerMediaChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_media_changed", 0)));

    else if (event->type == libvlc_MediaPlayerNothingSpecial)
        PUSHs(sv_2mortal(newSVpv("media_player_nothing_special", 0)));

    else if (event->type == libvlc_MediaPlayerBuffering)
        PUSHs(sv_2mortal(newSVpv("media_player_buffering", 0)));

    else if (event->type == libvlc_MediaPlayerPaused)
        PUSHs(sv_2mortal(newSVpv("media_player_paused", 0)));

    else if (event->type == libvlc_MediaPlayerForward)
        PUSHs(sv_2mortal(newSVpv("media_player_forward", 0)));

    else if (event->type == libvlc_MediaPlayerBackward)
        PUSHs(sv_2mortal(newSVpv("media_player_backward", 0)));

    else if (event->type == libvlc_MediaPlayerEndReached)
        PUSHs(sv_2mortal(newSVpv("media_player_end_reached", 0)));

    else if (event->type == libvlc_MediaPlayerEncounteredError)
        PUSHs(sv_2mortal(newSVpv("media_player_encountered_error", 0)));

    else if (event->type == libvlc_MediaPlayerTimeChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_time_changed", 0)));

    else if (event->type == libvlc_MediaPlayerPositionChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_position_changed", 0)));

    else if (event->type == libvlc_MediaPlayerSeekableChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_seekable_changed", 0)));

    else if (event->type == libvlc_MediaPlayerPausableChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_pausable_changed", 0)));

    else if (event->type == libvlc_MediaPlayerTitleChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_title_changed", 0)));

    else if (event->type == libvlc_MediaPlayerSnapshotTaken)
        PUSHs(sv_2mortal(newSVpv("media_player_snapshot_taken", 0)));

    else if (event->type == libvlc_MediaPlayerLengthChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_length_changed", 0)));

    else if (event->type == libvlc_MediaPlayerVout)
        PUSHs(sv_2mortal(newSVpv("media_player_vout", 0)));

    else if (event->type == libvlc_MediaPlayerScrambledChanged)
        PUSHs(sv_2mortal(newSVpv("media_player_scrambled_changed", 0)));

    else if (event->type == libvlc_MediaPlayerCorked)
        PUSHs(sv_2mortal(newSVpv("media_player_corked", 0)));

    else if (event->type == libvlc_MediaPlayerUncorked)
        PUSHs(sv_2mortal(newSVpv("media_player_uncorked", 0)));

    else if (event->type == libvlc_MediaPlayerMuted)
        PUSHs(sv_2mortal(newSVpv("media_player_muted", 0)));

    else if (event->type == libvlc_MediaPlayerUnmuted)
        PUSHs(sv_2mortal(newSVpv("MediaPlayerUnmuted", 0)));

    else if (event->type == libvlc_MediaPlayerAudioVolume)
        PUSHs(sv_2mortal(newSVpv("media_player_audio_volume", 0)));

    else if (event->type == libvlc_MediaListItemAdded)
        PUSHs(sv_2mortal(newSVpv("media_list_item_added", 0)));

    else if (event->type == libvlc_MediaListWillAddItem)
        PUSHs(sv_2mortal(newSVpv("media_list_will_add_item", 0)));

    else if (event->type == libvlc_MediaListItemDeleted)
        PUSHs(sv_2mortal(newSVpv("media_list_item_deleted", 0)));

    else if (event->type == libvlc_MediaListWillDeleteItem)
        PUSHs(sv_2mortal(newSVpv("media_list_will_delete_item", 0)));

    else if (event->type == libvlc_MediaListViewItemAdded)
        PUSHs(sv_2mortal(newSVpv("media_list_view_item_added", 0)));

    else if (event->type == libvlc_MediaListViewWillAddItem)
        PUSHs(sv_2mortal(newSVpv("media_list_view_will_add_item", 0)));

    else if (event->type == libvlc_MediaListViewItemDeleted)
        PUSHs(sv_2mortal(newSVpv("media_list_view_item_deleted", 0)));

    else if (event->type == libvlc_MediaListViewWillDeleteItem)
        PUSHs(sv_2mortal(newSVpv("media_list_view_will_delete_item", 0)));

    else if (event->type == libvlc_MediaListPlayerPlayed)
        PUSHs(sv_2mortal(newSVpv("media_list_player_played", 0)));

    else if (event->type == libvlc_MediaListPlayerNextItemSet)
        PUSHs(sv_2mortal(newSVpv("media_list_player_next_item_set", 0)));

    else if (event->type == libvlc_MediaListPlayerStopped)
        PUSHs(sv_2mortal(newSVpv("media_list_player_stopped", 0)));

    else if (event->type == libvlc_MediaDiscovererStarted)
        PUSHs(sv_2mortal(newSVpv("media_discoverer_started", 0)));

    else if (event->type == libvlc_MediaDiscovererEnded)
        PUSHs(sv_2mortal(newSVpv("media_discoverer_ended", 0)));

    else if (event->type == libvlc_VlmMediaAdded)
        PUSHs(sv_2mortal(newSVpv("vlm_media_added", 0)));

    else if (event->type == libvlc_VlmMediaRemoved)
        PUSHs(sv_2mortal(newSVpv("vlm_media_removed", 0)));

    else if (event->type == libvlc_VlmMediaChanged)
        PUSHs(sv_2mortal(newSVpv("vlm_media_changed", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStarted)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_started", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStopped)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_stopped", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStatusInit)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_status_init", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStatusOpening)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_status_opening", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStatusPlaying)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_status_playing", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStatusPause)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_status_pause", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStatusEnd)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_status_end", 0)));

    else if (event->type == libvlc_VlmMediaInstanceStatusError)
        PUSHs(sv_2mortal(newSVpv("vlm_media_instance_status_error", 0)));

    PUSHs(sv_2mortal(newSViv(20)));
    PUTBACK;
    call_sv(perl_sub_event_manager_function, G_DISCARD);
}

MODULE = Vlc::Engine		PACKAGE = Vlc::Engine		

void
_version_()
CODE:
    printf("%s",libvlc_get_version());

libvlc_instance_t *
costum_inst(AV* vlc_args = 0)
CODE:
    libvlc_instance_t * inst;
    if (vlc_args == 0){
        inst = libvlc_new (0, NULL);
    } else {
        const char *res[av_len(vlc_args)];
        int i;
        for (i = 0; i <= av_len(vlc_args); ++i){
            SV** elem = av_fetch(vlc_args, i, 0);
            *(res + i) = SvPV_nolen(*elem);
        }
        inst = libvlc_new (av_len(vlc_args), res);
    }
    mp = libvlc_media_player_new( inst );
    mlp = libvlc_media_list_player_new(inst);
    ml = libvlc_media_list_new(inst);
    RETVAL = inst;
OUTPUT:
    RETVAL

void 
_set_media_(p_inst, url)
    libvlc_instance_t * p_inst;
    const char *url;
CODE:
    m = libvlc_media_new_path (p_inst, url);
    libvlc_media_player_set_media( mp, m );
    libvlc_media_release (m); 

void
_set_location_(p_inst, mrl)
    char *mrl;
    libvlc_instance_t * p_inst;
CODE:
   m = libvlc_media_new_location(p_inst, mrl );
   libvlc_media_player_set_media( mp, m );
   libvlc_media_release (m);

void 
_set_media_list_(p_inst, url)
    libvlc_instance_t * p_inst;
    const char *url;
CODE:
    m = libvlc_media_new_path (p_inst, url);
    libvlc_media_list_add_media(ml, m);
    libvlc_media_release (m);

    libvlc_media_list_player_set_media_list(mlp, ml);
    libvlc_media_list_player_set_media_player(mlp, mp);

int
_insert_media_list_(p_inst, url, i_pos)
    char* url;
    int i_pos;
    libvlc_instance_t * p_inst;
CODE:
    m = libvlc_media_new_path (p_inst, url);
    RETVAL = libvlc_media_list_insert_media(ml, m, i_pos );
    libvlc_media_release (m);
OUTPUT:
    RETVAL

int
_remove_media_list_index_(i_pos)
    int i_pos;
CODE:
    RETVAL = libvlc_media_list_remove_index(ml, i_pos);
OUTPUT:
    RETVAL

int
_media_list_count_()
CODE:
    RETVAL = libvlc_media_list_count(ml);
OUTPUT:
    RETVAL

void
_play_list_()
CODE:
    libvlc_media_list_player_set_media_list(mlp, ml);
    libvlc_media_list_player_set_media_player(mlp, mp);
    libvlc_media_list_player_play(mlp);

void
_pause_list_()
CODE:
    libvlc_media_list_player_pause(mlp);

int
_media_list_player_next_()
CODE:
    RETVAL = libvlc_media_list_player_next(mlp);
OUTPUT:
    RETVAL

int
_media_list_player_previous_()
CODE:
    RETVAL = libvlc_media_list_player_previous(mlp);
OUTPUT:
    RETVAL

int 
_media_list_is_readonly_()
CODE:
    RETVAL = libvlc_media_list_is_readonly( ml );
OUTPUT:
    RETVAL

void
_media_list_lock()
CODE:
    libvlc_media_list_lock( ml );

void
_media_list_unlock()
CODE:
    libvlc_media_list_unlock( ml );

void
_parse_media_()
CODE:
    libvlc_media_parse(m);

long
_get_duration_()
CODE:
    RETVAL = libvlc_media_get_duration(m);
OUTPUT:
    RETVAL

void 
_play_()
CODE:       
    libvlc_media_player_play (mp);

void
_pause_()
CODE:
    libvlc_media_player_pause(mp);

void 
_stop_()
CODE:
    libvlc_media_player_stop (mp);

void
_stop_list_()
CODE:
    libvlc_media_list_player_stop(mlp);

void 
_release_(p_inst)
    libvlc_instance_t * p_inst
CODE:
    libvlc_media_player_release (mp);
    libvlc_media_list_player_release(mlp);
    libvlc_media_list_release(ml);
    libvlc_release (p_inst);

int
_set_volume_(i_volume)
    int i_volume;
CODE:
    RETVAL = libvlc_audio_set_volume(mp, i_volume);
OUTPUT:
    RETVAL

int
_get_volume_()
CODE:
    RETVAL = libvlc_audio_get_volume(mp);
OUTPUT:
    RETVAL

void
_set_mute_(status)
    int status;
CODE:
    libvlc_audio_set_mute(mp, status);

int 
_get_mute_()
CODE:
    RETVAL = libvlc_audio_get_mute(mp);
OUTPUT:
    RETVAL

int
_get_state_()
CODE:
     RETVAL = libvlc_media_get_state(m);
OUTPUT:
     RETVAL

libvlc_event_manager_t*
_event_manager_()
CODE:
    RETVAL = libvlc_media_player_event_manager( mp );
OUTPUT:
    RETVAL

libvlc_event_manager_t*
_event_list_manager_()
CODE:
    RETVAL = libvlc_media_list_event_manager( ml );
OUTPUT:
    RETVAL

void 
_event_attach_(manager, i_event_type, callback_p, SV* user_data = 0)
    libvlc_event_manager_t* manager;
    char *i_event_type;
    SV* callback_p;
CODE:

    if (perl_sub_event_manager_function == (SV*)NULL)
        perl_sub_event_manager_function = newSVsv(callback_p);
    else
        SvSetSV(perl_sub_event_manager_function, callback_p);
 
    if (strcmp(i_event_type, "media_player_playing") == 0)
        libvlc_event_attach(manager, libvlc_MediaPlayerPlaying, &f_callback, user_data);
    else if (strcmp(i_event_type, "media_player_paused") == 0)
        libvlc_event_attach(manager, libvlc_MediaPlayerPaused, f_callback, user_data);
    else if (strcmp(i_event_type, "media_player_stopped") == 0)
        libvlc_event_attach(manager, libvlc_MediaPlayerStopped, f_callback, user_data);
    else if (strcmp(i_event_type, "media_player_opening") == 0)
        libvlc_event_attach(manager, libvlc_MediaPlayerOpening, f_callback, user_data);
    else if (strcmp(i_event_type, "media_player_forward") == 0)
        libvlc_event_attach(manager, libvlc_MediaPlayerForward, f_callback, user_data);
    else if (strcmp(i_event_type, "media_player_backward") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerBackward, f_callback, user_data);

    else if (strcmp(i_event_type, "media_meta_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaMetaChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_sub_item_Added") == 0) 
        libvlc_event_attach(manager, libvlc_MediaSubItemAdded, f_callback, user_data);

    else if (strcmp(i_event_type, "media_duration_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaDurationChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_parsed_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaParsedChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_freed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaFreed, f_callback, user_data);

    else if (strcmp(i_event_type, "media_state_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaStateChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_subItem_tree_added") == 0) 
        libvlc_event_attach(manager, libvlc_MediaSubItemTreeAdded, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_media_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerMediaChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_nothing_special") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerNothingSpecial, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_buffering") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerBuffering, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_paused") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerPaused, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_Forward") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerForward, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_backward") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerBackward, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_end_Reached") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerEndReached, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_encountered_error") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerEncounteredError, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_time_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerTimeChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_seekable_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerSeekableChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_pausable_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerPausableChanged, f_callback, user_data);


    else if (strcmp(i_event_type, "media_player_Title_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerTitleChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_length_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerLengthChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_vout") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerVout, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_scrambled_changed") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerScrambledChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_corked") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerCorked, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_uncorked") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerUncorked, f_callback, user_data);


    else if (strcmp(i_event_type, "media_player_Muted") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerMuted, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_unmuted") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerUnmuted, f_callback, user_data);

    else if (strcmp(i_event_type, "media_player_Audio_volume") == 0) 
        libvlc_event_attach(manager, libvlc_MediaPlayerAudioVolume, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_item_added") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListItemAdded, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_will_add_item") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListWillAddItem, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_item_deleted") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListItemDeleted, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_will_delete_item") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListWillDeleteItem, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_view_item_added") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListViewItemAdded, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_view_will_Add_item") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListViewWillAddItem, f_callback, user_data);

    else if (strcmp(i_event_type, "MediaListViewItemDeleted") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListViewItemDeleted, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_view_will_Delete_item") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListViewWillDeleteItem, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_player_played") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListPlayerPlayed, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_player_next_item_set") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListPlayerNextItemSet, f_callback, user_data);

    else if (strcmp(i_event_type, "media_list_player_stopped") == 0) 
        libvlc_event_attach(manager, libvlc_MediaListPlayerStopped, f_callback, user_data);

    else if (strcmp(i_event_type, "media_discoverer_started") == 0) 
        libvlc_event_attach(manager, libvlc_MediaDiscovererStarted, f_callback, user_data);

    else if (strcmp(i_event_type, "media_discoverer_ended") == 0) 
        libvlc_event_attach(manager, libvlc_MediaDiscovererEnded, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_added") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaAdded, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_removed") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaRemoved, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_changed") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaChanged, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_started") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStarted, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_stopped") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStopped, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_status_init") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStatusInit, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_status_opening") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStatusOpening, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_status_playing") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStatusPlaying, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_status_pause") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStatusPause, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_status_end") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStatusEnd, f_callback, user_data);

    else if (strcmp(i_event_type, "vlm_media_instance_status_error") == 0) 
        libvlc_event_attach(manager, libvlc_VlmMediaInstanceStatusError, f_callback, user_data);

char*
_get_meta_(val)
    const char *val
CODE:
    if(strcmp(val, "title") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Title);

    if (strcmp(val, "artist") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Artist);

    if (strcmp(val, "genre") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Genre);

    if (strcmp(val, "album") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Album);

    if(strcmp(val, "copyright") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Copyright);

    if(strcmp(val, "track_number") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_TrackNumber);

    if(strcmp(val, "description") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Description);

    if(strcmp(val, "rating") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Rating);

    if(strcmp(val, "date") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Date);

    if(strcmp(val, "setting") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Setting);

    if(strcmp(val, "url") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_URL);

    if(strcmp(val, "language") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Language);

    if(strcmp(val, "now_playing") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_NowPlaying);

    if(strcmp(val, "publisher") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Publisher);

    if(strcmp(val, "encoded_by") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_EncodedBy);

    if(strcmp(val, "artwork_url") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_ArtworkURL);

    if(strcmp(val, "track_id") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_TrackID);

    if(strcmp(val, "track_total") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_TrackTotal);

    if(strcmp(val, "director") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Director);

    if(strcmp(val, "season") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Season);

    if(strcmp(val, "episode") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Episode);

    if(strcmp(val, "show_name") == 0) 
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_ShowName);

    if(strcmp(val, "actors") == 0)
        RETVAL = libvlc_media_get_meta(m, libvlc_meta_Actors);
OUTPUT:
    RETVAL

void
_set_meta_(e_meta, val)
    const char *e_meta;
    const char *val;
CODE:
    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Title, val );

    if(strcmp(e_meta, "artist") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Artist, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Genre, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Copyright, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Album, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_TrackNumber, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Description, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Rating, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Date, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Setting, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_URL, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Language, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_NowPlaying, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Publisher, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_EncodedBy, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_ArtworkURL, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_TrackID, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_TrackTotal, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Director, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Season, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Episode, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_ShowName, val );

    if(strcmp(e_meta, "title") == 0)
        libvlc_media_set_meta( m, libvlc_meta_Actors, val );


int
_save_meta_()
CODE:
    RETVAL = libvlc_media_save_meta( m );
OUTPUT:
    RETVAL

void
_media_parse_async_()
CODE:
    libvlc_media_parse_async( m );


