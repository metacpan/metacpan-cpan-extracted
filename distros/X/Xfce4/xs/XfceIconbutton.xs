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

MODULE = Xfce4::Iconbutton    PACKAGE = Xfce4::Iconbutton    PREFIX = xfce_iconbutton_

GtkWidget *
xfce_iconbutton_new(class)
    C_ARGS:
        /* void */

GtkWidget *
xfce_iconbutton_new_from_pixbuf(class, pb)
        GdkPixbuf * pb
    C_ARGS:
        pb

void
xfce_iconbutton_set_pixbuf(icon_button, pixbuf)
        XfceIconbutton * icon_button
        GdkPixbuf * pixbuf

