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

MODULE = Xfce4::Netk::Screen    PACKAGE = Xfce4::Netk::Screen    PREFIX = netk_screen_

NetkScreen *
netk_screen_get_default(class)
    C_ARGS:
        /* void */

NetkScreen *
netk_screen_get(class, index)
        int index
    C_ARGS:
        index

NetkScreen *
netk_screen_get_for_root(class, root_window_id)
        gulong root_window_id
    C_ARGS:
        root_window_id

NetkWorkspace *
netk_screen_get_workspace(screen, workspace)
        NetkScreen * screen
        int workspace

NetkWorkspace *
netk_screen_get_active_workspace(screen)
        NetkScreen * screen

NetkWindow *
netk_screen_get_active_window(screen)
        NetkScreen * screen

## GList *netk_screen_get_windows(NetkScreen *screen)
void
netk_screen_get_windows(screen)
        NetkScreen * screen
    PREINIT:
        GList *l, *windows = NULL;
        gint i;
    CODE:
        PERL_UNUSED_VAR(ax);
        windows = netk_screen_get_windows(screen);
        EXTEND(SP, g_list_length(windows));
        for(l = windows, i = 0; l; l = l->next, i++)
            ST(i) = sv_2mortal(newSVNetkWindow(l->data));
        g_list_free(windows);
        XSRETURN(i);

## GList *netk_screen-get_windows_stacked(NetkScreen *screen
void
netk_screen_get_windows_stacked(screen)
        NetkScreen * screen
    PREINIT:
        GList *l, *windows = NULL;
        gint i;
    CODE:
        PERL_UNUSED_VAR(ax);
        windows = netk_screen_get_windows_stacked(screen);
        for(l = windows, i = 0; l; l = l->next, i++)
            ST(i) = sv_2mortal(newSVNetkWindow(l->data));
        g_list_free(windows);
        XSRETURN(i);

void
netk_screen_force_update(screen)
        NetkScreen * screen

int
netk_screen_get_workspace_count(screen)
        NetkScreen * screen

void
netk_screen_change_workspace_count(screen, count)
        NetkScreen * screen
        int count

gboolean
netk_screen_net_wm_supports(screen, atom)
        NetkScreen * screen
        const char * atom

gulong
netk_screen_get_background_pixmap(screen)
        NetkScreen * screen

int
netk_screen_get_width(screen)
        NetkScreen * screen

int
netk_screen_get_height(screen)
        NetkScreen * screen

gboolean
netk_screen_get_showing_desktop(screen)
        NetkScreen * screen

void
netk_screen_toggle_showing_desktop(screen, show)
        NetkScreen * screen
        gboolean show

void
netk_screen_move_viewport(screen, x, y)
        NetkScreen * screen
        int x
        int y

int
netk_screen_try_set_workspace_layout(screen, current_token, rows, columns)
        NetkScreen * screen
        int current_token
        int rows
        int columns

void
netk_screen_release_workspace_layout(screen, current_token)
        NetkScreen * screen
        int current_token

