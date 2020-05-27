package X11::Xlib::Screen;
use strict;
use warnings;
use X11::Xlib::Display;
require Scalar::Util;

# All modules in dist share a version
our $VERSION = '0.20';

=head1 NAME

X11::Xlib::Screen - Convenience wrapper around Display+ScreenID

=head1 DESCRIPTION

In ancient history, a C<Screen> represented one physical graphics device
+ monitor.
Now days there tends to be only one per system, with multiple monitors or
displays aggregated into a single screen using Xinerama or XRandR.
This was mostly caused by the annoying restriction that graphic resources
(i.e. windows) are bound to a single screen.

The short of that story is that C<< $display->screen_count >> and
C<< $screen->width >> etc don't do what a person might expect them to do.
If you want to know about the boundaries of physical monitors you'll need
the yet-unwritten C<X11::Xlib::Monitor> objects provided by a future wrapper
around Xinerama or XRandR.

=head1 ATTRIBUTES

=head2 display

Reference to L<X11::Xlib::Display>

=head2 screen_number

The integer identifying this screen.

=head2 width

Width in pixels

=head2 height

Height in pixels

=head2 width_mm

Physical width in millimeters.

=head2 height_mm

Physical height in millimeters.

=head2 depth

Color depth of the RootWindow of this screen.

=cut

sub display   { $_[0]{display} }
sub screen_number { $_[0]{screen_number} }
sub width     { $_[0]{display}->DisplayWidth($_[0]{screen_number}) }
sub height    { $_[0]{display}->DisplayHeight($_[0]{screen_number}) }
sub width_mm  { $_[0]{display}->DisplayWidthMM($_[0]{screen_number}) }
sub height_mm { $_[0]{display}->DisplayHeightMM($_[0]{screen_number}) }
sub depth     { $_[0]{display}->DefaultDepth($_[0]{screen_number}) }

=head2 root_window_xid

The XID of the root window of this screen

=head2 root_window

The L<X11::Xlib::Window> object for the root window of this screen

=cut

sub root_window_xid {
    my $self= shift;
    $self->{root_window_xid} ||=
        X11::Xlib::RootWindow($self->{display}, $self->{screen_number});
}

sub root_window {
    my $self= shift;
    # Allow strong ref to root window, since it isn't going anywhere
    $self->{root_window} ||=
        $self->{display}->get_cached_window($self->root_window_xid);
}

=head2 visual

The default visual of this screen

=cut

sub visual {
    my $self= shift;
    $self->{visual} ||= $self->{display}->DefaultVisual($self->{screen_number});
}

=head1 METHODS

=cut

sub _new {
    my $class= shift;
    my %args= (@_ == 1 && ref $_[0] eq 'HASH')? %{$_[0]} : @_;
    defined $args{display} or die "'display' is required";
    defined $args{screen_number} or die "'screen_number' is required";
    Scalar::Util::weaken($args{display});
    bless \%args, $class;
}

=head2 visual_info

  my $vinfo= $screen->visual_info();  # uses defualt visual for this screen
  my $vinfo= $screen->visual_info($visual);
  my $vinfo= $screen->visual_info($visual_id);

Shortcut to L<X11::Xlib::Display/visual_info>, but using this screen's
default visual when no argument is given.

=cut

sub visual_info {
    my ($self, $visual_or_id)= @_;
    $self->display->visual_info(defined $visual_or_id? $visual_or_id : $self->visual);
}

=head2 match_visual_info

  my $vinfo= $screen->match_visual_info($depth, $class);

Like L<X11::Xlib::Display/match_visual_info> but with an implied C<$screen> argument.

=cut

sub match_visual_info {
    my ($self, $depth, $class)= @_;
    $self->display->match_visual_info($self, $depth, $class);
}

1;

__END__

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2020 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
