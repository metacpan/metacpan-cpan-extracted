# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2010,2012,2014 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::Xcursor;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(DynaLoader);

__PACKAGE__->bootstrap;

1;

__END__

=head1 NAME

Tk::Xcursor - interface between Tk and the X cursor management library

=head1 SYNOPSIS

   use Tk::Xcursor;
   Tk::Xcursor::SupportsARGB($mw) or warn "This display does not support ARGB cursors";
   my $xcursor = Tk::Xcursor::LoadCursor("/path/to/xcursor");
   $xcursor->Set($tk_widget);

=head1 DESCRPTION

The L<Xcursor(3)> library has support for advanced cursor management.
L<Xcursor> allows the definition of cursors with an alpha channel
(ARGB), and it allows animated cursors. See L<xcursorgen(1)> for a
tool creating files suitable for Xcursor.

=head2 FUNCTIONS

Functions cannot be exported and have therefore be fully qualified.

=head3 SupportsARGB($tk_widget)

Return a true value if the I<$tk_widget>'s display supports ARGB
cursors.

=head3 LoadCursor($path)

Load the Xcursor specified by I<$path> and return a B<Tk::Xcursor>
object.

=head2 METHODS

=head3 Set($tk_widget)

Set the cursor to the given Tk widget.

=head1 COMPATIBILITY

This module works only on (modern) X11 systems.

=head1 AUTHOR

Slaven Rezic <srezic@cpan.org>

=head1 SEE ALSO

L<Xcursor(3)>, L<xcursorgen(1)>, L<Tk>.

=cut
