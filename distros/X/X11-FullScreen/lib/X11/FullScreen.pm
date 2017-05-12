package X11::FullScreen;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.994'; # VERSION

require XSLoader;
XSLoader::load('X11::FullScreen', $VERSION);

1;
__END__

=head1 NAME

X11::FullScreen - Create a full-screen window with Xlib

=head1 SYNOPSIS

  use X11::FullScreen;
  
  # Create the object
  my $xfs = X11::FullScreen->new( $display_string );

  # Create a full-screen window
  $xfs->show();

  # Return any new X event
  my $events = $xfs->check_event();

  # Display a still image
  $xfs->display_still("/path/to/my.png");
  
  # Sync the X display
  $xfs->sync();

  # Close the window
  $xfs->close();


=head1 DESCRIPTION

This module is used for creating simple borderless X windows that take up the entire screen. You can use it to display still images, or to show movies (with Video::Xine).

It was primarily developed to provide a no-frills interface to X for use with L<Video::Xine>, as part of the L<Video::PlaybackMachine> project.

=head1 METHODS

=head3 new()

   my $xfs = X11::FullScreen->new( $display_string );

Creates a new Display object. C<$display_string> should be a valid
X11 display specifier, such as ':0.0'. This does not connect to the display. Call C<show()> before doing anything else.

=head3 show()

   $xfs->show();

Map the window and make it full screen.

=head3 close()

  $xfs->close();

Close the window.

=head3 window()

  my $window = $xfs->window();

Returns the Xlib window ID for our window.

=head3 display()

Returns a pointer to the X connection.

=head3 screen()

Returns the number of the default screen on our display.

=head3 display_width()

Returns the width in pixels of the display.

=head3 display_height()

Returns the height in pixels of the displays.

=head3 pixel_aspect()

Returns the pixel aspect of the screen.

=head3 clear()

Clears the window.

=head3 display_still()

   $xfs->display_still( 'my_file.png' );

Displays a still image. This can be any image format handled by imlib2.

=head3 sync()

Flushes the output buffer and waits until all all requests have been received and
processed by the X server.

=head3 check_event( $event_mask )

   my $event = check_event( $event_mask );
   my $event_type = $event->get_type();

Checks for any new event which has occurred to the full screen window. If
C<$event_mask> is not specified, defaults to 
   ( ExposureMask | VisibilityChangeMask)

This returns an X11::FullScreen::Event object. You can access the event type
by the get_type() method.

=head1 SEE ALSO

L<Video::Xine>, L<Video::PlaybackMachine>, L<Xlib>

=head1 AUTHOR

Stephen Nelson, E<lt>stephenenelson@mac.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Stephen Nelson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
