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

MODULE = Xfce4::Netk::Pager    PACKAGE = Xfce4::Netk::Pager    PREFIX = netk_pager_

GtkWidget *
netk_pager_new(class, screen)
        NetkScreen * screen
    C_ARGS:
        screen

void
netk_pager_set_screen(pager, screen)
        NetkPager * pager
        NetkScreen * screen

void
netk_pager_set_orientation(pager, orientation)
        NetkPager * pager
        GtkOrientation orientation

void
netk_pager_set_n_rows(pager, n_rows)
        NetkPager * pager
        int n_rows

void
netk_pager_set_display_mode(pager, mode)
        NetkPager * pager
        NetkPagerDisplayMode mode

void
netk_pager_set_show_all(pager, show_all_workspaces)
        NetkPager * pager
        gboolean show_all_workspaces

void
netk_pager_set_shadow_type(pager, shadow_type)
        NetkPager * pager
        GtkShadowType shadow_type

