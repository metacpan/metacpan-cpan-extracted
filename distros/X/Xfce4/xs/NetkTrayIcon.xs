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
#include <libxfcegui4/netk-trayicon.h>
#include <gdk/gdkx.h>

MODULE = Xfce4::Netk::TrayIcon    PACKAGE = Xfce4::Netk::TrayIcon    PREFIX = netk_tray_icon_

GtkWidget *
netk_tray_icon_new(class, screen)
        int screen
    C_ARGS:
        screen
    PREINIT:
        Screen *xscreen = NULL;
    CODE:
        xscreen = XScreenOfDisplay(GDK_DISPLAY(), screen);
        RETVAL = netk_tray_icon_new(xscreen);
    OUTPUT:
        RETVAL

void
netk_tray_icon_set_screen(trayicon, screen)
        NetkTrayIcon * trayicon
        int screen
    PREINIT:
        Screen *xscreen = NULL;
    CODE:
        xscreen = XScreenOfDisplay(GDK_DISPLAY(), screen);
        netk_tray_icon_set_screen(trayicon, xscreen);

glong
netk_tray_icon_message_new(trayicon, id, text)
        NetkTrayIcon * trayicon
        glong id
        const gchar * text

void
netk_tray_icon_message_cancel(trayicon, id)
        NetkTrayIcon * trayicon
        glong id

