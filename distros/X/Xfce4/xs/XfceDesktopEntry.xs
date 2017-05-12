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

MODULE = Xfce4::DesktopEntry    PACKAGE = Xfce4::DesktopEntry    PREFIX = xfce_desktop_entry_

## XfceDesktopEnry *xfce_desktop_entry_new_from_data(const char *data,
##                                                   const char **categories,
##                                                   int num_categories)
XfceDesktopEntry *
xfce_desktop_entry_new_from_data(class, data, ...)
        const char * data
    C_ARGS:
        data
    PREINIT:
        const char **categories = NULL;
        gint num_categories = 0, i;
    CODE:
        num_categories = items - 2;
        categories = g_new(const gchar *, num_categories);
        for(i = 0; i < num_categories; i++)
            categories[i] = SvPV_nolen(ST(i+2));
        RETVAL = xfce_desktop_entry_new_from_data(data,
                                                  categories,
                                                  num_categories);
        g_free(categories);
    OUTPUT:
        RETVAL

## XfceDesktopEntry *xfce_desktop_entry_new(const char *file,
##                                          const char **categories,
##                                          int num_categories)
XfceDesktopEntry *
xfce_desktop_entry_new(class, file, ...)
        const char *file
    C_ARGS:
        file
    PREINIT:
        const char **categories = NULL;
        gint num_categories = 0, i;
    CODE:
        num_categories = items - 2;
        categories = g_new(const gchar *, num_categories);
        for(i = 0; i < num_categories; i++)
            categories[i] = SvPV_nolen(ST(i+2));
        RETVAL = xfce_desktop_entry_new(file,
                                        categories,
                                        num_categories);
        g_free(categories);
    OUTPUT:
        RETVAL

const char *
xfce_desktop_entry_get_file(desktop_entry)
        XfceDesktopEntry * desktop_entry

## gboolean xfce_desktop_entry_get_string(XfceDesktopEntry *desktop_entry,
##                                        const char *key,
##                                        gboolean translated,
##                                        char **value)
void
xfce_desktop_entry_get_string(desktop_entry, key, translated)
        XfceDesktopEntry * desktop_entry
        const char * key
        gboolean translated
    PREINIT:
        gchar *value = NULL;
    CODE:
        ST(0) = sv_newmortal();
        if(xfce_desktop_entry_get_string(desktop_entry,
                                         key,
                                         translated,
                                         &value))
        {
            ST(0) = sv_2mortal(newSVGChar(value));
            g_free(value);
        } else {
            ST(0) = &PL_sv_undef;
        }

## gboolean xfce_desktop_entry_get_int(XfceDesktopEntry *desktop_entry,
##                                     const char *key,
##                                     int *value)
void
xfce_desktop_entry_get_int(desktop_entry, key)
        XfceDesktopEntry * desktop_entry
        const char * key
    PREINIT:
        gint value = 0;
    CODE:
        ST(0) = sv_newmortal();
        if(xfce_desktop_entry_get_int(desktop_entry, key, &value))
            ST(0) = sv_2mortal(newSViv(value));
        else
            ST(0) = &PL_sv_undef;
