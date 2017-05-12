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
#include <gdk/gdkx.h>

MODULE = Xfce4::SystemTray    PACKAGE = Xfce4::SystemTray    PREFIX = xfce_system_tray_

XfceSystemTray *
xfce_system_tray_new(class)
    C_ARGS:
        /* void */

## gboolean xfce_system_tray_register(XfceSystemTray *tray,
##                                    Screen *screen,
##                                    GError **error)
gboolean
xfce_system_tray_register(tray, screen)
        XfceSystemTray * tray
        int screen
    PREINIT:
        Screen *xscreen = NULL;
        GError *error = NULL;
    CODE:
        xscreen = XScreenOfDisplay(GDK_DISPLAY(), screen);
        RETVAL = xfce_system_tray_register(tray, xscreen, &error);
        if(!RETVAL)
            gperl_croak_gerror("", error);
    OUTPUT:
        RETVAL

void
xfce_system_tray_unregister(tray)
        XfceSystemTray * tray

gboolean
xfce_system_tray_check_running(screen)
        int screen
    PREINIT:
        Screen *xscreen = NULL;
    CODE:
        xscreen = XScreenOfDisplay(GDK_DISPLAY(), screen);
        RETVAL = xfce_system_tray_check_running(xscreen);
    OUTPUT:
        RETVAL

