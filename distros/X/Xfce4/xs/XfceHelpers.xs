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

MODULE = Xfce4::Helpers    PACKAGE = Xfce4::Helpers    PREFIX = xfce_

=head1 SYNOPSIS

  Various widget helpers and utilities.

=cut

=for apidoc
=for signature ($frame, $frame_bin) = Xfce4::Helpers->create_framebox ($title=undef)
Creates an Xfce-styled GtkFrame with and optional bold-weight title and
indented child contents.  Frame children should be added to the returned
$frame_bin.
=cut
void
xfce_create_framebox(class, title=NULL)
        const gchar *title
    PREINIT:
        GtkWidget *framebox, *frame_bin = NULL;
    CODE:
        EXTEND(SP, 2);
        framebox = xfce_create_framebox(title, &frame_bin);
        ST(0) = sv_2mortal(newSVGtkWidget(framebox));
        ST(1) = sv_2mortal(newSVGtkWidget(frame_bin));
        XSRETURN(2);
