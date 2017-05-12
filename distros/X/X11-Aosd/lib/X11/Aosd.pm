#----------------------------------------------------------------------- 
# $Id: Aosd.pm,v 1.4 2008/03/29 16:26:56 joern Exp $
#----------------------------------------------------------------------- 
# X11::Aosd - libaosd binding for Cairo powered on screen display
#
# Written by Jörn Reder with support from Thorsten Schönfeld.
# Copyright (C) 2008 Jörn Reder, All Rights Reserved
#-----------------------------------------------------------------------
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.8 or,
# at your option, any later version of Perl 5 you may have available.
#-----------------------------------------------------------------------
package X11::Aosd;

our $VERSION = '0.03';

use 5.008;
use strict;
use warnings;
use Carp;

use Glib;
use Cairo;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        COORDINATE_CENTER
        COORDINATE_MAXIMUM
        COORDINATE_MINIMUM
        TRANSPARENCY_COMPOSITE
        TRANSPARENCY_FAKE
        TRANSPARENCY_NONE
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&X11::Aosd::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('X11::Aosd', $VERSION);

# Preloaded methods go here.

sub update {
    my $self = shift;

    $self->render;
    $self->loop_once;

    1;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

X11::Aosd - libaosd binding for Cairo powered on screen display

=head1 SYNOPSIS

  use X11::Aosd ':all';

  my $aosd = X11::Aosd->new;

  $aosd->set_transparency(TRANSPARENCY_COMPOSITE);

  $aosd->set_position_with_offset(
    COORDINATE_CENTER,
    COORDINATE_CENTER,
    200, 200, 0, 0
  );

  $aosd->set_renderer(sub {
    my ($cr) = @_;
    $cr->set_source_rgba (1, 0, 0, 0.5);
    $cr->rectangle (0, 0, 200, 200);
    $cr->fill;
  });

  $aosd->show;
  $aosd->loop_for(2000);

=head1 DESCRIPTION

This Perl extension binds the aosd library. For now just the Cairo
part is bound, Pango support may be added later.

=head1 REQUIREMENTS

This module needs libaosd version 0.2.4 or better installed
on your system. Additionally the following Perl modules are
required:

  Glib
  Gtk2
  Cairo

The development packages for the correspondent C libraries
are required as well:

  libglib2.0-dev
  libgtk2.0-dev
  libcairo2-dev

=head1 METHODS

=head2 Constructor

=over 4

=item $aosd = X11::Aosd->new()

The constructor takes no arguments. Everthing is controlled
through the $aosd object.

=back

=head2 Object configurators

=over 4

=item $aosd->set_name($name, $class)

Sets XClassHint name and class of the window.

=item $aosd->set_transparency($mode)

Sets the transparency mode of the window. Valid modes are:

  TRANSPARENCY_COMPOSITE
  TRANSPARENCY_FAKE
  TRANSPARENCY_NONE

=item $aosd->set_geometry($x, $y, $width, $height)

Changes absolute position and dimensions of the window.

=item $aosd->set_position_offset($x_offset, $y_offset)

Changes the current position by moving the window by
the given offsets.

=item $aosd->set_position_with_offset($abscissa, $ordinate, $width, $height, $x_offset, $y_offset)

Changes window position and dimension on the screen by positioning
it horizontally ($abscissa) and vertically ($ordinate) adding the given
offsets ($x_offset, $y_offset).

Use these constants to specify the window attachment parameters $abscissa
and $ordinate.

  COORDINATE_CENTER
  COORDINATE_MAXIMUM
  COORDINATE_MINIMUM

=item $aosd->set_renderer($renderer, $user_data)

Apply your renderer to the OSD window. This is a subroutine resp. a closure
with this signature:

  sub renderer {
    my ($cr, $user_data) = @_;
    ...
  }

$cr is the Cairo context managed by libaosd you can draw with. Anytime
the surface needs to be (re)drawn the renderer is called. You can force
calling it using the $aosd->render method (or even better
$aosd->update - see below).

=item $aosd->set_mouse_event_cb($callback, $user_data)

libaosd catches mouse clicks on the window. You can handle these events
by attaching a callback, which has the following signature:

  sub mouse_event {
    my ($event, $user_data) = @_;
    ...
  }
  
$event is a hash reference with the following keys (all integers)
corresponding to libaosd's AosdMouseEvent structure:

  x
  y
  x_root
  y_root
  send_event
  button
  int

=item $aosd->set_hide_upon_mouse_event($boolean)

Set this to a true value if the OSD window should automatically
hide on mouse click.

=back

=head2 Object inspectors

=over 4

=item ($name, $class) = $aosd->get_name

Returns XClassHint name and class of the window.

=item ($trans) = $aosd->get_transparency;

Returns the current transparency mode of the window. Valid
modes are:

  TRANSPARENCY_COMPOSITE
  TRANSPARENCY_FAKE
  TRANSPARENCY_NONE

=item ($x, $y, $width, $height) = $aosd->get_geometry;

Returns position and dimensions of the window.

=item ($width, $height) = $aosd->get_screen_size;

Returns the dimensions of the X screen.

=item ($shown) = $aosd->get_is_shown;

Returns a boolean whether the window is currently visible or not.

=back

=head2 Object manipulators

=over 4

=item $aosd->render

This actually renders the window. Note that the X mainloop need to
run at least one time ($aosd->loop_once) to take rendering effect.
You can use the $aosd->update convenience method for render + loop_once.

=item $aosd->show

Shows the OSD window (and renders it, if not rendered yet).

=item $aosd->hide

Hides the OSD window.

=back

=head2 Mainloop processing

libaosd can take control of the mainloop, but note that your program
blocks when libaosd's mainloop is running. For simple programs
libaosd's maninloop is Ok, but for more complex situations,
e.g. drawing an animation, you should use Glib's mainloop instead
(or any event loop you like, e.g. Event or EV).

Animations are always controlled through timeouts, so with Glib's
mainloop this will look this way:

  my $main_loop = Glib::MainLoop->new;

  my $animation_step = 0;

  $aosd->set_renderer(sub {
    my ($cr) = @_;
    #-- draw animation corresponding to $animation_step.
    ...
    #-- quit mainloop when animation is finished
    $main_loop->quit if $animation_step == $animation_last_step;
  });

  Glib::Timeout->add (20, sub {
    ++$animation_step;
    $aosd->update;
    1;
  });

  $main_loop->run;

Of course you don't need to quit the mainloop at the end of
the animation. This is just for the simplicity of the
example ;)

=over 4

=item $aosd->loop_once

Run the X mainloop one time. Needs to be called after rendering.
You can use the $aosd->update convenience method for render + loop_once.

=item $aosd->loop_for($loop_ms)

Runs the X mainloop for $loop_ms milliseconds, blocking your program
for this amount of time.

=back

=head2 Automatic object manipulator

=over 4

=item $aosd->flash($fade_in_ms, $full_ms, $fade_out_ms)

Fades in the OSD window in $fade_in_ms milliseconds, let it stay
for $full_ms milliseconds and fades it out in $fade_out_ms milliseconds.

=item $aosd->update

This is a convenience method for the combination:

  $aosd->render;
  $aosd->loop_once;

=back

=head1 CONSTANTS

=head2 EXPORT

None by default.

=head2 Exportable constants

Catch these with the ':all' import tag.

Required for set_position_with_offset():

  COORDINATE_CENTER
  COORDINATE_MAXIMUM
  COORDINATE_MINIMUM

Required for set_transparency():

  TRANSPARENCY_COMPOSITE
  TRANSPARENCY_FAKE
  TRANSPARENCY_NONE

=head1 KNOWN BUGS

Currently attached callbacks leak memory which won't be freed, even if the
X11::Aosd instance is destroyed (note: B<attaching> the callback leaks,
not B<calling> it, so it's not that evil ;).

=head1 SEE ALSO

Home of X11::Aosd:

  http://www.exit1.org/X11-Aosd/

Home of libaosd:

  http://www.atheme.org/projects/libaosd.shtml

=head1 AUTHOR

Joern Reder E<lt>joern AT zyn DOT deE<gt>

=head1 THANKS

Many thanks to Thorsten Schönfeld, who supported me with
providing details of the Glib/Cairo/Perl binding stuff, which
I didn't fully understand by myself ;)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Joern Reder

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
