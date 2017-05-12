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

MODULE = Xfce4::Menubutton    PACKAGE = Xfce4::Menubutton    PREFIX = xfce_menubutton_

GtkWidget *
xfce_menubutton_new(class, text)
        const char * text
    C_ARGS:
        text

GtkWidget *
xfce_menubutton_new_with_pixbuf(class, text, pb)
        const char * text
        GdkPixbuf * pb
    C_ARGS:
        text,
        pb

GtkWidget *
xfce_menubutton_new_with_stock_icon(class, text, stock)
        const char * text
        const char * stock
    C_ARGS:
        text,
        stock

void
xfce_menubutton_set_text(menubutton, text)
        XfceMenubutton * menubutton
        const char * text

void
xfce_menubutton_set_pixbuf(menubutton, pixbuf)
        XfceMenubutton * menubutton
        GdkPixbuf * pixbuf

void
xfce_menubutton_set_stock_icon(menubutton, stock)
        XfceMenubutton * menubutton
        const char * stock

