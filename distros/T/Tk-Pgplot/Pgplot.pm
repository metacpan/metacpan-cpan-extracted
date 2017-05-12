package Tk::Pgplot;

=head1 NAME

Tk::Pgplot - Draw PGPLOT graphics in a Perl/Tk window

=head1 SYNOPSIS

 use Tk;
 use Tk::Pgplot;
 use PGPLOT;

 my $mw = new MainWindow;
 my $f = $mw->Frame->pack;
 $f->Pgplot(-name => 'pgtest')->pack;
 $mw->idletasks;
 pgopen('pgtest/ptk');
 my $n = 360;
 pgenv(0, $n, -1, 1, 0, 2);
 pglab('x', 'y', 'y = sin(x)');
 pgline($n+1, [(0..$n)], [map {sin($_*6.28/$n)} (0..$n)]);
 MainLoop;

=head1 STANDARD OPTIONS

-background   -foreground   -cursor   -borderwidth   -relief
-height   -width  -highlightbackground   -highlightcolor
-highlightthickness   -takefocus   -xscrollcommand
-yscrollcommand   -padx   -pady

See Tk::options for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

 Name:     name
 Class:    Name
 Switch:   -name
     Specifies the name of the widget. This name must also be supplied to pgopen

 Name:     minColors
 Class:    MinColors
 Switch:   -mincolors
     Specifies the minimum number of colors to allocate for the plot

 Name:     maxColors
 Class:    MaxColors
 Switch:   -maxcolors
     Specifies the maximum number of colors to allocate for the plot

 Name:     share
 Class:    Share
 Switch:   -share
     A value of 1 specifies that colors will be shared

=head1 DESCRIPTION

This module implements a pgplot widget that can be used in a Perl/Tk
window. Additional options, described above, may be specified on the
command line or in the option database to configure aspects of the
widget.

=head1 METHODS

The Pgplot method creates a widget object.  This object supports the
configure and cget methods described in Tk::options which can be used
to enquire and modify the options described above.  The widget also
inherits all the methods provided by the generic Tk::Widget class.

The following additional methods are available for Pgplot widgets:

=over 4

=item B<id>

 Returns the PGPLOT id of the widget.

=item B<xview>

The xview method is normally used as the callback in a Tk::Scrollbar
widget for a horizontal scrollbar, e.g.:

  $w->Scrollbar(-orient => 'horizontal',
               -command => ['xview', $pgplot_widget]);

=item B<yview>

The yview method is normally used as the callback in a Tk::Scrollbar
widget for a vertical scrollbar, e.g.:

  $w->Scrollbar(-orient => 'vertical',
               -command => ['yview', $pgplot_widget]);

=item B<world(axis, val1, val2)>

Transform from pixel coordinates into PGPLOT world coordinates

Arguments:

   axis   - one of the following strings:
               x : convert an x-coordinate value
               y : convert a y-coordinate value
              xy : convert an (x,y) coordinate pair

   val1   - if axis is 'x' or 'y', val1 is the pixel
            coordinate value to be transformed. If
            axis is 'xy', val1 is the x-coordinate
            in the coordinate pair.

   val2   - val2 is required only if axis is 'xy'.
            val2 is the y-coordinate in the coordinate pair.

Returns:

   When axis is 'x' or 'y', returns the transformed coordinate
   value. When axis is 'xy', returns an array that contains the
   transformed coordinate pair.

=item B<pixel(axis, val1, val2)>

Transform from PGPLOT world coordinates into pixel coordinates

Arguments:

   axis   - one of the following strings:
               x : convert an x-coordinate value
               y : convert a y-coordinate value
              xy : convert an (x,y) coordinate pair

   val1   - if axis is 'x' or 'y', val1 is the world
            coordinate value to be transformed. If
            axis is 'xy', val1 is the x-coordinate
            in the coordinate pair.

   val2   - val2 is required only if axis is 'xy'.
            val2 is the y-coordinate in the coordinate pair.

Returns:

   When axis is 'x' or 'y', returns the transformed coordinate
   value. When axis is 'xy', returns an array that contains the
   transformed coordinate pair.

=item B<setcursor(mode, xref, yref, ci>

Sets the cursor mode.

Arguments:

   mode   - one of the following strings:

             norm  => Normal, un-agumented cursor
             line  => Line between (xref, yref) and current pointer position
             rect  => Rectangle between (xref, yref) and current pointer position
             yrng  => Horizontal lines at y=yref and current pointer y position
             xrng  => Vertical lines at x=xref and current pointer x position
             hline => Horizontal line passing through pointer y position
             vline => Vertical line passing through  pointer x position
             cross => Crosshair centered at current pointer position

   xref   - x-coordinate reference position

   yref   - y-coordinate reference position

   ci     - color index.

=item B<clrcursor>

Reset the cursor to the 'normal', un-augmented cursor.

=back

=cut

require Tk;

use base qw(Tk::Widget);

Construct Tk::Widget 'Pgplot';


use vars qw($VERSION);
$VERSION = '0.40';

bootstrap Tk::Pgplot $Tk::VERSION;

sub Tk_cmd { \&Tk::pgplot }

Tk::Methods('xview', 'yview', 'world', 'setcursor', 'clrcursor',
	    'id', 'pixel');

1;

=head1 BUGS

You cannot create a Pgplot widget directly in the MainWindow. It must
be created within a Frame.

=head1 REQUIREMENTS

Requires the C<Tk> Module

=head1 AUTHOR

Chris Phillips E<lt>cphil@cpan.orgE<gt>

and

Russell Kackley E<lt>rkackley@cpan.orgE<gt>

=head1 COPYRIGHT

This module is copyright (C) 2000-2002 Chris Phillips.  All rights
reserved.

Copyright (C) 2007 Science and Technology Facilities Council.  All
Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut
