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

MODULE = Xfce4::ScaledImage    PACKAGE = Xfce4::ScaledImage    PREFIX = xfce_scaled_image_

GtkWidget *
xfce_scaled_image_new(class, pixbuf=NULL)
        GdkPixbuf * pixbuf
    ALIAS:
        Xfce4::ScaledImage::new_from_pixbuf = 1
    CODE:
        if(pixbuf)
            RETVAL = xfce_scaled_image_new_from_pixbuf(pixbuf);
        else
            RETVAL = xfce_scaled_image_new();
    OUTPUT:
        RETVAL

void
xfce_scaled_image_set_from_pixbuf(image, pixbuf)
        XfceScaledImage * image
        GdkPixbuf * pixbuf
