/* NOTE: THIS FILE WAS POSSIBLY AUTO-GENERATED! */

/*
 * Copyright (c) 2005 Brian Tarricone <bjt23@cornell.edu>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "xfce4perl.h"

MODULE = Xfce4::Netk::Window    PACKAGE = Xfce4::Netk::Window    PREFIX = netk_window_

NetkWindow *
netk_window_get(class, xwindow)
        gulong xwindow
    C_ARGS:
        xwindow

NetkScreen *
netk_window_get_screen(window)
        NetkWindow * window

const char *
netk_window_get_name(window)
        NetkWindow * window

const char *
netk_window_get_icon_name(window)
        NetkWindow * window

NetkApplication *
netk_window_get_application(window)
        NetkWindow * window

gulong
netk_window_get_group_leader(window)
        NetkWindow * window

gulong
netk_window_get_xid(window)
        NetkWindow * window

NetkClassGroup *
netk_window_get_class_group(window)
        NetkWindow * window

const char *
netk_window_get_session_id(window)
        NetkWindow * window

const char *
netk_window_get_session_id_utf8(window)
        NetkWindow * window

int
netk_window_get_pid(window)
        NetkWindow * window

const char *
netk_window_get_client_machine(window)
        NetkWindow * window

NetkWindowType
netk_window_get_window_type(window)
        NetkWindow * window

const char*
netk_window_get_resource_class(window)
        NetkWindow * window

const char*
netk_window_get_resource_name(window)
        NetkWindow * window

gboolean
netk_window_is_minimized(window)
        NetkWindow * window

gboolean
netk_window_is_maximized_horizontally(window)
        NetkWindow * window

gboolean
netk_window_is_maximized_vertically(window)
        NetkWindow * window

gboolean
netk_window_is_maximized(window)
        NetkWindow * window

gboolean
netk_window_is_shaded(window)
        NetkWindow * window

gboolean
netk_window_is_skip_pager(window)
        NetkWindow * window

gboolean
netk_window_is_skip_tasklist(window)
        NetkWindow * window

gboolean
netk_window_is_sticky(window)
        NetkWindow * window

void
netk_window_set_skip_pager(window, skip)
        NetkWindow * window
        gboolean skip

void
netk_window_set_skip_tasklist(window, skip)
        NetkWindow * window
        gboolean skip

void
netk_window_close(window)
        NetkWindow * window

void
netk_window_minimize(window)
        NetkWindow * window

void
netk_window_unminimize(window)
        NetkWindow * window

void
netk_window_maximize(window)
        NetkWindow * window

void
netk_window_unmaximize(window)
        NetkWindow * window

void
netk_window_maximize_horizontally(window)
        NetkWindow * window

void
netk_window_unmaximize_horizontally(window)
        NetkWindow * window

void
netk_window_maximize_vertically(window)
        NetkWindow * window

void
netk_window_unmaximize_vertically(window)
        NetkWindow * window

void
netk_window_shade(window)
        NetkWindow * window

void
netk_window_unshade(window)
        NetkWindow * window

void
netk_window_stick(window)
        NetkWindow * window

void
netk_window_unstick(window)
        NetkWindow * window

void
netk_window_keyboard_move(window)
        NetkWindow * window

void
netk_window_keyboard_size(window)
        NetkWindow * window

NetkWorkspace *
netk_window_get_workspace(window)
        NetkWindow * window

void
netk_window_move_to_workspace(window, space)
        NetkWindow * window
        NetkWorkspace * space

gboolean
netk_window_is_pinned(window)
        NetkWindow * window

void
netk_window_pin(window)
        NetkWindow * window

void
netk_window_unpin(window)
        NetkWindow * window

void
netk_window_activate(window)
        NetkWindow * window

gboolean
netk_window_is_active(window)
        NetkWindow * window

void
netk_window_activate_transient(window)
        NetkWindow * window

GdkPixbuf *
netk_window_get_icon(window)
        NetkWindow * window

GdkPixbuf *
netk_window_get_mini_icon(window)
        NetkWindow * window

gboolean
netk_window_get_icon_is_fallback(window)
        NetkWindow * window

void
netk_window_set_icon_geometry(window, x, y, width, height)
        NetkWindow * window
        int x
        int y
        int width
        int height

NetkWindowActions
netk_window_get_actions(window)
        NetkWindow * window

NetkWindowState
netk_window_get_state(window)
        NetkWindow * window

## void netk_window_get_geometry(NetkWindow *window,
##                               int *xp,
##                               int *yp,
##                               int *widthp,
##                               int *heightp)
void
netk_window_get_geometry(window)
        NetkWindow * window
    PREINIT:
        int xp = 0, yp = 0, widthp = 0, heightp = 0;
    INIT:
        dXSTARG;
    PPCODE:
        netk_window_get_geometry(window, &xp, &yp, &widthp, &heightp);
        EXTEND(SP, 4);
        PUSHi(sv_2mortal(newSViv(xp)));
        PUSHi(sv_2mortal(newSViv(yp)));
        PUSHi(sv_2mortal(newSViv(widthp)));
        PUSHi(sv_2mortal(newSViv(heightp)));

gboolean
netk_window_is_visible_on_workspace(window, workspace)
        NetkWindow * window
        NetkWorkspace * workspace

gboolean
netk_window_is_on_workspace(window, workspace)
        NetkWindow * window
        NetkWorkspace * workspace

gboolean
netk_window_is_in_viewport(window, workspace)
        NetkWindow * window
        NetkWorkspace * workspace

