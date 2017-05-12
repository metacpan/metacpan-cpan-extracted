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

MODULE = Xfce4::Netk::Workspace    PACKAGE = Xfce4::Netk::Workspace    PREFIX = netk_workspace_

int
netk_workspace_get_number(space)
        NetkWorkspace * space

const char *
netk_workspace_get_name(space)
        NetkWorkspace * space

void
netk_workspace_change_name(space, name)
        NetkWorkspace * space
        const char * name

void
netk_workspace_activate(space)
        NetkWorkspace * space

int
netk_workspace_get_width(space)
        NetkWorkspace * space

int
netk_workspace_get_height(space)
        NetkWorkspace * space

int
netk_workspace_get_viewport_x(space)
        NetkWorkspace * space

int
netk_workspace_get_viewport_y(space)
        NetkWorkspace * space

gboolean
netk_workspace_is_virtual(space)
        NetkWorkspace * space

