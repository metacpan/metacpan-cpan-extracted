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

MODULE = Xfce4::Netk::ClassGroup    PACKAGE = Xfce4::Netk::ClassGroup    PREFIX = netk_class_group_

NetkClassGroup *
netk_class_group_get(class, res_class)
        const char * res_class
    C_ARGS:
        res_class

## GList *netk_class_group_get_windows(NetkClassGroup *class_group)
void
netk_class_group_get_windows(class_group)
        NetkClassGroup * class_group
    PREINIT:
        GList *l, *windows = NULL;
        gint i;
    CODE:
        PERL_UNUSED_VAR(ax);
        windows = netk_class_group_get_windows(class_group);
        EXTEND(SP, g_list_length(windows));
        for(l = windows, i = 0; l; l = l->next, i++)
            ST(i) = sv_2mortal(newSVNetkWindow(l->data));
        g_list_free(windows);
        XSRETURN(i);

const char *
netk_class_group_get_res_class(class_group)
        NetkClassGroup * class_group

const char *
netk_class_group_get_name(class_group)
        NetkClassGroup * class_group

GdkPixbuf *
netk_class_group_get_icon(class_group)
        NetkClassGroup * class_group

GdkPixbuf *
netk_class_group_get_mini_icon(class_group)
        NetkClassGroup * class_group
