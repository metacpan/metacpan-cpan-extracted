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

MODULE = Xfce4::AppMenuItem    PACKAGE = Xfce4::AppMenuItem    PREFIX = xfce_app_menu_item_

GtkWidget *
xfce_app_menu_item_new(class)
    C_ARGS:
        /* void */

GtkWidget *
xfce_app_menu_item_new_with_label(class, label)
        const gchar * label
    C_ARGS:
        label

GtkWidget *
xfce_app_menu_item_new_with_mnemonic(class, label)
        const gchar * label
    C_ARGS:
        label

GtkWidget *
xfce_app_menu_item_new_with_command(class, label, command)
        const gchar * label
        const gchar * command
    C_ARGS:
        label,
        command

GtkWidget *
xfce_app_menu_item_new_full(class, label, command, icon_filename, needs_term, snotify)
        const gchar * label
        const gchar * command
        const gchar * icon_filename
        gboolean needs_term
        gboolean snotify
    C_ARGS:
        label,
        command,
        icon_filename,
        needs_term,
        snotify

GtkWidget *
xfce_app_menu_item_new_from_desktop_entry(class, entry, show_icon)
        XfceDesktopEntry * entry
        gboolean show_icon
    C_ARGS:
        entry,
        show_icon

void
xfce_app_menu_item_set_name(app_menu_item, name)
        XfceAppMenuItem * app_menu_item
        const gchar * name

void
xfce_app_menu_item_set_icon_name(app_menu_item, filename)
        XfceAppMenuItem * app_menu_item
        const gchar * filename

void
xfce_app_menu_item_set_command(app_menu_item, command)
        XfceAppMenuItem * app_menu_item
        const gchar * command

void
xfce_app_menu_item_set_needs_term(app_menu_item, needs_term)
        XfceAppMenuItem * app_menu_item
        gboolean needs_term

void
xfce_app_menu_item_set_startup_notification(app_menu_item, snotify)
        XfceAppMenuItem * app_menu_item
        gboolean snotify

const gchar *
xfce_app_menu_item_get_name(app_menu_item)
        XfceAppMenuItem * app_menu_item

const gchar *
xfce_app_menu_item_get_icon_name(app_menu_item)
        XfceAppMenuItem * app_menu_item

const gchar *
xfce_app_menu_item_get_command(app_menu_item)
        XfceAppMenuItem * app_menu_item

gboolean
xfce_app_menu_item_get_needs_term(app_menu_item)
        XfceAppMenuItem * app_menu_item

gboolean
xfce_app_menu_item_get_startup_notification(app_menu_item)
        XfceAppMenuItem * app_menu_item

void
xfce_app_menu_item_set_icon_size(icon_size)
        guint icon_size

void
xfce_app_menu_item_set_icon_theme_name(theme_name)
        const gchar * theme_name

