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

static gboolean
xfce4perl_free_old_callback(XfceMovehandler *handler)
{
    GPerlCallback *old_callback = g_object_get_data(G_OBJECT(handler),
                                                    "xfce4perl-callback");
    if(old_callback) {
        gperl_callback_destroy(old_callback);
        g_object_set_data(G_OBJECT(handler), "xfce4perl-callback", NULL);
        return TRUE;
    }
    
    return FALSE;
}

static void
xfce4perl_move_func(GtkWidget *win, int *x, int *y, gpointer data)
{
    gperl_callback_invoke((GPerlCallback *)data, NULL, win, x, y);
}

static void
xfce4perl_xfce_movehandler_set_move_func(XfceMovehandler *handler,
                                         SV *move,
                                         SV *data)
{
    GPerlCallback *callback, *old_callback;
    GType param_types[3];
    
    param_types[0] = GTK_TYPE_WIDGET;
    param_types[1] = G_TYPE_INT;
    param_types[2] = G_TYPE_INT;
    
    callback = gperl_callback_new(move, data, 3, param_types, G_TYPE_NONE);
    xfce_movehandler_set_move_func(handler, xfce4perl_move_func, callback);
    
    if(!xfce4perl_free_old_callback(handler)) {
        g_signal_connect(G_OBJECT(handler), "destroy",
                         G_CALLBACK(xfce4perl_free_old_callback), NULL);
    }
    g_object_set_data(G_OBJECT(handler), "xfce4perl-callback", callback);
}

MODULE = Xfce4::Movehandler    PACKAGE = Xfce4::Movehandler    PREFIX = xfce_movehandler_

GtkWidget *
xfce_movehandler_new(class, window)
        GtkWidget * window
    C_ARGS:
        window

void
xfce_movehandler_set_move_func(handler, move, data)
        XfceMovehandler * handler
        SV * move
        SV * data
    CODE:
        xfce4perl_xfce_movehandler_set_move_func(handler, move, data=NULL);
