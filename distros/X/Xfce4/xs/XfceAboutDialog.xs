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

typedef XfceAboutInfo * Xfce4__AboutInfo;

MODULE = Xfce4::AboutDialog    PACKAGE = Xfce4::AboutDialog    PREFIX = xfce_about_dialog_

=for apidoc Xfce4::AboutDialog::new
=for signature widget = Xfce4::AboutDialog->new
=for signature widget = Xfce4::AboutDialog->new ($parent, $info, $icon=undef)
Creates a new Xfce4::AboutDialog, either empty, or intialised with a parent,
Xfce4::AboutInfo, and icon.
=cut

=for apidoc Xfce4::AboutDialog::new_with_values
=for signature widget = Xfce4::AboutDialog->new_with_values ($parent, $info, $icon=undef)
=cut

=for apidoc Xfce4::AboutDialog::new_empty
=for signature widget = Xfce4::AboutDialog->new_empty
=for arg parent (__hide__)
=for arg info (__hide__)
=for arg icon (__hide__)
=cut

GtkWidget*
xfce_about_dialog_new(class, parent=NULL, info=NULL, icon=NULL)
        GtkWindow_ornull     * parent
        Xfce4::AboutInfo       info
        GdkPixbuf_ornull     * icon
    ALIAS:
        Xfce4::AboutDialog::new_with_values = 1
        Xfce4::AboutDialog::new_empty = 2
    CODE:
        if(ix == 0 && (items != 1 && items != 3 && items != 4))
            croak("Usage: Xfce4::AboutDialog->new(parent=NULL, info=NULL, icon=NULL");
        else if(ix == 1 && (items != 3 && items != 4))
            croak("Usage: Xfce4::AboutDialog->new_with_values(parent, info, icon=NULL)");
        else if(ix == 2 && items != 1)
            croak("Usage: Xfce4::AboutDialog->new_empty()");
        
        if(ix == 0 || ix == 1)
            RETVAL = xfce_about_dialog_new_with_values(parent, info, icon);
        else
            RETVAL = xfce_about_dialog_new_empty();
    OUTPUT:
        RETVAL

void
xfce_about_dialog_set_program(dialog, value)
        XfceAboutDialog* dialog
        const gchar * value

void
xfce_about_dialog_set_version(dialog, value)
        XfceAboutDialog* dialog
        const gchar * value

void
xfce_about_dialog_set_description(dialog, value)
        XfceAboutDialog* dialog
        const gchar * value

void
xfce_about_dialog_set_copyright(dialog, value)
        XfceAboutDialog* dialog
        const gchar * value

void
xfce_about_dialog_set_license(dialog, value)
        XfceAboutDialog* dialog
        const gchar * value

void
xfce_about_dialog_set_homepage(dialog, value)
        XfceAboutDialog* dialog
        const gchar * value

void
xfce_about_dialog_add_credit(dialog, name, mail, task)
        XfceAboutDialog* dialog
        const gchar   * name
        const gchar   * mail
        const gchar   * task

const gchar *
xfce_about_dialog_get_program(dialog)
        XfceAboutDialog* dialog

const gchar *
xfce_about_dialog_get_version(dialog)
        XfceAboutDialog* dialog

const gchar *
xfce_about_dialog_get_description(dialog)
        XfceAboutDialog* dialog

const gchar *
xfce_about_dialog_get_copyright(dialog)
        XfceAboutDialog* dialog

const gchar *
xfce_about_dialog_get_license(dialog)
        XfceAboutDialog* dialog

const gchar *
xfce_about_dialog_get_homepage(dialog)
        XfceAboutDialog* dialog

