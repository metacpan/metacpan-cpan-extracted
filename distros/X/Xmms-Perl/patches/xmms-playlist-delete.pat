--- ./libxmms/xmmsctrl.c.orig	Thu Jul 29 14:03:12 1999
+++ ./libxmms/xmmsctrl.c	Mon Dec 27 10:16:22 1999
@@ -266,6 +266,11 @@
 	g_free(str_list);
 }
 
+void xmms_remote_playlist_delete(gint session,gint pos)
+{
+	remote_send_guint32(session,CMD_PLAYLIST_DELETE,pos);
+}
+
 void xmms_remote_play(gint session)
 {
 	remote_cmd(session, CMD_PLAY);
--- ./libxmms/xmmsctrl.h.orig	Thu Jul 29 14:03:12 1999
+++ ./libxmms/xmmsctrl.h	Mon Dec 27 10:16:22 1999
@@ -28,6 +28,7 @@
 void xmms_remote_playlist(gint session, gchar ** list, gint num, gboolean enqueue);
 gint xmms_remote_get_version(gint session);
 void xmms_remote_playlist_add(gint session, GList * list);
+void xmms_remote_playlist_delete(gint session, gint pos);
 void xmms_remote_play(gint session);
 void xmms_remote_pause(gint session);
 void xmms_remote_stop(gint session);
--- ./xmms/controlsocket.h.orig	Thu Jul 29 14:03:12 1999
+++ ./xmms/controlsocket.h	Mon Dec 27 10:16:22 1999
@@ -27,7 +27,7 @@
 
 enum
 {
-	CMD_GET_VERSION, CMD_PLAYLIST_ADD, CMD_PLAY, CMD_PAUSE, CMD_STOP,
+	CMD_GET_VERSION, CMD_PLAYLIST_ADD, CMD_PLAYLIST_DELETE, CMD_PLAY, CMD_PAUSE, CMD_STOP,
 	CMD_IS_PLAYING, CMD_IS_PAUSED, CMD_GET_PLAYLIST_POS,
 	CMD_SET_PLAYLIST_POS, CMD_GET_PLAYLIST_LENGTH, CMD_PLAYLIST_CLEAR,
 	CMD_GET_OUTPUT_TIME, CMD_JUMP_TO_TIME, CMD_GET_VOLUME,
--- ./xmms/controlsocket.c.orig	Sun Sep 12 14:03:40 1999
+++ ./xmms/controlsocket.c	Mon Dec 27 10:23:52 1999
@@ -340,6 +340,17 @@
 						playlistwin_update_list();
 						ctrl_ack_packet(pkt);
 						break;
+ 					case	CMD_PLAYLIST_DELETE:
+ 					        if (data && get_playlist_length()) {
+ 						    GList *node = g_list_nth(get_playlist(), *((guint32 *)data));
+ 						    if (node) {
+ 							PlaylistEntry *entry = (PlaylistEntry *)node->data;
+ 							entry->selected = 1;
+ 							playlist_delete(0);
+ 						    }
+ 						}
+ 						ctrl_ack_packet(pkt);
+ 						break;
 					case CMD_PLAYLIST_CLEAR:
 						playlist_clear();
 						ctrl_ack_packet(pkt);
