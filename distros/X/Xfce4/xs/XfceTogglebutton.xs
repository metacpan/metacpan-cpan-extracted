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

MODULE = Xfce4::Togglebutton    PACKAGE = Xfce4::Togglebutton    PREFIX = xfce_togglebutton_

GtkWidget *
xfce_togglebutton_new(class, arrow_type)
        GtkArrowType arrow_type
    C_ARGS:
        arrow_type

void
xfce_togglebutton_set_arrow_type(togglebutton, arrow_type)
        XfceTogglebutton * togglebutton
        GtkArrowType arrow_type

