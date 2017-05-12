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

MODULE = Xfce4::Netk::Application    PACKAGE = Xfce4::Netk::Application    PREFIX = netk_application_

NetkApplication *
netk_application_get(class, xwindow)
        gulong xwindow
    C_ARGS:
        xwindow

gulong
netk_application_get_xid(app)
        NetkApplication * app

## GList *netk_application_get_windows(NetkApplication *app)
void
netk_application_get_windows(app)
        NetkApplication * app
    PREINIT:
        GList *l, *windows = NULL;
        gint i;
    CODE:
        PERL_UNUSED_VAR(ax);
        windows = netk_application_get_windows(app);
        EXTEND(SP, g_list_length(windows));
        for(l = windows, i = 0; l; l = l->next, i++)
            ST(i) = sv_2mortal(newSVNetkWindow(l->data));
        g_list_free(windows);
        XSRETURN(i);

int
netk_application_get_n_windows(app)
        NetkApplication * app

const char *
netk_application_get_name(app)
        NetkApplication * app

const char *
netk_application_get_icon_name(app)
        NetkApplication * app

int
netk_application_get_pid(app)
        NetkApplication * app

GdkPixbuf *
netk_application_get_icon(app)
        NetkApplication * app

GdkPixbuf *
netk_application_get_mini_icon(app)
        NetkApplication * app

gboolean
netk_application_get_icon_is_fallback(app)
        NetkApplication * app

