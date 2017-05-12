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

MODULE = Xfce4::IconTheme    PACKAGE = Xfce4::IconTheme    PREFIX = xfce_icon_theme_

XfceIconTheme *
xfce_icon_theme_get_for_screen(class, screen)
        GdkScreen_ornull * screen
    C_ARGS:
        screen

gchar *
xfce_icon_theme_lookup(icon_theme, icon_name, icon_size)
        XfceIconTheme * icon_theme
        const gchar * icon_name
        gint icon_size

=for apidoc Xfce4::IconTheme::lookup_list
=for signature string = $icon_theme->lookup_list (@icon_names, $icon_size)
=for arg ... (__hide__)
=for arg icon_size (integer)
=for arg icon_names (list)
=cut
## gchar *xfce_icon_theme_lookup_list(XfceIconTheme *icon_theme,
##                                    GList* icon_names,
##                                    gint icon_size)
gchar *
xfce_icon_theme_lookup_list(icon_theme, ...)
        XfceIconTheme * icon_theme
    PREINIT:
        GList *icon_names = NULL;
        gint icon_size = -1, nnames, i;
    CODE:
        nnames = items - 2;
        for(i = 0; i < nnames; i++)
            icon_names = g_list_prepend(icon_names, SvGChar(ST(i+1)));
        icon_size = SvGInt(ST(items-1));
        if(icon_names) {
            RETVAL = xfce_icon_theme_lookup_list(icon_theme,
                                                 icon_names,
                                                 icon_size);
            g_list_free(icon_names);
        } else
            RETVAL = NULL;
    OUTPUT:
        RETVAL

gchar *
xfce_icon_theme_lookup_category(icon_theme, category, icon_size)
        XfceIconTheme * icon_theme
        XfceIconThemeCategory category
        gint icon_size

GdkPixbuf *
xfce_icon_theme_load(icon_theme, icon_name, icon_size)
        XfceIconTheme * icon_theme
        const gchar * icon_name
        gint icon_size

=for apidoc Xfce4::IconTheme::load_list
=for signature pixbuf = $icon_theme->load_list (@icon_names, $icon_size)
=for arg ... (__hide__)
=for arg icon_size (integer)
=for arg icon_names (list)
=cut
## GdkPixbuf *xfce_icon_theme_load_list(XfceIconTheme *icon_theme,
##                                      GList* icon_names,
##                                      gint icon_size)
GdkPixbuf *
xfce_icon_theme_load_list(icon_theme, ...)
        XfceIconTheme * icon_theme
    PREINIT:
        GList *icon_names = NULL;
        gint icon_size = -1, nnames, i;
    CODE:
        nnames = items - 2;
        for(i = 0; i < nnames; i++)
            icon_names = g_list_prepend(icon_names, SvGChar(ST(i+1)));
        icon_size = SvGInt(ST(items-1));
        if(icon_names) {
            RETVAL = xfce_icon_theme_load_list(icon_theme,
                                               icon_names,
                                               icon_size);
            g_list_free(icon_names);
        } else
            RETVAL = NULL;
    OUTPUT:
        RETVAL

GdkPixbuf *
xfce_icon_theme_load_category(icon_theme, category, icon_size)
        XfceIconTheme * icon_theme
        XfceIconThemeCategory category
        gint icon_size

## GList *xfce_icon_theme_get_search_path(XfceIconTheme *icon_theme)
void
xfce_icon_theme_get_search_path(icon_theme)
        XfceIconTheme * icon_theme
    PREINIT:
        GList *l, *paths = NULL;
    PPCODE:
        PERL_UNUSED_VAR(ax);
        paths = xfce_icon_theme_get_search_path(icon_theme);
        EXTEND(SP, g_list_length(paths));
        for(l = paths; l; l = l->next) {
            PUSHs(sv_2mortal(newSVGChar(l->data)));
            g_free(l->data);
        }
        g_list_free(paths);

=for apidoc Xfce4::IconTheme::set_search_path
=for signature $icon_theme->set_search_path (@path)
=for arg ... (__hide__)
=for arg path (list)
=cut
## void xfce_icon_theme_set_search_path(XfceIconTheme *icon_theme,
##                                      GList *search_paths)
void
xfce_icon_theme_set_search_path(icon_theme, ...)
        XfceIconTheme * icon_theme
    PREINIT:
        GList *search_paths = NULL;
        gint i;
    CODE:
        for(i = 1; i < items; i++)
            search_paths = g_list_prepend(search_paths, SvGChar(ST(i)));
        if(search_paths) {
            xfce_icon_theme_set_search_path(icon_theme, search_paths);
            g_list_free(search_paths);
        }

void
xfce_icon_theme_prepend_search_path(icon_theme, search_path)
        XfceIconTheme * icon_theme
        const gchar * search_path

void
xfce_icon_theme_append_search_path(icon_theme, search_path)
        XfceIconTheme * icon_theme
        const gchar * search_path

=for apidoc Xfce4::IconTheme::register_category
=for signature xfceiconthemecategory = $icon_theme->register_category (@icon_names)
=for arg ... (__hide__)
=for arg icon_names (list)
=cut
## XfceIconThemeCategory xfce_icon_theme_register_category
##                                                 (XfceIconTheme *icon_theme,
##                                                  GList *icon_names)
XfceIconThemeCategory
xfce_icon_theme_register_category(icon_theme, ...)
        XfceIconTheme * icon_theme
    PREINIT:
        GList *icon_names = NULL;
        gint i;
    CODE:
        for(i = 1; i < items; i++)
            icon_names = g_list_prepend(icon_names, SvGChar(ST(i)));
        RETVAL = xfce_icon_theme_register_category(icon_theme, icon_names);
        if(icon_names)
            g_list_free(icon_names);
    OUTPUT:
        RETVAL

void
xfce_icon_theme_unregister_category(icon_theme, category)
        XfceIconTheme * icon_theme
        XfceIconThemeCategory category

void
xfce_icon_theme_set_use_svg(icon_theme, use_svg)
        XfceIconTheme * icon_theme
        gboolean use_svg

gboolean
xfce_icon_theme_get_use_svg(icon_theme)
        XfceIconTheme * icon_theme

