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

typedef XfceAboutInfo * Xfce4__AboutInfo;

MODULE = Xfce4::AboutInfo    PACKAGE = Xfce4::AboutInfo    PREFIX = xfce_about_info_

Xfce4::AboutInfo
xfce_about_info_new(class, program, version, description, copyright=NULL, license=NULL)
        const gchar * program
        const gchar * version
        const gchar * description
        const gchar * copyright
        const gchar * license
    C_ARGS:
        program,
        version,
        description,
        copyright,
        license

void
xfce_about_info_DESTROY(info)
        Xfce4::AboutInfo info
    CODE:
        xfce_about_info_free(info);

## this is a departure from the C API, but is more perlish
## void
## xfce_about_info_copy_from(XfceAboutInfo * info,
##                           XfceAboutInfo const * from);
Xfce4::AboutInfo
xfce_about_info_copy(info)
        Xfce4::AboutInfo info
    PREINIT:
        XfceAboutInfo *new_info = NULL;
    CODE:
        new_info = xfce_about_info_new("", "", "", NULL, NULL);
        xfce_about_info_copy_from(new_info, info);
        RETVAL = new_info;
    OUTPUT:
        RETVAL

## no need to bind this, as perl's GC will take care of it.
## void
## xfce_about_info_free(info)
##         XfceAboutInfo * info

void
xfce_about_info_set_homepage(info, homepage)
        Xfce4::AboutInfo info
        const gchar * homepage

void
xfce_about_info_add_credit(info, name, mail, task)
        Xfce4::AboutInfo info
        const gchar * name
        const gchar * mail
        const gchar * task
